extends Interactable
class_name MemoItem

## Petit papier posé dans le décor : s'ouvre dans le lecteur de notes.

@export var memo_title: String = "MÉMO"
@export_multiline var memo_text: String = ""

func _ready() -> void:
	if prompt_message == "Examiner":
		prompt_message = "Lire : " + memo_title.capitalize()

func interact() -> void:
	super.interact()
	get_tree().call_group("note_viewer", "show_note", memo_title, memo_text)
