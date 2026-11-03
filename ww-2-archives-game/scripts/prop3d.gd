extends StaticBody3D
class_name Prop3D

## Instancie un modèle .glb (Louka) et lui ajoute une collision en boîte calée sur sa taille.

@export_file("*.glb") var model_path: String = ""
@export var collide: bool = true
@export var collision_shrink: float = 0.0
## Si > 0 : hauteur max de la collision (le bureau ne doit pas englober les objets posés dessus)
@export var collision_height: float = 0.0
## Texte optionnel posé à plat sur le modèle (ex. plaque nominative du bureau), lisible depuis +Z du monde
@export var label_text: String = ""
@export var label_pos: Vector3 = Vector3.ZERO
@export var label_pixel_size: float = 0.00042
## Inclinaison du texte (degrés) : la plaque nominative est un chevalet incliné
@export var label_tilt_deg: float = 27.0

func _ready() -> void:
	if model_path == "" or get_child_count() > 0:
		return
	var scn := load(model_path) as PackedScene
	if scn == null:
		push_warning("Prop3D: modèle introuvable " + model_path)
		return
	var inst := scn.instantiate() as Node3D
	add_child(inst)
	if label_text != "":
		var l := Label3D.new()
		l.text = label_text
		l.font = UIStyle.font_title()
		l.font_size = 64
		l.pixel_size = label_pixel_size
		l.modulate = Color(0.12, 0.10, 0.08)
		l.outline_size = 0
		l.shaded = false
		l.double_sided = false
		l.top_level = true  # ignore l'échelle du bureau : le texte reste net
		inst.add_child(l)
		l.global_position = to_global(label_pos)
		var tilt := deg_to_rad(label_tilt_deg)
		# texte lisible depuis le sud (+Z monde), incliné comme la face du chevalet
		l.global_basis = Basis(Vector3(1, 0, 0), Vector3(0, sin(tilt), -cos(tilt)), Vector3(0, cos(tilt), sin(tilt)))
	if not collide:
		return
	var box := AABB()
	var first := true
	for m in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var a: AABB = mi.global_transform * mi.get_aabb() if mi.is_inside_tree() else mi.get_aabb()
		a = global_transform.affine_inverse() * a
		box = a if first else box.merge(a)
		first = false
	if first:
		return
	if collision_height > 0.0:
		box.size.y = collision_height
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = box.size - Vector3.ONE * collision_shrink
	cs.shape = bs
	cs.position = box.get_center()
	add_child(cs)
