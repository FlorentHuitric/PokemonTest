# res://scripts/resources/ItemResource.gd

extends Resource
class_name ItemResource

@export var item_id: int = 0
@export var names: Dictionary = {"en": "", "fr": ""}
@export var description: Dictionary = {"en": "", "fr": ""}
@export var effect: String = ""  # Effet de l'objet
@export var sprite_path: String = ""  # Chemin vers le sprite de l'objet
