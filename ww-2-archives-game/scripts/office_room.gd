extends Node3D
class_name OfficeRoom

## Salle du bureau d'archives (construite par code, sans mobilier ni objets d'interaction :
## ceux-ci sont faits à part et se posent dans la scène principale).
##
## Contenu : sol carrelé, murs en plâtre, plafond à dalles, porte des archives (mur ouest),
## fenêtre à store (mur est) avec vue sur la ville, plinthes,
## éclairage et ambiance qui changent avec la période (matin / midi-après-midi / soir).
##
## Repère : x vers l'est, z vers le sud. La pièce fait 7,2 m (x) sur 6,6 m (z), 3 m sous plafond.
## Le fond de la pièce (étagères, classeurs verts, tableau en liège) est le mur nord (z = -3,3).
## Tout se règle avec les constantes ci-dessous.

const HALF_W: float = 3.6
const HALF_D: float = 3.3
const H: float = 3.0
const T: float = 0.25                # épaisseur des murs

# Porte des archives (mur ouest, verrouillée jusqu'à la date 14)
const ARCH_DOOR_Z: float = -1.1
const ARCH_DOOR_W: float = 1.0
const DOOR_H: float = 2.1
# Fenêtre (mur est)
const WIN_Z: float = -2.3
const WIN_W: float = 1.5
const WIN_Y0: float = 0.85
const WIN_Y1: float = 2.4

const TEX_DIR: String = "res://assets/textures/room/"

## Une entrée par période. Les valeurs sont mélangées en fondu quand la période change.
const PRESETS: Dictionary = {
	1: { # MATIN : lumière claire et fraîche qui entre par la fenêtre est, soleil encore bas
		"light_color": Color(1.0, 0.91, 0.76), "light_energy": 1.35, "light_dir": Vector3(-0.82, -0.40, 0.25),
		"ambient_color": Color(0.30, 0.34, 0.44), "ambient_energy": 0.9, "ceiling": 0.30, "corner": 0.08,
		"lamp": 1.2, "fill_color": Color(0.80, 0.88, 1.0), "fill": 0.45,
		"bg": Color(0.10, 0.12, 0.16), "sky": "morning",
	},
	2: { # MIDI / APRÈS-MIDI : soleil haut, lumière blanche et franche
		"light_color": Color(1.0, 0.97, 0.88), "light_energy": 1.9, "light_dir": Vector3(-0.58, -0.78, 0.15),
		"ambient_color": Color(0.52, 0.54, 0.58), "ambient_energy": 1.0, "ceiling": 0.22, "corner": 0.12,
		"lamp": 0.4, "fill_color": Color(1.0, 0.98, 0.92), "fill": 0.5,
		"bg": Color(0.20, 0.22, 0.25), "sky": "day",
	},
	3: { # SOIR : soleil couchant orange-rouge, ombres longues, lampe de bureau allumée
		"light_color": Color(1.0, 0.52, 0.24), "light_energy": 1.35, "light_dir": Vector3(-0.94, -0.17, 0.2),
		"ambient_color": Color(0.30, 0.22, 0.28), "ambient_energy": 0.8, "ceiling": 0.28, "corner": 0.08,
		"lamp": 1.7, "fill_color": Color(1.0, 0.50, 0.28), "fill": 0.6,
		"bg": Color(0.07, 0.05, 0.07), "sky": "evening",
	},
}

var mats: Dictionary = {}
var sun: DirectionalLight3D
var lamp: OmniLight3D
var fill: OmniLight3D
var ceil_light: OmniLight3D
var corner_lights: Array[OmniLight3D] = []
var env: Environment
var window_view: WindowView
var current_period: int = 1
var period_tween: Tween = null

func _ready() -> void:
	add_to_group("office_room")
	_make_materials()
	_build_structure()
	_build_openings()
	_build_collisions()
	_build_lights()
	_build_window_view()

	current_period = clampi(GameManager.current_period, 1, 3)
	_mix(PRESETS[current_period], PRESETS[current_period], 1.0)
	GameManager.period_changed.connect(_on_period_changed)

# ---------------------------------------------------------------------------
# Ambiance (nuit / aube / jour)
# ---------------------------------------------------------------------------

