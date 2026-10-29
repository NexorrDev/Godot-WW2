extends Node3D

## Contrôleur de la scène principale
## Connecte le menu principal, le joueur et le HUD de progression.

@onready var main_menu: CanvasLayer = $MainMenu
@onready var joueur: CharacterBody3D = $Joueur
@onready var hud: CanvasLayer = $HUDProgression

func _ready() -> void:
	# Démarre les sons (ambiance de bureau, clics de boutons...)
	Sfx.ensure()
	if main_menu:
		main_menu.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	if joueur:
		joueur.start_game()
	if hud and hud.has_method("show_hud"):
		hud.show_hud()
