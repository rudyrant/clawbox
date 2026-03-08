extends Control

const ITEM_DATA := preload("res://scripts/item_data.gd")

const HOTBAR_SIZE := 5
const EMPTY_ITEM_ID: StringName = ITEM_DATA.EMPTY_ITEM_ID

@export var player_path: NodePath = NodePath("../../Player")

@onready var _inventory_panel: PanelContainer = $InventoryPanel
@onready var _inventory_list: VBoxContainer = $InventoryPanel/Margin/VBox
@onready var _hotbar_panel: PanelContainer = $HotbarPanel
@onready var _hotbar_row: HBoxContainer = $HotbarPanel/Margin/HotbarRow
@onready var _inventory_toggle_button: Button = $InventoryToggleButton

var _player: Node = null
var _hotbar_buttons: Array[Button] = []
var _inventory_snapshot: Dictionary = {}

func _ready() -> void:
	_create_hotbar_buttons()
	_connect_player()
	_inventory_toggle_button.pressed.connect(_on_inventory_toggle_pressed)
	_inventory_panel.visible = false
	get_viewport().size_changed.connect(_apply_layout_scaling)
	_apply_layout_scaling()

func _create_hotbar_buttons() -> void:
	for child in _hotbar_row.get_children():
		child.queue_free()
	_hotbar_buttons.clear()

	for index in range(HOTBAR_SIZE):
		var button := Button.new()
		button.text = str(index + 1)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_hotbar_slot_pressed.bind(index))
		_hotbar_row.add_child(button)
		_hotbar_buttons.append(button)

func _connect_player() -> void:
	_player = get_node_or_null(player_path)
	if _player == null:
		return
	if _player.has_signal("inventory_changed"):
		_player.inventory_changed.connect(_on_inventory_changed)
	if _player.has_signal("selected_hotbar_changed"):
		_player.selected_hotbar_changed.connect(_on_selected_hotbar_changed)
	if _player.has_method("get_inventory_snapshot"):
		_inventory_snapshot = _player.get_inventory_snapshot()
	if _player.has_method("get_hotbar_data") and _player.has_method("get_selected_hotbar_index"):
		_on_inventory_changed(_inventory_snapshot, _player.get_hotbar_data(), _player.get_selected_hotbar_index())
	else:
		_refresh_inventory_list()

func _on_inventory_changed(inventory: Dictionary, hotbar: Array, selected_index: int) -> void:
	var inventory_changed := inventory != _inventory_snapshot
	_inventory_snapshot = inventory.duplicate()
	_refresh_hotbar_buttons(hotbar, selected_index)
	if inventory_changed or _inventory_list.get_child_count() == 0:
		_refresh_inventory_list()

func _refresh_hotbar_buttons(hotbar: Array, selected_index: int) -> void:
	for slot_index in range(HOTBAR_SIZE):
		if slot_index >= _hotbar_buttons.size():
			break
		var button := _hotbar_buttons[slot_index]
		var item_id: StringName = EMPTY_ITEM_ID
		var count := 0
		if slot_index < hotbar.size():
			var slot_variant = hotbar[slot_index]
			if slot_variant is Dictionary:
				var slot_data := slot_variant as Dictionary
				item_id = slot_data.get("item_id", EMPTY_ITEM_ID)
				count = int(slot_data.get("count", 0))

		var name_text := "-"
		if item_id != EMPTY_ITEM_ID:
			name_text = _display_name(item_id)
		button.text = "%d\n%s\nx%d" % [slot_index + 1, name_text, count]
		button.modulate = Color(1.0, 1.0, 1.0, 1.0) if slot_index == selected_index else Color(0.8, 0.8, 0.8, 0.95)

func _on_selected_hotbar_changed(selected_index: int) -> void:
	if _player == null:
		return
	if _player.has_method("get_hotbar_data"):
		_refresh_hotbar_buttons(_player.get_hotbar_data(), selected_index)

