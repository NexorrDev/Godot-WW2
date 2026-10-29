extends CanvasLayer

## Menu pause (touche Échap en jeu)
## Même style que le menu principal (voir UIStyle) : bandeau papier, police machine à écrire,
## boutons à sélection beige. Met l'arbre de scène en pause (process_mode = Always pour ce menu).

signal pause_opened
signal pause_closed

var is_open: bool = false

var root: Control
var left_container: VBoxContainer
var popup_layer: CenterContainer
var settings_panel: PanelContainer
var confirm_panel: PanelContainer
var buttons: Array[Button] = []
var fade_tween: Tween = null

# Contrôles des paramètres (mêmes réglages que le menu principal)
var check_fullscreen: CheckBox
var slider_sensitivity: HSlider
var label_sensitivity_val: Label
var slider_fov: HSlider
var label_fov_val: Label
var check_head_bob: CheckBox

func _ready() -> void:
	add_to_group("pause_menu")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	visible = false
	_build_ui()
	root.modulate.a = 0.0

# ---------------------------------------------------------------------------
# Entrées
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
		return

	if is_open:
		# Échap ferme d'abord les fenêtres ouvertes, puis le menu pause
		if _any_popup_open():
			_close_popups()
		else:
			close_pause()
		get_viewport().set_input_as_handled()
		return

	if _can_open():
		open_pause()
		get_viewport().set_input_as_handled()

## On n'ouvre la pause que si le joueur a la main (donc ni menu principal,
## ni fiche d'archive, ni carnet, ni radio ouverts).
func _can_open() -> bool:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return false
	return players[0].can_control

# ---------------------------------------------------------------------------
# Ouverture / fermeture
# ---------------------------------------------------------------------------

func open_pause() -> void:
	if is_open:
		return
	is_open = true
	_close_popups()
	_select(buttons[0])

	visible = true
	Sfx.play("pause")
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("player", "pause_control")

	_fade(1.0, 0.18)
	pause_opened.emit()

func close_pause() -> void:
	if not is_open:
		return
	is_open = false
	_close_popups()
	Sfx.play("pause", -4.0)

	get_tree().paused = false
	get_tree().call_group("player", "resume_control")

	var tw := _fade(0.0, 0.12)
	tw.tween_callback(func():
		if not is_open:
			visible = false
	)
	pause_closed.emit()

func _fade(target_alpha: float, duration: float) -> Tween:
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(root, "modulate:a", target_alpha, duration)
	return fade_tween

func _return_to_main_menu() -> void:
	get_tree().paused = false
	GameManager.reset_game()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()

# ---------------------------------------------------------------------------
# Sélection des boutons
# ---------------------------------------------------------------------------

func _select(target: Button) -> void:
	for btn in buttons:
		UIStyle.style_menu_button(btn, btn == target)

func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var btn := UIStyle.make_menu_button(text)
	parent.add_child(btn)
	btn.pressed.connect(callback)
	btn.mouse_entered.connect(_select.bind(btn))
	btn.focus_entered.connect(_select.bind(btn))
	buttons.append(btn)

# ---------------------------------------------------------------------------
# Fenêtres (paramètres / confirmation)
# ---------------------------------------------------------------------------

func _any_popup_open() -> bool:
	return settings_panel.visible or confirm_panel.visible

func _close_popups() -> void:
	settings_panel.visible = false
	confirm_panel.visible = false

func _show_settings() -> void:
	_sync_settings()
	confirm_panel.visible = false
	settings_panel.visible = true

func _show_confirm() -> void:
	settings_panel.visible = false
	confirm_panel.visible = true

## Recopie l'état actuel du joueur dans les curseurs (sans déclencher les signaux)
func _sync_settings() -> void:
	check_fullscreen.set_pressed_no_signal(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p = players[0]

	var mult: float = p.mouse_sensitivity / p.base_mouse_sensitivity
	slider_sensitivity.set_value_no_signal(mult)
	label_sensitivity_val.text = "%d%%" % int(round(mult * 100.0))

	var fov: float = p.camera.fov
	slider_fov.set_value_no_signal(fov)
	label_fov_val.text = "%d°" % int(fov)

	check_head_bob.set_pressed_no_signal(p.head_bob_enabled)

# ---------------------------------------------------------------------------
# Construction de l'interface
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	root = Control.new()
	root.name = "RootControl"
	add_child(root)
	UIStyle.fill_rect(root)

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.03, 0.03, 0.04, 0.72)
	root.add_child(backdrop)
	UIStyle.fill_rect(backdrop)

	root.add_child(UIStyle.make_vignette())
	root.add_child(UIStyle.make_left_shade())

	# Bloc de menu à gauche (mêmes positions que le menu principal)
	left_container = VBoxContainer.new()
	left_container.name = "LeftMenuContainer"
	left_container.position = Vector2(80, 130)
	left_container.custom_minimum_size = Vector2(350, 0)
	left_container.add_theme_constant_override("separation", 22)
	root.add_child(left_container)

	left_container.add_child(UIStyle.make_title_strip("PAUSE"))
	left_container.add_child(UIStyle.make_subtitle("Dossier en attente..."))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	left_container.add_child(spacer)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	left_container.add_child(list)

	_add_button(list, "Reprendre", close_pause)
	_add_button(list, "Paramètres", _show_settings)
	_add_button(list, "Menu principal", _show_confirm)
	_add_button(list, "Quitter", func(): get_tree().quit())
	_select(buttons[0])

	UIStyle.add_footer(root, "[ÉCHAP] REPRENDRE L'ENQUÊTE")

	# Calque central pour les fenêtres
	popup_layer = CenterContainer.new()
	popup_layer.name = "PopupLayer"
	popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(popup_layer)
	UIStyle.fill_rect(popup_layer)

	_build_settings_panel()
	_build_confirm_panel()

