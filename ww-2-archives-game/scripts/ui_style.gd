extends RefCounted
class_name UIStyle

## Style partagé du menu principal et du menu pause.
## Bandeau de titre "papier", police machine à écrire, boutons à sélection beige,
## ombrage latéral et vignette : tout est centralisé ici pour que les deux menus se ressemblent.

const PAPER := Color(0.85, 0.81, 0.74, 0.97)
const PAPER_EDGE := Color(0.62, 0.56, 0.46, 1.0)
const INK := Color(0.12, 0.12, 0.12, 1.0)
const TEXT := Color(0.86, 0.84, 0.80, 1.0)
const TEXT_HOVER := Color(0.95, 0.93, 0.88, 1.0)
const TEXT_DIM := Color(0.50, 0.48, 0.44, 1.0)
const SUBTITLE := Color(0.72, 0.69, 0.64, 1.0)
const FOOTER := Color(0.55, 0.52, 0.47, 1.0)
const GOLD := Color(0.95, 0.82, 0.48, 1.0)

## Couleur propre à chaque période (bleu / orange / or), utilisée par le HUD
static func period_color(period: int) -> Color:
	match period:
		1:
			return Color(0.50, 0.68, 0.92)
		2:
			return Color(0.95, 0.66, 0.34)
		_:
			return Color(0.93, 0.83, 0.45)

static var _font_title: SystemFont = null
static var _font_mono: SystemFont = null

# ---------------------------------------------------------------------------
# Polices
# ---------------------------------------------------------------------------

static func font_title() -> SystemFont:
	if _font_title == null:
		_font_title = SystemFont.new()
		_font_title.font_names = PackedStringArray(["Bebas Neue", "Oswald", "Impact", "Haettenschweiler", "Arial Narrow", "sans-serif"])
		_font_title.font_weight = 700
	return _font_title

static func font_mono() -> SystemFont:
	if _font_mono == null:
		_font_mono = SystemFont.new()
		_font_mono.font_names = PackedStringArray(["JetBrains Mono", "Consolas", "Courier New", "Courier", "monospace"])
		_font_mono.font_weight = 400
	return _font_mono

# ---------------------------------------------------------------------------
# Utilitaires de mise en page
# ---------------------------------------------------------------------------

static func fill_rect(c: Control) -> void:
	c.anchor_left = 0.0
	c.anchor_top = 0.0
	c.anchor_right = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0

# ---------------------------------------------------------------------------
# Titre en bandeau papier
# ---------------------------------------------------------------------------

static func style_title(panel: PanelContainer, label: Label, font_size: int = 46) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 22.0
	sb.content_margin_right = 22.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 2.0
	sb.border_width_bottom = 3
	sb.border_color = PAPER_EDGE
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(3, 5)
	panel.add_theme_stylebox_override("panel", sb)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	label.add_theme_font_override("font", font_title())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

static func make_title_strip(text: String, font_size: int = 46) -> HBoxContainer:
	var box := HBoxContainer.new()
	var panel := PanelContainer.new()
	box.add_child(panel)
	var label := Label.new()
	label.text = text.to_upper()
	panel.add_child(label)
	style_title(panel, label, font_size)
	return box

static func style_subtitle(label: Label) -> void:
	label.add_theme_font_override("font", font_mono())
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", SUBTITLE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

static func make_subtitle(text: String) -> Label:
	var label := Label.new()
	label.text = text
	style_subtitle(label)
	return label

# ---------------------------------------------------------------------------
# Boutons de menu (sélection = bande beige + triangle à gauche)
# ---------------------------------------------------------------------------

