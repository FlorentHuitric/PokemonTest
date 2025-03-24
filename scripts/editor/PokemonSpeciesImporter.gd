@tool
extends EditorScript

# Chemins des fichiers CSV
const POKEMON_SPECIES_FLAVOR_TEXT_PATH = "res://imports/pokemon_species_flavor_text.csv"
const POKEMON_SPECIES_NAMES_PATH = "res://imports/pokemon_species_names.csv"

# Dictionnaires pour stocker les données
var pokemon_descriptions = {}
var pokemon_names = {}
var pokemon_genus = {}
var version_group_stats = {}
var best_version = 0

# Exécuté quand le script est lancé depuis l'éditeur
func _run() -> void:
	print("Importing Pokémon species data...")
	
	# Vérifier si les fichiers CSV existent
	if not FileAccess.file_exists(POKEMON_SPECIES_FLAVOR_TEXT_PATH):
		printerr("pokemon_species_flavor_text.csv not found. Please place it in the imports folder.")
		return
		
	if not FileAccess.file_exists(POKEMON_SPECIES_NAMES_PATH):
		printerr("pokemon_species_names.csv not found. Please place it in the imports folder.")
		return
	
	# Charger les données depuis les CSV
	load_pokemon_descriptions()
	load_pokemon_names_and_genus()
	
	# Déterminer la meilleure version pour les descriptions
	find_best_version()
	
	# Mettre à jour les ressources de Pokémon
	update_pokemon_resources()
	
	print("Import terminé!")

# Charger les descriptions des Pokémon depuis le fichier CSV
func load_pokemon_descriptions() -> void:
	var file = FileAccess.open(POKEMON_SPECIES_FLAVOR_TEXT_PATH, FileAccess.READ)
	if file:
		# Skip header
		var _header = file.get_csv_line()
		
		var count = 0
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 4:
				var species_id = int(line[0]) if line[0].strip_edges() != "" else 0
				var version_id = int(line[1]) if line[1].strip_edges() != "" else 0
				var language_id = int(line[2]) if line[2].strip_edges() != "" else 0
				var flavor_text = clean_text(line[3])
				
				# Ignorer les entrées invalides
				if species_id <= 0 or version_id <= 0:
					continue
				
				# Initialiser les structures si nécessaire
				if not pokemon_descriptions.has(species_id):
					pokemon_descriptions[species_id] = {}
				
				if not pokemon_descriptions[species_id].has(version_id):
					pokemon_descriptions[species_id][version_id] = {}
				
				# Stocker la description selon la langue (9=EN, 5=FR)
				if language_id == 9:  # Anglais
					pokemon_descriptions[species_id][version_id]["en"] = flavor_text
				elif language_id == 5:  # Français
					pokemon_descriptions[species_id][version_id]["fr"] = flavor_text
				
				# Mettre à jour les statistiques des versions
				if not version_group_stats.has(version_id):
					version_group_stats[version_id] = {"count": 0, "en": 0, "fr": 0}
				version_group_stats[version_id]["count"] += 1
				if language_id == 9:
					version_group_stats[version_id]["en"] += 1
				elif language_id == 5:
					version_group_stats[version_id]["fr"] += 1
				
				count += 1
		
		file.close()
		print("Loaded %d Pokémon descriptions" % count)
	else:
		printerr("Failed to open file " + POKEMON_SPECIES_FLAVOR_TEXT_PATH)

# Charger les noms et genus des Pokémon
func load_pokemon_names_and_genus() -> void:
	var file = FileAccess.open(POKEMON_SPECIES_NAMES_PATH, FileAccess.READ)
	if file:
		# Skip header
		var _header = file.get_csv_line()
		
		var count = 0
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 4:
				var species_id = int(line[0]) if line[0].strip_edges() != "" else 0
				var language_id = int(line[1]) if line[1].strip_edges() != "" else 0
				var name = line[2].strip_edges()
				var genus = line[3].strip_edges()
				
				# Ignorer les entrées invalides
				if species_id <= 0 or name.is_empty():
					continue
				
				# Initialiser les structures si nécessaire
				if not pokemon_names.has(species_id):
					pokemon_names[species_id] = {}
				
				if not pokemon_genus.has(species_id):
					pokemon_genus[species_id] = {}
				
				# Stocker le nom et le genus selon la langue (9=EN, 5=FR)
				if language_id == 9:  # Anglais
					pokemon_names[species_id]["en"] = name
					pokemon_genus[species_id]["en"] = genus
				elif language_id == 5:  # Français
					pokemon_names[species_id]["fr"] = name
					pokemon_genus[species_id]["fr"] = genus
				
				count += 1
		
		file.close()
		print("Loaded %d Pokémon names and genus entries" % count)
	else:
		printerr("Failed to open file " + POKEMON_SPECIES_NAMES_PATH)

