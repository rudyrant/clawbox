extends TileMap

const TILE_SIZE := Vector2i(16, 16)
const WORLD_WIDTH := 96
const WORLD_HEIGHT := 40
const BASE_SURFACE_Y := 12
const SURFACE_VARIATION := 3
const DIRT_DEPTH := 3
const TREE_CHANCE := 0.1
const TREE_MIN_HEIGHT := 3
const TREE_MAX_HEIGHT := 6
const CAVE_START_DEPTH := 4
const CAVE_THRESHOLD := 0.43
const MIN_CAVE_NOISE := 0.03
const MAX_CAVE_NOISE := 0.085
const IRON_MIN_DEPTH := 6
const IRON_CHANCE := 0.08
const INTERACTION_REACH_PIXELS := 88.0

const SOURCE_ID := 0
const TILE_GRASS := Vector2i(0, 0)
const TILE_DIRT := Vector2i(1, 0)
const TILE_STONE := Vector2i(2, 0)
const TILE_WOOD := Vector2i(3, 0)
const TILE_IRON_ORE := Vector2i(4, 0)
const DROPPED_ITEM_SCENE := preload("res://items/dropped_item.tscn")
const ITEM_TO_ATLAS := {
	&"grass": TILE_GRASS,
	&"dirt": TILE_DIRT,
	&"stone": TILE_STONE,
	&"wood": TILE_WOOD,
	&"iron_ore": TILE_IRON_ORE
}
const ATLAS_TO_ITEM := {
	TILE_GRASS: &"grass",
	TILE_DIRT: &"dirt",
	TILE_STONE: &"stone",
	TILE_WOOD: &"wood",
	TILE_IRON_ORE: &"iron_ore"
}

signal world_changed

@onready var _player: CharacterBody2D = get_node_or_null("../Player")
@onready var _player_collision_shape: CollisionShape2D = _player.get_node_or_null("CollisionShape2D") if _player != null else null

var _target_cell := Vector2i.ZERO
var _has_target_cell := false

func _ready() -> void:
	if tile_set == null:
		tile_set = _build_tileset()

	_build_level()

