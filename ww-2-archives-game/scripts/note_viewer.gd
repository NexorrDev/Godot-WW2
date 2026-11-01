extends CanvasLayer

## Affiche un petit papier (brouillon, note...) au centre de l'écran.
## Appel : get_tree().call_group("note_viewer", "show_note", "TITRE", "texte")

var is_open := false
var root: Control
var title_label: Label
var body_label: RichTextLabel

func _ready() -> void:
	add_to_group("note_viewer")
	layer = 19
	visible = false
	root = Control.new()
	UIStyle.fill_rect(root)
	root.modulate.a = 0.0
	add_child(root)

	var dim := ColorRect.new()
	UIStyle.fill_rect(dim)
	dim.color = Color(0.03, 0.03, 0.05, 0.75)
	root.add_child(dim)

	var center := CenterContainer.new()
	UIStyle.fill_rect(center)
	root.add_child(center)

	var sheet := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.88, 0.84, 0.72)
	sb.border_color = Color(0.62, 0.55, 0.42)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(34)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 18
	sheet.add_theme_stylebox_override("panel", sb)
	sheet.rotation_degrees = -1.2
	sheet.pivot_offset = Vector2(250, 200)
	center.add_child(sheet)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(500, 0)
	vb.add_theme_constant_override("separation", 14)
	sheet.add_child(vb)

	title_label = Label.new()
	title_label.add_theme_font_override("font", UIStyle.font_title())
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(0.50, 0.12, 0.10))
	vb.add_child(title_label)

	body_label = RichTextLabel.new()
	body_label.bbcode_enabled = true
	body_label.fit_content = true
	body_label.scroll_active = false
	body_label.add_theme_font_override("normal_font", UIStyle.font_mono())
	body_label.add_theme_font_size_override("normal_font_size", 17)
	body_label.add_theme_color_override("default_color", Color(0.14, 0.12, 0.10))
	vb.add_child(body_label)

	var close := Button.new()
	close.text = "Reposer le papier  [E]"
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(close_note)
	vb.add_child(close)

func show_note(title: String, body: String) -> void:
	if is_open:
		return
	is_open = true
	title_label.text = title
	body_label.text = body
	visible = true
	Sfx.play("paper_open")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("player", "pause_control")
	create_tween().tween_property(root, "modulate:a", 1.0, 0.2)

func close_note() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	root.modulate.a = 0.0
	Sfx.play("paper_close")
	get_tree().call_group("player", "resume_control")

func _unhandled_input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_ESCAPE or event.keycode == KEY_E):
		close_note()
		get_viewport().set_input_as_handled()