# Déterminer la meilleure version à utiliser pour les descriptions
func find_best_version() -> void:
	var best_score = 0
	best_version = 0
	
	# Version IDs par génération (pour référence)
	var generation_mapping = {
		1: [1, 2],         # Gen 1: Red/Blue, Yellow
		2: [3, 4],         # Gen 2: Gold/Silver, Crystal
		3: [5, 6, 7],      # Gen 3: Ruby/Sapphire, Emerald, FireRed/LeafGreen
		4: [8, 9, 10],     # Gen 4: Diamond/Pearl, Platinum, HeartGold/SoulSilver 
		5: [11, 12],       # Gen 5: Black/White, Black 2/White 2
		6: [13, 14],       # Gen 6: X/Y, Omega Ruby/Alpha Sapphire
		7: [15, 16, 17],   # Gen 7: Sun/Moon, Ultra Sun/Ultra Moon, Let's Go
		8: [18, 19, 20],   # Gen 8: Sword/Shield, BDSP, Legends Arceus
		9: [21, 22]        # Gen 9: Scarlet/Violet
	}
	
	# Préférer les versions plus récentes, mais avec une bonne couverture en anglais et français
	for version_id in version_group_stats:
		var stats = version_group_stats[version_id]
		var coverage = float(stats["en"] + stats["fr"]) / (2 * stats["count"]) if stats["count"] > 0 else 0
		var generation = 0
		
		# Déterminer la génération de cette version
		for gen in generation_mapping:
			if version_id in generation_mapping[gen]:
				generation = gen
				break
		
		# Calculer un score basé sur la génération et la couverture des langues
		var score = generation * 100 + coverage * 50
		
		# Préférer les versions avec à la fois des textes EN et FR
		if stats["en"] > 0 and stats["fr"] > 0:
			score += 200
		
		# Mettre à jour la meilleure version si ce score est plus élevé
		if score > best_score:
			best_score = score
			best_version = version_id
	
	if best_version > 0:
		var stats = version_group_stats[best_version]
		print("Selected version %d with %d English and %d French descriptions" % [
			best_version, stats["en"], stats["fr"]
		])
	else:
		printerr("Couldn't find a suitable version!")

# Nettoyer le texte des caractères indésirables et normaliser les sauts de ligne
func clean_text(text: String) -> String:
	# Remplacer les retours à la ligne spéciaux par des espaces
	var cleaned = text.replace("­\n", " ")
	
	# Remplacer d'autres séquences problématiques
	cleaned = cleaned.replace("\n", " ")
	
	# Éliminer les espaces multiples
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	
	return cleaned.strip_edges()

# Mettre à jour les ressources de Pokémon
func update_pokemon_resources() -> void:
	var dir = DirAccess.open("res://data/pokemon/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var count = 0
		var desc_count = 0
		var names_count = 0
		var genus_count = 0
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var pokemon_path = "res://data/pokemon/" + file_name
				var pokemon = load(pokemon_path) as Resource # PokemonResource
				
				if pokemon:
					var pokemon_id = pokemon.pokemon_id
					var updated = false
					
					# Mettre à jour le nom du Pokémon
					if pokemon_names.has(pokemon_id):
						var names_dict = {}
						if pokemon_names[pokemon_id].has("en"):
							names_dict["en"] = pokemon_names[pokemon_id]["en"]
						if pokemon_names[pokemon_id].has("fr"):
							names_dict["fr"] = pokemon_names[pokemon_id]["fr"]
						
						if names_dict.size() > 0:
							pokemon.names = names_dict
							names_count += 1
							updated = true
					
					# Ajouter le genus (catégorie) du Pokémon
					if pokemon_genus.has(pokemon_id) and "genus" in pokemon:
						var genus_dict = {}
						if pokemon_genus[pokemon_id].has("en"):
							genus_dict["en"] = pokemon_genus[pokemon_id]["en"]
						if pokemon_genus[pokemon_id].has("fr"):
							genus_dict["fr"] = pokemon_genus[pokemon_id]["fr"]
						
						if genus_dict.size() > 0:
							pokemon.genus = genus_dict
							genus_count += 1
							updated = true
					
					# Mettre à jour la description du Pokémon
					if pokemon_descriptions.has(pokemon_id) and pokemon_descriptions[pokemon_id].has(best_version):
						var description_dict = {}
						if pokemon_descriptions[pokemon_id][best_version].has("en"):
							description_dict["en"] = pokemon_descriptions[pokemon_id][best_version]["en"]
						if pokemon_descriptions[pokemon_id][best_version].has("fr"):
							description_dict["fr"] = pokemon_descriptions[pokemon_id][best_version]["fr"]
						
						if description_dict.size() > 0:
							pokemon.description = description_dict
							desc_count += 1
							updated = true
					
					# Sauvegarder les changements
					if updated:
						var err = ResourceSaver.save(pokemon, pokemon_path)
						if err == OK:
							count += 1
							print("Updated Pokémon #%d (%s)" % [pokemon_id, file_name])
						else:
							printerr("Error saving resource: " + str(err))
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("Updated %d Pokémon resources (%d names, %d genus, %d descriptions)" % [
			count, names_count, genus_count, desc_count
		])
	else:
		printerr("Failed to open directory res://data/pokemon/")
