extends Resource
class_name PokemonInstance

# Référence à la ressource de base du Pokémon
@export var base_pokemon: PokemonResource
@export var nickname: String = ""
@export var level: int = 1
@export var experience: int = 0
@export var gender: String = ""  # "male", "female", "unknown"
@export var is_shiny: bool = false
@export var nature: String = ""
@export var ability_index: int = 0  # Index dans le tableau d'abilities du Pokémon de base

# Valeurs individuelles (IVs) - générées aléatoirement entre 0 et 31
@export var ivs: Dictionary = {
	"hp": 0,
	"attack": 0,
	"defense": 0,
	"special_attack": 0,
	"special_defense": 0,
	"speed": 0
}

# Valeurs d'effort (EVs) - max 252 par stat, 510 au total
@export var evs: Dictionary = {
	"hp": 0,
	"attack": 0,
	"defense": 0,
	"special_attack": 0,
	"special_defense": 0,
	"speed": 0
}

# Moves actuels (maximum 4)
@export var current_moves: Array[Dictionary] = []
# Structure d'un move:
# {
#    "move_id": 0,       # ID du move
#    "pp_current": 0,    # PP actuels
#    "pp_max": 0         # PP maximum
# }

# Stats calculées
var current_stats: Dictionary = {}

# Constantes pour la génération de Pokémon
const SHINY_CHANCE = 4096  # 1/4096 chance d'être shiny
const MAX_EVS_TOTAL = 510
const MAX_EVS_PER_STAT = 252

# Dictionnaire des natures et leurs effets (augmente une stat de 10%, diminue une autre de 10%)
const NATURES = {
	"Hardy": {"increase": null, "decrease": null},
	"Lonely": {"increase": "attack", "decrease": "defense"},
	"Brave": {"increase": "attack", "decrease": "speed"},
	"Adamant": {"increase": "attack", "decrease": "special_attack"},
	"Naughty": {"increase": "attack", "decrease": "special_defense"},
	"Bold": {"increase": "defense", "decrease": "attack"},
	"Docile": {"increase": null, "decrease": null},
	"Relaxed": {"increase": "defense", "decrease": "speed"},
	"Impish": {"increase": "defense", "decrease": "special_attack"},
	"Lax": {"increase": "defense", "decrease": "special_defense"},
	"Timid": {"increase": "speed", "decrease": "attack"},
	"Hasty": {"increase": "speed", "decrease": "defense"},
	"Serious": {"increase": null, "decrease": null},
	"Jolly": {"increase": "speed", "decrease": "special_attack"},
	"Naive": {"increase": "speed", "decrease": "special_defense"},
	"Modest": {"increase": "special_attack", "decrease": "attack"},
	"Mild": {"increase": "special_attack", "decrease": "defense"},
	"Quiet": {"increase": "special_attack", "decrease": "speed"},
	"Bashful": {"increase": null, "decrease": null},
	"Rash": {"increase": "special_attack", "decrease": "special_defense"},
	"Calm": {"increase": "special_defense", "decrease": "attack"},
	"Gentle": {"increase": "special_defense", "decrease": "defense"},
	"Sassy": {"increase": "special_defense", "decrease": "speed"},
	"Careful": {"increase": "special_defense", "decrease": "special_attack"},
	"Quirky": {"increase": null, "decrease": null}
}

# Types d'expérience avec leurs formules
const EXP_TYPES = {
	"erratic": 0,      # 0: Erratic
	"fast": 1,         # 1: Fast
	"medium_fast": 2,  # 2: Medium Fast (aussi appelé "Standard")
	"medium_slow": 3,  # 3: Medium Slow
	"slow": 4,         # 4: Slow
	"fluctuating": 5   # 5: Fluctuating
}

func _init(pokemon_resource: PokemonResource = null, init_level: int = 5) -> void:
	if pokemon_resource:
		base_pokemon = pokemon_resource
		level = init_level
		generate_random_ivs()
		determine_gender()
		determine_nature()
		determine_shiny()
		select_ability()
		initialize_stats()
		set_initial_moves()
		calculate_experience()

# Générer des IVs aléatoires
func generate_random_ivs() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for stat in ivs.keys():
		var min_val = base_pokemon.iv_ranges[stat].min
		var max_val = base_pokemon.iv_ranges[stat].max
		ivs[stat] = rng.randi_range(min_val, max_val)

# Déterminer le genre en fonction des ratios de genre du Pokémon
func determine_gender() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var random_value = rng.randf() * 100.0
	
	if base_pokemon.gender_ratio.unknown > 0:
		gender = "unknown"
	elif random_value < base_pokemon.gender_ratio.female:
		gender = "female"
	else:
		gender = "male"

# Sélectionner une nature aléatoire
func determine_nature() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var nature_names = NATURES.keys()
	nature = nature_names[rng.randi() % nature_names.size()]

# Déterminer si le Pokémon est shiny
func determine_shiny() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	is_shiny = rng.randi_range(1, SHINY_CHANCE) == 1

