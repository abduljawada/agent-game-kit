class_name Hurtbox
extends Area2D
## Receives damage from Hitboxes and forwards it to a Health node.
## Applies knockback if the owner is a CharacterBody2D.

signal hit(hitbox: Hitbox)

@export var health: Health


func _ready() -> void:
	monitoring = true
	area_entered.connect(_on_area_entered)


func _physics_process(_delta: float) -> void:
	# Re-check overlaps so standing on spikes keeps hurting after i-frames end.
	if health and not health.is_invulnerable():
		for area in get_overlapping_areas():
			if area is Hitbox:
				_on_area_entered(area)
				break


func _on_area_entered(area: Area2D) -> void:
	if not area is Hitbox or not area.active or health == null:
		return
	var hitbox := area as Hitbox
	if health.damage(hitbox.damage, hitbox):
		hit.emit(hitbox)
		var body := get_parent() as CharacterBody2D
		if body and hitbox.knockback > 0.0:
			var away := (body.global_position - hitbox.global_position).normalized()
			if away == Vector2.ZERO:
				away = Vector2.UP
			body.velocity = Vector2(away.x, minf(away.y, -0.5)).normalized() * hitbox.knockback
