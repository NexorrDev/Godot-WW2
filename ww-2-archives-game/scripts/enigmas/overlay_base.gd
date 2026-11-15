extends CanvasLayer
class_name OverlayBase

## Base commune des énigmes en surimpression : fond sombre, panneau central, Échap pour fermer.
## Les classes filles remplissent `vb` dans _build_content() et réagissent à _on_open().

signal puzzle_completed

var group_name := ""
var is_open := false
var solved := false
var root: Control
var panel: PanelContainer
var vb: VBoxContainer
var status: Label
var _title_text := ""
var _min_width := 700.0

func _init(p_group: String = "", p_title: String = "") -> void:
	group_name = p_group
	_title_text = p_title

func _ready() -> void:
	if group_name != "":
		add_to_group(group_name)
	layer = 20
	visible = false
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
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.popup_stylebox())
	center.add_child(panel)
	vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var title := Label.new()
	title.text = _title_text
	title.add_theme_font_override("font", UIStyle.font_title())
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", UIStyle.GOLD)
	vb.add_child(title)
	_build_content()
	status = Label.new()
	status.add_theme_font_override("font", UIStyle.font_mono())
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", UIStyle.SUBTITLE)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(_min_width, 0)
	vb.add_child(status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	_build_buttons(row)
	var close := UIStyle.make_menu_button("Fermer")
	close.pressed.connect(close_overlay)
	row.add_child(close)

func _build_content() -> void:
	pass

func _build_buttons(_row: HBoxContainer) -> void:
	pass

func _on_open() -> void:
	pass

func say(text: String, good: bool = false) -> void:
	status.text = text
	status.add_theme_color_override("font_color", UIStyle.GOLD if good else UIStyle.SUBTITLE)

func hint(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UIStyle.font_mono())
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", UIStyle.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(_min_width, 0)
	return l

func open_overlay() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_on_open()
	Sfx.play("click", -6.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("player", "pause_control")
	create_tween().tween_property(root, "modulate:a", 1.0, 0.2)

func close_overlay(resume: bool = true) -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	root.modulate.a = 0.0
	if resume:
		get_tree().call_group("player", "resume_control")

## Ferme l'énigme et ouvre la fiche de la date (déblocage).
func finish(date_id: String) -> void:
	solved = true
	Sfx.play("stamp", -5.0)
	close_overlay(false)
	get_tree().call_group("document_viewer", "open_document", date_id)
	puzzle_completed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or (event.keycode == KEY_E and _e_closes()):
			close_overlay()
			get_viewport().set_input_as_handled()

func _e_closes() -> bool:
	return true
