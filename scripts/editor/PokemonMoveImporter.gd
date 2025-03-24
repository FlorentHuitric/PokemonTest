@tool
extends EditorScript

# Chemin vers le fichier CSV contenant les moves apprenables par les Pokémon
var POKEMON_MOVES_PATH = "res://imports/pokemon_moves.csv"

# Structure du CSV:
# pokemon_id,version_group_id,move_id,pokemon_move_method_id,level,order

# Dictionnaire pour stocker les moves apprenables par chaque Pokémon
var pokemon_moves = {}

# Mapping des version_group_id aux générations
var version_group_generations = {
	1: 1,  # Red/Blue - Gen 1
	2: 1,  # Yellow - Gen 1
	3: 2,  # Gold/Silver - Gen 2
	4: 2,  # Crystal - Gen 2
	5: 3,  # Ruby/Sapphire - Gen 3
	6: 3,  # Emerald - Gen 3
	7: 3,  # FireRed/LeafGreen - Gen 3
	8: 4,  # Diamond/Pearl - Gen 4
	9: 4,  # Platinum - Gen 4
	10: 4, # HeartGold/SoulSilver - Gen 4
	11: 5, # Black/White - Gen 5
	12: 5, # Black 2/White 2 - Gen 5
	13: 6, # XY - Gen 6
	14: 6, # ORAS - Gen 6
	15: 7, # Sun/Moon - Gen 7
	16: 7, # Ultra Sun/Ultra Moon - Gen 7
	17: 7, # Let's Go Pikachu/Eevee - Gen 7
	18: 8, # Sword/Shield - Gen 8
	19: 8, # BDSP - Gen 8
	20: 8  # Legends Arceus - Gen 8
}

func _run() -> void:
	print("Importing Pokémon moves...")
	
	# Vérifier si le fichier existe
	if !FileAccess.file_exists(POKEMON_MOVES_PATH):
		printerr("Le fichier " + POKEMON_MOVES_PATH + " n'existe pas!")
		return
	
	# Charger les données des moves apprenables
	load_pokemon_moves()
	update_pokemon_resources()
	
	print("Import terminé!")

# Charger les moves apprenables par les Pokémon
func load_pokemon_moves() -> void:
	var file = FileAccess.open(POKEMON_MOVES_PATH, FileAccess.READ)
	if file:
		# Skip _header
		var _header = file.get_csv_line()
		var line_count = 0
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 5:  # Vérifier qu'il y a assez de colonnes
				var pokemon_id = int(line[0]) if line[0].strip_edges() != "" else 0
				var version_group_id = int(line[1]) if line[1].strip_edges() != "" else 0
				var move_id = int(line[2]) if line[2].strip_edges() != "" else 0
				var method_id = int(line[3]) if line[3].strip_edges() != "" else 0
				var level = int(line[4]) if line[4].strip_edges() != "" else 0
				var order = int(line[5]) if line.size() > 5 && line[5].strip_edges() != "" else 0
				
				# Ignorer les entrées invalides
				if pokemon_id <= 0 || move_id <= 0:
					continue
				
				# Déterminer la génération
				var generation = version_group_generations.get(version_group_id, 1)
				
				# Initialiser le dictionnaire pour ce Pokémon s'il n'existe pas
				if not pokemon_moves.has(pokemon_id):
					pokemon_moves[pokemon_id] = []
				
				# Vérifier si ce move existe déjà pour éviter les doublons
				var move_exists = false
				for existing_move in pokemon_moves[pokemon_id]:
					if existing_move.move_id == move_id && existing_move.method == method_id && existing_move.level == level:
						move_exists = true
						# Mettre à jour la génération si celle-ci est plus récente
						if generation > existing_move.generation:
							existing_move.generation = generation
							existing_move.version_group_id = version_group_id
							existing_move.order = order
						break
				
				if not move_exists:
					# Ajouter le move apprenable
					pokemon_moves[pokemon_id].append({
						"move_id": move_id,
						"method": method_id,
						"level": level,
						"order": order,
						"generation": generation,
						"version_group_id": version_group_id
					})
					
				line_count += 1
		
		file.close()
		print("Loaded " + str(line_count) + " move entries for " + str(pokemon_moves.size()) + " Pokémon")
	else:
		printerr("Failed to open file " + POKEMON_MOVES_PATH)

# Mettre à jour les ressources de Pokémon avec leurs moves apprenables
func update_pokemon_resources() -> void:
	var dir = DirAccess.open("res://data/pokemon/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var count = 0
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var pokemon_path = "res://data/pokemon/" + file_name
				var pokemon = load(pokemon_path) as PokemonResource
				
				if pokemon:
					# On peut extraire l'ID du pokémon à partir du nom du fichier
					var pokemon_id = extract_pokemon_id(file_name)
					if pokemon_id <= 0:
						pokemon_id = pokemon.pokemon_id
					
					# Vérifier si nous avons des moves pour ce Pokémon
					if pokemon_moves.has(pokemon_id):
						# Créer une nouvelle liste pour les moves apprenables
						var new_learnable_moves = []
						
						# Ajouter chaque move apprenable à la nouvelle liste
						for move_data in pokemon_moves[pokemon_id]:
							# Déterminer TM/HM ID pour les moves de machine
							var tm_id = ""
							if move_data.method == 4:  # TM/HM
								tm_id = get_tm_id_for_move(move_data.move_id, move_data.version_group_id)
							
							# Créer le dictionnaire pour le move
							new_learnable_moves.append({
								"move_id": move_data.move_id,
								"method": move_data.method,
								"level": move_data.level,
								"tm_id": tm_id,
								"generation": move_data.generation
							})
						
						# Assigner la nouvelle liste à la propriété learnable_moves
						pokemon.learnable_moves = new_learnable_moves
						
						# Sauvegarder les changements
						var err = ResourceSaver.save(pokemon, pokemon_path)
						if err == OK:
							count += 1
							print("Updated Pokémon #%d (%s) with %d learnable moves" % [pokemon_id, file_name, pokemon.learnable_moves.size()])
						else:
							printerr("Error saving resource: " + str(err))
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("Updated " + str(count) + " Pokémon resources")
	else:
		printerr("Failed to open directory res://data/pokemon/")

# Extraire l'ID du pokémon à partir du nom de fichier (ex: 4_Charmander.tres -> 4)
func extract_pokemon_id(file_name: String) -> int:
	var parts = file_name.split("_")
	if parts.size() > 0:
		var id_str = parts[0]
		if id_str.is_valid_int():
			return int(id_str)
	return 0

# Fonction pour obtenir l'ID de la TM/HM pour un move
func get_tm_id_for_move(move_id: int, version_group_id: int) -> String:
	# À implémenter avec une base de données de TM/HM
	# Par exemple, mapper les moves aux TM/HM selon la génération
	
	# Exemple très simple pour illustration
	var tm_mappings = {
		# Format: [version_group_id][move_id] = "TM##"
		1: { 14: "TM06", 15: "TM08" },
		# Ajouter plus de mappings selon les besoins
	}
	
	if tm_mappings.has(version_group_id) and tm_mappings[version_group_id].has(move_id):
		return tm_mappings[version_group_id][move_id]
	
	return ""
