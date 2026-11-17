extends Node
## Player settings (volume, fullscreen), saved to user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"

var master_volume: float = 0.8:
	set(value):
		master_volume = clampf(value, 0.0, 1.0)
		_apply_volume()
		changed.emit()
var fullscreen: bool = false:
	set(value):
		fullscreen = value
		_apply_fullscreen()
		changed.emit()


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		master_volume = cfg.get_value("audio", "master_volume", master_volume)
		fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	_apply_volume()
	_apply_fullscreen()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))


func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
