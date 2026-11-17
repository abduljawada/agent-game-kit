extends GdUnitTestSuite
## Health, inventory pickups, save slots and dialogue.

const SLOT := 99


func test_health_damage_invulnerability_and_death() -> void:
	var health: Health = auto_free(Health.new())
	health.max_health = 2
	health.invulnerability_time = 0.5
	add_child(health)
	monitor_signals(health)
	assert_bool(health.damage(1)).is_true()
	assert_bool(health.damage(1)).is_false() # still invulnerable
	health._process(0.6)
	assert_bool(health.damage(5)).is_true()
	assert_int(health.current).is_equal(0)
	await assert_signal(health).is_emitted("died")


func test_health_heal_is_clamped() -> void:
	var health: Health = auto_free(Health.new())
	health.max_health = 3
	add_child(health)
	health.invulnerability_time = 0.0
	health.damage(2)
	health.heal(10)
	assert_int(health.current).is_equal(3)


func test_pickups_stack_in_gloot_inventory() -> void:
	var inv: Inventory = auto_free(Inventory.new())
	inv.protoset = load("res://example/items.json")
	add_child(inv)
	var pickup: Pickup = auto_free(Pickup.new())
	pickup.item_id = "coin"
	pickup.amount = 2
	assert_bool(pickup.give(inv)).is_true()
	pickup.amount = 3
	assert_bool(pickup.give(inv)).is_true()
	assert_int(Pickup.count(inv, "coin")).is_equal(5)
	assert_int(inv.get_item_count()).is_equal(1) # merged into one stack


func test_unknown_item_is_rejected() -> void:
	var inv: Inventory = auto_free(Inventory.new())
	inv.protoset = load("res://example/items.json")
	add_child(inv)
	var pickup: Pickup = auto_free(Pickup.new())
	pickup.item_id = "does_not_exist"
	assert_bool(pickup.give(inv)).is_false()


func test_save_slot_round_trip() -> void:
	Game.flags = {"door_open": true, "coins_spent": 4}
	assert_int(SaveSystem.save_slot(SLOT)).is_equal(OK)
	Game.flags = {}
	assert_int(SaveSystem.load_slot(SLOT)).is_equal(OK)
	assert_dict(Game.flags).contains_key_value("door_open", true)
	SaveSystem.delete_slot(SLOT)
	assert_bool(SaveSystem.has_slot(SLOT)).is_false()
	Game.flags = {}


func test_dialogue_compiles_and_branches_on_flags() -> void:
	var dialogue: DialogueResource = load("res://example/guide.dialogue")
	Game.flags = {}
	var line: DialogueLine = await DialogueManager.get_next_dialogue_line(dialogue, "start")
	assert_str(line.character).is_equal("Guide")
	assert_str(line.text).contains("visitor")
	Game.flags["met_guide"] = true
	line = await DialogueManager.get_next_dialogue_line(dialogue, "start")
	assert_str(line.text).contains("Back again")
	Game.flags = {}
