extends Interactable
class_name RadioItem

## Objet 3D représentant le vieux poste de radio T.S.F. (Date 2 - 3 Septembre 1939)
## Lorsqu'on interagit avec, il ouvre l'interface de syntonisation sur la BBC (390 kHz).

func _ready() -> void:
	prompt_message = "Syntoniser : Poste de radio T.S.F."
	# Écoute si la date 2 a déjà été trouvée
	if GameManager.is_date_unlocked("declaration_guerre_1939"):
		prompt_message = "Réécouter : Déclaration de guerre (3 Septembre 1939)"

func interact() -> void:
	super.interact()
	# Si déjà résolu, on peut ouvrir soit le viewer direct, soit l'interface radio
	get_tree().call_group("enigma_radio", "open_radio")
