extends LimboState
## Walk back and forth; switch to chase when the target is within sight_range.


func _update(delta: float) -> void:
	agent.walk(agent.patrol_speed, delta)
	if agent.distance_to_target() <= agent.sight_range:
		get_root().dispatch(&"target_seen")
