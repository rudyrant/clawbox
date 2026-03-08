extends Area2D

@export var item_id: StringName = &"dirt"
@export var amount: int = 1

const ITEM_COLORS := {
	&"grass": Color(0.34, 0.72, 0.29, 1.0),
	&"dirt": Color(0.53, 0.35, 0.2, 1.0),
	&"stone": Color(0.38, 0.38, 0.42, 1.0),
	&"wood": Color(0.56, 0.39, 0.21, 1.0),
	&"iron_ore": Color(0.62, 0.55, 0.44, 1.0)
}

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
	_visual.color = ITEM_COLORS.get(item_id, Color(0.98, 0.87, 0.2, 1.0))
