extends OverlayBase

## Date 12 : 22 juin 1944, opération Bagration (offensive soviétique en Biélorussie).
## Il faut tamponner le dossier de l'armée qui a lancé l'offensive avec le tampon d'état-major.

const DATE_ID := "bagration_1944"
const FOLDERS := [
	{"t": "WEHRMACHT\nHeeresgruppe Mitte\n(Biélorussie)", "c": Color(0.35, 0.37, 0.33), "ok": false},
	{"t": "ARMÉE ROUGE\nFronts de Biélorussie\n(Opération Bagration)", "c": Color(0.62, 0.15, 0.12), "ok": true},
	{"t": "U.S. ARMY\nPremière armée\n(Normandie)", "c": Color(0.32, 0.40, 0.28), "ok": false},
]

var btns: Array[Button] = []
var stamped := -1
var stamp_fx: Label

func _init() -> void:
	super("enigma_tampon", "TAMPON D'ÉTAT-MAJOR")

func _build_content() -> void:
	vb.add_child(hint("Tampon encreur en main. Opération BAGRATION : l'offensive qui anéantit le groupe d'armées Centre en Biélorussie. Tamponne « REÇU — ARCHIVÉ » sur le dossier de l'armée qui l'a lancée."))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	for i in FOLDERS.size():
		var b := Button.new()
		b.text = FOLDERS[i]["t"]
		b.custom_minimum_size = Vector2(210, 250)
		b.add_theme_font_override("font", UIStyle.font_mono())
		b.add_theme_font_size_override("font_size", 15)
		var sb := StyleBoxFlat.new()
		sb.bg_color = FOLDERS[i]["c"]
		sb.border_color = Color(0.1, 0.08, 0.06)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(4)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.pressed.connect(func(): _stamp(i))
		row.add_child(b)
		btns.append(b)
	stamp_fx = Label.new()
	stamp_fx.text = "ARCHIVÉ"
	stamp_fx.add_theme_font_override("font", UIStyle.font_title())
	stamp_fx.add_theme_font_size_override("font_size", 40)
	stamp_fx.add_theme_color_override("font_color", Color(0.75, 0.05, 0.05, 0.9))
	stamp_fx.rotation_degrees = -14.0
	stamp_fx.visible = false
	stamp_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stamp_fx)

func _on_open() -> void:
	solved = GameManager.is_date_unlocked(DATE_ID)
	stamp_fx.visible = false
	say("Choisis le dossier à tamponner.")
	for b in btns:
		b.disabled = false

func _stamp(i: int) -> void:
	if solved:
		finish(DATE_ID)
		return
	Sfx.play("stamp", -3.0)
	stamp_fx.visible = true
	stamp_fx.global_position = btns[i].global_position + Vector2(40, 100)
	if FOLDERS[i]["ok"]:
		say("Dossier soviétique tamponné. L'Armée rouge a lancé Bagration le 22 juin 1944, trois ans jour pour jour après Barbarossa.", true)
		get_tree().create_timer(1.1).timeout.connect(func():
			if is_open:
				finish(DATE_ID))
	else:
		say("Ce n'est pas le dossier de l'armée qui attaque (Bagration est une offensive soviétique). Le tampon est effacé.")
		get_tree().create_timer(0.9).timeout.connect(func(): stamp_fx.visible = false)
