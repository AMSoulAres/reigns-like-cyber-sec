extends Control

@onready var reason_label: Label = %ReasonLabel
@onready var restart_button: Button = %RestartButton

func _ready():
	var reason_text := GameState.last_game_over_reason
	if reason_text.strip_edges() == "":
		reason_text = "O jogo terminou."
	if reason_label:
		reason_label.text = reason_text
	if restart_button and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed():
	GameState.reset_state()
	GameState.money = 50
	GameState.sec = 50
	GameState.moral = 50
	GameState.reputation = 50
	get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")