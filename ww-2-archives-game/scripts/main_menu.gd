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

var normal_style: StyleBoxEmpty
var hover_style: StyleBoxFlat
var buttons: Array[Button] = []

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	normal_style = StyleBoxEmpty.new()
	
	hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.85, 0.81, 0.74, 1.0) # Fond papier beige/parchemin
	hover_style.corner_radius_top_left = 2
	hover_style.corner_radius_top_right = 2
	hover_style.corner_radius_bottom_right = 2
	hover_style.corner_radius_bottom_left = 2
	hover_style.content_margin_left = 12.0
	hover_style.content_margin_right = 16.0
	hover_style.content_margin_top = 4.0
	hover_style.content_margin_bottom = 4.0
	
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
	var original_text = btn.get_meta("original_text", "")
	if original_text == "":
		original_text = btn.text.replace("▶ ", "").strip_edges()
		btn.set_meta("original_text", original_text)
	
	if is_selected:
		btn.text = "▶  " + original_text
		btn.add_theme_stylebox_override("normal", hover_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("focus", hover_style)
		btn.add_theme_color_override("font_color", Color(0.12, 0.12, 0.12))
		btn.add_theme_color_override("font_hover_color", Color(0.12, 0.12, 0.12))
	else:
		btn.text = "    " + original_text
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", normal_style)
		btn.add_theme_stylebox_override("focus", normal_style)
		btn.add_theme_color_override("font_color", Color(0.78, 0.76, 0.72))
		btn.add_theme_color_override("font_hover_color", Color(0.95, 0.93, 0.88))

func _on_new_game_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(menu_root, "modulate:a", 0.0, 0.35)
	await tween.finished
	visible = false
	game_started.emit()