func _make_popup(min_size: Vector2) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", UIStyle.popup_stylebox())
	popup_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	return vbox

func _popup_title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.85, 0.81, 0.74, 1))
	l.add_theme_font_size_override("font_size", 24)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _popup_label(text: String, size: int = 15, color: Color = Color(0.9, 0.9, 0.9, 1)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	return l

func _popup_check(text: String) -> CheckBox:
	var c := CheckBox.new()
	c.text = text
	c.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	c.add_theme_font_size_override("font_size", 15)
	return c

func _popup_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(160, 36)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b

func _build_settings_panel() -> void:
	var vbox := _make_popup(Vector2(480, 420))
	settings_panel = vbox.get_parent().get_parent() as PanelContainer

	vbox.add_child(_popup_title("PARAMÈTRES"))
	vbox.add_child(HSeparator.new())

	# 1. Plein écran
	check_fullscreen = _popup_check("Activer le mode Plein écran")
	vbox.add_child(check_fullscreen)
	check_fullscreen.toggled.connect(func(pressed: bool):
		if pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)

	# 2. Sensibilité de la souris
	var sens_box := HBoxContainer.new()
	sens_box.add_theme_constant_override("separation", 10)
	vbox.add_child(sens_box)
	var sens_label := _popup_label("Sensibilité de la souris :")
	sens_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sens_box.add_child(sens_label)
	slider_sensitivity = HSlider.new()
	slider_sensitivity.custom_minimum_size = Vector2(160, 0)
	slider_sensitivity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider_sensitivity.min_value = 0.5
	slider_sensitivity.max_value = 2.0
	slider_sensitivity.step = 0.1
	slider_sensitivity.value = 1.0
	sens_box.add_child(slider_sensitivity)
	label_sensitivity_val = _popup_label("100%", 14, Color(0.8, 0.75, 0.65, 1))
	label_sensitivity_val.custom_minimum_size = Vector2(50, 0)
	label_sensitivity_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sens_box.add_child(label_sensitivity_val)
	slider_sensitivity.value_changed.connect(func(val: float):
		label_sensitivity_val.text = "%d%%" % int(round(val * 100.0))
		get_tree().call_group("player", "set_mouse_sensitivity_multiplier", val)
	)

	# 3. Champ de vision (FOV)
	var fov_box := HBoxContainer.new()
	fov_box.add_theme_constant_override("separation", 10)
	vbox.add_child(fov_box)
	var fov_label := _popup_label("Champ de vision (FOV) :")
	fov_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fov_box.add_child(fov_label)
	slider_fov = HSlider.new()
	slider_fov.custom_minimum_size = Vector2(160, 0)
	slider_fov.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider_fov.min_value = 60.0
	slider_fov.max_value = 95.0
	slider_fov.step = 1.0
	slider_fov.value = 75.0
	fov_box.add_child(slider_fov)
	label_fov_val = _popup_label("75°", 14, Color(0.8, 0.75, 0.65, 1))
	label_fov_val.custom_minimum_size = Vector2(50, 0)
	label_fov_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fov_box.add_child(label_fov_val)
	slider_fov.value_changed.connect(func(val: float):
		label_fov_val.text = "%d°" % int(val)
		get_tree().call_group("player", "set_fov", val)
	)

	# 4. Balancement de marche
	check_head_bob = _popup_check("Balancement de marche (Head Bobbing)")
	check_head_bob.button_pressed = true
	vbox.add_child(check_head_bob)
	check_head_bob.toggled.connect(func(pressed: bool):
		get_tree().call_group("player", "set_head_bob_enabled", pressed)
	)

	vbox.add_child(HSeparator.new())

	var info := _popup_label(
		"Commandes :\n• Déplacement : ZQSD / WASD / Flèches\n• Viser / Regarder : Souris\n• Examiner / Interagir : Touche E\n• Pause / Reprendre : Touche Échap",
		13, Color(0.7, 0.68, 0.65, 1))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)

	var close_btn := _popup_button("Fermer")
	vbox.add_child(close_btn)
	close_btn.pressed.connect(func(): settings_panel.visible = false)

func _build_confirm_panel() -> void:
	var vbox := _make_popup(Vector2(440, 0))
	confirm_panel = vbox.get_parent().get_parent() as PanelContainer

	vbox.add_child(_popup_title("RETOUR AU MENU"))
	vbox.add_child(HSeparator.new())

	var msg := _popup_label("Votre progression est sauvegardée automatiquement.\nRetourner au menu principal ?", 15, Color(0.9, 0.9, 0.9, 1))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vbox.add_child(row)

	var confirm_btn := _popup_button("Confirmer")
	row.add_child(confirm_btn)
	confirm_btn.pressed.connect(_return_to_main_menu)

	var cancel_btn := _popup_button("Annuler")
	row.add_child(cancel_btn)
	cancel_btn.pressed.connect(func(): confirm_panel.visible = false)
