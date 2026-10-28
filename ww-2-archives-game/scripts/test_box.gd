extends Interactable

## Script de test pour valider l'interaction avec la touche E
## Change de couleur quand on appuie sur E !

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var is_active: bool = false
var mat_default: StandardMaterial3D
var mat_active: StandardMaterial3D

func _ready() -> void:
	# Création de deux matériaux simples pour le feedback visuel
	mat_default = StandardMaterial3D.new()
	mat_default.albedo_color = Color(0.3, 0.5, 0.7, 1.0) # Bleu
	
	mat_active = StandardMaterial3D.new()
	mat_active.albedo_color = Color(0.9, 0.75, 0.2, 1.0) # Jaune doré
	
	if mesh_instance:
		mesh_instance.material_override = mat_default
	
	interacted.connect(_on_interacted)

func _on_interacted() -> void:
	is_active = !is_active
	if mesh_instance:
		mesh_instance.material_override = mat_active if is_active else mat_default
	print("[Interaction] Objet activé ! État : ", is_active)
