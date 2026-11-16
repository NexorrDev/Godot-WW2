extends Node3D
class_name CoinMidway

## Date 7 (Midway) : tableau en liège au mur nord avec la photo aérienne,
## et la loupe en laiton posée sur la table de la radio. Placeholders en attendant les modèles de Louka.

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

func _ready() -> void:
	_build()
	PeriodGate.bind(self, 2)

func _build() -> void:
	if get_child_count() > 0:
		return
	# --- Tableau en liège, mur nord (z = -3,3), face vers +z ---
	var board := Node3D.new()
	board.name = "Tableau_Liege"
	board.position = Vector3(0.9, 1.55, -3.27)
	add_child(board)
	board.add_child(_box(Vector3(1.3, 0.9, 0.03), Color(0.30, 0.19, 0.10)))                 # cadre
	board.add_child(_box(Vector3(1.2, 0.8, 0.034), Color(0.62, 0.45, 0.27), Vector3(0, 0, 0.003)))  # liège
	# papiers épinglés (décor)
	board.add_child(_box(Vector3(0.22, 0.30, 0.004), Color(0.9, 0.88, 0.78), Vector3(-0.42, 0.14, 0.022)))
	board.add_child(_box(Vector3(0.26, 0.18, 0.004), Color(0.85, 0.82, 0.7), Vector3(-0.38, -0.20, 0.022)))
	board.add_child(_box(Vector3(0.2, 0.28, 0.004), Color(0.92, 0.9, 0.8), Vector3(0.48, 0.2, 0.022)))
	for pp in [Vector3(-0.42, 0.27, 0.026), Vector3(-0.38, -0.12, 0.026), Vector3(0.48, 0.32, 0.026), Vector3(0.0, 0.2, 0.026)]:
		board.add_child(_box(Vector3(0.018, 0.018, 0.012), Color(0.75, 0.1, 0.1), pp))

	# --- Photo aérienne interactive ---
	var photo := StaticBody3D.new()
	photo.name = "Photo_Midway"
	photo.set_script(preload("res://scripts/photo_midway_item.gd"))
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.50, 0.36, 0.08)
	cs.shape = bs
	photo.add_child(cs)
	photo.add_child(_box(Vector3(0.46, 0.32, 0.006), Color(0.93, 0.92, 0.88)))         # bord blanc
	photo.add_child(_box(Vector3(0.42, 0.28, 0.008), Color(0.38, 0.41, 0.44), Vector3(0, 0, 0.002)))  # mer
	for sp in [Vector3(-0.1, 0.04, 0.007), Vector3(0.06, -0.05, 0.007), Vector3(0.12, 0.08, 0.007), Vector3(-0.14, -0.08, 0.007)]:
		photo.add_child(_box(Vector3(0.018, 0.006, 0.004), Color(0.1, 0.1, 0.11), sp))
	photo.position = Vector3(0.05, 0.0, 0.045)
	board.add_child(photo)

	# --- Loupe en laiton, sur la table de la radio ---
	var loupe := StaticBody3D.new()
	loupe.name = "Loupe"
	loupe.set_script(preload("res://scripts/tool_item.gd"))
	loupe.set("tool_id", "loupe")
	loupe.set("tool_label", "Loupe en laiton")
	var lcs := CollisionShape3D.new()
	var lbs := BoxShape3D.new()
	lbs.size = Vector3(0.12, 0.05, 0.22)
	lcs.shape = lbs
	loupe.add_child(lcs)
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.78, 0.58, 0.2)
	brass.metallic = 0.8
	brass.roughness = 0.35
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.048
	tm.outer_radius = 0.062
	ring.mesh = tm
	ring.material_override = brass
	ring.position = Vector3(0, 0, -0.07)
	loupe.add_child(ring)
	var glass := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.048
	cm.bottom_radius = 0.048
	cm.height = 0.004
	glass.mesh = cm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.7, 0.85, 0.95, 0.35)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.material_override = gm
	glass.position = Vector3(0, 0, -0.07)
	loupe.add_child(glass)
	var handle := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.011
	hm.bottom_radius = 0.014
	hm.height = 0.11
	handle.mesh = hm
	handle.material_override = brass
	handle.rotation_degrees = Vector3(90, 0, 0)
	handle.position = Vector3(0, 0, 0.04)
	loupe.add_child(handle)
	loupe.position = Vector3(2.0, 0.72, 0.78)
	add_child(loupe)
