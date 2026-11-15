extends Interactable
class_name MachineItem

## Machine à écrire (date 6 : Pearl Harbor). Ouvre l'énigme du mot de code.

const DATE_ID := "pearl_harbor_1941"

func _ready() -> void:
	_refresh()
	GameManager.date_unlocked.connect(func(_i, _d): _refresh())
	GameManager.game_loaded.connect(_refresh)

func _refresh() -> void:
	prompt_message = "Relire le télégramme de Pearl Harbor" if GameManager.is_date_unlocked(DATE_ID) else "Utiliser la machine à écrire"

func interact() -> void:
	super.interact()
	get_tree().call_group("enigma_machine", "open_machine")
