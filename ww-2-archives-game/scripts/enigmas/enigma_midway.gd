extends CanvasLayer

## Date 7 : 4-7 juin 1942, bataille de Midway.
## Photo aérienne du Pacifique : à l'œil nu on ne voit que des points. Avec la loupe en laiton
## (à ramasser), on survole la photo ; au bon endroit apparaît le porte-avions Akagi en flammes.
## Cliquer sur le porte-avions identifié valide la date.

signal puzzle_completed

const DATE_ID := "midway_1942"
const PHOTO := Vector2(760, 470)
const LENS := 250.0
const ZOOM := 3.4
# position (en fraction de la photo) de l'Akagi
const AKAGI := Vector2(0.69, 0.36)
const AKAGI_R := 0.045

# navires leurres : [position, longueur, type] ; type 0 = destroyer, 1 = croiseur, 2 = porte-avions intact
const SHIPS := [
	[Vector2(0.24, 0.62), 15.0, 1], [Vector2(0.30, 0.55), 11.0, 0], [Vector2(0.19, 0.70), 11.0, 0],
	[Vector2(0.55, 0.78), 18.0, 1], [Vector2(0.50, 0.70), 11.0, 0],
	[Vector2(0.80, 0.70), 24.0, 2], [Vector2(0.86, 0.62), 11.0, 0],
	[Vector2(0.62, 0.26), 12.0, 0], [Vector2(0.76, 0.26), 13.0, 1],
	[Vector2(0.15, 0.20), 12.0, 0], [Vector2(0.40, 0.30), 18.0, 1],
]

var is_open := false
var solved := false
var root: Control
var photo: Control
var lens: Control
var lens_view: Control
var status: Label
var close_btn: Button
var sea: ImageTexture
var lens_center := Vector2(0.5, 0.5)  # fraction de la photo
var has_loupe := false

func _ready() -> void:
	add_to_group("enigma_midway")
	layer = 20
	visible = false
	_make_sea()
	_build_ui()

func _make_sea() -> void:
	var n := FastNoiseLite.new()
	n.seed = 1942
	n.frequency = 0.035
	n.fractal_octaves = 4
	var n2 := FastNoiseLite.new()
	n2.seed = 7
	n2.frequency = 0.5
	var w := int(PHOTO.x)
	var h := int(PHOTO.y)
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var v := 0.42 + n.get_noise_2d(x, y) * 0.22 + n2.get_noise_2d(x, y) * 0.045
			# vignettage
			var dx := (x / float(w) - 0.5)
			var dy := (y / float(h) - 0.5)
			v *= 1.0 - (dx * dx + dy * dy) * 1.1
			img.set_pixel(x, y, Color(v * 0.95, v * 0.97, v * 1.0))
	sea = ImageTexture.create_from_image(img)

func _build_ui() -> void:
	root = Control.new()
	UIStyle.fill_rect(root)
	root.modulate.a = 0.0
	add_child(root)
	var dim := ColorRect.new()
	UIStyle.fill_rect(dim)
	dim.color = Color(0.03, 0.03, 0.05, 0.9)
	root.add_child(dim)
	var center := CenterContainer.new()
	UIStyle.fill_rect(center)
	root.add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	center.add_child(vb)
	var title := Label.new()
	title.text = "PHOTO AÉRIENNE — PACIFIQUE CENTRAL, JUIN 1942"
	title.add_theme_font_override("font", UIStyle.font_title())
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	vb.add_child(title)

	photo = Control.new()
	photo.custom_minimum_size = PHOTO
	photo.mouse_filter = Control.MOUSE_FILTER_STOP
	photo.draw.connect(_draw_photo)
	photo.gui_input.connect(_photo_input)
	vb.add_child(photo)

	lens = Control.new()
	lens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lens.size = Vector2(LENS, LENS)
	lens.clip_contents = true
	photo.add_child(lens)
	lens_view = Control.new()
	lens_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lens_view.draw.connect(_draw_lens)
	lens.add_child(lens_view)
	lens_view.size = Vector2(LENS, LENS)

	status = Label.new()
	status.add_theme_font_override("font", UIStyle.font_mono())
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", UIStyle.TEXT)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(PHOTO.x, 0)
	vb.add_child(status)
	close_btn = UIStyle.make_menu_button("Fermer")
	close_btn.pressed.connect(close_photo)
	vb.add_child(close_btn)

