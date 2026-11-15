extends Interactable
class_name ChaiseItem

## Chaise qu'on pousse (glisse) contre l'étagère pour atteindre la boîte « Méditerranée » (date 10).

const DATE_ID := "sicile_1943"
@export var start_z := -1.9
@export var pushed_z := -2.55
var pushed := false

func _ready() -> void:
	add_to_group("chaise_etagere")
	GameManager.game_loaded.connect(_sync)
	GameManager.date_unlocked.connect(func(_i, _d): _sync())
	_sync()

func _sync() -> void:
	if GameManager.is_date_unlocked(DATE_ID) and not pushed:
		pushed = true
		position.z = pushed_z
	prompt_message = "La chaise est contre l'étagère" if pushed else "Faire glisser la chaise vers l'étagère"

func interact() -> void:
	super.interact()
	if pushed:
		return
	pushed = true
	Sfx.play("click", -4.0, 0.2)
	create_tween().tween_property(self, "position:z", pushed_z, 0.9).set_trans(Tween.TRANS_SINE)
	prompt_message = "La chaise est contre l'étagère"
	get_tree().call_group("hud_progression", "show_info", "CHAISE", "Elle est maintenant sous l'étagère.")
