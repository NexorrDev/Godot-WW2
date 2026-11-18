extends Node3D
class_name WindowView

## Vue extérieure derrière la fenêtre : une vraie ville en 3D (et non une image).
## - Rue en contrebas (la salle est à l'étage), immeubles d'en face avec fenêtres éclairées
##   (certaines s'allument et s'éteignent), toits mansardés, cheminées qui fument,
##   clocher, cheminée d'usine, réverbères.
## - Ciel procédural : dégradé, lune ou soleil bas, étoiles, nuages qui défilent.
## - Oiseaux qui traversent le ciel à l'aube et en journée.
## - Parallaxe naturelle quand le joueur bouge la tête devant la fenêtre.
## Les ambiances (nuit / aube / jour) sont réglées dans PRESETS et mélangées par OfficeRoom.

const GROUND_Y := -12.0   # niveau de la rue par rapport au sol de la salle

const PRESETS: Dictionary = {
	"morning": { # MATIN CLAIR
		"sky_top": Color(0.33, 0.54, 0.90), "sky_horizon": Color(0.96, 0.89, 0.78),
		"disc_dir": Vector3(1.0, 0.22, -0.78), "disc_size": 0.045, "disc_col": Color(1.0, 0.95, 0.80),
		"glow_col": Color(1.0, 0.85, 0.60), "glow_amt": 0.75,
		"stars": 0.0, "cloud_col": Color(1.0, 0.96, 0.92), "cloud_cover": 0.35,
		"tint": Color(0.62, 0.62, 0.62), "fog_density": 0.009,
		"lit_col": Color(1.0, 0.85, 0.55), "lit_amount": 0.15, "lit_ratio": 0.03,
		"lamp_amt": 0.3, "smoke_col": Color(0.9, 0.9, 0.92, 0.5), "birds": 1.0,
	},
	"night": { # NUIT NOIRE (période 1) : lune, étoiles, réverbères, quelques fenêtres allumées
		"sky_top": Color(0.002, 0.004, 0.018), "sky_horizon": Color(0.035, 0.045, 0.10),
		"disc_dir": Vector3(1.0, 0.34, -0.55), "disc_size": 0.016, "disc_col": Color(0.82, 0.88, 1.0),
		"glow_col": Color(0.20, 0.30, 0.62), "glow_amt": 0.35,
		"stars": 1.0, "cloud_col": Color(0.05, 0.06, 0.12), "cloud_cover": 0.30,
		"tint": Color(0.17, 0.20, 0.34), "fog_density": 0.010,
		"lit_col": Color(1.0, 0.72, 0.34), "lit_amount": 1.0, "lit_ratio": 0.20,
		"lamp_amt": 1.0, "smoke_col": Color(0.22, 0.25, 0.38, 0.45), "birds": 0.0,
	},
	"evening": { # SOIR : COUCHER DE SOLEIL
		"sky_top": Color(0.16, 0.15, 0.42), "sky_horizon": Color(1.0, 0.42, 0.20),
		"disc_dir": Vector3(1.0, 0.14, -0.5), "disc_size": 0.07, "disc_col": Color(1.0, 0.60, 0.28),
		"glow_col": Color(1.0, 0.38, 0.14), "glow_amt": 1.4,
		"stars": 0.1, "cloud_col": Color(1.0, 0.45, 0.35), "cloud_cover": 0.5,
		"tint": Color(0.42, 0.28, 0.30), "fog_density": 0.014,
		"lit_col": Color(1.0, 0.72, 0.38), "lit_amount": 0.9, "lit_ratio": 0.2,
		"lamp_amt": 0.8, "smoke_col": Color(0.70, 0.40, 0.35, 0.55), "birds": 1.0,
	},
	"dusk": { # NUIT FROIDE
		"sky_top": Color(0.015, 0.025, 0.08), "sky_horizon": Color(0.17, 0.19, 0.36),
		"disc_dir": Vector3(1.0, 0.24, -0.78), "disc_size": 0.020, "disc_col": Color(0.92, 0.95, 1.0),
		"glow_col": Color(0.35, 0.45, 0.75), "glow_amt": 0.55,
		"stars": 1.0, "cloud_col": Color(0.10, 0.12, 0.22), "cloud_cover": 0.42,
		"tint": Color(0.16, 0.19, 0.30), "fog_density": 0.011,
		"lit_col": Color(1.0, 0.70, 0.32), "lit_amount": 1.0, "lit_ratio": 0.24,
		"lamp_amt": 1.0, "smoke_col": Color(0.30, 0.33, 0.45, 0.55), "birds": 0.0,
	},
	"dawn": { # AUBE ORANGÉE
		"sky_top": Color(0.30, 0.40, 0.66), "sky_horizon": Color(1.0, 0.60, 0.33),
		"disc_dir": Vector3(1.0, 0.07, -0.78), "disc_size": 0.055, "disc_col": Color(1.0, 0.86, 0.55),
		"glow_col": Color(1.0, 0.55, 0.22), "glow_amt": 1.2,
		"stars": 0.0, "cloud_col": Color(1.0, 0.62, 0.42), "cloud_cover": 0.52,
		"tint": Color(0.40, 0.30, 0.30), "fog_density": 0.015,
		"lit_col": Color(1.0, 0.75, 0.40), "lit_amount": 0.65, "lit_ratio": 0.08,
		"lamp_amt": 0.35, "smoke_col": Color(0.85, 0.55, 0.40, 0.55), "birds": 1.0,
	},
	"day": { # PLEIN JOUR
		"sky_top": Color(0.22, 0.46, 0.88), "sky_horizon": Color(0.76, 0.87, 0.97),
		"disc_dir": Vector3(1.0, 1.1, -0.6), "disc_size": 0.05, "disc_col": Color(1.0, 0.98, 0.9),
		"glow_col": Color(1.0, 0.95, 0.8), "glow_amt": 0.4,
		"stars": 0.0, "cloud_col": Color(1.0, 1.0, 1.0), "cloud_cover": 0.5,
		"tint": Color(0.72, 0.70, 0.66), "fog_density": 0.0065,
		"lit_col": Color(1.0, 0.9, 0.6), "lit_amount": 0.0, "lit_ratio": 0.0,
		"lamp_amt": 0.0, "smoke_col": Color(0.92, 0.92, 0.92, 0.5), "birds": 1.0,
	},
}

