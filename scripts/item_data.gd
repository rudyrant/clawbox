extends RefCounted

const EMPTY_ITEM_ID: StringName = &""

const ID_GRASS: StringName = &"grass"
const ID_DIRT: StringName = &"dirt"
const ID_STONE: StringName = &"stone"
const ID_WOOD: StringName = &"wood"
const ID_IRON_ORE: StringName = &"iron_ore"

const UNKNOWN_ITEM_COLOR := Color(0.98, 0.87, 0.2, 1.0)
const INVALID_ATLAS_COORDS := Vector2i(-1, -1)

const _ITEMS := {
	ID_GRASS: {
		"display_name": "Grass",
		"atlas_coords": Vector2i(0, 0),
		"color": Color(0.34, 0.72, 0.29, 1.0)
	},
	ID_DIRT: {
		"display_name": "Dirt",
		"atlas_coords": Vector2i(1, 0),
		"color": Color(0.53, 0.35, 0.2, 1.0)
	},
	ID_STONE: {
		"display_name": "Stone",
		"atlas_coords": Vector2i(2, 0),
		"color": Color(0.38, 0.38, 0.42, 1.0)
	},
	ID_WOOD: {
		"display_name": "Wood",
		"atlas_coords": Vector2i(3, 0),
		"color": Color(0.56, 0.39, 0.21, 1.0)
	},
	ID_IRON_ORE: {
		"display_name": "Iron Ore",
		"atlas_coords": Vector2i(4, 0),
		"color": Color(0.62, 0.55, 0.44, 1.0)
	}
}

const _PLACEABLE_ITEM_IDS: Array[StringName] = [
	ID_GRASS,
	ID_DIRT,
	ID_STONE,
	ID_WOOD,
	ID_IRON_ORE
]

static func get_placeable_item_ids() -> Array[StringName]:
	return _PLACEABLE_ITEM_IDS.duplicate()

static func get_atlas_coords(item_id: StringName) -> Vector2i:
	if not _ITEMS.has(item_id):
		return INVALID_ATLAS_COORDS
	return _ITEMS[item_id]["atlas_coords"]

static func get_item_id_from_atlas_coords(atlas_coords: Vector2i) -> StringName:
	for item_id in _PLACEABLE_ITEM_IDS:
		if _ITEMS[item_id]["atlas_coords"] == atlas_coords:
			return item_id
	return EMPTY_ITEM_ID

static func get_color(item_id: StringName) -> Color:
	if not _ITEMS.has(item_id):
		return UNKNOWN_ITEM_COLOR
	return _ITEMS[item_id]["color"]

static func get_display_name(item_id: StringName) -> String:
	if item_id == EMPTY_ITEM_ID:
		return "-"
	if not _ITEMS.has(item_id):
		var item_text := str(item_id)
		return "-" if item_text.is_empty() else item_text.capitalize()
	return _ITEMS[item_id]["display_name"]
