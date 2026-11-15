extends Node3D
class_name CoinMachine

## Coin « machine à écrire » contre le mur est : petite table, machine à écrire,
## calendrier bloqué sur décembre 1941 (indice). Construit par le code (placeholders à remplacer par les modèles de Louka).

const NOTE := "CALENDRIER — DÉCEMBRE 1941\n\nLe calendrier est resté bloqué sur le mois de décembre. Le 7 est entouré de rouge au crayon.\n\nEn marge, une note d'un officier de renseignement :\n« Signal radio de l'attaque aérienne : TORA — « tigre » en japonais — répété trois fois. »\n\nLa machine à écrire, juste dessous, attend un mot de code de 4 lettres."

func _box(size: Vector3, color: Color, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	m.position = pos
	return m

func _label(text: String, size: int, px: float, color: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = UIStyle.font_title()
	l.font_size = size
	l.pixel_size = px
	l.modulate = color
	l.shaded = false
	l.double_sided = false
	l.position = pos
	l.rotation_degrees = rot
	return l

func _ready() -> void:
	if get_child_count() > 0:
		return
	# Petite table (le mur est est à x = +3,6 : la pièce est à -x, donc l'avant regarde -x)
	var table := StaticBody3D.new()
	table.name = "Table_Machine"
	var tcs := CollisionShape3D.new()
	var tbs := BoxShape3D.new()
	tbs.size = Vector3(0.6, 0.72, 0.95)
	tcs.shape = tbs
	tcs.position = Vector3(0, 0.36, 0)
	table.add_child(tcs)
	table.add_child(_box(Vector3(0.6, 0.05, 0.95), Color(0.25, 0.16, 0.10), Vector3(0, 0.695, 0)))
	for sx in [-0.26, 0.26]:
		for sz in [-0.42, 0.42]:
			table.add_child(_box(Vector3(0.05, 0.67, 0.05), Color(0.20, 0.12, 0.08), Vector3(sx, 0.335, sz)))
	add_child(table)

	# Machine à écrire (interactive)
	var mach := StaticBody3D.new()
	mach.name = "Machine_Ecrire"
	mach.set_script(preload("res://scripts/machine_item.gd"))
	var mcs := CollisionShape3D.new()
	var mbs := BoxShape3D.new()
	mbs.size = Vector3(0.40, 0.22, 0.38)
	mcs.shape = mbs
	mcs.position = Vector3(0, 0.11, 0)
	mach.add_child(mcs)
	var iron := Color(0.12, 0.13, 0.14)
	mach.add_child(_box(Vector3(0.36, 0.10, 0.34), iron, Vector3(0, 0.07, 0)))          # caisse
	mach.add_child(_box(Vector3(0.32, 0.12, 0.10), iron, Vector3(0.0, 0.17, 0.12)))      # arrière (rouleau)
	var keys := _box(Vector3(0.26, 0.03, 0.17), Color(0.06, 0.06, 0.07), Vector3(-0.04, 0.14, -0.03))
	keys.rotation_degrees = Vector3(0, 0, 14)
	mach.add_child(keys)
	for i in 4:
		for j in 7:
			mach.add_child(_box(Vector3(0.022, 0.012, 0.022), Color(0.85, 0.82, 0.7), Vector3(-0.09 - i * 0.003 + 0.0, 0.158 + i * 0.002, -0.10 + j * 0.032 - 0.0)))
	var paper := _box(Vector3(0.02, 0.16, 0.26), Color(0.93, 0.90, 0.78), Vector3(0.0, 0.27, 0.12))
	paper.rotation_degrees = Vector3(0, 0, -8)
	mach.add_child(paper)
	mach.position = Vector3(0, 0.72, 0)
	mach.rotation_degrees = Vector3(0, 90, 0)  # clavier tourné vers la pièce (-x)
	add_child(mach)

	# Calendrier mural (indice), bloqué sur décembre
	var cal := StaticBody3D.new()
	cal.name = "Calendrier"
	cal.set_script(preload("res://scripts/memo_item.gd"))
	cal.set("memo_title", "CALENDRIER — DÉCEMBRE 1941")
	cal.set("memo_text", NOTE)
	cal.set("prompt_message", "Examiner le calendrier (bloqué sur décembre)")
	var ccs := CollisionShape3D.new()
	var cbs := BoxShape3D.new()
	cbs.size = Vector3(0.06, 0.70, 0.52)
	ccs.shape = cbs
	cal.add_child(ccs)
	cal.add_child(_box(Vector3(0.02, 0.66, 0.48), Color(0.94, 0.92, 0.84)))
	cal.add_child(_box(Vector3(0.026, 0.14, 0.48), Color(0.62, 0.12, 0.10), Vector3(0, 0.26, 0)))
	cal.add_child(_label("DÉCEMBRE", 56, 0.0013, Color(0.97, 0.93, 0.85), Vector3(-0.0145, 0.26, 0), Vector3(0, -90, 0)))
	cal.add_child(_label("1941", 56, 0.0018, Color(0.2, 0.18, 0.15), Vector3(-0.0115, 0.13, 0), Vector3(0, -90, 0)))
	var days := ""
	for d in range(1, 32):
		days += "%2d " % d
		if d % 7 == 0:
			days += "\n"
	cal.add_child(_label(days, 30, 0.0011, Color(0.15, 0.13, 0.11), Vector3(-0.0115, -0.08, 0), Vector3(0, -90, 0)))
	cal.position = Vector3(-0.015, 1.5, 0.0)
	add_child(cal)
