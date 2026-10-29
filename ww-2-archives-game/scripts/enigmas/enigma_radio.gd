extends CanvasLayer

## Interface du Poste de Radio T.S.F. (Date 2 - 3 Septembre 1939)
## Le joueur doit régler la fréquence sur 390 kHz (BBC Londres)
## pour capter la déclaration de guerre de la France et du Royaume-Uni.
##
## Aucun indicateur visuel de proximité : tout passe par le son.
## Plus on s'approche de 390 kHz, plus le grésillement est présent et intense.
## Il faut ensuite rester accordé quelques secondes pour que l'émission se dégage.
## Le son est généré en temps réel (AudioStreamGenerator), aucun fichier audio requis.

signal puzzle_completed

const TARGET_FREQ: float = 390.0
const TOLERANCE: float = 3.0          # Zone d'accord : entre 387 et 393 kHz
const HEAR_RANGE: float = 70.0        # Distance (kHz) à partir de laquelle on commence à entendre le signal
const LOCK_TIME_REQUIRED: float = 1.6 # Secondes à rester accordé avant de capter l'émission
const MIX_RATE: float = 22050.0

@onready var root_control: Control = $RootControl
@onready var freq_slider: HSlider = %FreqSlider
@onready var freq_label: Label = %FreqLabel
@onready var signal_status_label: Label = %SignalStatusLabel
@onready var transcript_panel: PanelContainer = %TranscriptPanel
@onready var transcript_text: RichTextLabel = %TranscriptText
@onready var validate_button: Button = %ValidateButton
@onready var close_button: Button = %CloseButton

var is_open: bool = false
var is_solved: bool = false
var current_frequency: float = 210.0

# --- Audio ---
var audio_player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback = null
var signal_strength: float = 0.0   # 0..1 selon la proximité de 390 kHz
var smooth_strength: float = 0.0   # version lissée (évite les à-coups dans le son)
var lock_time: float = 0.0         # temps passé dans la zone d'accord
var crackle_env: float = 0.0
var lp_state: float = 0.0
var hum_phase: float = 0.0

func _ready() -> void:
	add_to_group("enigma_radio")
	visible = false
	root_control.modulate.a = 0.0
	transcript_panel.visible = false
	validate_button.visible = false
	set_process(false)

	UIStyle.style_slider(freq_slider)
	_setup_audio()

	close_button.pressed.connect(close_radio)
	validate_button.pressed.connect(_on_validate_pressed)

	freq_slider.value_changed.connect(_on_frequency_changed)
	freq_slider.value = current_frequency
	_update_radio_ui(current_frequency)

func _setup_audio() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.12
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = generator
	audio_player.volume_db = -3.0
	add_child(audio_player)

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

	lock_time = 0.0
	smooth_strength = 0.0
	audio_player.play()
	playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	set_process(true)

	var tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 1.0, 0.22)

func close_radio() -> void:
	if not is_open:
		return
	is_open = false
	set_process(false)
	audio_player.stop()
	playback = null

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

	# Proximité de la cible (0 = loin, 1 = pile dessus), courbe progressive
	var distance: float = abs(freq - TARGET_FREQ)
	signal_strength = pow(clampf(1.0 - distance / HEAR_RANGE, 0.0, 1.0), 1.5)

func _process(delta: float) -> void:
	if not is_open:
		return

	smooth_strength = lerpf(smooth_strength, signal_strength, clampf(delta * 8.0, 0.0, 1.0))

	# Il faut rester dans la zone d'accord un petit moment pour capter l'émission
	var distance: float = abs(current_frequency - TARGET_FREQ)
	if distance <= TOLERANCE:
		lock_time += delta
		if lock_time >= LOCK_TIME_REQUIRED and not is_solved:
			_trigger_broadcast_reception()
	else:
		lock_time = maxf(0.0, lock_time - delta * 2.0)

	_fill_audio()

## Génère le grésillement :
## - loin : souffle très faible, quelques claquements rares
## - en approchant : souffle plus fort, claquements de plus en plus denses et marqués
## - accordé : le bruit s'efface au profit d'une porteuse stable (la station se dégage)
func _fill_audio() -> void:
	if playback == null:
		return
	var frames: int = playback.get_frames_available()
	if frames <= 0:
		return

	var s: float = smooth_strength
	var lock: float = clampf(lock_time / LOCK_TIME_REQUIRED, 0.0, 1.0)

	var hiss_amp: float = 0.015 + 0.10 * s
	var crackle_rate: float = 0.00004 + 0.0035 * s * s  # probabilité de claquement par échantillon
	var crackle_amp: float = 0.15 + 0.55 * s
	var noise_mult: float = 1.0 - 0.75 * lock
	var hum_amp: float = 0.10 * lock
	var hum_step: float = TAU * 140.0 / MIX_RATE

	var buf := PackedVector2Array()
	buf.resize(frames)
	for i in frames:
		if randf() < crackle_rate:
			crackle_env = randf_range(0.5, 1.0)
		crackle_env *= 0.97

		var white: float = randf() * 2.0 - 1.0
		lp_state += (white - lp_state) * 0.35

		var v: float = lp_state * hiss_amp + white * crackle_env * crackle_amp * 0.6
		v *= noise_mult

		hum_phase += hum_step
		v += (sin(hum_phase) * 0.6 + sin(hum_phase * 2.0) * 0.25) * hum_amp

		v = clampf(v, -0.9, 0.9)
		buf[i] = Vector2(v, v)
	hum_phase = fmod(hum_phase, TAU)
	playback.push_buffer(buf)

func _trigger_broadcast_reception() -> void:
	is_solved = true
	transcript_panel.visible = true
	validate_button.visible = true
	signal_status_label.text = "[SIGNAL SYNTONISÉ] TRANSMISSION BBC HOME SERVICE EN DIRECT (LONDRES)"
	signal_status_label.add_theme_color_override("font_color", Color(0.98, 0.85, 0.50))

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
