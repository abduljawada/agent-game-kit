class_name PlatformerMotor
extends RefCounted
## Pure platformer movement logic: no nodes, no Input, no physics server.
## PlatformerController2D feeds it input and floor state each physics frame;
## tests drive it directly. Keep all movement feel changes here.

signal jumped(is_air_jump: bool)

var profile: PlatformerProfile
var velocity: Vector2 = Vector2.ZERO

var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0
var _air_jumps_left: int = 0
var _jumping: bool = false


func _init(p_profile: PlatformerProfile = null) -> void:
	profile = p_profile if p_profile else PlatformerProfile.new()


## Advances one step and returns the new velocity.
## move_axis: -1..1. jump_pressed: true only on the frame the button went down.
func step(delta: float, move_axis: float, jump_pressed: bool, jump_held: bool, on_floor: bool) -> Vector2:
	_update_timers(delta, jump_pressed, on_floor)
	_apply_horizontal(delta, move_axis, on_floor)
	_apply_jump(jump_held, on_floor)
	_apply_gravity(delta, on_floor)
	return velocity


func _update_timers(delta: float, jump_pressed: bool, on_floor: bool) -> void:
	if on_floor:
		_coyote_timer = profile.coyote_time
		_air_jumps_left = profile.air_jumps
		if velocity.y >= 0.0:
			_jumping = false
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	if jump_pressed:
		_buffer_timer = profile.jump_buffer
	else:
		_buffer_timer = maxf(_buffer_timer - delta, 0.0)


func _apply_horizontal(delta: float, move_axis: float, on_floor: bool) -> void:
	var target := clampf(move_axis, -1.0, 1.0) * profile.max_speed
	var accelerating := absf(target) > 0.01 and (signf(target) == signf(velocity.x) or is_zero_approx(velocity.x))
	var rate: float
	if on_floor:
		rate = profile.ground_acceleration if accelerating else profile.ground_deceleration
	else:
		rate = profile.air_acceleration if accelerating else profile.air_deceleration
	velocity.x = move_toward(velocity.x, target, rate * delta)


func _apply_jump(jump_held: bool, on_floor: bool) -> void:
	if _buffer_timer > 0.0:
		if on_floor or _coyote_timer > 0.0:
			_do_jump(false)
		elif _air_jumps_left > 0:
			_air_jumps_left -= 1
			_do_jump(true)
	# Variable jump height: releasing early cuts upward speed once.
	if _jumping and not jump_held and velocity.y < 0.0:
		velocity.y *= profile.jump_cut
		_jumping = false


func _do_jump(is_air_jump: bool) -> void:
	velocity.y = profile.jump_velocity()
	_buffer_timer = 0.0
	_coyote_timer = 0.0
	_jumping = true
	jumped.emit(is_air_jump)


func _apply_gravity(delta: float, on_floor: bool) -> void:
	if on_floor and velocity.y >= 0.0:
		velocity.y = 0.0
		return
	var g := profile.rise_gravity() if velocity.y < 0.0 else profile.fall_gravity()
	velocity.y = minf(velocity.y + g * delta, profile.max_fall_speed)
