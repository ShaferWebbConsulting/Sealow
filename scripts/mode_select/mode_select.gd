extends Control
## Mode Select: pick STORY MODE or FREE FOR ALL before Enemy Select.

@onready var story_button: Button = %StoryButton
@onready var free_for_all_button: Button = %FreeForAllButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	story_button.pressed.connect(_on_mode_pressed.bind(SaveManager.GameMode.STORY))
	free_for_all_button.pressed.connect(_on_mode_pressed.bind(SaveManager.GameMode.FREE_FOR_ALL))
	back_button.pressed.connect(SceneManager.go_to_main_menu)


func _on_mode_pressed(mode: SaveManager.GameMode) -> void:
	SaveManager.set_game_mode(mode)
	SceneManager.go_to_enemy_select()
