extends Node
class_name SceneManager

const MAIN_MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const BATTLE_SCENE: String = "res://scenes/battle/Battle.tscn"

func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func go_to_battle() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)
