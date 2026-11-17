extends GdUnitTestSuite
## Movement feel contract. If you retune default_platformer_profile.tres these
## still hold, because they test against the profile's own numbers.

const DT := 1.0 / 60.0

var profile: PlatformerProfile
var motor: PlatformerMotor


func before_test() -> void:
	profile = load("res://kit/player/default_platformer_profile.tres").duplicate()
	motor = PlatformerMotor.new(profile)


## Simulates a jump from the floor and returns the highest point (px above start).
func _peak_height(hold_frames: int) -> float:
	var y := 0.0
	var peak := 0.0
	motor.step(DT, 0, false, false, true)
	for f in 240:
		var pressed := f == 0
		var held := f < hold_frames
		var v := motor.step(DT, 0, pressed, held, f == 0)
		y += v.y * DT
		peak = minf(peak, y)
		if f > 2 and y >= 0.0:
			break
	return -peak


func test_full_jump_reaches_profile_height() -> void:
	assert_float(_peak_height(999)).is_equal_approx(profile.jump_height, 3.0)


func test_releasing_early_gives_lower_jump() -> void:
	var full := _peak_height(999)
	motor = PlatformerMotor.new(profile)
	var tap := _peak_height(3)
	assert_float(tap).is_less(full * 0.6)


func test_reaches_but_never_exceeds_max_speed() -> void:
	for i in 120:
		motor.step(DT, 1.0, false, false, true)
	assert_float(motor.velocity.x).is_equal_approx(profile.max_speed, 0.01)


func test_stops_when_input_released() -> void:
	for i in 60:
		motor.step(DT, 1.0, false, false, true)
	for i in 60:
		motor.step(DT, 0.0, false, false, true)
	assert_float(motor.velocity.x).is_equal(0.0)


func test_coyote_time_allows_late_jump() -> void:
	motor.step(DT, 0, false, false, true)
	var frames := int(profile.coyote_time / DT) - 1
	for i in frames:
		motor.step(DT, 0, false, false, false)
	motor.step(DT, 0, true, true, false)
	assert_float(motor.velocity.y).is_less(0.0)


func test_no_jump_after_coyote_time() -> void:
	motor.step(DT, 0, false, false, true)
	for i in int(profile.coyote_time / DT) + 3:
		motor.step(DT, 0, false, false, false)
	motor.step(DT, 0, true, true, false)
	assert_float(motor.velocity.y).is_greater(0.0)


func test_jump_buffer_triggers_on_landing() -> void:
	motor.velocity = Vector2(0, 200)
	motor.step(DT, 0, true, true, false)
	motor.step(DT, 0, false, true, false)
	motor.step(DT, 0, false, true, true)
	assert_float(motor.velocity.y).is_less(0.0)


func test_double_jump_only_with_air_jumps() -> void:
	motor.step(DT, 0, false, false, true)
	motor.step(DT, 0, true, true, true)
	for i in 20:
		motor.step(DT, 0, false, true, false)
	var before := motor.velocity.y
	motor.step(DT, 0, true, true, false)
	assert_float(motor.velocity.y).is_greater_equal(before)

	profile.air_jumps = 1
	motor = PlatformerMotor.new(profile)
	motor.step(DT, 0, false, false, true)
	motor.step(DT, 0, true, true, true)
	for i in 20:
		motor.step(DT, 0, false, true, false)
	motor.step(DT, 0, true, true, false)
	# jump impulse, then one frame of rising gravity
	var expected := profile.jump_velocity() + profile.rise_gravity() * DT
	assert_float(motor.velocity.y).is_equal_approx(expected, 0.01)


func test_fall_speed_is_capped() -> void:
	for i in 300:
		motor.step(DT, 0, false, false, false)
	assert_float(motor.velocity.y).is_equal_approx(profile.max_fall_speed, 0.01)
