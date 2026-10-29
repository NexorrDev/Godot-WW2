extends CanvasLayer

## Carnet d'Archives Militaire (Consultable avec la touche TAB ou J)
## Affiche la vue d'ensemble des 15 dates réparties sur les 3 périodes.
## Permet de suivre la progression (0/15) et de relire n'importe quelle fiche débloquée.
## Chaque période a sa couleur (bleu / orange / or) pour se repérer d'un coup d'œil.

const PERIOD_COLORS: Dictionary = {
	1: Color(0.50, 0.68, 0.92),
	2: Color(0.95, 0.66, 0.34),
	3: Color(0.93, 0.83, 0.45),
}

@onready var root_control: Control = $RootControl
@onready var counter_label: Label = %CounterLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var close_button: Button = %CloseButton

# Conteneurs des 3 colonnes de périodes
@onready var period_1_container: VBoxContainer = %Period1Container
@onready var period_2_container: VBoxContainer = %Period2Container
@onready var period_3_container: VBoxContainer = %Period3Container

var is_open: bool = false

func _ready() -> void:
	add_to_group("carnet_archives")
	visible = false
	root_control.modulate.a = 0.0

	close_button.pressed.connect(close_carnet)

	# Connexion aux signaux du GameManager
	GameManager.date_unlocked.connect(_on_date_unlocked)

	# Initialisation de l'affichage
	refresh_carnet()

func _unhandled_input(event: InputEvent) -> void:
	# Touche TAB ou J pour ouvrir / fermer le carnet
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_J:
			# Si le DocumentViewer est ouvert, on ne toggle pas le carnet par-dessus
			var doc_viewers = get_tree().get_nodes_in_group("document_viewer")
			if doc_viewers.size() > 0 and doc_viewers[0].is_open:
				return

			# Si le menu principal est actif, on n'ouvre pas le carnet
			var main_menus = get_tree().get_nodes_in_group("main_menu")
			if main_menus.size() > 0 and main_menus[0].is_in_menu:
				return

			toggle_carnet()
			get_viewport().set_input_as_handled()
			return

		if is_open and (event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel")):
			close_carnet()
			get_viewport().set_input_as_handled()
			return

func toggle_carnet() -> void:
	if is_open:
		close_carnet()
	else:
		open_carnet()

func open_carnet() -> void:
	if is_open:
		return
	is_open = true
	refresh_carnet()

	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("player", "pause_control")

	var tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 1.0, 0.2)

func close_carnet() -> void:
	if not is_open:
		return
	is_open = false

	var tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 0.0, 0.15)
	await tween.finished
	visible = false

	# Ne réactive les contrôles que si le DocumentViewer n'est pas ouvert
	var doc_viewers = get_tree().get_nodes_in_group("document_viewer")
	var doc_open = doc_viewers.size() > 0 and doc_viewers[0].is_open
	if not doc_open:
		get_tree().call_group("player", "resume_control")

## Met à jour toutes les cartes de dates dans les 3 colonnes
func refresh_carnet() -> void:
	var total_unlocked = GameManager.get_unlocked_count()
	counter_label.text = "%d / 15 ARCHIVES RECONSTITUÉES" % total_unlocked
	progress_bar.value = total_unlocked

	_populate_column(period_1_container, 1)
	_populate_column(period_2_container, 2)
	_populate_column(period_3_container, 3)

func _populate_column(container: VBoxContainer, period_num: int) -> void:
	# Nettoyer les anciens enfants
	for child in container.get_children():
		child.queue_free()

	var dates = HistoricalData.get_dates_for_period(period_num)
	for i in range(dates.size()):
		var date_data = dates[i]
		var date_id = date_data.get("id", "")
		var is_unlocked = GameManager.is_date_unlocked(date_id)

		var card = _create_date_card(date_data, is_unlocked, i + 1 + (period_num - 1) * 5, period_num)
		container.add_child(card)

func _make_label(text: String, size: int, color: Color, mono: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	if mono:
		lbl.add_theme_font_override("font", UIStyle.font_mono())
	return lbl

func _create_date_card(data: Dictionary, unlocked: bool, index: int, period_num: int) -> Control:
	var accent: Color = PERIOD_COLORS.get(period_num, Color.WHITE)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 76)
	btn.clip_text = false
	btn.focus_mode = Control.FOCUS_NONE

	var style_normal := StyleBoxFlat.new()
	style_normal.set_corner_radius_all(4)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	if unlocked:
		style_normal.bg_color = Color(0.20, 0.21, 0.18, 1.0)
		style_normal.border_color = accent.darkened(0.25)
		style_normal.border_width_left = 5
		style_normal.border_width_top = 1
		style_normal.border_width_right = 1
		style_normal.border_width_bottom = 1

		var style_hover: StyleBoxFlat = style_normal.duplicate()
		style_hover.bg_color = Color(0.28, 0.29, 0.24, 1.0)
		style_hover.border_color = accent

		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_hover)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		# Ligne 1 : numéro + date
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 10)
		row.add_child(_make_label("%02d" % index, 14, accent, true))
		row.add_child(_make_label(str(data.get("date_str", "")).to_upper(), 13, Color(0.86, 0.80, 0.66), true))
		vbox.add_child(row)

		# Ligne 2 : titre lisible (police normale, casse normale, 2 lignes max)
		var lbl_title := _make_label(str(data.get("title", "")), 15, Color(0.97, 0.95, 0.91))
		lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_title.max_lines_visible = 2
		lbl_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		vbox.add_child(lbl_title)

		var date_id = data.get("id", "")
		btn.pressed.connect(func():
			# Ouvre directement la fiche d'archives complète
			get_tree().call_group("document_viewer", "open_document", date_id)
		)
	else:
		# Carte verrouillée (texte plus contrasté qu'avant pour rester lisible)
		style_normal.bg_color = Color(0.11, 0.10, 0.09, 0.9)
		style_normal.border_color = Color(0.32, 0.30, 0.27, 1.0)
		style_normal.set_border_width_all(1)

		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_normal)
		btn.add_theme_stylebox_override("disabled", style_normal)
		btn.disabled = true

		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var lbl_locked := _make_label("[ DOSSIER CLASSIFIÉ N°%02d ]" % index, 14, Color(0.68, 0.64, 0.56), true)
		lbl_locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_locked)

		var lbl_hint := _make_label("À DÉCOUVRIR DANS LE BUREAU", 12, Color(0.54, 0.51, 0.46), true)
		lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_hint)

	btn.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return btn

## Réception du signal de nouvelle date débloquée
func _on_date_unlocked(date_id: String, date_info: Dictionary) -> void:
	refresh_carnet()
