extends Node3D
class_name CoinPeriode2

## Dates 8, 9 et 10 (période 2) : boussole + ordre de mission (El-Alamein), veste au portemanteau
## (Stalingrad), boîte « Méditerranée » en haut de l'étagère + chaise (Sicile). Placeholders pour Louka.

func _ready() -> void:
	_build()
	PeriodGate.bind(self, 2)

func _build() -> void:
	if get_child_count() > 0:
		return
	_build_boussole()
	_build_veste()
	_build_etagere()

func _build_boussole() -> void:
	var stool := StaticBody3D.new()
	stool.name = "Tabouret_Boussole"
	stool.position = Vector3(3.3, 0, -0.55)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.45, 0.6, 0.45)
	cs.shape = bs
	cs.position = Vector3(0, 0.3, 0)
	stool.add_child(cs)
	stool.add_child(PropKit.box(Vector3(0.45, 0.04, 0.45), Color(0.27, 0.18, 0.11), Vector3(0, 0.58, 0)))
	for sx in [-0.18, 0.18]:
		for sz in [-0.18, 0.18]:
			stool.add_child(PropKit.box(Vector3(0.04, 0.56, 0.04), Color(0.2, 0.13, 0.08), Vector3(sx, 0.28, sz)))
	add_child(stool)

	var boussole := PropKit.item(self, "Boussole", "res://scripts/overlay_item.gd", Vector3(3.3, 0.62, -0.55), Vector3(0.22, 0.08, 0.22), Vector3(0, 0.03, 0), {
		"group_name": "enigma_boussole", "call_method": "open_overlay", "date_id": "el_alamein_1942",
		"prompt_todo": "Régler la boussole militaire", "prompt_done": "Revoir : El-Alamein (Oct.-Nov. 1942)"})
	var brass := Color(0.55, 0.45, 0.2)
	boussole.add_child(PropKit.box(Vector3(0.18, 0.04, 0.18), Color(0.20, 0.22, 0.14)))
	boussole.add_child(PropKit.cyl(0.075, 0.03, brass, Vector3(0, 0.035, 0)))
	boussole.add_child(PropKit.cyl(0.062, 0.032, Color(0.9, 0.88, 0.78), Vector3(0, 0.038, 0)))
	boussole.add_child(PropKit.box(Vector3(0.008, 0.006, 0.10), Color(0.75, 0.1, 0.1), Vector3(0, 0.058, 0), Vector3(0, 40, 0)))

	# Ordre de mission punaisé sur le mur est
	var ordre := PropKit.item(self, "Ordre_Mission", "res://scripts/memo_item.gd", Vector3(3.585, 1.45, -0.55), Vector3(0.06, 0.38, 0.28), Vector3.ZERO, {
		"memo_title": "ORDRE DE MISSION — DÉSERT",
		"memo_text": "OCTOBRE 1942 — FRONT D'AFRIQUE DU NORD\n\nL'Afrika Korps de Rommel est arrêté devant El-Alamein par la 8e armée de Montgomery.\n\nORDRE : « Cap au SUD-EST, vers le canal de Suez. »\n\nRégler la boussole en conséquence et la comparer à la carte d'Afrique du Nord.",
		"prompt_message": "Lire l'ordre de mission"})
	ordre.add_child(PropKit.box(Vector3(0.012, 0.34, 0.24), Color(0.9, 0.87, 0.74)))
	ordre.add_child(PropKit.label("ORDRE", 40, 0.0016, Color(0.4, 0.05, 0.05), Vector3(-0.009, 0.1, 0), Vector3(0, -90, 0)))
	ordre.add_child(PropKit.label("CAP : SE", 36, 0.0016, Color(0.15, 0.12, 0.1), Vector3(-0.009, 0.0, 0), Vector3(0, -90, 0)))

