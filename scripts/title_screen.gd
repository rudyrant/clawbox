extends Control

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

@onready var _start_button: Button = %StartButton
@onready var _quit_button: Button = %QuitButton
@onready var _menu_panel: PanelContainer = $Center/MenuPanel
@onready var _title_label: Label = $Center/MenuPanel/Margin/VBox/Title
@onready var _subtitle_label: Label = $Center/MenuPanel/Margin/VBox/Subtitle

func _ready() -> void:
	_start_button.pressed.connect(_on_start_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)
	_quit_button.visible = _can_quit_game()
	get_viewport().size_changed.connect(_apply_layout_scaling)
	_apply_layout_scaling()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func _on_quit_button_pressed() -> void:
	if _can_quit_game():
		get_tree().quit()

func _can_quit_game() -> bool:
	return not OS.has_feature("web") and not OS.has_feature("android") and not OS.has_feature("ios")

func _apply_layout_scaling() -> void:
	var viewport_size := get_viewport_rect().size
	var short_side := min(viewport_size.x, viewport_size.y)
	var scale_factor := clamp(short_side / 360.0, 0.85, 1.9)

	_menu_panel.custom_minimum_size.x = clamp(viewport_size.x * 0.7, 260.0, 460.0)
	_title_label.add_theme_font_size_override("font_size", int(clamp(36.0 * scale_factor, 28.0, 56.0)))
	_subtitle_label.add_theme_font_size_override("font_size", int(clamp(16.0 * scale_factor, 14.0, 24.0)))

	var button_height := clamp(56.0 * scale_factor, 48.0, 88.0)
	var button_font := int(clamp(20.0 * scale_factor, 16.0, 30.0))
	_start_button.custom_minimum_size.y = button_height
	_quit_button.custom_minimum_size.y = button_height
	_start_button.add_theme_font_size_override("font_size", button_font)
	_quit_button.add_theme_font_size_override("font_size", button_font)
