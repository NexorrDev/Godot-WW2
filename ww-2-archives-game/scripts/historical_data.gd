extends RefCounted
class_name HistoricalData

## Données historiques officielles des 15 dates (conformes à la feuille de cours)
## Chaque entrée comporte : date précise, événement, lieu, explication avec vocabulaire du cours.

const DATES: Dictionary = {
	# =========================================================================
	# PÉRIODE 1 : LES VICTOIRES DE L'AXE (1939-1941)
	# =========================================================================
	"pologne_1939": {
		"id": "pologne_1939",
		"period": 1,
		"period_title": "PÉRIODE 1 : LES VICTOIRES DE L'AXE (1939-1941)",
		"date_str": "1er Septembre 1939",
		"title": "Invasion de la Pologne",
		"location": "Pologne (frontière germano-polonaise, Varsovie)",
		"summary": "La [b]Wehrmacht[/b] envahit la Pologne en appliquant la tactique du [b]Blitzkrieg[/b] (guerre-éclair). Cette agression marque le déclenchement de la Seconde Guerre mondiale en Europe.",
		"object_name": "Dossier militaire scellé 'TOP SECRET'"
	},
	"declaration_guerre_1939": {
		"id": "declaration_guerre_1939",
		"period": 1,
		"period_title": "PÉRIODE 1 : LES VICTOIRES DE L'AXE (1939-1941)",
		"date_str": "3 Septembre 1939",
		"title": "Déclaration de guerre de la France et du Royaume-Uni",
		"location": "Paris et Londres (Europe de l'Ouest)",
		"summary": "En réponse à l'invasion de la Pologne, la France et le Royaume-Uni déclarent la guerre à l'[b]Axe[/b], mais adoptent une stratégie défensive passive derrière la ligne Maginot : c'est le début de la [b]« drôle de guerre »[/b].",
		"object_name": "Poste de radio militaire"
	},
	"offensive_ouest_1940": {
		"id": "offensive_ouest_1940",
		"period": 1,
		"period_title": "PÉRIODE 1 : LES VICTOIRES DE L'AXE (1939-1941)",
		"date_str": "10 Mai 1940",
		"title": "Offensive allemande à l'Ouest",
		"location": "Pays-Bas, Belgique, Luxembourg et Ardennes (France)",
		"summary": "Hitler met fin à l'attente en lançant ses blindés à travers les Ardennes. En quelques semaines, l'armée française est mise en déroute, provoquant l'évacuation de Dunkerque et l'exode de millions de civils.",
		"object_name": "Carte d'état-major sous le buvard"
	},
	"armistice_1940": {
		"id": "armistice_1940",
		"period": 1,
		"period_title": "PÉRIODE 1 : LES VICTOIRES DE L'AXE (1939-1941)",
		"date_str": "22 Juin 1940",
		"title": "Signature de l'armistice franco-allemand",
		"location": "Clairière de Rethondes (forêt de Compiègne, France)",
		"summary": "La France, à moitié envahie, capitule et signe l'armistice dans le même wagon qu'en 1918. Le pays est coupé en deux et le Royaume-Uni de Winston Churchill se retrouve désormais seul face à l'Allemagne.",
		"object_name": "Pendule murale d'archives"
	},
	"barbarossa_1941": {
		"id": "barbarossa_1941",
		"period": 1,
		"period_title": "PÉRIODE 1 : LES VICTOIRES DE L'AXE (1939-1941)",
		"date_str": "22 Juin 1941",
		"title": "Opération Barbarossa (Invasion de l'URSS)",
		"location": "Frontière orientale, Union Soviétique (vers Moscou et Leningrad)",
		"summary": "Rompant le pacte germano-soviétique, Hitler lance par surprise la [b]Wehrmacht[/b] à l'assaut de l'URSS par haine de l'idéologie communiste. Cette invasion ouvre le gigantesque front de l'Est et fait entrer l'URSS dans la [b]Grande Alliance[/b].",
		"object_name": "Classeur métallique à tiroirs"
	},

	# =========================================================================
	# PÉRIODE 2 : LE TOURNANT DE LA GUERRE (1942-1943)
	# =========================================================================
	"pearl_harbor_1941": {
		"id": "pearl_harbor_1941",
		"period": 2,
		"period_title": "PÉRIODE 2 : LE TOURNANT DE LA GUERRE (1942-1943)",
		"date_str": "7 Décembre 1941",
		"title": "Attaque japonaise de Pearl Harbor",
		"location": "Pearl Harbor, îles Hawaï (océan Pacifique)",
		"summary": "L'aviation japonaise bombarde par surprise la flotte américaine dans le Pacifique. Cet événement entraîne l'entrée officielle et décisive des États-Unis dans la guerre aux côtés des [b]Alliés[/b].",
		"object_name": "Machine à écrire d'époque"
	},
	"midway_1942": {
		"id": "midway_1942",
		"period": 2,
		"period_title": "PÉRIODE 2 : LE TOURNANT DE LA GUERRE (1942-1943)",
		"date_str": "4 au 7 Juin 1942",
		"title": "Bataille aéronavale de Midway",
		"location": "Atoll de Midway (océan Pacifique)",
		"summary": "Les forces américaines du général Douglas MacArthur détruisent quatre porte-avions japonais. C'est le coup d'arrêt de l'expansionnisme nippon en Asie-Pacifique et le début de la reconquête américaine.",
		"object_name": "Photo aérienne et loupe"
	},
	"el_alamein_1942": {
		"id": "el_alamein_1942",
		"period": 2,
		"period_title": "PÉRIODE 2 : LE TOURNANT DE LA GUERRE (1942-1943)",
		"date_str": "Novembre 1942 (23 oct. - 4 nov.)",
		"title": "Bataille d'El-Alamein",
		"location": "El-Alamein (Égypte, Afrique du Nord)",
		"summary": "Les troupes britanniques battent l'[b]Afrika Korps[/b] du général Rommel. Cette victoire empêche l'Axe d'atteindre le canal de Suez et amorce l'expulsion des forces germano-italiennes d'Afrique du Nord.",
		"object_name": "Boussole militaire de visée"
	},
	"stalingrad_1943": {
		"id": "stalingrad_1943",
		"period": 2,
		"period_title": "PÉRIODE 2 : LE TOURNANT DE LA GUERRE (1942-1943)",
		"date_str": "2 Février 1943",
		"title": "Capitulation allemande à Stalingrad",
		"location": "Stalingrad (URSS, front de l'Est)",
		"summary": "Encerclée par l'Armée rouge, la 6e armée allemande du maréchal Paulus capitule. C'est la première grande défaite terrestre de la [b]Wehrmacht[/b] et le tournant psychologique majeur du conflit en Europe.",
		"object_name": "Veste militaire au portemanteau"
	},
	"sicile_1943": {
		"id": "sicile_1943",
		"period": 2,
		"period_title": "PÉRIODE 2 : LE TOURNANT DE LA GUERRE (1942-1943)",
		"date_str": "Juillet 1943 (10 juillet)",
		"title": "Débarquement allié en Sicile (Opération Husky)",
		"location": "Sicile (Italie, Méditerranée)",
		"summary": "Les [b]Alliés[/b] débarquent en Italie du Sud depuis l'Afrique du Nord. Cette opération provoque la chute du dictateur fasciste Mussolini et ouvre un nouveau front en Europe du Sud.",
		"object_name": "Boîte d'archives 'Méditerranée'"
	},

	# =========================================================================
	# PÉRIODE 3 : LA VICTOIRE DES ALLIÉS (1944-1945)
	# =========================================================================
	"normandie_1944": {
		"id": "normandie_1944",
		"period": 3,
		"period_title": "PÉRIODE 3 : LA VICTOIRE DES ALLIÉS (1944-1945)",
		"date_str": "6 Juin 1944 (PPO)",
		"title": "Débarquement en Normandie (Jour J / Overlord)",
		"location": "Plages de Normandie (France, Europe de l'Ouest)",
		"summary": "Les forces anglo-américaines ouvrent le second front à l'Ouest promis lors de la conférence de Téhéran. C'est le début de la libération de la France et de l'Europe occidentale.",
		"object_name": "Tableau d'affichage des plages du Débarquement"
	},
	"bagration_1944": {
		"id": "bagration_1944",
		"period": 3,
		"period_title": "PÉRIODE 3 : LA VICTOIRE DES ALLIÉS (1944-1945)",
		"date_str": "22 Juin 1944 (PPO)",
		"title": "Début de l'opération Bagration",
		"location": "Biélorussie (front de l'Est)",
		"summary": "L'Armée rouge lance une offensive massive qui anéantit le groupe d'armées Centre allemand en moins de trois mois. Elle libère la Biélorussie, les pays baltes et ouvre la route de Berlin.",
		"object_name": "Tampon officiel d'état-major"
	},
	"elbe_1945": {
		"id": "elbe_1945",
		"period": 3,
		"period_title": "PÉRIODE 3 : LA VICTOIRE DES ALLIÉS (1944-1945)",
		"date_str": "26 Avril 1945",
		"title": "Jonction des armées sur l'Elbe",
		"location": "Torgau, sur le fleuve Elbe (Allemagne)",
		"summary": "Les soldats américains et soviétiques se rejoignent sur l'Elbe, coupant le territoire allemand en deux et scellant la victoire militaire totale des [b]Alliés[/b] sur le régime nazi.",
		"object_name": "Cadre photo de jonction"
	},
	"capitulation_1945": {
		"id": "capitulation_1945",
		"period": 3,
		"period_title": "PÉRIODE 3 : LA VICTOIRE DES ALLIÉS (1944-1945)",
		"date_str": "8 Mai 1945",
		"title": "Capitulation sans condition de l'Allemagne",
		"location": "Berlin et Reims (Europe)",
		"summary": "Après le suicide d'Hitler le 30 avril et la prise de Berlin par les Soviétiques, l'Allemagne signe une [b]capitulation sans condition[/b]. La guerre prend fin sur le continent européen.",
		"object_name": "Porte blindée des Archives"
	},
	"hiroshima_1945": {
		"id": "hiroshima_1945",
		"period": 3,
		"period_title": "PÉRIODE 3 : LA VICTOIRE DES ALLIÉS (1944-1945)",
		"date_str": "6 et 9 Août 1945 (PPO)",
		"title": "Bombardements atomiques d'Hiroshima et Nagasaki",
		"location": "Hiroshima et Nagasaki (Japon, Asie-Pacifique)",
		"summary": "Le président américain Harry Truman ordonne l'usage de l'arme atomique pour contraindre le Japon à se rendre. Le 2 septembre 1945, l'empereur Hirohito capitule, mettant fin à la Seconde Guerre mondiale.",
		"object_name": "Dossier final 'Projet Manhattan'"
	}
}

static func get_date_info(date_id: String) -> Dictionary:
	if DATES.has(date_id):
		return DATES[date_id]
	return {}

static func get_dates_for_period(p_period: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in DATES:
		var item: Dictionary = DATES[key]
		if item.get("period", 0) == p_period:
			result.append(item)
	return result
