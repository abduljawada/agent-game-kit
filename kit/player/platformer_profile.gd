class_name PlatformerProfile
extends Resource
## Tuning for PlatformerController2D. Designers think in heights and times,
## so jump is set as height + time to apex; gravity and jump speed are derived.
## Make a copy of default_platformer_profile.tres per character instead of
## editing the controller script.

@export_group("Run")
@export var max_speed: float = 140.0 ## px/s
@export var ground_acceleration: float = 1400.0 ## px/s²
@export var ground_deceleration: float = 1800.0 ## px/s²
@export var air_acceleration: float = 900.0 ## px/s²
@export var air_deceleration: float = 500.0 ## px/s²

@export_group("Jump")
@export var jump_height: float = 56.0 ## px, at full hold
@export var time_to_apex: float = 0.38 ## s
@export var time_to_land: float = 0.30 ## s, falling is faster than rising
@export_range(0.0, 1.0) var jump_cut: float = 0.45 ## upward speed kept when jump is released early
@export var max_fall_speed: float = 420.0 ## px/s
@export var coyote_time: float = 0.1 ## s after leaving a ledge where jump still works
@export var jump_buffer: float = 0.12 ## s a jump press is remembered before landing
@export_range(0, 3) var air_jumps: int = 0 ## extra jumps (1 = double jump)


func rise_gravity() -> float:
	return 2.0 * jump_height / (time_to_apex * time_to_apex)


func fall_gravity() -> float:
	return 2.0 * jump_height / (time_to_land * time_to_land)


func jump_velocity() -> float:
	return -2.0 * jump_height / time_to_apex
