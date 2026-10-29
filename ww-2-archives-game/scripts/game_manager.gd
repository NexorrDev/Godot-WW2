extends Node

## GameManager (Singleton / Autoload)
## Gère l'état global du jeu, la progression des 15 dates et le changement d'ambiance/période.

signal date_unlocked(date_id: String, date_info: Dictionary)
signal period_changed(new_period: int)
signal all_dates_completed

## Émis après le chargement d'une sauvegarde (le HUD et les objets se remettent à jour)
signal game_loaded

const DATES_PER_PERIOD: int = 5
const TOTAL_DATES: int = 15
const SAVE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 1

var unlocked_dates: Array[String] = []
var current_period: int = 1
## Vrai pendant un chargement : le HUD n'affiche alors aucune bannière
var is_loading: bool = false

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
	save_game()

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

## Remet l'état en mémoire à zéro. Ne touche PAS au fichier de sauvegarde
## (voir delete_save() pour une vraie nouvelle partie).
func reset_game() -> void:
	unlocked_dates.clear()
	current_period = 1
	period_changed.emit(1)

# ---------------------------------------------------------------------------
# Sauvegarde / chargement (user://savegame.json, écrit à chaque date découverte)
# ---------------------------------------------------------------------------

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("[GameManager] Sauvegarde impossible : %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify({
		"version": SAVE_VERSION,
		"unlocked_dates": unlocked_dates,
	}))

## Lit le fichier et renvoie les identifiants valides, ou null si aucune sauvegarde exploitable
func _read_save() -> Variant:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return null
	var data = JSON.parse_string(file.get_as_text())
	if not (data is Dictionary) or not (data.get("unlocked_dates") is Array):
		return null
	var ids: Array[String] = []
	for id in data["unlocked_dates"]:
		if id is String and HistoricalData.DATES.has(id) and not ids.has(id):
			ids.append(id)
	return ids

## Nombre de dates de la sauvegarde (0 si aucune sauvegarde valide)
func get_saved_count() -> int:
	var ids = _read_save()
	return 0 if ids == null else ids.size()

func has_save() -> bool:
	return get_saved_count() > 0

func load_game() -> bool:
	var ids = _read_save()
	if ids == null or ids.is_empty():
		return false
	is_loading = true
	unlocked_dates = ids
	current_period = 1
	if get_period_unlocked_count(1) >= DATES_PER_PERIOD:
		current_period = 2
		if get_period_unlocked_count(2) >= DATES_PER_PERIOD:
			current_period = 3
	period_changed.emit(current_period)
	game_loaded.emit()
	is_loading = false
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
