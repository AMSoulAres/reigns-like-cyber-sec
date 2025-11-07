# Card.gd
extends Node2D

signal card_resolved(card_data, choice: String)

# Referências aos nós principais
@onready var template: TextureRect = %Template
@onready var portrait: TextureRect = %Portrait
@onready var character: Label = %CharacterLabel
@onready var dialogue_label: Label = %DialogueLabel
@onready var choice_left_container: Control = %ChoiceLeftContainer
@onready var choice_right_container: Control = %ChoiceRightContainer

# Referências aos labels DENTRO dos containers
@onready var choice_left_label: Label = $Template/ChoiceLeftContainer/Label
@onready var choice_right_label: Label = $Template/ChoiceRightContainer/Label

# Variável para armazenar os dados do cartão atual.
var card_data

var initial_portrait_pos = Vector2.ZERO
var drag_offset = Vector2.ZERO
var base_template_size = Vector2.ZERO
var reset_tween: Tween
var entry_tween: Tween
var base_portrait_scale = Vector2.ONE
var base_portrait_color = Color.WHITE

# Função pública para configurar o cartão com dados específicos.
func setup_card(data):
	self.card_data = data
	
	# Atualiza os elementos visuais com base nos dados recebidos[cite: 25].
	portrait.texture = data.portrait
	_center_portrait_pivot()
	dialogue_label.text = data.dialogue
	choice_left_label.text = data.choice_left_text
	choice_right_label.text = data.choice_right_text
	character.text = data.character

	# Garante que os containers de escolha comecem invisíveis.
	choice_left_container.modulate.a = 0
	choice_right_container.modulate.a = 0
	_reset_card_visuals(false)
	
	# Configura quais ícones devem aparecer para cada escolha
	_setup_icons(choice_left_container, data.effects_left)
	_setup_icons(choice_right_container, data.effects_right)

# Função auxiliar para ligar/desligar ícones de status
func _setup_icons(container: Control, effects: Dictionary):
	var icon_paths = {
		"money": "Icons/Money",
		"moral": "Icons/Moral",
		"infra": "Icons/Infra",
		"reputation": "Icons/Reputation"
	}

	var any_visible = false
	for stat in icon_paths.keys():
		var icon_node = container.get_node_or_null(icon_paths[stat])
		if icon_node:
			var show_icon = effects.has(stat)
			icon_node.visible = show_icon
			any_visible = any_visible or show_icon

	var icons_row = container.get_node_or_null("Icons")
	if icons_row:
		icons_row.visible = any_visible

const BASE_SWIPE_THRESHOLD = 150 # Distância em pixels para confirmar um deslize no tamanho base.[cite: 27]
const ROTATION_FACTOR = 0.005 # Quão rápido o cartão gira ao ser arrastado[cite: 27].
const MAX_DROP_OFFSET = 50.0 # Quanto a carta desce visualmente durante o swipe.
var is_dragging = false
var initial_mouse_pos = Vector2.ZERO
var swipe_threshold = BASE_SWIPE_THRESHOLD

func _ready():
	initial_portrait_pos = portrait.position
	base_portrait_scale = portrait.scale
	base_portrait_color = portrait.modulate
	_center_portrait_pivot()
	_cache_template_size()
	_update_swipe_threshold()

func _center_portrait_pivot():
	var base_size = portrait.size
	if base_size == Vector2.ZERO and portrait.texture:
		base_size = portrait.texture.get_size()
	if base_size != Vector2.ZERO:
		portrait.pivot_offset = base_size * 0.5

func _cache_template_size():
	if template.texture:
		base_template_size = template.texture.get_size()
	if base_template_size == Vector2.ZERO:
		base_template_size = template.size

func update_layout(viewport_size: Vector2):
	if base_template_size == Vector2.ZERO:
		_cache_template_size()
	if base_template_size == Vector2.ZERO or viewport_size.y <= 0:
		return
	var scale_factor = viewport_size.y / base_template_size.y
	scale = Vector2.ONE * scale_factor
	if entry_tween and entry_tween.is_running():
		entry_tween.kill()
	entry_tween = null
	portrait.scale = base_portrait_scale
	portrait.modulate = base_portrait_color
	_update_swipe_threshold()

func get_scaled_size() -> Vector2:
	if base_template_size == Vector2.ZERO:
		_cache_template_size()
	return base_template_size * scale

