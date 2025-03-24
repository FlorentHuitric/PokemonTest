@tool
# res://scripts/resources/MoveResource.gd

extends Resource
class_name MoveResource

@export var move_id: int = 0
@export var move_name: Dictionary = {"en": "", "fr": ""}
@export var move_type: Resource  # TypeResource
@export var category: String = ""  # Physical, Special, Status
@export var contest: String = ""
@export var power: int = 0
@export var accuracy: int = 0
@export var pp: int = 0
@export var generation: int = 0
@export var descriptions: Dictionary = {"en": "", "fr": ""}
@export var tm_id: String = ""

# Nouvelles propriétés basées sur les CSV
@export var meta_category_id: int = 0  # Catégorie selon move_meta_category_prose.csv
@export var meta_category_desc: Dictionary = {"en": "", "fr": ""}
@export var meta_ailment_id: int = 0  # Ailment selon move_meta_ailments.csv
@export var meta_ailment_name: Dictionary = {"en": "", "fr": ""}

# Propriétés détaillées du move (move_meta.csv)
@export var min_hits: int = 0
@export var max_hits: int = 0
@export var min_turns: int = 0
@export var max_turns: int = 0
@export var drain: int = 0  # % de HP drainés (négatif = recoil)
@export var healing: int = 0  # % de healing
@export var crit_rate: int = 0  # Bonus au taux critique
@export var ailment_chance: int = 0  # % de chance d'infliger l'ailment
@export var flinch_chance: int = 0  # % de chance de flinch
@export var stat_chance: int = 0  # % de chance de modifier les stats

# Nouvelles propriétés pour les cibles et les effets
@export var move_target_id: int = 0
@export var move_target_name: Dictionary = {"en": "", "fr": ""}
@export var move_target_description: Dictionary = {"en": "", "fr": ""}
@export var move_effect_id: int = 0
@export var move_effect_short: Dictionary = {"en": "", "fr": ""}

# Méthode pour mettre à jour les données du move à partir des CSV
func update_from_meta(meta_data: Dictionary) -> void:
	if meta_data.has("meta_category_id"):
		meta_category_id = meta_data.meta_category_id
	if meta_data.has("meta_ailment_id"):
		meta_ailment_id = meta_data.meta_ailment_id
	if meta_data.has("min_hits"):
		min_hits = meta_data.min_hits
	if meta_data.has("max_hits"):
		max_hits = meta_data.max_hits
	if meta_data.has("min_turns"):
		min_turns = meta_data.min_turns
	if meta_data.has("max_turns"):
		max_turns = meta_data.max_turns
	if meta_data.has("drain"):
		drain = meta_data.drain
	if meta_data.has("healing"):
		healing = meta_data.healing
	if meta_data.has("crit_rate"):
		crit_rate = meta_data.crit_rate
	if meta_data.has("ailment_chance"):
		ailment_chance = meta_data.ailment_chance
	if meta_data.has("flinch_chance"):
		flinch_chance = meta_data.flinch_chance
	if meta_data.has("stat_chance"):
		stat_chance = meta_data.stat_chance

# Fonction pour définir la description de la catégorie
func set_meta_category_desc(desc: Dictionary) -> void:
	meta_category_desc = desc

# Fonction pour définir le nom de l'ailment
func set_meta_ailment_name(name: Dictionary) -> void:
	meta_ailment_name = name