func _on_period_changed(new_period: int) -> void:
	new_period = clampi(new_period, 1, 3)
	if new_period == current_period:
		return
	var from: Dictionary = PRESETS[current_period]
	var to: Dictionary = PRESETS[new_period]
	current_period = new_period
	if period_tween and period_tween.is_valid():
		period_tween.kill()
	if GameManager.is_loading:
		_mix(to, to, 1.0)
		return
	period_tween = create_tween()
	period_tween.tween_method(func(t: float): _mix(from, to, t), 0.0, 1.0, 4.0).set_trans(Tween.TRANS_SINE)

func _mix(a: Dictionary, b: Dictionary, t: float) -> void:
	var ca: Color = a["light_color"]
	sun.light_color = ca.lerp(b["light_color"], t)
	sun.light_energy = lerpf(a["light_energy"], b["light_energy"], t)
	var da: Vector3 = a["light_dir"]
	var d: Vector3 = da.lerp(b["light_dir"], t).normalized()
	sun.basis = Basis.looking_at(d, Vector3.UP)

	var aa: Color = a["ambient_color"]
	env.ambient_light_color = aa.lerp(b["ambient_color"], t)
	env.ambient_light_energy = lerpf(a["ambient_energy"], b["ambient_energy"], t)
	var bg: Color = a["bg"]
	env.background_color = bg.lerp(b["bg"], t)

	lamp.light_energy = lerpf(a["lamp"], b["lamp"], t)
	ceil_light.light_energy = lerpf(a.get("ceiling", 1.0), b.get("ceiling", 1.0), t)
	for c in corner_lights:
		c.light_energy = lerpf(a.get("corner", 0.1), b.get("corner", 0.1), t)
	var fa: Color = a["fill_color"]
	fill.light_color = fa.lerp(b["fill_color"], t)
	fill.light_energy = lerpf(a["fill"], b["fill"], t)

	# Vue extérieure (ciel, ville, lumières des immeubles) : mélange des deux ambiances
	if window_view:
		window_view.apply_mix(a["sky"], b["sky"], t)

# ---------------------------------------------------------------------------
# Matériaux
# ---------------------------------------------------------------------------

func _tex(file: String) -> Texture2D:
	var path := TEX_DIR + file
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

