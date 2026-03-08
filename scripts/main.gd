extends Node2D

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

@onready var _blocks: Node = $Blocks
@onready var _player: Node = $Player

var _is_loading := false

func _ready() -> void:
	_connect_state_signals()
	_load_game()

func _connect_state_signals() -> void:
	if _blocks != null and _blocks.has_signal("world_changed"):
		_blocks.world_changed.connect(_on_state_changed)
	if _player != null and _player.has_signal("inventory_changed"):
		_player.inventory_changed.connect(_on_state_changed)
	tree_exiting.connect(_on_tree_exiting)

func _on_tree_exiting() -> void:
	_save_game()

func _on_state_changed(_arg1 = null, _arg2 = null, _arg3 = null) -> void:
	if _is_loading:
		return
	_save_game()

func _save_game() -> void:
	var save_data := {
		"version": SAVE_VERSION,
		"world": _blocks.get_world_state() if _blocks != null and _blocks.has_method("get_world_state") else {},
		"player": _player.get_save_data() if _player != null and _player.has_method("get_save_data") else {}
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to open save file for writing: %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(save_data, "\t"))

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var raw_json := FileAccess.get_file_as_string(SAVE_PATH)
	if raw_json.is_empty():
		return

	var parser := JSON.new()
	var parse_result := parser.parse(raw_json)
	if parse_result != OK:
		push_warning("Save file parse failed; using generated defaults.")
		_reset_world_to_default()
		return

	var save_data = parser.data
	if not (save_data is Dictionary):
		push_warning("Save file root is invalid; using generated defaults.")
		_reset_world_to_default()
		return
	var save_version := int(save_data.get("version", 0))
	if save_version > SAVE_VERSION:
		push_warning("Save file version is newer than supported; using generated defaults.")
		_reset_world_to_default()
		return

	_is_loading = true

	var world_loaded := false
	var world_data = save_data.get("world", null)
	if world_data is Dictionary and _blocks != null and _blocks.has_method("load_world_state"):
		world_loaded = _blocks.load_world_state(world_data)

	if not world_loaded:
		_reset_world_to_default()

	var player_data = save_data.get("player", null)
	if player_data is Dictionary and _player != null and _player.has_method("load_save_data"):
		_player.load_save_data(player_data)

	_is_loading = false

func _reset_world_to_default() -> void:
	if _blocks != null and _blocks.has_method("generate_default_world"):
		_blocks.generate_default_world()
