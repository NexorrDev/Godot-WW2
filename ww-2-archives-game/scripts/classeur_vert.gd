extends Node3D
class_name ClasseurVert

## Meuble classeur vert à trois tiroirs (placeholder : le modèle de Louka le remplacera).
## Le tiroir du milieu est fermé par un cadenas (date 5). Un mémo est posé dessus (indice du code).
## Pour remplacer par un vrai modèle : garder un nœud "Tiroir_Milieu" avec le script
## tiroir_cadenas_item.gd, et un nœud "Memo" avec memo_item.gd.

const W := 1.0
const D := 0.5
const H := 1.35

const MEMO_TEXT := "[i]Mémo de l'état-major — classeur vert[/i]\n\n" + \
	"Le tiroir du milieu contient les ordres sur la grande offensive à l'Est. Il est fermé par un cadenas à [b]4 chiffres[/b].\n\n" + \
	"Rappel du code : l'opération porte le nom d'un [b]empereur du XIIe siècle[/b] ; le code est [b]l'année qui suit celle de l'armistice de 1940[/b]."

var drawer_front: Node3D
var padlock: Node3D
var drawer_closed_pos := Vector3.ZERO
var drawer_doc: Node3D
var use_model := false

func _ready() -> void:
	if get_child_count() > 0:
		return
	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.27, 0.48, 0.36)
	green.metallic = 0.15
	green.roughness = 0.55
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.09, 0.09, 0.09)
	dark.metallic = 0.6
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.85, 0.68, 0.25)
	gold.metallic = 0.9
	gold.roughness = 0.3
	var cream := StandardMaterial3D.new()
	cream.albedo_color = Color(0.9, 0.87, 0.76)

	# Caisson plein (collision générale)
	var body := StaticBody3D.new()
	body.name = "Caisson"
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(W, H, D)
	cs.shape = bs
	body.add_child(cs)
	body.position = Vector3(0, H / 2.0, 0)
	add_child(body)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(W, H, D)
	mi.mesh = bm
	mi.material_override = green
	body.add_child(mi)
	# Modèle de Louka : le corps procédural est caché (la collision reste)
	use_model = ModelVisual.attach(self, "classeur_corps.glb", Vector3(W, H, D), Vector3.ZERO, 180.0, "classeur_ref.glb", -1, "Modele_Corps") != null
	mi.visible = not use_model

	# Trois façades de tiroirs
	var dh := H / 3.0 - 0.04
	for i in 3:
		var y := 0.2 + i * (H / 3.0) + dh / 2.0 - 0.05
		var front := _box(Vector3(W - 0.08, dh, 0.03), green)
		front.position = Vector3(0, y, D / 2.0 + 0.012)
		add_child(front)
		front.visible = not use_model
		var handle := _box(Vector3(0.22, 0.03, 0.03), dark)
		handle.position = Vector3(0, y + 0.06, D / 2.0 + 0.04)
		handle.visible = not use_model
		add_child(handle)
		var plate := _box(Vector3(0.14, 0.05, 0.005), cream)
		plate.position = Vector3(0, y - 0.07, D / 2.0 + 0.03)
		plate.visible = not use_model
		add_child(plate)
		if i == 1:
			_make_middle_drawer(front, y, dh, gold)

	# Mémo posé sur le meuble
	var memo := StaticBody3D.new()
	memo.name = "Memo"
	memo.set_script(preload("res://scripts/memo_item.gd"))
	memo.set("memo_title", "MÉMO — CLASSEUR VERT")
	memo.set("memo_text", MEMO_TEXT)
	memo.set("prompt_message", "Lire le mémo posé sur le classeur")
	var mcs := CollisionShape3D.new()
	var mbs := BoxShape3D.new()
	mbs.size = Vector3(0.3, 0.08, 0.24)
	mcs.shape = mbs
	memo.add_child(mcs)
	var sheet := _box(Vector3(0.2, 0.004, 0.15), cream)
	memo.add_child(sheet)
	memo.position = Vector3(0.28, H + 0.01, 0.0)
	memo.rotation_degrees = Vector3(0, 14, 0)
	add_child(memo)

func _box(size: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = mat
	return m

func _make_middle_drawer(front: MeshInstance3D, y: float, dh: float, gold: Material) -> void:
	# Le tiroir interactif remplace la façade du milieu (elle glisse vers l'avant quand il s'ouvre)
	var drawer := StaticBody3D.new()
	drawer.name = "Tiroir_Milieu"
	drawer.set_script(preload("res://scripts/tiroir_cadenas_item.gd"))
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(W - 0.08, dh, 0.05)
	cs.shape = bs
	drawer.add_child(cs)
	drawer_closed_pos = Vector3(0, y, D / 2.0 + 0.04)
	drawer.position = drawer_closed_pos
	add_child(drawer)
	drawer_front = drawer
	# cadenas doré sur la poignée
	padlock = _box(Vector3(0.07, 0.09, 0.035), gold)
	padlock.position = Vector3(0.0, -0.01, 0.04)
	drawer.add_child(padlock)
	# contenu visible quand le tiroir est ouvert : un dossier
	var folder_mat := StandardMaterial3D.new()
	folder_mat.albedo_color = Color(0.75, 0.58, 0.35)
	drawer_doc = _box(Vector3(0.5, 0.03, 0.34), folder_mat)
	drawer_doc.position = Vector3(0, dh / 2.0 - 0.01, -0.22)
	drawer_doc.visible = false
	drawer.add_child(drawer_doc)
	front.visible = false  # la façade est portée par le tiroir
	var face := _box(Vector3(W - 0.08, dh, 0.03), front.material_override)
	drawer.add_child(face)
	if use_model:
		face.visible = false
		ModelVisual.attach(drawer, "classeur_tiroir.glb", Vector3(W, H, D), -drawer_closed_pos, 180.0, "classeur_ref.glb", -1, "Modele_Tiroir")
	drawer.drawer_state_changed.connect(func(): _apply_state(drawer, true))
	GameManager.game_loaded.connect(func(): _apply_state(drawer, false))
	_apply_state(drawer, false)

func _apply_state(drawer: Node3D, animate: bool) -> void:
	var open: bool = GameManager.is_date_unlocked("barbarossa_1941")
	padlock.visible = not open
	drawer_doc.visible = open
	var target := drawer_closed_pos + (Vector3(0, 0, 0.32) if open else Vector3.ZERO)
	if animate and open and not GameManager.is_loading and drawer.position.is_equal_approx(drawer_closed_pos):
		create_tween().tween_property(drawer, "position", target, 0.5).set_trans(Tween.TRANS_SINE)
	else:
		drawer.position = target
