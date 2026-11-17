@tool
extends EditorScenePostImport
## Project-wide post-import step for 3D models (set in project.godot [importer_defaults]).
## Synty packs (res://assets/local/synty/<Pack>/): FBX files carry no texture links, so
## every surface gets a StandardMaterial3D with the right atlas from the pack's
## synty_materials.json (written by scripts/assets/synty.py). Add other per-source fixes
## here as new branches. Any other model (Kenney GLB, your own) passes through unchanged.

const SYNTY_ROOT := "res://assets/local/synty/"


func _post_import(scene: Node) -> Object:
	var path := get_source_file()
	if path.begins_with(SYNTY_ROOT):
		_synty_materials(scene, path)
	return scene


func _synty_materials(scene: Node, path: String) -> void:
	var pack_dir := SYNTY_ROOT + path.trim_prefix(SYNTY_ROOT).get_slice("/", 0) + "/"
	var info := _load_info(pack_dir)
	var cache := {}
	var file := path.get_file()
	var is_character := file.to_lower().contains("character") or file.contains("_Chr_")
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var old := mi.mesh.surface_get_material(i)
			var mat_name := old.resource_name.to_lower() if old else ""
			var tex_rel: Variant = info.get("materials", {}).get(mat_name)
			if tex_rel == null and is_character:
				tex_rel = info.get("characters")
			if tex_rel == null:
				tex_rel = info.get("default")
			if tex_rel == null:
				continue
			var key := "%s|%s" % [tex_rel, mat_name.contains("glass")]
			if not cache.has(key):
				cache[key] = _material(pack_dir + str(tex_rel), mat_name)
			if cache[key]:
				mi.mesh.surface_set_material(i, cache[key])


func _load_info(pack_dir: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(pack_dir + "synty_materials.json")
	var data: Variant = JSON.parse_string(text) if text else null
	return data if data is Dictionary else {}


func _material(texture_path: String, mat_name: String) -> StandardMaterial3D:
	if not ResourceLoader.exists(texture_path):
		push_warning("Synty import: missing texture %s" % texture_path)
		return null
	var mat := StandardMaterial3D.new()
	mat.resource_name = mat_name if mat_name else texture_path.get_file().get_basename()
	mat.albedo_texture = load(texture_path)
	mat.roughness = 0.9
	if mat_name.contains("glass"):
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.4
	return mat
