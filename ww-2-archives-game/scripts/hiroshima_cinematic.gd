extends CanvasLayer
class_name HiroshimaCinematic

## Cinématique de fin, juste avant le générique : 6 août 1945, 8 h 15, Hiroshima.
## Noir, bourdonnement d'un avion, silence, éclair blanc, onde de choc et champignon atomique (shader),
## puis texte historique et fondu au noir. Tout est généré par code (image et sons).
## Signal finished : à la fin (ou quand le joueur appuie sur « Passer »).

signal finished

const SHADER := """
shader_type canvas_item;
uniform float t = 0.0;
uniform float flash = 0.0;
uniform float aspect = 1.78;
uniform float shake = 0.0;
uniform float show_blast = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * vnoise(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; }
	return v;
}
float smin(float a, float b, float k) {
	float h = max(k - abs(a - b), 0.0) / k;
	return min(a, b) - h * h * k * 0.25;
}
float ellipse_sd(vec2 p, vec2 r) { return (length(p / r) - 1.0) * min(r.x, r.y); }

void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	uv.y += (hash(vec2(floor(TIME * 24.0), 1.0)) - 0.5) * 0.012 * shake;
	uv.x += (hash(vec2(floor(TIME * 24.0), 2.0)) - 0.5) * 0.012 * shake;
	vec2 p = vec2((uv.x - 0.5) * aspect, uv.y);
	float ground = 0.20;

	// ciel : matin clair, puis rougi par l'éclat
	vec3 sky_h = vec3(0.86, 0.84, 0.78);
	vec3 sky_t = vec3(0.30, 0.50, 0.78);
	vec3 col = mix(sky_h, sky_t, smoothstep(ground, 1.0, uv.y));
	float dim = 1.0 - 0.62 * smoothstep(3.0, 16.0, t) * show_blast;
	float glow = show_blast * exp(-length((p - vec2(0.0, ground + 0.12)) * vec2(0.9, 1.4)) * 2.2);
	col = mix(col, vec3(1.0, 0.55, 0.22), clamp(glow * (0.55 + 0.25 * exp(-t * 0.3)), 0.0, 0.8));
	col *= dim;

	// montagnes lointaines
	float mt = ground + 0.05 + 0.05 * fbm(vec2(p.x * 2.2 + 3.0, 0.5)) + 0.03 * sin(p.x * 3.0);
	col = mix(col, vec3(0.30, 0.36, 0.40) * dim, step(uv.y, mt) * 0.8);

	// la ville : silhouette basse, ruinée par l'onde de choc
	float cell = floor(p.x * 70.0);
	float bh = 0.012 + 0.030 * hash(vec2(cell, 3.0)) + 0.012 * step(0.85, hash(vec2(cell, 8.0)));
	float shock_r = t * 0.20;
	float ruin = smoothstep(shock_r + 0.05, shock_r - 0.05, abs(p.x)) * show_blast;
	bh *= mix(1.0, 0.12, ruin);
	float city = step(uv.y, ground + bh) * step(ground - 0.01, uv.y);
	vec3 city_col = mix(vec3(0.16, 0.16, 0.18), vec3(0.45, 0.20, 0.08), ruin * (0.4 + 0.6 * fbm(vec2(p.x * 20.0, t * 0.5))));
	col = mix(col, city_col * dim, city);
	// sol
	float gnd = step(uv.y, ground - 0.01);
	col = mix(col, vec3(0.10, 0.09, 0.08) * dim, gnd);

	if (show_blast > 0.5) {
		// onde de choc : mur de poussière qui avance au sol
		float ring = exp(-pow((abs(p.x) - shock_r) * 14.0, 2.0)) * smoothstep(0.0, 1.5, t) * (1.0 - smoothstep(6.0, 12.0, t));
		float dust_h = 0.03 + 0.06 * fbm(vec2(p.x * 9.0, t));
		float dust = ring * smoothstep(ground + dust_h, ground, uv.y) * step(ground - 0.02, uv.y);
		col = mix(col, vec3(0.78, 0.60, 0.42), clamp(dust * 0.9, 0.0, 1.0));

		// champignon
		float k1 = 1.0 - exp(-t * 0.40);
		float k2 = 1.0 - exp(-t * 0.22);
		float stem_top = ground + 0.05 + 0.50 * k1;
		float cap_rx = 0.07 + 0.27 * k2;
		float cap_ry = cap_rx * (0.58 + 0.12 * (1.0 - k2));
		float stem_w = 0.028 + 0.022 * k2;
		vec2 q = p;
		vec2 warp = vec2(fbm(q * 6.0 + vec2(0.0, -t * 0.25)), fbm(q * 6.0 + vec2(5.2, -t * 0.25)));
		q += (warp - 0.5) * (0.05 + 0.03 * k2);
		float base = ellipse_sd(q - vec2(0.0, ground + 0.015), vec2(0.07 + 0.20 * k1, 0.035 + 0.05 * (1.0 - k2)));
		float stem = max(abs(q.x) - stem_w * (1.0 + 0.5 * smoothstep(stem_top, ground, q.y)), max(ground - q.y, q.y - stem_top));
		float cap = ellipse_sd(q - vec2(0.0, stem_top + cap_ry * 0.55), vec2(cap_rx, cap_ry));
		float skirt = ellipse_sd(q - vec2(0.0, stem_top - cap_ry * 0.12), vec2(cap_rx * 1.06, cap_ry * 0.34));
		float d = smin(smin(base, stem, 0.06), smin(cap, skirt, 0.05), 0.06);
		float body = smoothstep(0.012, -0.012, d);
		// température : blanc-jaune au début, orange, rouge, puis fumée grise
		float age = clamp(t / 16.0, 0.0, 1.0);
		float tex = fbm(q * 9.0 + vec2(0.0, -t * 0.4));
		float inner = clamp(-d * 14.0, 0.0, 1.0);
		float heat = clamp((1.0 - age * 1.25) * (0.45 + 0.8 * inner) * (0.55 + 0.9 * tex) + 0.9 * exp(-t * 0.7), 0.0, 1.0);
		vec3 hot = mix(vec3(0.55, 0.12, 0.04), vec3(1.0, 0.62, 0.18), smoothstep(0.2, 0.7, heat));
		hot = mix(hot, vec3(1.0, 0.97, 0.80), smoothstep(0.75, 1.0, heat));
		vec3 smoke = mix(vec3(0.20, 0.17, 0.15), vec3(0.50, 0.45, 0.40), tex);
		smoke *= 0.7 + 0.5 * smoothstep(stem_top - cap_ry * 1.2, stem_top + cap_ry * 1.2, q.y);
		vec3 cloud = mix(smoke, hot, smoothstep(0.18, 0.55, heat));
		col = mix(col, cloud, body);
		// halo
		col += vec3(1.0, 0.6, 0.25) * exp(-max(d, 0.0) * 9.0) * 0.25 * exp(-t * 0.18) * (1.0 - body);
	}
	// éclair blanc
	col = mix(col, vec3(1.0), clamp(flash, 0.0, 1.0));
	COLOR = vec4(col, 1.0);
}
"""

