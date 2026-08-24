extends Node
## Single source of truth for persistent player save data (character choice,
## shells, level, battle wins, and item inventory). Autoloaded as
## `SaveManager`.
##
## Anything that needs to read or modify persisted player state should go
## through this singleton instead of keeping its own copy — battle scenes,
## the main menu, character select, etc. should never store a duplicate.

const PlayerDataScript = preload("res://scripts/player/player_data.gd")

const SAVE_PATH: String = "user://sealow_save.json"

## Full save dictionary, always kept merged with PlayerData.DEFAULT_SAVE so
## every known field is present even right after loading an old/partial save.
var data: Dictionary = {}


## Legacy accessor kept for existing callers (e.g. MainMenu) that only care
## about the shell total.
var player_shells: int:
	get:
		return int(data.get("shells", 0))


func _ready() -> void:
	load_game()


## Adds `amount` shells to the player's total and immediately persists it.
func add_shells(amount: int) -> void:
	if amount <= 0:
		return
	data["shells"] = int(data.get("shells", 0)) + amount
	save_game()


## Whether a save file exists on disk at all (used by the startup screen to
## decide whether CONTINUE should be offered). This is deliberately based on
## the file's existence rather than `character_selected`, so a save that
## exists but hasn't finished character select yet is still treated as "has
## a save" (CONTINUE will simply route back into character select).
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Wipes all player progress (character, shells, level, wins, inventory) back
## to defaults and persists it immediately. Used by the "NEW DIVE" flow on
## the startup screen only after the player has explicitly confirmed.
func reset_save() -> void:
	data = PlayerDataScript.DEFAULT_SAVE.duplicate(true)
	save_game()


func is_character_selected() -> bool:
	return bool(data.get("character_selected", false))


func get_character_type() -> String:
	return String(data.get("character_type", "octopus"))


func get_character_color() -> String:
	return String(data.get("character_color", "seafoam"))

func get_player_name() -> String:
	return String(data.get("player_name", "Little Diver"))

## Persists the player's chosen creature + color and marks character select
## as completed so it is never shown again on future launches.
func select_character(
	character_type: String,
	character_color: String,
	player_name: String = "Diver"
) -> void:
	var cleaned_name: String = player_name.strip_edges()

	if cleaned_name.is_empty():
		cleaned_name = "Diver"

	data["character_selected"] = true
	data["character_type"] = character_type
	data["character_color"] = character_color
	data["player_name"] = cleaned_name

	save_game()


func get_level() -> int:
	return int(data.get("level", 1))


func get_battles_won() -> int:
	return int(data.get("battles_won", 0))


## Records a battle win and immediately persists it.
func register_battle_win() -> void:
	data["battles_won"] = int(data.get("battles_won", 0)) + 1
	save_game()


func get_item_count(key: String) -> int:
	var inventory: Dictionary = data.get("inventory", {})
	return int(inventory.get(key, 0))


## Returns a duplicate of the current item inventory dictionary
## (e.g. `{"turtle_shield": 1, "trident": 1, "mermaid_scale": 1}`) so
## callers can read quantities without depending on the internal shape of
## `data`.
func get_inventory() -> Dictionary:
	return (data.get("inventory", {}) as Dictionary).duplicate()


## Consumes one of item `key` if available, persisting immediately. Returns
## true if an item was actually consumed.
func consume_item(key: String) -> bool:
	var inventory: Dictionary = data.get("inventory", {})
	if int(inventory.get(key, 0)) <= 0:
		return false
	inventory[key] = int(inventory.get(key, 0)) - 1
	data["inventory"] = inventory
	save_game()
	return true


## Grants `amount` of item `key` (e.g. a future shop purchase), persisting
## immediately.
func add_item(key: String, amount: int = 1) -> void:
	var inventory: Dictionary = data.get("inventory", {})
	inventory[key] = int(inventory.get(key, 0)) + amount
	data["inventory"] = inventory
	save_game()


## Shop purchase: spends `cost` shells and grants one of item `key` if the
## player can afford it, persisting immediately. Returns true on success,
## false (with no state changed) if the player doesn't have enough shells.
func buy_item(key: String, cost: int) -> bool:
	if int(data.get("shells", 0)) < cost:
		return false
	data["shells"] = int(data.get("shells", 0)) - cost
	var inventory: Dictionary = data.get("inventory", {})
	inventory[key] = int(inventory.get(key, 0)) + 1
	data["inventory"] = inventory
	save_game()
	return true


## Writes the current save data to disk as JSON.
func save_game() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: unable to open save file for writing.")
		return
	file.store_string(JSON.stringify(data))
	file.close()


## Loads save data from disk. Falls back to safe defaults if the save file
## does not exist yet or is corrupted, and never crashes. Missing fields
## (from older save versions) are merged with PlayerData.DEFAULT_SAVE rather
## than wiping the whole save.
func load_game() -> void:
	var defaults: Dictionary = PlayerDataScript.DEFAULT_SAVE.duplicate(true)

	if not FileAccess.file_exists(SAVE_PATH):
		data = defaults
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		data = defaults
		return

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: save file corrupted or invalid, resetting to defaults.")
		data = defaults
		return

	var parsed_dict: Dictionary = parsed
	# Backward compatibility with the pre-v0.2 save shape, which only ever
	# stored a top-level "player_shells" int.
	if parsed_dict.has("player_shells") and not parsed_dict.has("shells"):
		parsed_dict["shells"] = parsed_dict["player_shells"]

	data = PlayerDataScript.merge_with_defaults(parsed_dict, defaults)


func set_player_name(player_name: String) -> void:
	var cleaned_name: String = player_name.strip_edges()

	if cleaned_name.is_empty():
		cleaned_name = "Diver"

	data["player_name"] = cleaned_name
	save_game()