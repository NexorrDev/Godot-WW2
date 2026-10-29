extends CanvasLayer

## Menu Principal "Les Archives" affiché directement en surimpression de la pièce 3D

signal game_started

@onready var menu_root: Control = $MenuRoot
@onready var btn_new_game: Button = %BtnNewGame
@onready var btn_continue: Button = %BtnContinue
@onready var btn_settings: Button = %BtnSettings
@onready var btn_credits: Button = %BtnCredits
@onready var btn_quit: Button = %BtnQuit

@onready var credits_panel: PanelContainer = %CreditsPanel
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var close_credits_btn: Button = %CloseCreditsBtn
@onready var close_settings_btn: Button = %CloseSettingsBtn

# Paramètres fonctionnels
@onready var check_fullscreen: CheckBox = %CheckFullscreen
@onready var slider_sensitivity: HSlider = %SliderSensitivity
@onready var label_sensitivity_val: Label = %LabelSensitivityVal
@onready var slider_fov: HSlider = %SliderFov
@onready var label_fov_val: Label = %LabelFovVal
@onready var check_head_bob: CheckBox = %CheckHeadBob

var buttons: Array[Button] = []

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_style_visuals()

	buttons = [btn_new_game, btn_continue, btn_settings, btn_credits, btn_quit]
	
	for btn in buttons:
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.focus_entered.connect(_on_button_hover.bind(btn))
		_apply_style(btn, false)
	
	# Par défaut "Nouvelle partie" est surligné
	_apply_style(btn_new_game, true)
	
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_new_game_pressed)
	btn_settings.pressed.connect(func(): settings_panel.visible = true)
	btn_credits.pressed.connect(func(): credits_panel.visible = true)
	btn_quit.pressed.connect(func(): get_tree().quit())
	
	if close_credits_btn:
		close_credits_btn.pressed.connect(func(): credits_panel.visible = false)
	if close_settings_btn:
		close_settings_btn.pressed.connect(func(): settings_panel.visible = false)

	_setup_settings()

## Habillage visuel (bandeau papier, polices, vignette, animation d'entrée).
## Le style est partagé avec le menu pause via UIStyle.
func _style_visuals() -> void:
	var container: Control = $MenuRoot/LeftMenuContainer
	var title_panel: PanelContainer = $MenuRoot/LeftMenuContainer/TitleBox/TitlePanel
	var title_label: Label = $MenuRoot/LeftMenuContainer/TitleBox/TitlePanel/TitleLabel
	var subtitle_label: Label = $MenuRoot/LeftMenuContainer/SubtitleLabel

	UIStyle.style_title(title_panel, title_label, 46)
	UIStyle.style_subtitle(subtitle_label)

	# Vignette sous tout le reste de l'interface
	var vignette := UIStyle.make_vignette()
	menu_root.add_child(vignette)
	menu_root.move_child(vignette, 0)

	UIStyle.add_footer(menu_root, "ÉTAT-MAJOR GÉNÉRAL // REGISTRE DE GUERRE 1939-1945")

	# Petite animation d'entrée : le bloc de menu glisse et apparaît
	var base_x: float = container.position.x
	container.modulate.a = 0.0
	container.position.x = base_x - 40.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(container, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(container, "position:x", base_x, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _setup_settings() -> void:
	# 1. Plein écran
	if check_fullscreen:
		check_fullscreen.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		check_fullscreen.toggled.connect(func(pressed: bool):
			if pressed:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		)
	
	# 2. Sensibilité souris
	if slider_sensitivity:
		slider_sensitivity.value_changed.connect(func(val: float):
			if label_sensitivity_val:
				label_sensitivity_val.text = "%d%%" % int(val * 100)
			get_tree().call_group("player", "set_mouse_sensitivity_multiplier", val)
		)
	
	# 3. Champ de vision (FOV)
	if slider_fov:
		slider_fov.value_changed.connect(func(val: float):
			if label_fov_val:
				label_fov_val.text = "%d°" % int(val)
			get_tree().call_group("player", "set_fov", val)
		)
	
	# 4. Balancement de marche
	if check_head_bob:
		check_head_bob.button_pressed = true
		check_head_bob.toggled.connect(func(pressed: bool):
			get_tree().call_group("player", "set_head_bob_enabled", pressed)
		)

func _on_button_hover(target_btn: Button) -> void:
	for btn in buttons:
		_apply_style(btn, btn == target_btn)

func _apply_style(btn: Button, is_selected: bool) -> void:
	# "Continuer" est grisé tant qu'il n'y a pas de sauvegarde (comme sur la maquette)
	UIStyle.style_menu_button(btn, is_selected, btn == btn_continue)

func _on_new_game_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(menu_root, "modulate:a", 0.0, 0.35)
	await tween.finished
	visible = false
	game_started.emit()
