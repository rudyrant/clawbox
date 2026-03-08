extends Control

const HOTBAR_SIZE := 5
const EMPTY_ITEM_ID: StringName = &""

@export var player_path: NodePath = NodePath("../../Player")

@onready var _inventory_panel: PanelContainer = $InventoryPanel
@onready var _inventory_list: VBoxContainer = $InventoryPanel/Margin/VBox
@onready var _hotbar_panel: PanelContainer = $HotbarPanel
@onready var _hotbar_row: HBoxContainer = $HotbarPanel/Margin/HotbarRow

var _player: Node = null
var _hotbar_buttons: Array[Button] = []
var _inventory_snapshot: Dictionary = {}

func _ready() -> void:
	_create_hotbar_buttons()
	_connect_player()
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

func _on_inventory_changed(inventory: Dictionary, hotbar: Array, selected_index: int) -> void:
	_inventory_snapshot = inventory
	for slot_index in range(HOTBAR_SIZE):
		if slot_index >= _hotbar_buttons.size():
			break
		var button := _hotbar_buttons[slot_index]
		var item_id: StringName = EMPTY_ITEM_ID
		var count := 0
		if slot_index < hotbar.size():
			var slot_data: Dictionary = hotbar[slot_index]
			item_id = slot_data.get("item_id", EMPTY_ITEM_ID)
			count = int(slot_data.get("count", 0))

		var name_text := "-"
		if item_id != EMPTY_ITEM_ID:
			name_text = _display_name(item_id)
		button.text = "%d\n%s\nx%d" % [slot_index + 1, name_text, count]
		button.modulate = Color(1.0, 1.0, 1.0, 1.0) if slot_index == selected_index else Color(0.8, 0.8, 0.8, 0.95)

	_refresh_inventory_list()

func _on_selected_hotbar_changed(selected_index: int) -> void:
	if _player == null:
		return
	if _player.has_method("get_hotbar_data"):
		_on_inventory_changed(_inventory_snapshot, _player.get_hotbar_data(), selected_index)

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

func _apply_layout_scaling() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var short_side: float = min(viewport_size.x, viewport_size.y)
	var scale_factor: float = clamp(short_side / 360.0, 0.85, 1.8)

	var slot_size: float = clamp(54.0 * scale_factor, 44.0, 92.0)
	var gap: float = clamp(6.0 * scale_factor, 4.0, 12.0)
	var margin: float = clamp(12.0 * scale_factor, 10.0, 24.0)

	_hotbar_row.add_theme_constant_override("separation", int(round(gap)))
	for button in _hotbar_buttons:
		button.custom_minimum_size = Vector2(slot_size, slot_size)

	var hotbar_width: float = HOTBAR_SIZE * slot_size + (HOTBAR_SIZE - 1) * gap + margin * 2.0
	var hotbar_height: float = slot_size + margin * 2.0
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
	_inventory_panel.offset_bottom = margin + clamp(120.0 * scale_factor, 110.0, 260.0)

func _display_name(item_id: StringName) -> String:
	if item_id == EMPTY_ITEM_ID:
		return "-"
	var item_text := str(item_id)
	if item_text.is_empty():
		return "-"
	return item_text.capitalize()
