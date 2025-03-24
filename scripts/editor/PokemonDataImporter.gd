@tool
extends EditorScript

# Chemins des fichiers CSV
const MOVE_META_CATEGORY_PROSE_PATH = "res://imports/move_meta_category_prose.csv"
const MOVE_META_AILMENTS_PATH = "res://imports/move_meta_ailments.csv"
const MOVE_META_AILMENT_NAMES_PATH = "res://imports/move_meta_ailment_names.csv"
const MOVE_META_PATH = "res://imports/move_meta.csv"
const POKEMON_MOVE_METHOD_PROSE_PATH = "res://imports/pokemon_move_method_prose.csv"

# Dictionnaires pour stocker les données
var move_meta_categories = {}
var move_meta_ailments = {}
var move_meta_ailment_names = {}
var move_meta_data = {}
var pokemon_move_methods = {}

# Exécuté quand le script est lancé depuis l'éditeur
func _run() -> void:
	print("Importing Pokémon data...")
	
	# Charger les données des CSV
	load_move_meta_categories()
	load_move_meta_ailments()
	load_move_meta_ailment_names()
	load_move_meta_data()
	load_pokemon_move_methods()
	
	# Mettre à jour les ressources de moves
	update_move_resources()
	
	print("Import terminé!")

# Charger les catégories de moves
func load_move_meta_categories() -> void:
	var file = FileAccess.open(MOVE_META_CATEGORY_PROSE_PATH, FileAccess.READ)
	if file:
		# Skip _header
		var _header = file.get_csv_line()
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 3:
				var category_id = int(line[0])
				var language_id = int(line[1])
				var description = line[2]
				
				if not move_meta_categories.has(category_id):
					move_meta_categories[category_id] = {}
				
				# Language ID 9 est anglais
				if language_id == 9:
					move_meta_categories[category_id]["en"] = description
				# Language ID 5 est français
				elif language_id == 5:
					move_meta_categories[category_id]["fr"] = description
		
		file.close()
		print("Loaded %d move categories" % move_meta_categories.size())

# Charger les ailments de moves
func load_move_meta_ailments() -> void:
	var file = FileAccess.open(MOVE_META_AILMENTS_PATH, FileAccess.READ)
	if file:
		# Skip _header
		var _header = file.get_csv_line()
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 2:
				var ailment_id = int(line[0])
				var identifier = line[1]
				
				move_meta_ailments[ailment_id] = identifier
		
		file.close()
		print("Loaded %d move ailments" % move_meta_ailments.size())

# Charger les noms des ailments
func load_move_meta_ailment_names() -> void:
	var file = FileAccess.open(MOVE_META_AILMENT_NAMES_PATH, FileAccess.READ)
	if file:
		# Skip _header
		var _header = file.get_csv_line()
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 3:
				var ailment_id = int(line[0])
				var language_id = int(line[1])
				var name = line[2]
				
				if not move_meta_ailment_names.has(ailment_id):
					move_meta_ailment_names[ailment_id] = {}
				
				# Language ID 9 est anglais
				if language_id == 9:
					move_meta_ailment_names[ailment_id]["en"] = name
				# Language ID 5 est français
				elif language_id == 5:
					move_meta_ailment_names[ailment_id]["fr"] = name
		
		file.close()
		print("Loaded %d move ailment names" % move_meta_ailment_names.size())

# Charger les données meta des moves
func load_move_meta_data() -> void:
	var file = FileAccess.open(MOVE_META_PATH, FileAccess.READ)
	if file:
		# Skip _header
		var _header = file.get_csv_line()
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 13:
				var move_id = int(line[0])
				
				move_meta_data[move_id] = {
					"meta_category_id": int(line[1]),
					"meta_ailment_id": int(line[2]),
					"min_hits": parse_int_or_null(line[3]),
					"max_hits": parse_int_or_null(line[4]),
					"min_turns": parse_int_or_null(line[5]),
					"max_turns": parse_int_or_null(line[6]),
					"drain": int(line[7]),
					"healing": int(line[8]),
					"crit_rate": int(line[9]),
					"ailment_chance": int(line[10]),
					"flinch_chance": int(line[11]),
					"stat_chance": int(line[12])
				}
		
		file.close()
		print("Loaded meta data for %d moves" % move_meta_data.size())

# Charger les méthodes d'apprentissage de moves
func load_pokemon_move_methods() -> void:
	var file = FileAccess.open(POKEMON_MOVE_METHOD_PROSE_PATH, FileAccess.READ)
	if file:
		# Skip _header
		var _header = file.get_csv_line()
		
		while !file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 4:
				var method_id = int(line[0])
				var language_id = int(line[1])
				var name = line[2]
				var description = line[3]
				
				if not pokemon_move_methods.has(method_id):
					pokemon_move_methods[method_id] = {"name": {}, "description": {}}
				
				# Language ID 9 est anglais
				if language_id == 9:
					pokemon_move_methods[method_id]["name"]["en"] = name
					pokemon_move_methods[method_id]["description"]["en"] = description
				# Language ID 5 est français (parfois 6 pour allemand, 7 pour espagnol)
				elif language_id == 5:
					pokemon_move_methods[method_id]["name"]["fr"] = name
					pokemon_move_methods[method_id]["description"]["fr"] = description
		
		file.close()
		print("Loaded %d move learning methods" % pokemon_move_methods.size())

# Mettre à jour les ressources de moves
func update_move_resources() -> void:
	# Trouver tous les fichiers .tres dans le répertoire des moves
	var dir = DirAccess.open("res://data/moves/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var count = 0
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var move_path = "res://data/moves/" + file_name
				var move = load(move_path) as MoveResource
				
				if move:
					var move_id = move.move_id
					
					# Mettre à jour avec les données meta
					if move_meta_data.has(move_id):
						var original_category_id = move.meta_category_id
						var original_ailment_id = move.meta_ailment_id
						
						# Set properties directly instead of using the method
						var meta = move_meta_data[move_id]
						move.meta_category_id = meta.meta_category_id
						move.meta_ailment_id = meta.meta_ailment_id
						move.min_hits = meta.min_hits if meta.min_hits != null else 0
						move.max_hits = meta.max_hits if meta.max_hits != null else 0
						move.min_turns = meta.min_turns if meta.min_turns != null else 0
						move.max_turns = meta.max_turns if meta.max_turns != null else 0
						move.drain = meta.drain
						move.healing = meta.healing
						move.crit_rate = meta.crit_rate
						move.ailment_chance = meta.ailment_chance
						move.flinch_chance = meta.flinch_chance
						move.stat_chance = meta.stat_chance
						
						# Ajouter description de la catégorie
						var category_id = meta.meta_category_id
						if move_meta_categories.has(category_id):
							move.meta_category_desc = move_meta_categories[category_id]
						
						# Ajouter nom de l'ailment
						var ailment_id = meta.meta_ailment_id
						if move_meta_ailment_names.has(ailment_id):
							move.meta_ailment_name = move_meta_ailment_names[ailment_id]
						
						# Sauvegarder les changements
						var err = ResourceSaver.save(move, move_path)
						if err == OK:
							count += 1
							print("Updated move #%d (%s) | Category: %d → %d | Ailment: %d → %d | Power: %d | Accuracy: %d" % 
								[move_id, file_name, original_category_id, move.meta_category_id, 
								original_ailment_id, move.meta_ailment_id, move.power, move.accuracy])
						else:
							printerr("Error saving resource: " + str(err))
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("Updated %d move resources" % count)

# Fonction utilitaire pour parser un entier ou null
func parse_int_or_null(value: String):
	if value.strip_edges() == "":
		return null
	return int(value)
