extends Node
## Single source of truth for persistent player save data (currently just
## the shell currency total). Autoloaded as `SaveManager`.
##
## Anything that needs to read or modify the player's shell total should go
## through this singleton instead of keeping its own copy — battle scenes,
## the main menu, etc. should never store a duplicate shell variable.

const SAVE_PATH: String = "user://sealow_save.json"

var player_shells: int = 0

func _ready() -> void:
	load_game()

## Adds `amount` shells to the player's total and immediately persists it.
func add_shells(amount: int) -> void:
	if amount <= 0:
		return
	player_shells += amount
	save_game()

## Writes the current save data to disk as JSON.
func save_game() -> void:
	var data: Dictionary = {
		"player_shells": player_shells,
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: unable to open save file for writing.")
		return
	file.store_string(JSON.stringify(data))
	file.close()

## Loads save data from disk. Falls back to safe defaults (0 shells) if the
## save file does not exist yet or is corrupted, and never crashes.
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		player_shells = 0
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		player_shells = 0
		return

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("player_shells"):
		push_warning("SaveManager: save file corrupted or invalid, resetting to defaults.")
		player_shells = 0
		return

	var value: Variant = parsed["player_shells"]
	player_shells = int(value) if (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) else 0
