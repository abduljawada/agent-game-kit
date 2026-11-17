extends Control
## Title screen. Buttons are named so tests and MCP tools can find them.

@onready var play_button: Button = %PlayButton
@onready var continue_button: Button = %ContinueButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var options_menu: Control = %OptionsMenu


func _ready() -> void:
	play_button.pressed.connect(Game.start_new_game)
	continue_button.visible = SaveSystem.has_slot(0)
	continue_button.pressed.connect(_on_continue)
	options_button.pressed.connect(func() -> void: options_menu.visible = true)
	quit_button.pressed.connect(get_tree().quit)
	quit_button.visible = OS.get_name() != "Web"
	play_button.grab_focus.call_deferred()


func _on_continue() -> void:
	Game.change_scene(Game.first_level)
	await get_tree().process_frame
	await get_tree().process_frame
	SaveSystem.load_slot(0)