const SKY_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec3 sky_top : source_color = vec3(0.1, 0.2, 0.5);
uniform vec3 sky_horizon : source_color = vec3(0.7, 0.8, 0.9);
uniform vec3 disc_dir = vec3(1.0, 0.2, -0.8);
uniform float disc_size = 0.03;
uniform vec3 disc_col : source_color = vec3(1.0);
uniform vec3 glow_col : source_color = vec3(1.0);
uniform float glow_amt = 0.5;
uniform float stars = 0.0;
uniform vec3 cloud_col : source_color = vec3(1.0);
uniform float cloud_cover = 0.5;

varying vec3 wpos;

float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i); float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0)); float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * vnoise(p); p *= 2.03; a *= 0.5; }
	return v;
}

void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	vec3 dir = normalize(wpos - CAMERA_POSITION_WORLD);
	float elev = dir.y;
	vec3 col = mix(sky_horizon, sky_top, pow(clamp(elev * 1.7, 0.0, 1.0), 0.55));

	vec3 dd = normalize(disc_dir);
	float dist = distance(dir, dd);
	col += glow_col * glow_amt * exp(-dist * 4.5) * 0.7;
	col += glow_col * glow_amt * exp(-dist * 14.0) * 0.5;
	float disc = smoothstep(disc_size, disc_size * 0.8, dist);
	// étoiles
	vec3 g = floor(dir * 300.0);
	float h = hash21(g.xy + g.z * 17.3);
	float st = step(0.9992, h) * stars * smoothstep(0.02, 0.3, elev) * (0.6 + 0.4 * sin(TIME * 2.0 + h * 400.0));
	col += vec3(st);

	// nuages qui défilent
	vec2 cuv = dir.zx / (max(elev, 0.0) + 0.16) * 0.55 + vec2(TIME * 0.006, TIME * 0.0025);
	float c = fbm(cuv);
	float cl = smoothstep(1.0 - cloud_cover, 1.0 - cloud_cover + 0.22, c);
	cl *= smoothstep(0.0, 0.18, elev);
	float edge = smoothstep(1.0 - cloud_cover + 0.05, 1.0 - cloud_cover + 0.35, fbm(cuv + vec2(0.07, 0.04)));
	vec3 ccol = mix(cloud_col, cloud_col * 0.55 + sky_horizon * 0.3, clamp(c - edge * 0.2, 0.0, 1.0) * 0.6);
	col = mix(col, ccol, cl * 0.85);
	// le disque passe derrière les nuages
	col = mix(col, disc_col, disc * (1.0 - cl * 0.8));
	ALBEDO = col;
}
"""

const CITY_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 base_col : source_color = vec3(0.7, 0.65, 0.55);
uniform vec3 roof_col : source_color = vec3(0.35, 0.38, 0.42);
uniform vec3 tint : source_color = vec3(1.0);
uniform vec3 fog_col : source_color = vec3(0.6);
uniform float fog_density = 0.01;
uniform vec3 lit_col : source_color = vec3(1.0, 0.7, 0.3);
uniform float lit_amount = 1.0;
uniform float lit_ratio = 0.2;
uniform vec2 cell = vec2(2.6, 3.2);
uniform float seed = 0.0;

varying vec3 wpos;
varying vec3 wnrm;

float hash(vec2 p) { return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453); }

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 col;
	float lit = 0.0;
	if (wnrm.y > 0.3) {
		col = roof_col * (0.85 + 0.3 * hash(floor(wpos.xz * 1.5)));
	} else {
		vec2 uv = abs(wnrm.x) > 0.5 ? vec2(wpos.z, wpos.y) : vec2(wpos.x, wpos.y);
		vec2 p = uv / cell;
		vec2 id = floor(p);
		vec2 f = fract(p);
		float n = hash(id);
		vec3 wall = base_col * (0.9 + 0.2 * hash(id.yx + 7.0));
		// corniche et balcon
		if (f.y > 0.9 || (f.y < 0.2 && f.y > 0.14)) wall *= 0.8;
		bool win = f.x > 0.27 && f.x < 0.73 && f.y > 0.24 && f.y < 0.80;
		if (win) {
			float mullion = step(abs(f.x - 0.5), 0.018) + step(abs(f.y - 0.55), 0.015);
			col = vec3(0.03, 0.04, 0.07);
			float phase = floor(TIME / 40.0 + n * 12.0);
			float l = hash(id + vec2(phase * 1.7, phase * 0.3));
			lit = step(l, lit_ratio) * (1.0 - clamp(mullion, 0.0, 1.0)) * (0.55 + 0.45 * hash(id + 3.3));
			col = mix(col, wall * 0.55, clamp(mullion, 0.0, 1.0));
			col *= tint;
		} else {
			col = wall * tint;
		}
		// pied d'immeuble : volets / ombre
		col *= mix(0.55, 1.0, smoothstep(-12.0, -2.0, wpos.y));
	}
	if (wnrm.y > 0.3) col *= tint;
	col = mix(col, lit_col * lit_amount, lit * clamp(lit_amount, 0.0, 1.0));
	float d = length(wpos - CAMERA_POSITION_WORLD);
	float fogf = 1.0 - exp(-d * fog_density);
	ALBEDO = mix(col, fog_col, clamp(fogf, 0.0, 1.0));
}
"""

