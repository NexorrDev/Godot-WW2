extends CharacterBody3D

## Contrôleur de déplacement à la première personne (FPS)
## Déplacement au clavier (ZQSD / WASD / Flèches), vue à la souris, balancement et interaction [E].

@export var can_control: bool = false # Devient true quand on clique sur "Nouvelle partie"
@export var speed: float = 3.5
@export var mouse_sensitivity: float = 0.0025
@export var gravity: float = 9.8

var base_mouse_sensitivity: float = 0.0025
var head_bob_enabled: bool = true

# Paramètres du balancement de marche (Head Bobbing)
@export var bob_frequency: float = 2.6
@export var bob_vertical_amp: float = 0.065
@export var bob_horizontal_amp: float = 0.035

@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay
@onready var prompt_label: Label = $UI/PromptLabel
@onready var crosshair: ColorRect = $UI/Crosshair

var default_cam_pos: Vector3
var bob_timer: float = 0.0
var step_distance: float = 1.0 # Distance parcourue depuis le dernier bruit de pas
var current_interactable: Interactable = null

func _ready() -> void:
	add_to_group("player")
	default_cam_pos = camera.transform.origin
	if prompt_label:
		prompt_label.visible = false
	if crosshair:
		crosshair.visible = can_control

func start_game() -> void:
	resume_control()

func pause_control() -> void:
	can_control = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if crosshair:
		crosshair.visible = false
	if prompt_label:
		prompt_label.visible = false

func resume_control() -> void:
	can_control = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if crosshair:
		crosshair.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not can_control:
		return
		
	# Clic pour capturer la souris
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	# Échap pour libérer la souris
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Interaction avec la touche E
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		if current_interactable:
			current_interactable.interact()

	# Rotation de la vue avec la souris
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

func _physics_process(delta: float) -> void:
	if not can_control:
		return
		
	# Gravité
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Lecture des touches de déplacement
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0

	input_dir = input_dir.normalized()
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# Bruits de pas (indépendants du balancement de marche)
	var walk_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and walk_speed > 0.5:
		step_distance += walk_speed * delta
		if step_distance >= 1.4:
			step_distance = 0.0
			Sfx.play("step", -8.0, 0.04)
	else:
		step_distance = 1.0

	# Balancement de marche
	_handle_head_bob(delta, input_dir)
	
	# Détection des objets interactifs devant la caméra
	_handle_interaction()

func _handle_head_bob(delta: float, input_dir: Vector2) -> void:
	if not head_bob_enabled:
		camera.transform.origin = camera.transform.origin.lerp(default_cam_pos, delta * 8.0)
		camera.rotation.z = lerp_angle(camera.rotation.z, 0.0, delta * 8.0)
		return

	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	if is_on_floor() and horizontal_speed > 0.1:
		bob_timer += delta * horizontal_speed
		
		var target_pos = default_cam_pos
		target_pos.y += sin(bob_timer * bob_frequency * 2.0) * bob_vertical_amp
		target_pos.x += cos(bob_timer * bob_frequency) * bob_horizontal_amp
		
		camera.transform.origin = camera.transform.origin.lerp(target_pos, delta * 12.0)
		
		var target_tilt = -input_dir.x * deg_to_rad(1.5)
		camera.rotation.z = lerp_angle(camera.rotation.z, target_tilt, delta * 8.0)
	else:
		bob_timer = 0.0
		camera.transform.origin = camera.transform.origin.lerp(default_cam_pos, delta * 8.0)
		camera.rotation.z = lerp_angle(camera.rotation.z, 0.0, delta * 8.0)

func set_mouse_sensitivity_multiplier(multiplier: float) -> void:
	mouse_sensitivity = base_mouse_sensitivity * multiplier

func set_fov(new_fov: float) -> void:
	if camera:
		camera.fov = new_fov

func set_head_bob_enabled(enabled: bool) -> void:
	head_bob_enabled = enabled
	if not enabled and camera:
		camera.transform.origin = default_cam_pos
		camera.rotation.z = 0.0

func _handle_interaction() -> void:
	if not interaction_ray:
		return
		
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider is Interactable:
			current_interactable = collider
			if prompt_label:
				prompt_label.text = "[E] " + current_interactable.prompt_message
				prompt_label.visible = true
			if crosshair:
				crosshair.color = Color(1.0, 0.9, 0.3, 0.9)
			return

	current_interactable = null
	if prompt_label:
		prompt_label.visible = false
	if crosshair:
		crosshair.color = Color(1.0, 1.0, 1.0, 0.7)
