extends CanvasLayer

## Date 3 : 10 mai 1940, offensive allemande à l'Ouest.
## Sous le sous-main vert : une carte d'état-major. Le joueur glisse 3 pions d'assaut
## sur les bonnes zones pour contourner la ligne Maginot (Pays-Bas, Belgique, Ardennes).
## Interface entièrement construite par code.

signal puzzle_completed

const MAP_SIZE := Vector2(760, 560)
const DATE_ID := "offensive_ouest_1940"
const PAWN_R := 17.0
const S := 0.76   # échelle d'affichage (la carte tient dans 720p)
const GOOD_ZONES := ["pays_bas", "belgique", "ardennes"]

# Zones (coordonnées de la carte). "ok" = zone valide, sinon leurre
const ZONES := {
	"pays_bas": {"name": "PAYS-BAS", "color": Color(0.80, 0.70, 0.52), "label": Vector2(385, 66),
		"poly": [Vector2(330, 40), Vector2(430, 30), Vector2(450, 90), Vector2(430, 135), Vector2(340, 130), Vector2(320, 80)]},
	"belgique": {"name": "BELGIQUE", "color": Color(0.74, 0.74, 0.55), "label": Vector2(335, 158),
		"poly": [Vector2(250, 140), Vector2(340, 130), Vector2(430, 135), Vector2(430, 205), Vector2(330, 215), Vector2(240, 200)]},
	"ardennes": {"name": "ARDENNES", "color": Color(0.52, 0.62, 0.45), "label": Vector2(385, 248),
		"poly": [Vector2(330, 215), Vector2(430, 205), Vector2(470, 260), Vector2(430, 310), Vector2(340, 305), Vector2(310, 255)]},
	"allemagne": {"name": "ALLEMAGNE", "color": Color(0.64, 0.60, 0.55), "label": Vector2(610, 200),
		"poly": [Vector2(460, 35), Vector2(740, 30), Vector2(740, 520), Vector2(480, 520), Vector2(500, 420), Vector2(470, 330), Vector2(430, 310), Vector2(470, 260), Vector2(430, 205), Vector2(430, 135), Vector2(450, 90)]},
	"france": {"name": "FRANCE", "color": Color(0.70, 0.76, 0.82), "label": Vector2(190, 430),
		"poly": [Vector2(70, 230), Vector2(240, 200), Vector2(330, 215), Vector2(310, 255), Vector2(340, 305), Vector2(430, 310), Vector2(470, 330), Vector2(500, 420), Vector2(480, 520), Vector2(60, 520), Vector2(40, 380)]},
	"maginot": {"name": "LIGNE MAGINOT", "color": Color(0.60, 0.63, 0.70), "label": Vector2(425, 420),
		"poly": [Vector2(430, 320), Vector2(475, 335), Vector2(500, 420), Vector2(482, 500), Vector2(440, 500), Vector2(455, 420)]},
	"uk": {"name": "ROYAUME-UNI", "color": Color(0.74, 0.68, 0.74), "label": Vector2(125, 115),
		"poly": [Vector2(60, 60), Vector2(170, 40), Vector2(200, 120), Vector2(150, 190), Vector2(80, 170)]},
}

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
	for id in ["maginot", "pays_bas", "belgique", "ardennes", "allemagne", "france", "uk"]:
		if Geometry2D.is_point_in_polygon(p, PackedVector2Array(ZONES[id]["poly"])):
			return id
	return ""

func _zone_center(id: String) -> Vector2:
	var c := Vector2.ZERO
	var poly: Array = ZONES[id]["poly"]
	for v in poly:
		c += v
	return c / poly.size()

func _slot_pos(id: String) -> Vector2:
	# si plusieurs pions voulaient la même zone on ne les superpose pas (une zone = un pion)
	return _zone_center(id) + Vector2(0, 26)

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
			status_label.text = "%s : un état-major ne perce pas ici." % ZONES[zone]["name"]
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
	canvas.draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.58, 0.72, 0.80)) # mer
	canvas.draw_string(font, Vector2(150, 245), "LA MANCHE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.28, 0.40, 0.50))
	canvas.draw_string(font, Vector2(245, 30), "MER DU NORD", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.28, 0.40, 0.50))
	for id in ZONES:
		var z: Dictionary = ZONES[id]
		var poly := PackedVector2Array(z["poly"])
		var col: Color = z["color"]
		if id == flash_zone:
			col = col.lerp(Color(0.85, 0.25, 0.2), 0.6)
		canvas.draw_colored_polygon(poly, col)
		var closed := poly.duplicate()
		closed.append(poly[0])
		canvas.draw_polyline(closed, Color(0.25, 0.22, 0.18), 2.0 if id == "maginot" else 1.5)
		var lab := Vector2(z["label"])
		var size := 12 if id in ["pays_bas", "maginot"] else 14
		canvas.draw_string(font, lab - Vector2(float(str(z["name"]).length()) * size * 0.3, 0), z["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.14, 0.12, 0.10))
	# Paris (leurre)
	canvas.draw_circle(Vector2(210, 330), 5, Color(0.2, 0.15, 0.1))
	canvas.draw_string(font, Vector2(222, 334), "Paris", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.14, 0.12, 0.10))
	# Bac des pions
	canvas.draw_rect(Rect2(540, 512, 205, 44), Color(0.14, 0.12, 0.10, 0.85))
	canvas.draw_string(font, Vector2(548, 507), "PIONS D'ASSAUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UIStyle.INK)
	for i in pawns.size():
		var p: Vector2 = pawns[i]["pos"]
		var locked: bool = pawns[i]["locked"]
		canvas.draw_circle(p + Vector2(2, 3), PAWN_R, Color(0, 0, 0, 0.35))
		canvas.draw_circle(p, PAWN_R, Color(0.55, 0.12, 0.10) if not locked else Color(0.75, 0.15, 0.12))
		canvas.draw_arc(p, PAWN_R, 0, TAU, 32, Color(0.95, 0.85, 0.6), 2.0)
		canvas.draw_string(font, p + Vector2(-5, 5), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.85, 0.6))
