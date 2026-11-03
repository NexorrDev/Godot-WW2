extends Node3D
class_name ClasseurVert

## Meuble classeur vert à trois tiroirs (placeholder : le modèle de Louka le remplacera).
## Le tiroir du milieu est fermé par un cadenas (date 5). Un mémo est posé dessus (indice du code).
## Pour remplacer par un vrai modèle : garder un nœud "Tiroir_Milieu" avec le script
## tiroir_cadenas_item.gd, et un nœud "Memo" avec memo_item.gd.

const MODEL_BODY := "res://assets/models/louka/meuble_tiroirs.glb"
const MODEL_DRAWER := "res://assets/models/louka/meuble_tiroir_ouvert.glb"
const SLIDE := 0.26  # profondeur dont le tiroir ressort quand il est ouvert

const MEMO_TEXT := "[i]Mémo de l'état-major — classeur vert[/i]\n\n" + \
	"Le tiroir du milieu contient les ordres sur la grande offensive à l'Est. Il est fermé par un cadenas à [b]4 chiffres[/b].\n\n" + \
	"Rappel du code : l'opération porte le nom d'un [b]empereur du XIIe siècle[/b] ; le code est [b]l'année qui suit celle de l'armistice de 1940[/b]."

var drawer_front: Node3D
var padlock: Node3D
var drawer_closed_pos := Vector3.ZERO
var drawer_doc: Node3D

func _ready() -> void:
	if get_child_count() > 0:
		return
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.85, 0.68, 0.25)
	gold.metallic = 0.9
	gold.roughness = 0.3

	# Caisson du meuble (modèle de Louka) + collision
	var body := Prop3D.new()
	body.name = "Caisson"
	body.model_path = MODEL_BODY
	add_child(body)

	# Mémo punaisé au mur, au-dessus du meuble (le meuble est adossé au mur nord)
	var memo := StaticBody3D.new()
	memo.name = "Memo"
	memo.set_script(preload("res://scripts/memo_item.gd"))
	memo.set("memo_title", "MÉMO — CLASSEUR VERT")
	memo.set("memo_text", MEMO_TEXT)
	memo.set("prompt_message", "Lire le mémo punaisé au-dessus du classeur")
	var mcs := CollisionShape3D.new()
	var mbs := BoxShape3D.new()
	mbs.size = Vector3(0.3, 0.4, 0.1)
	mcs.shape = mbs
	memo.add_child(mcs)
	var cream := StandardMaterial3D.new()
	cream.albedo_color = Color(0.9, 0.87, 0.76)
	var sheet := _box(Vector3(0.22, 0.3, 0.004), cream)
	memo.add_child(sheet)
	memo.position = Vector3(0.0, 2.1, -0.405)
	add_child(memo)

	# Tiroir du milieu interactif
	var drawer := StaticBody3D.new()
	drawer.name = "Tiroir_Milieu"
	drawer.set_script(preload("res://scripts/tiroir_cadenas_item.gd"))
	var inst := (load(MODEL_DRAWER) as PackedScene).instantiate()
	drawer.add_child(inst)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.48, 0.48, 0.52)
	cs.shape = bs
	cs.position = Vector3(0, 0.77, 0.153)
	drawer.add_child(cs)
	drawer_closed_pos = Vector3(0, 0, -SLIDE)
	drawer.position = drawer_closed_pos
	add_child(drawer)
	drawer_front = drawer
	# cadenas doré sur la façade du tiroir
	padlock = _box(Vector3(0.05, 0.07, 0.03), gold)
	padlock.position = Vector3(0, 0.74, 0.43)
	drawer.add_child(padlock)
	drawer_doc = Node3D.new()
	drawer.add_child(drawer_doc)
	var folder_mat := StandardMaterial3D.new()
	folder_mat.albedo_color = Color(0.75, 0.58, 0.35)
	var folder := _box(Vector3(0.34, 0.03, 0.3), folder_mat)
	folder.position = Vector3(0, 0.6, 0.15)
	drawer_doc.add_child(folder)
	drawer_doc.visible = false
	drawer.drawer_state_changed.connect(func(): _apply_state(drawer, true))
	GameManager.game_loaded.connect(func(): _apply_state(drawer, false))
	_apply_state(drawer, false)

func _box(size: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = mat
	return m

func _apply_state(drawer: Node3D, animate: bool) -> void:
	var open: bool = GameManager.is_date_unlocked("barbarossa_1941")
	padlock.visible = not open
	drawer_doc.visible = open
	var target := Vector3(0, 0, 0) + (Vector3.ZERO if open else Vector3(0, 0, -SLIDE))
	if animate and open and not GameManager.is_loading and drawer.position.is_equal_approx(drawer_closed_pos):
		create_tween().tween_property(drawer, "position", target, 0.5).set_trans(Tween.TRANS_SINE)
	else:
		drawer.position = target
