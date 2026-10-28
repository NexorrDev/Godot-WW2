extends Area3D
class_name InteractiveItem

## Script pour les objets 3D interactifs du bureau (dossiers, radio, cartes, etc.)
## Ton ami modélisateur peut ajouter ce script à n'importe quel objet 3D avec une CollisionShape3D.

@export var date_id: String = ""
@export var item_label: String = "Examiner l'élément"
@export var active_in_period: int = 1 # 1, 2, ou 3 (ou 0 pour toujours actif)

var is_hovered: bool = false
var original_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	original_scale = scale
	input_ray_pickable = true
	
	# Connexion aux événements de clic et de survol
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Écouter les changements de période pour activer/désactiver l'objet si nécessaire
	if GameManager:
		GameManager.period_changed.connect(_on_period_changed)
	
	_update_visibility_for_period()

func _on_input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_interact()

func _interact() -> void:
	if date_id.is_empty():
		print("[InteractiveItem] Aucun date_id assigné à cet objet : ", name)
		return
	
	# Déclenche l'affichage et la validation dans le GameManager
	GameManager.unlock_date(date_id)

func _on_mouse_entered() -> void:
	is_hovered = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	
	# Petit effet de zoom subtil au survol pour donner du dynamisme
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", original_scale * 1.05, 0.15)

func _on_mouse_exited() -> void:
	is_hovered = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", original_scale, 0.15)

func _on_period_changed(_new_period: int) -> void:
	_update_visibility_for_period()

func _update_visibility_for_period() -> void:
	# Si active_in_period vaut 0, l'objet est disponible tout le temps
	if active_in_period == 0:
		visible = true
		monitoring = true
		monitorable = true
		return
	
	# L'objet apparaît à sa période
	var is_active = (GameManager.current_period >= active_in_period)
	visible = is_active
	monitoring = is_active
	monitorable = is_active
