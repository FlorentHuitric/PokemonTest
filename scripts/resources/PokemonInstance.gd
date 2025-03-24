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

func _init(pokemon_resource: PokemonResource = null) -> void:
	if pokemon_resource:
		base_pokemon = pokemon_resource
		generate_random_ivs()
		initialize_stats()

# Générer des IVs aléatoires
func generate_random_ivs() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for stat in ivs.keys():
		var min_val = base_pokemon.iv_ranges[stat].min
		var max_val = base_pokemon.iv_ranges[stat].max
		ivs[stat] = rng.randi_range(min_val, max_val)

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
	
	# Appliquer les modificateurs de nature (à implémenter plus tard)
	# Exemple: nature "Adamant" augmente Attack mais réduit Special Attack
	
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
