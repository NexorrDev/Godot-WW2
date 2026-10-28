extends Interactable
class_name NoteItem

## Note ou document papier posé dans le décor fournissant un indice au joueur.

@export_multiline var note_text: String = "ORDRE MILITAIRE : Syntoniser le poste T.S.F. sur 390 kHz (BBC Londres)."

func _ready() -> void:
	if prompt_message == "Examiner":
		prompt_message = "Lire la note d'instructions"

func interact() -> void:
	super.interact()
	print("[Note] %s" % note_text)
	# Ouvre le poste de radio pour guider directement le joueur
	get_tree().call_group("enigma_radio", "open_radio")
