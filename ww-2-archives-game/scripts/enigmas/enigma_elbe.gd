extends OverlayBase

## Date 13 : 26 avril 1945, jonction sur l'Elbe à Torgau.
## Un cadre photo déchiré : deux moitiés (soldat américain / soldat soviétique) à reconstituer.

const DATE_ID := "elbe_1945"
const PW := 260.0
const PH := 300.0

var area: Control
var piece_a: Control
var piece_b: Control
var dragging: Control = null
var drag_off := Vector2.ZERO
var done_msg := false

func _init() -> void:
	super("enigma_elbe", "CADRE PHOTO — DEUX MOITIÉS DÉCHIRÉES")

func _build_content() -> void:
	vb.add_child(hint("Une photo déchirée en deux, face contre la table. Fais glisser les deux moitiés pour les raccorder : on doit voir la poignée de main de Torgau."))
	area = Control.new()
	area.custom_minimum_size = Vector2(700, 360)
	area.clip_contents = true
	area.draw.connect(func(): area.draw_rect(Rect2(Vector2.ZERO, area.size), Color(0.16, 0.12, 0.09)))
	vb.add_child(area)
	piece_a = _make_piece(true)
	piece_b = _make_piece(false)
	area.add_child(piece_a)
	area.add_child(piece_b)

func _make_piece(american: bool) -> Control:
	var c := Control.new()
	c.size = Vector2(PW + 14, PH)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.draw.connect(func(): _draw_piece(c, american))
	c.gui_input.connect(func(e: InputEvent): _piece_input(c, e))
	return c

func _tear(american: bool) -> PackedVector2Array:
	# bord déchiré : ligne en dents de scie commune (décalée selon le côté)
	var pts := PackedVector2Array()
	var xs := [0.0, 8.0, -4.0, 10.0, -6.0, 6.0, -2.0, 9.0, -5.0, 4.0, 0.0]
	if american:
		pts.append(Vector2(0, 0))
		for i in xs.size():
			pts.append(Vector2(PW + xs[i], i * PH / (xs.size() - 1)))
		pts.append(Vector2(0, PH))
	else:
		pts.append(Vector2(PW + 14, 0))
		for i in xs.size():
			pts.append(Vector2(14.0 + xs[i], i * PH / (xs.size() - 1)))
		pts.append(Vector2(PW + 14, PH))
	return pts

func _draw_piece(c: Control, american: bool) -> void:
	var off := 0.0 if american else 0.0
	c.draw_colored_polygon(_tear(american), Color(0.72, 0.68, 0.58))
	# fond de décor (ciel / rive de l'Elbe)
	var sky := PackedVector2Array([Vector2(0 if american else 14, 0), Vector2(PW if american else PW + 14, 0), Vector2(PW if american else PW + 14, PH * 0.55), Vector2(0 if american else 14, PH * 0.55)])
	c.draw_colored_polygon(sky, Color(0.80, 0.80, 0.76))
	c.draw_rect(Rect2(0 if american else 14, PH * 0.55, PW, PH * 0.45), Color(0.45, 0.45, 0.40))
	# soldat
	var bx := 120.0 if american else 140.0
	var uni := Color(0.33, 0.36, 0.22) if american else Color(0.42, 0.34, 0.20)
	c.draw_rect(Rect2(bx - 34, 125, 68, 150), uni)                   # corps
	c.draw_circle(Vector2(bx, 100), 24, Color(0.78, 0.62, 0.5))      # tête
	if american:
		c.draw_arc(Vector2(bx, 92), 28, PI, TAU, 16, Color(0.25, 0.28, 0.17), 14.0)  # casque
		c.draw_string(UIStyle.font_title(), Vector2(18, 28), "U.S. ARMY", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.1, 0.1, 0.1))
	else:
		c.draw_rect(Rect2(bx - 26, 68, 52, 18), Color(0.3, 0.25, 0.15))        # chapka
		c.draw_circle(Vector2(bx, 77), 5, Color(0.8, 0.1, 0.1))                 # étoile
		c.draw_string(UIStyle.font_title(), Vector2(30, 28), "ARMÉE ROUGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.1, 0.1, 0.1))
	# bras tendu vers la déchirure, main à hauteur y = 175
	var hand := Vector2(PW + 4, 175) if american else Vector2(14 - 2, 175)
	c.draw_line(Vector2(bx + (30 if american else -30), 150), hand, uni, 18.0)
	c.draw_circle(hand, 11, Color(0.78, 0.62, 0.5))
	c.draw_polyline(_tear(american), Color(0.2, 0.17, 0.12), 2.0)

func _on_open() -> void:
	solved = GameManager.is_date_unlocked(DATE_ID)
	done_msg = false
	if solved:
		piece_a.position = Vector2(60, 30)
		piece_b.position = piece_a.position + Vector2(PW - 14.0, 0)
		say("La photo est reconstituée : poignée de main entre un soldat américain et un soldat soviétique, Torgau, 26 avril 1945.", true)
	else:
		piece_a.position = Vector2(30, 20)
		piece_b.position = Vector2(400, 50)
		say("")

func _piece_input(c: Control, e: InputEvent) -> void:
	if solved:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			dragging = c
			drag_off = c.get_local_mouse_position()
			c.move_to_front()
		else:
			dragging = null
			_check()
	elif e is InputEventMouseMotion and dragging == c:
		c.position = (area.get_local_mouse_position() - drag_off).clamp(Vector2.ZERO, area.size - c.size)

func _check() -> void:
	var rel := piece_b.position - piece_a.position
	if rel.distance_to(Vector2(PW - 14.0, 0)) < 22.0:
		piece_b.position = piece_a.position + Vector2(PW - 14.0, 0)
		solved = true
		say("Les deux moitiés se raccordent : poignée de main entre un soldat américain et un soldat soviétique !", true)
		get_tree().create_timer(1.2).timeout.connect(func():
			if is_open:
				finish(DATE_ID))
