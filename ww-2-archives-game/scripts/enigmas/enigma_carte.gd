extends CanvasLayer

## Date 3 : 10 mai 1940, offensive allemande à l'Ouest.
## Sous le sous-main vert : une carte d'état-major. Le joueur glisse 3 pions d'assaut
## sur les bonnes zones pour contourner la ligne Maginot (Pays-Bas, Belgique, Ardennes).
## Interface entièrement construite par code.

signal puzzle_completed

const MAP_SIZE := Vector2(760, 560)
const DATE_ID := "offensive_ouest_1940"
const PAWN_R := 17.0
const S := 0.80   # échelle d'affichage (la carte tient dans 720p)
const GOOD_ZONES := ["pays_bas", "belgique", "ardennes"]

const MAP_TEXTURE := preload("res://assets/textures/map/carte_europe_1940.png")
# Noms affichés quand un pion est posé sur une mauvaise zone
const ZONE_NAMES := {"maginot": "La ligne Maginot", "ardennes": "Les Ardennes", "pays_bas": "Les Pays-Bas", "belgique": "La Belgique",
	"allemagne": "Le territoire allemand", "france": "La France", "uk": "Le Royaume-Uni"}
# Ordre de test : les zones fines d'abord
const HIT_ORDER := ["maginot", "ardennes", "pays_bas", "belgique", "allemagne", "france", "uk"]

var is_open := false
var is_solved := false

var root: Control
var canvas: Control          # zone de dessin + pions
var status_label: Label
var validate_button: Button
var pawns: Array[Dictionary] = []   # {home, pos, zone, locked}
var dragging := -1
var drag_offset := Vector2.ZERO
var flash_zone := ""
var flash_time := 0.0

func _ready() -> void:
	add_to_group("enigma_carte")
	layer = 20
	visible = false
	_build_ui()
	for i in 3:
		var home := Vector2(560 + i * 60, 545 - 10)
		pawns.append({"home": home, "pos": home, "zone": "", "locked": false})
	GameManager.game_loaded.connect(func(): is_solved = GameManager.is_date_unlocked(DATE_ID))

func _build_ui() -> void:
	root = Control.new()
	UIStyle.fill_rect(root)
	root.modulate.a = 0.0
	add_child(root)

	var dim := ColorRect.new()
	UIStyle.fill_rect(dim)
	dim.color = Color(0.03, 0.03, 0.05, 0.86)
	root.add_child(dim)

	var center := CenterContainer.new()
	UIStyle.fill_rect(center)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.popup_stylebox())
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "CARTE D'ÉTAT-MAJOR  ·  FALL GELB"
	title.add_theme_font_override("font", UIStyle.font_title())
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	vb.add_child(title)

	var hint := Label.new()
	hint.text = "La ligne Maginot est trop solide : il faut la contourner. Glissez les 3 pions d'assaut (en bas à droite) sur les bonnes zones."
	hint.add_theme_font_override("font", UIStyle.font_mono())
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", UIStyle.TEXT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(MAP_SIZE.x * S, 0)
	vb.add_child(hint)

	canvas = Control.new()
	canvas.custom_minimum_size = MAP_SIZE * S
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	canvas.draw.connect(_draw_map)
	canvas.gui_input.connect(_on_canvas_input)
	vb.add_child(canvas)

	status_label = Label.new()
	status_label.add_theme_font_override("font", UIStyle.font_mono())
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", UIStyle.SUBTITLE)
	status_label.text = "Pions placés : 0 / 3"
	vb.add_child(status_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)

	validate_button = UIStyle.make_menu_button("Classer la carte")
	validate_button.visible = false
	validate_button.pressed.connect(_on_validate)
	row.add_child(validate_button)

	var close := UIStyle.make_menu_button("Fermer")
	close.pressed.connect(close_map)
	row.add_child(close)

func open_map() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	Sfx.play("paper_open")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("player", "pause_control")
	if GameManager.is_date_unlocked(DATE_ID) and not is_solved:
		is_solved = true
	if is_solved:
		_place_all_solved()
	create_tween().tween_property(root, "modulate:a", 1.0, 0.2)
	canvas.queue_redraw()

func close_map(resume: bool = true) -> void:
	if not is_open:
		return
	is_open = false
	dragging = -1
	visible = false
	root.modulate.a = 0.0
	Sfx.play("paper_close")
	if resume:
		var viewers := get_tree().get_nodes_in_group("document_viewer")
		if not (viewers.size() > 0 and viewers[0].is_open):
			get_tree().call_group("player", "resume_control")

func _unhandled_input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_ESCAPE or event.keycode == KEY_E):
		close_map()
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------------------
# Logique de glisser-déposer
# ---------------------------------------------------------------------------

func _zone_at(p: Vector2) -> String:
	# les zones plus fines (Maginot) sont testées en premier
	for id in HIT_ORDER:
		if Geometry2D.is_point_in_polygon(p, CarteData.ZONES[id]):
			return id
	return ""

func _slot_pos(id: String) -> Vector2:
	return CarteData.SLOTS[id]

