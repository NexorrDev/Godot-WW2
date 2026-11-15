extends OverlayBase

## Date 11 : 6 juin 1944, débarquement de Normandie.
## 5 photos de plages à relier (clic photo, puis clic secteur) par un fil rouge au bon secteur.

const DATE_ID := "normandie_1944"
const PHOTOS := [
	{"id": "omaha", "title": "PHOTO A", "txt": "Troupes américaines (1re et 29e division). Falaises, plage hérissée d'obstacles : les pertes sont très lourdes."},
	{"id": "juno", "title": "PHOTO B", "txt": "Troupes canadiennes (3e division) devant Courseulles-sur-Mer."},
	{"id": "utah", "title": "PHOTO C", "txt": "Troupes américaines (4e division) à l'extrémité ouest, dunes et marais derrière la plage : débarquement le moins coûteux."},
	{"id": "sword", "title": "PHOTO D", "txt": "Britanniques (3e division) et commandos français du commandant Kieffer, près d'Ouistreham, à l'extrémité est."},
	{"id": "gold", "title": "PHOTO E", "txt": "Troupes britanniques (50e division), secteur central : Arromanches et son futur port artificiel."},
]
const SECTORS := [
	{"id": "utah", "txt": "UTAH — secteur américain, tout à l'ouest"},
	{"id": "omaha", "txt": "OMAHA — secteur américain, entre Vierville et Colleville"},
	{"id": "gold", "txt": "GOLD — secteur britannique, au centre"},
	{"id": "juno", "txt": "JUNO — secteur canadien"},
	{"id": "sword", "txt": "SWORD — secteur britannique, tout à l'est"},
]

var links := {}          # index photo -> index secteur
var sel_photo := -1
var photo_btns: Array[Button] = []
var sector_btns: Array[Button] = []
var board: Control

func _init() -> void:
	super("enigma_normandie", "TABLEAU — LES CINQ PLAGES DU 6 JUIN 1944")
	_min_width = 900.0

func _build_content() -> void:
	vb.add_child(hint("Relie chaque photo à son secteur de débarquement avec un fil rouge : clique d'abord sur une photo, puis sur le secteur correspondant. Relis bien les indices (nationalité, relief, lieu)."))
	board = Control.new()
	board.custom_minimum_size = Vector2(900, 380)
	board.draw.connect(_draw_threads)
	vb.add_child(board)
	for i in PHOTOS.size():
		var b := Button.new()
		b.text = PHOTOS[i]["title"] + "\n" + PHOTOS[i]["txt"]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.size = Vector2(420, 66)
		b.position = Vector2(0, i * 76)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", UIStyle.font_mono())
		b.add_theme_font_size_override("font_size", 13)
		b.pressed.connect(func(): _pick_photo(i))
		board.add_child(b)
		photo_btns.append(b)
	for j in SECTORS.size():
		var s := Button.new()
		s.text = SECTORS[j]["txt"]
		s.size = Vector2(420, 56)
		s.position = Vector2(480, j * 76 + 5)
		s.add_theme_font_override("font", UIStyle.font_mono())
		s.add_theme_font_size_override("font_size", 14)
		s.pressed.connect(func(): _pick_sector(j))
		board.add_child(s)
		sector_btns.append(s)

func _build_buttons(row: HBoxContainer) -> void:
	var ok := UIStyle.make_menu_button("Valider le tableau")
	ok.pressed.connect(_validate)
	row.add_child(ok)
	var reset := UIStyle.make_menu_button("Tout défaire")
	reset.pressed.connect(func():
		links.clear()
		sel_photo = -1
		_refresh()
		say(""))
	row.add_child(reset)

func _on_open() -> void:
	solved = GameManager.is_date_unlocked(DATE_ID)
	if solved:
		links.clear()
		for i in PHOTOS.size():
			for j in SECTORS.size():
				if SECTORS[j]["id"] == PHOTOS[i]["id"]:
					links[i] = j
	else:
		links.clear()
	sel_photo = -1
	say("Les cinq plages du débarquement : Utah, Omaha, Gold, Juno, Sword.")
	_refresh()

func _pick_photo(i: int) -> void:
	if solved:
		return
	Sfx.play("click", -8.0)
	if links.has(i):
		links.erase(i)
		sel_photo = -1
	else:
		sel_photo = i
	_refresh()

func _pick_sector(j: int) -> void:
	if solved or sel_photo < 0:
		return
	for k in links.keys():
		if links[k] == j:
			links.erase(k)
	links[sel_photo] = j
	sel_photo = -1
	Sfx.play("click", -5.0, 0.15)
	_refresh()

func _refresh() -> void:
	for i in photo_btns.size():
		photo_btns[i].modulate = Color(1, 0.8, 0.6) if i == sel_photo else (Color(0.8, 1, 0.8) if links.has(i) else Color.WHITE)
	for j in sector_btns.size():
		sector_btns[j].modulate = Color(0.8, 1, 0.8) if links.values().has(j) else Color.WHITE
	board.queue_redraw()

func _draw_threads() -> void:
	for i in links:
		var a := Vector2(420, i * 76 + 33)
		var b := Vector2(480, links[i] * 76 + 33)
		board.draw_line(a, b, Color(0.75, 0.08, 0.08), 4.0)
		board.draw_circle(a, 7, Color(0.9, 0.15, 0.15))
		board.draw_circle(b, 7, Color(0.9, 0.15, 0.15))

func _validate() -> void:
	if solved:
		finish(DATE_ID)
		return
	if links.size() < PHOTOS.size():
		say("Il reste des photos sans fil rouge.")
		return
	var wrong := 0
	for i in links:
		if SECTORS[links[i]]["id"] != PHOTOS[i]["id"]:
			wrong += 1
	if wrong == 0:
		say("Les cinq plages sont correctement reliées. Opération Overlord : l'ordre du jour d'Eisenhower est dans le dossier.", true)
		get_tree().create_timer(1.0).timeout.connect(func():
			if is_open:
				finish(DATE_ID))
	else:
		Sfx.play("click", -3.0, 0.3)
		say("%d fil(s) mal placé(s). Reprends les indices : nationalité des troupes, falaises ou dunes, position ouest/est." % wrong)
