extends RefCounted
class_name HintData

## Indices pour chaque date : niveau 1 = où chercher, niveau 2 = la solution.
## (Ordre = ordre des 15 dates ; les clés sont les identifiants de HistoricalData.)

const HINTS: Dictionary = {
	"pologne_1939": ["Un dossier « TOP SECRET » fermé par un cachet de cire est posé sur le bureau. Il faut un outil pour l'ouvrir.",
		"Ramasse les ciseaux posés sur le bureau (côté droit), puis utilise-les sur le dossier au cachet rouge."],
	"declaration_guerre_1939": ["Un poste de radio est posé sur une petite table près du bureau, avec une note d'instructions à lire.",
		"Ouvre la radio et règle la fréquence sur 390 kHz (BBC Londres), puis écoute l'annonce."],
	"offensive_ouest_1940": ["Le sous-main vert sur le bureau cache une carte d'Europe.",
		"Soulève le sous-main, puis place les 3 pions sur les zones de l'offensive allemande de mai 1940 : Pays-Bas, Belgique et Ardennes (percée de Sedan)."],
	"armistice_1940": ["Une pendule est accrochée au mur et une corbeille à papier est posée par terre, le long du même mur. Fouille la corbeille.",
		"Le brouillon de la corbeille donne l'heure de la signature de l'armistice : 18 h 36. Va à la pendule et règle les aiguilles sur 18 h 36 (petite aiguille entre le 6 et le 7, grande aiguille sur le 36)."],
	"barbarossa_1941": ["Au fond de la pièce, le classeur vert a un tiroir fermé par un cadenas. Un mémo est posé dessus : lis-le.",
		"Le code est l'année qui suit l'armistice de 1940 : 1941. Entre 1-9-4-1 sur le cadenas du tiroir du milieu."],
	"pearl_harbor_1941": ["Dans un coin de la pièce, une machine à écrire est posée sur un meuble, avec un calendrier bloqué sur décembre 1941. Examine-les.",
		"Le mot de code de l'attaque est TORA (« tigre » en japonais). Utilise la machine à écrire et tape T-O-R-A."],
	"midway_1942": ["Une photo aérienne du Pacifique est accrochée sur le mur du fond. À l'œil nu, les navires ne sont que des points : il faut un instrument grossissant.",
		"Ramasse la loupe, posée sur la petite table de la radio, puis examine la photo. Déplace la loupe et clique sur le porte-avions japonais en flammes (l'Akagi, à droite de la photo)."],
	"el_alamein_1942": ["Contre le mur de la machine à écrire : une boussole est posée sur un tabouret et un ordre de mission est accroché au mur juste au-dessus. Lis l'ordre.",
		"L'ordre dit « CAP : SE » (Sud-Est, vers le canal de Suez). Maintiens le clic pour tourner l'aiguille vers le Sud-Est (entre l'Est et le Sud, environ 135°), puis valide."],
	"stalingrad_1943": ["Un portemanteau près du mur porte une veste militaire allemande. Fouille ses poches.",
		"La lettre est dans la poche de poitrine (celle du milieu), prise dans la glace : maintiens le clic dessus jusqu'à ce qu'elle dégèle."],
	"sicile_1943": ["Tout en haut de l'étagère, une boîte « MÉDITERRANÉE » est hors d'atteinte. Une chaise est posée à proximité.",
		"Interagis avec la chaise pour la faire glisser contre l'étagère, puis consulte la boîte."],
	"normandie_1944": ["Un tableau en liège sur le mur porte cinq photos de plages (A à E) et cinq secteurs à relier.",
		"A = Omaha (américains, falaises) · B = Juno (canadiens) · C = Utah (américains, dunes, à l'ouest) · D = Sword (britanniques et commandos français, à l'est) · E = Gold (britanniques, au centre)."],
	"bagration_1944": ["Un tampon encreur d'état-major est posé près du bureau, et un dossier d'état-major attend d'être tamponné. Ramasse d'abord le tampon.",
		"Bagration est une offensive soviétique : tamponne le dossier de l'Armée rouge (K.A.)."],
	"elbe_1945": ["Un cadre photo est posé face contre la table, près du bureau. Retourne-le.",
		"Fais glisser les deux moitiés l'une contre l'autre pour raccorder la déchirure : on doit voir la poignée de main entre un soldat américain et un soldat soviétique."],
	"capitulation_1945": ["Un coffre-fort est dans un coin du fond de la pièce. Une note est punaisée au mur juste à côté : lis-la.",
		"Le code est l'année de la jonction sur l'Elbe : 1945. Règle les chiffres sur 1-9-4-5."],
	"hiroshima_1945": ["Prends le dossier noir « PROJET MANHATTAN » dans le coffre ouvert, puis regarde l'horloge arrêtée sur le mur du fond. La table de classement attend le dossier.",
		"L'horloge est arrêtée sur 8 h 15 : à la table centrale, entre 0-8-1-5 pour classer le dossier."],
}
