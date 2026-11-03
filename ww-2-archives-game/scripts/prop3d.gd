extends StaticBody3D
class_name Prop3D

## Instancie un modèle .glb (Louka) et lui ajoute une collision en boîte calée sur sa taille.

@export_file("*.glb") var model_path: String = ""
@export var collide: bool = true
@export var collision_shrink: float = 0.0

func _ready() -> void:
	if model_path == "" or get_child_count() > 0:
		return
	var scn := load(model_path) as PackedScene
	if scn == null:
		push_warning("Prop3D: modèle introuvable " + model_path)
		return
	var inst := scn.instantiate() as Node3D
	add_child(inst)
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
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = box.size - Vector3.ONE * collision_shrink
	cs.shape = bs
	cs.position = box.get_center()
	add_child(cs)
