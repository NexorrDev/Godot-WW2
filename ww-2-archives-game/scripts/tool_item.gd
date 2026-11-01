extends Interactable
class_name ToolItem

## Objet à ramasser (coupe-papier, ciseaux...). Une fois pris il disparaît de la scène
## et reste dans l'inventaire du GameManager (sauvegardé).
## Les modèles 3D de Louka remplaceront les placeholders : il suffit de garder ce script.

@export var tool_id: String = "coupe_papier"
@export var tool_label: String = "Coupe-papier"

func _ready() -> void:
	GameManager.game_loaded.connect(_refresh)
	_refresh()
	if prompt_message == "Examiner":
		prompt_message = "Prendre : " + tool_label

func _refresh() -> void:
	if GameManager.has_item(tool_id):
		_take_visual()

func _take_visual() -> void:
	visible = false
	collision_layer = 0
	collision_mask = 0

func interact() -> void:
	super.interact()
	if GameManager.has_item(tool_id):
		return
	Sfx.play("click", -4.0)
	GameManager.give_item(tool_id, tool_label)
	_take_visual()
	get_tree().call_group("hud_progression", "show_info", "OBJET RAMASSÉ", tool_label.to_upper())
