extends CanvasLayer

## HUD de progression en jeu, volontairement discret :
## - une petite pastille en haut à gauche : compteur "03/15" + 15 segments colorés par période
## - une fine bannière au centre haut à chaque nouvelle archive (ou nouvelle période)
## Les bannières passent dans une file d'attente pour ne jamais se chevaucher.

const TOTAL: int = 15
const PER_PERIOD: int = 5
const SEGMENT_EMPTY: Color = Color(0.28, 0.26, 0.23, 1.0)
const TOAST_HOLD: float = 3.2

const PERIOD_NAMES: Dictionary = {
	1: "PÉRIODE 1 · LES VICTOIRES DE L'AXE (1939-1941)",
	2: "PÉRIODE 2 · LE TOURNANT DE LA GUERRE (1942-1943)",
	3: "PÉRIODE 3 · LA VICTOIRE DES ALLIÉS (1944-1945)",
}

@onready var root_control: Control = $RootControl
@onready var badge_panel: PanelContainer = %BadgePanel
@onready var counter_label: Label = %CounterLabel
@onready var segments_box: HBoxContainer = %SegmentsBox

@onready var toast_panel: PanelContainer = %ToastPanel
@onready var toast_caption: Label = %ToastCaption
@onready var toast_title: Label = %ToastTitle

var segments: Array[ColorRect] = []
var seen_dates: Array[String] = []
var toast_queue: Array[Dictionary] = []
var toast_busy: bool = false
var toast_tween: Tween = null
var toast_style: StyleBoxFlat = null

func _ready() -> void:
	add_to_group("hud_progression")
	# Masqué au début tant qu'on est sur le menu principal
	root_control.modulate.a = 0.0

	toast_panel.visible = false
	toast_panel.modulate.a = 0.0
	# Style propre à ce HUD pour pouvoir changer la couleur du liseré à chaque bannière
	toast_style = (toast_panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	toast_panel.add_theme_stylebox_override("panel", toast_style)

	_build_segments()

	# Connexions aux signaux du GameManager
	GameManager.date_unlocked.connect(_on_date_unlocked)
	GameManager.period_changed.connect(_on_period_changed)
	GameManager.game_loaded.connect(_on_game_loaded)
	# Les bannières attendent que la fiche ouverte soit refermée
	_connect_viewer.call_deferred()

	_update_display(false)

## Crée les 15 petits segments (un espace entre chaque groupe de 5 = une période)
func _build_segments() -> void:
	for i in TOTAL:
		if i > 0 and i % PER_PERIOD == 0:
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(6, 0)
			gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			segments_box.add_child(gap)
		var seg := ColorRect.new()
		seg.custom_minimum_size = Vector2(8, 14)
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seg.color = SEGMENT_EMPTY
		segments_box.add_child(seg)
		segments.append(seg)

## Appelé quand le joueur lance la partie depuis le menu
func show_hud() -> void:
	_update_display(false)
	var tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 1.0, 0.4)

func hide_hud() -> void:
	var tween = create_tween()
	tween.tween_property(root_control, "modulate:a", 0.0, 0.25)

func _segment_color(index: int) -> Color:
	return UIStyle.period_color(int(floor(float(index) / PER_PERIOD)) + 1)

func _update_display(flash_last: bool) -> void:
	var count: int = GameManager.get_unlocked_count()
	counter_label.text = "%02d/%d" % [count, TOTAL]

	for i in segments.size():
		var target: Color = _segment_color(i) if i < count else SEGMENT_EMPTY
		if flash_last and i == count - 1:
			# Le segment qui vient d'être rempli s'illumine puis reprend sa couleur
			segments[i].color = Color.WHITE
			create_tween().tween_property(segments[i], "color", target, 0.8)
		else:
			segments[i].color = target

