extends OverlayBase

## Codes à 4 chiffres, deux configurations :
##  - "coffre"     : coffre-fort des archives, code 1945 (date 14 : capitulation du 8 mai 1945)
##  - "classement" : table centrale, heure de Hiroshima 08:15 (date 15) ; il faut le dossier noir

const CONFIGS := {
	"coffre": {
		"date": "capitulation_1945", "code": [1, 9, 4, 5], "title": "COFFRE-FORT DES ARCHIVES",
		"hint": "Serrure à 4 chiffres. La note punaisée au mur dit : « Code = l'année de la jonction sur l'Elbe. »",
		"ok": "Le coffre s'ouvre dans un lourd cliquetis. L'acte de capitulation est à l'intérieur.", "btn": "Ouvrir le coffre",
	},
	"classement": {
		"date": "hiroshima_1945", "code": [0, 8, 1, 5], "title": "FICHE DE CLASSEMENT — DOSSIER N°15",
		"hint": "Dossier noir « PROJET MANHATTAN ». Pour le classer, inscris l'heure de l'explosion d'Hiroshima (HH MM) : celle de l'horloge arrêtée au mur.",
		"ok": "Fiche validée. Le 15e dossier est classé : la guerre prend fin.", "btn": "Classer le dossier",
	},
}

var cfg_key := "coffre"
var digits := [0, 0, 0, 0]
var labels: Array[Label] = []
var hint_lbl: Label
var title_lbl: Label
var ok_btn: Button

func _init() -> void:
	super("enigma_digicode", "SERRURE")

func _build_content() -> void:
	title_lbl = vb.get_child(0) as Label
	hint_lbl = hint("")
	vb.add_child(hint_lbl)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	vb.add_child(row)
	for i in 4:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		var up := Button.new()
		up.text = "▲"
		up.custom_minimum_size = Vector2(84, 34)
		up.pressed.connect(func(): _turn(i, 1))
		col.add_child(up)
		var box := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.14, 0.12)
		sb.border_color = Color(0.5, 0.55, 0.45)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(6)
		box.add_theme_stylebox_override("panel", sb)
		box.custom_minimum_size = Vector2(84, 110)
		box.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed:
				if e.button_index == MOUSE_BUTTON_WHEEL_UP:
					_turn(i, 1)
				elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					_turn(i, -1))
		var lab := Label.new()
		lab.text = "0"
		lab.add_theme_font_override("font", UIStyle.font_mono())
		lab.add_theme_font_size_override("font_size", 70)
		lab.add_theme_color_override("font_color", Color(0.4, 1.0, 0.45))
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(lab)
		labels.append(lab)
		col.add_child(box)
		var dn := Button.new()
		dn.text = "▼"
		dn.custom_minimum_size = Vector2(84, 34)
		dn.pressed.connect(func(): _turn(i, -1))
		col.add_child(dn)
		row.add_child(col)

func _build_buttons(row: HBoxContainer) -> void:
	ok_btn = UIStyle.make_menu_button("Valider")
	ok_btn.pressed.connect(_validate)
	row.add_child(ok_btn)

func _e_closes() -> bool:
	return true

func open_code(key: String) -> void:
	cfg_key = key
	var cfg: Dictionary = CONFIGS[key]
	title_lbl.text = cfg["title"]
	hint_lbl.text = cfg["hint"]
	ok_btn.text = cfg["btn"]
	digits = [0, 0, 0, 0]
	for l in labels:
		l.text = "0"
	solved = false
	say("")
	open_overlay()

func _turn(i: int, dir: int) -> void:
	digits[i] = (digits[i] + dir + 10) % 10
	labels[i].text = str(digits[i])
	Sfx.play("click", -7.0, 0.1)

func _validate() -> void:
	var cfg: Dictionary = CONFIGS[cfg_key]
	if digits == cfg["code"]:
		say(cfg["ok"], true)
		solved = true
		get_tree().create_timer(1.0).timeout.connect(func():
			if is_open:
				finish(cfg["date"]))
	else:
		Sfx.play("click", -3.0, 0.3)
		say("Mauvaise combinaison.")
