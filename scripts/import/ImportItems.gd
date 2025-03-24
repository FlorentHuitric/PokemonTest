extends Node

# Chemins des fichiers
const CSV_PATH = "res://imports/"
const OUTPUT_PATH = "res://data/items/"

# Langues supportées
const LANGUAGES = {
	"5": "fr",  # Français - Notez que les clés sont maintenant des chaînes
	"9": "en"   # Anglais
}

# Données importées
var items_data = []
var item_names_data = []
var item_prose_data = []
var item_pockets_data = []
var item_pocket_names_data = []
var item_categories_data = []
var item_category_prose_data = []
var item_flavor_text_data = []
var item_flags_data = []
var item_flag_prose_data = []
var item_flag_map_data = []
var item_fling_effects_data = []
var item_fling_effect_prose_data = []
var item_game_indices_data = []

# Mappings pour faciliter les recherches
var category_to_pocket = {}
var flag_names = {}
var fling_effects = {}

func _ready():
	print("Démarrage de l'importation des items...")
	
	# S'assurer que le dossier de sortie existe
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("data/items"):
		dir.make_dir_recursive("data/items")
	
	# Charger toutes les données CSV
	load_all_csv_data()
	
	# Préparer les mappings
	prepare_mappings()
	
	# Ajouter les traductions françaises manquantes
	add_missing_french_translations()
	
	# Tester la récupération des données pour un item spécifique
	var test_id = "1"  # Master Ball
	print("\nTest de récupération pour l'item ID ", test_id)
	print("Noms: ", get_translations_for_item(test_id, item_names_data, "item_id", "name"))
	print("Catégorie: ", get_translations("34", item_category_prose_data, "item_category_id", "name"))
	print("Poche: ", get_translations("3", item_pocket_names_data, "item_pocket_id", "name"))
	print("Prose: ", get_item_prose(test_id))
	print("Flavor text: ", get_flavor_text(test_id))
	print("Flags: ", get_flags_for_item(test_id))
	
	# Générer les ressources d'items
	generate_item_resources()
	
	print("Importation des items terminée.")

func load_all_csv_data():
	print("Chargement des fichiers CSV...")
	
	# Vérification des chemins de fichiers avant le chargement
	print("Vérification du chemin: ", CSV_PATH)
	var dir = DirAccess.open(CSV_PATH)
	if dir == null:
		print("Erreur d'accès au dossier CSV: ", CSV_PATH, " - Erreur: ", DirAccess.get_open_error())
	else:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		print("Fichiers dans le dossier:")
		while file_name != "":
			if not file_name.begins_with("."):
				print("- ", file_name)
			file_name = dir.get_next()
	
	items_data = load_csv(CSV_PATH + "items.csv")
	item_names_data = load_csv(CSV_PATH + "item_names.csv")
	item_prose_data = load_csv(CSV_PATH + "item_prose.csv")
	item_pockets_data = load_csv(CSV_PATH + "item_pockets.csv")
	item_pocket_names_data = load_csv(CSV_PATH + "item_pocket_names.csv")
	item_categories_data = load_csv(CSV_PATH + "item_categories.csv")
	item_category_prose_data = load_csv(CSV_PATH + "item_category_prose.csv")
	item_flavor_text_data = load_csv(CSV_PATH + "item_flavor_text.csv")
	item_flags_data = load_csv(CSV_PATH + "item_flags.csv")
	item_flag_prose_data = load_csv(CSV_PATH + "item_flag_prose.csv")
	item_flag_map_data = load_csv(CSV_PATH + "item_flag_map.csv")
	item_fling_effects_data = load_csv(CSV_PATH + "item_fling_effects.csv")
	item_fling_effect_prose_data = load_csv(CSV_PATH + "item_fling_effect_prose.csv")
	item_game_indices_data = load_csv(CSV_PATH + "item_game_indices.csv")

