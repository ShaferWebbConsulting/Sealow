extends Node

const STARTUP_SCENE: String = "res://scenes/startup/Startup.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const BATTLE_SCENE: String = "res://scenes/battle/Battle.tscn"
const CHARACTER_SELECT_SCENE: String = "res://scenes/character_select/CharacterSelect.tscn"
const SHOP_SCENE: String = "res://scenes/shop/Shop.tscn"

func go_to_startup() -> void:
	get_tree().change_scene_to_file(STARTUP_SCENE)

func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func go_to_battle() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)

func go_to_character_select() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)

func go_to_shop() -> void:
	get_tree().change_scene_to_file(SHOP_SCENE)