# Sélectionner une capacité parmi celles disponibles
func select_ability() -> void:
	if base_pokemon.abilities.size() == 0:
		return
		
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	ability_index = rng.randi() % base_pokemon.abilities.size()

# Initialiser les stats en fonction du niveau, IVs, EVs
func initialize_stats() -> void:
	calculate_stats()

# Calculer les stats en fonction du niveau, IVs, EVs et de la nature
func calculate_stats() -> void:
	var nature_mod = {
		"hp": 1.0,
		"attack": 1.0,
		"defense": 1.0,
		"special_attack": 1.0,
		"special_defense": 1.0,
		"speed": 1.0
	}
	
	# Appliquer les modificateurs de nature
	if NATURES[nature].increase != null:
		nature_mod[NATURES[nature].increase] = 1.1
	if NATURES[nature].decrease != null:
		nature_mod[NATURES[nature].decrease] = 0.9
	
	# Calculer HP
	var hp_base = base_pokemon.base_stats.hp
	var hp = floor(((2 * hp_base + ivs.hp + floor(evs.hp / 4)) * level) / 100) + level + 10
	current_stats.hp = hp
	
	# Calculer les autres stats
	for stat in ["attack", "defense", "special_attack", "special_defense", "speed"]:
		var base = base_pokemon.base_stats[stat]
		var stat_value = floor(((2 * base + ivs[stat] + floor(evs[stat] / 4)) * level) / 100) + 5
		stat_value = floor(stat_value * nature_mod[stat])
		current_stats[stat] = stat_value

# Initialiser les moves en fonction du niveau
func set_initial_moves() -> void:
	current_moves.clear()
	var level_up_moves = []
	
	# Sélectionner tous les moves apprenables par niveau jusqu'au niveau actuel
	for move_data in base_pokemon.learnable_moves:
		# On ne prend que les moves par niveau (method = 1)
		if move_data.method == 1 and move_data.level <= level:
			level_up_moves.append(move_data)
	
	# Trier par niveau (du plus haut au plus bas)
	level_up_moves.sort_custom(func(a, b): return a.level > b.level)
	
	# Prendre les 4 derniers moves appris (ou moins si pas assez)
	var moves_to_learn = min(4, level_up_moves.size())
	for i in range(moves_to_learn):
		var move_data = level_up_moves[i]
		var move_resource = load_move_resource(move_data.move_id)
		if move_resource:
			current_moves.append({
				"move_id": move_data.move_id,
				"pp_current": move_resource.pp,
				"pp_max": move_resource.pp
			})

# Calculer l'expérience nécessaire pour le niveau actuel
func calculate_experience() -> void:
	var exp_type = base_pokemon.experience_type
	experience = calculate_exp_for_level(level, exp_type)

# Calcule l'expérience nécessaire pour un niveau donné
func calculate_exp_for_level(target_level: int, exp_type: String) -> int:
	var n = float(target_level)
	var exp = 0
	
	match exp_type:
		"1059860":  # Medium Fast (Standard)
			exp = int(n * n * n)
		"800000":   # Fast
			exp = int(4 * n * n * n / 5)
		"1250000":  # Medium Slow
			exp = int((6/5) * n * n * n - 15 * n * n + 100 * n - 140)
		"1640000":  # Slow
			exp = int(5 * n * n * n / 4)
		"600000":   # Erratic
			if n <= 50:
				exp = int(n * n * n * (100 - n) / 50)
			elif n <= 68:
				exp = int(n * n * n * (150 - n) / 100)
			elif n <= 98:
				exp = int(n * n * n * floor((1911 - 10 * n) / 3) / 500)
			else:
				exp = int(n * n * n * (160 - n) / 100)
		"1750000":  # Fluctuating
			if n <= 15:
				exp = int(n * n * n * (floor((n + 1) / 3) + 24) / 50)
			elif n <= 36:
				exp = int(n * n * n * (n + 14) / 50)
			else:
				exp = int(n * n * n * (floor(n / 2) + 32) / 50)
	
	return exp

# Fonction pour ajouter de l'expérience et gérer la montée de niveau
func gain_experience(exp_amount: int) -> Dictionary:
	var result = {
		"old_level": level,
		"new_level": level,
		"leveled_up": false,
		"new_moves": []
	}
	
	experience += exp_amount
	var old_level = level
	
	# Vérifier si le Pokémon peut monter de niveau
	while level < 100:
		var next_level_exp = calculate_exp_for_level(level + 1, base_pokemon.experience_type)
		if experience >= next_level_exp:
			level += 1
		else:
			break
	
	if level > old_level:
		result.new_level = level
		result.leveled_up = true
		
		# Recalculer les stats
		calculate_stats()
		
		# Vérifier les nouveaux moves disponibles
		for move_data in base_pokemon.learnable_moves:
			if move_data.method == 1 and move_data.level > old_level and move_data.level <= level:
				result.new_moves.append(move_data.move_id)
	
	return result

