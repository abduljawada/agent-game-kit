extends Node
## Save slots as JSON in user://saves/.
##
## Any node in the "persist" group that implements
##   func save_state() -> Dictionary
##   func load_state(data: Dictionary) -> void
## is saved under its `persist_id` (exported property or meta) or, if it has
## none, its scene path. The Game autoload is always saved under "game".

signal saved(slot: int)
signal loaded(slot: int)

const DIR := "user://saves"
const VERSION := 1


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [DIR, slot]


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func collect() -> Dictionary:
	var nodes := {}
	for node in get_tree().get_nodes_in_group(&"persist"):
		if node.has_method(&"save_state"):
			nodes[_persist_id(node)] = node.save_state()
	return {"version": VERSION, "game": Game.save_state(), "nodes": nodes}


func apply(data: Dictionary) -> void:
	Game.load_state(data.get("game", {}))
	var nodes: Dictionary = data.get("nodes", {})
	for node in get_tree().get_nodes_in_group(&"persist"):
		var id := _persist_id(node)
		if nodes.has(id) and node.has_method(&"load_state"):
			node.load_state(nodes[id])


func save_slot(slot: int) -> Error:
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(collect(), "\t"))
	file.close()
	saved.emit(slot)
	return OK


func load_slot(slot: int) -> Error:
	if not has_slot(slot):
		return ERR_FILE_NOT_FOUND
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	if not parsed is Dictionary:
		return ERR_PARSE_ERROR
	apply(parsed)
	loaded.emit(slot)
	return OK


func delete_slot(slot: int) -> void:
	if has_slot(slot):
		DirAccess.remove_absolute(slot_path(slot))


func _persist_id(node: Node) -> String:
	if "persist_id" in node and str(node.persist_id) != "":
		return str(node.persist_id)
	if node.has_meta(&"persist_id"):
		return str(node.get_meta(&"persist_id"))
	return str(node.get_path())
