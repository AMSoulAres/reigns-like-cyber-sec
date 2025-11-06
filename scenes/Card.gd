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
	_reset_card_visuals()
	
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


const SWIPE_THRESHOLD = 150 # Distância em pixels para confirmar um deslize[cite: 27].
const ROTATION_FACTOR = 0.005 # Quão rápido o cartão gira ao ser arrastado[cite: 27].
var is_dragging = false
var initial_mouse_pos = Vector2.ZERO

func _ready():
	initial_portrait_pos = portrait.position
	_center_portrait_pivot()

func _center_portrait_pivot():
	var base_size = portrait.size
	if base_size == Vector2.ZERO and portrait.texture:
		base_size = portrait.texture.get_size()
	if base_size != Vector2.ZERO:
		portrait.pivot_offset = base_size * 0.5

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
	var limited_offset_x = clamp(drag_offset.x, -SWIPE_THRESHOLD, SWIPE_THRESHOLD)
	portrait.position = initial_portrait_pos + Vector2(limited_offset_x, 0)
	portrait.rotation = limited_offset_x * ROTATION_FACTOR

	var swipe_progress = clamp(abs(drag_offset.x) / SWIPE_THRESHOLD, 0, 1)
	if drag_offset.x < 0:
		choice_left_container.modulate.a = swipe_progress
		choice_right_container.modulate.a = 0
	else:
		choice_right_container.modulate.a = swipe_progress
		choice_left_container.modulate.a = 0

func process_swipe():
	var final_delta_x = drag_offset.x
	
	# Verifica se o deslize excedeu o limiar para a esquerda.
	if final_delta_x < -SWIPE_THRESHOLD:
		card_resolved.emit(card_data, "left")
		queue_free()
	# Verifica se o deslize excedeu o limiar para a direita.
	elif final_delta_x > SWIPE_THRESHOLD:
		card_resolved.emit(card_data, "right")
		queue_free()
	else:
		_reset_card_visuals()

func _reset_card_visuals():
	drag_offset = Vector2.ZERO
	if initial_portrait_pos == Vector2.ZERO:
		initial_portrait_pos = portrait.position
	portrait.position = initial_portrait_pos
	portrait.rotation = 0
	choice_left_container.modulate.a = 0
	choice_right_container.modulate.a = 0
