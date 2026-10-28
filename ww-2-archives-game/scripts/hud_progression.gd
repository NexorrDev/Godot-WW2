extends CanvasLayer

## HUD de Progression en jeu (Affichage permanent + Toast)
## Affiche en temps réel le nombre d'archives débloquées (0/15),
## la période actuelle de la guerre et les notifications de découverte.

@onready var root_control: Control = $RootControl
@onready var badge_panel: PanelContainer = %BadgePanel
@onready var counter_label: Label = %CounterLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var period_label: Label = %PeriodLabel

@onready var toast_panel: PanelContainer = %ToastPanel
@onready var toast_title: Label = %ToastTitle
@onready var toast_subtitle: Label = %ToastSubtitle

var toast_tween: Tween = null
var pulse_tween: Tween = null

func _ready() -> void:
	add_to_group("hud_progression")
	# Masqué au début tant qu'on est sur le menu principal
	root_control.modulate.a = 0.0
	
	if toast_panel:
		toast_panel.visible = false
		toast_panel.modulate.a = 0.0
	
	# Connexions aux signaux du GameManager
	GameManager.date_unlocked.connect(_on_date_unlocked)
	GameManager.period_changed.connect(_on_period_changed)
	
	_update_display()

## Appelé quand le joueur lance la partie depuis le menu
func show_hud() -> void:
	_update_display()
	var tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 1.0, 0.4)

func hide_hud() -> void:
	var tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 0.0, 0.25)

func _update_display() -> void:
	var count = GameManager.get_unlocked_count()
	counter_label.text = "ARCHIVES IDENTIFIÉES : %d / 15" % count
	progress_bar.value = count
	
	match GameManager.current_period:
		1:
			period_label.text = "PÉRIODE 1 : LES VICTOIRES DE L'AXE (1939-1941)"
		2:
			period_label.text = "PÉRIODE 2 : LE TOURNANT DE LA GUERRE (1942-1943)"
		3:
			period_label.text = "PÉRIODE 3 : LA VICTOIRE DES ALLIÉS (1944-1945)"

func _on_date_unlocked(date_id: String, date_info: Dictionary) -> void:
	_update_display()
	_pulse_badge()
	_show_toast(date_info)

func _on_period_changed(new_period: int) -> void:
	_update_display()
	_pulse_badge()

## Animation de pulsation dorée sur le badge lors d'une découverte
func _pulse_badge() -> void:
	if not badge_panel:
		return
		
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
		
	pulse_tween = create_tween()
	pulse_tween.tween_property(counter_label, "modulate", Color(1.0, 1.0, 0.8), 0.15)
	pulse_tween.tween_property(counter_label, "modulate", Color(1.0, 1.0, 1.0), 0.3)

## Bannière Toast militaire en haut au centre
func _show_toast(date_info: Dictionary) -> void:
	if not toast_panel:
		return
		
	var count = GameManager.get_unlocked_count()
	var date_str = date_info.get("date_str", "")
	var title = date_info.get("title", "Nouvelle archive")
	
	toast_title.text = "[ ARCHIVE MILITAIRE CLASSÉE // %d / 15 ]" % count
	toast_subtitle.text = "%s : %s" % [date_str.to_upper(), title.to_upper()]
	
	toast_panel.visible = true
	toast_panel.position.y = -60.0
	
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
		
	toast_tween = create_tween()
	# Glisse vers le bas avec fondu
	toast_tween.tween_property(toast_panel, "position:y", 20.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.parallel().tween_property(toast_panel, "modulate:a", 1.0, 0.25)
	# Reste affiché 4.5 secondes
	toast_tween.tween_interval(4.5)
	# Remonte vers le haut
	toast_tween.tween_property(toast_panel, "position:y", -60.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	toast_tween.parallel().tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	toast_tween.tween_callback(func(): toast_panel.visible = false)