const FLAT_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 col : source_color = vec3(0.3);
uniform vec3 tint : source_color = vec3(1.0);
uniform vec3 fog_col : source_color = vec3(0.6);
uniform float fog_density = 0.01;
uniform vec3 emit_col : source_color = vec3(1.0, 0.8, 0.4);
uniform float emit_amt = 0.0;

varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 c = mix(col * tint, emit_col, emit_amt);
	float d = length(wpos - CAMERA_POSITION_WORLD);
	ALBEDO = mix(c, fog_col, clamp(1.0 - exp(-d * fog_density), 0.0, 1.0));
}
"""

const STREET_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 tint : source_color = vec3(1.0);
uniform vec3 fog_col : source_color = vec3(0.6);
uniform float fog_density = 0.01;
uniform float x0 = 3.6;
uniform float gap_z0 = -22.5;
uniform float gap_z1 = -14.0;
uniform float lamp_amt = 0.0;

varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

// bande [a,b] le long d'un axe, avec bords nets
float band(float v, float a, float b) { return step(a, v) * step(v, b); }

void fragment() {
	float rx = wpos.x - x0;      // distance au mur de la salle, vers l'extérieur
	float z = wpos.z;
	vec3 col = vec3(0.24, 0.23, 0.22);                     // cours, sol lointain
	vec2 cell = floor(wpos.xz * 1.6);
	col *= 0.85 + 0.3 * hash(cell);

	// rue principale (le long de z) : x0+0 .. x0+11
	float main_st = band(rx, 0.0, 11.0);
	float main_side = main_st * (1.0 - band(rx, 1.7, 9.3));
	float main_road = main_st * band(rx, 1.7, 9.3);
	// rue transversale dans la trouée entre les immeubles
	float cross_st = band(z, gap_z0, gap_z1) * step(11.0, rx) * step(rx, 80.0);
	float cross_road = cross_st * band(z, gap_z0 + 1.6, gap_z1 - 1.6);
	float cross_side = cross_st * (1.0 - band(z, gap_z0 + 1.6, gap_z1 - 1.6));

	float road = clamp(main_road + cross_road, 0.0, 1.0);
	float side = clamp(main_side + cross_side, 0.0, 1.0) * (1.0 - road);

	// asphalte : grain + pavés usés
	vec3 asphalt = vec3(0.20, 0.20, 0.215) * (0.8 + 0.4 * hash(floor(wpos.xz * 5.0)));
	vec2 cob = fract(wpos.xz * 1.3);
	asphalt *= 1.0 - 0.18 * (step(cob.x, 0.07) + step(cob.y, 0.07));
	// trottoirs : dalles
	vec3 pave = vec3(0.46, 0.44, 0.40) * (0.88 + 0.2 * hash(floor(wpos.xz * 0.9)));
	vec2 sl = fract(wpos.xz * 0.85);
	pave *= 1.0 - 0.22 * (step(sl.x, 0.05) + step(sl.y, 0.05));
	// bordure
	float curb = main_st * (band(rx, 1.55, 1.7) + band(rx, 9.3, 9.45)) + cross_st * (band(z, gap_z0 + 1.45, gap_z0 + 1.6) + band(z, gap_z1 - 1.6, gap_z1 - 1.45));

	col = mix(col, pave, side);
	col = mix(col, asphalt, road);
	col = mix(col, vec3(0.62, 0.60, 0.55), clamp(curb, 0.0, 1.0) * 0.8);

	// ligne centrale en pointillés
	float dash_main = main_road * band(rx, 5.44, 5.56) * step(0.5, fract(z / 5.0));
	float dash_cross = cross_road * band(z, (gap_z0 + gap_z1) * 0.5 - 0.06, (gap_z0 + gap_z1) * 0.5 + 0.06) * step(0.5, fract(wpos.x / 5.0));
	col = mix(col, vec3(0.86, 0.82, 0.62), clamp(dash_main + dash_cross, 0.0, 1.0) * 0.85);
	// passage piéton au carrefour
	float zebra = main_road * band(z, gap_z0 - 3.2, gap_z0 - 1.9) * step(0.5, fract(rx * 1.4));
	col = mix(col, vec3(0.78, 0.76, 0.70), zebra * 0.7);

	col *= tint;
	float d = length(wpos - CAMERA_POSITION_WORLD);
	ALBEDO = mix(col, fog_col, clamp(1.0 - exp(-d * fog_density), 0.0, 1.0));
}
"""

