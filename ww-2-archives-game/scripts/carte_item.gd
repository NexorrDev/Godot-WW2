extends Interactable
class_name CarteItem

## Sous-main vert sur le bureau : on le soulève pour découvrir la carte d'état-major (date 3).

func _ready() -> void:
	_refresh()
	GameManager.date_unlocked.connect(func(_id, _i): _refresh())
	GameManager.game_loaded.connect(_refresh)

func _refresh() -> void:
	if GameManager.is_date_unlocked("offensive_ouest_1940"):
		prompt_message = "Consulter : Carte d'état-major (10 Mai 1940)"
	else:
		prompt_message = "Soulever le sous-main"

func interact() -> void:
	super.interact()
	get_tree().call_group("enigma_carte", "open_map")
