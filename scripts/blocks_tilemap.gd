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
	if get_cell_source_id(0, cell) == -1:
		return

	erase_cell(0, cell)
	_spawn_dropped_item(cell)

func _place_block_from_screen_position(screen_position: Vector2) -> void:
	var world_position := get_viewport().get_canvas_transform().affine_inverse() * screen_position
	var cell := local_to_map(to_local(world_position))
	if get_cell_source_id(0, cell) != -1:
		return
	if _would_overlap_player(cell):
		return

	set_cell(0, cell, SOURCE_ID, TILE_DIRT)

func _spawn_dropped_item(cell: Vector2i) -> void:
	var dropped_item := DROPPED_ITEM_SCENE.instantiate()
	dropped_item.global_position = to_global(map_to_local(cell))
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
