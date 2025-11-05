# Main.gd
extends Node

const CardScene = preload("res://scenes/Card.tscn")

@onready var card_spawn_point = $CardSpawnPoint

var card_lookup: Dictionary = {}
var draw_pile: Array = []
var discard_pile: Array = []
var pending_cards: Array = []
var questline_state: Dictionary = {}
var game_has_ended = false

func _ready():
	GameState.game_over.connect(_on_game_over)
	load_deck("res://card_data/")
	draw_next_card()

func load_deck(path: String):
	card_lookup.clear()
	draw_pile.clear()
	discard_pile.clear()
	pending_cards.clear()
	questline_state.clear()

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
		if dir.current_is_dir():
			_collect_cards(full_path)
		elif entry.ends_with(".tres"):
			var resource = load(full_path)
			if resource is CardData:
				var card: CardData = resource
				card_lookup[card.card_id] = card
				if card.available_from_start:
					draw_pile.append(card)
			else:
				push_warning("Arquivo %s nao eh um CardData valido." % full_path)
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
	add_child(card_instance)
	card_instance.position = card_spawn_point.position
	card_instance.setup_card(next_card)
	card_instance.card_resolved.connect(_on_card_resolved)
	card_instance.tree_exited.connect(draw_next_card)

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
	var index = 0
	while index < pending_cards.size():
		var entry = pending_cards[index]
		if entry.get("remaining", 0) <= 0:
			pending_cards.remove_at(index)
			var card_id: String = entry.get("card_id", "")
			if card_lookup.has(card_id):
				return card_lookup[card_id]
			else:
				push_warning("Carta agendada %s nao encontrada." % card_id)
				continue
		index += 1
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
	if choice == "left":
		next_id = card_data.next_card_id_left
		next_delay = card_data.next_card_delay_left
		should_game_over = card_data.game_over_left

	if card_data.questline_id != "":
		_update_questline_state(card_data, next_id)

	_advance_pending_delays()

	if next_id != "":
		_schedule_follow_up(next_id, next_delay, card_data.questline_id)

	if card_data.reshuffle_after_use:
		discard_pile.append(card_data)

	if should_game_over:
		var reason = "%s: a escolha '%s' encerrou a jornada." % [card_data.character, choice]
		GameState.trigger_game_over(reason)

func _schedule_follow_up(card_id: String, delay: int, questline_id: String):
	if card_id == "":
		return
	if not card_lookup.has(card_id):
		push_warning("Proxima carta %s nao encontrada." % card_id)
		return
	var entry = {
		"card_id": card_id,
		"remaining": max(delay, 0),
		"questline_id": questline_id
	}
	pending_cards.append(entry)
	if questline_id != "":
		var future_card: CardData = card_lookup[card_id]
		var state = questline_state.get(questline_id, {"status": "idle", "step": -1})
		state["status"] = "active"
		state["step"] = future_card.quest_step
		questline_state[questline_id] = state

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
	print("O jogo terminou. A mudar para a cena de Game Over.")
	game_has_ended = true
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