## Matériau texturé qui se répète tous les `tile` mètres (indépendant de la taille de la boîte)
func _tiled(file: String, tile: float, tint: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex(file)
	m.albedo_color = tint
	m.roughness = roughness
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / tile
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

func _plain(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _make_materials() -> void:
	mats["floor"] = _tiled("floor_tiles.png", 2.0, Color(1, 1, 1), 0.55)
	mats["wall"] = _tiled("plaster.png", 1.5, Color(0.66, 0.70, 0.76))
	mats["ceiling"] = _tiled("ceiling_tiles.png", 1.2, Color(0.62, 0.64, 0.68))
	mats["wood_dark"] = _plain(Color(0.22, 0.14, 0.09), 0.7)
	mats["wood"] = _plain(Color(0.36, 0.23, 0.13), 0.65)
	mats["metal"] = _plain(Color(0.55, 0.52, 0.45), 0.35, 0.8)
	mats["blind"] = _plain(Color(0.78, 0.76, 0.70), 0.6)
	mats["outside"] = _plain(Color(0.03, 0.03, 0.04), 1.0)

	var rug := StandardMaterial3D.new()
	rug.albedo_texture = _tex("rug.png")
	rug.roughness = 1.0
	mats["rug"] = rug

	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.55, 0.65, 0.85, 0.10)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic_specular = 0.8
	mats["glass"] = glass

	var frosted := StandardMaterial3D.new()
	frosted.albedo_color = Color(0.72, 0.76, 0.72)
	frosted.roughness = 0.9
	frosted.emission_enabled = true
	frosted.emission = Color(0.30, 0.33, 0.28)
	frosted.emission_energy_multiplier = 0.30
	mats["frosted"] = frosted

	var fixture := StandardMaterial3D.new()
	fixture.albedo_color = Color(0.85, 0.84, 0.78)
	fixture.emission_enabled = true
	fixture.emission = Color(0.55, 0.52, 0.40)
	fixture.emission_energy_multiplier = 0.15
	mats["fixture"] = fixture

# ---------------------------------------------------------------------------
# Outils de construction
# ---------------------------------------------------------------------------

func _box(box_name: String, center: Vector3, size: Vector3, mat: Material, shadow: bool = true) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = box_name
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = mat
	m.position = center
	if not shadow:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	return m

## Morceau de mur est/ouest (fin selon x). side = -1 (ouest) ou +1 (est)
func _wall_x(side: int, z0: float, z1: float, y0: float, y1: float) -> void:
	_box("Mur_%s" % ("Est" if side > 0 else "Ouest"),
		Vector3(side * (HALF_W + T / 2.0), (y0 + y1) / 2.0, (z0 + z1) / 2.0),
		Vector3(T, y1 - y0, z1 - z0), mats["wall"])

## Morceau de mur nord/sud (fin selon z). side = -1 (nord) ou +1 (sud)
func _wall_z(side: int, x0: float, x1: float, y0: float, y1: float) -> void:
	_box("Mur_%s" % ("Sud" if side > 0 else "Nord"),
		Vector3((x0 + x1) / 2.0, (y0 + y1) / 2.0, side * (HALF_D + T / 2.0)),
		Vector3(x1 - x0, y1 - y0, T), mats["wall"])

func _baseboard_x(side: int, z0: float, z1: float) -> void:
	_box("Plinthe", Vector3(side * (HALF_W - 0.015), 0.06, (z0 + z1) / 2.0), Vector3(0.03, 0.12, z1 - z0), mats["wood_dark"], false)

func _baseboard_z(side: int, x0: float, x1: float) -> void:
	_box("Plinthe", Vector3((x0 + x1) / 2.0, 0.06, side * (HALF_D - 0.015)), Vector3(x1 - x0, 0.12, 0.03), mats["wood_dark"], false)

# ---------------------------------------------------------------------------
# Structure : sol, plafond, murs
# ---------------------------------------------------------------------------

func _build_structure() -> void:
	var fw := HALF_W * 2.0 + T * 2.0
	var fd := HALF_D * 2.0 + T * 2.0
	_box("Sol", Vector3(0, -0.1, 0), Vector3(fw, 0.2, fd), mats["floor"])
	_box("Tapis", Vector3(0, 0.006, 0.6), Vector3(3.3, 0.012, 2.6), mats["rug"], false)
	var ceiling := _box("Plafond", Vector3(0, H + T / 2.0, 0), Vector3(fw, T, fd), mats["ceiling"])
	ceiling.add_to_group("room_ceiling")

	# Luminaire de plafond (éteint, juste décoratif)
	_box("Luminaire", Vector3(0.3, H - 0.22, -0.4), Vector3(1.7, 0.09, 0.26), mats["fixture"], false)
	for dx in [-0.75, 0.75]:
		_box("Tige_Luminaire", Vector3(0.3 + dx, H - 0.1, -0.4), Vector3(0.02, 0.2, 0.02), mats["metal"], false)

	# Mur nord (le fond de la pièce) : plein
	_wall_z(-1, -HALF_W - T, HALF_W + T, 0.0, H)
	_baseboard_z(-1, -HALF_W, HALF_W)

	# Mur sud : plein (pas de porte d'entrée)
	_wall_z(1, -HALF_W - T, HALF_W + T, 0.0, H)
	_baseboard_z(1, -HALF_W, HALF_W)

	# Mur ouest : porte des archives
	var az0 := ARCH_DOOR_Z - ARCH_DOOR_W / 2.0
	var az1 := ARCH_DOOR_Z + ARCH_DOOR_W / 2.0
	_wall_x(-1, -HALF_D - T, az0, 0.0, H)
	_wall_x(-1, az1, HALF_D + T, 0.0, H)
	_wall_x(-1, az0, az1, DOOR_H, H)
	_baseboard_x(-1, -HALF_D, az0)
	_baseboard_x(-1, az1, HALF_D)

	# Mur est : fenêtre
	var wz0 := WIN_Z - WIN_W / 2.0
	var wz1 := WIN_Z + WIN_W / 2.0
	_wall_x(1, -HALF_D - T, wz0, 0.0, H)
	_wall_x(1, wz1, HALF_D + T, 0.0, H)
	_wall_x(1, wz0, wz1, 0.0, WIN_Y0)
	_wall_x(1, wz0, wz1, WIN_Y1, H)
	_baseboard_x(1, -HALF_D, wz0)
	_baseboard_x(1, wz1, HALF_D)

# ---------------------------------------------------------------------------
# Ouvertures : portes et fenêtre
# ---------------------------------------------------------------------------

func _build_openings() -> void:
	_build_archives_door()
	_build_window()

func _build_archives_door() -> void:
	var x_in := -HALF_W
	var z0 := ARCH_DOOR_Z - ARCH_DOOR_W / 2.0
	var z1 := ARCH_DOOR_Z + ARCH_DOOR_W / 2.0
	# Encadrement en saillie sur la pièce
	_box("Chambranle_A", Vector3(x_in + 0.03, DOOR_H / 2.0, z0 - 0.03), Vector3(0.07, DOOR_H, 0.07), mats["wood"])
	_box("Chambranle_B", Vector3(x_in + 0.03, DOOR_H / 2.0, z1 + 0.03), Vector3(0.07, DOOR_H, 0.07), mats["wood"])
	_box("Chambranle_Haut", Vector3(x_in + 0.03, DOOR_H + 0.03, ARCH_DOOR_Z), Vector3(0.07, 0.07, ARCH_DOOR_W + 0.14), mats["wood"])
	# Vantail en bois + vitre dépolie
	var px := x_in - 0.06
	_box("Porte_Archives", Vector3(px, DOOR_H / 2.0, ARCH_DOOR_Z), Vector3(0.05, DOOR_H - 0.01, ARCH_DOOR_W - 0.01), mats["wood"])
	_box("Vitre_Archives", Vector3(px + 0.01, 1.42, ARCH_DOOR_Z), Vector3(0.06, 1.0, 0.72), mats["frosted"], false)

	var label := Label3D.new()
	label.name = "Label_Archives"
	label.text = "ARCHIVES"
	label.font = UIStyle.font_title()
	label.font_size = 72
	label.pixel_size = 0.0019
	label.modulate = Color(0.10, 0.10, 0.10)
	label.outline_size = 0
	label.shaded = false
	label.double_sided = false
	label.position = Vector3(px + 0.045, 1.45, ARCH_DOOR_Z)
	label.rotation_degrees = Vector3(0, 90, 0)
	add_child(label)

	_box("Poignee_Archives", Vector3(x_in + 0.05, 1.0, z1 - 0.12), Vector3(0.05, 0.04, 0.14), mats["metal"], false)

func _build_window() -> void:
	var x_in := HALF_W
	var z0 := WIN_Z - WIN_W / 2.0
	var z1 := WIN_Z + WIN_W / 2.0
	var h := WIN_Y1 - WIN_Y0
	var yc := (WIN_Y0 + WIN_Y1) / 2.0
	# Encadrement
	_box("Fenetre_Appui", Vector3(x_in - 0.07, WIN_Y0 - 0.02, WIN_Z), Vector3(0.18, 0.05, WIN_W + 0.16), mats["wood"])
	_box("Fenetre_Linteau", Vector3(x_in - 0.03, WIN_Y1 + 0.03, WIN_Z), Vector3(0.07, 0.07, WIN_W + 0.14), mats["wood"])
	_box("Fenetre_Montant_A", Vector3(x_in - 0.03, yc, z0 - 0.03), Vector3(0.07, h, 0.07), mats["wood"])
	_box("Fenetre_Montant_B", Vector3(x_in - 0.03, yc, z1 + 0.03), Vector3(0.07, h, 0.07), mats["wood"])
	# Croisillons
	_box("Fenetre_Croisillon_V", Vector3(x_in + 0.04, yc, WIN_Z), Vector3(0.05, h, 0.04), mats["wood"])
	_box("Fenetre_Croisillon_H", Vector3(x_in + 0.04, yc - 0.1, WIN_Z), Vector3(0.05, 0.04, WIN_W), mats["wood"])
	# Vitre (ne projette pas d'ombre)
	_box("Fenetre_Vitre", Vector3(x_in + 0.06, yc, WIN_Z), Vector3(0.01, h, WIN_W), mats["glass"], false)
	# Store vénitien à moitié relevé : lames en haut de la fenêtre (leurs ombres rayent le sol)
	_box("Store_Rail", Vector3(x_in - 0.1, WIN_Y1 - 0.02, WIN_Z), Vector3(0.05, 0.04, WIN_W - 0.02), mats["blind"], false)
	var y := WIN_Y1 - 0.07
	while y > WIN_Y1 - 0.42:
		var slat := _box("Store_Lame", Vector3(x_in - 0.1, y, WIN_Z), Vector3(0.07, 0.012, WIN_W - 0.06), mats["blind"])
		slat.rotation_degrees = Vector3(0, 0, 32)
		y -= 0.05

# ---------------------------------------------------------------------------
# Collisions : les murs pleins (même au niveau des portes et de la fenêtre) et le sol
# ---------------------------------------------------------------------------

func _build_collisions() -> void:
	var body := StaticBody3D.new()
	body.name = "Collisions_Salle"
	add_child(body)
	var fw := HALF_W * 2.0 + T * 2.0
	var fd := HALF_D * 2.0 + T * 2.0
	var shapes := [
		[Vector3(0, -0.1, 0), Vector3(fw, 0.2, fd)],
		[Vector3(0, H + T / 2.0, 0), Vector3(fw, T, fd)],
		[Vector3(0, H / 2.0, -(HALF_D + T / 2.0)), Vector3(fw, H, T)],
		[Vector3(0, H / 2.0, HALF_D + T / 2.0), Vector3(fw, H, T)],
		[Vector3(-(HALF_W + T / 2.0), H / 2.0, 0), Vector3(T, H, fd)],
		[Vector3(HALF_W + T / 2.0, H / 2.0, 0), Vector3(T, H, fd)],
	]
	for s in shapes:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = s[1]
		cs.shape = bs
		cs.position = s[0]
		body.add_child(cs)

# ---------------------------------------------------------------------------
# Lumières et environnement
# ---------------------------------------------------------------------------

func _build_lights() -> void:
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.07, 0.11)
	env.fog_density = 0.008
	we.environment = env
	add_child(we)

	# Lune / aube / soleil : entre par la fenêtre, les croisillons et le store dessinent leurs ombres au sol
	sun = DirectionalLight3D.new()
	sun.name = "Lumiere_Fenetre"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 14.0
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	add_child(sun)

	# Lampe de bureau : emplacement de la future lampe de Louka (sur le bureau, côté gauche)
	lamp = OmniLight3D.new()
	lamp.name = "Lumiere_Lampe_Bureau"
	lamp.position = Vector3(-0.85, 1.25, 0.2)
	lamp.light_color = Color(1.0, 0.72, 0.38)
	lamp.omni_range = 3.8
	lamp.omni_attenuation = 1.6
	lamp.shadow_enabled = true
	add_child(lamp)

	# Plafonnier (néon) : éclaire toute la pièce, sans ombres
	ceil_light = OmniLight3D.new()
	ceil_light.name = "Lumiere_Plafonnier"
	ceil_light.position = Vector3(0, H - 0.35, -0.3)
	ceil_light.light_color = Color(1.0, 0.93, 0.80)
	ceil_light.omni_range = 11.0
	ceil_light.omni_attenuation = 0.8
	add_child(ceil_light)
	# Appoints de coin pour que le fond de la pièce reste lisible
	for p in [Vector3(-2.6, 2.2, -2.3), Vector3(2.6, 2.2, 2.3), Vector3(-2.6, 2.2, 2.3)]:
		var c := OmniLight3D.new()
		c.name = "Lumiere_Coin"
		c.position = p
		c.light_color = Color(1.0, 0.92, 0.8)
		c.light_energy = 0.35
		c.omni_range = 6.0
		add_child(c)
		corner_lights.append(c)

	# Appoint près de la fenêtre : donne la lueur de la lumière extérieure sur le mur et les meubles
	fill = OmniLight3D.new()
	fill.name = "Lumiere_Appoint_Fenetre"
	fill.position = Vector3(2.7, 1.7, -2.0)
	fill.omni_range = 4.0
	fill.omni_attenuation = 1.5
	add_child(fill)

func _build_window_view() -> void:
	window_view = WindowView.new()
	window_view.name = "Vue_Fenetre"
	add_child(window_view)
	window_view.setup(HALF_W, WIN_Z)

## Pour les captures et le débogage : cache ou montre le plafond (vue de dessus)
func set_ceiling_visible(v: bool) -> void:
	for c in get_tree().get_nodes_in_group("room_ceiling"):
		c.visible = v
