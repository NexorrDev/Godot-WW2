extends Interactable
class_name OverlayItem

## Objet générique du décor : ouvre une énigme (CanvasLayer d'un groupe) ou une note.
## - group_name / call_method / call_arg : ce qu'on appelle quand on l'utilise
## - date_id : si cette date est déjà trouvée, le texte d'invite change et on relit le document
## - need_item : objet d'inventaire nécessaire (sinon un message d'aide s'affiche)

@export var group_name: String = ""
@export var call_method: String = ""
@export var call_arg: String = ""
@export var date_id: String = ""
@export var prompt_todo: String = "Examiner"
@export var prompt_done: String = ""
@export var need_item: String = ""
@export var need_message: String = "Il me manque quelque chose pour ça."

func _ready() -> void:
	_refresh()
	GameManager.date_unlocked.connect(func(_i, _d): _refresh())
	GameManager.game_loaded.connect(_refresh)
	GameManager.item_obtained.connect(func(_a, _b): _refresh())

func _refresh() -> void:
	if date_id != "" and prompt_done != "" and GameManager.is_date_unlocked(date_id):
		prompt_message = prompt_done
	else:
		prompt_message = prompt_todo

func interact() -> void:
	super.interact()
	var done := date_id != "" and GameManager.is_date_unlocked(date_id)
	if need_item != "" and not done and not GameManager.has_item(need_item):
		get_tree().call_group("hud_progression", "show_info", "INDICE", need_message)
		Sfx.play("click", -8.0)
		return
	if done and prompt_done != "":
		get_tree().call_group("document_viewer", "open_document", date_id)
		return
	if call_arg != "":
		get_tree().call_group(group_name, call_method, call_arg)
	else:
		get_tree().call_group(group_name, call_method)
