# res://scripts/resources/PokemonResource.gd

extends Resource
class_name PokemonResource

# Informations de base
@export var pokemon_id: int = 0
@export var branch_code: String = ""
@export var names: Dictionary = {"en": "", "fr": ""}
@export var generation: int = 0
@export var height: float = 0.0
@export var weight: float = 0.0
@export var types: Array[TypeResource] = []
@export var abilities: Array[AbilityResource] = []
@export var color: String = ""
@export var gender_ratio: Dictionary = {"male": 0.0, "female": 0.0, "unknown": 0.0}
@export var egg_steps: int = 0
@export var egg_groups: PackedStringArray = PackedStringArray()
@export var catch_rate: int = 0
@export var base_experience: int = 0
@export var experience_type: String = ""
@export var category: String = ""
@export var mega_evolution_flag: bool = false
@export var region_form: String = ""

# Statistiques de base
@export var base_stats: Dictionary = {
	"hp": 0,
	"attack": 0,
	"defense": 0,
	"special_attack": 0,
	"special_defense": 0,
	"speed": 0,
	"total": 0
}

# Points d'effort
@export var effort_points: Dictionary = {
	"hp": 0,
	"attack": 0,
	"defense": 0,
	"special_attack": 0,
	"special_defense": 0,
	"speed": 0
}

# Sprites
@export var sprite_normal_front: String = ""
@export var sprite_normal_back: String = ""
@export var sprite_shiny_front: String = ""
@export var sprite_shiny_back: String = ""
@export var sprite_female_front: String = ""
@export var sprite_female_back: String = ""
@export var sprite_shiny_female_front: String = ""
@export var sprite_shiny_female_back: String = ""

# Description du Pokémon
@export var description: Dictionary = {"en": "", "fr": ""}

# Nouvelles propriétés
# Valeurs individuelles (IVs)
@export var iv_ranges: Dictionary = {
	"hp": {"min": 0, "max": 31},
	"attack": {"min": 0, "max": 31},
	"defense": {"min": 0, "max": 31},
	"special_attack": {"min": 0, "max": 31},
	"special_defense": {"min": 0, "max": 31},
	"speed": {"min": 0, "max": 31}
}

# Moves que le Pokémon peut apprendre
@export var learnable_moves: Array[Dictionary] = []
# Structure d'un move apprenable:
# {
#    "move_id": 0,         # ID du move
#    "method": 1,          # Méthode d'apprentissage (1=level-up, 2=egg, 3=tutor, 4=tm/hm)
#    "level": 0,           # Niveau requis si méthode = level-up
#    "tm_id": "",          # ID de la TM/HM si applicable
#    "generation": 1       # Génération où ce move est appris
# }

# Fonction pour ajouter un move apprenable
func add_learnable_move(move_id: int, method: int, level: int = 0, tm_id: String = "", generation: int = 1) -> void:
	learnable_moves.append({
		"move_id": move_id,
		"method": method,
		"level": level,
		"tm_id": tm_id,
		"generation": generation
	})

# Fonction pour vérifier si le Pokémon peut apprendre un move spécifique
func can_learn_move(move_id: int) -> bool:
	for move in learnable_moves:
		if move.move_id == move_id:
			return true
	return false
