extends LimboState
## Move toward the target; give up beyond lose_range.


func _update(delta: float) -> void:
	var target: Node2D = agent.find_target()
	if target == null or agent.distance_to_target() > agent.lose_range:
		get_root().dispatch(&"target_lost")
		return
	var dx: float = target.global_position.x - agent.global_position.x
	if absf(dx) > 4.0:
		agent.direction = int(signf(dx))
	agent.walk(agent.chase_speed, delta)
