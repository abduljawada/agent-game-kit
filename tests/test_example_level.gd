extends GdUnitTestSuite
## Plays the example level with simulated input. Copy this file for your own levels:
## every level should at least load, let the player land, move and reach key objects.

const LEVEL := "res://example/level_01.tscn"

var runner: GdUnitSceneRunner


func before_test() -> void:
	Game.flags = {}
	Game.has_respawn_point = false
	runner = scene_runner(LEVEL)


## Waits for real physics ticks. Headless runs draw frames faster than physics
## steps, so never count process frames when testing movement.
func _physics(ticks: int) -> void:
	for i in ticks:
		await get_tree().physics_frame


func _player() -> PlatformerController2D:
	return runner.find_child("Player") as PlatformerController2D


func test_player_lands_on_ground() -> void:
	await _physics(60)
	assert_bool(_player().is_on_floor()).is_true()


func test_player_runs_right_with_input() -> void:
	await _physics(30)
	var start_x := _player().global_position.x
	runner.simulate_action_press("move_right")
	await _physics(45)
	runner.simulate_action_release("move_right")
	assert_float(_player().global_position.x - start_x).is_greater(40.0)


func test_player_jumps_with_input() -> void:
	await _physics(30)
	var ground_y := _player().global_position.y
	runner.simulate_action_press("jump")
	await _physics(12)
	assert_float(_player().global_position.y).is_less(ground_y - 20.0)
	runner.simulate_action_release("jump")


func test_coin_pickup_updates_inventory() -> void:
	await _physics(10)
	var coin := runner.find_child("Coin5") as Node2D # on the ground at x=760
	_player().global_position = coin.global_position + Vector2(0, -2)
	_player().reset_physics_interpolation()
	await _physics(10)
	assert_int(Pickup.count(Pickup.find_inventory(_player()), "coin")).is_equal(1)


func test_spikes_hurt_player() -> void:
	await _physics(10)
	var spikes := runner.find_child("Spikes") as Node2D
	_player().global_position = spikes.global_position + Vector2(0, -8)
	_player().reset_physics_interpolation()
	await _physics(10)
	var health := _player().get_node("Health") as Health
	assert_int(health.current).is_less(health.max_health)


func test_pit_respawns_player_at_spawn() -> void:
	await _physics(10)
	_player().global_position = Vector2(940, 315) # inside the pit kill zone
	_player().reset_physics_interpolation()
	await _physics(20)
	assert_float(_player().global_position.y).is_less(220.0)
	assert_float(absf(_player().global_position.x)).is_less(50.0)


func test_enemy_patrols_then_chases_nearby_player() -> void:
	await _physics(10)
	var enemy := runner.find_child("Enemy") as PatrolChaseEnemy2D
	assert_str(enemy.current_state_name()).is_equal("Patrol")
	_player().global_position = enemy.global_position + Vector2(60, -10)
	_player().reset_physics_interpolation()
	await _physics(5)
	assert_str(enemy.current_state_name()).is_equal("Chase")


func test_talking_to_guide_starts_dialogue() -> void:
	await _physics(30)
	var guide := runner.find_child("Guide") as DialogueTrigger
	_player().global_position = guide.global_position + Vector2(10, 0)
	_player().reset_physics_interpolation()
	await _physics(5)
	runner.simulate_action_pressed("interact")
	await _physics(5)
	# Dialogue is open: the player is frozen until the conversation ends.
	assert_bool(_player().input_enabled).is_false()
	guide.close()
	await _physics(2)
	assert_bool(_player().input_enabled).is_true()
