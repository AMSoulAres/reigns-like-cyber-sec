# Main.gd
extends Node

const CardScene = preload("res://scenes/Card.tscn")

@onready var background: Sprite2D = $Background
@onready var card_container: Node2D = $CardContainer
@onready var card_spawn_point = $CardSpawnPoint
@onready var ui_layer: Node = $UI

@export var preloaded_deck: Array[CardData] = []
var card_lookup: Dictionary = {}
var draw_pile: Array = []
var discard_pile: Array = []
var pending_cards: Array = []
var questline_state: Dictionary = {}
var game_has_ended = false
var current_viewport_size: Vector2 = Vector2.ZERO

func _ready():
	GameState.game_over.connect(_on_game_over)
	GameState.game_over_sequence_requested.connect(_on_game_over_sequence_requested)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_update_layout()
	load_deck("res://card_data/")
	draw_next_card()

func _on_viewport_size_changed():
	_update_layout()

func load_deck(path: String):
	card_lookup.clear()
	draw_pile.clear()
	discard_pile.clear()
	pending_cards.clear()
	questline_state.clear()

	if preloaded_deck.size() > 0:
		print("Usando baralho pré-carregado (%d cartas)" % preloaded_deck.size())
		preloaded_deck.shuffle()
		for card in preloaded_deck:
			if card:
				card_lookup[card.card_id] = card
				if card.available_from_start:
					draw_pile.append(card)
	else:
		# Fallback para o método antigo de escanear pastas
		print("Escaneando diretório: " + path)
		_collect_cards(path.rstrip("/"))
	
	draw_pile.shuffle()

func _collect_cards(path: String):
	var dir = DirAccess.open(path)
	if dir == null:
		push_error("Erro ao abrir diretorio de cartas: %s" % path)
		return

	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue

		var full_path = path.path_join(entry)
		
		# Se for diretório, entra recursivamente
		if dir.current_is_dir():
			_collect_cards(full_path)
		else:
			# Remove a extensão .remap se ela existir (build)
			var filename_check = entry.trim_suffix(".remap")
			
			if filename_check.ends_with(".tres") or filename_check.ends_with(".res"):
				var path_to_load = full_path.trim_suffix(".remap")
				var resource = load(path_to_load)
				if resource is CardData:
					var card: CardData = resource
					card_lookup[card.card_id] = card
					if card.available_from_start:
						draw_pile.append(card)
				else:
					pass
					
		entry = dir.get_next()
	dir.list_dir_end()

func draw_next_card():
	if game_has_ended:
		return

	var next_card = _pick_next_card()
	if next_card == null:
		print("Fim do baralho! O jogo termina aqui por enquanto.")
		_on_game_over()
		return

	var card_instance = CardScene.instantiate()
	card_container.add_child(card_instance)
	card_instance.position = card_spawn_point.position
	card_instance.setup_card(next_card)
	if current_viewport_size != Vector2.ZERO:
		if card_instance.has_method("update_layout"):
			card_instance.update_layout(current_viewport_size)
	_position_card(card_instance)
	var card_size = Vector2.ZERO
	if card_instance.has_method("get_scaled_size"):
		card_size = card_instance.get_scaled_size()
	_update_ui_layer(card_size)
	if card_instance.has_method("play_draw_animation"):
		card_instance.play_draw_animation()
	card_instance.card_resolved.connect(_on_card_resolved)
	card_instance.tree_exited.connect(draw_next_card)

func _update_layout():
	current_viewport_size = get_viewport().get_visible_rect().size
	card_spawn_point.position = current_viewport_size * 0.5
	_update_background()
	var first_card_size := Vector2.ZERO
	for child in card_container.get_children():
		if child.has_method("update_layout"):
			child.update_layout(current_viewport_size)
		_position_card(child)
		if first_card_size == Vector2.ZERO and child.has_method("get_scaled_size"):
			first_card_size = child.get_scaled_size()
	_update_ui_layer(first_card_size)

func _update_ui_layer(card_size: Vector2):
	if ui_layer == null:
		return
	if ui_layer.has_method("update_card_metrics"):
		ui_layer.update_card_metrics(card_size, current_viewport_size)

func _update_background():
	if background == null or background.texture == null:
		return
	var tex_size = background.texture.get_size()
	if tex_size == Vector2.ZERO:
		return
	var scale_factor = max(
		current_viewport_size.x / tex_size.x,
		current_viewport_size.y / tex_size.y
	)
	background.scale = Vector2.ONE * scale_factor
	background.position = current_viewport_size * 0.5

func _position_card(card):
	var card_size = Vector2.ZERO
	if card.has_method("get_scaled_size"):
		card_size = card.get_scaled_size()
	card.position = card_spawn_point.position - card_size * 0.5

func _pick_next_card() -> CardData:
	var pending_card = _consume_ready_pending_card()
	if pending_card:
		return pending_card

	if draw_pile.is_empty():
		_reshuffle_draw_pile()
	if draw_pile.is_empty():
		if pending_cards.size() > 0:
			pending_cards[0]["remaining"] = 0
			return _consume_ready_pending_card()
		return null

	return draw_pile.pop_back()

