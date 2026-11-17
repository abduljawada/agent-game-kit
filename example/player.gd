extends PlatformerController2D
## Example player: kit controller + death handling. Game-specific player logic goes here,
## not in kit/player/platformer_controller_2d.gd.

@onready var health: Health = $Health
@onready var visual: CanvasItem = $Visual

var spawn_point: Vector2


func _ready() -> void:
	super()
	add_to_group(&"persist")
	set_meta(&"persist_id", "player")
	spawn_point = global_position
	health.died.connect(_on_died)
	health.damaged.connect(func(_a: int, _s: Node) -> void: _flash())


func _on_died() -> void:
	health.revive()
	respawn(spawn_point)


func _flash() -> void:
	var tw := create_tween()
	tw.tween_property(visual, "modulate:a", 0.3, 0.08)
	tw.tween_property(visual, "modulate:a", 1.0, 0.08)
	tw.set_loops(3)


func save_state() -> Dictionary:
	var inv := Pickup.find_inventory(self)
	return {
		"x": global_position.x,
		"y": global_position.y,
		"health": health.save_state(),
		"inventory": inv.serialize() if inv else {},
	}


func load_state(data: Dictionary) -> void:
	global_position = Vector2(data.get("x", global_position.x), data.get("y", global_position.y))
	reset_physics_interpolation()
	health.load_state(data.get("health", {}))
	var inv := Pickup.find_inventory(self)
	if inv and data.has("inventory"):
		inv.deserialize(data["inventory"])