# ---------------------------------------------------------------------------

func _draw_ship(c: Control, p: Vector2, length: float, kind: int, scale: float, detail: bool, burning: bool, time: float) -> void:
	var L := length * scale
	var W := L * (0.26 if kind != 2 else 0.30)
	var dark := Color(0.10, 0.11, 0.12)
	# sillage
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(-L * 0.5, 0), p + Vector2(-L * 1.6, -W * 0.35), p + Vector2(-L * 1.6, W * 0.35)]), Color(0.9, 0.92, 0.95, 0.35))
	var hull := PackedVector2Array([p + Vector2(-L * 0.5, -W * 0.5), p + Vector2(L * 0.35, -W * 0.5), p + Vector2(L * 0.5, 0), p + Vector2(L * 0.35, W * 0.5), p + Vector2(-L * 0.5, W * 0.5)])
	c.draw_colored_polygon(hull, dark if not burning else Color(0.07, 0.06, 0.06))
	if not detail:
		return
	if kind == 2 or burning:
		# pont d'envol clair
		var deck := Rect2(p + Vector2(-L * 0.46, -W * 0.4), Vector2(L * 0.88, W * 0.8))
		c.draw_rect(deck, Color(0.45, 0.43, 0.38) if not burning else Color(0.30, 0.27, 0.24))
		c.draw_line(p + Vector2(-L * 0.4, 0), p + Vector2(L * 0.38, 0), Color(0.85, 0.85, 0.8, 0.8), maxf(1.0, scale * 0.12))
		c.draw_rect(Rect2(p + Vector2(L * 0.05, -W * 0.5), Vector2(L * 0.12, W * 0.18)), Color(0.2, 0.2, 0.2))  # îlot
		# ascenseurs
		c.draw_rect(Rect2(p + Vector2(-L * 0.25, -W * 0.22), Vector2(L * 0.14, W * 0.44)), Color(0.55, 0.5, 0.42))
	else:
		c.draw_rect(Rect2(p + Vector2(-L * 0.1, -W * 0.18), Vector2(L * 0.2, W * 0.36)), Color(0.3, 0.3, 0.32))
		c.draw_rect(Rect2(p + Vector2(L * 0.1, -W * 0.12), Vector2(L * 0.08, W * 0.24)), Color(0.22, 0.22, 0.24))
	if burning:
		# fumée noire + flammes
		for i in 9:
			var a := float(i) / 9.0
			var sp := p + Vector2(-L * 0.1 - a * L * 1.3, -a * L * 0.55 + sin(time * 3.0 + i) * 3.0)
			c.draw_circle(sp, scale * (3.5 + a * 6.0), Color(0.05, 0.05, 0.06, 0.75 - a * 0.45))
		for i in 6:
			var fp := p + Vector2(-L * 0.35 + i * L * 0.14, sin(time * 9.0 + i * 1.7) * W * 0.12)
			c.draw_circle(fp, scale * (1.8 + 0.6 * sin(time * 8.0 + i)), Color(1.0, 0.55, 0.12, 0.95))
			c.draw_circle(fp, scale * 0.9, Color(1.0, 0.9, 0.4, 0.95))

func _draw_photo() -> void:
	var r := Rect2(Vector2.ZERO, PHOTO)
	photo.draw_texture_rect(sea, r, false)
	# petites îles (Midway : atoll)
	photo.draw_circle(Vector2(0.12, 0.85) * PHOTO, 9.0, Color(0.78, 0.76, 0.7))
	photo.draw_circle(Vector2(0.14, 0.87) * PHOTO, 5.0, Color(0.7, 0.68, 0.62))
	for s in SHIPS:
		_draw_ship(photo, s[0] * PHOTO, s[1], s[2], 0.5, false, false, 0.0)
	_draw_ship(photo, AKAGI * PHOTO, 24.0, 2, 0.5, false, false, 0.0)
	photo.draw_rect(r, Color(0.9, 0.85, 0.7), false, 4.0)
	# légende façon photo d'archive
	photo.draw_rect(Rect2(0, PHOTO.y - 26, PHOTO.x, 26), Color(0, 0, 0, 0.55))
	photo.draw_string(UIStyle.font_mono(), Vector2(10, PHOTO.y - 8), "U.S. NAVY — RECONNAISSANCE — 4 JUIN 1942 — 1/12000", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.9, 0.85))
	if has_loupe:
		var c := lens_center * PHOTO
		photo.draw_rect(Rect2(c - Vector2(LENS, LENS) * 0.5, Vector2(LENS, LENS)), Color(0.8, 0.65, 0.25), false, 6.0)
	else:
		photo.draw_string(UIStyle.font_title(), Vector2(30, 40), "Trop flou à l'œil nu…", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.85))

