class_name Pickup
extends Area2D
## Collectible. When a body with a GLoot Inventory child touches it, adds
## `amount` of `item_id` (an id from the inventory's protoset JSON) and frees itself.
## Leave item_id empty for pickups that only emit `picked_up` (e.g. health).

signal picked_up(by: Node)

@export var item_id: String = "coin"
@export var amount: int = 1
@export var heal_amount: int = 0 ## heals the collector's Health child, if any
@export var sound: AudioStream ## played through the Audio autoload when collected


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(&"player"):
		return
	if item_id != "":
		var inventory := find_inventory(body)
		if inventory == null:
			push_warning("Pickup: %s has no Inventory child" % body.name)
			return
		if not give(inventory):
			return
	if heal_amount > 0:
		var health := body.get_node_or_null(^"Health") as Health
		if health:
			health.heal(heal_amount)
	Audio.play(sound)
	picked_up.emit(body)
	queue_free()


## Adds this pickup's items to `inventory`, stacking where possible.
func give(inventory: Inventory) -> bool:
	var tree := inventory.get_prototree()
	if tree == null or not tree.has_prototype(item_id):
		push_error("Pickup: item_id '%s' is not in the inventory protoset" % item_id)
		return false
	var item := inventory.create_item(item_id)
	item.set_property("stack_size", amount)
	return inventory.add_item_automerge(item)


static func find_inventory(node: Node) -> Inventory:
	for child in node.get_children():
		if child is Inventory:
			return child
	return null


## Total stack count of `id` in an inventory.
static func count(inventory: Inventory, id: String) -> int:
	var total := 0
	for item in inventory.get_items_with_prototype_id(id):
		total += int(item.get_property("stack_size", 1))
	return total
