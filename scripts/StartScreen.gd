extends Control

func _ready():
	# Connect buttons if they exist, or wait for them to be pressed via editor signals
	# But since we are creating the scene programmatically, we might rely on node paths
	pass

func _on_play_pressed():
	GameState.tutorial_active = false
	GameState.gallery_active = false
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_tutorial_pressed():
	GameState.tutorial_active = true
	GameState.gallery_active = false
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_gallery_pressed():
	GameState.tutorial_active = false
	GameState.gallery_active = true
	get_tree().change_scene_to_file("res://Main.tscn")
