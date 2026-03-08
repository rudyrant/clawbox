extends Control

@export var player_path: NodePath = NodePath("../../Player")
@export var blocks_path: NodePath = NodePath("../../Blocks")

const ACTION_REPEAT_INTERVAL := 0.12
const INITIAL_OVERLAY_DURATION := 4.0

var _player: Node = null
var _blocks: Node = null

var _left_button: Button
var _right_button: Button
var _jump_button: Button
var _mine_button: Button
var _place_button: Button
var _overlay_toggle_button: Button
var _controls_overlay_panel: PanelContainer
var _controls_overlay_label: Label

var _left_held := false
var _right_held := false
var _mine_held := false
var _place_held := false

var _mine_repeat_timer := 0.0
var _place_repeat_timer := 0.0
var _initial_overlay_active := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_buttons()
	_connect_world_nodes()
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()
	_show_initial_controls_overlay()

func _input(event: InputEvent) -> void:
	if not _initial_overlay_active:
		return
	if event is InputEventScreenTouch and event.pressed:
		_dismiss_initial_controls_overlay()
	elif event is InputEventMouseButton and event.pressed:
		_dismiss_initial_controls_overlay()
	elif event is InputEventKey and event.pressed:
		_dismiss_initial_controls_overlay()

func _process(delta: float) -> void:
	if _mine_held:
		_mine_repeat_timer -= delta
		if _mine_repeat_timer <= 0.0:
			_try_break_block()
			_mine_repeat_timer = ACTION_REPEAT_INTERVAL
	if _place_held:
		_place_repeat_timer -= delta
		if _place_repeat_timer <= 0.0:
			_try_place_block()
			_place_repeat_timer = ACTION_REPEAT_INTERVAL

func _create_buttons() -> void:
	_left_button = _make_button("Left")
	_right_button = _make_button("Right")
	_jump_button = _make_button("Jump")
	_mine_button = _make_button("Mine")
	_place_button = _make_button("Place")
	_overlay_toggle_button = _make_button("Controls")

	add_child(_left_button)
	add_child(_right_button)
	add_child(_jump_button)
	add_child(_mine_button)
	add_child(_place_button)
	add_child(_overlay_toggle_button)
	_create_controls_overlay()

	_left_button.button_down.connect(_on_left_down)
	_left_button.button_up.connect(_on_left_up)
	_right_button.button_down.connect(_on_right_down)
	_right_button.button_up.connect(_on_right_up)

	_jump_button.pressed.connect(_on_jump_pressed)

	_mine_button.button_down.connect(_on_mine_down)
	_mine_button.button_up.connect(_on_mine_up)
	_place_button.button_down.connect(_on_place_down)
	_place_button.button_up.connect(_on_place_up)
	_overlay_toggle_button.pressed.connect(_on_toggle_controls_overlay)

func _create_controls_overlay() -> void:
	_controls_overlay_panel = PanelContainer.new()
	_controls_overlay_panel.visible = false
	_controls_overlay_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_controls_overlay_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	_controls_overlay_panel.add_child(margin)

	_controls_overlay_label = Label.new()
	_controls_overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_overlay_label.text = "Mobile Controls\nLeft side: virtual joystick / D-pad for movement.\nRight side: Jump, Mine, Place buttons.\nTap Bag to open/close inventory."
	margin.add_child(_controls_overlay_label)

func _show_initial_controls_overlay() -> void:
	if _controls_overlay_panel == null:
		return
	_controls_overlay_panel.visible = true
	_overlay_toggle_button.text = "Hide"
	_initial_overlay_active = true
	_auto_hide_initial_controls_overlay()

func _auto_hide_initial_controls_overlay() -> void:
	await get_tree().create_timer(INITIAL_OVERLAY_DURATION).timeout
	_dismiss_initial_controls_overlay()

func _dismiss_initial_controls_overlay() -> void:
	if not _initial_overlay_active:
		return
	_initial_overlay_active = false
	if _controls_overlay_panel != null:
		_controls_overlay_panel.visible = false
	_overlay_toggle_button.text = "Controls"

func _make_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = Color(1.0, 1.0, 1.0, 0.94)
	return button

func _connect_world_nodes() -> void:
	_player = get_node_or_null(player_path)
	_blocks = get_node_or_null(blocks_path)

