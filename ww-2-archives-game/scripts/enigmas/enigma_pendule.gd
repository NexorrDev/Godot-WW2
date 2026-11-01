extends CanvasLayer

## Date 4 : 22 juin 1940, armistice de Rethondes.
## La pendule des archives est déréglée : il faut placer les aiguilles sur 18h36
## (l'heure du brouillon trouvé dans la corbeille) pour ouvrir le compartiment du socle.
## Les deux aiguilles se déplacent à la souris (clic maintenu sur une aiguille).

signal puzzle_completed

const DATE_ID := "armistice_1940"
const R := 190.0
const HOUR_LEN := 105.0
const MIN_LEN := 160.0
const TARGET_MIN_DEG := 216.0     # 36 minutes
const TARGET_HOUR_DEG := 186.0    # 6h36 sur un cadran de 12 h
const TOL_MIN := 12.0
const TOL_HOUR := 15.0

var is_open := false
var solved := false
var root: Control
var face: Control
var status: Label
var confirm_btn: Button
var take_btn: Button

var hour_deg := 305.0   # 10h10 au départ
var min_deg := 60.0
var dragging := ""      # "hour" / "min"

func _ready() -> void:
	add_to_group("enigma_pendule")
	layer = 20
	visible = false
	_build_ui()

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
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "PENDULE DES ARCHIVES"
	title.add_theme_font_override("font", UIStyle.font_title())
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	vb.add_child(title)

	var hint := Label.new()
	hint.text = "La pendule est déréglée. Attrapez une aiguille et faites-la tourner."
	hint.add_theme_font_override("font", UIStyle.font_mono())
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", UIStyle.TEXT)
	vb.add_child(hint)

	face = Control.new()
	face.custom_minimum_size = Vector2(R * 2 + 40, R * 2 + 40)
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	face.draw.connect(_draw_face)
	face.gui_input.connect(_on_face_input)
	vb.add_child(face)

	status = Label.new()
	status.add_theme_font_override("font", UIStyle.font_mono())
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", UIStyle.SUBTITLE)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(R * 2 + 40, 0)
	status.text = "Heure affichée : 10h10"
	vb.add_child(status)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	confirm_btn = UIStyle.make_menu_button("Valider l'heure")
	confirm_btn.pressed.connect(_on_confirm)
	row.add_child(confirm_btn)
	take_btn = UIStyle.make_menu_button("Prendre l'acte")
	take_btn.visible = false
	take_btn.pressed.connect(_on_take)
	row.add_child(take_btn)
	var close := UIStyle.make_menu_button("Fermer")
	close.pressed.connect(close_clock)
	row.add_child(close)

func open_clock() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	Sfx.play("click", -6.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("player", "pause_control")
	create_tween().tween_property(root, "modulate:a", 1.0, 0.2)
	face.queue_redraw()

func close_clock(resume: bool = true) -> void:
	if not is_open:
		return
	is_open = false
	dragging = ""
	visible = false
	root.modulate.a = 0.0
	if resume:
		get_tree().call_group("player", "resume_control")

func _unhandled_input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_ESCAPE or event.keycode == KEY_E):
		close_clock()
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------------------

func _center() -> Vector2:
	return face.size / 2.0

func _tip(deg: float, length: float) -> Vector2:
	var a := deg_to_rad(deg)
	return _center() + Vector2(sin(a), -cos(a)) * length

func _angle_of(p: Vector2) -> float:
	var d := p - _center()
	return fposmod(rad_to_deg(atan2(d.x, -d.y)), 360.0)

func _on_face_input(event: InputEvent) -> void:
	if solved:
		return
	var pos: Vector2 = (event as InputEventMouse).position if event is InputEventMouse else Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var dh: float = pos.distance_to(_tip(hour_deg, HOUR_LEN * 0.8))
			var dm: float = pos.distance_to(_tip(min_deg, MIN_LEN * 0.7))
			var dh_tip: float = pos.distance_to(_tip(hour_deg, HOUR_LEN))
			var dm_tip: float = pos.distance_to(_tip(min_deg, MIN_LEN))
			var best: float = minf(minf(dh, dh_tip), minf(dm, dm_tip))
			if best < 45.0:
				dragging = "hour" if minf(dh, dh_tip) <= minf(dm, dm_tip) else "min"
				Sfx.play("click", -9.0)
		else:
			dragging = ""
	elif event is InputEventMouseMotion and dragging != "":
		var a := _angle_of(pos)
		if dragging == "hour":
			hour_deg = a
		else:
			min_deg = a
		_update_text()
		face.queue_redraw()