func load_csv(file_path: String) -> Array:
	var data = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		print("Erreur lors de l'ouverture du fichier: ", file_path, " - Erreur: ", FileAccess.get_open_error())
		return data
	
	var headers = file.get_line().split(",")
	
	# Afficher les en-têtes pour le débogage
	print("En-têtes pour ", file_path, ": ", headers)
	
	while !file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
			
		var values = line.split(",")
		var row = {}
		
		for i in range(min(headers.size(), values.size())):
			row[headers[i]] = values[i]
			
		data.append(row)
	
	print("Chargé: ", file_path, " (", data.size(), " lignes)")
	
	# Afficher quelques exemples de données pour le débogage
	if data.size() > 0:
		print("Exemple de données pour ", file_path, ": ", data[0])
	
	return data

func prepare_mappings():
	print("Préparation des mappings...")
	
	# Mapping catégorie vers poche
	for category in item_categories_data:
		category_to_pocket[category.get("id", "0")] = category.get("pocket_id", "1")
	
	# Mapping drapeaux
	for flag in item_flags_data:
		flag_names[flag.get("id", "0")] = flag.get("identifier", "")
	
	# Mapping effets de lancer
	for effect in item_fling_effects_data:
		fling_effects[effect.get("id", "0")] = effect.get("identifier", "")
	
	# Afficher les mappings pour le débogage
	print("Nombre de catégories mappées: ", category_to_pocket.size())
	print("Exemple de catégorie: ", category_to_pocket.get("1", "non trouvé"))
	print("Nombre de drapeaux mappés: ", flag_names.size())
	print("Exemple de drapeau: ", flag_names.get("1", "non trouvé"))

func add_missing_french_translations():
	print("Ajout des traductions françaises manquantes...")
	
	# Traduction des effets de lancer (fling effects)
	var fr_fling_effects = {
		"1": "Empoisonne gravement la cible.",
		"2": "Brûle la cible.",
		"3": "Active immédiatement l'effet de la baie sur la cible.",
		"4": "Active immédiatement l'effet de l'herbe sur la cible.",
		"5": "Paralyse la cible.",
		"6": "Empoisonne la cible.",
		"7": "La cible va tressaillir si elle n'a pas encore agi ce tour."
	}
	
	# Ajouter les traductions françaises pour les effets de lancer
	for effect_id in fr_fling_effects:
		var effect_fr = fr_fling_effects[effect_id]
		var found = false
		for prose in item_fling_effect_prose_data:
			if prose.get("item_fling_effect_id", "0") == effect_id and prose.get("local_language_id", "0") == "5":
				found = true
				break
		
		if not found:
			item_fling_effect_prose_data.append({
				"item_fling_effect_id": effect_id,
				"local_language_id": "5",
				"effect": effect_fr
			})
	
	# Traductions françaises pour les drapeaux d'items
	var fr_flags = {
		"1": {"name": "Comptable", "description": "A un compteur dans le sac"},
		"2": {"name": "Consommable", "description": "Consommé lors de l'utilisation"},
		"3": {"name": "Utilisable_monde", "description": "Utilisable hors combat"},
		"4": {"name": "Utilisable_combat", "description": "Utilisable en combat"},
		"5": {"name": "Tenable", "description": "Peut être tenu par un Pokémon"},
		"6": {"name": "Tenable_passif", "description": "Fonctionne passivement quand tenu"},
		"7": {"name": "Tenable_actif", "description": "Utilisable par un Pokémon quand tenu"},
		"8": {"name": "Souterrain", "description": "Apparaît dans le Souterrain de Sinnoh"}
	}
	
	# Ajouter les traductions françaises pour les drapeaux
	for flag_id in fr_flags:
		var flag_data = fr_flags[flag_id]
		var found = false
		for prose in item_flag_prose_data:
			if prose.get("item_flag_id", "0") == flag_id and prose.get("local_language_id", "0") == "5":
				found = true
				break
		
		if not found:
			item_flag_prose_data.append({
				"item_flag_id": flag_id,
				"local_language_id": "5",
				"name": flag_data.name,
				"description": flag_data.description
			})
	
	# Traductions françaises pour les catégories d'items
	var fr_categories = {
		"1": "Boost de stats",
		"2": "Réducteur d'EV",
		"3": "Médicament",
		"4": "Autre",
		"5": "En cas de besoin",
		"6": "Soin difficile",
		"7": "Protection de type"
	}
	
	# Ajouter les traductions françaises pour les catégories
	for cat_id in fr_categories:
		var cat_name = fr_categories[cat_id]
		var found = false
		for prose in item_category_prose_data:
			if prose.get("item_category_id", "0") == cat_id and prose.get("local_language_id", "0") == "5":
				found = true
				break
		
		if not found:
			item_category_prose_data.append({
				"item_category_id": cat_id,
				"local_language_id": "5",
				"name": cat_name
			})

