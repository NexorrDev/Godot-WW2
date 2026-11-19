extends RefCounted
class_name PeriodGate

## Fil narratif : les objets des périodes suivantes sont déjà visibles dans la salle,
## mais on ne peut pas interagir avec tant que la période précédente n'est pas terminée.
## Période 1 (matin) : dates 1-5 ; période 2 (midi) : dates 6-10 ; période 3 (soir) : dates 11-15.

static func bind(node: Node3D, period: int) -> void:
	var refresh := func():
		if not is_instance_valid(node):
			return
		var open: bool = GameManager.current_period >= period
		_lock(node, not open)
	var on_period := func(_p): refresh.call()
	GameManager.period_changed.connect(on_period)
	GameManager.game_loaded.connect(refresh)
	# la scène peut être rechargée (retour au menu) : on se débranche pour ne pas viser un nœud libéré
	node.tree_exiting.connect(func():
		if GameManager.period_changed.is_connected(on_period):
			GameManager.period_changed.disconnect(on_period)
		if GameManager.game_loaded.is_connected(refresh):
			GameManager.game_loaded.disconnect(refresh))
	refresh.call()

static func _lock(n: Node, value: bool) -> void:
	if not is_instance_valid(n):
		return
	if n is Interactable:
		n.locked = value
	for c in n.get_children():
		_lock(c, value)
