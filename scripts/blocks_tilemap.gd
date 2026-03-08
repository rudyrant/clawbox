extends TileMap

const TILE_SIZE := Vector2i(16, 16)
const WORLD_WIDTH := 96
const WORLD_HEIGHT := 40
const BASE_SURFACE_Y := 12
const SURFACE_VARIATION := 3
const DIRT_DEPTH := 3

const SOURCE_ID := 0
const TILE_GRASS := Vector2i(0, 0)
const TILE_DIRT := Vector2i(1, 0)
const TILE_STONE := Vector2i(2, 0)
const DROPPED_ITEM_SCENE := preload("res://items/dropped_item.tscn")

signal world_changed

@onready var _player: CharacterBody2D = get_node_or_null("../Player")
@onready var _player_collision_shape: CollisionShape2D = _player.get_node_or_null("CollisionShape2D") if _player != null else null

func _ready() -> void:
	if tile_set == null:
		tile_set = _build_tileset()

	_build_level()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place_block_from_screen_position(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_break_block_from_screen_position(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_place_block_from_screen_position(event.position)

func generate_default_world() -> void:
	_build_level()

func get_world_state() -> Dictionary:
	var cells: Array = []
	for cell in get_used_cells(0):
		var source_id := get_cell_source_id(0, cell)
		if source_id == -1:
			continue
		var atlas_coords := get_cell_atlas_coords(0, cell)
		cells.append({
			"x": cell.x,
			"y": cell.y,
			"source_id": source_id,
			"atlas_x": atlas_coords.x,
			"atlas_y": atlas_coords.y
		})
	return {
		"cells": cells
	}

func load_world_state(data: Dictionary) -> bool:
	if not data.has("cells"):
		return false
	var cells_variant = data.get("cells")
	if not (cells_variant is Array):
		return false

	clear()
	for cell_data in cells_variant:
		if not (cell_data is Dictionary):
			continue

		var x := int(cell_data.get("x", 0))
		var y := int(cell_data.get("y", 0))
		var source_id := int(cell_data.get("source_id", SOURCE_ID))
		var atlas_x := int(cell_data.get("atlas_x", -1))
		var atlas_y := int(cell_data.get("atlas_y", -1))
		if atlas_x < 0 or atlas_y < 0:
			continue

		set_cell(0, Vector2i(x, y), source_id, Vector2i(atlas_x, atlas_y))

	return true

func _build_tileset() -> TileSet:
	var generated_tileset := TileSet.new()
	generated_tileset.add_physics_layer()

	var source := TileSetAtlasSource.new()
	var image := Image.create(TILE_SIZE.x * 3, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(0, 0, TILE_SIZE.x, TILE_SIZE.y), Color(0.34, 0.72, 0.29, 1.0)) # grass
	image.fill_rect(Rect2i(TILE_SIZE.x, 0, TILE_SIZE.x, TILE_SIZE.y), Color(0.53, 0.35, 0.2, 1.0)) # dirt
	image.fill_rect(Rect2i(TILE_SIZE.x * 2, 0, TILE_SIZE.x, TILE_SIZE.y), Color(0.38, 0.38, 0.42, 1.0)) # stone
	var texture := ImageTexture.create_from_image(image)

	source.texture = texture
	source.texture_region_size = TILE_SIZE
	source.create_tile(TILE_GRASS)
	source.create_tile(TILE_DIRT)
	source.create_tile(TILE_STONE)

	generated_tileset.add_source(source, SOURCE_ID)

	for atlas_coords in [TILE_GRASS, TILE_DIRT, TILE_STONE]:
		var tile_data := source.get_tile_data(atlas_coords, 0)
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(
			0,
			0,
			PackedVector2Array([
				Vector2(0, 0),
				Vector2(TILE_SIZE.x, 0),
				Vector2(TILE_SIZE.x, TILE_SIZE.y),
				Vector2(0, TILE_SIZE.y)
			])
		)

	return generated_tileset

func _build_level() -> void:
	clear()
	var terrain_noise := FastNoiseLite.new()
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	terrain_noise.seed = 1337
	terrain_noise.frequency = 0.08

	for x in range(WORLD_WIDTH):
		var noise_height := int(round(terrain_noise.get_noise_1d(float(x)) * SURFACE_VARIATION))
		var surface_y := BASE_SURFACE_Y + noise_height

		for y in range(surface_y, WORLD_HEIGHT):
			var atlas_coords := TILE_STONE
			if y == surface_y:
				atlas_coords = TILE_GRASS
			elif y <= surface_y + DIRT_DEPTH:
				atlas_coords = TILE_DIRT

			set_cell(0, Vector2i(x, y), SOURCE_ID, atlas_coords)

func _break_block_from_screen_position(screen_position: Vector2) -> void:
	var world_position := get_viewport().get_canvas_transform().affine_inverse() * screen_position
	var cell := local_to_map(to_local(world_position))
	var source_id := get_cell_source_id(0, cell)
	if source_id == -1:
		return
	var atlas_coords := get_cell_atlas_coords(0, cell)

	erase_cell(0, cell)
	_spawn_dropped_item(cell, _item_id_from_atlas_coords(atlas_coords))
	world_changed.emit()

func _place_block_from_screen_position(screen_position: Vector2) -> void:
	var world_position := get_viewport().get_canvas_transform().affine_inverse() * screen_position
	var cell := local_to_map(to_local(world_position))
	if get_cell_source_id(0, cell) != -1:
		return
	if _would_overlap_player(cell):
		return

	if _player == null or not _player.has_method("get_selected_item_id") or not _player.has_method("consume_selected_item"):
		return

	var selected_item_id: StringName = _player.get_selected_item_id()
	var atlas_coords := _atlas_coords_from_item_id(selected_item_id)
	if atlas_coords.x < 0:
		return
	if not _player.consume_selected_item(1):
		return

	set_cell(0, cell, SOURCE_ID, atlas_coords)
	world_changed.emit()

func _spawn_dropped_item(cell: Vector2i, item_id: StringName) -> void:
	if item_id == &"":
		return
	var dropped_item := DROPPED_ITEM_SCENE.instantiate()
	dropped_item.global_position = to_global(map_to_local(cell))
	dropped_item.item_id = item_id
	get_parent().add_child(dropped_item)

func _would_overlap_player(cell: Vector2i) -> bool:
	if _player_collision_shape == null:
		return false
	var rectangle_shape := _player_collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		return false

	var cell_center_global := to_global(map_to_local(cell))
	var half_tile_size := Vector2(TILE_SIZE) * 0.5
	var cell_rect := Rect2(cell_center_global - half_tile_size, Vector2(TILE_SIZE))
	var player_rect := Rect2(
		_player_collision_shape.global_position - rectangle_shape.size * 0.5,
		rectangle_shape.size
	)
	return cell_rect.intersects(player_rect)

func _item_id_from_atlas_coords(atlas_coords: Vector2i) -> StringName:
	if atlas_coords == TILE_GRASS:
		return &"grass"
	if atlas_coords == TILE_DIRT:
		return &"dirt"
	if atlas_coords == TILE_STONE:
		return &"stone"
	return &""

func _atlas_coords_from_item_id(item_id: StringName) -> Vector2i:
	if item_id == &"grass":
		return TILE_GRASS
	if item_id == &"dirt":
		return TILE_DIRT
	if item_id == &"stone":
		return TILE_STONE
	return Vector2i(-1, -1)
