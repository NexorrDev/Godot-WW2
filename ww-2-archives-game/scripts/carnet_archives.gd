extends CanvasLayer

## Carnet d'Archives Militaire (Consultable avec la touche TAB ou J)
## Affiche la vue d'ensemble des 15 dates réparties sur les 3 périodes.
## Permet de suivre la progression (0/15) et de relire n'importe quelle fiche débloquée.

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
	counter_label.text = "PROGRESSION : %d / 15 ARCHIVES RECONSTITUÉES" % total_unlocked
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
		
		var card = _create_date_card(date_data, is_unlocked, i + 1 + (period_num - 1) * 5)
		container.add_child(card)

func _create_date_card(data: Dictionary, unlocked: bool, index: int) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 68)
	btn.clip_text = false
	
	var style_normal = StyleBoxFlat.new()
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	style_normal.content_margin_left = 10
	style_normal.content_margin_top = 8
	style_normal.content_margin_right = 10
	style_normal.content_margin_bottom = 8
	
	if unlocked:
		style_normal.bg_color = Color(0.18, 0.19, 0.16, 0.95)
		style_normal.border_color = Color(0.72, 0.62, 0.42, 0.8)
		style_normal.border_width_left = 3
		style_normal.border_width_top = 1
		style_normal.border_width_right = 1
		style_normal.border_width_bottom = 1
		
		var style_hover = style_normal.duplicate()
		style_hover.bg_color = Color(0.24, 0.25, 0.20, 1.0)
		style_hover.border_color = Color(0.95, 0.85, 0.55, 1.0)
		style_hover.border_width_left = 4
		
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_hover)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		# Contenu débloqué
		var vbox = VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		var lbl_date = Label.new()
		lbl_date.text = "DATE : %s" % data.get("date_str", "").to_upper()
		lbl_date.add_theme_color_override("font_color", Color(0.95, 0.82, 0.48))
		lbl_date.add_theme_font_size_override("font_size", 11)
		vbox.add_child(lbl_date)
		
		var lbl_title = Label.new()
		lbl_title.text = "%d. %s" % [index, data.get("title", "").to_upper()]
		lbl_title.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88))
		lbl_title.add_theme_font_size_override("font_size", 12)
		lbl_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		vbox.add_child(lbl_title)
		
		var lbl_loc = Label.new()
		lbl_loc.text = "SECTEUR : %s" % data.get("location", "")
		lbl_loc.add_theme_color_override("font_color", Color(0.68, 0.65, 0.58))
		lbl_loc.add_theme_font_size_override("font_size", 10)
		lbl_loc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		vbox.add_child(lbl_loc)
		
		btn.add_child(vbox)
		
		var date_id = data.get("id", "")
		btn.pressed.connect(func():
			# Ouvre directement la fiche d'archives complète
			get_tree().call_group("document_viewer", "open_document", date_id)
		)
	else:
		# Carte verrouillée
		style_normal.bg_color = Color(0.09, 0.08, 0.07, 0.7)
		style_normal.border_color = Color(0.24, 0.22, 0.20, 0.6)
		style_normal.border_width_left = 1
		style_normal.border_width_top = 1
		style_normal.border_width_right = 1
		style_normal.border_width_bottom = 1
		
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_normal)
		btn.add_theme_stylebox_override("disabled", style_normal)
		btn.disabled = true
		
		var vbox = VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		var lbl_locked = Label.new()
		lbl_locked.text = "[ DOSSIER SECRET N°%d ]" % index
		lbl_locked.add_theme_color_override("font_color", Color(0.48, 0.44, 0.38))
		lbl_locked.add_theme_font_size_override("font_size", 12)
		lbl_locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_locked)
		
		var lbl_hint = Label.new()
		lbl_hint.text = "ACCÈS RESTREINT // NON IDENTIFIÉ"
		lbl_hint.add_theme_color_override("font_color", Color(0.35, 0.32, 0.28))
		lbl_hint.add_theme_font_size_override("font_size", 10)
		lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_hint)
		
		btn.add_child(vbox)
		
	return btn

## Réception du signal de nouvelle date débloquée
func _on_date_unlocked(date_id: String, date_info: Dictionary) -> void:
	refresh_carnet()
