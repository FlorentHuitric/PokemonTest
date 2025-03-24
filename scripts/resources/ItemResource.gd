# res://scripts/resources/ItemResource.gd

extends Resource
class_name ItemResource

# Données de base
@export var item_id: int = 0
@export var identifier: String = ""
@export var names: Dictionary = {}  # {"en": "English Name", "fr": "French Name"}
@export var cost: int = 0

# Catégorie et poche
@export var category_id: int = 0
@export var category_name: Dictionary = {}  # {"en": "Category Name", "fr": "Nom de catégorie"}
@export var pocket_id: int = 0
@export var pocket_name: Dictionary = {}  # {"en": "Pocket Name", "fr": "Nom de poche"}

# Effet de lancer (fling)
@export var fling_power: int = 0
@export var fling_effect_id: int = 0
@export var fling_effect: Dictionary = {}  # {"en": "Fling Effect", "fr": "Effet de lancer"}

# Descriptions et effets
@export var short_effect: Dictionary = {}  # {"en": "Short Effect", "fr": "Effet court"}
@export var effect: Dictionary = {}  # {"en": "Effect Description", "fr": "Description d'effet"}
@export var flavor_text: Dictionary = {}  # {"en": "Flavor Text", "fr": "Texte descriptif"}

# Drapeaux (flags)
@export var flags: Array[String] = []  # ["countable", "consumable", etc.]

# Génération dans laquelle l'item est apparu
@export var generation_id: int = 0
@export var game_index: int = 0

# Sprite
@export var sprite_path: String = ""

# Obtenir le nom localisé - Renommé pour éviter le conflit avec Resource.get_name()
func get_item_name(lang: String = "fr") -> String:
	if names.has(lang):
		return names[lang]
	if names.has("en"):
		return names["en"]
	return identifier

# Obtenir la description de l'effet
func get_effect(lang: String = "fr") -> String:
	if effect.has(lang):
		return effect[lang]
	if effect.has("en"):
		return effect["en"]
	return ""

# Obtenir l'effet court
func get_short_effect(lang: String = "fr") -> String:
	if short_effect.has(lang):
		return short_effect[lang]
	if short_effect.has("en"):
		return short_effect["en"]
	return ""

# Obtenir le texte descriptif
func get_flavor_text(lang: String = "fr") -> String:
	if flavor_text.has(lang):
		return flavor_text[lang]
	if flavor_text.has("en"):
		return flavor_text["en"]
	return ""

# Vérifier si l'item a un flag spécifique
func has_flag(flag_name: String) -> bool:
	return flag_name in flags

# Obtenir le nom de catégorie
func get_category_name(lang: String = "fr") -> String:
	if category_name.has(lang):
		return category_name[lang]
	if category_name.has("en"):
		return category_name["en"]
	return ""

# Obtenir le nom de poche
func get_pocket_name(lang: String = "fr") -> String:
	if pocket_name.has(lang):
		return pocket_name[lang]
	if pocket_name.has("en"):
		return pocket_name["en"]
	return ""

# Vérifier si l'item peut être utilisé en combat
func is_usable_in_battle() -> bool:
	return has_flag("usable-in-battle")

# Vérifier si l'item peut être utilisé hors combat
func is_usable_overworld() -> bool:
	return has_flag("usable-overworld")

# Vérifier si l'item peut être tenu par un Pokémon
func is_holdable() -> bool:
	return has_flag("holdable")