func _refresh_inventory_list() -> void:
	for child in _inventory_list.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "Inventory"
	_inventory_list.add_child(title)

	if _inventory_snapshot.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Empty"
		_inventory_list.add_child(empty_label)
		return

	var sorted_ids := _inventory_snapshot.keys()
	sorted_ids.sort()
	for item_id in sorted_ids:
		var row := Label.new()
		row.text = "%s x%d" % [_display_name(item_id), int(_inventory_snapshot[item_id])]
		_inventory_list.add_child(row)

func _on_hotbar_slot_pressed(slot_index: int) -> void:
	if _player == null:
		return
	if _player.has_method("select_hotbar_slot"):
		_player.select_hotbar_slot(slot_index)

func _on_inventory_toggle_pressed() -> void:
	_inventory_panel.visible = not _inventory_panel.visible
	_inventory_toggle_button.text = "Hide" if _inventory_panel.visible else "Bag"

func _apply_layout_scaling() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var short_side: float = min(viewport_size.x, viewport_size.y)
	var scale_factor: float = clamp(short_side / 360.0, 0.85, 1.8)

	var slot_size: float = clamp(54.0 * scale_factor, 44.0, 92.0)
	var slot_height: float = clamp(64.0 * scale_factor, 52.0, 108.0)
	var gap: float = clamp(6.0 * scale_factor, 4.0, 12.0)
	var margin: float = clamp(12.0 * scale_factor, 10.0, 24.0)
	var button_font_size := int(clamp(11.0 * scale_factor, 10.0, 18.0))
	var panel_font_size := int(clamp(15.0 * scale_factor, 12.0, 22.0))

	_hotbar_row.add_theme_constant_override("separation", int(round(gap)))
	for button in _hotbar_buttons:
		button.custom_minimum_size = Vector2(slot_size, slot_height)
		button.add_theme_font_size_override("font_size", button_font_size)

	var hotbar_width: float = HOTBAR_SIZE * slot_size + (HOTBAR_SIZE - 1) * gap + margin * 2.0
	var hotbar_height: float = slot_height + margin * 2.0
	_hotbar_panel.anchor_left = 0.5
	_hotbar_panel.anchor_right = 0.5
	_hotbar_panel.anchor_top = 1.0
	_hotbar_panel.anchor_bottom = 1.0
	_hotbar_panel.offset_left = -hotbar_width * 0.5
	_hotbar_panel.offset_right = hotbar_width * 0.5
	_hotbar_panel.offset_top = -hotbar_height - margin
	_hotbar_panel.offset_bottom = -margin

	_inventory_panel.anchor_left = 0.0
	_inventory_panel.anchor_right = 0.0
	_inventory_panel.anchor_top = 0.0
	_inventory_panel.anchor_bottom = 0.0
	_inventory_panel.offset_left = margin
	_inventory_panel.offset_top = margin
	_inventory_panel.offset_right = margin + clamp(160.0 * scale_factor, 150.0, 280.0)
	_inventory_panel.offset_bottom = margin + minf(clamp(140.0 * scale_factor, 130.0, 320.0), viewport_size.y * 0.55)

	_inventory_toggle_button.anchor_left = 1.0
	_inventory_toggle_button.anchor_right = 1.0
	_inventory_toggle_button.anchor_top = 0.0
	_inventory_toggle_button.anchor_bottom = 0.0
	var toggle_width := clamp(86.0 * scale_factor, 72.0, 130.0)
	var toggle_height := clamp(44.0 * scale_factor, 40.0, 72.0)
	_inventory_toggle_button.offset_left = -margin - toggle_width
	_inventory_toggle_button.offset_right = -margin
	_inventory_toggle_button.offset_top = margin
	_inventory_toggle_button.offset_bottom = margin + toggle_height
	_inventory_toggle_button.custom_minimum_size = Vector2(toggle_width, toggle_height)
	_inventory_toggle_button.add_theme_font_size_override("font_size", panel_font_size)

func _display_name(item_id: StringName) -> String:
	return ITEM_DATA.get_display_name(item_id)
