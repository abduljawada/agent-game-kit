class_name Interactable
extends Area2D
## Something the player can use with the "interact" action (NPCs, doors,
## levers, chests). Connect to `interacted` or extend and override `_on_interact`.
## Players call Interactable.nearest_to(self) to find what is in reach.

signal interacted(by: Node)

@export var prompt: String = "Interact"
@export var enabled: bool = true

var _bodies_in_reach: Array[Node] = []


func _ready() -> void:
	add_to_group(&"interactable")
	body_entered.connect(func(b: Node) -> void: _bodies_in_reach.append(b))
	body_exited.connect(func(b: Node) -> void: _bodies_in_reach.erase(b))


func can_interact(by: Node) -> bool:
	return enabled and by in _bodies_in_reach


func interact(by: Node) -> void:
	if not can_interact(by):
		return
	_on_interact(by)
	interacted.emit(by)


func _on_interact(_by: Node) -> void:
	pass


static func nearest_to(node: Node2D) -> Interactable:
	var best: Interactable = null
	var best_dist := INF
	for candidate in node.get_tree().get_nodes_in_group(&"interactable"):
		var i := candidate as Interactable
		if i and i.can_interact(node):
			var d := node.global_position.distance_squared_to(i.global_position)
			if d < best_dist:
				best_dist = d
				best = i
	return best
