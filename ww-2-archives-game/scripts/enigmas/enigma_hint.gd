extends OverlayBase

## Panneau d'indices (ampoule) : une carte par date de la période en cours pas encore trouvée.
## Chaque carte donne d'abord un indice sur où chercher, puis (à la demande) la solution.

var levels := {}      # date_id -> 0 (rien) / 1 (où chercher) / 2 (solution)
var list: VBoxContainer
var scroll: ScrollContainer

func _init() -> void:
	super("hint_panel", "AMPOULE — INDICES")
	_min_width = 760.0

func _build_content() -> void:
	vb.add_child(hint("Bloqué ? Chaque archive de la période en cours a deux niveaux d'aide : d'abord où chercher, puis la solution. Essaie le premier avant de passer au second."))
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.custom_minimum_size = Vector2(740, 0)
	scroll.add_child(list)

func _on_open() -> void:
	_rebuild()

func open_hints() -> void:
	open_overlay()

func _rebuild() -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	var period: int = GameManager.current_period
	var shown := 0
	for id in HistoricalData.DATES.keys():
		var info: Dictionary = HistoricalData.get_date_info(id)
		if info.get("period", 0) != period or GameManager.is_date_unlocked(id):
			continue
		shown += 1
		list.add_child(_card(id, info))
	if shown == 0:
		var l := hint("Toutes les archives de cette période sont trouvées. Bravo !")
		list.add_child(l)
	var names := {1: "PÉRIODE 1 · MATIN", 2: "PÉRIODE 2 · MIDI", 3: "PÉRIODE 3 · SOIR"}
	say("%s — %d archive(s) restante(s) dans cette période." % [names.get(period, ""), shown])

func _card(id: String, info: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.10, 0.09, 0.95)
	sb.border_color = Color(0.55, 0.46, 0.25, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	var idx := HistoricalData.DATES.keys().find(id) + 1
	var t := Label.new()
	t.text = "ARCHIVE N°%d  ·  %s" % [idx, info.get("object_name", "")]
	t.add_theme_font_override("font", UIStyle.font_title())
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", UIStyle.GOLD)
	v.add_child(t)
	var body := Label.new()
	body.add_theme_font_override("font", UIStyle.font_mono())
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", UIStyle.TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(700, 0)
	v.add_child(body)
	var btn := UIStyle.make_menu_button("Voir l'indice")
	v.add_child(btn)
	var refresh := func():
		var lv: int = levels.get(id, 0)
		var hs: Array = HintData.HINTS.get(id, ["", ""])
		if lv == 0:
			body.text = "Indice caché."
			btn.text = "Voir l'indice"
			btn.visible = true
		elif lv == 1:
			body.text = "INDICE : " + hs[0]
			btn.text = "Plus d'aide (la solution)"
			btn.visible = true
		else:
			body.text = "INDICE : " + hs[0] + "\n\nSOLUTION : " + hs[1]
			btn.visible = false
	btn.pressed.connect(func():
		levels[id] = mini(levels.get(id, 0) + 1, 2)
		Sfx.play("click", -6.0)
		refresh.call())
	refresh.call()
	return pc
