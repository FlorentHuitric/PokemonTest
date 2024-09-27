# res://scripts/tools/CSVImporter.gd
extends Node
class_name CSVImporter

# Assurez-vous que les autres ressources sont préchargées ou importées correctement
const TypeResource = preload("res://scripts/resources/TypeResource.gd")
const MoveResource = preload("res://scripts/resources/MoveResource.gd")
const AbilityResource = preload("res://scripts/resources/AbilityResource.gd")
const PokemonResource = preload("res://scripts/resources/PokemonResource.gd")
const ItemResource = preload("res://scripts/resources/ItemResource.gd")

func _ready():
	cleaning_functions()
	import_all_data()

func import_all_data():
	import_types()
	import_moves()
	import_move_names()
	var csv_path = "res://assets/data/Pokedex_Ver_SV2.csv"
	var pokemon_list = load_pokemon_csv(csv_path)
	var ability_names = extract_unique_abilities(pokemon_list)
	import_abilities(ability_names)
	import_pokemon(pokemon_list)

func cleaning_functions():
	clean_old_moves()

func import_types():
	var type_names = [
		"Normal", "Fire", "Water", "Grass", "Electric", "Ice",
		"Fighting", "Poison", "Ground", "Flying", "Psychic",
		"Bug", "Rock", "Ghost", "Dragon", "Dark", "Steel", "Fairy"
	]
	for type_name in type_names:
		var type_resource = TypeResource.new()
		if type_resource == null:
			print("Erreur : Impossible de créer une instance de TypeResource pour le type ", type_name)
			continue
		type_resource.type_name = type_name
		type_resource.sprite_path = "res://assets/sprites/types/" + type_name.to_lower() + ".png"
		var save_path = "res://data/types/" + type_name + ".tres"
		var error = ResourceSaver.save(type_resource, save_path)
		if error != OK:
			print("Erreur lors de la sauvegarde de ", save_path, ": ", error)

func import_moves():
	var csv_path = "res://assets/data/move-data.csv"
	var move_list = load_moves_csv(csv_path)
	var type_resources = load_type_resources()
	
	for move_data in move_list:
		var move_resource = MoveResource.new()
		
		# Id de l'attaque
		var move_id = move_data.get("Index", "").strip_edges()
		move_resource.move_id = int(move_id) if move_id.is_valid_int() else 0
		
		# Nom de l'attaque en anglais
		var move_name_en = move_data.get("Name", "").strip_edges()
		move_resource.move_name = {
			"en": move_name_en,
			"fr": move_name_en
		}
		
		# Type de l'attaque
		var type_name = move_data.get("Type", "").strip_edges()
		if type_resources.has(type_name):
			move_resource.move_type = type_resources[type_name]
		else:
			print("Type inconnu pour l'attaque : " + move_name_en)
		
		# Catégorie
		move_resource.category = move_data.get("Category", "").strip_edges()
		
		# Contest
		move_resource.contest = move_data.get("Contest", "").strip_edges()
		
		# Puissance
		var power_str = move_data.get("Power", "").strip_edges()
		move_resource.power = int(power_str) if power_str.is_valid_int() else 0
		
		# Précision
		var accuracy_str = move_data.get("Accuracy", "").strip_edges()
		move_resource.accuracy = int(accuracy_str) if accuracy_str.is_valid_int() else 0
		
		# PP
		var pp_str = move_data.get("PP", "").strip_edges()
		move_resource.pp = int(pp_str) if pp_str.is_valid_int() else 0
		
		# Génération
		var generation_str = move_data.get("Generation", "").strip_edges()
		move_resource.generation = int(generation_str) if generation_str.is_valid_int() else 0
		
		# Descriptions
		move_resource.descriptions = {
			"en": "Description not available yet.",
			"fr": "Description non disponible pour le moment."
		}
		
		# TM ID
		move_resource.tm_id = ""
		
		# Sauvegarder la ressource
		var sanitized_name = sanitize_filename(move_resource.move_name["en"]).replace(" ", "_")
		var save_path = "res://data/moves/" + str(move_resource.move_id) + "_" + sanitized_name + ".tres"
		var error = ResourceSaver.save(move_resource, save_path)
		if error != OK:
			print("Erreur lors de la sauvegarde de ", save_path, ": ", error)

