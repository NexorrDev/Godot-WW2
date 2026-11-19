extends CanvasLayer
class_name HintBulb

## Icône d'ampoule en bas à gauche (touche H sur PC) : ouvre le panneau d'indices.
## Elle se met à pulser doucement si rien n'a été trouvé depuis un moment (joueur bloqué).

const IDLE_BEFORE_PULSE := 90.0

var btn: Button
var icon: Control
var idle := 0.0
var t := 0.0
var _alt_free := false
var key_label: Label

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn = Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.anchor_top = 1.0
	btn.anchor_bottom = 1.0
	btn.offset_left = 22
	btn.offset_right = 22 + 78
	btn.offset_top = -22 - 78
	btn.offset_bottom = -22
	btn.tooltip_text = "Indices (H)"
	btn.add_to_group("touch_block")
	btn.pressed.connect(_open)
	add_child(btn)
	icon = Control.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.draw.connect(_draw_icon)
	btn.add_child(icon)
	# pastille « H » : sur PC la souris est capturée, on rappelle donc le raccourci
	key_label = Label.new()
	key_label.text = "H"
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_label.add_theme_font_size_override("font_size", 16)
	key_label.add_theme_color_override("font_color", Color(0.1, 0.08, 0.05))
	key_label.add_theme_color_override("font_outline_color", Color(0.95, 0.88, 0.6))
	key_label.add_theme_constant_override("outline_size", 6)
	key_label.position = Vector2(58, 52)
	btn.add_child(key_label)
	btn.tooltip_text = "Indices (touche H — ou maintenir Alt pour utiliser la souris)"
	GameManager.date_unlocked.connect(func(_i, _d): idle = 0.0)
	visible = false

func _player() -> Node:
	var p := get_tree().get_nodes_in_group("player")
	return p[0] if p.size() > 0 else null

func _process(delta: float) -> void:
	var pl := _player()
	var show: bool = pl != null and pl.get("can_control") == true
	visible = show
	# PC : maintenir Alt libère la souris pour cliquer sur l'ampoule, relâcher la recapture
	if show and pl.get("touch") == null:
		var alt := Input.is_key_pressed(KEY_ALT)
		if alt and not _alt_free:
			_alt_free = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif not alt and _alt_free:
			_alt_free = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if show:
		idle += delta
	t += delta
	icon.queue_redraw()

func _open() -> void:
	idle = 0.0
	get_tree().call_group("hint_panel", "open_hints")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H and visible:
		_open()
		get_viewport().set_input_as_handled()

func _draw_icon() -> void:
	var c := Vector2(39, 36)
	var pulse := 0.0
	if idle > IDLE_BEFORE_PULSE:
		pulse = 0.5 + 0.5 * sin(t * 3.0)
	# halo + fond
	icon.draw_circle(c, 38.0, Color(0.08, 0.07, 0.05, 0.62))
	if pulse > 0.0:
		icon.draw_circle(c, 38.0 + pulse * 6.0, Color(1.0, 0.85, 0.35, 0.18 + 0.25 * pulse))
	icon.draw_arc(c, 37.0, 0, TAU, 40, Color(0.88, 0.78, 0.5, 0.85), 3.0)
	var glass := Color(1.0, 0.90, 0.42) if pulse > 0.0 else Color(0.96, 0.88, 0.62)
	if pulse > 0.0:
		glass = glass.lerp(Color(1.0, 1.0, 0.75), pulse)
	# ampoule
	icon.draw_circle(c + Vector2(0, -6), 14.0, glass)
	icon.draw_colored_polygon(PackedVector2Array([c + Vector2(-8, 4), c + Vector2(8, 4), c + Vector2(5, 14), c + Vector2(-5, 14)]), glass)
	icon.draw_line(c + Vector2(-6, 18), c + Vector2(6, 18), Color(0.7, 0.68, 0.62), 3.0)
	icon.draw_line(c + Vector2(-4, 23), c + Vector2(4, 23), Color(0.7, 0.68, 0.62), 3.0)
	# filament
	icon.draw_polyline(PackedVector2Array([c + Vector2(-4, 12), c + Vector2(-3, -2), c + Vector2(0, 2), c + Vector2(3, -2), c + Vector2(4, 12)]), Color(0.6, 0.4, 0.1), 1.6)
