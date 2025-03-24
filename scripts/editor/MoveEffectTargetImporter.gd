@tool
extends EditorScript

# Chemins des fichiers CSV
const MOVE_EFFECT_PROSE_PATH = "res://imports/move_effect_prose.csv"
const MOVE_EFFECT_PROSE_FR_PATH = "res://imports/move_effect_prose_fr.csv" # Nouveau fichier pour les traductions françaises
const MOVE_EFFECTS_PATH = "res://imports/move_effects.csv"
const MOVE_TARGET_PROSE_PATH = "res://imports/move_target_prose.csv"
const MOVE_TARGET_PROSE_FR_PATH = "res://imports/move_target_prose_fr.csv" # Nouveau fichier pour les traductions françaises
const MOVE_TARGETS_PATH = "res://imports/move_targets.csv"
const MOVES_PATH = "res://imports/moves.csv"

# Dictionnaires pour stocker les données
var move_effects = {}
var move_effect_descriptions = {}
var move_targets = {}
var move_target_descriptions = {}
var move_to_effect_map = {}
var move_to_target_map = {}
var move_meta_data = {}

# Exécuté quand le script est lancé depuis l'éditeur
func _run() -> void:
	print("Importing Move effects and targets...")
	
	# Vérifier si moves.csv existe
	if not FileAccess.file_exists(MOVES_PATH):
		printerr("moves.csv not found. Please place it in the imports folder.")
		return
	
	# Charger les données des CSV
	load_move_effects()
	load_move_effect_descriptions()
	load_move_target_descriptions_fr() # Charger les traductions françaises des cibles
	load_move_effect_descriptions_fr() # Charger les traductions françaises des effets
	load_move_targets()
	load_move_target_descriptions()
	load_move_to_effect_target_mapping()
	
	# Mettre à jour les ressources de moves
	update_move_resources()
	
	print("Import terminé!")

# Charger les IDs des effets de moves
func load_move_effects() -> void:
	var file = FileAccess.open(MOVE_EFFECTS_PATH, FileAccess.READ)
	if file:
		# Skip header
		var _header = file.get_csv_line()
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 1 and line[0].strip_edges() != "":
				var effect_id = int(line[0])
				move_effects[effect_id] = line[1] if line.size() > 1 else "effect" + str(effect_id) # Tenir compte de la colonne name ajoutée
		
		file.close()
		print("Loaded %d move effects" % move_effects.size())
	else:
		printerr("Failed to open file " + MOVE_EFFECTS_PATH)

# Charger les descriptions des effets de moves
func load_move_effect_descriptions() -> void:
	var file = FileAccess.open(MOVE_EFFECT_PROSE_PATH, FileAccess.READ)
	if file:
		# Skip header
		var _header = file.get_csv_line()
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 4:
				var effect_id = int(line[0])
				var language_id = int(line[1])
				var short_effect = line[2]
				var effect = line[3]
				
				if not move_effect_descriptions.has(effect_id):
					move_effect_descriptions[effect_id] = {"short": {}, "full": {}}
				
				# Language ID 9 est anglais
				if language_id == 9:
					move_effect_descriptions[effect_id]["short"]["en"] = short_effect
					move_effect_descriptions[effect_id]["full"]["en"] = effect
		
		file.close()
		print("Loaded descriptions for %d move effects" % move_effect_descriptions.size())

# Charger les descriptions françaises des effets de moves
func load_move_effect_descriptions_fr() -> void:
	if not FileAccess.file_exists(MOVE_EFFECT_PROSE_FR_PATH):
		print("French move effect descriptions file not found, skipping...")
		return
		
	var file = FileAccess.open(MOVE_EFFECT_PROSE_FR_PATH, FileAccess.READ)
	if file:
		# Skip header
		var _header = file.get_csv_line()
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 4:
				var effect_id = int(line[0])
				var language_id = int(line[1])
				var short_effect = line[2]
				var effect = line[3]
				
				if not move_effect_descriptions.has(effect_id):
					move_effect_descriptions[effect_id] = {"short": {}, "full": {}}
				
				# Language ID 5 est français
				if language_id == 5:
					move_effect_descriptions[effect_id]["short"]["fr"] = short_effect
					move_effect_descriptions[effect_id]["full"]["fr"] = effect
		
		file.close()
		print("Loaded French descriptions for move effects")

