extends Node3D
class_name CoinPeriode3

## Dates 11 à 15 (période 3) : tableau des plages (Normandie), tampon + dossier soviétique (Bagration),
## cadre photo déchiré (Elbe), coffre-fort + note (capitulation), horloge arrêtée et table de classement (Hiroshima).
## Placeholders construits par le code, à remplacer par les modèles de Louka.

var coffre_door_pivot: Node3D
var coffre_front: StaticBody3D
var dossier_noir: StaticBody3D

func _ready() -> void:
	_build()
	PeriodGate.bind(self, 3)

func _build() -> void:
	if get_child_count() > 0:
		return
	_build_tableau_normandie()
	_build_bureau_objets()
	_build_coffre()
	_build_horloge()
	_build_table_classement()
	GameManager.date_unlocked.connect(func(_i, _d): _sync())
	GameManager.game_loaded.connect(_sync)
	GameManager.item_obtained.connect(func(_a, _b): _sync())
	_sync()

func _build_tableau_normandie() -> void:
	var board := StaticBody3D.new()
	board.name = "Tableau_Normandie"
	board.set_script(load("res://scripts/overlay_item.gd"))
	board.set("group_name", "enigma_normandie")
	board.set("call_method", "open_overlay")
	board.set("date_id", "normandie_1944")
	board.set("prompt_todo", "Examiner le tableau : 5 photos de plages")
	board.set("prompt_done", "Revoir : Débarquement de Normandie (6 Juin 1944)")
	board.position = Vector3(-3.58, 1.55, 1.8)
	board.rotation_degrees = Vector3(0, 90, 0)  # face vers +x (la pièce)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.4, 0.95, 0.08)
	cs.shape = bs
	cs.position = Vector3(0, 0, 0.03)
	board.add_child(cs)
	board.add_child(PropKit.box(Vector3(1.4, 0.95, 0.03), Color(0.30, 0.19, 0.10)))
	board.add_child(PropKit.box(Vector3(1.3, 0.85, 0.034), Color(0.62, 0.45, 0.27), Vector3(0, 0, 0.003)))
	var shots := [Vector3(-0.5, 0.2, 0), Vector3(-0.25, -0.2, 0), Vector3(0.0, 0.22, 0), Vector3(0.28, -0.18, 0), Vector3(0.5, 0.2, 0)]
	var tones := [Color(0.52, 0.52, 0.5), Color(0.45, 0.47, 0.5), Color(0.55, 0.53, 0.48), Color(0.48, 0.5, 0.47), Color(0.5, 0.5, 0.52)]
	var names := ["A", "B", "C", "D", "E"]
	for i in 5:
		var p: Vector3 = shots[i]
		board.add_child(PropKit.box(Vector3(0.2, 0.16, 0.004), Color(0.92, 0.9, 0.84), Vector3(p.x, p.y, 0.021)))
		board.add_child(PropKit.box(Vector3(0.18, 0.13, 0.005), tones[i], Vector3(p.x, p.y, 0.022)))
		board.add_child(PropKit.label(names[i], 36, 0.0016, Color(0.1, 0.1, 0.1), Vector3(p.x, p.y - 0.115, 0.025)))
		board.add_child(PropKit.box(Vector3(0.016, 0.016, 0.01), Color(0.8, 0.1, 0.1), Vector3(p.x, p.y + 0.085, 0.028)))
	# fil rouge décoratif
	board.add_child(PropKit.box(Vector3(0.6, 0.004, 0.003), Color(0.75, 0.08, 0.08), Vector3(-0.1, 0.0, 0.03), Vector3(0, 0, 14)))
	add_child(board)

