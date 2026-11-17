extends Node
## Replays a scripted input timeline so recordings and tests show real gameplay.
##
## Timeline JSON (times in seconds of game time, measured in physics steps):
##   { "events": [
##       { "at": 0.5, "action": "move_right", "hold": 1.6 },
##       { "at": 1.4, "action": "jump", "hold": 0.35 },
##       { "at": 3.0, "action": "interact" }          # no hold = 0.1 s tap
##   ] }
##
## Start it from the command line (scripts/record.sh does this for you):
##   godot --path . res://level.tscn -- --input-timeline=res://example/demo_run.json
## or from code / tests:  InputPlayback.play(events_array)
## While playing, an overlay shows the game time and held actions so each recorded
## frame can be matched to the timeline.

signal finished

const DEFAULT_TAP := 0.1

var playing: bool = false
var time: float = 0.0
var show_overlay: bool = true

var _events: Array[Dictionary] = []
var _held: Dictionary = {} # action -> release time
var _next: int = 0
var _overlay: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_physics_process(false)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--input-timeline="):
			var path := arg.trim_prefix("--input-timeline=")
			var events := load_timeline(path)
			if events.is_empty():
				push_error("InputPlayback: no events in %s" % path)
			else:
				play.call_deferred(events)


static func load_timeline(path: String) -> Array:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("InputPlayback: cannot read %s" % path)
		return []
	var data: Variant = JSON.parse_string(text)
	if data is Dictionary and data.get("events") is Array:
		return data["events"]
	if data is Array:
		return data
	push_error("InputPlayback: %s must be {\"events\": [...]}" % path)
	return []


func play(events: Array) -> void:
	stop()
	for e: Dictionary in events:
		var action := StringName(e.get("action", ""))
		if not InputMap.has_action(action):
			push_error("InputPlayback: unknown action '%s'" % action)
			continue
		_events.append({"at": float(e.get("at", 0.0)), "action": action,
			"hold": float(e.get("hold", DEFAULT_TAP))})
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["at"] < b["at"])
	time = 0.0
	_next = 0
	playing = true
	if show_overlay:
		_make_overlay()
	set_physics_process(true)


func stop() -> void:
	for action: StringName in _held.keys():
		_send(action, false)
	_held.clear()
	_events.clear()
	playing = false
	set_physics_process(false)
	if is_instance_valid(_overlay):
		_overlay.get_parent().queue_free()
	_overlay = null


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	while _next < _events.size() and _events[_next]["at"] <= time + 0.0001:
		var e: Dictionary = _events[_next]
		_send(e["action"], true)
		_held[e["action"]] = maxf(_held.get(e["action"], 0.0), e["at"] + e["hold"])
		_next += 1
	for action: StringName in _held.keys():
		if time >= _held[action]:
			_send(action, false)
			_held.erase(action)
	_update_overlay()
	time += delta
	if _next >= _events.size() and _held.is_empty():
		playing = false
		set_physics_process(false)
		finished.emit()


func _send(action: StringName, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


func _make_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	_overlay = Label.new()
	_overlay.position = Vector2(8, 336)
	_overlay.add_theme_font_size_override("font_size", 12)
	_overlay.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	_overlay.add_theme_color_override("font_outline_color", Color.BLACK)
	_overlay.add_theme_constant_override("outline_size", 4)
	layer.add_child(_overlay)
	add_child(layer)


func _update_overlay() -> void:
	if is_instance_valid(_overlay):
		var held := ", ".join(_held.keys().map(func(a: StringName) -> String: return String(a)))
		_overlay.text = "t=%.2fs  %s" % [time, held if held else "-"]