func _consume_ready_pending_card() -> CardData:
	var best_candidate_index = -1
	var highest_priority = -9999
	
	for i in range(pending_cards.size()):
		var entry = pending_cards[i]
		
		# Só considera cartas que já cumpriram o delay (remaining <= 0)
		if entry.get("remaining", 0) <= 0:
			var entry_priority = entry.get("priority", 0)

			if entry_priority > highest_priority:
				highest_priority = entry_priority
				best_candidate_index = i

	if best_candidate_index != -1:
		var entry = pending_cards[best_candidate_index]
		pending_cards.remove_at(best_candidate_index)
		
		var card_id: String = entry.get("card_id", "")
		if card_lookup.has(card_id):
			return card_lookup[card_id]
		else:
			push_warning("Carta agendada %s nao encontrada." % card_id)
			return _consume_ready_pending_card()
			
	return null

func _on_card_resolved(card_data: CardData, choice: String):
	if card_data == null:
		return

	var effects = card_data.effects_right
	if choice == "left":
		effects = card_data.effects_left
	if effects and effects.size() > 0:
		GameState.apply_effects(effects)

	var next_id = card_data.next_card_id_right
	var next_delay = card_data.next_card_delay_right
	var should_game_over = card_data.game_over_right
	var explicit_reason = card_data.game_over_right_reason
	if choice == "left":
		next_id = card_data.next_card_id_left
		next_delay = card_data.next_card_delay_left
		should_game_over = card_data.game_over_left
		explicit_reason = card_data.game_over_left_reason

	if card_data.questline_id != "":
		_update_questline_state(card_data, next_id)

	_advance_pending_delays()

	if next_id != "":
		_schedule_follow_up(next_id, next_delay, card_data.questline_id)

	if card_data.reshuffle_after_use:
		discard_pile.append(card_data)

	if should_game_over:
		var reason = explicit_reason.strip_edges() if explicit_reason is String else ""
		if reason == "":
			reason = "%s: a escolha '%s' encerrou a jornada." % [card_data.character, choice]
		GameState.trigger_game_over(reason)

func _schedule_follow_up(card_id: String, delay: int, questline_id: String):
	if card_id == "":
		return
	if not card_lookup.has(card_id):
		push_warning("Proxima carta %s nao encontrada." % card_id)
		return

	var target_card: CardData = card_lookup[card_id]
	
	var entry = {
		"card_id": card_id,
		"remaining": max(delay, 0),
		"questline_id": questline_id,
		"priority": target_card.priority
	}
	pending_cards.append(entry)
	if questline_id != "":
		var future_card: CardData = card_lookup[card_id]
		var state = questline_state.get(questline_id, {"status": "idle", "step": - 1})
		state["status"] = "active"
		state["step"] = future_card.quest_step
		questline_state[questline_id] = state

func _clear_pending_for_questline(questline_id: String, keep_card_id: String = ""):
	if questline_id == "":
		return
	var index := pending_cards.size() - 1
	while index >= 0:
		var entry: Dictionary = pending_cards[index]
		if entry.get("questline_id", "") == questline_id and entry.get("card_id", "") != keep_card_id:
			pending_cards.remove_at(index)
		index -= 1

func _advance_pending_delays():
	for entry in pending_cards:
		entry["remaining"] = max(entry.get("remaining", 0) - 1, 0)

func _update_questline_state(card: CardData, next_id: String):
	var state = questline_state.get(card.questline_id, {"status": "idle", "step": card.quest_step})
	state["step"] = card.quest_step
	if next_id == "":
		state["status"] = "complete"
	else:
		state["status"] = "active"
	questline_state[card.questline_id] = state

func _reshuffle_draw_pile():
	if discard_pile.is_empty():
		return
	for card in discard_pile:
		draw_pile.append(card)
	discard_pile.clear()
	draw_pile.shuffle()

func _on_game_over():
	if game_has_ended:
		return
	print("O jogo terminou. A mudar para a cena de Game Over.")
	game_has_ended = true
	call_deferred("_switch_to_game_over_scene")

func _switch_to_game_over_scene():
	if not is_instance_valid(get_tree()):
		return
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _on_game_over_sequence_requested(card_id: String, reason: String):
	if reason.strip_edges() != "":
		GameState.last_game_over_reason = reason
	if card_id == "":
		GameState.trigger_game_over(reason)
		return
	if not card_lookup.has(card_id):
		push_warning("Carta de game over %s nao encontrada." % card_id)
		GameState.trigger_game_over(reason)
		return
	for entry in pending_cards:
		if entry.get("card_id", "") == card_id:
			return
	var card: CardData = card_lookup[card_id]
	var questline_id = card.questline_id
	_clear_pending_for_questline(questline_id, card_id)
	var entry = {
		"card_id": card_id,
		"remaining": 0,
		"questline_id": questline_id,
		"priority": 9999
	}
	pending_cards.append(entry)
	if questline_id != "":
		var state = questline_state.get(questline_id, {"status": "idle", "step": card.quest_step})
		state["status"] = "active"
		state["step"] = card.quest_step
		questline_state[questline_id] = state