func _on_canvas_input(event_in: InputEvent) -> void:
	if is_solved:
		return
	var event := event_in.duplicate()
	if event is InputEventMouse:
		event.position = event.position / S
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for i in pawns.size():
				if not pawns[i]["locked"] and event.position.distance_to(pawns[i]["pos"]) <= PAWN_R + 4.0:
					dragging = i
					drag_offset = pawns[i]["pos"] - event.position
					Sfx.play("click", -8.0)
					break
		elif dragging >= 0:
			_drop(dragging, event.position)
			dragging = -1
		canvas.queue_redraw()
	elif event is InputEventMouseMotion and dragging >= 0:
		pawns[dragging]["pos"] = (event.position + drag_offset).clamp(Vector2(PAWN_R, PAWN_R), MAP_SIZE - Vector2(PAWN_R, PAWN_R))
		canvas.queue_redraw()

func _drop(i: int, mouse: Vector2) -> void:
	var zone := _zone_at(mouse)
	var taken := false
	for k in pawns.size():
		if k != i and pawns[k]["zone"] == zone:
			taken = true
	if zone in GOOD_ZONES and not taken:
		pawns[i]["zone"] = zone
		pawns[i]["locked"] = true
		pawns[i]["pos"] = _slot_pos(zone)
		Sfx.play("stamp", -8.0)
	else:
		pawns[i]["pos"] = pawns[i]["home"]
		flash_zone = zone
		flash_time = 0.6
		if zone != "" and not taken:
			status_label.text = "%s : ce n'est pas là que l'attaque doit passer." % ZONE_NAMES[zone]
		elif taken:
			status_label.text = "Un seul pion par zone."
		Sfx.play("click", -4.0)
		set_process(true)
	_update_status()

func _update_status() -> void:
	var n := 0
	for p in pawns:
		if p["locked"]:
			n += 1
	if n == 3:
		is_solved = true
		status_label.text = "Percée de Sedan : les blindés passent par les Ardennes. Offensive du 10 mai 1940 !"
		status_label.add_theme_color_override("font_color", UIStyle.GOLD)
		validate_button.visible = true
	elif flash_time <= 0.0 or status_label.text.begins_with("Pions"):
		status_label.text = "Pions placés : %d / 3" % n

func _place_all_solved() -> void:
	for i in 3:
		pawns[i]["zone"] = GOOD_ZONES[i]
		pawns[i]["locked"] = true
		pawns[i]["pos"] = _slot_pos(GOOD_ZONES[i])
	status_label.text = "Archive déjà classée : offensive allemande du 10 mai 1940."
	status_label.add_theme_color_override("font_color", UIStyle.GOLD)
	validate_button.visible = true
	validate_button.text = "Relire la fiche"

func _process(delta: float) -> void:
	if flash_time > 0.0:
		flash_time -= delta
		if flash_time <= 0.0:
			flash_zone = ""
			set_process(false)
		canvas.queue_redraw()

func _on_validate() -> void:
	close_map(false)
	get_tree().call_group("document_viewer", "open_document", DATE_ID)
	puzzle_completed.emit()

# ---------------------------------------------------------------------------
# Dessin de la carte
# ---------------------------------------------------------------------------

func _draw_map() -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(S, S))
	var font := UIStyle.font_mono()
	var ink := Color(0.20, 0.15, 0.10)
	canvas.draw_texture_rect(MAP_TEXTURE, Rect2(Vector2.ZERO, MAP_SIZE), false)
	# zone refusée : brève lueur rouge
	if flash_zone != "" and CarteData.ZONES.has(flash_zone):
		canvas.draw_colored_polygon(CarteData.ZONES[flash_zone], Color(0.8, 0.12, 0.08, 0.35))
	# noms de pays et de régions
	for l in CarteData.LABELS:
		var name: String = l[0]
		if name == "SUISSE":
			continue
		var size: int = l[2]
		var is_sea: bool = name in ["La Manche", "Mer du Nord"]
		var col := Color(0.25, 0.38, 0.45) if is_sea else (Color(0.45, 0.10, 0.08) if name == "LIGNE MAGINOT" else ink)
		var w := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		canvas.draw_string(font, l[1] - Vector2(w / 2.0, 0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	# villes
	for city in CarteData.CITIES:
		var c: Vector2 = CarteData.CITIES[city]
		canvas.draw_circle(c, 3.0, ink)
		canvas.draw_string(font, c + Vector2(6, 4), city, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, ink)
	# cadre de carte
	canvas.draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.25, 0.18, 0.12), false, 3.0)
	# bac des pions
	canvas.draw_rect(Rect2(540, 512, 205, 44), Color(0.14, 0.12, 0.10, 0.88))
	canvas.draw_string(font, Vector2(548, 507), "PIONS D'ASSAUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.95, 0.88, 0.7))
	for i in pawns.size():
		var p: Vector2 = pawns[i]["pos"]
		var locked: bool = pawns[i]["locked"]
		canvas.draw_circle(p + Vector2(2, 3), PAWN_R, Color(0, 0, 0, 0.4))
		canvas.draw_circle(p, PAWN_R, Color(0.75, 0.15, 0.12) if locked else Color(0.60, 0.13, 0.10))
		canvas.draw_arc(p, PAWN_R, 0, TAU, 32, Color(0.95, 0.85, 0.6), 2.0)
		canvas.draw_string(font, p + Vector2(-5, 5), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.85, 0.6))
