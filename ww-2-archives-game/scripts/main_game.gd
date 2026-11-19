extends Node3D

## Contrôleur de la scène principale
## Connecte le menu principal, le joueur et le HUD de progression.

@onready var main_menu: CanvasLayer = $MainMenu
@onready var joueur: CharacterBody3D = $Joueur
@onready var hud: CanvasLayer = $HUDProgression

func _ready() -> void:
	# Démarre les sons (ambiance de bureau, clics de boutons...)
	Sfx.ensure()
	Music.ensure()
	_apply_louka_models()
	if main_menu:
		main_menu.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	if joueur:
		joueur.start_game()
	# nouvelle partie : carte de titre de la période 1 (fondu depuis le noir)
	if GameManager.unlocked_dates.is_empty() and has_node("PeriodTransition"):
		$PeriodTransition.intro()
	if hud and hud.has_method("show_hud"):
		hud.show_hud()


## Modèles 3D de Louka (visuel seul). Le bureau devient un StaticBody3D à boîte de collision identique
## à l'ancien CSG ; le poste de radio garde sa collision et son script, seul son maillage change.
func _apply_louka_models() -> void:
	var old := get_node_or_null("Bureau_Placeholder")
	if old is CSGBox3D:
		var pos: Vector3 = old.position
		var size: Vector3 = old.size
		var body := StaticBody3D.new()
		body.name = "Bureau"
		body.position = pos
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		body.add_child(cs)
		add_child(body)
		if ModelVisual.attach(body, "bureau.glb", Vector3(size.x, size.y, size.z), Vector3(0, -size.y / 2.0, 0), 90.0, "", -1, "Modele3D") != null:
			old.queue_free()
		else:
			body.queue_free()
	# Ciseaux de Louka à la place du coupe-papier (même objet pour le jeu : tool_id "coupe_papier")
	var cp := get_node_or_null("CoupePapier")
	if cp:
		var cm := cp.get_node_or_null("MeshInstance3D")
		if cm and ModelVisual.attach(cp, "res://assets/models/louka3/ciseaux.glb", Vector3(0.2, 0.2, 0.2), Vector3(0, -0.006, 0), 0.0, "", 2, "Modele3D") != null:
			cm.visible = false
	var radio := get_node_or_null("Poste_Radio")
	if radio:
		var mesh := radio.get_node_or_null("MeshInstance3D")
		if mesh and ModelVisual.attach(radio, "radio.glb", Vector3(0.5, 0.35, 0.28), Vector3(0, -0.175, 0), 0.0, "", -1, "Modele3D") != null:
			mesh.visible = false
