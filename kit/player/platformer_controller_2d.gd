class_name PlatformerController2D
extends CharacterBody2D
## Side-view player body. Movement feel lives in PlatformerMotor + PlatformerProfile;
## this node only reads input, moves the body and talks to sibling components.
## Set `input_enabled = false` for cutscenes and dialogue.

signal jumped
signal landed
signal interacted(target: Interactable)

@export var profile: PlatformerProfile = preload("res://kit/player/default_platformer_profile.tres")
@export var input_enabled: bool = true
@export_group("Actions")
@export var action_left: StringName = &"move_left"
@export var action_right: StringName = &"move_right"
@export var action_jump: StringName = &"jump"
@export var action_interact: StringName = &"interact"

var motor: PlatformerMotor
var facing: int = 1
## Where the body was when the level started; respawn() falls back to it.
var start_position: Vector2
var _was_on_floor: bool = true


func _ready() -> void:
	start_position = global_position
	motor = PlatformerMotor.new(profile)
	motor.jumped.connect(func(_air: bool) -> void: jumped.emit())
	add_to_group(&"player")
	DialogueManager.dialogue_started.connect(func(_r: DialogueResource) -> void: input_enabled = false)
	DialogueManager.dialogue_ended.connect(func(_r: DialogueResource) -> void: input_enabled = true)


func _physics_process(delta: float) -> void:
	var axis := 0.0
	var pressed := false
	var held := false
	if input_enabled:
		axis = Input.get_axis(action_left, action_right)
		pressed = Input.is_action_just_pressed(action_jump)
		held = Input.is_action_pressed(action_jump)
	motor.velocity = velocity
	velocity = motor.step(delta, axis, pressed, held, is_on_floor())
	if absf(axis) > 0.01:
		facing = int(signf(axis))
	move_and_slide()
	if is_on_floor() and not _was_on_floor:
		landed.emit()
	_was_on_floor = is_on_floor()


func _unhandled_input(event: InputEvent) -> void:
	if input_enabled and event.is_action_pressed(action_interact):
		var target := Interactable.nearest_to(self)
		if target:
			get_viewport().set_input_as_handled()
			target.interact(self)
			interacted.emit(target)


## Moves the player to the last checkpoint (else `fallback`, else its start) and stops it.
func respawn(fallback: Variant = null) -> void:
	if Game.has_respawn_point:
		global_position = Game.respawn_point
	else:
		global_position = fallback if fallback is Vector2 else start_position
	velocity = Vector2.ZERO
	reset_physics_interpolation()
