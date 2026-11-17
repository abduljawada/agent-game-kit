extends CanvasLayer
## Drop into any level. "pause" toggles it; works while the tree is paused.

@onready var root: Control = %Root
@onready var resume_button: Button = %ResumeButton
@onready var save_button: Button = %SaveButton
@onready var options_button: Button = %OptionsButton
@onready var menu_button: Button = %MenuButton
@onready var options_menu: Control = %OptionsMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	Game.paused_changed.connect(_on_paused_changed)
	resume_button.pressed.connect(func() -> void: Game.set_paused(false))
	save_button.pressed.connect(func() -> void:
		SaveSystem.save_slot(0)
		save_button.text = "Saved")
	options_button.pressed.connect(func() -> void: options_menu.visible = true)
	menu_button.pressed.connect(Game.to_main_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not options_menu.visible:
		get_viewport().set_input_as_handled()
		Game.toggle_pause()


func _on_paused_changed(is_paused: bool) -> void:
	root.visible = is_paused
	save_button.text = "Save"
	if is_paused:
		resume_button.grab_focus.call_deferred()
