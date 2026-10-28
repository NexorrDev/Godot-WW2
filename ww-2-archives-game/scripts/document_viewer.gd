extends CanvasLayer

## Interface de lecture de document d'archive militaire
## Affiche la fiche historique avec une mise en page authentique d'époque (dossier classifié 1939-1945).
## Sans émojis, avec typographie d'état-major et vocabulaire officiel du cours.

signal document_closed(date_id: String)

@onready var root_control: Control = $RootControl
@onready var period_label: Label = %PeriodLabel
@onready var ref_label: Label = %RefLabel
@onready var date_label: Label = %DateLabel
@onready var title_label: Label = %TitleLabel
@onready var location_label: Label = %LocationLabel
@onready var summary_label: RichTextLabel = %SummaryLabel
@onready var close_button: Button = %CloseButton

var current_date_id: String = ""
var is_open: bool = false

func _ready() -> void:
	add_to_group("document_viewer")
	visible = false
	root_control.modulate.a = 0.0
	close_button.pressed.connect(close_document)

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
		
	# Fermer avec Échap ou la touche E
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and (event.keycode == KEY_ESCAPE or event.keycode == KEY_E) and event.pressed and not event.echo):
		close_document()
		get_viewport().set_input_as_handled()

func open_document(date_id: String) -> void:
	var info = HistoricalData.get_date_info(date_id)
	if info.is_empty():
		push_warning("[DocumentViewer] Date inconnue : " + date_id)
		return
		
	current_date_id = date_id
	is_open = true
	
	# Enregistre la découverte dans le GameManager
	GameManager.unlock_date(date_id)
	
	# Remplissage des 4 informations demandées par le professeur (format archive d'état-major)
	period_label.text = info.get("period_title", "").to_upper()
	ref_label.text = "RÉFÉRENCE : GQG/ARCH-%s" % date_id.to_upper()
	date_label.text = "DATE OFFICIELLE : " + info.get("date_str", "")
	title_label.text = "OBJET : " + info.get("title", "").to_upper()
	location_label.text = "THÉÂTRE DES OPÉRATIONS : " + info.get("location", "")
	summary_label.text = "[font_size=16]" + info.get("summary", "") + "[/font_size]"
	
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("player", "pause_control")
	
	var tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 1.0, 0.22)

func close_document() -> void:
	if not is_open:
		return
	is_open = false
	
	var tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 0.0, 0.18)
	await tween.finished
	visible = false
	
	get_tree().call_group("player", "resume_control")
	document_closed.emit(current_date_id)
