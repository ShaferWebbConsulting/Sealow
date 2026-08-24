extends Node
## Headless integration smoke test: exercises Startup -> New Dive ->
## Character Select -> Main Menu -> Shop purchase -> persistence, without
## real input events (calls the same handler functions button presses would
## trigger). Not part of the shipped game; run manually for verification.


func _ready() -> void:
	print("[flow] has_save at boot: ", SaveManager.has_save())
	assert(not SaveManager.has_save())

	# Simulate picking a character + color, then persisting via SaveManager
	# the same way character_select.gd does.
	SaveManager.select_character("octopus", "#B3E5FC", "Test Diver")
	SaveManager.save_game()
	print("[flow] after character select, has_save: ", SaveManager.has_save())
	assert(SaveManager.has_save())

	# Give ourselves shells to buy something.
	SaveManager.data["shells"] = 3
	SaveManager.save_game()

	var key: String = ItemData.id_to_key(ItemData.get_catalog()[0].id)
	var before: int = int(SaveManager.get_inventory().get(key, 0))
	var bought: bool = SaveManager.buy_item(key, ItemData.SHOP_COST_SHELLS)
	print("[flow] buy result: ", bought, " shells left: ", SaveManager.player_shells)
	assert(bought)
	assert(SaveManager.player_shells == 2)
	assert(int(SaveManager.get_inventory().get(key, 0)) == before + 1)

	# Reload from disk to confirm persistence.
	SaveManager.load_game()
	print("[flow] after reload, shells: ", SaveManager.player_shells, " inventory: ", SaveManager.get_inventory())
	assert(SaveManager.player_shells == 2)
	assert(int(SaveManager.get_inventory().get(key, 0)) == before + 1)

	# reset_save() writes fresh defaults to disk (has_save() checks file
	# existence, which remains true), but all fields are back to defaults.
	SaveManager.reset_save()
	print("[flow] after reset_save, has_save: ", SaveManager.has_save(), " character_selected: ", SaveManager.is_character_selected(), " shells: ", SaveManager.player_shells)
	assert(SaveManager.has_save())
	assert(not SaveManager.is_character_selected())
	assert(SaveManager.player_shells == 0)

	print("[flow] ALL CHECKS PASSED")
	get_tree().quit()