func generate_item_resources():
	print("Génération des ressources d'items...")
	
	var created_count = 0
	
	for item in items_data:
		var item_id = item.get("id", "0")
		var identifier = item.get("identifier", "")
		
		print("\nTraitement de l'item ", item_id, " (", identifier, ")")
		
		# Créer une nouvelle ressource d'item
		var resource = ItemResource.new()
		resource.item_id = int(item_id)
		resource.identifier = identifier
		resource.cost = int(item.get("cost", "0"))
		
		var category_id = item.get("category_id", "0")
		if not category_id.is_empty():
			resource.category_id = int(category_id)
		
		# Déterminer la poche
		var pocket_id = category_to_pocket.get(category_id, "1")
		if not pocket_id.is_empty():
			resource.pocket_id = int(pocket_id)
		
		# Fling power et fling effect
		var fling_power = item.get("fling_power", "")
		if not fling_power.is_empty():
			resource.fling_power = int(fling_power)
			
		var fling_effect_id = item.get("fling_effect_id", "")
		if not fling_effect_id.is_empty():
			resource.fling_effect_id = int(fling_effect_id)
		
		# Ajouter les noms dans différentes langues
		resource.names = get_translations_for_item(item_id, item_names_data, "item_id", "name")
		print("Noms récupérés: ", resource.names)
		
		# Ajouter les noms de catégories
		if not category_id.is_empty():
			resource.category_name = get_translations(category_id, item_category_prose_data, "item_category_id", "name")
			print("Noms de catégorie récupérés: ", resource.category_name)
		
		# Ajouter les noms de poches
		if not pocket_id.is_empty():
			resource.pocket_name = get_translations(pocket_id, item_pocket_names_data, "item_pocket_id", "name")
			print("Noms de poche récupérés: ", resource.pocket_name)
		
		# Ajouter les effets et descriptions
		var prose_data = get_item_prose(item_id)
		if prose_data:
			resource.short_effect = prose_data.short_effect
			resource.effect = prose_data.effect
			print("Effets récupérés: ", resource.short_effect, resource.effect)
		
		# Ajouter les textes descriptifs
		resource.flavor_text = get_flavor_text(item_id)
		print("Textes descriptifs récupérés: ", resource.flavor_text)
		
		# Ajouter les effets de lancer
		if resource.fling_effect_id > 0:
			resource.fling_effect = get_translations(str(resource.fling_effect_id), item_fling_effect_prose_data, "item_fling_effect_id", "effect")
			print("Effets de lancer récupérés: ", resource.fling_effect)
		
		# Ajouter les drapeaux (flags)
		resource.flags = get_flags_for_item(item_id)
		print("Drapeaux récupérés: ", resource.flags)
		
		# Ajouter les informations de génération et d'index
		var game_index_data = get_game_index(item_id)
		if game_index_data:
			resource.generation_id = game_index_data.generation_id
			resource.game_index = game_index_data.game_index
		
		# Définir le chemin du sprite (format UPPERCASE)
		var sprite_name = format_sprite_name(identifier)
		resource.sprite_path = "res://assets/Items/" + sprite_name + ".png"
		
		# Vérifier si le sprite existe
		if not FileAccess.file_exists(resource.sprite_path):
			print("Attention: Sprite introuvable pour l'item ", item_id, " (", sprite_name, ")")
		
		# Sauvegarder la ressource
		var save_path = OUTPUT_PATH + "%03d_%s.tres" % [int(item_id), identifier]
		var error = ResourceSaver.save(resource, save_path)
		
		if error == OK:
			created_count += 1
		else:
			print("Erreur lors de l'enregistrement de l'item ", item_id, " (", identifier, "): ", error)
		
		# Limiter l'affichage de débogage aux premiers items seulement
		if created_count >= 5:
			print("\nLimitation du débogage aux 5 premiers items...")
			break
	
	# Poursuivre l'importation sans débogage extensif
	for i in range(created_count, items_data.size()):
		var item = items_data[i]
		var item_id = item.get("id", "0")
		var identifier = item.get("identifier", "")
		
		var resource = ItemResource.new()
		resource.item_id = int(item_id)
		resource.identifier = identifier
		resource.cost = int(item.get("cost", "0"))
		
		var category_id = item.get("category_id", "0")
		if not category_id.is_empty():
			resource.category_id = int(category_id)
		
		var pocket_id = category_to_pocket.get(category_id, "1")
		if not pocket_id.is_empty():
			resource.pocket_id = int(pocket_id)
			
		var fling_power = item.get("fling_power", "")
		if not fling_power.is_empty():
			resource.fling_power = int(fling_power)
			
		var fling_effect_id = item.get("fling_effect_id", "")
		if not fling_effect_id.is_empty():
			resource.fling_effect_id = int(fling_effect_id)
		
		resource.names = get_translations_for_item(item_id, item_names_data, "item_id", "name")
		resource.category_name = get_translations(category_id, item_category_prose_data, "item_category_id", "name")
		resource.pocket_name = get_translations(pocket_id, item_pocket_names_data, "item_pocket_id", "name")
		
		var prose_data = get_item_prose(item_id)
		if prose_data:
			resource.short_effect = prose_data.short_effect
			resource.effect = prose_data.effect
		
		resource.flavor_text = get_flavor_text(item_id)
		
		if resource.fling_effect_id > 0:
			resource.fling_effect = get_translations(str(resource.fling_effect_id), item_fling_effect_prose_data, "item_fling_effect_id", "effect")
		
		resource.flags = get_flags_for_item(item_id)
		
		var game_index_data = get_game_index(item_id)
		if game_index_data:
			resource.generation_id = game_index_data.generation_id
			resource.game_index = game_index_data.game_index
		
		var sprite_name = format_sprite_name(identifier)
		resource.sprite_path = "res://assets/Items/" + sprite_name + ".png"
		
		var save_path = OUTPUT_PATH + "%03d_%s.tres" % [int(item_id), identifier]
		var error = ResourceSaver.save(resource, save_path)
		
		if error == OK:
			created_count += 1
		
		# Afficher la progression tous les 100 items
		if created_count % 100 == 0:
			print("Progression: ", created_count, "/", items_data.size(), " items créés")
	
	print("Ressources créées: ", created_count, "/", items_data.size())

