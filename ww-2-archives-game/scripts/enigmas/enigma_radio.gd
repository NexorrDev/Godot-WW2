extends CanvasLayer

## Interface du Poste de Radio T.S.F. (Date 2 - 3 Septembre 1939)
## Le joueur doit régler la fréquence sur 390 kHz (BBC Londres)
## pour capter la déclaration de guerre de la France et du Royaume-Uni.
## Conception authentique d'époque (ébénisterie, cadran ambré, tube cathodique 6E5).

signal puzzle_completed

const TARGET_FREQ: float = 390.0
const TOLERANCE: float = 3.0 # Entre 387 et 393 kHz

@onready var root_control: Control = $RootControl
@onready var freq_slider: HSlider = %FreqSlider
@onready var freq_label: Label = %FreqLabel
@onready var signal_bar: ProgressBar = %SignalBar
@onready var signal_status_label: Label = %SignalStatusLabel
@onready var transcript_panel: PanelContainer = %TranscriptPanel
@onready var transcript_text: RichTextLabel = %TranscriptText
@onready var validate_button: Button = %ValidateButton
@onready var close_button: Button = %CloseButton

var is_open: bool = false
var is_solved: bool = false
var current_frequency: float = 210.0

func _ready() -> void:
	add_to_group("enigma_radio")
	visible = false
	root_control.modulate.a = 0.0
	transcript_panel.visible = false
	validate_button.visible = false
	
	close_button.pressed.connect(close_radio)
	validate_button.pressed.connect(_on_validate_pressed)
	
	freq_slider.value_changed.connect(_on_frequency_changed)
	freq_slider.value = current_frequency
	_update_radio_ui(current_frequency)

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
		
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and (event.keycode == KEY_ESCAPE or event.keycode == KEY_E) and event.pressed and not event.echo):
		close_radio()
		get_viewport().set_input_as_handled()

func open_radio() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("player", "pause_control")
	
	var tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 1.0, 0.22)

func close_radio() -> void:
	if not is_open:
		return
	is_open = false
	
	var tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 0.0, 0.18)
	await tween.finished
	visible = false
	
	# Réactiver les contrôles si le viewer n'est pas ouvert
	var doc_viewers = get_tree().get_nodes_in_group("document_viewer")
	var doc_open = doc_viewers.size() > 0 and doc_viewers[0].is_open
	if not doc_open:
		get_tree().call_group("player", "resume_control")

func _on_frequency_changed(new_val: float) -> void:
	current_frequency = new_val
	_update_radio_ui(new_val)

func _update_radio_ui(freq: float) -> void:
	freq_label.text = "FRÉQUENCE : %.0f kHz  //  LONGUEUR D'ONDE : %.0f m" % [freq, (300000.0 / max(freq, 1.0))]
	
	# Calcul de la proximité avec la cible 390 kHz (0.0 à 1.0)
	var distance = abs(freq - TARGET_FREQ)
	var signal_strength: float = 0.0
	
	if distance < 50.0:
		signal_strength = clamp(1.0 - (distance / 50.0), 0.0, 1.0)
	
	signal_bar.value = signal_strength * 100.0
	
	# Mise à jour de l'état sans émojis, style télégraphique d'époque
	if distance <= TOLERANCE:
		signal_status_label.text = "[SIGNAL SYNTONISÉ] TRANSMISSION BBC HOME SERVICE EN DIRECT (LONDRES)"
		signal_status_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
		
		if not is_solved:
			_trigger_broadcast_reception()
	elif distance < 15.0:
		signal_status_label.text = "[PORTEUSE DÉTECTÉE] VOIX AUDIBLE SOUS LES PARASITES — AFFINER L'ACCORD"
		signal_status_label.add_theme_color_override("font_color", Color(0.85, 0.70, 0.35))
	elif distance < 35.0:
		signal_status_label.text = "[SIGNAL FAIBLE] INTERFÉRENCES ÉLECTROMAGNÉTIQUES CONTINUES"
		signal_status_label.add_theme_color_override("font_color", Color(0.70, 0.55, 0.30))
	else:
		signal_status_label.text = "[SIGNAL NUL] HORS DE LA PORTEUSE RADIO — GRÉSILLEMENTS DE L'ÉTHER"
		signal_status_label.add_theme_color_override("font_color", Color(0.50, 0.45, 0.40))

func _trigger_broadcast_reception() -> void:
	is_solved = true
	transcript_panel.visible = true
	validate_button.visible = true
	
	transcript_text.text = (
		"[b]MINISTÈRE DE L'INFORMATION BRITANNIQUE • LONDRES (11h15)[/b]\n" +
		"[i]« I am speaking to you from the Cabinet Room at 10 Downing Street... This morning the British Ambassador in Berlin handed the German Government a final note stating that, unless we heard from them by 11 o'clock that they were prepared at once to withdraw their troops from Poland, a state of war would exist between us. I have to tell you now that no such undertaking has been received, and that consequently this country is at war with Germany. »[/i]\n" +
		"— Neville Chamberlain, Premier ministre du Royaume-Uni\n\n" +
		"[b]PRÉSIDENCE DU CONSEIL • PARIS (17h00)[/b]\n" +
		"[i]« Depuis le 1er septembre à l'aube, la Pologne est victime de la plus brutale et de la plus cynique des agressions... La France et l'Angleterre ne peuvent tolérer cet attentat. Le gouvernement français décrète la mobilisation générale et déclare l'état de guerre. »[/i]\n" +
		"— Édouard Daladier, Président du Conseil des ministres"
	)
	
	var tween = create_tween()
	transcript_panel.modulate.a = 0.0
	tween.tween_property(transcript_panel, "modulate:a", 1.0, 0.35)

func _on_validate_pressed() -> void:
	close_radio()
	# Débloque l'archive officielle et ouvre la fiche de cours
	GameManager.unlock_date("declaration_guerre_1939")
	get_tree().call_group("document_viewer", "open_document", "declaration_guerre_1939")
	puzzle_completed.emit()
