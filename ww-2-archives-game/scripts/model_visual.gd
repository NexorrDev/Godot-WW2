extends RefCounted
class_name ModelVisual

## Ajoute un modèle 3D (.glb de Louka) comme décor VISUEL d'un meuble existant.
## Aucune collision n'est créée : les collisions et les objets interactifs d'origine ne changent pas.
## Le modèle est calé (mise à l'échelle + position) sur la boîte du meuble qu'il remplace.

const DIR := "res://assets/models/louka2/"

## Boîte englobante d'un modèle (dans le repère du modèle).
static func model_aabb(path: String) -> AABB:
	var scn := load(path) as PackedScene
	if scn == null:
		return AABB()
	var inst := scn.instantiate() as Node3D
	var box := _collect_aabb(inst, inst)
	inst.free()
	return box

static func _collect_aabb(root: Node3D, node: Node) -> AABB:
	var box := AABB()
	var first := true
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var t := Transform3D.IDENTITY
		var n: Node = mi
		while n != null and n != root:
			t = (n as Node3D).transform * t
			n = n.get_parent()
		var a: AABB = t * mi.get_aabb()
		box = a if first else box.merge(a)
		first = false
	return box

## fit : taille finale (repère du parent) ; pos : centre-bas du modèle dans le repère du parent ;
## yaw_deg : rotation autour de Y (multiple de 90) ; ref : modèle servant de référence pour la mise à l'échelle
## (permet de caler plusieurs pièces d'un même meuble de la même façon) ;
## uniform_axis : 0/1/2 = mise à l'échelle uniforme sur cet axe (x, y, z du repère du parent), -1 = chaque axe séparément.
static func attach(parent: Node3D, file: String, fit: Vector3, pos: Vector3 = Vector3.ZERO, yaw_deg: float = 0.0, ref: String = "", uniform_axis: int = -1, node_name: String = "Modele3D") -> Node3D:
	var path := DIR + file
	var scn := load(path) as PackedScene
	if scn == null:
		push_warning("ModelVisual : modèle introuvable " + path)
		return null
	var box := model_aabb(DIR + ref) if ref != "" else model_aabb(path)
	if box.size.x <= 0.0001:
		return null
	var swap := int(round(absf(yaw_deg) / 90.0)) % 2 == 1
	# taille du modèle dans le repère du parent (après rotation)
	var size_p := Vector3(box.size.z, box.size.y, box.size.x) if swap else box.size
	var sp := Vector3(fit.x / size_p.x, fit.y / size_p.y, fit.z / size_p.z)
	if uniform_axis >= 0:
		var u: float = sp[uniform_axis]
		sp = Vector3(u, u, u)
	# échelle dans le repère du modèle
	var sm := Vector3(sp.z, sp.y, sp.x) if swap else sp
	var holder := Node3D.new()
	holder.name = node_name
	holder.position = pos
	holder.rotation_degrees.y = yaw_deg
	var inst := scn.instantiate() as Node3D
	inst.scale = sm
	var c := box.get_center()
	inst.position = Vector3(-c.x * sm.x, -box.position.y * sm.y, -c.z * sm.z)
	holder.add_child(inst)
	parent.add_child(holder)
	return holder
