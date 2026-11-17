extends Control
## Volume and fullscreen. Saves on close.

@onready var volume_slider: HSlider = %VolumeSlider
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var back_button: Button = %BackButton


func _ready() -> void:
	volume_slider.value = Settings.master_volume
	fullscreen_check.button_pressed = Settings.fullscreen
	volume_slider.value_changed.connect(func(v: float) -> void: Settings.master_volume = v)
	fullscreen_check.toggled.connect(func(on: bool) -> void: Settings.fullscreen = on)
	back_button.pressed.connect(close)
	visibility_changed.connect(func() -> void:
		if visible:
			volume_slider.grab_focus.call_deferred())


func close() -> void:
	Settings.save_settings()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
