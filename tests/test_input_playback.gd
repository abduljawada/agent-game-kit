extends GdUnitTestSuite
## Plays the scripted demo run (the same timeline scripts/record.sh uses) and checks
## the outcome, so a recorded "this is how the level plays" stays true.

const LEVEL := "res://example/level_01.tscn"
const TIMELINE := "res://example/demo_run.json"

var runner: GdUnitSceneRunner


func before_test() -> void:
	Game.flags = {}
	Game.has_respawn_point = false
	runner = scene_runner(LEVEL)


func after_test() -> void:
	InputPlayback.stop()


func _player() -> PlatformerController2D:
	return runner.find_child("Player") as PlatformerController2D


func test_timeline_loads_and_uses_known_actions() -> void:
	var events := InputPlayback.load_timeline(TIMELINE)
	assert_int(events.size()).is_greater(0)
	for e: Dictionary in events:
		assert_bool(InputMap.has_action(e["action"])).is_true()


func test_demo_run_reaches_checkpoint_unhurt() -> void:
	InputPlayback.show_overlay = false
	InputPlayback.play(InputPlayback.load_timeline(TIMELINE))
	var health := _player().get_node("Health") as Health
	var log := PackedStringArray()
	var t := 0
	while InputPlayback.playing and t < 600:
		await get_tree().physics_frame
		t += 1
		if t % 6 == 0:
			log.append("t=%.2f x=%.0f y=%.0f hp=%d" % [InputPlayback.time, _player().global_position.x,
				_player().global_position.y, health.current])
	var coins := Pickup.count(Pickup.find_inventory(_player()), "coin")
	if health.current < health.max_health or coins < 4 or not Game.has_respawn_point:
		print("\n".join(log)) # trajectory, to retime the timeline
	assert_int(health.current).override_failure_message("got hurt during the run").is_equal(health.max_health)
	assert_int(coins).override_failure_message("missed coins (3 on the ledges, 1 after the spikes)").is_greater_equal(4)
	assert_bool(Game.has_respawn_point).override_failure_message("did not reach the checkpoint").is_true()
	InputPlayback.show_overlay = true
