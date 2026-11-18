extends Node
class_name Music

## Musique d'ambiance en boucle (menu + jeu). Se crée toute seule au premier appel : Music.ensure().
##   Music.duck(true/false)      : baisse la musique (radio, cinématique...)
##   Music.set_level(db, duree)  : change le volume en fondu
##   Music.fade_out(duree)       : coupe en fondu

const TRACK := "res://assets/sounds/music_ambiance.mp3"
const NORMAL_DB := -13.0
const DUCKED_DB := -26.0

static var instance: Music = null

var player: AudioStreamPlayer
var tween: Tween = null
var base_db := NORMAL_DB
var ducked := false

static func ensure() -> void:
	if instance != null and is_instance_valid(instance):
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	instance = Music.new()
	instance.name = "Music"
	tree.root.add_child.call_deferred(instance)

static func duck(on: bool) -> void:
	ensure()
	if instance != null and instance.is_inside_tree():
		instance.ducked = on
		instance._fade(DUCKED_DB if on else instance.base_db, 0.6)

static func set_level(db: float, duration: float = 1.5) -> void:
	ensure()
	if instance != null and instance.is_inside_tree():
		instance.base_db = db
		instance._fade(db, duration)

static func fade_out(duration: float = 2.0) -> void:
	if instance != null and is_instance_valid(instance) and instance.is_inside_tree():
		instance._fade(-60.0, duration)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var stream = load(TRACK)
	if stream == null:
		push_warning("Musique introuvable : " + TRACK)
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -50.0
	player.autoplay = false
	add_child(player)
	player.play()
	_fade(base_db, 4.0)

func _fade(db: float, duration: float) -> void:
	if player == null:
		return
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(player, "volume_db", db, duration)
