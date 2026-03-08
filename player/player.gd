extends CharacterBody2D

const SPEED: float = 300.0
const JUMP_VELOCITY: float = -450.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var collected_items: int = 0

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

func collect_item(item_id: StringName, amount: int = 1) -> void:
	collected_items += amount
	print("Picked up %s x%d (total: %d)" % [str(item_id), amount, collected_items])
