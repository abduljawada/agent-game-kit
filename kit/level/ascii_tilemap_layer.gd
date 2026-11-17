@tool
class_name AsciiTileMapLayer
extends TileMapLayer
## Builds a level from a plain-text layout, so agents and humans can write and diff levels:
##
##   ..........c.c.........
##   ....P....=====....^^..
##   ######################
##
## - `solids`: char -> dictionary of atlas coords {"top_left","top","top_right","single",
##   "fill_left","fill","fill_right", optional "bottom_left","bottom","bottom_right"}.
##   The layer picks the tile from the neighbours (grass on top, dirt below, edges at
##   the ends, bottom border where nothing solid is below).
## - `tiles`: char -> Vector2i atlas coords for plain one-off tiles (planks, decor).
## - `rows`: char -> {"left","middle","right","single"} for horizontal runs like planks.
## - `entities`: char -> PackedScene instanced at the cell (coins, spikes, ...), named
##   <SceneName><n> in reading order, added under `entity_parent`.
## - `markers`: char -> NodePath of an existing node to move onto that cell (player, NPC).
## Entities and markers sit on the cell's bottom edge, so feet land on the floor below.
## Any other char (e.g. '.') is empty. Rebuilds in the editor when the file changes.

signal built

@export_file("*.txt") var layout_file: String:
	set(value):
		layout_file = value
		if is_inside_tree():
			build()
@export var source_id: int = 0
@export var solids: Dictionary = {}
@export var tiles: Dictionary = {}
@export var rows: Dictionary = {}
@export var entities: Dictionary = {}
@export var markers: Dictionary = {}
@export var entity_parent: NodePath
@export_tool_button("Rebuild from layout") var rebuild_action := build

var grid: PackedStringArray = []
var spawned: Array[Node] = []


func _ready() -> void:
	build()


func build() -> void:
	if layout_file.is_empty():
		return
	var text := FileAccess.get_file_as_string(layout_file)
	if text.is_empty():
		push_error("AsciiTileMapLayer: cannot read %s" % layout_file)
		return
	grid = PackedStringArray()
	for line in text.split("\n"):
		if not line.begins_with(";"): # ';' lines are comments
			grid.append(line.rstrip("\r"))
	clear()
	_clear_spawned()
	for y in grid.size():
		for x in grid[y].length():
			_place(x, y, grid[y][x])
	built.emit()


## World position of the bottom-centre of a cell (where an entity's feet go).
func cell_floor_position(cell: Vector2i) -> Vector2:
	var size := tile_set.tile_size if tile_set else Vector2i(16, 16)
	return to_global(map_to_local(cell) + Vector2(0, size.y / 2.0))


## Cells containing `ch`, in reading order. Useful in tests: cells_of("c").
func cells_of(ch: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in grid.size():
		for x in grid[y].length():
			if grid[y][x] == ch:
				out.append(Vector2i(x, y))
	return out


func _char_at(x: int, y: int) -> String:
	if y < 0 or y >= grid.size() or x < 0 or x >= grid[y].length():
		return ""
	return grid[y][x]


func _place(x: int, y: int, ch: String) -> void:
	var cell := Vector2i(x, y)
	if solids.has(ch):
		set_cell(cell, source_id, _solid_tile(x, y, ch, solids[ch]))
	elif rows.has(ch):
		var r: Dictionary = rows[ch]
		var left := _char_at(x - 1, y) == ch
		var right := _char_at(x + 1, y) == ch
		var key := "middle" if left and right else ("left" if right else ("right" if left else "single"))
		set_cell(cell, source_id, r.get(key, r.get("middle")))
	elif tiles.has(ch):
		set_cell(cell, source_id, tiles[ch])
	elif entities.has(ch):
		_spawn(entities[ch], cell)
	elif markers.has(ch) and not Engine.is_editor_hint():
		var node := get_node_or_null(markers[ch]) as Node2D
		if node:
			node.global_position = cell_floor_position(cell)
			if node.has_method(&"reset_physics_interpolation"):
				node.reset_physics_interpolation()


func _solid_tile(x: int, y: int, ch: String, s: Dictionary) -> Vector2i:
	var solid := func(cx: int, cy: int) -> bool: return solids.has(_char_at(cx, cy))
	var top: bool = not solid.call(x, y - 1)
	var l: bool = solid.call(x - 1, y)
	var r: bool = solid.call(x + 1, y)
	var side := "_left" if not l else ("_right" if not r else "")
	if top:
		if not l and not r:
			return s.get("single", s["top"])
		return s.get("top" + side, s["top"])
	if not solid.call(x, y + 1) and s.has("bottom"):
		return s.get("bottom" + side, s["bottom"])
	return s.get("fill" + side, s["fill"])


func _spawn(scene: PackedScene, cell: Vector2i) -> void:
	if scene == null or Engine.is_editor_hint():
		return
	var parent := get_node_or_null(entity_parent) if not entity_parent.is_empty() else get_parent()
	var node := scene.instantiate()
	var base := scene.resource_path.get_file().get_basename().to_pascal_case()
	var n := 1
	while parent.has_node(NodePath(base + str(n))):
		n += 1
	node.name = base + str(n)
	if node is Node2D and parent is CanvasItem:
		(node as Node2D).position = (parent as CanvasItem).get_global_transform().affine_inverse() * cell_floor_position(cell)
	parent.add_child.call_deferred(node)
	spawned.append(node)


func _clear_spawned() -> void:
	for node in spawned:
		if is_instance_valid(node):
			node.queue_free()
	spawned.clear()
