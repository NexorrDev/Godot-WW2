extends CanvasLayer

## Date 5 : 22 juin 1941, opération Barbarossa.
## Cadenas à 4 chiffres du tiroir du classeur vert. Code : 1941.
## (l'empereur du XIIe siècle est Frédéric Barberousse ; 1941 = l'année qui suit l'armistice de 1940)

signal puzzle_completed

const DATE_ID := "barbarossa_1941"
const CODE := [1, 9, 4, 1]

var is_open := false
var solved := false
var root: Control
var digits := [0, 0, 0, 0]
var digit_labels: Array[Label] = []
var status: Label
var open_btn: Button
var panel_wheels: HBoxContainer

func _ready() -> void:
	add_to_group("enigma_cadenas")
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
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "CADENAS À 4 CHIFFRES"
	title.add_theme_font_override("font", UIStyle.font_title())
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	vb.add_child(title)

	var hint := Label.new()
	hint.text = "Tiroir du milieu du classeur vert. Molette de la souris ou flèches pour tourner les chiffres."
	hint.add_theme_font_override("font", UIStyle.font_mono())
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", UIStyle.TEXT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(560, 0)
	vb.add_child(hint)

	panel_wheels = HBoxContainer.new()
	panel_wheels.alignment = BoxContainer.ALIGNMENT_CENTER
	panel_wheels.add_theme_constant_override("separation", 18)
	vb.add_child(panel_wheels)
	for i in 4:
		panel_wheels.add_child(_make_wheel(i))

	status = Label.new()
	status.add_theme_font_override("font", UIStyle.font_mono())
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", UIStyle.SUBTITLE)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(560, 0)
	status.text = "Le cadenas est fermé."
	vb.add_child(status)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	open_btn = UIStyle.make_menu_button("Ouvrir le tiroir")
	open_btn.visible = false
	open_btn.pressed.connect(_on_open)
	row.add_child(open_btn)
	var close := UIStyle.make_menu_button("Fermer")
	close.pressed.connect(close_lock)
	row.add_child(close)

func _make_wheel(i: int) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var up := _arrow("▲", i, 1)
	col.add_child(up)
	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.86, 0.80, 0.62)
	sb.border_color = Color(0.35, 0.28, 0.15)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	box.add_theme_stylebox_override("panel", sb)
	box.custom_minimum_size = Vector2(84, 110)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			if e.button_index == MOUSE_BUTTON_WHEEL_UP:
				_turn(i, 1)
			elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_turn(i, -1))
	var lab := Label.new()
	lab.text = "0"
	lab.add_theme_font_override("font", UIStyle.font_title())
	lab.add_theme_font_size_override("font_size", 78)
	lab.add_theme_color_override("font_color", Color(0.10, 0.08, 0.06))
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(lab)
	digit_labels.append(lab)
	col.add_child(box)
	col.add_child(_arrow("▼", i, -1))
	return col

func _arrow(txt: String, i: int, dir: int) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(84, 34)
	b.pressed.connect(func(): _turn(i, dir))
	return b

func _turn(i: int, dir: int) -> void:
	if solved:
		return
	digits[i] = (digits[i] + dir + 10) % 10
	digit_labels[i].text = str(digits[i])
	Sfx.play("click", -7.0, 0.1)
	_check()

func _check() -> void:
	if digits == CODE:
		solved = true
		Sfx.play("stamp", -5.0)
		status.text = "Clic ! Le cadenas s'ouvre. Le tiroir contient le dossier de l'opération Barbarossa."
		status.add_theme_color_override("font_color", UIStyle.GOLD)
		open_btn.visible = true
	else:
		status.text = "Le cadenas est fermé."
		status.add_theme_color_override("font_color", UIStyle.SUBTITLE)

func open_lock() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	Sfx.play("click", -6.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("player", "pause_control")
	create_tween().tween_property(root, "modulate:a", 1.0, 0.2)

func close_lock(resume: bool = true) -> void:
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
			close_lock()
			get_viewport().set_input_as_handled()

func _on_open() -> void:
	close_lock(false)
	get_tree().call_group("document_viewer", "open_document", DATE_ID)
	puzzle_completed.emit()
