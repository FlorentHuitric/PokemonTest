@tool
extends EditorScript

const MOVE_EFFECT_IMPORTER_PATH = "res://scripts/editor/MoveEffectTargetImporter.gd"
const POKEMON_DATA_IMPORTER_PATH = "res://scripts/editor/PokemonDataImporter.gd"
const POKEMON_MOVE_IMPORTER_PATH = "res://scripts/editor/PokemonMoveImporter.gd"
const MOVE_DESCRIPTION_IMPORTER_PATH = "res://scripts/editor/MoveDescriptionImporter.gd" 
const POKEMON_SPECIES_IMPORTER_PATH = "res://scripts/editor/PokemonSpeciesImporter.gd"
const POKEMON_EVOLUTION_IMPORTER_PATH = "res://scripts/editor/PokemonEvolutionImporter.gd"

func _run() -> void:
	print("Starting master import process...")
	
	# Charger et exécuter l'importeur d'effets et cibles de moves
	print("\n--- IMPORTING MOVE EFFECTS AND TARGETS ---\n")
	var EffectImporterScript = load(MOVE_EFFECT_IMPORTER_PATH)
	var effect_importer = EffectImporterScript.new()
	effect_importer._run()
	
	# Charger et exécuter l'importeur de descriptions de moves
	print("\n--- IMPORTING MOVE DESCRIPTIONS ---\n")
	var DescriptionImporterScript = load(MOVE_DESCRIPTION_IMPORTER_PATH)
	var description_importer = DescriptionImporterScript.new()
	description_importer._run()
	
	# Charger et exécuter l'importeur de méta-données de moves
	print("\n--- IMPORTING MOVE META DATA ---\n")
	var DataImporterScript = load(POKEMON_DATA_IMPORTER_PATH)
	var data_importer = DataImporterScript.new()
	data_importer._run()
	
	# Charger et exécuter l'importeur des données d'espèces de Pokémon
	print("\n--- IMPORTING POKEMON SPECIES DATA ---\n")
	var SpeciesImporterScript = load(POKEMON_SPECIES_IMPORTER_PATH)
	var species_importer = SpeciesImporterScript.new()
	species_importer._run()
	
	# Charger et exécuter l'importeur des données d'évolution
	print("\n--- IMPORTING POKEMON EVOLUTION DATA ---\n")
	var EvolutionImporterScript = load(POKEMON_EVOLUTION_IMPORTER_PATH)
	var evolution_importer = EvolutionImporterScript.new()
	evolution_importer._run()
	
	# Charger et exécuter l'importeur de moves apprenables
	print("\n--- IMPORTING POKEMON MOVES ---\n")
	var MoveImporterScript = load(POKEMON_MOVE_IMPORTER_PATH)
	var move_importer = MoveImporterScript.new()
	move_importer._run()
	
	print("\nMaster import process complete!")
