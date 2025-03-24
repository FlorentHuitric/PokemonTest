@tool
extends EditorScript

# Chemins des fichiers CSV
const POKEMON_EVOLUTION_PATH = "res://imports/pokemon_evolution.csv"
const EVOLUTION_TRIGGERS_PATH = "res://imports/evolution_triggers.csv"
const EVOLUTION_TRIGGER_PROSE_PATH = "res://imports/evolution_trigger_prose.csv"

# Dictionnaires pour stocker les données
var pokemon_evolutions = {}
var evolution_triggers = {}
var evolution_trigger_names = {}
var species_to_pokemon_mapping = {}

# Exécuté quand le script est lancé depuis l'éditeur
func _run() -> void:
	print("Importing Pokémon evolution data...")
	
	# Vérifier si le fichier CSV existe
	if not FileAccess.file_exists(POKEMON_EVOLUTION_PATH):
		printerr("pokemon_evolution.csv not found. Please place it in the imports folder.")
		return
	
	# Créer un mapping des species_id vers pokemon_id
	create_species_to_pokemon_mapping()
	
	# Charger les données des déclencheurs d'évolution
	load_evolution_triggers()
	
	# Charger les traductions des déclencheurs d'évolution
	load_evolution_trigger_prose()
	
	# Charger les données d'évolution depuis le CSV
	load_pokemon_evolutions()
	
	# Mettre à jour les ressources de Pokémon
	update_pokemon_resources()
	
	print("Import terminé!")

