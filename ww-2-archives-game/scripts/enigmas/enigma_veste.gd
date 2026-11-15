extends OverlayBase

## Date 9 : 2 février 1943, Stalingrad. Dans la veste d'un soldat : une lettre gelée.
## Il faut la réchauffer (maintenir le clic dessus) pour la dégeler et la lire.

const DATE_ID := "stalingrad_1943"

var pockets: Array[Button] = []
var found_letter := false
var ice := 1.0
var holding := false
var letter_ctrl: Control
var read_btn: Button
var content_lbl: Label

func _init() -> void:
	super("enigma_veste", "VESTE MILITAIRE — FRONT DE L'EST")

func _build_content() -> void:
	vb.add_child(hint("Une capote de soldat allemand, raidie par le froid russe. Fouille les poches. (Clique sur une poche.)"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	var names := ["Poche gauche", "Poche poitrine", "Poche droite"]
	for i in 3:
		var b := Button.new()
		b.text = names[i]
		b.custom_minimum_size = Vector2(190, 90)
		b.add_theme_font_override("font", UIStyle.font_mono())
		b.pressed.connect(func(): _search(i))
		row.add_child(b)
		pockets.append(b)
	content_lbl = Label.new()
	content_lbl.add_theme_font_override("font", UIStyle.font_mono())
	content_lbl.add_theme_font_size_override("font_size", 17)
	content_lbl.add_theme_color_override("font_color", UIStyle.TEXT)
	content_lbl.custom_minimum_size = Vector2(700, 40)
	vb.add_child(content_lbl)
	letter_ctrl = Control.new()
	letter_ctrl.custom_minimum_size = Vector2(300, 180)
	letter_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	letter_ctrl.draw.connect(_draw_letter)
	letter_ctrl.visible = false
	var cc := CenterContainer.new()
	cc.add_child(letter_ctrl)
	vb.add_child(cc)

func _build_buttons(row: HBoxContainer) -> void:
	read_btn = UIStyle.make_menu_button("Lire la lettre")
	read_btn.visible = false
	read_btn.pressed.connect(func(): finish(DATE_ID))
	row.add_child(read_btn)

func _on_open() -> void:
	found_letter = false
	ice = 1.0
	holding = false
	solved = false
	read_btn.visible = false
	letter_ctrl.visible = false
	content_lbl.text = ""
	for b in pockets:
		b.disabled = false
	if GameManager.is_date_unlocked(DATE_ID):
		found_letter = true
		ice = 0.0
		letter_ctrl.visible = true
		read_btn.visible = true
		content_lbl.text = "La lettre est dégelée."
		say("")
	else:
		say("")

func _search(i: int) -> void:
	Sfx.play("click", -7.0, 0.2)
	pockets[i].disabled = true
	match i:
		0: content_lbl.text = "Un briquet vide et un mouchoir gelé. Rien d'utile."
		2: content_lbl.text = "Quelques cartouches et une photo de famille. Rien d'autre."
		1:
			content_lbl.text = "Une lettre ! Mais le papier est pris dans la glace…"
			found_letter = true
			letter_ctrl.visible = true
			say("Maintiens le clic sur la lettre pour la réchauffer entre tes mains.")

func _process(delta: float) -> void:
	if not is_open or not found_letter or solved:
		return
	holding = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and letter_ctrl.get_global_rect().has_point(letter_ctrl.get_global_mouse_position())
	if holding and ice > 0.0:
		ice = maxf(0.0, ice - delta * 0.35)
		if ice <= 0.0:
			Sfx.play("stamp", -9.0)
			say("La glace a fondu : la lettre d'un soldat de la 6e armée est lisible.", true)
			read_btn.visible = true
	elif not holding and ice > 0.0 and ice < 1.0:
		ice = minf(1.0, ice + delta * 0.05)
	letter_ctrl.queue_redraw()

func _draw_letter() -> void:
	letter_ctrl.draw_rect(Rect2(10, 10, 280, 160), Color(0.9, 0.86, 0.72))
	for i in 6:
		letter_ctrl.draw_line(Vector2(30, 40 + i * 20), Vector2(270 - (i % 3) * 40, 40 + i * 20), Color(0.3, 0.25, 0.2, 0.7), 2.0)
	letter_ctrl.draw_rect(Rect2(10, 10, 280, 160), Color(0.7, 0.88, 1.0, 0.15 + ice * 0.7))
	for i in int(ice * 14.0):
		letter_ctrl.draw_line(Vector2(20 + i * 19, 14), Vector2(10 + i * 19 + 14, 168), Color(1, 1, 1, 0.35), 2.0)
