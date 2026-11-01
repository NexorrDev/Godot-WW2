extends Interactable
class_name TiroirCadenasItem

## Tiroir du milieu du classeur vert, fermé par un cadenas à 4 chiffres (date 5 : Barbarossa).
## Une fois la date trouvée, le tiroir reste ouvert (visuel géré par ClasseurVert).

const DATE_ID := "barbarossa_1941"

signal drawer_state_changed

func _ready() -> void:
	_refresh()
	GameManager.date_unlocked.connect(func(_i, _d): _refresh())
	GameManager.game_loaded.connect(_refresh)

func is_open() -> bool:
	return GameManager.is_date_unlocked(DATE_ID)

func _refresh() -> void:
	prompt_message = "Consulter : Dossier Barbarossa (22 Juin 1941)" if is_open() else "Ouvrir le tiroir (cadenas à 4 chiffres)"
	drawer_state_changed.emit()

func interact() -> void:
	super.interact()
	if is_open():
		get_tree().call_group("document_viewer", "open_document", DATE_ID)
	else:
		get_tree().call_group("enigma_cadenas", "open_lock")
