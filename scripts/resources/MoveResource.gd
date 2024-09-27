# res://scripts/resources/MoveResource.gd

extends Resource
class_name MoveResource

@export var move_id:int = 0 
@export var move_name = {}
@export var move_type: TypeResource
@export var category: String = ""  # "Physical", "Special", or "Status"
@export var contest: String = ""   # "Cool", "Clever", "Tough", etc.
@export var power:int = 0
@export var accuracy:int = 0
@export var pp:int = 0
@export var generation:int = 0
@export var descriptions = {} # fr et en à implémenter
@export var tm_id = ""  # Identifiant de la CT, si applicable