# Ajouter un move à la liste des moves courants
func learn_move(move_id: int) -> bool:
	# Vérifier si le Pokémon peut apprendre ce move
	if not base_pokemon.can_learn_move(move_id):
		return false
		
	# Vérifier si le Pokémon a déjà ce move
	for move in current_moves:
		if move.move_id == move_id:
			return false
			
	# Vérifier si le Pokémon a déjà 4 moves
	if current_moves.size() >= 4:
		return false
		
	# Charger la ressource du move
	var move_resource = load_move_resource(move_id)
	if move_resource == null:
		return false
		
	current_moves.append({
		"move_id": move_id,
		"pp_current": move_resource.pp,
		"pp_max": move_resource.pp
	})
	
	return true

# Oublier un move
func forget_move(move_index: int) -> bool:
	if move_index < 0 or move_index >= current_moves.size():
		return false
		
	current_moves.remove_at(move_index)
	return true

# Remplacer un move par un nouveau
func replace_move(old_move_index: int, new_move_id: int) -> bool:
	if old_move_index < 0 or old_move_index >= current_moves.size():
		return false
		
	if not base_pokemon.can_learn_move(new_move_id):
		return false
		
	var move_resource = load_move_resource(new_move_id)
	if move_resource == null:
		return false
		
	current_moves[old_move_index] = {
		"move_id": new_move_id,
		"pp_current": move_resource.pp,
		"pp_max": move_resource.pp
	}
	
	return true

# Fonction helper pour charger une ressource de move
func load_move_resource(move_id: int) -> MoveResource:
	var path = "res://data/moves/%d_%s.tres" % [move_id, get_move_name(move_id)]
	if ResourceLoader.exists(path):
		return load(path) as MoveResource
	return null

# Fonction helper pour obtenir le nom d'un move à partir de son ID
# Cette fonction devra être remplacée par une vraie méthode pour récupérer les noms des moves
func get_move_name(move_id: int) -> String:
	# À implémenter avec une base de données de moves
	return "Move%d" % move_id

# Vérifier si le Pokémon peut évoluer
func can_evolve() -> Dictionary:
	var result = {
		"can_evolve": false,
		"evolution_data": null
	}
	
	for evolution in base_pokemon.evolutions:
		if evolution.trigger_type == "level-up" and level >= int(evolution.condition_en.split(" ")[1]):
			result.can_evolve = true
			result.evolution_data = evolution
			break
	
	return result

# Fonction pour faire évoluer le Pokémon
func evolve() -> bool:
	var evolution_check = can_evolve()
	if not evolution_check.can_evolve:
		return false
		
	var evolved_pokemon_id = evolution_check.evolution_data.evolved_pokemon_id
	var evolved_pokemon_resource = load_pokemon_resource(evolved_pokemon_id)
	
	if evolved_pokemon_resource == null:
		return false
	
	# Conserver les attributs personnalisés
	var old_nickname = nickname
	var old_ivs = ivs.duplicate()
	var old_evs = evs.duplicate()
	var old_moves = current_moves.duplicate()
	
	# Mettre à jour avec le nouveau Pokémon
	base_pokemon = evolved_pokemon_resource
	
	# Restaurer les attributs personnalisés
	if nickname != "":
		nickname = old_nickname
	ivs = old_ivs
	evs = old_evs
	current_moves = old_moves
	
	# Recalculer les statistiques
	calculate_stats()
	
	return true

# Fonction helper pour charger une ressource de Pokémon
func load_pokemon_resource(pokemon_id: int) -> PokemonResource:
	var files = get_pokemon_file_path(pokemon_id)
	if files.size() > 0 and ResourceLoader.exists(files[0]):
		return load(files[0]) as PokemonResource
	return null

# Fonction helper pour trouver le chemin du fichier d'un Pokémon
func get_pokemon_file_path(pokemon_id: int) -> Array:
	var pokemon_dir = "res://data/pokemon/"
	var dir = DirAccess.open(pokemon_dir)
	var files = []
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.begins_with(str(pokemon_id) + "_") and file_name.ends_with(".tres"):
				files.append(pokemon_dir + file_name)
			file_name = dir.get_next()
	
	return files

# Obtenir les données de l'abilité actuelle
func get_current_ability() -> AbilityResource:
	if ability_index >= 0 and ability_index < base_pokemon.abilities.size():
		return base_pokemon.abilities[ability_index]
	return null

# Obtenir le chemin du sprite approprié en fonction du genre et du statut shiny
func get_front_sprite_path() -> String:
	if is_shiny:
		if gender == "female" and base_pokemon.sprite_shiny_female_front:
			return base_pokemon.sprite_shiny_female_front
		return base_pokemon.sprite_shiny_front
	else:
		if gender == "female" and base_pokemon.sprite_female_front:
			return base_pokemon.sprite_female_front
		return base_pokemon.sprite_normal_front

func get_back_sprite_path() -> String:
	if is_shiny:
		if gender == "female" and base_pokemon.sprite_shiny_female_back:
			return base_pokemon.sprite_shiny_female_back
		return base_pokemon.sprite_shiny_back
	else:
		if gender == "female" and base_pokemon.sprite_female_back:
			return base_pokemon.sprite_female_back
		return base_pokemon.sprite_normal_back
