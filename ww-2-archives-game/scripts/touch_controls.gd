extends CanvasLayer
class_name TouchControls

## Commandes tactiles (téléphone) : joystick à gauche, regard en glissant à droite,
## bouton d'action, bouton pause / retour. Créé par le joueur uniquement sur mobile.

const LOOK_SENS := 0.0045
const STICK_RADIUS := 110.0

var player: Node = null
var move_vector := Vector2.ZERO
var look_delta := Vector2.ZERO

var _stick_id := -1
var _stick_origin := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _look_id := -1
var _look_moved := 0.0
var _look_start := Vector2.ZERO

var _pad: Control
var _knob: Control
var _btn_act: Button
var _btn_menu: Button
var _btn_back: Button

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_parent()
	_pad = Control.new()
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pad.draw.connect(_draw_pad)
	add_child(_pad)

	_btn_act = _make_button("AGIR", Vector2(1, 1), Vector2(-230, -250), Vector2(170, 170), 30)
	_btn_act.button_down.connect(_on_act)
	_btn_menu = _make_button("II", Vector2(1, 0), Vector2(-120, 24), Vector2(96, 96), 36)
	_btn_menu.button_down.connect(func(): _send_escape())
	_btn_back = _make_button("✕  Retour", Vector2(1, 0), Vector2(-300, 24), Vector2(280, 96), 32)
	_btn_back.button_down.connect(func(): _send_escape())

func _make_button(text: String, anchor: Vector2, offset: Vector2, size: Vector2, fs: int) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", fs)
	b.anchor_left = anchor.x
	b.anchor_right = anchor.x
	b.anchor_top = anchor.y
	b.anchor_bottom = anchor.y
	b.offset_left = offset.x
	b.offset_top = offset.y
	b.offset_right = offset.x + size.x
	b.offset_bottom = offset.y + size.y
	b.modulate = Color(1, 1, 1, 0.78)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.09, 0.07, 0.6)
	sb.border_color = Color(0.88, 0.8, 0.6, 0.9)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(int(min(size.x, size.y) / 2.0))
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	add_child(b)
	return b

func _send_escape() -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = KEY_ESCAPE
		ev.physical_keycode = KEY_ESCAPE
		ev.pressed = pressed
		Input.parse_input_event(ev)

func _on_act() -> void:
	if player and player.can_control and player.current_interactable:
		player.current_interactable.interact()

func _process(_delta: float) -> void:
	var controlling: bool = player != null and player.can_control
	var menu := get_tree().current_scene.get_node_or_null("MainMenu") if get_tree().current_scene else null
	var in_main_menu: bool = menu != null and menu.visible
	var pause_open := false
	for p in get_tree().get_nodes_in_group("pause_menu"):
		if p.get("is_open"):
			pause_open = true
	_btn_act.visible = controlling
	_btn_menu.visible = controlling
	_btn_back.visible = not controlling and not in_main_menu and not pause_open
	if not controlling:
		_stick_id = -1
		_look_id = -1
		move_vector = Vector2.ZERO
	_pad.queue_redraw()

func _over_button(pos: Vector2) -> bool:
	for b in [_btn_act, _btn_menu, _btn_back]:
		if b.visible and b.get_global_rect().has_point(pos):
			return true
	for n in get_tree().get_nodes_in_group("touch_block"):
		if n is Control and n.is_visible_in_tree() and n.get_global_rect().has_point(pos):
			return true
	return false

func _input(event: InputEvent) -> void:
	if player == null or not player.can_control:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _over_button(t.position):
				return
			var half := get_viewport().get_visible_rect().size.x * 0.42
			if t.position.x < half and _stick_id < 0:
				_stick_id = t.index
				_stick_origin = t.position
				_stick_pos = t.position
			elif t.position.x >= half and _look_id < 0:
				_look_id = t.index
				_look_moved = 0.0
				_look_start = t.position
		else:
			if t.index == _stick_id:
				_stick_id = -1
				move_vector = Vector2.ZERO
			elif t.index == _look_id:
				# Un simple tap (sans glisser) vise et interagit
				if _look_moved < 18.0:
					_on_act()
				_look_id = -1
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _stick_id:
			_stick_pos = d.position
			var v := (_stick_pos - _stick_origin)
			if v.length() > STICK_RADIUS:
				_stick_origin = _stick_pos - v.normalized() * STICK_RADIUS
				v = v.normalized() * STICK_RADIUS
			move_vector = v / STICK_RADIUS
		elif d.index == _look_id:
			_look_moved += d.relative.length()
			look_delta += d.relative

func consume_look() -> Vector2:
	var l := look_delta
	look_delta = Vector2.ZERO
	return l * LOOK_SENS

func _draw_pad() -> void:
	if _stick_id < 0:
		return
	_pad.draw_circle(_stick_origin, STICK_RADIUS, Color(1, 1, 1, 0.10))
	_pad.draw_arc(_stick_origin, STICK_RADIUS, 0, TAU, 48, Color(0.9, 0.82, 0.62, 0.55), 3.0)
	_pad.draw_circle(_stick_pos, 44.0, Color(0.95, 0.88, 0.68, 0.55))