func import_move_names():
	var csv_path = "res://assets/data/move_names.csv"
	var move_names_list = load_move_names_csv(csv_path)
	
	var move_id_to_french = {}
	
	for move_name_data in move_names_list:
		var move_id_str = move_name_data.get("move_id", "").strip_edges()
		var local_lang_id_str = move_name_data.get("local_language_id", "").strip_edges()
		var name = move_name_data.get("name", "").strip_edges()
		
		var move_id = int(move_id_str) if move_id_str.is_valid_int() else -1
		var local_lang_id = int(local_lang_id_str) if local_lang_id_str.is_valid_int() else -1
		
		if local_lang_id == 5 and move_id != -1:
			move_id_to_french[move_id] = name
	
	var moves_dir = "res://data/moves/"
	var dir = DirAccess.open(moves_dir)
	if dir == null:
		print("Erreur : Impossible d'accéder au dossier des moves pour la mise à jour des noms français.")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var files_updated = 0
	var files_missing_french = 0
	var move_ids_not_found = []
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var move_resource_path = moves_dir + file_name
			var move_resource = ResourceLoader.load(move_resource_path)
			
			if move_resource is MoveResource:
				var current_move_id = move_resource.move_id
				if move_id_to_french.has(current_move_id):
					var french_name = move_id_to_french[current_move_id]
					move_resource.move_name["fr"] = french_name
					var error = ResourceSaver.save(move_resource, move_resource_path)
					if error == OK:
						files_updated += 1
						print("Mis à jour : ", file_name, " avec le nom français '", french_name, "'.")
					else:
						print("Erreur lors de la sauvegarde de ", move_resource_path, ": ", error)
				else:
					files_missing_french += 1
					move_ids_not_found.append(current_move_id)
			else:
				print("Erreur : Le fichier ", file_name, " n'est pas une ressource MoveResource valide.")
		file_name = dir.get_next()
	dir.list_dir_end()
	
	print("Mise à jour des noms français des moves terminée.")
	print("Fichiers mis à jour : ", files_updated)
	if files_missing_french > 0:
		print("Fichiers sans nom français trouvé : ", files_missing_french)
		print("move_ids sans noms français : ", move_ids_not_found)
	else:
		print("Tous les moves ont un nom français.")

func clean_old_moves():
	var moves_dir = "res://data/moves/"
	var dir = DirAccess.open(moves_dir)
	if dir == null:
		print("Erreur : Impossible d'accéder au dossier des moves.")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	var files_deleted = 0

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var base_name = file_name.get_basename()
			if base_name.size() > 0:
				var first_char = base_name.substr(0, 1)
				var is_letter = (first_char >= 'A' and first_char <= 'Z') or (first_char >= 'a' and first_char <= 'z')
				if is_letter:
					var file_path = moves_dir + file_name
					var remove_error = dir.remove(file_name)
					if remove_error == OK:
						files_deleted += 1
						print("Supprimé : ", file_name)
					else:
						print("Erreur lors de la suppression de ", file_path, ": ", remove_error)
		file_name = dir.get_next()
	dir.list_dir_end()

	if files_deleted > 0:
		print("Nettoyage des moves effectué : ", files_deleted, " fichiers supprimés.")
	else:
		print("Aucun fichier à supprimer dans ", moves_dir)