func _draw() -> void:
	if not _has_target_cell:
		return

	var tile_center := map_to_local(_target_cell)
	var half_tile_size := Vector2(TILE_SIZE) * 0.5
	var tile_rect := Rect2(tile_center - half_tile_size, Vector2(TILE_SIZE))
	draw_rect(tile_rect, Color(1.0, 1.0, 1.0, 0.75), false, 1.5)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_target_from_screen_position(event.position)
	elif event is InputEventMouseButton and event.pressed:
		_set_target_from_screen_position(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_targeted_block()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			break_targeted_block()
	elif event is InputEventScreenTouch and event.pressed:
		_set_target_from_screen_position(event.position)
	elif event is InputEventScreenDrag:
		_set_target_from_screen_position(event.position)

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

	queue_redraw()
	return true

func break_targeted_block() -> bool:
	if not _has_target_cell:
		return false
	if not _is_cell_within_reach(_target_cell):
		return false
	return _break_block_at_cell(_target_cell)

func place_targeted_block() -> bool:
	if not _has_target_cell:
		return false
	if not _is_cell_within_reach(_target_cell):
		return false
	return _place_block_at_cell(_target_cell)

func _set_target_from_screen_position(screen_position: Vector2) -> void:
	var world_position := get_viewport().get_canvas_transform().affine_inverse() * screen_position
	var next_cell := local_to_map(to_local(world_position))
	if _has_target_cell and next_cell == _target_cell:
		return
	_target_cell = next_cell
	_has_target_cell = true
	queue_redraw()

func _build_tileset() -> TileSet:
	var generated_tileset := TileSet.new()
	generated_tileset.add_physics_layer()

	var source := TileSetAtlasSource.new()
	var image := Image.create(TILE_SIZE.x * 5, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(0, 0, TILE_SIZE.x, TILE_SIZE.y), Color(0.34, 0.72, 0.29, 1.0)) # grass
	image.fill_rect(Rect2i(TILE_SIZE.x, 0, TILE_SIZE.x, TILE_SIZE.y), Color(0.53, 0.35, 0.2, 1.0)) # dirt
	image.fill_rect(Rect2i(TILE_SIZE.x * 2, 0, TILE_SIZE.x, TILE_SIZE.y), Color(0.38, 0.38, 0.42, 1.0)) # stone
	image.fill_rect(Rect2i(TILE_SIZE.x * 3, 0, TILE_SIZE.x, TILE_SIZE.y), Color(0.56, 0.39, 0.21, 1.0)) # wood
	image.fill_rect(Rect2i(TILE_SIZE.x * 4, 0, TILE_SIZE.x, TILE_SIZE.y), Color(0.62, 0.55, 0.44, 1.0)) # iron ore
	var texture := ImageTexture.create_from_image(image)

	source.texture = texture
	source.texture_region_size = TILE_SIZE
	source.create_tile(TILE_GRASS)
	source.create_tile(TILE_DIRT)
	source.create_tile(TILE_STONE)
	source.create_tile(TILE_WOOD)
	source.create_tile(TILE_IRON_ORE)

	generated_tileset.add_source(source, SOURCE_ID)

	for atlas_coords in [TILE_GRASS, TILE_DIRT, TILE_STONE, TILE_WOOD, TILE_IRON_ORE]:
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
	var cave_noise := FastNoiseLite.new()
	cave_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	cave_noise.seed = 2442
	cave_noise.frequency = 0.06
	var ore_noise := FastNoiseLite.new()
	ore_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	ore_noise.seed = 9851
	ore_noise.frequency = 0.17
	var rng := RandomNumberGenerator.new()
	rng.seed = 777

	for x in range(WORLD_WIDTH):
		var noise_height := int(round(terrain_noise.get_noise_1d(float(x)) * SURFACE_VARIATION))
		var surface_y := BASE_SURFACE_Y + noise_height

		for y in range(surface_y, WORLD_HEIGHT):
			var atlas_coords := TILE_STONE
			if y == surface_y:
				atlas_coords = TILE_GRASS
			elif y <= surface_y + DIRT_DEPTH:
				atlas_coords = TILE_DIRT

			var depth := y - surface_y
			if depth >= CAVE_START_DEPTH:
				var cave_turbulence := absf(cave_noise.get_noise_2d(float(x) * 1.8, float(y) * 1.8))
				var cave_shape := absf(cave_noise.get_noise_2d(float(x), float(y)))
				var depth_blend := clampf(float(depth) / float(WORLD_HEIGHT), 0.0, 1.0)
				var cave_cutoff := lerpf(CAVE_THRESHOLD + 0.06, CAVE_THRESHOLD - 0.06, depth_blend)
				if cave_shape > cave_cutoff and cave_turbulence > 0.27:
					continue

			if atlas_coords == TILE_STONE and depth >= IRON_MIN_DEPTH:
				var ore_value := ore_noise.get_noise_2d(float(x), float(y))
				if ore_value > (1.0 - IRON_CHANCE * 2.0):
					atlas_coords = TILE_IRON_ORE

			set_cell(0, Vector2i(x, y), SOURCE_ID, atlas_coords)

		if rng.randf() < TREE_CHANCE:
			var tree_height := rng.randi_range(TREE_MIN_HEIGHT, TREE_MAX_HEIGHT)
			for i in range(tree_height):
				var trunk_cell := Vector2i(x, surface_y - 1 - i)
				if trunk_cell.y < 0:
					break
				set_cell(0, trunk_cell, SOURCE_ID, TILE_WOOD)

	_carve_cave_tunnels(MIN_CAVE_NOISE, MAX_CAVE_NOISE)
	queue_redraw()

func _carve_cave_tunnels(min_noise: float, max_noise: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001
	var tunnel_count := 6

	for _i in range(tunnel_count):
		var position := Vector2(
			rng.randi_range(0, WORLD_WIDTH - 1),
			rng.randi_range(BASE_SURFACE_Y + 2, WORLD_HEIGHT - 8)
		)
		var angle := rng.randf_range(0.0, TAU)
		var step_length := rng.randi_range(18, 32)
		var noise_strength := rng.randf_range(min_noise, max_noise)

		for _step in range(step_length):
			var tunnel_radius := rng.randi_range(1, 2)
			_carve_circle(Vector2i(int(round(position.x)), int(round(position.y))), tunnel_radius)
			angle += rng.randf_range(-0.55, 0.55)
			position += Vector2.RIGHT.rotated(angle) * rng.randf_range(0.9, 1.4)
			position.x = clampf(position.x + rng.randf_range(-noise_strength, noise_strength), 0.0, WORLD_WIDTH - 1.0)
			position.y = clampf(position.y + rng.randf_range(-noise_strength, noise_strength), BASE_SURFACE_Y + 1.0, WORLD_HEIGHT - 2.0)

func _carve_circle(center: Vector2i, radius: int) -> void:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy > radius * radius:
				continue
			var cell := center + Vector2i(dx, dy)
			if cell.x < 0 or cell.x >= WORLD_WIDTH or cell.y < 0 or cell.y >= WORLD_HEIGHT:
				continue
			erase_cell(0, cell)

func _break_block_at_cell(cell: Vector2i) -> bool:
	var source_id := get_cell_source_id(0, cell)
	if source_id == -1:
		return false
	var atlas_coords := get_cell_atlas_coords(0, cell)

	erase_cell(0, cell)
	_spawn_dropped_item(cell, _item_id_from_atlas_coords(atlas_coords))
	world_changed.emit()
	queue_redraw()
	return true

func _place_block_at_cell(cell: Vector2i) -> bool:
	if get_cell_source_id(0, cell) != -1:
		return false
	if _would_overlap_player(cell):
		return false

	if _player == null or not _player.has_method("get_selected_item_id") or not _player.has_method("consume_selected_item"):
		return false

	var selected_item_id: StringName = _player.get_selected_item_id()
	var atlas_coords := _atlas_coords_from_item_id(selected_item_id)
	if atlas_coords.x < 0:
		return false
	if not _player.consume_selected_item(1):
		return false

	set_cell(0, cell, SOURCE_ID, atlas_coords)
	world_changed.emit()
	queue_redraw()
	return true

func _spawn_dropped_item(cell: Vector2i, item_id: StringName) -> void:
	if item_id == &"":
		return
	if get_parent() == null:
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

func _is_cell_within_reach(cell: Vector2i) -> bool:
	if _player == null:
		return true
	var cell_global := to_global(map_to_local(cell))
	return _player.global_position.distance_to(cell_global) <= INTERACTION_REACH_PIXELS

func _item_id_from_atlas_coords(atlas_coords: Vector2i) -> StringName:
	return ATLAS_TO_ITEM.get(atlas_coords, &"")

func _atlas_coords_from_item_id(item_id: StringName) -> Vector2i:
	return ITEM_TO_ATLAS.get(item_id, Vector2i(-1, -1))
