class_name PatrolChaseEnemy2D
extends CharacterBody2D
## Ground enemy: patrols between walls/ledges, chases the player when close,
## gives up when the player gets away. Built on a LimboAI state machine
## (LimboHSM) created in code; add states in kit/ai/states/ and wire them in _build_hsm().

@export var patrol_speed: float = 40.0
@export var chase_speed: float = 90.0
@export var sight_range: float = 120.0
@export var lose_range: float = 200.0
@export var gravity: float = 900.0
@export var target_group: StringName = &"player"

var direction: int = -1
var hsm: LimboHSM
var patrol_state: LimboState
var chase_state: LimboState

@onready var floor_probe: RayCast2D = get_node_or_null(^"FloorProbe")


func _ready() -> void:
	_build_hsm()
	var health := get_node_or_null(^"Health") as Health
	if health:
		health.died.connect(queue_free)


func _build_hsm() -> void:
	hsm = LimboHSM.new()
	hsm.name = "LimboHSM"
	patrol_state = preload("res://kit/ai/states/patrol_state.gd").new()
	patrol_state.name = "Patrol"
	chase_state = preload("res://kit/ai/states/chase_state.gd").new()
	chase_state.name = "Chase"
	hsm.add_child(patrol_state)
	hsm.add_child(chase_state)
	add_child(hsm)
	hsm.add_transition(patrol_state, chase_state, &"target_seen")
	hsm.add_transition(chase_state, patrol_state, &"target_lost")
	hsm.initial_state = patrol_state
	hsm.initialize(self)
	hsm.set_active(true)


func current_state_name() -> String:
	var s := hsm.get_active_state()
	return String(s.name) if s else ""


func find_target() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group(target_group):
		var t := n as Node2D
		if t:
			var d := global_position.distance_to(t.global_position)
			if d < best_d:
				best_d = d
				best = t
	return best


func distance_to_target() -> float:
	var t := find_target()
	return global_position.distance_to(t.global_position) if t else INF


## Called by states each physics frame.
func walk(speed: float, delta: float) -> void:
	velocity.x = direction * speed
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if is_on_wall() or _at_ledge():
		direction = -direction
	if floor_probe:
		floor_probe.position.x = absf(floor_probe.position.x) * direction


func _at_ledge() -> bool:
	return floor_probe != null and is_on_floor() and not floor_probe.is_colliding()