func load_pokemon_csv(csv_path: String) -> Array:
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		print("Erreur : Impossible d'ouvrir le fichier CSV.")
		return []

	var headers: Array = []
	var pokemon_list: Array = []

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line == "":
			continue

		var values = parse_csv_line(line)
		if headers.size() == 0:
			headers = values
			continue

		while values.size() < headers.size():
			values.append("")

		var pokemon_data: Dictionary = {}
		for i in range(headers.size()):
			pokemon_data[headers[i]] = values[i] if i < values.size() else ""
		pokemon_list.append(pokemon_data)

	file.close()
	return pokemon_list

func extract_unique_abilities(pokemon_list: Array) -> Array:
	var ability_names: Dictionary = {}
	for pokemon_data in pokemon_list:
		var ability1_name = pokemon_data.get("Ability1", "").strip_edges()
		var ability2_name = pokemon_data.get("Ability2", "").strip_edges()
		var ability_hidden_name = pokemon_data.get("Ability_Hidden", "").strip_edges()
		if ability1_name != "":
			ability_names[ability1_name] = true
		if ability2_name != "":
			ability_names[ability2_name] = true
		if ability_hidden_name != "":
			ability_names[ability_hidden_name] = true
	return ability_names.keys()

func import_abilities(ability_names: Array):
	for ability_name in ability_names:
		var ability_resource = AbilityResource.new()
		ability_resource.ability_name = ability_name
		ability_resource.descriptions = {
			"en": "Description not available yet.",
			"fr": "Description non disponible pour le moment."
		}
		var save_path = "res://data/abilities/" + sanitize_filename(ability_name) + ".tres"
		var error = ResourceSaver.save(ability_resource, save_path)
		if error != OK:
			print("Erreur lors de la sauvegarde de ", save_path, ": ", error)

func load_moves_csv(csv_path: String) -> Array:
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		print("Erreur : Impossible d'ouvrir le fichier des attaques.")
		return []
	
	var headers: Array = []
	var move_list: Array = []
	
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line == "":
			continue
		
		var values = parse_csv_line(line)
		if headers.size() == 0:
			headers = values
			continue
		
		while values.size() < headers.size():
			values.append("")
		
		var move_data: Dictionary = {}
		for i in range(headers.size()):
			move_data[headers[i]] = values[i] if i < values.size() else ""
		move_list.append(move_data)
	
	file.close()
	return move_list

func load_move_names_csv(csv_path: String) -> Array:
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		print("Erreur : Impossible d'ouvrir le fichier move_names.csv.")
		return []
	
	var headers: Array = []
	var move_names_list: Array = []
	
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line == "":
			continue
		
		var values = parse_csv_line(line)
		if headers.size() == 0:
			headers = values
			continue
		
		while values.size() < headers.size():
			values.append("")
		
		var move_name_data: Dictionary = {}
		for i in range(headers.size()):
			move_name_data[headers[i]] = values[i] if i < values.size() else ""
		move_names_list.append(move_name_data)
	
	file.close()
	return move_names_list

func sanitize_filename(name: String) -> String:
	var invalid_chars: Array = ['\\', '/', ':', '*', '?', '"', '<', '>', '|', ',', "'", ' ']
	var sanitized_name: String = name
	for char in invalid_chars:
		sanitized_name = sanitized_name.replace(char, '_')
	return sanitized_name

func parse_csv_line(line: String) -> Array:
	var result: Array = []
	var inside_quotes: bool = false
	var value: String = ""
	var i: int = 0
	while i < line.length():
		var char: String = line[i]
		if char == '"' and (i == 0 or line[i - 1] != '\\'):
			inside_quotes = not inside_quotes
		elif char == ',' and not inside_quotes:
			result.append(value)
			value = ""
		else:
			value += char
		i += 1
	result.append(value)
	return result

func load_type_resources() -> Dictionary:
	var type_resources: Dictionary = {}
	var dir = DirAccess.open("res://data/types/")
	if dir == null:
		print("Erreur : Impossible d'accéder au dossier des types.")
		return type_resources

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var type_resource = ResourceLoader.load("res://data/types/" + file_name)
				if type_resource is TypeResource:
					type_resources[type_resource.type_name] = type_resource
		file_name = dir.get_next()
	dir.list_dir_end()
	return type_resources

