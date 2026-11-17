extends CanvasLayer
## Shows the player's health and the count of one inventory item.

@export var player: Node
@export var counted_item: String = "coin"

@onready var health_label: Label = %HealthLabel
@onready var item_label: Label = %ItemLabel

var _health: Health
var _inventory: Inventory


func _ready() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group(&"player")
	if player == null:
		return
	_health = player.get_node_or_null(^"Health") as Health
	_inventory = Pickup.find_inventory(player)
	if _health:
		_health.changed.connect(func(_c: int, _m: int) -> void: _refresh())
	if _inventory:
		_inventory.item_added.connect(func(_i: InventoryItem) -> void: _refresh())
		_inventory.item_property_changed.connect(func(_i: InventoryItem, _p: String) -> void: _refresh())
	_refresh.call_deferred()


func _refresh() -> void:
	if _health:
		health_label.text = "HP %d/%d" % [_health.current, _health.max_health]
	if _inventory:
		item_label.text = "%s x%d" % [counted_item.capitalize(), Pickup.count(_inventory, counted_item)]