func _time_text() -> String:
	var minutes := int(round(min_deg / 6.0)) % 60
	var hours := int(floor(hour_deg / 30.0)) % 12
	if hours == 0:
		hours = 12
	return "%dh%02d" % [hours, minutes]

func _update_text() -> void:
	status.text = "Heure affichée : " + _time_text()
	status.add_theme_color_override("font_color", UIStyle.SUBTITLE)

func _ang_diff(a: float, b: float) -> float:
	return absf(fposmod(a - b + 180.0, 360.0) - 180.0)

func _on_confirm() -> void:
	if solved:
		return
	if _ang_diff(min_deg, TARGET_MIN_DEG) <= TOL_MIN and _ang_diff(hour_deg, TARGET_HOUR_DEG) <= TOL_HOUR:
		solved = true
		Sfx.play("stamp", -5.0)
		status.text = "Clac ! Un compartiment s'ouvre dans le socle de la pendule : l'acte d'armistice y était caché."
		status.add_theme_color_override("font_color", UIStyle.GOLD)
		confirm_btn.visible = false
		take_btn.visible = true
	else:
		Sfx.play("click", -3.0)
		status.text = "%s : rien ne se passe. Vérifiez l'heure notée sur le brouillon (corbeille)." % _time_text()
		status.add_theme_color_override("font_color", Color(0.9, 0.45, 0.35))

func _on_take() -> void:
	close_clock(false)
	get_tree().call_group("document_viewer", "open_document", DATE_ID)
	puzzle_completed.emit()

# ---------------------------------------------------------------------------

func _draw_face() -> void:
	var c := _center()
	var font := UIStyle.font_mono()
	face.draw_circle(c + Vector2(4, 6), R + 12, Color(0, 0, 0, 0.4))
	face.draw_circle(c, R + 12, Color(0.22, 0.14, 0.09))
	face.draw_circle(c, R, Color(0.92, 0.89, 0.78))
	face.draw_arc(c, R - 6, 0, TAU, 96, Color(0.3, 0.22, 0.15), 2.0)
	for i in 60:
		var a := deg_to_rad(i * 6.0)
		var dir := Vector2(sin(a), -cos(a))
		var major := i % 5 == 0
		face.draw_line(c + dir * (R - (28 if major else 16)), c + dir * (R - 8), Color(0.12, 0.10, 0.09), 3.0 if major else 1.2)
	var romans := ["XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
	for i in 12:
		var a := deg_to_rad(i * 30.0)
		var pos := c + Vector2(sin(a), -cos(a)) * (R - 52)
		var w := font.get_string_size(romans[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		face.draw_string(font, pos + Vector2(-w / 2.0, 7), romans[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.12, 0.10, 0.09))
	# aiguilles (ombre puis aiguille)
	var hand_col := Color(0.08, 0.07, 0.07)
	var hl := 5.0 if dragging != "hour" else 7.0
	var ml := 3.0 if dragging != "min" else 5.0
	face.draw_line(c + Vector2(3, 4), _tip(hour_deg, HOUR_LEN) + Vector2(3, 4), Color(0, 0, 0, 0.25), hl)
	face.draw_line(c + Vector2(3, 4), _tip(min_deg, MIN_LEN) + Vector2(3, 4), Color(0, 0, 0, 0.25), ml)
	face.draw_line(c, _tip(hour_deg, HOUR_LEN), hand_col, hl)
	face.draw_line(c, _tip(min_deg, MIN_LEN), hand_col, ml)
	face.draw_circle(c, 9, hand_col)
	face.draw_circle(c, 3, Color(0.8, 0.7, 0.4))