const RATE := 16000

var blast: ColorRect
var mat: ShaderMaterial
var black: ColorRect
var text: Label
var skip_btn: Button
var drone: AudioStreamPlayer
var sfx: AudioStreamPlayer
var tint: AudioStreamPlayer
var s_drone: AudioStreamWAV
var s_boom: AudioStreamWAV
var s_ring: AudioStreamWAV
var s_wind: AudioStreamWAV
var rng := RandomNumberGenerator.new()
var running := false
var done := false
var t_blast := 0.0
var blast_on := false
var tw_main: Tween

func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	rng.seed = 1945
	var sh := Shader.new(); sh.code = SHADER
	mat = ShaderMaterial.new(); mat.shader = sh
	blast = ColorRect.new()
	UIStyle.fill_rect(blast)
	blast.material = mat
	blast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(blast)
	black = ColorRect.new()
	UIStyle.fill_rect(black)
	black.color = Color(0, 0, 0, 0)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	text = Label.new()
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_override("font", UIStyle.font_title())
	text.add_theme_font_size_override("font_size", 40)
	text.add_theme_color_override("font_color", UIStyle.TEXT)
	text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	text.add_theme_constant_override("outline_size", 8)
	text.modulate.a = 0.0
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text)
	skip_btn = UIStyle.make_menu_button("Passer")
	skip_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_btn.offset_left = -190
	skip_btn.offset_top = -72
	skip_btn.offset_right = -24
	skip_btn.offset_bottom = -24
	skip_btn.modulate.a = 0.55
	skip_btn.add_to_group("touch_block")
	skip_btn.pressed.connect(_finish)
	add_child(skip_btn)
	drone = _player(-80.0)
	sfx = _player(0.0)
	tint = _player(-6.0)

