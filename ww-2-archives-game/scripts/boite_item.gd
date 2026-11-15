extends Interactable
class_name BoiteItem

## Boîte d'archives « MÉDITERRANÉE » tout en haut de l'étagère (date 10 : Sicile, opération Husky).

const DATE_ID := "sicile_1943"

func _ready() -> void:
	GameManager.date_unlocked.connect(func(_i, _d): _refresh())
	GameManager.game_loaded.connect(_refresh)
	_refresh()

func _chair_pushed() -> bool:
	for c in get_tree().get_nodes_in_group("chaise_etagere"):
		if c.get("pushed"):
			return true
	return false

func _refresh() -> void:
	if GameManager.is_date_unlocked(DATE_ID):
		prompt_message = "Consulter : Boîte « Méditerranée » (Sicile, 10 Juillet 1943)"
	else:
		prompt_message = "Boîte d'archives « MÉDITERRANÉE » (tout en haut)"

func interact() -> void:
	super.interact()
	if GameManager.is_date_unlocked(DATE_ID) or _chair_pushed():
		get_tree().call_group("document_viewer", "open_document", DATE_ID)
		_refresh()
	else:
		Sfx.play("click", -8.0)
		get_tree().call_group("hud_progression", "show_info", "TROP HAUT", "Impossible de l'atteindre debout. Il faut monter sur quelque chose…")