func load_ability_resources() -> Dictionary:
	var ability_resources: Dictionary = {}
	var dir = DirAccess.open("res://data/abilities/")
	if dir == null:
		print("Erreur : Impossible d'accéder au dossier des abilities.")
		return ability_resources

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var ability_resource = ResourceLoader.load("res://data/abilities/" + file_name)
				if ability_resource is AbilityResource:
					ability_resources[ability_resource.ability_name] = ability_resource
		file_name = dir.get_next()
	dir.list_dir_end()
	return ability_resources

func has_female_sprite(pokemon_id: int) -> bool:
	var female_sprite_ids: Array = [
		3, 12, 19, 20, 25, 26, 41, 42, 44, 45, 64, 65, 84, 85, 97, 111, 112,
		118, 119, 123, 129, 130, 154, 165, 166, 178, 185, 186, 190, 194, 195, 198,
		202, 203, 207, 208, 212, 214, 215, 217, 221, 224, 229, 232, 255, 256, 257,
		267, 269, 272, 274, 275, 307, 308, 315, 316, 317, 322, 323, 332, 350, 369,
		396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 407, 415, 417, 418, 419,
		424, 443, 444, 445, 449, 450, 453, 454, 456, 457, 459, 460, 461, 464, 465,
		473, 521, 592, 593, 668, 678, 876
	]
	return female_sprite_ids.has(pokemon_id)