func _build_bureau_objets() -> void:
	# Tampon encreur (à ramasser) sur l'angle gauche du bureau
	var tampon := PropKit.item(self, "Tampon", "res://scripts/tool_item.gd", Vector3(-0.85, 0.775, 0.85), Vector3(0.14, 0.12, 0.14), Vector3(0, 0.03, 0), {
		"tool_id": "tampon", "tool_label": "Tampon encreur d'état-major"})
	tampon.add_child(PropKit.box(Vector3(0.12, 0.02, 0.12), Color(0.1, 0.1, 0.12), Vector3(0, 0.0, 0)))
	tampon.add_child(PropKit.box(Vector3(0.09, 0.015, 0.09), Color(0.55, 0.08, 0.08), Vector3(0, 0.017, 0)))
	tampon.add_child(PropKit.box(Vector3(0.05, 0.07, 0.05), Color(0.35, 0.2, 0.1), Vector3(0, 0.06, 0)))

	# Dossier soviétique (rouge) à tamponner
	var dos := PropKit.item(self, "Dossier_Sovietique", "res://scripts/overlay_item.gd", Vector3(0.05, 0.77, 0.9), Vector3(0.3, 0.05, 0.22), Vector3.ZERO, {
		"group_name": "enigma_tampon", "call_method": "open_overlay", "date_id": "bagration_1944",
		"prompt_todo": "Tamponner un dossier d'état-major", "prompt_done": "Revoir : Opération Bagration (22 Juin 1944)",
		"need_item": "tampon", "need_message": "Des dossiers attendent d'être tamponnés… il me faut le tampon encreur d'état-major."})
	dos.rotation_degrees = Vector3(0, -12, 0)
	dos.add_child(PropKit.box(Vector3(0.30, 0.03, 0.22), Color(0.62, 0.15, 0.12)))
	dos.add_child(PropKit.box(Vector3(0.30, 0.012, 0.22), Color(0.8, 0.75, 0.6), Vector3(0, 0.018, 0)))
	dos.add_child(PropKit.label("К.А.", 30, 0.0016, Color(0.4, 0.05, 0.05), Vector3(0, 0.026, 0), Vector3(-90, 0, 0)))

	# Cadre photo face contre la table, coin du bureau
	var cadre := PropKit.item(self, "Cadre_Photo", "res://scripts/overlay_item.gd", Vector3(0.93, 0.77, 0.86), Vector3(0.22, 0.04, 0.3), Vector3.ZERO, {
		"group_name": "enigma_elbe", "call_method": "open_overlay", "date_id": "elbe_1945",
		"prompt_todo": "Retourner le cadre photo", "prompt_done": "Revoir : Jonction sur l'Elbe (26 Avril 1945)"})
	cadre.rotation_degrees = Vector3(0, 20, 0)
	cadre.add_child(PropKit.box(Vector3(0.2, 0.02, 0.28), Color(0.22, 0.14, 0.09)))
	cadre.add_child(PropKit.box(Vector3(0.012, 0.04, 0.1), Color(0.3, 0.2, 0.12), Vector3(0.0, 0.025, -0.05)))