func _build_veste() -> void:
	# Portemanteau contre le mur ouest, à gauche (côté sud) de la porte des archives
	var stand := Node3D.new()
	stand.name = "Portemanteau"
	stand.position = Vector3(-3.3, 0, -2.45)
	add_child(stand)
	stand.add_child(PropKit.cyl(0.22, 0.04, Color(0.16, 0.1, 0.06), Vector3(0, 0.02, 0)))
	stand.add_child(PropKit.cyl(0.025, 1.75, Color(0.2, 0.12, 0.07), Vector3(0, 0.9, 0)))
	for a in [0, 90, 180, 270]:
		stand.add_child(PropKit.box(Vector3(0.18, 0.02, 0.02), Color(0.2, 0.12, 0.07), Vector3(0, 1.78, 0), Vector3(0, a, 0)))
	var veste := PropKit.item(stand, "Veste", "res://scripts/overlay_item.gd", Vector3(0.16, 1.25, 0), Vector3(0.22, 0.75, 0.55), Vector3.ZERO, {
		"group_name": "enigma_veste", "call_method": "open_overlay", "date_id": "stalingrad_1943",
		"prompt_todo": "Fouiller la veste militaire", "prompt_done": "Relire : Stalingrad (2 Février 1943)"})
	var cloth := Color(0.36, 0.38, 0.30)
	veste.add_child(PropKit.box(Vector3(0.12, 0.70, 0.46), cloth))
	veste.add_child(PropKit.box(Vector3(0.12, 0.32, 0.14), cloth, Vector3(0, 0.12, 0.30), Vector3(18, 0, 0)))
	veste.add_child(PropKit.box(Vector3(0.12, 0.32, 0.14), cloth, Vector3(0, 0.12, -0.30), Vector3(-18, 0, 0)))
	veste.add_child(PropKit.box(Vector3(0.016, 0.1, 0.12), Color(0.28, 0.3, 0.23), Vector3(0.07, 0.12, 0.13)))
	veste.add_child(PropKit.box(Vector3(0.016, 0.1, 0.12), Color(0.28, 0.3, 0.23), Vector3(0.07, -0.18, -0.12)))

func _build_etagere() -> void:
	# Étagère de Louka (meuble à livres) : 1,52 x 1,90 x 0,80 m contre le mur nord. Collision = boîte simple.
	var sh := StaticBody3D.new()
	sh.name = "Etagere_Haute"
	sh.position = Vector3(-0.65, 0, -3.03)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.5, 1.9, 0.45)
	cs.shape = bs
	cs.position = Vector3(0, 0.95, 0)
	sh.add_child(cs)
	add_child(sh)
	if ModelVisual.attach(sh, "res://assets/models/louka3/bibliotheque.glb", Vector3(1.5, 1.9, 0.45), Vector3.ZERO, -90.0, "", -1, "Modele3D") == null:
		# secours : planches simples si le modèle manque
		sh.add_child(PropKit.box(Vector3(1.5, 1.9, 0.45), Color(0.30, 0.20, 0.12), Vector3(0, 0.95, 0)))

	var boite := PropKit.item(self, "Boite_Mediterranee", "res://scripts/boite_item.gd", Vector3(-0.65, 2.05, -3.03), Vector3(0.5, 0.30, 0.30), Vector3.ZERO)
	boite.add_child(PropKit.box(Vector3(0.46, 0.28, 0.28), Color(0.62, 0.55, 0.38)))
	boite.add_child(PropKit.box(Vector3(0.40, 0.12, 0.012), Color(0.9, 0.88, 0.8), Vector3(0, 0.0, 0.146)))
	boite.add_child(PropKit.label("MÉDITERRANÉE", 40, 0.0015, Color(0.15, 0.1, 0.08), Vector3(0, 0.0, 0.153)))

	# Chaise de Louka : on la fait glisser vers l'étagère
	var ch := PropKit.item(self, "Chaise_Etagere", "res://scripts/chaise_item.gd", Vector3(-0.65, 0, -1.9), Vector3(0.6, 0.9, 0.6), Vector3(0, 0.45, 0), {"start_z": -1.9, "pushed_z": -2.45})
	if ModelVisual.attach(ch, "chaise.glb", Vector3(0, 0.95, 0), Vector3.ZERO, 0.0, "", 1, "Modele3D") == null:
		var wood2 := Color(0.34, 0.22, 0.13)
		ch.add_child(PropKit.box(Vector3(0.44, 0.04, 0.44), wood2, Vector3(0, 0.45, 0)))
		ch.add_child(PropKit.box(Vector3(0.44, 0.40, 0.04), wood2, Vector3(0, 0.67, 0.2)))
		for sx in [-0.19, 0.19]:
			for sz in [-0.19, 0.19]:
				ch.add_child(PropKit.box(Vector3(0.04, 0.44, 0.04), wood2, Vector3(sx, 0.22, sz)))
