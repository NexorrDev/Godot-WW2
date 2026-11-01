extends Interactable
class_name CorbeilleItem

## Corbeille à papier : on y fouille pour trouver le brouillon froissé (indice de la date 4).
## Sans enfant, le script fabrique un placeholder (le modèle de Louka le remplacera).

const ITEM_ID := "brouillon_rethondes"

const TEXT := "[i]Brouillon — ne pas classer[/i]\n\n" + \
	"Les plénipotentiaires français sont convoqués en forêt de Compiègne, dans la clairière de [b]Rethondes[/b]. " + \
	"Le Führer a fait sortir de son musée le [b]wagon[/b] de 1918 : l'humiliation doit être totale.\n\n" + \
	"Heure fixée pour la signature de l'armistice :\n\n[center][b][font_size=26]18h36[/font_size][/b][/center]\n\n" + \
	"[i]À reporter sur la pendule des archives (aiguilles à régler à la main).[/i]"

func _ready() -> void:
	if get_child_count() == 0:
		var cs := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.2
		shape.height = 0.4
		cs.shape = shape
		add_child(cs)
		var mi := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.19
		mesh.bottom_radius = 0.15
		mesh.height = 0.4
		mi.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.20, 0.20, 0.21)
		mat.metallic = 0.6
		mat.roughness = 0.5
		mi.material_override = mat
		add_child(mi)
		# papiers froissés qui dépassent
		for i in 3:
			var p := MeshInstance3D.new()
			var s := SphereMesh.new()
			s.radius = 0.06
			s.height = 0.1
			p.mesh = s
			var pm := StandardMaterial3D.new()
			pm.albedo_color = Color(0.86, 0.83, 0.74)
			p.material_override = pm
			p.position = Vector3(-0.07 + i * 0.07, 0.21 + (i % 2) * 0.02, 0.02 * i)
			add_child(p)
	_refresh()
	GameManager.item_obtained.connect(func(_i, _l): _refresh())
	GameManager.game_loaded.connect(_refresh)

func _refresh() -> void:
	prompt_message = "Relire : brouillon froissé" if GameManager.has_item(ITEM_ID) else "Fouiller la corbeille"

func interact() -> void:
	super.interact()
	var first := not GameManager.has_item(ITEM_ID)
	if first:
		Sfx.play("paper_open", -4.0)
		GameManager.give_item(ITEM_ID, "Brouillon froissé")
	get_tree().call_group("note_viewer", "show_note", "BROUILLON FROISSÉ", TEXT)