# Créer un mapping entre species_id et pokemon_id
func create_species_to_pokemon_mapping() -> void:
	# En général, species_id est identique au pokemon_id pour les formes de base
	# Mais pour les formes alternatives, ça peut être différent
	
	# Charger tous les Pokémon et créer le mapping
	var dir = DirAccess.open("res://data/pokemon/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var pokemon_path = "res://data/pokemon/" + file_name
				var pokemon = load(pokemon_path) as Resource # PokemonResource
				
				if pokemon:
					var pokemon_id = pokemon.pokemon_id
					# Pour simplifier, on considère que le species_id est le même que le pokemon_id
					# Dans une implémentation complète, on chargerait pokemon_species.csv pour le mapping exact
					species_to_pokemon_mapping[pokemon_id] = pokemon_id
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("Created mapping for %d Pokémon species" % species_to_pokemon_mapping.size())
	else:
		printerr("Failed to open directory res://data/pokemon/")

# Charger les déclencheurs d'évolution
func load_evolution_triggers() -> void:
	if FileAccess.file_exists(EVOLUTION_TRIGGERS_PATH):
		var file = FileAccess.open(EVOLUTION_TRIGGERS_PATH, FileAccess.READ)
		if file:
			# Skip header
			var _header = file.get_csv_line()
			
			while !file.eof_reached():
				var line = file.get_csv_line()
				if line.size() >= 2:
					var trigger_id = int(line[0]) if line[0].strip_edges() != "" else 0
					var identifier = line[1].strip_edges()
					
					if trigger_id > 0:
						evolution_triggers[trigger_id] = identifier
			
			file.close()
			print("Loaded %d evolution triggers" % evolution_triggers.size())
		else:
			printerr("Failed to open file " + EVOLUTION_TRIGGERS_PATH)
	else:
		# Créer des déclencheurs par défaut si le fichier n'existe pas
		evolution_triggers = {
			1: "level-up",
			2: "trade",
			3: "use-item",
			4: "shed",
			5: "spin",
			6: "tower-of-darkness",
			7: "tower-of-waters",
			8: "three-critical-hits",
			9: "take-damage"
		}
		print("Using default evolution triggers (file not found)")

# Charger les traductions des déclencheurs d'évolution
func load_evolution_trigger_prose() -> void:
	if FileAccess.file_exists(EVOLUTION_TRIGGER_PROSE_PATH):
		var file = FileAccess.open(EVOLUTION_TRIGGER_PROSE_PATH, FileAccess.READ)
		if file:
			# Skip header
			var _header = file.get_csv_line()
			
			while !file.eof_reached():
				var line = file.get_csv_line()
				if line.size() >= 3:
					var trigger_id = int(line[0]) if line[0].strip_edges() != "" else 0
					var language_id = int(line[1]) if line[1].strip_edges() != "" else 0
					var name = line[2].strip_edges()
					
					if trigger_id > 0:
						if not evolution_trigger_names.has(trigger_id):
							evolution_trigger_names[trigger_id] = {}
						
						# Language ID 9 est anglais
						if language_id == 9:
							evolution_trigger_names[trigger_id]["en"] = name
						# Language ID 5 est français
						elif language_id == 5:
							evolution_trigger_names[trigger_id]["fr"] = name
						# Language ID 6 est allemand (utilisé comme fallback pour le français si nécessaire)
						elif language_id == 6 and not evolution_trigger_names[trigger_id].has("fr"):
							evolution_trigger_names[trigger_id]["fr"] = name
			
			file.close()
			print("Loaded translations for %d evolution triggers" % evolution_trigger_names.size())
		else:
			printerr("Failed to open file " + EVOLUTION_TRIGGER_PROSE_PATH)
	else:
		# Ajouter des traductions par défaut
		evolution_trigger_names = {
			1: {"en": "Level-up", "fr": "Montée de niveau"},
			2: {"en": "Trade", "fr": "Échange"},
			3: {"en": "Use Item", "fr": "Utilisation d'objet"},
			4: {"en": "Shed", "fr": "Changement de forme"},
			5: {"en": "Spin", "fr": "Rotation"},
			6: {"en": "Tower of Darkness", "fr": "Tour des Ténèbres"},
			7: {"en": "Tower of Waters", "fr": "Tour des Eaux"},
			8: {"en": "Three Critical Hits", "fr": "Trois coups critiques"},
			9: {"en": "Take Damage", "fr": "Subir des dégâts"}
		}
		print("Using default trigger translations (file not found)")

# Charger les données d'évolution des Pokémon
func load_pokemon_evolutions() -> void:
	var file = FileAccess.open(POKEMON_EVOLUTION_PATH, FileAccess.READ)
	if file:
		# Skip header
		var _header = file.get_csv_line()
		
		var count = 0
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 20:
				var id = int(line[0]) if line[0].strip_edges() != "" else 0
				var evolved_species_id = int(line[1]) if line[1].strip_edges() != "" else 0
				var evolution_trigger_id = int(line[2]) if line[2].strip_edges() != "" else 0
				var trigger_item_id = int(line[3]) if line[3].strip_edges() != "" else 0
				var minimum_level = int(line[4]) if line[4].strip_edges() != "" else 0
				var gender_id = int(line[5]) if line[5].strip_edges() != "" else 0
				var location_id = int(line[6]) if line[6].strip_edges() != "" else 0
				var held_item_id = int(line[7]) if line[7].strip_edges() != "" else 0
				var time_of_day = line[8].strip_edges()
				var known_move_id = int(line[9]) if line[9].strip_edges() != "" else 0
				var known_move_type_id = int(line[10]) if line[10].strip_edges() != "" else 0
				var minimum_happiness = int(line[11]) if line[11].strip_edges() != "" else 0
				var minimum_beauty = int(line[12]) if line[12].strip_edges() != "" else 0
				var minimum_affection = int(line[13]) if line[13].strip_edges() != "" else 0
				var relative_physical_stats = int(line[14]) if line[14].strip_edges() != "" else 0
				var party_species_id = int(line[15]) if line[15].strip_edges() != "" else 0
				var party_type_id = int(line[16]) if line[16].strip_edges() != "" else 0
				var trade_species_id = int(line[17]) if line[17].strip_edges() != "" else 0
				var needs_overworld_rain = bool(int(line[18])) if line[18].strip_edges() != "" else false
				var turn_upside_down = bool(int(line[19])) if line[19].strip_edges() != "" else false
				
				# On cherche le Pokémon précédent
				var base_pokemon_id = evolved_species_id - 1
				
				# Si le Pokémon évolué existe dans notre mapping
				if species_to_pokemon_mapping.has(evolved_species_id):
					var evolved_pokemon_id = species_to_pokemon_mapping[evolved_species_id]
					
					# Récupérer les traductions du déclencheur
					var trigger_names = {}
					if evolution_trigger_names.has(evolution_trigger_id):
						trigger_names = evolution_trigger_names[evolution_trigger_id]
					else:
						trigger_names = {
							"en": evolution_triggers.get(evolution_trigger_id, "unknown"),
							"fr": evolution_triggers.get(evolution_trigger_id, "inconnu")
						}
					
					# Créer l'entrée d'évolution
					var evolution_data = {
						"evolved_pokemon_id": evolved_pokemon_id,
						"trigger_id": evolution_trigger_id,
						"trigger_identifier": evolution_triggers.get(evolution_trigger_id, "unknown"),
						"trigger_name": trigger_names,
						"minimum_level": minimum_level,
						"item_id": trigger_item_id if trigger_item_id > 0 else held_item_id,
						"gender_id": gender_id,
						"location_id": location_id,
						"time_of_day": time_of_day,
						"known_move_id": known_move_id,
						"known_move_type_id": known_move_type_id,
						"minimum_happiness": minimum_happiness,
						"minimum_beauty": minimum_beauty,
						"minimum_affection": minimum_affection,
						"relative_physical_stats": relative_physical_stats,
						"party_species_id": party_species_id,
						"party_type_id": party_type_id,
						"trade_species_id": trade_species_id,
						"needs_overworld_rain": needs_overworld_rain,
						"turn_upside_down": turn_upside_down
					}
					
					# Pour déterminer le Pokémon de base, nous avons quelques stratégies
					var found_base = false
					
					# 1. Si c'est la première évolution du Pokémon, on suppose qu'il s'agit du Pokémon précédent
					if evolved_species_id > 1 and species_to_pokemon_mapping.has(base_pokemon_id):
						# Ajouter l'évolution au Pokémon de base
						if not pokemon_evolutions.has(base_pokemon_id):
							pokemon_evolutions[base_pokemon_id] = []
						
						pokemon_evolutions[base_pokemon_id].append(evolution_data)
						found_base = true
						count += 1
					
					# 2. Si nous avons des informations spécifiques (comme party_species_id), on peut les utiliser
					if not found_base and party_species_id > 0 and species_to_pokemon_mapping.has(party_species_id):
						var party_pokemon_id = species_to_pokemon_mapping[party_species_id]
						
						if not pokemon_evolutions.has(party_pokemon_id):
							pokemon_evolutions[party_pokemon_id] = []
						
						pokemon_evolutions[party_pokemon_id].append(evolution_data)
						found_base = true
						count += 1
					
					# 3. Si rien n'a fonctionné, on stocke l'évolution dans une catégorie spéciale
					if not found_base:
						if not pokemon_evolutions.has(0):
							pokemon_evolutions[0] = []
						
						pokemon_evolutions[0].append({
							"unresolved_evolution_id": id,
							"evolved_pokemon_id": evolved_pokemon_id,
							"evolution_data": evolution_data
						})
		
		file.close()
		print("Loaded %d Pokémon evolution entries" % count)
	else:
		printerr("Failed to open file " + POKEMON_EVOLUTION_PATH)

# Mettre à jour les ressources de Pokémon
func update_pokemon_resources() -> void:
	var dir = DirAccess.open("res://data/pokemon/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var count = 0
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var pokemon_path = "res://data/pokemon/" + file_name
				var pokemon = load(pokemon_path) as Resource # PokemonResource
				
				if pokemon:
					var pokemon_id = pokemon.pokemon_id
					
					# Vérifier si nous avons des évolutions pour ce Pokémon
					if pokemon_evolutions.has(pokemon_id) and "evolutions" in pokemon:
						# Convertir les évolutions en format adapté pour le PokemonResource
						var evolutions_data = []
						
						for evolution in pokemon_evolutions[pokemon_id]:
							var simplified_evolution = {
								"evolved_pokemon_id": evolution.evolved_pokemon_id,
								"trigger_type": evolution.trigger_identifier,
								"trigger_name": evolution.trigger_name,
								"condition": {},
								"condition_en": get_evolution_condition_text(evolution, "en"),
								"condition_fr": get_evolution_condition_text(evolution, "fr")
							}
							evolutions_data.append(simplified_evolution)
						
						# Mettre à jour les évolutions du Pokémon
						pokemon.evolutions = evolutions_data
						
						# Sauvegarder les changements
						var err = ResourceSaver.save(pokemon, pokemon_path)
						if err == OK:
							count += 1
							print("Updated evolutions for Pokémon #%d (%s) with %d evolutions" % [
								pokemon_id, file_name, evolutions_data.size()
							])
						else:
							printerr("Error saving resource: " + str(err))
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("Updated %d Pokémon resources with evolution data" % count)
	else:
		printerr("Failed to open directory res://data/pokemon/")

# Générer une description textuelle de la condition d'évolution
func get_evolution_condition_text(evolution: Dictionary, lang: String = "en") -> String:
	var condition = ""
	
	# Niveau minimum
	if evolution.minimum_level > 0:
		if lang == "en":
			condition = "Level " + str(evolution.minimum_level)
		else: # fr
			condition = "Niveau " + str(evolution.minimum_level)
	
	# Bonheur minimum
	if evolution.minimum_happiness > 0:
		if condition != "":
			condition += " + "
			
		if lang == "en":
			condition += "Happiness " + str(evolution.minimum_happiness)
		else: # fr
			condition += "Bonheur " + str(evolution.minimum_happiness)
	
	# Objet
	if evolution.item_id > 0:
		if condition != "":
			condition += " + "
			
		if lang == "en":
			condition += "Item " + str(evolution.item_id)
		else: # fr
			condition += "Objet " + str(evolution.item_id)
	
	# Moment de la journée
	if evolution.time_of_day != "":
		if condition != "":
			condition += " + "
			
		var time_of_day_trans = evolution.time_of_day
		if lang == "fr":
			# Traduire le moment de la journée
			var time_translations = {
				"day": "jour",
				"night": "nuit",
				"dusk": "crépuscule",
				"dawn": "aube"
			}
			if time_translations.has(evolution.time_of_day):
				time_of_day_trans = time_translations[evolution.time_of_day]
		
		if lang == "en":
			condition += "Time: " + time_of_day_trans
		else: # fr
			condition += "Moment: " + time_of_day_trans
	
	# Capacité connue
	if evolution.known_move_id > 0:
		if condition != "":
			condition += " + "
			
		if lang == "en":
			condition += "Known move " + str(evolution.known_move_id)
		else: # fr
			condition += "Capacité connue " + str(evolution.known_move_id)
	
	# Si aucune condition n'est spécifiée
	if condition == "":
		if evolution.trigger_identifier == "trade":
			if lang == "en":
				condition = "Trading"
			else: # fr
				condition = "Échange"
		else:
			if lang == "en":
				condition = "Special condition"
			else: # fr
				condition = "Condition spéciale"
	
	return condition
