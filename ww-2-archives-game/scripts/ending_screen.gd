extends CanvasLayer
class_name EndingScreen

## Fin du jeu : après la 15e date, on affiche « FIN » puis un générique défilant.

var root: Control
var scroller: Label
var tween: Tween
var shown := false

const CREDITS := "LES ARCHIVES\n\n1939 — 1945\n\n\nVous avez classé les 15 dates qui ont fait basculer la Seconde Guerre mondiale.\n\n\nPÉRIODE 1\nLes victoires de l'Axe\n\nPÉRIODE 2\nLe tournant de la guerre\n\nPÉRIODE 3\nLa victoire des Alliés\n\n\nCODE\nThomas · Raphaël\n\nMODÈLES 3D\nLouka\n\nGAME DESIGN\nIlyem\n\n\nMerci d'avoir joué.\n\n\n« Plus jamais ça. »"

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	root = Control.new()
	UIStyle.fill_rect(root)
	add_child(root)
	var bg := ColorRect.new()
	UIStyle.fill_rect(bg)
	bg.color = Color(0.02, 0.02, 0.03, 1.0)
	root.add_child(bg)
	scroller = Label.new()
	scroller.text = CREDITS
	scroller.add_theme_font_override("font", UIStyle.font_title())
	scroller.add_theme_font_size_override("font_size", 34)
	scroller.add_theme_color_override("font_color", UIStyle.GOLD)
	scroller.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scroller.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(scroller)
	var skip := UIStyle.make_menu_button("Retour au menu")
	skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.offset_left = -260
	skip.offset_top = -80
	skip.offset_right = -30
	skip.offset_bottom = -30
	skip.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	root.add_child(skip)
	GameManager.all_dates_completed.connect(_on_all)

var _pending := false
func _on_all() -> void:
	_pending = true
	# on attend que la dernière fiche soit refermée
	for dv in get_tree().get_nodes_in_group("document_viewer"):
		if not dv.document_closed.is_connected(_on_doc_closed):
			dv.document_closed.connect(_on_doc_closed)

func _on_doc_closed(_id: String) -> void:
	if _pending and not shown:
		show_ending()

func show_ending() -> void:
	shown = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("player", "pause_control")
	var vs := get_viewport().get_visible_rect().size
	scroller.size = Vector2(vs.x * 0.7, 0)
	scroller.position = Vector2(vs.x * 0.15, vs.y)
	await get_tree().process_frame
	var h := scroller.get_minimum_size().y
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(scroller, "position:y", -h - 40.0, 48.0)
