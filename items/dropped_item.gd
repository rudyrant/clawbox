extends Area2D

@export var item_id: StringName = &"block"
@export var amount: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("collect_item"):
		body.collect_item(item_id, amount)
		queue_free()
