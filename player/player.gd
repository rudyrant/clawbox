extends CharacterBody2D

const SPEED: float = 300.0
const JUMP_VELOCITY: float = -450.0
const HOTBAR_SIZE := 5
const EMPTY_ITEM_ID: StringName = &""
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

signal inventory_changed(inventory: Dictionary, hotbar: Array, selected_index: int)
signal selected_hotbar_changed(selected_index: int)

var inventory: Dictionary = {}
var hotbar: Array[StringName] = []
var selected_hotbar_index: int = 0

func _ready() -> void:
	hotbar.resize(HOTBAR_SIZE)
	for index in range(HOTBAR_SIZE):
		hotbar[index] = EMPTY_ITEM_ID
	_emit_inventory_changed()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction: float = Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * delta)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		match key_event.keycode:
			KEY_1:
				select_hotbar_slot(0)
			KEY_2:
				select_hotbar_slot(1)
			KEY_3:
				select_hotbar_slot(2)
			KEY_4:
				select_hotbar_slot(3)
			KEY_5:
				select_hotbar_slot(4)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_hotbar_slot(selected_hotbar_index - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_hotbar_slot(selected_hotbar_index + 1)

func collect_item(item_id: StringName, amount: int = 1) -> void:
	if item_id == EMPTY_ITEM_ID or amount <= 0:
		return

	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	_assign_hotbar_slot_if_needed(item_id)
	_emit_inventory_changed()
	print("Picked up %s x%d (new stack: %d)" % [str(item_id), amount, int(inventory[item_id])])

func select_hotbar_slot(index: int) -> void:
	var wrapped_index := wrapi(index, 0, HOTBAR_SIZE)
	if selected_hotbar_index == wrapped_index:
		return

	selected_hotbar_index = wrapped_index
	selected_hotbar_changed.emit(selected_hotbar_index)
	_emit_inventory_changed()

func consume_selected_item(amount: int = 1) -> bool:
	if amount <= 0:
		return true

	var item_id := get_selected_item_id()
	if item_id == EMPTY_ITEM_ID:
		return false

	var remaining := get_item_count(item_id) - amount
	if remaining < 0:
		return false
	if remaining == 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = remaining

	_emit_inventory_changed()
	return true

func get_selected_item_id() -> StringName:
	return hotbar[selected_hotbar_index]

func get_selected_hotbar_index() -> int:
	return selected_hotbar_index

func get_hotbar_data() -> Array:
	var slots: Array = []
	for item_id in hotbar:
		slots.append({
			"item_id": item_id,
			"count": get_item_count(item_id)
		})
	return slots

func get_inventory_snapshot() -> Dictionary:
	return inventory.duplicate()

func get_item_count(item_id: StringName) -> int:
	if item_id == EMPTY_ITEM_ID:
		return 0
	return int(inventory.get(item_id, 0))

func _assign_hotbar_slot_if_needed(item_id: StringName) -> void:
	if hotbar.has(item_id):
		return

	for index in range(HOTBAR_SIZE):
		if hotbar[index] == EMPTY_ITEM_ID:
			hotbar[index] = item_id
			return

func _emit_inventory_changed() -> void:
	inventory_changed.emit(inventory.duplicate(), get_hotbar_data(), selected_hotbar_index)
