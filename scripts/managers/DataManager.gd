# res://scripts/managers/DataManager.gd

extends Node
class_name DataManager

var pokemon_data: Dictionary = {}
var move_data: Dictionary = {}
var item_data: Dictionary = {}

func _ready():
	load_all_data()

func load_all_data():
	load_pokemon_data()
	load_move_data()
	load_item_data()

func load_pokemon_data():
	var path: String = "res://data/pokemon/"
	var dir = DirAccess.open(path)
	if dir:
		for file_name in dir.get_files():
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var resource_path: String = path + file_name
				var pokemon_resource = ResourceLoader.load(resource_path)
				if pokemon_resource is PokemonResource:
					pokemon_data[pokemon_resource.pokemon_id] = pokemon_resource
	else:
		print("Erreur : Impossible d'ouvrir le dossier des Pokémon.")

func load_move_data():
	var path: String = "res://data/moves/"
	var dir = DirAccess.open(path)
	if dir:
		for file_name in dir.get_files():
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var resource_path: String = path + file_name
				var move_resource = ResourceLoader.load(resource_path)
				if move_resource is MoveResource:
					move_data[move_resource.move_id] = move_resource
	else:
		print("Erreur : Impossible d'ouvrir le dossier des attaques.")

func load_item_data():
	var path: String = "res://data/items/"
	var dir = DirAccess.open(path)
	if dir:
		for file_name in dir.get_files():
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var resource_path: String = path + file_name
				var item_resource = ResourceLoader.load(resource_path)
				if item_resource is ItemResource:
					item_data[item_resource.item_id] = item_resource
	else:
		print("Erreur : Impossible d'ouvrir le dossier des objets.")
