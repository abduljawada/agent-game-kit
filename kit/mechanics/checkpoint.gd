class_name Checkpoint
extends Area2D
## Sets the respawn point when the player touches it.

signal activated

var is_active: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(&"player") and not is_active:
		is_active = true
		Game.set_respawn_point(global_position)
		activated.emit()