func import_pokemon(pokemon_list: Array):
	var type_resources = load_type_resources()
	var ability_resources = load_ability_resources()
	
	for pokemon_data in pokemon_list:
		var pokemon_resource = PokemonResource.new()
		
		pokemon_resource.pokemon_id = int(pokemon_data.get("No", "0")) if pokemon_data.get("No", "").is_valid_int() else 0
		
		pokemon_resource.names = {
			"en": pokemon_data.get("Name", "").strip_edges(),
			"fr": pokemon_data.get("Name", "").strip_edges()  # Ajout du français si nécessaire
		}
		
		pokemon_resource.generation = int(pokemon_data.get("Generation", "0")) if pokemon_data.get("Generation", "").is_valid_int() else 0
		
		pokemon_resource.height = float(pokemon_data.get("Height", "0")) if pokemon_data.get("Height", "").is_valid_float() else 0.0
		pokemon_resource.weight = float(pokemon_data.get("Weight", "0")) if pokemon_data.get("Weight", "").is_valid_float() else 0.0
		
		pokemon_resource.types = []
		var type1_name = pokemon_data.get("Type1", "").strip_edges()
		var type2_name = pokemon_data.get("Type2", "").strip_edges()
		if type1_name != "" and type_resources.has(type1_name):
			pokemon_resource.types.append(type_resources[type1_name])
		if type2_name != "" and type_resources.has(type2_name):
			pokemon_resource.types.append(type_resources[type2_name])
		
		pokemon_resource.abilities = []
		var abilities = [
			pokemon_data.get("Ability1", "").strip_edges(),
			pokemon_data.get("Ability2", "").strip_edges(),
			pokemon_data.get("Ability_Hidden", "").strip_edges()
		]
		for ability_name in abilities:
			if ability_name != "":
				if ability_resources.has(ability_name):
					pokemon_resource.abilities.append(ability_resources[ability_name])
				else:
					print("Warning: Ability '" + ability_name + "' not found for Pokémon " + pokemon_resource.names["en"])
		
		pokemon_resource.color = pokemon_data.get("Color", "").strip_edges()
		
		var male_ratio = float(pokemon_data.get("Gender_Male", "0")) if pokemon_data.get("Gender_Male", "").is_valid_float() else 0.0
		var female_ratio = float(pokemon_data.get("Gender_Female", "0")) if pokemon_data.get("Gender_Female", "").is_valid_float() else 0.0
		var unknown_ratio = float(pokemon_data.get("Gender_Unknown", "0")) if pokemon_data.get("Gender_Unknown", "").is_valid_float() else 0.0
		pokemon_resource.gender_ratio = {
			"male": male_ratio,
			"female": female_ratio,
			"unknown": unknown_ratio
		}
		
		pokemon_resource.egg_steps = int(pokemon_data.get("Egg_Steps", "0")) if pokemon_data.get("Egg_Steps", "").is_valid_int() else 0
		
		pokemon_resource.egg_groups = []
		var egg_group1 = pokemon_data.get("Egg_Group1", "").strip_edges()
		var egg_group2 = pokemon_data.get("Egg_Group2", "").strip_edges()
		if egg_group1 != "":
			pokemon_resource.egg_groups.append(egg_group1)
		if egg_group2 != "":
			pokemon_resource.egg_groups.append(egg_group2)
		
		pokemon_resource.catch_rate = int(pokemon_data.get("Get_Rate", "0")) if pokemon_data.get("Get_Rate", "").is_valid_int() else 0
		
		pokemon_resource.base_experience = int(pokemon_data.get("Base_Experience", "0")) if pokemon_data.get("Base_Experience", "").is_valid_int() else 0
		
		pokemon_resource.experience_type = pokemon_data.get("Experience_Type", "").strip_edges()
		
		pokemon_resource.category = pokemon_data.get("Category", "").strip_edges()
		
		pokemon_resource.mega_evolution_flag = pokemon_data.get("Mega_Evolution_Flag", "").strip_edges() == "Mega"
		
		var branch_code = pokemon_data.get("Branch_Code", "").strip_edges()
		
		pokemon_resource.region_form = pokemon_data.get("Region_Form", "").strip_edges()
		
		pokemon_resource.base_stats = {
			"hp": int(pokemon_data.get("HP", "0")) if pokemon_data.get("HP", "").is_valid_int() else 0,
			"attack": int(pokemon_data.get("Attack", "0")) if pokemon_data.get("Attack", "").is_valid_int() else 0,
			"defense": int(pokemon_data.get("Defense", "0")) if pokemon_data.get("Defense", "").is_valid_int() else 0,
			"special_attack": int(pokemon_data.get("SP_Attack", "0")) if pokemon_data.get("SP_Attack", "").is_valid_int() else 0,
			"special_defense": int(pokemon_data.get("SP_Defense", "0")) if pokemon_data.get("SP_Defense", "").is_valid_int() else 0,
			"speed": int(pokemon_data.get("Speed", "0")) if pokemon_data.get("Speed", "").is_valid_int() else 0,
			"total": int(pokemon_data.get("Total", "0")) if pokemon_data.get("Total", "").is_valid_int() else 0
		}
		
		pokemon_resource.effort_points = {
			"hp": int(pokemon_data.get("E_HP", "0")) if pokemon_data.get("E_HP", "").is_valid_int() else 0,
			"attack": int(pokemon_data.get("E_Attack", "0")) if pokemon_data.get("E_Attack", "").is_valid_int() else 0,
			"defense": int(pokemon_data.get("E_Defense", "0")) if pokemon_data.get("E_Defense", "").is_valid_int() else 0,
			"special_attack": int(pokemon_data.get("E_SP_Attack", "0")) if pokemon_data.get("E_SP_Attack", "").is_valid_int() else 0,
			"special_defense": int(pokemon_data.get("E_SP_Defense", "0")) if pokemon_data.get("E_SP_Defense", "").is_valid_int() else 0,
			"speed": int(pokemon_data.get("E_Speed", "0")) if pokemon_data.get("E_Speed", "").is_valid_int() else 0
		}
		
		var pokemon_id_str = str(pokemon_resource.pokemon_id)
		var sprite_base_name = pokemon_id_str
		
		var form_identifier = ""
		
		if pokemon_resource.mega_evolution_flag:
			if pokemon_resource.pokemon_id == 6:
				if branch_code == "6_1":
					form_identifier = "mega-x"
				elif branch_code == "6_2":
					form_identifier = "mega-y"
				else:
					form_identifier = "mega"
			elif pokemon_resource.pokemon_id == 150:
				if branch_code == "150_1":
					form_identifier = "mega-x"
				elif branch_code == "150_2":
					form_identifier = "mega-y"
				else:
					form_identifier = "mega"
			else:
				form_identifier = "mega"
		elif pokemon_resource.pokemon_id == 382 and branch_code == "382_1":
			form_identifier = "primal"
		elif pokemon_resource.pokemon_id == 383 and branch_code == "383_1":
			form_identifier = "primal"
		elif pokemon_resource.region_form != "":
			var region_form_lower = pokemon_resource.region_form.to_lower()
			match region_form_lower:
				"alolan", "alola":
					form_identifier = "alola"
				"galarian", "galar":
					form_identifier = "galar"
				"hisuian", "hisui":
					form_identifier = "hisui"
				"paldean", "paldea":
					form_identifier = "paldea"
				_:
					form_identifier = pokemon_resource.region_form.replace(" ", "_").replace("'", "").replace(".", "").to_lower()
		
		if form_identifier != "":
			sprite_base_name += "-" + form_identifier
		
		var sprite_folder = "res://assets/sprites/pokemon/"
		var back_folder = sprite_folder + "back/"
		var shiny_folder = sprite_folder + "shiny/"
		var shiny_back_folder = shiny_folder + "back/"
		var female_folder = sprite_folder + "female/"
		var female_back_folder = female_folder + "back/"
		var shiny_female_folder = shiny_folder + "female/"
		var shiny_female_back_folder = shiny_female_folder + "back/"
		
		pokemon_resource.sprite_normal_front = sprite_folder + sprite_base_name + ".png"
		pokemon_resource.sprite_normal_back = back_folder + sprite_base_name + ".png"
		
		pokemon_resource.sprite_shiny_front = shiny_folder + sprite_base_name + ".png"
		pokemon_resource.sprite_shiny_back = shiny_back_folder + sprite_base_name + ".png"
		
		if has_female_sprite(pokemon_resource.pokemon_id):
			pokemon_resource.sprite_female_front = female_folder + sprite_base_name + ".png"
			pokemon_resource.sprite_female_back = female_back_folder + sprite_base_name + ".png"
			
			pokemon_resource.sprite_shiny_female_front = shiny_female_folder + sprite_base_name + ".png"
			pokemon_resource.sprite_shiny_female_back = shiny_female_back_folder + sprite_base_name + ".png"
		else:
			pokemon_resource.sprite_female_front = ""
			pokemon_resource.sprite_female_back = ""
			pokemon_resource.sprite_shiny_female_front = ""
			pokemon_resource.sprite_shiny_female_back = ""
		
		var save_file_name = pokemon_id_str + "_" + sanitize_filename(pokemon_resource.names["en"]).replace(" ", "_") + ".tres"
		var save_path = "res://data/pokemon/" + save_file_name
		var error = ResourceSaver.save(pokemon_resource, save_path)
		if error != OK:
			print("Erreur lors de la sauvegarde de ", save_path, ": ", error)

func load_pokemon_resources() -> Dictionary:
	var pokemon_resources: Dictionary = {}
	var dir = DirAccess.open("res://data/pokemon/")
	if dir == null:
		print("Erreur : Impossible d'accéder au dossier des Pokémons.")
		return pokemon_resources
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var pokemon_resource = ResourceLoader.load("res://data/pokemon/" + file_name)
			if pokemon_resource is PokemonResource:
				pokemon_resources[pokemon_resource.pokemon_id] = pokemon_resource
		file_name = dir.get_next()
	dir.list_dir_end()
	return pokemon_resources
