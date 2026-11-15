extends OverlayBase

## Date 8 : El-Alamein (oct.-nov. 1942). L'ordre de mission dit « Cap au Sud-Est vers le canal de Suez ».
## On règle la boussole (glisser l'aiguille) et on la compare à la carte d'Afrique du Nord.

const DATE_ID := "el_alamein_1942"
const TARGET := 135.0   # Sud-Est
const TOL := 18.0

var dial: Control
var heading := 20.0
var dragging := false
var map: Control

func _init() -> void:
	super("enigma_boussole", "BOUSSOLE MILITAIRE")

func _build_content() -> void:
	vb.add_child(hint("Ordre de mission : « Cap au SUD-EST vers le canal de Suez. » Fais tourner l'aiguille (clic maintenu) pour viser ce cap, puis valide. La carte à gauche montre El-Alamein et le canal de Suez."))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	vb.add_child(row)
	map = Control.new()
	map.custom_minimum_size = Vector2(300, 300)
	map.draw.connect(_draw_map)
	row.add_child(map)
	dial = Control.new()
	dial.custom_minimum_size = Vector2(330, 330)
	dial.mouse_filter = Control.MOUSE_FILTER_STOP
	dial.draw.connect(_draw_dial)
	dial.gui_input.connect(_dial_input)
	row.add_child(dial)

func _build_buttons(row: HBoxContainer) -> void:
	var ok := UIStyle.make_menu_button("Valider le cap")
	ok.pressed.connect(_validate)
	row.add_child(ok)

func _on_open() -> void:
	solved = GameManager.is_date_unlocked(DATE_ID)
	say("Cap actuel : %d°" % int(heading))
	map.queue_redraw()
	dial.queue_redraw()

func _draw_map() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(300, 300))
	map.draw_rect(r, Color(0.85, 0.78, 0.58))
	# Méditerranée (haut) et mer Rouge (bas droite), delta du Nil
	map.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(300, 0), Vector2(300, 60), Vector2(215, 70), Vector2(150, 55), Vector2(70, 75), Vector2(0, 62)]), Color(0.45, 0.62, 0.72))
	map.draw_colored_polygon(PackedVector2Array([Vector2(250, 300), Vector2(300, 200), Vector2(300, 300)]), Color(0.45, 0.62, 0.72))
	map.draw_line(Vector2(175, 66), Vector2(195, 300), Color(0.35, 0.55, 0.75), 4.0)  # Nil
	var al := Vector2(70, 80)    # El-Alamein
	var su := Vector2(235, 190)  # canal de Suez
	map.draw_line(Vector2(228, 130), Vector2(246, 245), Color(0.4, 0.6, 0.78), 5.0)  # canal
	map.draw_circle(al, 6, Color(0.5, 0.1, 0.1))
	map.draw_circle(su, 6, Color(0.1, 0.1, 0.5))
	map.draw_string(UIStyle.font_mono(), al + Vector2(-8, 22), "EL-ALAMEIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.3, 0.05, 0.05))
	map.draw_string(UIStyle.font_mono(), su + Vector2(-60, 24), "CANAL DE SUEZ", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.05, 0.05, 0.35))
	map.draw_string(UIStyle.font_mono(), Vector2(70, 20), "MÉDITERRANÉE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.1, 0.2, 0.35))
	map.draw_string(UIStyle.font_mono(), Vector2(30, 160), "LIBYE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.3, 0.15))
	map.draw_string(UIStyle.font_mono(), Vector2(150, 260), "ÉGYPTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.3, 0.15))
	# flèche du cap choisi depuis El-Alamein
	var a := deg_to_rad(heading)
	var d := Vector2(sin(a), -cos(a))
	map.draw_line(al, al + d * 170.0, Color(0.8, 0.1, 0.1, 0.85), 3.0)
	map.draw_rect(r, Color(0.3, 0.22, 0.1), false, 3.0)
	map.draw_string(UIStyle.font_mono(), Vector2(270, 295), "N↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.2, 0.15, 0.1))

func _draw_dial() -> void:
	var c := Vector2(165, 165)
	dial.draw_circle(c, 150, Color(0.18, 0.2, 0.14))
	dial.draw_circle(c, 140, Color(0.88, 0.85, 0.72))
	for i in 72:
		var a := deg_to_rad(i * 5.0)
		var d := Vector2(sin(a), -cos(a))
		var len_ := 14.0 if i % 9 == 0 else (9.0 if i % 3 == 0 else 5.0)
		dial.draw_line(c + d * 140, c + d * (140 - len_), Color(0.1, 0.1, 0.1), 2.0)
	var names := {"N": 0.0, "NE": 45.0, "E": 90.0, "SE": 135.0, "S": 180.0, "SO": 225.0, "O": 270.0, "NO": 315.0}
	for k in names:
		var a2 := deg_to_rad(names[k])
		var p: Vector2 = c + Vector2(sin(a2), -cos(a2)) * 108 - Vector2(10 if k.length() == 1 else 14, -6)
		dial.draw_string(UIStyle.font_title(), p, k, HORIZONTAL_ALIGNMENT_LEFT, -1, 20 if k.length() == 1 else 15, Color(0.45, 0.08, 0.08) if k == "N" else Color(0.15, 0.12, 0.1))
	var ar := deg_to_rad(heading)
	var dir := Vector2(sin(ar), -cos(ar))
	var perp := Vector2(-dir.y, dir.x)
	dial.draw_colored_polygon(PackedVector2Array([c + dir * 96, c + perp * 10, c - dir * 20, c - perp * 10]), Color(0.75, 0.12, 0.1))
	dial.draw_colored_polygon(PackedVector2Array([c - dir * 96, c + perp * 10, c + dir * 20, c - perp * 10]), Color(0.2, 0.2, 0.25))
	dial.draw_circle(c, 8, Color(0.7, 0.6, 0.3))

func _dial_input(event: InputEvent) -> void:
	if solved:
		return
	var c := Vector2(165, 165)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if dragging:
			_aim(event.position - c)
	elif event is InputEventMouseMotion and dragging:
		_aim(event.position - c)

func _aim(v: Vector2) -> void:
	if v.length() < 8.0:
		return
	heading = fposmod(rad_to_deg(atan2(v.x, -v.y)), 360.0)
	say("Cap actuel : %d°" % int(heading))
	dial.queue_redraw()
	map.queue_redraw()

func _validate() -> void:
	var diff := absf(wrapf(heading - TARGET, -180.0, 180.0))
	if diff <= TOL:
		say("Cap confirmé : Sud-Est. La route de Rommel vers le canal de Suez est coupée…", true)
		get_tree().create_timer(1.0).timeout.connect(func():
			if is_open:
				finish(DATE_ID))
	else:
		Sfx.play("click", -3.0, 0.3)
		say("Ce n'est pas le cap de l'ordre de mission (Sud-Est : entre l'Est et le Sud). Regarde la carte : le canal de Suez est en bas à droite d'El-Alamein.")
