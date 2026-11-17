extends CollisionObject3D
class_name Interactable

## Composant pour rendre n'importe quel objet 3D interactif avec la touche E.
## Il suffit d'attacher ce script à un StaticBody3D ou Area3D.

@export var prompt_message: String = "Examiner"

## Verrouillé par le fil narratif (PeriodGate) : l'objet reste visible mais on ne peut pas encore interagir avec.
var locked := false

signal interacted()

func interact() -> void:
	interacted.emit()
