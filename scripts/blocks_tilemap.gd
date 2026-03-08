extends TileMap

const TILE_SIZE := Vector2i(16, 16)
const GROUND_Y := 12
const LEVEL_WIDTH := 64

func _ready() -> void:
	if tile_set == null:
		tile_set = _build_tileset()

	_build_level()

func _build_tileset() -> TileSet:
	var generated_tileset := TileSet.new()
	generated_tileset.add_physics_layer()

	var source := TileSetAtlasSource.new()
	var image := Image.create(TILE_SIZE.x, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.32, 0.32, 0.36, 1.0))
	var texture := ImageTexture.create_from_image(image)

	source.texture = texture
	source.texture_region_size = TILE_SIZE
	source.create_tile(Vector2i.ZERO)

	generated_tileset.add_source(source, 0)

	var tile_data := source.get_tile_data(Vector2i.ZERO, 0)
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

	for x in range(LEVEL_WIDTH):
		set_cell(0, Vector2i(x, GROUND_Y), 0, Vector2i.ZERO)

	for x in range(12, 18):
		set_cell(0, Vector2i(x, GROUND_Y - 3), 0, Vector2i.ZERO)

	for x in range(26, 30):
		set_cell(0, Vector2i(x, GROUND_Y - 6), 0, Vector2i.ZERO)
