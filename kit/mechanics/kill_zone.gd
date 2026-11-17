class_name KillZone
extends Area2D
## Pits and out-of-bounds. Damages the player and sends it back to the last checkpoint
## (or `fallback_spawn`). Other bodies that enter are freed.

@export var damage: int = 1
@export var fallback_spawn: Marker2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(&"player"):
		body.queue_free()
		return
	var health := body.get_node_or_null(^"Health") as Health
	if health:
		health.damage(damage, self)
	if body.has_method(&"respawn"):
		var spawn := fallback_spawn.global_position if fallback_spawn else Vector2.ZERO
		body.respawn.call_deferred(spawn)
