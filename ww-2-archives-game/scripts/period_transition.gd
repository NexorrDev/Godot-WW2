extends CanvasLayer
class_name PeriodTransition

## Transitions entre les périodes : fondu au noir, carte-titre (période, titre, années, moment de la journée),
## changement d'ambiance sous l'écran noir, puis fondu vers la nouvelle lumière.
## - intro() : carte de la période 1 au début d'une nouvelle partie
## - la transition 1→2 et 2→3 se lance toute seule, dès que la dernière fiche de la période est refermée.

const CARDS := {
	1: {"kicker": "PÉRIODE 1", "title": "LES VICTOIRES DE L'AXE", "years": "1939 — 1941", "moment": "AVANT L'AUBE"},
	2: {"kicker": "PÉRIODE 2", "title": "LE TOURNANT DE LA GUERRE", "years": "1942 — 1943", "moment": "MIDI"},
	3: {"kicker": "PÉRIODE 3", "title": "LA VICTOIRE DES ALLIÉS", "years": "1944 — 1945", "moment": "LE SOIR TOMBE"},
}

var black: ColorRect
var box: VBoxContainer
var kicker: Label
var title: Label
var line: ColorRect
var years: Label
var moment: Label
var pending := 0
var running := false

func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("period_transition")
	black = ColorRect.new()
	UIStyle.fill_rect(black)
	black.color = Color(0, 0, 0, 1)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size = Vector2(900, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.add_child(box)
	kicker = _label(26, UIStyle.GOLD)
	title = _label(58, UIStyle.TEXT)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line = ColorRect.new()
	line.color = UIStyle.GOLD
	line.custom_minimum_size = Vector2(0, 2)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	years = _label(30, UIStyle.TEXT_DIM)
	moment = _label(22, UIStyle.GOLD)
	for n in [kicker, title, line, years, moment]:
		box.add_child(n)
	black.color.a = 0.0
	black.visible = false
	GameManager.period_changed.connect(_on_period_changed)

func _label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", UIStyle.font_title())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _on_period_changed(p: int) -> void:
	if GameManager.is_loading or p < 2:
		return
	pending = p
	# on attend que la fiche d'archive qui vient de s'ouvrir soit refermée
	var waiting := false
	for dv in get_tree().get_nodes_in_group("document_viewer"):
		if dv.is_open or dv.visible:
			waiting = true
			if not dv.document_closed.is_connected(_on_doc_closed):
				dv.document_closed.connect(_on_doc_closed, CONNECT_ONE_SHOT)
	if not waiting:
		_start_pending.call_deferred()

func _on_doc_closed(_id: String) -> void:
	await get_tree().create_timer(0.35).timeout
	_start_pending()

func _start_pending() -> void:
	if pending > 0 and not running:
		var p := pending
		pending = 0
		play(p, true)

func intro() -> void:
	play(GameManager.current_period, false)

## Joue la carte d'une période. change_ambiance : applique la nouvelle lumière sous l'écran noir.
func play(p: int, change_ambiance: bool) -> void:
	if running:
		return
	running = true
	var card: Dictionary = CARDS.get(p, CARDS[1])
	kicker.text = card["kicker"]
	title.text = card["title"]
	years.text = card["years"]
	moment.text = card["moment"]
	for n in [kicker, title, line, years, moment]:
		n.modulate.a = 0.0
	line.custom_minimum_size = Vector2(0, 2)
	get_tree().call_group("player", "pause_control")
	black.visible = true
	if change_ambiance:
		# fondu vers le noir
		var t0 := create_tween()
		t0.tween_property(black, "color:a", 1.0, 1.3)
		await t0.finished
		Sfx.play("stamp", -2.0)
		get_tree().call_group("office_room", "apply_period", p)
	else:
		black.color.a = 1.0
	await get_tree().create_timer(0.5).timeout
	# la carte apparaît ligne par ligne
	await _reveal(kicker, 0.8)
	await _reveal(title, 1.1)
	var tl := create_tween()
	tl.tween_property(line, "modulate:a", 1.0, 0.2)
	tl.parallel().tween_property(line, "custom_minimum_size:x", 420.0, 0.9).set_trans(Tween.TRANS_SINE)
	await tl.finished
	await _reveal(years, 0.8)
	await _reveal(moment, 0.8)
	await get_tree().create_timer(2.2).timeout
	# la carte s'efface, puis la pièce réapparaît dans sa nouvelle lumière
	var t1 := create_tween()
	t1.tween_property(box, "modulate:a", 0.0, 0.9)
	await t1.finished
	var t2 := create_tween()
	t2.tween_property(black, "color:a", 0.0, 2.2).set_trans(Tween.TRANS_SINE)
	await t2.finished
	box.modulate.a = 1.0
	black.visible = false
	running = false
	get_tree().call_group("player", "resume_control")

func _reveal(n: Control, d: float) -> void:
	var t := create_tween()
	t.tween_property(n, "modulate:a", 1.0, d)
	await t.finished