func _apply_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var short_side := min(viewport_size.x, viewport_size.y)
	var scale_factor := clamp(short_side / 360.0, 0.9, 1.8)

	var move_size := clamp(64.0 * scale_factor, 52.0, 104.0)
	var action_width := clamp(84.0 * scale_factor, 68.0, 140.0)
	var action_height := clamp(56.0 * scale_factor, 48.0, 100.0)
	var toggle_width := clamp(96.0 * scale_factor, 80.0, 160.0)
	var toggle_height := clamp(44.0 * scale_factor, 38.0, 80.0)
	var overlay_width := clamp(viewport_size.x * 0.72, 220.0, 560.0)
	var margin := clamp(16.0 * scale_factor, 12.0, 30.0)
	var gap := clamp(8.0 * scale_factor, 6.0, 14.0)
	var safe_bottom := margin + clamp(96.0 * scale_factor, 88.0, 150.0)
	var font_size := int(clamp(14.0 * scale_factor, 12.0, 24.0))

	_left_button.custom_minimum_size = Vector2(move_size, move_size)
	_right_button.custom_minimum_size = Vector2(move_size, move_size)
	_jump_button.custom_minimum_size = Vector2(action_width, action_height)
	_mine_button.custom_minimum_size = Vector2(action_width, action_height)
	_place_button.custom_minimum_size = Vector2(action_width, action_height)
	_overlay_toggle_button.custom_minimum_size = Vector2(toggle_width, toggle_height)

	_left_button.position = Vector2(margin, viewport_size.y - safe_bottom)
	_right_button.position = Vector2(margin + move_size + gap, viewport_size.y - safe_bottom)

	_place_button.position = Vector2(viewport_size.x - margin - action_width, viewport_size.y - safe_bottom)
	_mine_button.position = Vector2(viewport_size.x - margin - action_width, _place_button.position.y - action_height - gap)
	_jump_button.position = Vector2(viewport_size.x - margin - action_width, _mine_button.position.y - action_height - gap)
	_overlay_toggle_button.position = Vector2(viewport_size.x - margin - toggle_width, margin)

	_controls_overlay_panel.custom_minimum_size = Vector2(overlay_width, 0.0)
	_controls_overlay_panel.position = Vector2((viewport_size.x - overlay_width) * 0.5, margin + toggle_height + gap)

	_left_button.add_theme_font_size_override("font_size", font_size)
	_right_button.add_theme_font_size_override("font_size", font_size)
	_jump_button.add_theme_font_size_override("font_size", font_size)
	_mine_button.add_theme_font_size_override("font_size", font_size)
	_place_button.add_theme_font_size_override("font_size", font_size)
	_overlay_toggle_button.add_theme_font_size_override("font_size", font_size)
	if _controls_overlay_label != null:
		_controls_overlay_label.add_theme_font_size_override("font_size", font_size)

func _on_left_down() -> void:
	_left_held = true
	_update_move_input()

func _on_left_up() -> void:
	_left_held = false
	_update_move_input()

func _on_right_down() -> void:
	_right_held = true
	_update_move_input()

func _on_right_up() -> void:
	_right_held = false
	_update_move_input()

func _update_move_input() -> void:
	if _player == null or not _player.has_method("set_move_input"):
		return

	var move_input := 0.0
	if _left_held and not _right_held:
		move_input = -1.0
	elif _right_held and not _left_held:
		move_input = 1.0

	_player.set_move_input(move_input)

func _on_jump_pressed() -> void:
	if _player == null or not _player.has_method("request_jump"):
		return
	_player.request_jump()

func _on_mine_down() -> void:
	_mine_held = true
	_try_break_block()
	_mine_repeat_timer = ACTION_REPEAT_INTERVAL

func _on_mine_up() -> void:
	_mine_held = false

func _on_place_down() -> void:
	_place_held = true
	_try_place_block()
	_place_repeat_timer = ACTION_REPEAT_INTERVAL

func _on_place_up() -> void:
	_place_held = false

func _try_break_block() -> void:
	if _blocks == null or not _blocks.has_method("break_targeted_block"):
		return
	_blocks.break_targeted_block()

func _try_place_block() -> void:
	if _blocks == null or not _blocks.has_method("place_targeted_block"):
		return
	_blocks.place_targeted_block()

func _on_toggle_controls_overlay() -> void:
	if _controls_overlay_panel == null:
		return
	_initial_overlay_active = false
	_controls_overlay_panel.visible = not _controls_overlay_panel.visible
	_overlay_toggle_button.text = "Hide" if _controls_overlay_panel.visible else "Controls"
