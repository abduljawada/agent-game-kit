class_name TopDownController2D
extends CharacterBody2D
## Top-down (RPG, twin-stick, Zelda-like) player body with acceleration and friction.

signal interacted(target: Interactable)

@export var max_speed: float = 110.0
@export var acceleration: float = 900.0
@export var friction: float = 1100.0
@export var input_enabled: bool = true

var facing: Vector2 = Vector2.DOWN


func _ready() -> void:
	add_to_group(&"player")
	DialogueManager.dialogue_started.connect(func(_r: DialogueResource) -> void: input_enabled = false)
	DialogueManager.dialogue_ended.connect(func(_r: DialogueResource) -> void: input_enabled = true)


func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if input_enabled:
		dir = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = step_velocity(velocity, dir, delta)
	if dir != Vector2.ZERO:
		facing = dir.normalized()
	move_and_slide()


## Pure helper so tests can check movement without physics.
func step_velocity(current: Vector2, dir: Vector2, delta: float) -> Vector2:
	if dir == Vector2.ZERO:
		return current.move_toward(Vector2.ZERO, friction * delta)
	return current.move_toward(dir.limit_length(1.0) * max_speed, acceleration * delta)


func _unhandled_input(event: InputEvent) -> void:
	if input_enabled and event.is_action_pressed(&"interact"):
		var target := Interactable.nearest_to(self)
		if target:
			get_viewport().set_input_as_handled()
			target.interact(self)
			interacted.emit(target)
