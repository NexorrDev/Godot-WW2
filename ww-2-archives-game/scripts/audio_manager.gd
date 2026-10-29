extends Node
class_name Sfx

## Sons du jeu, tous générés par code (aucun fichier audio à importer).
## Utilisation depuis n'importe quel script :  Sfx.play("stamp")
##
## - clic / survol : branchés automatiquement sur TOUS les boutons du jeu (menus, carnet, radio...)
## - papier : ouverture / fermeture des fiches et du carnet
## - stamp : tampon quand une archive est classée
## - pause : ouverture / fermeture du menu pause
## - step : bruits de pas sur plancher, talon puis pointe (appelé par le joueur)
## - ambiance de bureau très discrète en boucle (souffle grave, sans note continue ni tic-tac)
##
## Le nœud se crée tout seul au premier appel (Sfx.ensure()), aucun Autoload à déclarer.

const RATE: int = 22050
const AMBIENT_RATE: int = 16000
const AMBIENT_DB: float = -32.0
const AMBIENT_DUCKED_DB: float = -44.0
const POOL_SIZE: int = 10
const STEP_VARIANTS: int = 5

static var instance: Sfx = null

var sounds: Dictionary = {}
var pool: Array[AudioStreamPlayer] = []
var ambient: AudioStreamPlayer
var duck_tween: Tween = null
var rng := RandomNumberGenerator.new()

# ---------------------------------------------------------------------------
# API statique
# ---------------------------------------------------------------------------

static func ensure() -> void:
	if instance != null and is_instance_valid(instance):
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	instance = Sfx.new()
	instance.name = "Sfx"
	tree.root.add_child.call_deferred(instance)

## Joue un son. pitch_var = variation aléatoire de hauteur (0.05 = ±5 %).
static func play(sound: String, volume_db: float = 0.0, pitch_var: float = 0.0) -> void:
	ensure()
	if instance != null and instance.is_inside_tree():
		instance._play(sound, volume_db, pitch_var)

## Baisse l'ambiance (ex. pendant l'écoute de la radio) puis la remonte
static func duck_ambient(on: bool) -> void:
	ensure()
	if instance != null and instance.is_inside_tree():
		instance._duck(on)

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.seed = 1939
	_build_sounds()

	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)

	ambient = AudioStreamPlayer.new()
	ambient.stream = sounds["room_tone"]
	ambient.volume_db = AMBIENT_DB
	add_child(ambient)
	ambient.play()

	# Tous les boutons, présents ou à venir, font du bruit
	get_tree().node_added.connect(_on_node_added)
	_hook_existing(get_tree().root)

func _hook_existing(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node)
	for child in node.get_children():
		_hook_existing(child)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node)

func _hook_button(btn: BaseButton) -> void:
	if btn.has_meta("sfx_hooked"):
		return
	btn.set_meta("sfx_hooked", true)
	btn.pressed.connect(func(): _play("click", -2.0, 0.04))
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			_play("hover", -9.0, 0.03)
	)

# ---------------------------------------------------------------------------
# Lecture
# ---------------------------------------------------------------------------

func _play(sound: String, volume_db: float, pitch_var: float) -> void:
	var key := sound
	if sound == "step":
		key = "step%d" % rng.randi_range(0, STEP_VARIANTS - 1)
	if not sounds.has(key):
		return
	var player: AudioStreamPlayer = null
	for p in pool:
		if not p.playing:
			player = p
			break
	if player == null:
		player = pool[0]
	player.stream = sounds[key]
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + rng.randf_range(-pitch_var, pitch_var)
	player.play()

func _duck(on: bool) -> void:
	if duck_tween and duck_tween.is_valid():
		duck_tween.kill()
	duck_tween = create_tween()
	duck_tween.tween_property(ambient, "volume_db", AMBIENT_DUCKED_DB if on else AMBIENT_DB, 0.5)

# ---------------------------------------------------------------------------
# Synthèse des sons
# ---------------------------------------------------------------------------

func _build_sounds() -> void:
	sounds["hover"] = _make_wav(_gen_hover())
	sounds["click"] = _make_wav(_gen_click())
	sounds["paper_open"] = _make_wav(_gen_paper(0.5, 0.62))
	sounds["paper_close"] = _make_wav(_gen_paper(0.3, 0.45))
	sounds["stamp"] = _make_wav(_gen_stamp())
	sounds["pause"] = _make_wav(_gen_thud(0.3, 95.0, 0.7))
	for i in STEP_VARIANTS:
		sounds["step%d" % i] = _make_wav(_gen_step())
	sounds["room_tone"] = _make_wav(_gen_room_tone(), AMBIENT_RATE, true)

