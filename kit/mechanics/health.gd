class_name Health
extends Node
## Hit points with optional invulnerability frames. Add as a child of anything
## that can be hurt; pair with a Hurtbox. Listen to `died` for death logic.

signal changed(current: int, maximum: int)
signal damaged(amount: int, source: Node)
signal healed(amount: int)
signal died

@export var max_health: int = 3
@export var invulnerability_time: float = 0.6 ## s after a hit with no further damage

var current: int
var _invulnerable_left: float = 0.0


func _ready() -> void:
	current = max_health


func _process(delta: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)


func is_dead() -> bool:
	return current <= 0


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


## Returns true if damage was applied.
func damage(amount: int, source: Node = null) -> bool:
	if amount <= 0 or is_dead() or is_invulnerable():
		return false
	current = maxi(current - amount, 0)
	_invulnerable_left = invulnerability_time
	damaged.emit(amount, source)
	changed.emit(current, max_health)
	if current == 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	if amount <= 0 or is_dead():
		return
	var before := current
	current = mini(current + amount, max_health)
	if current != before:
		healed.emit(current - before)
		changed.emit(current, max_health)


func revive() -> void:
	current = max_health
	_invulnerable_left = invulnerability_time
	changed.emit(current, max_health)


func save_state() -> Dictionary:
	return {"current": current, "max": max_health}


func load_state(data: Dictionary) -> void:
	max_health = data.get("max", max_health)
	current = data.get("current", max_health)
	changed.emit(current, max_health)
