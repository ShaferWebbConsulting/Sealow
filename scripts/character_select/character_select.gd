extends Control
## First-time (and re-selectable in future) character + color picker.
## Step 1: choose a starter sea creature. Step 2: choose a pastel body color
## with a live preview. Saves the selection via SaveManager and continues to
## the Main Menu.

const PlayerDataScript = preload("res://scripts/player/player_data.gd")

@onready var step1: Control = %Step1
@onready var step2: Control = %Step2

@onready var creature_grid: GridContainer = %CreatureGrid
@onready var next_button: Button = %NextButton

@onready var preview_body: Panel = %PreviewBody
@onready var preview_emoji: Label = %PreviewEmoji
@onready var color_grid: GridContainer = %ColorGrid
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton

var _selected_creature: String = ""
var _selected_color: String = ""
var _creature_buttons: Dictionary = {}
var _color_buttons: Dictionary = {}


func _ready() -> void:
	_build_creature_buttons()
	_build_color_swatches()

	next_button.pressed.connect(_on_next_pressed)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)

	next_button.disabled = true
	start_button.disabled = true
	step1.visible = true
	step2.visible = false


func _build_creature_buttons() -> void:
	for creature_key in PlayerDataScript.CHARACTER_ORDER:
		var button: Button = Button.new()
		button.text = "%s\n%s" % [
			PlayerDataScript.get_emoji(creature_key),
			PlayerDataScript.get_display_name(creature_key),
		]
		button.custom_minimum_size = Vector2(180, 160)
		button.toggle_mode = true
		button.add_theme_font_size_override("font_size", 30)
		button.pressed.connect(_on_creature_selected.bind(creature_key))
		creature_grid.add_child(button)
		_creature_buttons[creature_key] = button


func _build_color_swatches() -> void:
	for color_key in PlayerDataScript.CHARACTER_COLOR_ORDER:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(72, 72)
		button.toggle_mode = true
		button.text = ""
		button.tooltip_text = color_key.capitalize()

		var normal_style: StyleBoxFlat = StyleBoxFlat.new()
		normal_style.bg_color = PlayerDataScript.get_color(color_key)
		normal_style.set_corner_radius_all(36)
		normal_style.border_width_left = 3
		normal_style.border_width_top = 3
		normal_style.border_width_right = 3
		normal_style.border_width_bottom = 3
		normal_style.border_color = Color(1, 1, 1, 0.35)
		button.add_theme_stylebox_override("normal", normal_style)

		var pressed_style: StyleBoxFlat = normal_style.duplicate()
		pressed_style.border_color = Color(1, 1, 1, 0.95)
		pressed_style.border_width_left = 5
		pressed_style.border_width_top = 5
		pressed_style.border_width_right = 5
		pressed_style.border_width_bottom = 5
		button.add_theme_stylebox_override("pressed", pressed_style)
		button.add_theme_stylebox_override("hover", normal_style)

		button.pressed.connect(_on_color_selected.bind(color_key))
		color_grid.add_child(button)
		_color_buttons[color_key] = button


func _on_creature_selected(creature_key: String) -> void:
	_selected_creature = creature_key
	for key in _creature_buttons.keys():
		_creature_buttons[key].button_pressed = (key == creature_key)
	next_button.disabled = false


func _on_color_selected(color_key: String) -> void:
	_selected_color = color_key
	for key in _color_buttons.keys():
		_color_buttons[key].button_pressed = (key == color_key)
	start_button.disabled = false
	_update_preview()


func _update_preview() -> void:
	preview_emoji.text = PlayerDataScript.get_emoji(_selected_creature)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PlayerDataScript.get_color(_selected_color) if not _selected_color.is_empty() else Color(1, 1, 1, 0.08)
	style.set_corner_radius_all(120)
	preview_body.add_theme_stylebox_override("panel", style)


func _on_next_pressed() -> void:
	if _selected_creature.is_empty():
		return
	step1.visible = false
	step2.visible = true
	_update_preview()


func _on_back_pressed() -> void:
	step2.visible = false
	step1.visible = true


func _on_start_pressed() -> void:
	if _selected_creature.is_empty() or _selected_color.is_empty():
		return
	SaveManager.select_character(_selected_creature, _selected_color)
	SceneManager.go_to_main_menu()
