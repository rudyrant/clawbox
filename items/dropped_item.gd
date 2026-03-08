extends Area2D

const ITEM_DATA := preload("res://scripts/item_data.gd")

@export var item_id: StringName = ITEM_DATA.ID_DIRT
@export var amount: int = 1

@onready var _visual: Polygon2D = $Visual

func _ready() -> void:
	_apply_visual_style()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("collect_item"):
		body.collect_item(item_id, amount)
		queue_free()

func _apply_visual_style() -> void:
	if _visual == null:
		return
	_visual.color = ITEM_DATA.get_color(item_id)