func _player(db: float) -> AudioStreamPlayer:
	var a := AudioStreamPlayer.new()
	a.volume_db = db
	add_child(a)
	return a

func _process(delta: float) -> void:
	if not visible:
		return
	mat.set_shader_parameter("aspect", get_viewport().get_visible_rect().size.x / maxf(1.0, get_viewport().get_visible_rect().size.y))
	if blast_on:
		t_blast += delta
		mat.set_shader_parameter("t", t_blast)
		mat.set_shader_parameter("shake", clampf(1.0 - t_blast / 3.5, 0.0, 1.0))

func play() -> void:
	if running:
		return
	running = true
	visible = true
	blast.visible = false
	black.color.a = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Music.set_level(-34.0, 2.5)
	# la pièce s'efface dans le noir
	var tb := create_tween()
	tb.tween_property(black, "color:a", 1.0, 1.8)
	await tb.finished
	if done: return
	_make_drone()
	await get_tree().process_frame
	await _say("6 août 1945", 2.6, 40)
	if done: return
	# bourdonnement lointain d'un avion
	drone.stream = s_drone
	drone.volume_db = -60.0
	drone.play()
	var td := create_tween()
	td.tween_property(drone, "volume_db", -9.0, 7.0)
	await _say("Hiroshima\n8 h 15", 3.2, 50)
	if done: return
	_make_boom()
	await get_tree().process_frame
	_make_ring()
	await get_tree().process_frame
	_make_wind()
	await get_tree().create_timer(1.6).timeout
	if done: return
	# silence brutal
	var ts := create_tween()
	ts.tween_property(drone, "volume_db", -80.0, 0.12)
	await get_tree().create_timer(2.2).timeout
	if done: return
	_explosion()

func _say(msg: String, hold: float, size: int) -> void:
	text.text = msg
	text.add_theme_font_size_override("font_size", size)
	var t1 := create_tween()
	t1.tween_property(text, "modulate:a", 1.0, 0.9)
	await t1.finished
	await get_tree().create_timer(hold).timeout
	var t2 := create_tween()
	t2.tween_property(text, "modulate:a", 0.0, 0.8)
	await t2.finished

