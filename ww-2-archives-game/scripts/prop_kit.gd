extends RefCounted
class_name PropKit

## Petits outils pour construire des placeholders 3D (boîtes, textes, objets interactifs) par le code.

static func box(size: Vector3, color: Color, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	m.position = pos
	m.rotation_degrees = rot_deg
	return m

static func cyl(radius: float, height: float, color: Color, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	m.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	m.position = pos
	m.rotation_degrees = rot_deg
	return m

static func label(text: String, size: int, px: float, color: Color, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = UIStyle.font_title()
	l.font_size = size
	l.pixel_size = px
	l.modulate = color
	l.shaded = false
	l.double_sided = false
	l.position = pos
	l.rotation_degrees = rot_deg
	return l

## Crée un StaticBody3D interactif avec une collision en boîte.
static func item(parent: Node, node_name: String, script_path: String, pos: Vector3, col_size: Vector3, col_offset: Vector3 = Vector3.ZERO, props: Dictionary = {}) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = node_name
	b.set_script(load(script_path))
	for k in props:
		b.set(k, props[k])
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = col_size
	cs.shape = bs
	cs.position = col_offset
	b.add_child(cs)
	b.position = pos
	parent.add_child(b)
	return b
