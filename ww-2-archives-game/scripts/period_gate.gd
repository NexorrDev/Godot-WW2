extends RefCounted
class_name PeriodGate

## Fil narratif : les objets d'une période n'existent (visibles et utilisables) que quand cette période est atteinte.
## Période 1 (matin) : dates 1-5 ; période 2 (midi / après-midi) : dates 6-10 ; période 3 (soir) : dates 11-15.
## On désactive le nœud (process_mode DISABLED) : ses collisions sortent du monde physique, donc plus de visée possible.

static func bind(node: Node3D, period: int) -> void:
	var refresh := func():
		var open: bool = GameManager.current_period >= period
		node.visible = open
		node.process_mode = Node.PROCESS_MODE_INHERIT if open else Node.PROCESS_MODE_DISABLED
	GameManager.period_changed.connect(func(_p): refresh.call())
	GameManager.game_loaded.connect(refresh)
	refresh.call()