# Convertit l'identifiant de l'item au format des noms de sprites
func format_sprite_name(identifier: String) -> String:
	# Convertir "master-ball" en "MASTERBALL"
	var result = identifier.to_upper()
	result = result.replace("-", "")
	return result

func get_translations_for_item(item_id: String, data: Array, id_field: String, value_field: String) -> Dictionary:
	var translations = {}
	var found_entries = 0
	
	# Debug avancé
	print("\nDébogage détaillé pour la récupération de traductions:")
	print("Recherche dans le champ '", id_field, "' pour la valeur '", item_id, "'")
	print("Premier élément de données: ", data[0] if data.size() > 0 else "aucune donnée")
	
	# Compter combien d'entrées correspondent à cet ID
	var matching_entries = []
	for entry in data:
		if entry.get(id_field, "") == item_id:
			matching_entries.append(entry)
	print("Nombre d'entrées correspondantes trouvées: ", matching_entries.size())
	
	# Si aucune correspondance, afficher quelques exemples pour diagnostic
	if matching_entries.size() == 0:
		print("Échantillon de données (5 premiers éléments):")
		for i in range(min(5, data.size())):
			print("  Entrée ", i, ": ", data[i])
	
	for entry in data:
		if entry.get(id_field, "") == item_id:
			var lang_id = entry.get("local_language_id", "")
			if lang_id == null:
				lang_id = entry.get("language_id", "")
			
			print("Entrée trouvée pour ID ", item_id, ", langue ", lang_id)
			
			if lang_id in LANGUAGES:
				var lang_code = LANGUAGES[lang_id]
				var value = entry.get(value_field, "")
				translations[lang_code] = value
				print("  Ajout de la traduction [", lang_code, "]: ", value)
				found_entries += 1
			else:
				print("  Langue ", lang_id, " non prise en charge")
	
	print("Total des traductions récupérées: ", found_entries)
	return translations

