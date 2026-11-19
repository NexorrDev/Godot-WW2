extends DocumentItem
class_name SealedDocumentItem

## Dossier scellé : il faut un outil tranchant (ciseaux) pour briser le cachet
## avant de lire la fiche. Une fois la date découverte, le dossier s'ouvre directement.

@export var required_tools: Array[String] = ["coupe_papier"]
## Le cachet de cire (placeholder rouge), masqué quand le dossier est ouvert
@export var seal_path: NodePath = ^"Cachet"

var _title: String = ""

func _ready() -> void:
	super._ready()
	_title = prompt_message.trim_prefix("Consulter : ")
	GameManager.item_obtained.connect(func(_id, _l): _refresh())
	GameManager.date_unlocked.connect(func(_id, _i): _refresh())
	GameManager.game_loaded.connect(_refresh)
	_refresh()

func _is_sealed() -> bool:
	return not GameManager.is_date_unlocked(date_id)

func _refresh() -> void:
	var seal := get_node_or_null(seal_path)
	if seal:
		seal.visible = _is_sealed()
	if not _is_sealed():
		prompt_message = "Consulter : " + _title
	elif GameManager.has_any_item(required_tools):
		prompt_message = "Briser le cachet : " + _title
	else:
		prompt_message = "Dossier scellé : il faut de quoi l'ouvrir"

func interact() -> void:
	if _is_sealed() and not GameManager.has_any_item(required_tools):
		Sfx.play("click", -6.0)
		get_tree().call_group("hud_progression", "show_info", "CACHET DE CIRE", "IL FAUT DES CISEAUX")
		return
	if _is_sealed():
		Sfx.play("stamp", -6.0) # le cachet craque
	super.interact()