func _build_coffre() -> void:
	var cx := 2.9
	var cz := -2.93
	var steel := Color(0.22, 0.25, 0.27)
	var safe := Node3D.new()
	safe.name = "Coffre"
	safe.position = Vector3(cx, 0, cz)
	add_child(safe)
	# caisson creux (visible à l'intérieur quand la porte est ouverte)
	safe.add_child(PropKit.box(Vector3(0.8, 0.9, 0.04), steel, Vector3(0, 0.45, -0.33)))
	safe.add_child(PropKit.box(Vector3(0.04, 0.9, 0.7), steel, Vector3(-0.38, 0.45, 0)))
	safe.add_child(PropKit.box(Vector3(0.04, 0.9, 0.7), steel, Vector3(0.38, 0.45, 0)))
	safe.add_child(PropKit.box(Vector3(0.8, 0.04, 0.7), steel, Vector3(0, 0.88, 0)))
	safe.add_child(PropKit.box(Vector3(0.8, 0.04, 0.7), steel, Vector3(0, 0.02, 0)))
	safe.add_child(PropKit.box(Vector3(0.72, 0.02, 0.6), Color(0.12, 0.12, 0.13), Vector3(0, 0.05, 0)))
	# porte pivotante (charnière à gauche, côté -x)
	coffre_door_pivot = Node3D.new()
	coffre_door_pivot.position = Vector3(-0.4, 0, 0.35)
	safe.add_child(coffre_door_pivot)
	coffre_door_pivot.add_child(PropKit.box(Vector3(0.78, 0.86, 0.05), Color(0.27, 0.3, 0.32), Vector3(0.39, 0.45, 0)))
	coffre_door_pivot.add_child(PropKit.cyl(0.09, 0.03, Color(0.7, 0.62, 0.3), Vector3(0.39, 0.5, 0.04), Vector3(90, 0, 0)))
	coffre_door_pivot.add_child(PropKit.box(Vector3(0.14, 0.02, 0.02), Color(0.7, 0.62, 0.3), Vector3(0.39, 0.5, 0.062)))
	# collision du caisson (creux : le dossier à l'intérieur reste atteignable)
	var body := StaticBody3D.new()
	for sh in [[Vector3(0.8, 0.9, 0.04), Vector3(0, 0.45, -0.33)], [Vector3(0.04, 0.9, 0.7), Vector3(-0.38, 0.45, 0)],
			[Vector3(0.04, 0.9, 0.7), Vector3(0.38, 0.45, 0)], [Vector3(0.8, 0.04, 0.7), Vector3(0, 0.88, 0)]]:
		var bcs := CollisionShape3D.new()
		var bbs := BoxShape3D.new()
		bbs.size = sh[0]
		bcs.shape = bbs
		bcs.position = sh[1]
		body.add_child(bcs)
	safe.add_child(body)
	# zone interactive sur la façade
	coffre_front = PropKit.item(safe, "Coffre_Porte", "res://scripts/overlay_item.gd", Vector3(0, 0.45, 0.4), Vector3(0.8, 0.9, 0.1), Vector3.ZERO, {
		"group_name": "enigma_digicode", "call_method": "open_code", "call_arg": "coffre", "date_id": "capitulation_1945",
		"prompt_todo": "Ouvrir le coffre-fort (code à 4 chiffres)", "prompt_done": "Consulter : Capitulation sans condition (8 Mai 1945)"})
	# Dossier noir « PROJET MANHATTAN » dans le coffre
	dossier_noir = PropKit.item(safe, "Dossier_Noir", "res://scripts/tool_item.gd", Vector3(0, 0.1, 0.0), Vector3(0.34, 0.06, 0.44), Vector3.ZERO, {
		"tool_id": "dossier_manhattan", "tool_label": "Dossier noir « PROJET MANHATTAN »"})
	dossier_noir.add_child(PropKit.box(Vector3(0.30, 0.04, 0.40), Color(0.04, 0.04, 0.05)))
	dossier_noir.add_child(PropKit.label("PROJET MANHATTAN", 36, 0.0012, Color(0.85, 0.8, 0.6), Vector3(0, 0.022, 0), Vector3(-90, 0, 0)))

	# Note punaisée au-dessus du coffre (indice du code)
	var note := PropKit.item(self, "Note_Coffre", "res://scripts/memo_item.gd", Vector3(cx, 1.45, -3.285), Vector3(0.3, 0.4, 0.06), Vector3.ZERO, {
		"memo_title": "NOTE — COFFRE DES ARCHIVES",
		"memo_text": "Code du coffre-fort :\n\n« L'année de la jonction sur l'Elbe. »\n\n(Les dates de la dernière période sont dans ton carnet.)\n\nLe coffre contient l'acte de capitulation et le dernier dossier, classé « noir ».",
		"prompt_message": "Lire la note du coffre"})
	note.add_child(PropKit.box(Vector3(0.22, 0.3, 0.008), Color(0.9, 0.87, 0.74)))

