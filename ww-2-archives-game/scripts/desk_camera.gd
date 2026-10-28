extends Camera3D

## Caméra immersive de bureau avec léger suivi fluide de la souris
## Donne l'impression d'être assis au bureau et d'observer la pièce.

@export var max_yaw: float = 12.0 # Degrés max vers la gauche/droite
@export var max_pitch: float = 8.0 # Degrés max vers le haut/bas
@export var smooth_speed: float = 4.0

var initial_rotation: Vector3
var target_rotation: Vector3

func _ready() -> void:
	initial_rotation = rotation_degrees
	target_rotation = initial_rotation

func _process(delta: float) -> void:
	var viewport = get_viewport()
	if not viewport:
		return
	
	# Position normalisée de la souris entre -1.0 et 1.0 par rapport au centre de l'écran
	var mouse_pos = viewport.get_mouse_position()
	var screen_size = viewport.get_visible_rect().size
	if screen_size.x == 0 or screen_size.y == 0:
		return
		
	var norm_x = (mouse_pos.x / screen_size.x - 0.5) * 2.0
	var norm_y = (mouse_pos.y / screen_size.y - 0.5) * 2.0
	
	target_rotation.y = initial_rotation.y - (norm_x * max_yaw)
	target_rotation.x = initial_rotation.x - (norm_y * max_pitch)
	
	rotation_degrees = rotation_degrees.lerp(target_rotation, smooth_speed * delta)
