extends Interactable
class_name PenduleItem

## Pendule murale au-dessus de la porte des archives (date 4 : armistice du 22 juin 1940).
## Sans enfant, le script fabrique un placeholder (cadran + socle + compartiment secret).
## Le modèle de Louka peut le remplacer : garder ce script et un enfant nommé "Compartiment".

const DATE_ID := "armistice_1940"

var compartment: Node3D

func _ready() -> void:
	if get_child_count() == 0:
		_build_placeholder()
	compartment = get_node_or_null("Compartiment")
	_refresh()
	GameManager.date_unlocked.connect(func(_i, _d): _refresh())
	GameManager.game_loaded.connect(_refresh)

func _build_placeholder() -> void:
	# les axes : le cadran regarde vers +x (la pièce), le mur ouest est à gauche
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.2, 0.62, 0.52)
	cs.shape = shape
	add_child(cs)

	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.22, 0.14, 0.09)
	var cream := StandardMaterial3D.new()
	cream.albedo_color = Color(0.90, 0.87, 0.76)
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(0.06, 0.05, 0.05)

	var rim := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.27; rm.bottom_radius = 0.27; rm.height = 0.06
	rim.mesh = rm; rim.material_override = wood
	rim.rotation_degrees = Vector3(0, 0, 90)
	add_child(rim)
	var face := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.235; fm.bottom_radius = 0.235; fm.height = 0.02
	face.mesh = fm; face.material_override = cream
	face.rotation_degrees = Vector3(0, 0, 90)
	face.position = Vector3(0.035, 0, 0)
	add_child(face)
	# graduations
	for i in 12:
		var a := deg_to_rad(i * 30.0)
		var t := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(0.006, 0.03 if i % 3 == 0 else 0.018, 0.012)
		t.mesh = tm; t.material_override = black
		t.position = Vector3(0.047, cos(a) * 0.20, sin(a) * 0.20)
		t.rotation = Vector3(a, 0, 0)
		add_child(t)
	# aiguilles (position décorative : 10h10)
	for h in [[0.15, 305.0, 0.014], [0.20, 60.0, 0.009]]:
		var a := deg_to_rad(h[1])
		var hand := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(0.006, h[0], h[2])
		hand.mesh = hm; hand.material_override = black
		hand.position = Vector3(0.052, cos(a) * h[0] / 2.0, sin(a) * h[0] / 2.0)
		hand.rotation = Vector3(a, 0, 0)
		add_child(hand)
	# socle sous la pendule
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.16, 0.07, 0.46)
	base.mesh = bm; base.material_override = wood
	base.position = Vector3(0.06, -0.33, 0)
	add_child(base)
	# compartiment secret (apparaît quand l'acte est trouvé)
	var comp := Node3D.new()
	comp.name = "Compartiment"
	var cm := MeshInstance3D.new()
	var cmm := BoxMesh.new()
	cmm.size = Vector3(0.14, 0.05, 0.3)
	cm.mesh = cmm; cm.material_override = wood
	comp.add_child(cm)
	var doc := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.1, 0.012, 0.24)
	doc.mesh = dm; doc.material_override = cream
	doc.position = Vector3(0, 0.03, 0)
	comp.add_child(doc)
	comp.position = Vector3(0.06, -0.33, 0)
	comp.visible = false
	add_child(comp)

func _solved() -> bool:
	return GameManager.is_date_unlocked(DATE_ID)

func _refresh() -> void:
	if _solved():
		prompt_message = "Consulter : Acte d'armistice (22 Juin 1940)"
	else:
		prompt_message = "Régler la pendule"
	if compartment:
		var was_visible := compartment.visible
		compartment.visible = _solved()
		if _solved() and not was_visible and not GameManager.is_loading:
			# le tiroir sort du socle
			var end := compartment.position
			compartment.position = end + Vector3(-0.0, 0.0, 0.0)
			var tw := create_tween()
			compartment.position = end + Vector3(0, 0, 0)
			tw.tween_property(compartment, "position:x", end.x + 0.16, 0.5).from(end.x)

func interact() -> void:
	super.interact()
	if _solved():
		get_tree().call_group("document_viewer", "open_document", DATE_ID)
	else:
		get_tree().call_group("enigma_pendule", "open_clock")
