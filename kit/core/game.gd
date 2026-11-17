extends Node
## Global game flow: scene changes, pausing, respawn point and story flags.
## Dialogue files can read and write `Game.flags` directly, e.g.
##   do Game.flags["met_guide"] = true
##   - Ask about the key [if Game.flags.get("met_guide", false) /]

signal paused_changed(is_paused: bool)
signal scene_changed(path: String)

const MAIN_MENU := "res://kit/ui/main_menu.tscn"

## First level started from the main menu. Change this for your game.
@export var first_level: String = "res://example/level_01.tscn"

var flags: Dictionary = {}
var respawn_point: Vector2 = Vector2.ZERO
var has_respawn_point: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func change_scene(path: String) -> void:
	set_paused(false)
	has_respawn_point = false
	get_tree().change_scene_to_file.call_deferred(path)
	scene_changed.emit(path)


func start_new_game() -> void:
	flags.clear()
	change_scene(first_level)


func to_main_menu() -> void:
	change_scene(MAIN_MENU)


func set_paused(value: bool) -> void:
	if get_tree().paused == value:
		return
	get_tree().paused = value
	paused_changed.emit(value)


func toggle_pause() -> void:
	set_paused(not get_tree().paused)


func set_respawn_point(point: Vector2) -> void:
	respawn_point = point
	has_respawn_point = true


func save_state() -> Dictionary:
	return {"flags": flags.duplicate(true)}


func load_state(data: Dictionary) -> void:
	flags = data.get("flags", {}).duplicate(true)
