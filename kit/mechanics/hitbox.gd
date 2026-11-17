class_name Hitbox
extends Area2D
## Deals damage to any Hurtbox it overlaps (spikes, enemy bodies, attacks).
## Use collision layers to pick who can hit whom; see docs/KIT.md.

@export var damage: int = 1
@export var knockback: float = 220.0 ## px/s pushed away from the hitbox
@export var active: bool = true


func _ready() -> void:
	monitorable = true