# Charger les descriptions françaises des cibles de moves
func load_move_target_descriptions_fr() -> void:
	if not FileAccess.file_exists(MOVE_TARGET_PROSE_FR_PATH):
		print("French move target descriptions file not found, skipping...")
		return
		
	var file = FileAccess.open(MOVE_TARGET_PROSE_FR_PATH, FileAccess.READ)
	if file:
		# Skip header
		var _header = file.get_csv_line()
		
		var count = 0
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 4:
				var target_id = int(line[0])
				var language_id = int(line[1])
				var name = line[2]
				var description = line[3]
				
				if not move_target_descriptions.has(target_id):
					move_target_descriptions[target_id] = {"name": {}, "description": {}}
				
				# Language ID 5 est français
				if language_id == 5:
					move_target_descriptions[target_id]["name"]["fr"] = name
					move_target_descriptions[target_id]["description"]["fr"] = description
					count += 1
		
		file.close()
		print("Loaded %d French descriptions for move targets" % count)

# Charger les IDs des cibles de moves
func load_move_targets() -> void:
	var file = FileAccess.open(MOVE_TARGETS_PATH, FileAccess.READ)
	if file:
		# Skip header
		var _header = file.get_csv_line()
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 2:
				var target_id = int(line[0])
				var identifier = line[1]
				
				move_targets[target_id] = identifier
		
		file.close()
		print("Loaded %d move targets" % move_targets.size())

# Charger les descriptions des cibles de moves
func load_move_target_descriptions() -> void:
	var file = FileAccess.open(MOVE_TARGET_PROSE_PATH, FileAccess.READ)
	if file:
		# Skip header
		var _header = file.get_csv_line()
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 4:
				var target_id = int(line[0])
				var language_id = int(line[1])
				var name = line[2]
				var description = line[3]
				
				if not move_target_descriptions.has(target_id):
					move_target_descriptions[target_id] = {"name": {}, "description": {}}
				
				# Language ID 9 est anglais
				if language_id == 9:
					move_target_descriptions[target_id]["name"]["en"] = name
					move_target_descriptions[target_id]["description"]["en"] = description
				# Language ID 6 est allemand, mais on l'utilise seulement si on n'a pas de français
				elif language_id == 6:
					# Ne stocker l'allemand que si nous n'avons pas déjà une traduction française
					if not move_target_descriptions[target_id]["name"].has("fr"):
						move_target_descriptions[target_id]["name"]["fr_backup"] = name
						move_target_descriptions[target_id]["description"]["fr_backup"] = description
		
		file.close()
		print("Loaded descriptions for %d move targets" % move_target_descriptions.size())
		
		# Migrer les traductions allemandes vers le français uniquement si nécessaire
		for target_id in move_target_descriptions.keys():
			if move_target_descriptions[target_id]["name"].has("fr_backup") and not move_target_descriptions[target_id]["name"].has("fr"):
				move_target_descriptions[target_id]["name"]["fr"] = move_target_descriptions[target_id]["name"]["fr_backup"]
				move_target_descriptions[target_id]["description"]["fr"] = move_target_descriptions[target_id]["description"]["fr_backup"]
				# Supprimer les backups
				move_target_descriptions[target_id]["name"].erase("fr_backup")
				move_target_descriptions[target_id]["description"].erase("fr_backup")

# Variables pour stocker des métadonnées supplémentaires par move
var move_meta_data_dict = {}

# Helper functions pour gérer les métadonnées supplémentaires par move
func has_meta_data(move_id: int) -> bool:
	return move_meta_data_dict.has(move_id)

func get_meta_data(move_id: int) -> Dictionary:
	return move_meta_data_dict.get(move_id, {})

func set_meta_data(move_id: int, data: Dictionary) -> void:
	move_meta_data_dict[move_id] = data

# Charger les correspondances entre moves et leurs effets/cibles
func load_move_to_effect_target_mapping() -> void:
	var file = FileAccess.open(MOVES_PATH, FileAccess.READ)
	if file:
		# Skip header
		var _header = file.get_csv_line()
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 11: # Vérifier qu'on a au moins 11 colonnes pour effect_id (colonne 10) et target_id (colonne 8)
				var move_id = int(line[0])
				var effect_id = int(line[10]) if line[10].strip_edges() != "" else 1
				var target_id = int(line[8]) if line[8].strip_edges() != "" else 10 # 10 = selected-pokemon par défaut
				var effect_chance = int(line[11]) if line.size() > 11 and line[11].strip_edges() != "" else 0
				
				move_to_effect_map[move_id] = effect_id
				move_to_target_map[move_id] = target_id
				
				# Stocker les métadonnées supplémentaires
				var meta_data = {"effect_chance": effect_chance}
				set_meta_data(move_id, meta_data)
		
		file.close()
		print("Loaded effect/target mapping for %d moves" % move_to_effect_map.size())
	else:
		printerr("Failed to open file " + MOVES_PATH + ". Please ensure it exists and is accessible.")

# Vérifier si un objet possède une propriété
func has_property(obj: Object, property: String) -> bool:
	return property in obj

