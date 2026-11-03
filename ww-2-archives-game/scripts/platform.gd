extends RefCounted
class_name Platform

## Détection de la plateforme : téléphone/tablette (commandes tactiles) ou PC (clavier + souris).
## Pour forcer le mode tactile sur PC (tests) : lancer avec l'argument `--touch`,
## ou mettre la variable d'environnement ARCHIVES_TOUCH=1. `--desktop` force le mode PC.

static var _cached: int = -1

static func is_mobile() -> bool:
	if _cached >= 0:
		return _cached == 1
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	var mobile := false
	if "--desktop" in args:
		mobile = false
	elif "--touch" in args or OS.get_environment("ARCHIVES_TOUCH") == "1":
		mobile = true
	elif OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		mobile = true
	elif OS.has_feature("web"):
		# Navigateur : on regarde si c'est un appareil tactile de type téléphone/tablette
		var r = JavaScriptBridge.eval("(navigator.maxTouchPoints > 0) && /Android|iPhone|iPad|iPod|Mobi|Tablet/i.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)", true)
		mobile = bool(r)
	_cached = 1 if mobile else 0
	return mobile