const POOL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float emit_amt = 0.0;
void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float a = pow(clamp(1.0 - d, 0.0, 1.0), 2.2);
	ALBEDO = vec3(1.0, 0.72, 0.36) * a * 0.55 * emit_amt;
}
"""

var pool_shader: Shader
var street_shader: Shader
var street_mat: ShaderMaterial
var cars: Array[Node3D] = []
var city_shader: Shader
var flat_shader: Shader
var sky_mat: ShaderMaterial
var city_mats: Array[ShaderMaterial] = []
var flat_mats: Array[ShaderMaterial] = []
var lamp_mats: Array[ShaderMaterial] = []
var smoke_mats: Array[StandardMaterial3D] = []
var birds: Array[Node3D] = []
var bird_amount := 0.0
var rng := RandomNumberGenerator.new()
var x0 := 3.6
var win_z := -2.3

func setup(wall_x: float, window_z: float) -> void:
	x0 = wall_x
	win_z = window_z
	rng.seed = 1940
	city_shader = Shader.new(); city_shader.code = CITY_SHADER
	flat_shader = Shader.new(); flat_shader.code = FLAT_SHADER
	street_shader = Shader.new(); street_shader.code = STREET_SHADER
	pool_shader = Shader.new(); pool_shader.code = POOL_SHADER
	_build_sky()
	_build_ground()
	_build_skyline()
	_build_landmarks()
	_build_street_lamps()
	_build_birds()
	apply_mix("night", "night", 1.0)

# ---------------------------------------------------------------------------
# Construction
# ---------------------------------------------------------------------------

func _build_sky() -> void:
	var sh := Shader.new(); sh.code = SKY_SHADER
	sky_mat = ShaderMaterial.new(); sky_mat.shader = sh
	var q := MeshInstance3D.new()
	q.name = "Ciel"
	var m := QuadMesh.new()
	m.size = Vector2(1400, 700)
	q.mesh = m
	q.material_override = sky_mat
	q.position = Vector3(x0 + 330.0, 120.0, win_z - 60.0)
	q.rotation_degrees = Vector3(0, -90, 0)
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(q)

func _flat_mat(color: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = flat_shader
	mat.set_shader_parameter("col", color)
	flat_mats.append(mat)
	return mat

func _mesh_node(mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

func _box(size: Vector3, mat: Material, pos: Vector3) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mesh_node(b, mat, pos)

func _build_ground() -> void:
	# sol : un grand plan avec rue principale, rue transversale, trottoirs, bordures, lignes et passage piéton
	street_mat = ShaderMaterial.new()
	street_mat.shader = street_shader
	street_mat.set_shader_parameter("x0", x0)
	street_mat.set_shader_parameter("gap_z0", win_z - 20.2)
	street_mat.set_shader_parameter("gap_z1", win_z - 11.7)
	var plane := BoxMesh.new()
	plane.size = Vector3(500.0, 0.2, 500.0)
	_mesh_node(plane, street_mat, Vector3(x0 + 250.0, GROUND_Y - 0.1, win_z - 40.0))
	_build_cars()

## Voitures de l'époque (boîtes arrondies à la main) : quelques-unes garées, deux qui roulent.
func _car(pos: Vector3, color: Color, yaw: float, moving: bool) -> Node3D:
	var car := Node3D.new()
	car.position = pos
	car.rotation_degrees.y = yaw
	var body_mat := _flat_mat(color)
	var glass := _flat_mat(Color(0.06, 0.07, 0.09))
	var tyre := _flat_mat(Color(0.03, 0.03, 0.035))
	var chrome := _flat_mat(Color(0.55, 0.55, 0.52))
	var parts := [
		[Vector3(1.75, 0.62, 4.3), Vector3(0, 0.62, 0), body_mat],        # caisse
		[Vector3(1.62, 0.55, 2.05), Vector3(0, 1.17, 0.25), body_mat],    # habitacle
		[Vector3(1.64, 0.40, 1.9), Vector3(0, 1.22, 0.25), glass],        # vitres
		[Vector3(1.9, 0.12, 0.35), Vector3(0, 0.38, -2.1), chrome],       # pare-chocs
		[Vector3(1.9, 0.12, 0.35), Vector3(0, 0.38, 2.1), chrome],
	]
	for p in parts:
		var b := BoxMesh.new(); b.size = p[0]
		var mi := MeshInstance3D.new(); mi.mesh = b; mi.material_override = p[2]; mi.position = p[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		car.add_child(mi)
	for wx in [-0.85, 0.85]:
		for wz in [-1.4, 1.4]:
			var c := CylinderMesh.new(); c.top_radius = 0.34; c.bottom_radius = 0.34; c.height = 0.22
			var w := MeshInstance3D.new(); w.mesh = c; w.material_override = tyre
			w.position = Vector3(wx, 0.34, wz); w.rotation_degrees = Vector3(0, 0, 90)
			w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			car.add_child(w)
	# phares (avant = -Z du véhicule) et feux arrière : allumés la nuit seulement
	for hx in [-0.6, 0.6]:
		var hm := ShaderMaterial.new(); hm.shader = flat_shader
		hm.set_shader_parameter("col", Color(0.7, 0.7, 0.6))
		hm.set_shader_parameter("emit_col", Color(1.0, 0.92, 0.62))
		lamp_mats.append(hm)
		var hb := BoxMesh.new(); hb.size = Vector3(0.3, 0.2, 0.08)
		var h := MeshInstance3D.new(); h.mesh = hb; h.material_override = hm; h.position = Vector3(hx, 0.7, -2.17)
		h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		car.add_child(h)
		var tm := ShaderMaterial.new(); tm.shader = flat_shader
		tm.set_shader_parameter("col", Color(0.5, 0.08, 0.06))
		tm.set_shader_parameter("emit_col", Color(1.0, 0.12, 0.08))
		lamp_mats.append(tm)
		var tb := BoxMesh.new(); tb.size = Vector3(0.24, 0.14, 0.08)
		var t := MeshInstance3D.new(); t.mesh = tb; t.material_override = tm; t.position = Vector3(hx, 0.72, 2.17)
		t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		car.add_child(t)
	add_child(car)
	if moving:
		cars.append(car)
	return car

func _build_cars() -> void:
	var colors := [Color(0.10, 0.12, 0.10), Color(0.28, 0.08, 0.07), Color(0.12, 0.13, 0.20), Color(0.30, 0.28, 0.22), Color(0.05, 0.05, 0.06), Color(0.22, 0.24, 0.26)]
	var gy := GROUND_Y + 0.1
	# garées le long du trottoir d'en face et de celui de la salle (tête-bêche)
	var zs := [win_z + 14.0, win_z + 3.0, win_z - 7.5, win_z - 27.0, win_z - 36.0, win_z - 48.0]
	for i in zs.size():
		_car(Vector3(x0 + 2.55, gy, zs[i]), colors[i % colors.size()], 0.0 if i % 2 == 0 else 180.0, false)
	for i in 3:
		_car(Vector3(x0 + 8.45, gy, win_z + 8.0 - i * 15.0 - 20.0), colors[(i + 2) % colors.size()], 180.0, false)
	# deux voitures qui roulent (sens opposés)
	var a := _car(Vector3(x0 + 4.3, gy, win_z + 30.0), Color(0.07, 0.08, 0.09), 0.0, true)
	a.set_meta("speed", 5.5)
	var b := _car(Vector3(x0 + 6.8, gy, win_z - 80.0), Color(0.30, 0.06, 0.05), 180.0, true)
	b.set_meta("speed", -4.5)

func _city_mat(base: Color, roof: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = city_shader
	mat.set_shader_parameter("base_col", base)
	mat.set_shader_parameter("roof_col", roof)
	mat.set_shader_parameter("seed", rng.randf() * 50.0)
	mat.set_shader_parameter("cell", Vector2(rng.randf_range(2.3, 3.0), rng.randf_range(3.0, 3.5)))
	city_mats.append(mat)
	return mat

const WALLS := [Color(0.80, 0.74, 0.62), Color(0.66, 0.66, 0.64), Color(0.58, 0.34, 0.27), Color(0.76, 0.62, 0.40), Color(0.72, 0.70, 0.66)]
const ROOFS := [Color(0.36, 0.40, 0.46), Color(0.50, 0.28, 0.20), Color(0.30, 0.32, 0.36)]

## Un immeuble : corps + (parfois) toit mansardé + cheminées
func _add_building(x_face: float, z_center: float, width: float, depth: float, top_y: float, mansard: bool, smoke: bool = false) -> void:
	var mat := _city_mat(WALLS[rng.randi() % WALLS.size()], ROOFS[rng.randi() % ROOFS.size()])
	var h := top_y - GROUND_Y
	_box(Vector3(depth, h, width), mat, Vector3(x_face + depth / 2.0, GROUND_Y + h / 2.0, z_center))
	var roof_top := top_y
	if mansard:
		var rh := rng.randf_range(2.4, 3.6)
		var prism := PrismMesh.new()
		prism.size = Vector3(depth * 0.96, rh, width)
		_mesh_node(prism, mat, Vector3(x_face + depth / 2.0, top_y + rh / 2.0, z_center))
		roof_top = top_y + rh * 0.55
	# cheminées
	var brick := _flat_mat(Color(0.42, 0.26, 0.21))
	for i in rng.randi_range(1, 3):
		var cz := z_center + rng.randf_range(-width * 0.35, width * 0.35)
		var cx := x_face + depth * rng.randf_range(0.3, 0.7)
		var ch := rng.randf_range(1.4, 2.4)
		_box(Vector3(0.9, ch, 0.9), brick, Vector3(cx, roof_top + ch / 2.0 - 0.2, cz))
		if smoke and i == 1:
			_add_smoke(Vector3(cx, roof_top + ch - 0.2, cz), 1.0)

func _build_skyline() -> void:
	# (x de la façade, profondeur, hauteur mini/maxi, largeur mini/maxi, z début, z fin, mansardes)
	var rows := [
		[17.0, 12.0, -6.0, 3.5, 8.0, 14.0, -90.0, 34.0, true, 0.22],
		[36.0, 14.0, -2.0, 14.0, 9.0, 16.0, -140.0, 70.0, true, 0.15],
		[62.0, 20.0, 5.0, 24.0, 12.0, 22.0, -190.0, 110.0, false, 0.12],
		[100.0, 30.0, 8.0, 30.0, 16.0, 30.0, -260.0, 170.0, false, 0.0],
	]
	for r in rows:
		var z: float = r[6]
		var z_end: float = r[7]
		while z < z_end:
			var w := rng.randf_range(r[4], r[5])
			# parfois une trouée (rue transversale) : on voit plus loin
			if rng.randf() < 0.28:
				z += rng.randf_range(4.0, 9.0)
				continue
			if r[0] < 20.0 and z < 2.0 and z + w > -31.0:
				z = 2.0   # zone de vue principale : composition manuelle (voir plus bas)
				continue
			var top := rng.randf_range(r[2], r[3])
			if r[0] < 20.0 and rng.randf() < 0.15:
				top += rng.randf_range(4.0, 7.0)
			var smoky: bool = r[0] < 20.0 and rng.randf() < r[9]
			_add_building(r[0] + x0 - 3.6 + (rng.randf() - 0.5) * 2.0, z + w / 2.0, w, r[1], top, r[8], smoky)
			z += w + 0.4

	# Composition de la vue principale (ce que voit le joueur depuis le bureau) :
	# deux immeubles bas de part et d'autre d'une rue transversale -> ciel, clocher et horizon visibles
	_add_building(x0 + 13.4, -27.0, 9.0, 12.0, -2.2, true)
	_add_building(x0 + 13.4, -9.0, 10.0, 12.0, 0.6, true, true)

func _build_landmarks() -> void:
	# Clocher d'église
	var stone := _flat_mat(Color(0.55, 0.52, 0.47))
	var slate := _flat_mat(Color(0.26, 0.29, 0.34))
	var cx := x0 + 46.0
	var cz := win_z - 34.0
	var base_h := 26.0 - GROUND_Y
	_box(Vector3(9.0, base_h, 9.0), stone, Vector3(cx, GROUND_Y + base_h / 2.0, cz))
	_box(Vector3(6.0, 8.0, 6.0), stone, Vector3(cx, 26.0 + 4.0, cz))
	var spire := CylinderMesh.new()
	spire.top_radius = 0.0
	spire.bottom_radius = 4.4
	spire.height = 17.0
	spire.radial_segments = 4
	_mesh_node(spire, slate, Vector3(cx, 34.0 + 8.5, cz), Vector3(0, 45, 0))
	_box(Vector3(0.3, 3.0, 0.3), slate, Vector3(cx, 34.0 + 17.0 + 1.5, cz))
	# beffroi : ouvertures sombres
	var dark := _flat_mat(Color(0.03, 0.03, 0.04))
	for s in [-1, 1]:
		_box(Vector3(0.1, 4.0, 1.6), dark, Vector3(cx - 3.05, 30.0, cz + s * 1.4))
	# Cheminée d'usine + fumée
	var brick := _flat_mat(Color(0.40, 0.25, 0.20))
	var fx := x0 + 58.0
	var fz := win_z - 8.0
	var fh := 24.0 - GROUND_Y + 8.0
	var chim := CylinderMesh.new()
	chim.top_radius = 1.1
	chim.bottom_radius = 1.7
	chim.height = fh
	_mesh_node(chim, brick, Vector3(fx, GROUND_Y + fh / 2.0, fz))
	_add_smoke(Vector3(fx, GROUND_Y + fh, fz), 2.6)

func _build_street_lamps() -> void:
	var post_mat := _flat_mat(Color(0.08, 0.08, 0.09))
	var z := win_z + 30.0
	while z > win_z - 90.0:
		var px := x0 + 2.3
		_box(Vector3(0.12, 4.6, 0.12), post_mat, Vector3(px, GROUND_Y + 2.3, z))
		var lamp := ShaderMaterial.new()
		lamp.shader = flat_shader
		lamp.set_shader_parameter("col", Color(0.8, 0.8, 0.7))
		lamp.set_shader_parameter("emit_col", Color(1.0, 0.82, 0.5))
		lamp_mats.append(lamp)
		var s := SphereMesh.new()
		s.radius = 0.28
		s.height = 0.56
		_mesh_node(s, lamp, Vector3(px, GROUND_Y + 4.7, z))
		# halo de lumière au sol : disque doux additif, visible seulement la nuit
		var pool := QuadMesh.new()
		pool.size = Vector2(9.0, 9.0)
		var pm := ShaderMaterial.new()
		pm.shader = pool_shader
		lamp_mats.append(pm)
		var mi := _mesh_node(pool, pm, Vector3(px, GROUND_Y + 0.14, z), Vector3(-90, 0, 0))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		z -= 14.0

func _add_smoke(pos: Vector3, scale: float) -> void:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = 26
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.local_coords = false
	p.direction = Vector3(0.5, 1.0, -0.15)
	p.spread = 10.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 1.0 * scale
	p.initial_velocity_max = 1.6 * scale
	p.scale_amount_min = 1.3 * scale
	p.scale_amount_max = 2.0 * scale
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.35))
	curve.add_point(Vector2(1, 2.8))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)])
	p.color_ramp = grad
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var g2 := Gradient.new()
	g2.offsets = PackedFloat32Array([0.0, 1.0])
	g2.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	tex.gradient = g2
	tex.width = 64
	tex.height = 64
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	mat.albedo_color = Color(0.7, 0.7, 0.7, 0.5)
	mat.disable_fog = true
	smoke_mats.append(mat)
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.material = mat
	p.mesh = q
	add_child(p)

func _tri_mesh(tris: Array) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	for t in tris:
		for v in t:
			verts.append(v)
			norms.append(Vector3.UP)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

func _build_birds() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.04, 0.04, 0.05)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_fog = true
	# Corps : tête vers -Z, queue en éventail vers +Z (unités : mètres, ~oiseau de 0,5 m)
	var body := _tri_mesh([
		[Vector3(0, 0, -0.20), Vector3(-0.045, 0, -0.04), Vector3(0.045, 0, -0.04)],
		[Vector3(-0.045, 0, -0.04), Vector3(0.045, 0, -0.04), Vector3(0, 0, 0.16)],
		[Vector3(0, 0, 0.10), Vector3(-0.08, 0, 0.30), Vector3(0.08, 0, 0.30)],
		[Vector3(0, 0.03, -0.10), Vector3(-0.03, 0, -0.04), Vector3(0.03, 0, -0.04)],
	])
	# Aile droite (la gauche est son miroir) : bord d'attaque avancé, bout effilé et recourbé vers l'arrière
	var wing_pts := [Vector3(0.03, 0, -0.07), Vector3(0.30, 0.02, -0.10), Vector3(0.62, 0.0, 0.08),
		Vector3(0.40, 0, 0.16), Vector3(0.03, 0, 0.18)]
	var wing_r := _tri_mesh([
		[wing_pts[0], wing_pts[1], wing_pts[4]],
		[wing_pts[1], wing_pts[3], wing_pts[4]],
		[wing_pts[1], wing_pts[2], wing_pts[3]],
	])
	var wing_l := _tri_mesh([
		[Vector3(-0.03, 0, -0.07), Vector3(-0.03, 0, 0.18), Vector3(-0.30, 0.02, -0.10)],
		[Vector3(-0.30, 0.02, -0.10), Vector3(-0.03, 0, 0.18), Vector3(-0.40, 0, 0.16)],
		[Vector3(-0.30, 0.02, -0.10), Vector3(-0.40, 0, 0.16), Vector3(-0.62, 0.0, 0.08)],
	])
	for i in 7:
		var bird := Node3D.new()
		bird.scale = Vector3.ONE * rng.randf_range(1.5, 2.2)
		bird.set_meta("z0", win_z + 25.0 - i * 9.0)
		bird.set_meta("speed", rng.randf_range(3.5, 5.0))
		bird.set_meta("phase", rng.randf() * 6.0)
		bird.set_meta("base_y", rng.randf_range(1.5, 7.0))
		bird.set_meta("off", rng.randf() * 60.0)
		bird.set_meta("rate", rng.randf_range(6.5, 9.0))
		bird.set_meta("radius", rng.randf_range(3.5, 5.0))
		bird.set_meta("cz", win_z + rng.randf_range(-7.0, 4.0))
		bird.set_meta("dir", 1.0 if i % 2 == 0 else -1.0)
		var mb := MeshInstance3D.new()
		mb.mesh = body
		mb.material_override = mat
		mb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bird.add_child(mb)
		for side in [-1, 1]:
			var hinge := Node3D.new()
			hinge.name = "Aile_%d" % side
			var mw := MeshInstance3D.new()
			mw.mesh = wing_r if side > 0 else wing_l
			mw.material_override = mat
			mw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			hinge.add_child(mw)
			bird.add_child(hinge)
		bird.visible = false
		add_child(bird)
		birds.append(bird)

func _process(delta: float) -> void:
	for c in cars:
		var sp := float(c.get_meta("speed"))
		# yaw 0 : l'avant (-Z) va vers -Z ; yaw 180 : vers +Z. speed > 0 => vers -Z
		c.position.z -= sp * delta
		if c.position.z < win_z - 110.0:
			c.position.z = win_z + 40.0
		elif c.position.z > win_z + 45.0:
			c.position.z = win_z - 105.0
	if bird_amount <= 0.01:
		for b in birds:
			b.visible = false
		return
	var t := Time.get_ticks_msec() / 1000.0
	for b in birds:
		var ph := float(b.get_meta("phase"))
		# Les oiseaux tournent en rond au-dessus de la rue : on les voit de profil, de face, de dos
		var r := float(b.get_meta("radius"))
		var dir := float(b.get_meta("dir"))
		var sp := float(b.get_meta("speed"))
		var ang := ph + dir * t * sp / r
		var cx := x0 + 13.5
		var cz := float(b.get_meta("cz"))
		var y := float(b.get_meta("base_y")) + 1.5 + sin(t * 0.7 + ph) * 0.6
		b.position = Vector3(cx + cos(ang) * r, y, cz + sin(ang) * r)
		b.visible = true
		var vx := -sin(ang) * dir
		var vz := cos(ang) * dir
		b.rotation = Vector3(0, atan2(-vx, -vz), dir * 0.45)
		# Battements par salves, puis plané ailes ouvertes
		var rate := float(b.get_meta("rate"))
		var burst := clampf(sin(t * 0.55 + ph) * 3.0 + 0.8, 0.0, 1.0)
		var flap := sin(t * rate + ph) * 38.0 * burst + 8.0 * (1.0 - burst)
		(b.get_node("Aile_1") as Node3D).rotation_degrees = Vector3(0, 0, flap)
		(b.get_node("Aile_-1") as Node3D).rotation_degrees = Vector3(0, 0, -flap)
		b.position.y += sin(t * rate + ph) * 0.05 * burst

# ---------------------------------------------------------------------------
# Ambiance
# ---------------------------------------------------------------------------

func _lerp_any(a: Variant, b: Variant, t: float) -> Variant:
	if a is Color:
		return (a as Color).lerp(b, t)
	if a is Vector3:
		return (a as Vector3).lerp(b, t)
	return lerpf(a, b, t)

func apply_mix(key_a: String, key_b: String, t: float) -> void:
	if sky_mat == null or not PRESETS.has(key_a) or not PRESETS.has(key_b):
		return
	var a: Dictionary = PRESETS[key_a]
	var b: Dictionary = PRESETS[key_b]
	var v := {}
	for k in a:
		v[k] = _lerp_any(a[k], b[k], t)

	for k in ["sky_top", "sky_horizon", "disc_dir", "disc_size", "disc_col", "glow_col", "glow_amt", "stars", "cloud_col", "cloud_cover"]:
		sky_mat.set_shader_parameter(k, v[k])
	var fog: Color = v["sky_horizon"]
	for m in city_mats:
		m.set_shader_parameter("tint", v["tint"])
		m.set_shader_parameter("fog_col", fog)
		m.set_shader_parameter("fog_density", v["fog_density"])
		m.set_shader_parameter("lit_col", v["lit_col"])
		m.set_shader_parameter("lit_amount", v["lit_amount"])
		m.set_shader_parameter("lit_ratio", v["lit_ratio"])
	for m in flat_mats:
		m.set_shader_parameter("tint", v["tint"])
		m.set_shader_parameter("fog_col", fog)
		m.set_shader_parameter("fog_density", v["fog_density"])
	if street_mat:
		street_mat.set_shader_parameter("tint", v["tint"])
		street_mat.set_shader_parameter("fog_col", fog)
		street_mat.set_shader_parameter("fog_density", v["fog_density"])
	for m in lamp_mats:
		m.set_shader_parameter("tint", v["tint"])
		m.set_shader_parameter("fog_col", fog)
		m.set_shader_parameter("fog_density", v["fog_density"])
		m.set_shader_parameter("emit_amt", v["lamp_amt"])
	for m in smoke_mats:
		m.albedo_color = v["smoke_col"]
	bird_amount = v["birds"]
