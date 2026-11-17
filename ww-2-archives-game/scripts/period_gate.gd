extends RefCounted
class_name PeriodGate

## Fil narratif : les objets des périodes suivantes sont déjà visibles dans la salle,
## mais on ne peut pas interagir avec tant que la période précédente n'est pas terminée.
## Période 1 (matin) : dates 1-5 ; période 2 (midi) : dates 6-10 ; période 3 (soir) : dates 11-15.

static func bind(node: Node3D, period: int) -> void:
	var refresh := func():
		var open: bool = GameManager.current_period >= period
		_lock(node, not open)
	GameManager.period_changed.connect(func(_p): refresh.call())
	GameManager.game_loaded.connect(refresh)
	refresh.call()

static func _lock(n: Node, value: bool) -> void:
	if n is Interactable:
		n.locked = value
	for c in n.get_children():
		_lock(c, value)