func get_translations(id: String, data: Array, id_field: String, value_field: String) -> Dictionary:
	var translations = {}
	var found_entries = 0
	
	print("\nDébogage pour ", id_field, " = ", id, ":")
	
	for entry in data:
		if entry.get(id_field, "") == id:
			var lang_id = entry.get("local_language_id", "")
			if lang_id == null:
				lang_id = entry.get("language_id", "")
			
			if lang_id in LANGUAGES:
				var lang_code = LANGUAGES[lang_id]
				var value = entry.get(value_field, "")
				translations[lang_code] = value
				print("  Trouvé traduction [", lang_code, "]: ", value)
				found_entries += 1
	
	print("Total des traductions pour ", id_field, "=", id, ": ", found_entries)
	return translations

func get_item_prose(item_id: String) -> Dictionary:
	var result = {
		"short_effect": {},
		"effect": {}
	}
	
	print("\nDébogage effets pour item_id = ", item_id, ":")
	var found = 0
	
	for prose in item_prose_data:
		if prose.get("item_id", "") == item_id:
			var lang_id = prose.get("local_language_id", "")
			if lang_id in LANGUAGES:
				var lang_code = LANGUAGES[lang_id]
				result.short_effect[lang_code] = prose.get("short_effect", "")
				result.effect[lang_code] = prose.get("effect", "").replace("\\n", "\n")
				print("  Trouvé effet [", lang_code, "]")
				found += 1
	
	print("Total des effets trouvés: ", found)
	return result

func get_flavor_text(item_id: String) -> Dictionary:
	var result = {}
	
	print("\nDébogage flavor text pour item_id = ", item_id, ":")
	var found = 0
	
	for flavor in item_flavor_text_data:
		if flavor.get("item_id", "") == item_id:
			var lang_id = flavor.get("language_id", "")
			if lang_id in LANGUAGES:
				result[LANGUAGES[lang_id]] = flavor.get("flavor_text", "").replace("\\n", "\n")
				print("  Trouvé flavor text [", LANGUAGES[lang_id], "]")
				found += 1
	
	print("Total des flavor texts trouvés: ", found)
	return result

func get_flags_for_item(item_id: String) -> Array[String]:
	var flags: Array[String] = []
	
	for flag_map in item_flag_map_data:
		if flag_map.get("item_id", "0") == item_id:
			var flag_id = flag_map.get("item_flag_id", "0")
			var flag_name = flag_names.get(flag_id, "")
			if flag_name:
				flags.append(flag_name)
	
	return flags

func get_game_index(item_id: String) -> Dictionary:
	for index_entry in item_game_indices_data:
		if index_entry.get("item_id", "0") == item_id:
			return {
				"generation_id": int(index_entry.get("generation_id", "0")),
				"game_index": int(index_entry.get("game_index", "0"))
			}
	
	return {}