func _draw_lens() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var origin := lens_center * PHOTO
	# région de la photo vue à travers la loupe, agrandie
	var src := Rect2(origin - Vector2(LENS, LENS) / (2.0 * ZOOM), Vector2(LENS, LENS) / ZOOM)
	lens_view.draw_texture_rect_region(sea, Rect2(Vector2.ZERO, Vector2(LENS, LENS)), src)
	var to_lens := func(p: Vector2) -> Vector2: return (p - src.position) * ZOOM
	for s in SHIPS:
		_draw_ship(lens_view, to_lens.call(s[0] * PHOTO), s[1], s[2], ZOOM * 0.5, true, false, t)
	_draw_ship(lens_view, to_lens.call(AKAGI * PHOTO), 24.0, 2, ZOOM * 0.5, true, true, t)
	if solved:
		lens_view.draw_string(UIStyle.font_title(), to_lens.call(AKAGI * PHOTO) + Vector2(-40, 36), "AKAGI", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.9, 0.5))
	lens_view.draw_rect(Rect2(Vector2.ZERO, Vector2(LENS, LENS)), Color(0.1, 0.07, 0.03), false, 8.0)
	lens_view.draw_line(Vector2(LENS / 2 - 8, LENS / 2), Vector2(LENS / 2 + 8, LENS / 2), Color(1, 1, 1, 0.5), 1.0)
	lens_view.draw_line(Vector2(LENS / 2, LENS / 2 - 8), Vector2(LENS / 2, LENS / 2 + 8), Color(1, 1, 1, 0.5), 1.0)

func _process(_d: float) -> void:
	if is_open and has_loupe:
		lens_view.queue_redraw()

func _photo_input(event: InputEvent) -> void:
	if not has_loupe or solved:
		return
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.pressed):
		var pos: Vector2 = (event as InputEventMouse).position
		lens_center = (pos / PHOTO).clamp(Vector2(0.05, 0.05), Vector2(0.95, 0.95))
		lens.position = lens_center * PHOTO - Vector2(LENS, LENS) * 0.5
		photo.queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos2: Vector2 = event.position
		var f := pos2 / PHOTO
		if f.distance_to(AKAGI) <= AKAGI_R * 1.6 and lens_center.distance_to(AKAGI) < 0.12:
			_success()
		else:
			status.text = "Rien de remarquable à cet endroit. Cherche un navire qui brûle."
			Sfx.play("click", -8.0)

func _success() -> void:
	solved = true
	Sfx.play("stamp", -5.0)
	status.text = "Porte-avions japonais Akagi en flammes, frappé par les bombardiers américains. Identification confirmée."
	status.add_theme_color_override("font_color", UIStyle.GOLD)
	get_tree().create_timer(2.2).timeout.connect(func():
		if is_open:
			close_photo(false)
			get_tree().call_group("document_viewer", "open_document", DATE_ID)
			puzzle_completed.emit())

func open_photo() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	has_loupe = GameManager.has_item("loupe")
	solved = GameManager.is_date_unlocked(DATE_ID)
	lens.visible = has_loupe
	if has_loupe:
		lens.position = lens_center * PHOTO - Vector2(LENS, LENS) * 0.5
		status.text = "Déplace la loupe sur la photo (souris / doigt). Clique sur ce qui te semble être un navire touché."
	else:
		status.text = "Les navires ne sont que des points sur la photo. Il faudrait un instrument grossissant : cherche une loupe dans le bureau."
	status.add_theme_color_override("font_color", UIStyle.TEXT)
	photo.queue_redraw()
	Sfx.play("click", -6.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("player", "pause_control")
	create_tween().tween_property(root, "modulate:a", 1.0, 0.2)

func close_photo(resume: bool = true) -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	root.modulate.a = 0.0
	if resume:
		get_tree().call_group("player", "resume_control")

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
			close_photo()
			get_viewport().set_input_as_handled()
