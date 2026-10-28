extends Interactable
class_name DocumentItem

## Objet 3D interactif (boîte, dossier, télégramme) qui ouvre une fiche historique à l'écran.
## Il suffit de renseigner 'date_id' dans l'inspecteur (ex: "pologne_1939").

@export var date_id: String = "pologne_1939"

func _ready() -> void:
	# Si aucun message personnalisé n'est mis, on utilise le titre de la fiche
	if prompt_message == "Examiner" and not date_id.is_empty():
		var info = HistoricalData.get_date_info(date_id)
		if not info.is_empty():
			prompt_message = "Consulter : " + info.get("title", "Document")

func interact() -> void:
	super.interact()
	if not date_id.is_empty():
		get_tree().call_group("document_viewer", "open_document", date_id)
