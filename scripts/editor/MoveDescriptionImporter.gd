@tool
extends EditorScript

# Chemin du fichier CSV contenant les descriptions des moves
const MOVE_FLAVOR_TEXT_PATH = "res://imports/move_flavor_text.csv"

# Dictionnaires pour stocker les données
var move_descriptions = {}
var version_group_stats = {}
var best_version_group = 0

# Exécuté quand le script est lancé depuis l'éditeur
func _run() -> void:
	print("Importing Move descriptions from flavor texts...")
	
	# Vérifier si le fichier existe
	if not FileAccess.file_exists(MOVE_FLAVOR_TEXT_PATH):
		printerr("move_flavor_text.csv not found. Please place it in the imports folder.")
		return
	
	# Charger les descriptions depuis le CSV
	load_move_descriptions()
	
	# Déterminer le meilleur version_group à utiliser
	find_best_version_group()
	
	# Mettre à jour les ressources de moves avec les descriptions
	update_move_resources()
	
	print("Import terminé!")

# Charger les descriptions depuis le fichier CSV
func load_move_descriptions() -> void:
	var file = FileAccess.open(MOVE_FLAVOR_TEXT_PATH, FileAccess.READ)
	if file:
		# Skip header
		var _header = file.get_csv_line()
		
		var count = 0
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 4:
				var move_id = int(line[0]) if line[0].strip_edges() != "" else 0
				var version_group_id = int(line[1]) if line[1].strip_edges() != "" else 0
				var language_id = int(line[2]) if line[2].strip_edges() != "" else 0
				var flavor_text = clean_text(line[3])
				
				# Ignorer les entrées invalides
				if move_id <= 0 or version_group_id <= 0:
					continue
				
				# Initialiser les structures si nécessaire
				if not move_descriptions.has(move_id):
					move_descriptions[move_id] = {}
				
				if not move_descriptions[move_id].has(version_group_id):
					move_descriptions[move_id][version_group_id] = {}
				
				# Stocker la description selon la langue (9=EN, 5=FR)
				if language_id == 9:  # Anglais
					move_descriptions[move_id][version_group_id]["en"] = flavor_text
				elif language_id == 5:  # Français
					move_descriptions[move_id][version_group_id]["fr"] = flavor_text
				
				# Mettre à jour les statistiques des version_groups
				if not version_group_stats.has(version_group_id):
					version_group_stats[version_group_id] = {"count": 0, "en": 0, "fr": 0}
				version_group_stats[version_group_id]["count"] += 1
				if language_id == 9:
					version_group_stats[version_group_id]["en"] += 1
				elif language_id == 5:
					version_group_stats[version_group_id]["fr"] += 1
				
				count += 1
		
		file.close()
		print("Loaded %d move descriptions" % count)
	else:
		printerr("Failed to open file " + MOVE_FLAVOR_TEXT_PATH)

# Déterminer le meilleur version_group à utiliser pour les descriptions
func find_best_version_group() -> void:
	var best_score = 0
	best_version_group = 0
	
	# Version groups par génération (pour référence)
	var generation_mapping = {
		1: [1, 2],         # Gen 1: Red/Blue, Yellow
		2: [3, 4],         # Gen 2: Gold/Silver, Crystal
		3: [5, 6, 7],      # Gen 3: Ruby/Sapphire, Emerald, FireRed/LeafGreen
		4: [8, 9, 10],     # Gen 4: Diamond/Pearl, Platinum, HeartGold/SoulSilver 
		5: [11, 12],       # Gen 5: Black/White, Black 2/White 2
		6: [13, 14],       # Gen 6: X/Y, Omega Ruby/Alpha Sapphire
		7: [15, 16, 17],   # Gen 7: Sun/Moon, Ultra Sun/Ultra Moon, Let's Go
		8: [18, 19, 20],   # Gen 8: Sword/Shield, BDSP, Legends Arceus
		9: [21]            # Gen 9: Scarlet/Violet
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
		
		# Mettre à jour le meilleur version_group si ce score est plus élevé
		if score > best_score:
			best_score = score
			best_version_group = version_id
	
	if best_version_group > 0:
		var stats = version_group_stats[best_version_group]
		print("Selected version group %d with %d English and %d French descriptions" % [
			best_version_group, stats["en"], stats["fr"]
		])
	else:
		printerr("Couldn't find a suitable version group!")

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

# Mettre à jour les ressources de moves avec les descriptions choisies
func update_move_resources() -> void:
	var dir = DirAccess.open("res://data/moves/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var count = 0
		var missing = 0
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var move_path = "res://data/moves/" + file_name
				var move = load(move_path) as Resource # MoveResource
				
				if move:
					var move_id = move.move_id
					
					# Vérifier si nous avons des descriptions pour ce move
					if move_descriptions.has(move_id) and move_descriptions[move_id].has(best_version_group):
						var descriptions = {}
						
						# Utiliser la description anglaise de la meilleure version
						if move_descriptions[move_id][best_version_group].has("en"):
							descriptions["en"] = move_descriptions[move_id][best_version_group]["en"]
						
						# Utiliser la description française de la meilleure version
						if move_descriptions[move_id][best_version_group].has("fr"):
							descriptions["fr"] = move_descriptions[move_id][best_version_group]["fr"]
						
						# Mettre à jour seulement si nous avons trouvé au moins une description
						if descriptions.size() > 0:
							# Conserver les descriptions existantes si la langue n'est pas disponible dans notre CSV
							if move.descriptions.has("en") and not descriptions.has("en"):
								descriptions["en"] = move.descriptions["en"]
							if move.descriptions.has("fr") and not descriptions.has("fr"):
								descriptions["fr"] = move.descriptions["fr"]
								
							# Si après fusion, aucune description n'est présente, conserver l'effet comme description
							if not descriptions.has("en") and not descriptions.has("fr"):
								# Essayer de récupérer l'effet si disponible
								if move.has_meta("move_effect_id"):
									var effect_id = move.get_meta("move_effect_id")
									# Logique pour utiliser l'effet comme description de secours
									# Cette partie pourrait être développée si nécessaire
							
							# Mettre à jour les descriptions
							move.descriptions = descriptions
							
							# Sauvegarder les changements
							var err = ResourceSaver.save(move, move_path)
							if err == OK:
								count += 1
								print("Updated description for move #%d (%s)" % [move_id, file_name])
							else:
								printerr("Error saving resource: " + str(err))
						else:
							missing += 1
							print("No description found for move #%d (%s)" % [move_id, file_name])
					else:
						missing += 1
						print("No description found for move #%d (%s)" % [move_id, file_name])
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("Updated %d move resources, %d missing descriptions" % [count, missing])
	else:
		printerr("Failed to open directory res://data/moves/")
