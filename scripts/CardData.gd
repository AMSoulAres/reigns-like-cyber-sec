# CardData.gd
extends Resource
class_name CardData

@export var card_id: String = ""
@export var character: String = "Personagem Desconhecido"
@export var portrait: Texture2D
@export_multiline var dialogue: String = "Texto da decisão aqui..."

@export_group("Questline")
@export var questline_id: String = ""
@export_range(0, 99, 1, "or_greater") var quest_step: int = 0
@export var available_from_start: bool = true
@export var reshuffle_after_use: bool = true

@export_group("Choice Labels")
@export var choice_left_text: String = "Opção Esquerda"
@export var choice_right_text: String = "Opção Direita"

@export_group("Choice Effects")
@export var effects_left: Dictionary = {}
@export var effects_right: Dictionary = {}

@export_group("Choice Left Flow")
@export var next_card_id_left: String = ""
@export_range(0, 10, 1, "or_greater") var next_card_delay_left: int = 0
@export var game_over_left: bool = false
@export var game_over_left_reason: String = ""

@export_group("Choice Right Flow")
@export var next_card_id_right: String = ""
@export_range(0, 10, 1, "or_greater") var next_card_delay_right: int = 0
@export var game_over_right: bool = false
@export var game_over_right_reason: String = ""