func _update_swipe_threshold():
	swipe_threshold = max(BASE_SWIPE_THRESHOLD * scale.x, 1.0)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			# Checa o clique no template do card, não mais só no retrato
			if template.get_global_rect().has_point(event.position):
				is_dragging = true
				initial_mouse_pos = get_global_mouse_position()
				drag_offset = Vector2.ZERO
		else:
			if is_dragging:
				drag_offset = get_global_mouse_position() - initial_mouse_pos
				is_dragging = false
				process_swipe()

	if event is InputEventMouseMotion and is_dragging:
		drag_offset = get_global_mouse_position() - initial_mouse_pos
		_update_drag_visuals()

func _update_drag_visuals():
	var limited_offset_x = clamp(drag_offset.x, -swipe_threshold, swipe_threshold)
	var swipe_amount = 0.0
	if swipe_threshold > 0:
		swipe_amount = clamp(abs(limited_offset_x) / swipe_threshold, 0.0, 1.0)
	var drop_offset = MAX_DROP_OFFSET * swipe_amount
	portrait.position = initial_portrait_pos + Vector2(limited_offset_x, 0) + Vector2(0, drop_offset)
	portrait.rotation = limited_offset_x * ROTATION_FACTOR * 0.5

	if swipe_threshold <= 0:
		return
	var swipe_progress = swipe_amount
	if drag_offset.x < 0:
		choice_left_container.modulate.a = swipe_progress
		choice_right_container.modulate.a = 0
	else:
		choice_right_container.modulate.a = swipe_progress
		choice_left_container.modulate.a = 0

func process_swipe():
	var final_delta_x = drag_offset.x
	
	# Verifica se o deslize excedeu o limiar para a esquerda.
	if final_delta_x < -swipe_threshold:
		card_resolved.emit(card_data, "left")
		queue_free()
	# Verifica se o deslize excedeu o limiar para a direita.
	elif final_delta_x > swipe_threshold:
		card_resolved.emit(card_data, "right")
		queue_free()
	else:
		_reset_card_visuals()

func _reset_card_visuals(animate: bool = true):
	drag_offset = Vector2.ZERO
	if initial_portrait_pos == Vector2.ZERO:
		initial_portrait_pos = portrait.position
	if reset_tween and reset_tween.is_running():
		reset_tween.kill()
	reset_tween = null
	if entry_tween and entry_tween.is_running():
		entry_tween.kill()
	entry_tween = null
	portrait.scale = base_portrait_scale
	portrait.modulate = base_portrait_color

	var left_target = choice_left_container.modulate
	left_target.a = 0.0
	var right_target = choice_right_container.modulate
	right_target.a = 0.0

	if not animate:
		portrait.position = initial_portrait_pos
		portrait.rotation = 0
		portrait.modulate = base_portrait_color
		portrait.scale = base_portrait_scale
		choice_left_container.modulate = left_target
		choice_right_container.modulate = right_target
		return

	reset_tween = create_tween()
	reset_tween.set_trans(Tween.TRANS_SINE)
	reset_tween.set_ease(Tween.EASE_IN_OUT)
	reset_tween.tween_property(portrait, "position", initial_portrait_pos, 0.25)
	reset_tween.parallel().tween_property(portrait, "rotation", 0.0, 0.25)
	reset_tween.parallel().tween_property(choice_left_container, "modulate", left_target, 0.2)
	reset_tween.parallel().tween_property(choice_right_container, "modulate", right_target, 0.2)
	reset_tween.finished.connect(func():
		if reset_tween:
			portrait.position = initial_portrait_pos
			portrait.rotation = 0
			portrait.modulate = base_portrait_color
			portrait.scale = base_portrait_scale
			choice_left_container.modulate = left_target
			choice_right_container.modulate = right_target
			reset_tween = null
		)

func play_draw_animation():
	if entry_tween and entry_tween.is_running():
		entry_tween.kill()
	entry_tween = null
	portrait.scale = base_portrait_scale
	portrait.modulate = base_portrait_color
	portrait.scale = Vector2(base_portrait_scale.x * 0.05, base_portrait_scale.y)
	portrait.modulate.a = 0.0
	entry_tween = create_tween()
	entry_tween.set_trans(Tween.TRANS_SINE)
	entry_tween.set_ease(Tween.EASE_OUT)
	entry_tween.tween_property(portrait, "scale", base_portrait_scale, 0.18)
	entry_tween.parallel().tween_property(portrait, "modulate:a", base_portrait_color.a, 0.18)
	entry_tween.finished.connect(func():
		if entry_tween:
			portrait.scale = base_portrait_scale
			portrait.modulate = base_portrait_color
			entry_tween = null
	)