static func style_menu_button(btn: Button, selected: bool, dimmed: bool = false) -> void:
	var original: String = btn.get_meta("original_text", "")
	if original == "":
		original = btn.text.replace("▶", "").strip_edges()
		btn.set_meta("original_text", original)
	btn.text = original

	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(maxf(btn.custom_minimum_size.x, 300.0), 42.0)
	btn.add_theme_font_override("font", font_mono())
	btn.add_theme_font_size_override("font_size", 20)

	var box: StyleBox
	if selected:
		var sb := StyleBoxFlat.new()
		sb.bg_color = PAPER
		sb.set_corner_radius_all(2)
		sb.border_width_bottom = 2
		sb.border_color = PAPER_EDGE
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 5
		sb.shadow_offset = Vector2(2, 3)
		box = sb
	else:
		box = StyleBoxEmpty.new()
	box.content_margin_left = 18.0
	box.content_margin_right = 16.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state, box)

	var color: Color = TEXT
	if selected:
		color = INK
	elif dimmed:
		color = TEXT_DIM
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_focus_color", color)
	btn.add_theme_color_override("font_pressed_color", color)
	btn.add_theme_color_override("font_hover_color", INK if selected else TEXT_HOVER)
	btn.add_theme_color_override("font_hover_pressed_color", INK if selected else TEXT_HOVER)

	var marker: Label = btn.get_node_or_null("Marker")
	if marker == null:
		marker = Label.new()
		marker.name = "Marker"
		marker.text = "▶"
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		marker.add_theme_font_size_override("font_size", 16)
		marker.add_theme_color_override("font_color", TEXT_HOVER)
		btn.add_child(marker)
		marker.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		marker.offset_left = -32.0
		marker.offset_right = -8.0
		marker.offset_top = 0.0
		marker.offset_bottom = 0.0
	marker.visible = selected

static func make_menu_button(text: String, dimmed: bool = false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	style_menu_button(btn, false, dimmed)
	return btn

# ---------------------------------------------------------------------------
# Décor : ombrage gauche, vignette, pied de page
# ---------------------------------------------------------------------------

static func make_left_shade(width: float = 720.0) -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(0.03, 0.03, 0.04, 0.85), Color(0.03, 0.03, 0.04, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0)
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.anchor_left = 0.0
	r.anchor_top = 0.0
	r.anchor_right = 0.0
	r.anchor_bottom = 1.0
	r.offset_left = 0.0
	r.offset_top = 0.0
	r.offset_right = width
	r.offset_bottom = 0.0
	return r

static func make_vignette() -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.45, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.6)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill_rect(r)
	return r

static func add_footer(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", font_mono())
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", FOOTER)
	parent.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	l.offset_left = 80.0
	l.offset_top = -56.0
	l.offset_right = 760.0
	l.offset_bottom = -28.0
	return l

# ---------------------------------------------------------------------------
# Curseur (cadran de la radio) : piste visible + gros bouton rond doré
# ---------------------------------------------------------------------------

static func make_knob(diameter: int, fill: Color, border: Color) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var c: float = (diameter - 1) / 2.0
	var r: float = diameter / 2.0
	for y in diameter:
		for x in diameter:
			var d: float = Vector2(x - c, y - c).length()
			var col := Color(0, 0, 0, 0)
			if d <= r - 3.0:
				col = fill
			elif d <= r - 0.5:
				col = border
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func style_slider(s: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.05, 0.04, 0.03, 1)
	track.set_corner_radius_all(4)
	track.set_border_width_all(1)
	track.border_color = Color(0.45, 0.36, 0.22, 1)
	track.content_margin_top = 5.0
	track.content_margin_bottom = 5.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.68, 0.50, 0.24, 1)
	fill.set_corner_radius_all(4)
	fill.content_margin_top = 5.0
	fill.content_margin_bottom = 5.0
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var knob := make_knob(28, GOLD, Color(0.35, 0.25, 0.10, 1))
	s.add_theme_icon_override("grabber", knob)
	s.add_theme_icon_override("grabber_highlight", knob)
	s.add_theme_icon_override("grabber_disabled", knob)

# ---------------------------------------------------------------------------
# Fenêtres contextuelles (identiques à celles du menu principal)
# ---------------------------------------------------------------------------

static func popup_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.11, 0.11, 0.97)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.8, 0.74, 0.62, 1.0)
	sb.set_corner_radius_all(6)
	sb.set_expand_margin_all(20.0)
	sb.shadow_color = Color(0, 0, 0, 0.8)
	sb.shadow_size = 25
	return sb
