extends Interactable
class_name PhotoMidwayItem

## Photo aérienne punaisée au tableau en liège (date 7 : Midway).

const DATE_ID := "midway_1942"

func _ready() -> void:
	_refresh()
	GameManager.date_unlocked.connect(func(_i, _d): _refresh())
	GameManager.game_loaded.connect(_refresh)
	GameManager.item_obtained.connect(func(_a, _b): _refresh())

func _refresh() -> void:
	if GameManager.is_date_unlocked(DATE_ID):
		prompt_message = "Revoir la photo aérienne (Midway)"
	elif GameManager.has_item("loupe"):
		prompt_message = "Examiner la photo aérienne à la loupe"
	else:
		prompt_message = "Examiner la photo aérienne du Pacifique"

func interact() -> void:
	super.interact()
	get_tree().call_group("enigma_midway", "open_photo")
