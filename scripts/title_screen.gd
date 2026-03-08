extends Control

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

@onready var _start_button: Button = %StartButton
@onready var _quit_button: Button = %QuitButton

func _ready() -> void:
	_start_button.pressed.connect(_on_start_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)
	_quit_button.visible = _can_quit_game()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func _on_quit_button_pressed() -> void:
	if _can_quit_game():
		get_tree().quit()

func _can_quit_game() -> bool:
	return not OS.has_feature("web") and not OS.has_feature("android") and not OS.has_feature("ios")