func _make_wav(data: PackedFloat32Array, rate: int = RATE, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size()
	return w

func _white() -> float:
	return rng.randf() * 2.0 - 1.0

## Survol : petit "tic" aigu et doux
func _gen_hover() -> PackedFloat32Array:
	var n := int(RATE * 0.05)
	var d := PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t := float(i) / RATE
		d[i] = sin(TAU * 1350.0 * t) * exp(-t * 110.0) * 0.35
	return d

## Clic : touche de machine à écrire (claquement sec + petit choc grave)
func _gen_click() -> PackedFloat32Array:
	var n := int(RATE * 0.09)
	var d := PackedFloat32Array()
	d.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (_white() - lp) * 0.25
		d[i] = lp * exp(-t * 90.0) * 0.9 + sin(TAU * 170.0 * t) * exp(-t * 55.0) * 0.45
	return d

## Papier : froissement filtré (bruit aigu, enveloppe en cloche)
func _gen_paper(duration: float, gain: float) -> PackedFloat32Array:
	var n := int(RATE * duration)
	var d := PackedFloat32Array()
	d.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var w := _white()
		lp += (w - lp) * 0.6
		var hp := w - lp
		var env := pow(sin(PI * t / duration), 1.4) * (0.55 + 0.45 * absf(sin(t * 38.0 + sin(t * 9.0) * 2.0)))
		d[i] = hp * env * gain
	return d

## Tampon : choc grave qui descend + claquement + léger métal
func _gen_stamp() -> PackedFloat32Array:
	var n := int(RATE * 0.55)
	var d := PackedFloat32Array()
	d.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += TAU * (60.0 + 90.0 * exp(-t * 28.0)) / RATE
		lp += (_white() - lp) * 0.3
		d[i] = sin(phase) * exp(-t * 9.0) * 0.9 + lp * exp(-t * 160.0) * 0.7 + sin(TAU * 420.0 * t) * exp(-t * 35.0) * 0.12
	return d

## Choc sourd (pause)
func _gen_thud(duration: float, freq: float, gain: float) -> PackedFloat32Array:
	var n := int(RATE * duration)
	var d := PackedFloat32Array()
	d.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (_white() - lp) * 0.08
		d[i] = sin(TAU * freq * t) * exp(-t * 18.0) * gain + lp * exp(-t * 40.0) * 0.3
	return d

## Pas sur un plancher : un talon (choc sourd + petit "toc" médium) puis la pointe, plus douce.
## Uniquement du bruit filtré, sans note pure : pas de côté creux ni métallique.
func _gen_step() -> PackedFloat32Array:
	var n := int(RATE * 0.30)
	var d := PackedFloat32Array()
	d.resize(n)
	
	var toe_delay := int(RATE * rng.randf_range(0.075, 0.105))
	var heel_gain := rng.randf_range(0.85, 1.0)
	var toe_gain := rng.randf_range(0.35, 0.55)
	var body_a := rng.randf_range(0.035, 0.055)   # fréquence de coupure du choc sourd (~120 à 190 Hz)
	
	_add_footfall(d, 0, heel_gain, body_a, 1.0)
	_add_footfall(d, toe_delay, toe_gain, body_a * 1.25, 0.7)
	
	# Normalisation douce : tous les pas ont le même niveau de crête
	var peak := 0.0
	for v in d:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		for i in n:
			d[i] = d[i] / peak * 0.8
	return d

func _add_footfall(d: PackedFloat32Array, start: int, gain: float, body_a: float, knock: float) -> void:
	var lp1 := 0.0
	var lp2 := 0.0
	var mid_lo := 0.0
	var mid_hi := 0.0
	for i in range(start, d.size()):
		var t := float(i - start) / RATE
		var w := _white()
		# Corps : bruit filtré deux fois vers le grave
		lp1 += (w - lp1) * body_a
		lp2 += (lp1 - lp2) * body_a
		# "Toc" médium : bande étroite autour de 300-900 Hz
		mid_lo += (w - mid_lo) * 0.11
		mid_hi += (w - mid_hi) * 0.035
		var mid := mid_lo - mid_hi
		var attack := 1.0 - exp(-t * 1200.0)
		d[i] += attack * (lp2 * 4.5 * exp(-t * 32.0) + mid * knock * 3.4 * exp(-t * 52.0)) * gain

## Ambiance de bureau : simple souffle grave et doux (aucune note continue, aucun tic-tac).
## Toutes les fréquences font un nombre entier de cycles sur la boucle : aucun "clic" au raccord.
func _gen_room_tone() -> PackedFloat32Array:
	var duration := 2.0
	var n := int(AMBIENT_RATE * duration)
	var d := PackedFloat32Array()
	d.resize(n)

	var freqs := PackedFloat32Array()
	var phases := PackedFloat32Array()
	for k in 24:
		freqs.append(float(rng.randi_range(120, 560)) / duration)  # 60 à 280 Hz
		phases.append(rng.randf() * TAU)

	for i in n:
		var t := float(i) / AMBIENT_RATE
		var v := 0.0
		for j in freqs.size():
			v += sin(TAU * freqs[j] * t + phases[j]) * 0.006
		d[i] = v
	return d