func _explosion() -> void:
	t_blast = 0.0
	blast_on = true
	blast.visible = true
	mat.set_shader_parameter("show_blast", 1.0)
	mat.set_shader_parameter("flash", 1.0)
	black.color.a = 0.0
	sfx.stream = s_boom
	sfx.volume_db = 0.0
	sfx.play()
	tint.stream = s_ring
	tint.volume_db = -14.0
	tint.play()
	# l'onde de choc arrive quelques secondes après l'éclair
	var w := AudioStreamPlayer.new()
	w.stream = s_wind
	w.volume_db = -3.0
	add_child(w)
	get_tree().create_timer(2.4).timeout.connect(func(): w.play())
	if tw_main and tw_main.is_valid():
		tw_main.kill()
	tw_main = create_tween()
	tw_main.tween_property(mat, "shader_parameter/flash", 0.0, 3.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_after_blast()

func _after_blast() -> void:
	await get_tree().create_timer(8.0).timeout
	if done: return
	await _say("Hiroshima, 6 août 1945, 8 h 15.\nEnviron 70 000 morts en quelques instants.", 4.2, 34)
	if done: return
	await _say("Nagasaki, 9 août 1945.", 2.6, 34)
	if done: return
	await _say("Le 2 septembre 1945, le Japon capitule.\nLa Seconde Guerre mondiale est terminée.", 4.5, 34)
	if done: return
	var tf := create_tween()
	tf.tween_property(black, "color:a", 1.0, 2.0)
	await tf.finished
	await get_tree().create_timer(0.6).timeout
	_finish()

func _finish() -> void:
	if done:
		return
	done = true
	for a in [drone, sfx, tint]:
		a.stop()
	for c in get_children():
		if c is AudioStreamPlayer:
			c.stop()
	blast.visible = false
	black.color.a = 1.0
	text.modulate.a = 0.0
	visible = false
	finished.emit()

# ---------------------------------------------------------------------------
# Sons synthétisés
# ---------------------------------------------------------------------------

func _wav(data: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size()
	return w

func _make_drone() -> void:
	# moteur d'avion : fondamentale grave + harmoniques, battement d'hélice, souffle filtré (boucle de 4 s)
	var n := RATE * 4
	var d := PackedFloat32Array(); d.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var beat := 0.65 + 0.35 * sin(TAU * 13.0 * t)
		var s := 0.0
		s += sin(TAU * 62.0 * t) * 0.5
		s += sin(TAU * 124.0 * t + 0.6) * 0.32
		s += sin(TAU * 186.0 * t + 1.3) * 0.18
		s += sin(TAU * 248.0 * t) * 0.08
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.07
		s = s * beat + lp * 0.35
		d[i] = s * 0.45
	s_drone = _wav(d, true)

func _make_boom() -> void:
	var n := RATE * 9
	var d := PackedFloat32Array(); d.resize(n)
	var lp := 0.0
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		# craquement initial
		var crack := rng.randf_range(-1.0, 1.0) * exp(-t * 14.0) * 0.9
		# souffle grave : bruit filtré dont la coupure baisse
		var a := clampf(0.5 * exp(-t * 0.9) + 0.012, 0.01, 0.5)
		lp += (rng.randf_range(-1.0, 1.0) - lp) * a
		var rumble := lp * 2.4 * exp(-t * 0.55)
		# sub qui descend de 60 à 22 Hz
		var f := 22.0 + 38.0 * exp(-t * 0.9)
		ph += TAU * f / RATE
		var sub := sin(ph) * 0.9 * exp(-t * 0.45)
		var v := crack + rumble + sub
		d[i] = tanh(v * 1.3) * clampf(t * 90.0, 0.0, 1.0)
	s_boom = _wav(d)

func _make_ring() -> void:
	var n := RATE * 5
	var d := PackedFloat32Array(); d.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 0.8) * clampf(t * 40.0, 0.0, 1.0)
		d[i] = (sin(TAU * 3150.0 * t) * 0.6 + sin(TAU * 3290.0 * t) * 0.4) * env * 0.22
	s_ring = _wav(d)

func _make_wind() -> void:
	var n := RATE * 8
	var d := PackedFloat32Array(); d.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var env := clampf(t / 1.8, 0.0, 1.0) * exp(-maxf(t - 1.8, 0.0) * 0.55)
		lp += (rng.randf_range(-1.0, 1.0) - lp) * (0.05 + 0.06 * env)
		d[i] = tanh(lp * 3.0 * env) * 0.8
	s_wind = _wav(d)
