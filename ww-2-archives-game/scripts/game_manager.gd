extends Node

## GameManager (Singleton / Autoload)
## Gère l'état global du jeu, la progression des 15 dates et le changement d'ambiance/période.

signal date_unlocked(date_id: String, date_info: Dictionary)
signal period_changed(new_period: int)
signal all_dates_completed

const DATES_PER_PERIOD: int = 5
const TOTAL_DATES: int = 15

var unlocked_dates: Array[String] = []
var current_period: int = 1

func _ready() -> void:
	print("[GameManager] Démarrage du système d'archives WW2")

## Tente de débloquer une date à partir de son identifiant
func unlock_date(date_id: String) -> bool:
	if not HistoricalData.DATES.has(date_id):
		push_warning("[GameManager] Date inconnue : " + date_id)
		return false
	
	if unlocked_dates.has(date_id):
		# Déjà découverte, on peut quand même réafficher la fiche d'archives
		var info = HistoricalData.get_date_info(date_id)
		date_unlocked.emit(date_id, info)
		return false
	
	# Nouvelle date découverte !
	unlocked_dates.append(date_id)
	var date_info = HistoricalData.get_date_info(date_id)
	print("[GameManager] Nouvelle date découverte : %s (%s/15)" % [date_info.get("title", date_id), unlocked_dates.size()])
	
	date_unlocked.emit(date_id, date_info)
	
	_check_period_progress()
	
	if unlocked_dates.size() >= TOTAL_DATES:
		all_dates_completed.emit()
		print("[GameManager] Toutes les 15 dates historiques ont été trouvées !")
	
	return true

func is_date_unlocked(date_id: String) -> bool:
	return unlocked_dates.has(date_id)

func get_unlocked_count() -> int:
	return unlocked_dates.size()

func get_period_unlocked_count(p_period: int) -> int:
	var count = 0
	for date_id in unlocked_dates:
		var info = HistoricalData.get_date_info(date_id)
		if info.get("period", 0) == p_period:
			count += 1
	return count

func _check_period_progress() -> void:
	# Passage à la période 2 quand 5 dates de la période 1 sont trouvées
	if current_period == 1 and get_period_unlocked_count(1) >= DATES_PER_PERIOD:
		_set_period(2)
	# Passage à la période 3 quand 5 dates de la période 2 sont trouvées
	elif current_period == 2 and get_period_unlocked_count(2) >= DATES_PER_PERIOD:
		_set_period(3)

func _set_period(new_period: int) -> void:
	if current_period != new_period:
		current_period = new_period
		print("[GameManager] Changement de période ! Entrée dans la période : ", new_period)
		period_changed.emit(new_period)

func reset_game() -> void:
	unlocked_dates.clear()
	current_period = 1
	period_changed.emit(1)
