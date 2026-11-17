extends Node3D
## Lays out every 3D model in a folder as labelled pages so you (or an agent) can see
## them. Used by scripts/assets/preview.sh, which records one image per page:
##   godot --path . res://kit/tools/model_gallery.tscn -- --gallery=res://assets/kenney/3d-platformer-kit
## Models are scaled to fit their cell, so compare shapes and materials here, not sizes.

@export_dir var folder: String = "res://assets/kenney/3d-platformer-kit"
@export var per_page: int = 12
@export var columns: int = 4
@export var frames_per_page: int = 20
@export var cell: float = 2.6

const EXTENSIONS := ["glb", "gltf", "fbx", "blend", "obj"]

var pages: Array[PackedStringArray] = []
var page: int = -1
var _frame: int = 0
var _exit_when_done: bool = false

@onready var shelf: Node3D = $Shelf
@onready var title: Label = %Title


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gallery="):
			folder = arg.trim_prefix("--gallery=")
			_exit_when_done = true
		elif arg.begins_with("--per-page="):
			per_page = int(arg.trim_prefix("--per-page="))
	var files := find_models(folder)
	files.sort()
	for i in range(0, files.size(), per_page):
		pages.append(files.slice(i, i + per_page))
	print("model_gallery: %d models, %d pages in %s" % [files.size(), pages.size(), folder])
	if pages.is_empty():
		title.text = "No models in " + folder
		if _exit_when_done:
			get_tree().quit(1)
		return
	_show_page(0)


func _process(_delta: float) -> void:
	if pages.is_empty():
		return
	_frame += 1
	if _frame >= frames_per_page:
		_frame = 0
		if page + 1 < pages.size():
			_show_page(page + 1)
		elif _exit_when_done:
			get_tree().quit()


static func find_models(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(dir):
		if f.get_extension().to_lower() in EXTENSIONS:
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		if not d.begins_with("."):
			out.append_array(find_models(dir.path_join(d)))
	return out


func _show_page(index: int) -> void:
	page = index
	for child in shelf.get_children():
		child.queue_free()
	var files: PackedStringArray = pages[index]
	var rows := ceili(files.size() / float(columns))
	for i in files.size():
		var slot := Node3D.new()
		slot.position = Vector3((i % columns - (columns - 1) / 2.0) * cell, 0, (i / columns - (rows - 1) / 2.0) * cell)
		shelf.add_child(slot)
		var packed := load(files[i]) as PackedScene
		if packed:
			var model := packed.instantiate()
			slot.add_child(model)
			_fit(model as Node3D, cell * 0.7)
		var label := Label3D.new()
		var label_text := files[i].get_file().get_basename()
		label.text = label_text if label_text.length() <= 26 else "…" + label_text.right(25)
		label.font_size = 32
		label.pixel_size = 0.0045
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0, -0.15, cell * 0.42)
		label.modulate = Color(1, 1, 0.85)
		label.outline_size = 8
		slot.add_child(label)
	title.text = "%s   page %d/%d   (%d models)" % [folder.get_file(), index + 1, pages.size(),
		pages.reduce(func(a: int, p: PackedStringArray) -> int: return a + p.size(), 0)]


## Scales and centres a model inside its slot, using world-space bounds of every mesh
## (FBX roots often carry their own scale/rotation, so local bounds are not enough).
func _fit(model: Node3D, size: float) -> void:
	if model == null:
		return
	var slot := model.get_parent() as Node3D
	var box := _world_aabb(model)
	if box.size == Vector3.ZERO:
		return
	var s := size / maxf(box.size.x, maxf(box.size.y, box.size.z))
	model.scale *= s
	box = _world_aabb(model)
	var bottom_center := Vector3(box.get_center().x, box.position.y, box.get_center().z)
	model.global_position += slot.global_position - bottom_center


func _world_aabb(root: Node) -> AABB:
	var total := AABB()
	var first := true
	var nodes: Array[Node] = root.find_children("*", "VisualInstance3D", true, false)
	if root is VisualInstance3D:
		nodes.append(root)
	for node in nodes:
		var vi := node as VisualInstance3D
		var b: AABB = vi.global_transform * vi.get_aabb()
		total = b if first else total.merge(b)
		first = false
	return total