func _on_date_unlocked(date_id: String, date_info: Dictionary) -> void:
	# Le GameManager ré-émet ce signal quand on relit une fiche déjà découverte :
	# dans ce cas, pas de nouvelle bannière.
	if seen_dates.has(date_id):
		return
	seen_dates.append(date_id)

	_update_display(false)

	var count: int = GameManager.get_unlocked_count()
	var period: int = int(date_info.get("period", 1))
	var date_str: String = str(date_info.get("date_str", "")).to_upper()
	var title: String = str(date_info.get("title", "Nouvelle archive")).to_upper()
	_enqueue_toast("ARCHIVE CLASSÉE  ·  %02d/%d" % [count, TOTAL], "%s — %s" % [date_str, title], UIStyle.period_color(period), count - 1)

## Après un chargement : les archives déjà classées ne déclenchent plus de bannière
func _on_game_loaded() -> void:
	seen_dates.clear()
	for id in GameManager.unlocked_dates:
		seen_dates.append(id)
	toast_queue.clear()
	_update_display(false)

func _on_period_changed(new_period: int) -> void:
	_update_display(false)
	if GameManager.is_loading:
		return
	# Le retour à la période 1 (nouvelle partie) n'a pas besoin d'annonce
	if new_period > 1:
		_enqueue_toast("NOUVELLE PÉRIODE", PERIOD_NAMES.get(new_period, ""), UIStyle.period_color(new_period))

# ---------------------------------------------------------------------------
# Bannières (file d'attente)
# ---------------------------------------------------------------------------

func _enqueue_toast(caption: String, title: String, accent: Color, flash_index: int = -1) -> void:
	toast_queue.append({"caption": caption, "title": title, "accent": accent, "flash": flash_index})
	if not toast_busy:
		_show_next_toast()

func _show_next_toast() -> void:
	if toast_queue.is_empty():
		toast_busy = false
		return
	# Une fiche est ouverte : on garde la bannière en attente, elle s\'affichera à sa fermeture
	if _document_is_open():
		toast_busy = false
		return
	toast_busy = true

	var t: Dictionary = toast_queue.pop_front()
	var accent: Color = t["accent"]
	toast_caption.text = t["caption"]
	toast_caption.add_theme_color_override("font_color", accent)
	toast_title.text = t["title"]
	toast_style.border_color = accent
	Sfx.play("stamp", -2.0)
	if int(t.get("flash", -1)) >= 0:
		_flash_segment(int(t["flash"]))

	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	toast_panel.position.y = -50.0

	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()

	toast_tween = create_tween()
	# Glisse vers le bas avec fondu
	toast_tween.tween_property(toast_panel, "position:y", 20.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.parallel().tween_property(toast_panel, "modulate:a", 1.0, 0.25)
	toast_tween.tween_interval(TOAST_HOLD)
	# Remonte vers le haut
	toast_tween.tween_property(toast_panel, "position:y", -50.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	toast_tween.parallel().tween_property(toast_panel, "modulate:a", 0.0, 0.25)
	toast_tween.tween_callback(func():
		toast_panel.visible = false
		_show_next_toast()
	)

# ---------------------------------------------------------------------------
# Bannières retenues tant qu'une fiche est ouverte
# ---------------------------------------------------------------------------

func _document_viewer() -> Node:
	return get_tree().get_first_node_in_group("document_viewer")

func _document_is_open() -> bool:
	var viewer := _document_viewer()
	return viewer != null and viewer.is_open

func _connect_viewer() -> void:
	var viewer := _document_viewer()
	if viewer and not viewer.document_closed.is_connected(_on_document_closed):
		viewer.document_closed.connect(_on_document_closed)

func _on_document_closed(_date_id: String) -> void:
	# Petit délai pour laisser le joueur retrouver le bureau avant la bannière
	await get_tree().create_timer(0.35).timeout
	if not toast_busy:
		_show_next_toast()

## Le segment de l'archive qui vient d'être classée s'illumine puis reprend sa couleur
func _flash_segment(index: int) -> void:
	if index < 0 or index >= segments.size():
		return
	segments[index].color = Color.WHITE
	create_tween().tween_property(segments[index], "color", _segment_color(index), 0.8)