# Mettre à jour les ressources de moves
func update_move_resources() -> void:
	var dir = DirAccess.open("res://data/moves/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var count = 0
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var move_path = "res://data/moves/" + file_name
				var move = load(move_path) as Resource # MoveResource
				
				if move:
					var move_id = move.move_id
					var updated = false
					
					# Mettre à jour l'effet et la cible du move
					if move_to_effect_map.has(move_id):
						var effect_id = move_to_effect_map[move_id]
						
						# Mettre à jour la métadonnée
						move.set_meta("move_effect_id", effect_id)
						
						# Ajouter la chance d'effet si disponible
						if has_meta_data(move_id):
							var meta_data = get_meta_data(move_id)
							if meta_data.has("effect_chance"):
								move.set_meta("effect_chance", meta_data["effect_chance"])
								if has_property(move, "effect_chance"):
									move.effect_chance = meta_data["effect_chance"]
						
						# Mettre à jour la propriété si elle existe
						if has_property(move, "move_effect_id"):
							move.move_effect_id = effect_id
							
						# Mettre à jour la description courte de l'effet si elle existe
						if has_property(move, "move_effect_short") and move_effect_descriptions.has(effect_id):
							var short_desc = {}
							if move_effect_descriptions[effect_id]["short"].has("en"):
								short_desc["en"] = move_effect_descriptions[effect_id]["short"]["en"]
							if move_effect_descriptions[effect_id]["short"].has("fr"):
								short_desc["fr"] = move_effect_descriptions[effect_id]["short"]["fr"]
							move.move_effect_short = short_desc
							
						updated = true
					
					if move_to_target_map.has(move_id):
						var target_id = move_to_target_map[move_id]
						
						# Mettre à jour la métadonnée
						move.set_meta("move_target_id", target_id)
						
						# Mettre à jour la propriété si elle existe
						if has_property(move, "move_target_id"):
							move.move_target_id = target_id
						
						# Mettre à jour les noms et descriptions des cibles
						if target_id > 0 and move_target_descriptions.has(target_id):
							if has_property(move, "move_target_name"):
								move.move_target_name = {
									"en": move_target_descriptions[target_id]["name"].get("en", ""),
									"fr": move_target_descriptions[target_id]["name"].get("fr", "")
								}
							if has_property(move, "move_target_description"):
								move.move_target_description = {
									"en": move_target_descriptions[target_id]["description"].get("en", ""),
									"fr": move_target_descriptions[target_id]["description"].get("fr", "")
								}
						
						updated = true
					
					# Mettre à jour la description du move avec l'effet et la cible
					var effect_id = move.get_meta("move_effect_id", 0)
					var target_id = move.get_meta("move_target_id", 0)
					
					# Mettre à jour les descriptions si effet et cible sont disponibles
					if move_effect_descriptions.has(effect_id) and move_target_descriptions.has(target_id):
						var descriptions = {}
						var effect_chance = 0
						
						# Récupérer la chance d'effet si elle existe
						if has_meta_data(move_id):
							effect_chance = get_meta_data(move_id).get("effect_chance", 0)
						
						# Description anglaise
						if move_effect_descriptions[effect_id]["full"].has("en"):
							var desc = move_effect_descriptions[effect_id]["full"]["en"]
							if effect_chance > 0:
								desc = desc.replace("$effect_chance", str(effect_chance))
							descriptions["en"] = desc
							
							# Ajouter information sur la cible
							if move_target_descriptions[target_id]["name"].has("en"):
								descriptions["en"] += "\n\nTarget: " + move_target_descriptions[target_id]["name"]["en"]
								descriptions["en"] += " - " + move_target_descriptions[target_id]["description"]["en"]
						
						# Description française
						if move_effect_descriptions[effect_id]["full"].has("fr"):
							var desc = move_effect_descriptions[effect_id]["full"]["fr"]
							if effect_chance > 0:
								desc = desc.replace("$effect_chance", str(effect_chance))
							descriptions["fr"] = desc
							
							# Ajouter information sur la cible
							if move_target_descriptions[target_id]["name"].has("fr"):
								descriptions["fr"] += "\n\nCible: " + move_target_descriptions[target_id]["name"]["fr"]
								descriptions["fr"] += " - " + move_target_descriptions[target_id]["description"]["fr"]
						
						# Mettre à jour les descriptions seulement si nous avons les données
						if descriptions.has("en") or descriptions.has("fr"):
							move.descriptions = descriptions
							updated = true
					
					# Sauvegarder les changements
					if updated:
						var err = ResourceSaver.save(move, move_path)
						if err == OK:
							count += 1
							print("Updated move #%d (%s) with effect ID %d and target ID %d" % [move_id, file_name, effect_id, target_id])
						else:
							printerr("Error saving resource: " + str(err))
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("Updated %d move resources" % count)
	else:
		printerr("Failed to open directory res://data/moves/")