func _build_horloge() -> void:
	var clock := PropKit.item(self, "Horloge_Arretee", "res://scripts/memo_item.gd", Vector3(2.0, 2.0, -3.27), Vector3(0.5, 0.5, 0.1), Vector3.ZERO, {
		"memo_title": "HORLOGE ARRÊTÉE",
		"memo_text": "L'horloge s'est arrêtée net, aiguilles figées sur 8 h 15. Le verre est fêlé.\n\nSur le cadran, une étiquette collée de travers : « 6 août 1945 — Hiroshima ».\n\nNote cette heure.",
		"prompt_message": "Examiner l'horloge arrêtée"})
	clock.add_child(PropKit.cyl(0.24, 0.05, Color(0.2, 0.12, 0.07), Vector3.ZERO, Vector3(90, 0, 0)))
	clock.add_child(PropKit.cyl(0.21, 0.052, Color(0.92, 0.9, 0.8), Vector3(0, 0, 0.002), Vector3(90, 0, 0)))
	for i in 12:
		var a := deg_to_rad(i * 30.0)
		clock.add_child(PropKit.box(Vector3(0.012, 0.03, 0.01), Color(0.1, 0.1, 0.1), Vector3(sin(a) * 0.17, cos(a) * 0.17, 0.028), Vector3(0, 0, -i * 30.0)))
	# 8 h 15 : petite aiguille à 247,5°, grande aiguille à 90°
	for h in [[247.5, 0.12, 0.018], [90.0, 0.17, 0.011]]:
		var a2: float = deg_to_rad(h[0])
		var l: float = h[1]
		clock.add_child(PropKit.box(Vector3(h[2], l, 0.01), Color(0.08, 0.08, 0.08), Vector3(sin(a2) * l / 2.0, cos(a2) * l / 2.0, 0.032), Vector3(0, 0, -h[0])))
	clock.add_child(PropKit.cyl(0.015, 0.012, Color(0.5, 0.1, 0.1), Vector3(0, 0, 0.036), Vector3(90, 0, 0)))

func _build_table_classement() -> void:
	var t := PropKit.item(self, "Table_Classement", "res://scripts/overlay_item.gd", Vector3(0.4, 0.0, -1.7), Vector3(1.0, 0.78, 0.65), Vector3(0, 0.39, 0), {
		"group_name": "enigma_digicode", "call_method": "open_code", "call_arg": "classement", "date_id": "hiroshima_1945",
		"prompt_todo": "Classer le 15e dossier sur la table centrale", "prompt_done": "Revoir : Hiroshima et Nagasaki (Août 1945)",
		"need_item": "dossier_manhattan", "need_message": "Le 15e dossier, classé « noir », doit se trouver quelque part sous clé… peut-être dans le coffre."})
	var wood := Color(0.26, 0.17, 0.10)
	t.add_child(PropKit.box(Vector3(1.0, 0.05, 0.65), wood, Vector3(0, 0.755, 0)))
	for sx in [-0.45, 0.45]:
		for sz in [-0.28, 0.28]:
			t.add_child(PropKit.box(Vector3(0.05, 0.73, 0.05), Color(0.2, 0.13, 0.08), Vector3(sx, 0.365, sz)))
	# bac de classement vert (14 dossiers déjà classés)
	t.add_child(PropKit.box(Vector3(0.55, 0.07, 0.3), Color(0.15, 0.32, 0.2), Vector3(-0.1, 0.815, 0)))
	t.add_child(PropKit.label("CLASSEMENT", 30, 0.0015, Color(0.9, 0.88, 0.7), Vector3(-0.1, 0.852, 0), Vector3(-90, 0, 0)))
	t.add_child(PropKit.label("N°15", 36, 0.002, Color(0.85, 0.2, 0.15), Vector3(0.33, 0.783, 0.1), Vector3(-90, 0, 0)))

func _sync() -> void:
	var open14 := GameManager.is_date_unlocked("capitulation_1945")
	if coffre_door_pivot:
		coffre_door_pivot.rotation_degrees.y = -110.0 if open14 else 0.0
	if coffre_front:
		coffre_front.collision_layer = 0 if open14 else 1
	if dossier_noir:
		var show := open14 and not GameManager.has_item("dossier_manhattan")
		dossier_noir.visible = show
		dossier_noir.collision_layer = 1 if show else 0
