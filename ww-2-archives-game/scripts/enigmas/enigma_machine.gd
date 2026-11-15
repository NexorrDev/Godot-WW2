extends CanvasLayer

## Date 6 : 7 décembre 1941, Pearl Harbor.
## La machine à écrire attend un mot de code de 4 lettres : TORA (« tigre » en japonais,
## « Tora ! Tora ! Tora ! » = signal de l'attaque). Clavier physique ou clavier à l'écran (tactile).

signal puzzle_completed

const DATE_ID := "pearl_harbor_1941"
const CODE := "TORA"
const MAX_LEN := 10
const MESSAGE := "TORA ! TORA ! TORA !\n\nA TOUS LES COMMANDEMENTS -\nATTAQUE AERIENNE JAPONAISE\nSUR PEARL HARBOR, HAWAI.\nCECI N'EST PAS UN EXERCICE.\n\n-- 7 DECEMBRE 1941 --"

var is_open := false
var solved := false
var typed := ""
var root: Control
var paper_label: Label
var status: Label
var keyboard: VBoxContainer
var read_btn: Button
var _typing_tween: Tween

func _ready() -> void:
	add_to_group("enigma_machine")
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
	dim.color = Color(0.03, 0.03, 0.05, 0.88)
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
	title.text = "MACHINE À ÉCRIRE"
	title.add_theme_font_override("font", UIStyle.font_title())
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	vb.add_child(title)

	var hint := Label.new()
	hint.text = "Tape le mot de code (4 lettres) sur le clavier, puis appuie sur Entrée."
	hint.add_theme_font_override("font", UIStyle.font_mono())
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", UIStyle.TEXT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(620, 0)
	vb.add_child(hint)

	var paper := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.89, 0.76)
	sb.border_color = Color(0.55, 0.47, 0.30)
	sb.set_border_width_all(2)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	paper.add_theme_stylebox_override("panel", sb)
	paper.custom_minimum_size = Vector2(620, 215)
	vb.add_child(paper)
	paper_label = Label.new()
	paper_label.add_theme_font_override("font", UIStyle.font_mono())
	paper_label.add_theme_font_size_override("font_size", 19)
	paper_label.add_theme_color_override("font_color", Color(0.08, 0.07, 0.06))
	paper_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paper.add_child(paper_label)

	status = Label.new()
	status.add_theme_font_override("font", UIStyle.font_mono())
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", UIStyle.SUBTITLE)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(620, 0)
	vb.add_child(status)

	keyboard = VBoxContainer.new()
	keyboard.add_theme_constant_override("separation", 5)
	keyboard.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(keyboard)
	for row_letters in ["AZERTYUIOP", "QSDFGHJKLM", "WXCVBN"]:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 5)
		keyboard.add_child(row)
		for ch in row_letters:
			row.add_child(_key(ch, ch))
		if row_letters == "WXCVBN":
			var back := _key("⌫", "", Vector2(70, 46))
			back.pressed.connect(_backspace)
			row.add_child(back)
			var ent := _key("Entrée ↵", "", Vector2(130, 46))
			ent.pressed.connect(_enter)
			row.add_child(ent)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	vb.add_child(row2)
	read_btn = UIStyle.make_menu_button("Lire le télégramme")
	read_btn.visible = false
	read_btn.pressed.connect(_on_read)
	row2.add_child(read_btn)
	var close := UIStyle.make_menu_button("Fermer")
	close.pressed.connect(close_machine)
	row2.add_child(close)

func _key(label: String, letter: String, size: Vector2 = Vector2(50, 46)) -> Button:
	var b := Button.new()
	b.text = label
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = size
	b.add_theme_font_override("font", UIStyle.font_mono())
	b.add_theme_font_size_override("font_size", 20)
	if letter != "":
		b.pressed.connect(func(): _type(letter))
	return b

func _refresh_paper() -> void:
	if solved:
		return
	paper_label.text = typed + "▌"

func _type(letter: String) -> void:
	if solved or typed.length() >= MAX_LEN:
		return
	typed += letter
	Sfx.play("click", -4.0, 0.15)
	_refresh_paper()
	status.text = ""
	if typed == CODE:
		_success()

func _backspace() -> void:
	if solved or typed.is_empty():
		return
	typed = typed.substr(0, typed.length() - 1)
	Sfx.play("click", -9.0, 0.1)
	_refresh_paper()

func _enter() -> void:
	if solved:
		return
	if typed == CODE:
		_success()
	elif typed.is_empty():
		return
	else:
		Sfx.play("click", -3.0, 0.3)
		status.text = "Les barres s'emmêlent… ce n'est pas le bon mot de code. Cherche l'indice autour de la machine."
		typed = ""
		_refresh_paper()

func _success() -> void:
	solved = true
	Sfx.play("stamp", -5.0)
	status.text = "La machine s'emballe et tape toute seule…"
	status.add_theme_color_override("font_color", UIStyle.GOLD)
	keyboard.modulate = Color(1, 1, 1, 0.35)
	paper_label.text = ""
	if _typing_tween:
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_method(_show_chars, 0, MESSAGE.length(), MESSAGE.length() * 0.045)
	_typing_tween.tween_callback(func():
		status.text = "Un télégramme de l'attaque de Pearl Harbor est sorti de la machine."
		read_btn.visible = true)

var _last_n := 0
func _show_chars(n: int) -> void:
	paper_label.text = MESSAGE.substr(0, n)
	if n != _last_n and n % 2 == 0:
		Sfx.play("click", -12.0, 0.25)
	_last_n = n

func open_machine() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	typed = ""
	solved = GameManager.is_date_unlocked(DATE_ID)
	keyboard.modulate = Color(1, 1, 1, 0.35 if solved else 1.0)
	read_btn.visible = solved
	if solved:
		paper_label.text = MESSAGE
		status.text = "Le télégramme est déjà tapé."
	else:
		status.text = ""
		status.add_theme_color_override("font_color", UIStyle.SUBTITLE)
		_refresh_paper()
	Sfx.play("click", -6.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("player", "pause_control")
	create_tween().tween_property(root, "modulate:a", 1.0, 0.2)

func close_machine(resume: bool = true) -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	root.modulate.a = 0.0
	if _typing_tween:
		_typing_tween.kill()
	if resume:
		get_tree().call_group("player", "resume_control")

func _unhandled_input(event: InputEvent) -> void:
	if not is_open or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := event as InputEventKey
	if k.keycode == KEY_ESCAPE:
		close_machine()
	elif k.keycode == KEY_BACKSPACE:
		_backspace()
	elif k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
		_enter()
	elif k.unicode > 0:
		var ch := char(k.unicode).to_upper()
		if ch.length() == 1 and ch >= "A" and ch <= "Z":
			_type(ch)
	get_viewport().set_input_as_handled()

func _on_read() -> void:
	close_machine(false)
	get_tree().call_group("document_viewer", "open_document", DATE_ID)
	puzzle_completed.emit()
