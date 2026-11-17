class_name DialogueTrigger
extends Interactable
## Starts a Dialogue Manager conversation when the player interacts.
## Write the conversation in a .dialogue file; `cue` is the `~ cue_name` to start at.

@export var dialogue: DialogueResource
@export var cue: String = "start"
@export var one_shot: bool = false

var _open: bool = false
## The balloon currently showing this dialogue (null when closed).
var balloon: Node


func _ready() -> void:
	super()
	prompt = "Talk"
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func can_interact(by: Node) -> bool:
	return super(by) and not _open and dialogue != null


func _on_interact(_by: Node) -> void:
	_open = true
	balloon = DialogueManager.show_dialogue_balloon(dialogue, cue)


func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource == dialogue:
		_open = false
		balloon = null
		if one_shot:
			enabled = false


## Closes the conversation early (cutscene skip, player hit, tests).
func close() -> void:
	if is_instance_valid(balloon):
		balloon.queue_free()
	balloon = null
	_open = false
	DialogueManager.dialogue_ended.emit(dialogue)
