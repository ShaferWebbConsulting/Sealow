extends Control
## Mode Select: two large visual cards (STORY MODE / FREE FOR ALL). Each card
## shows a depth background (dimmed for readability) and a circular character
## portrait, all pulled through SeaLowAtlas / EnemyData.

const EnemyDataScript = preload("res://scripts/enemies/enemy_data.gd")
const SeaLowAtlasScript = preload("res://scripts/assets/sea_low_atlas.gd")
const PortraitShader = preload("res://scripts/ui/portrait_circle.gdshader")

const STORY_PORTRAIT: String = "puffer_boss"
const FREE_PORTRAIT: String = "hammerhead_hustler"

@onready var story_button: Button = %StoryButton
@onready var free_for_all_button: Button = %FreeForAllButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	_decorate(story_button, "surface", STORY_PORTRAIT, "STORY MODE", "Fight enemies in order")
	_decorate(free_for_all_button, "mystic_waters", FREE_PORTRAIT, "FREE FOR ALL", "Fight anyone anytime")
	story_button.pressed.connect(_on_mode_pressed.bind(SaveManager.GameMode.STORY))
	free_for_all_button.pressed.connect(_on_mode_pressed.bind(SaveManager.GameMode.FREE_FOR_ALL))
	back_button.pressed.connect(SceneManager.go_to_main_menu)


func _decorate(button: Button, depth: String, enemy_key: String, title: String, subtitle: String) -> void:
	button.text = ""
	button.clip_contents = true

	var bg: TextureRect = TextureRect.new()
	bg.texture = SeaLowAtlasScript.get_background_texture(EnemyDataScript.get_background_cell(depth))
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(bg)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.05, 0.1, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(dim)

	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)

	var portrait: TextureRect = TextureRect.new()
	portrait.texture = SeaLowAtlasScript.get_character_portrait(EnemyDataScript.get_enemy(enemy_key)["atlas"], 0.85)
	portrait.custom_minimum_size = Vector2(0, 190)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = PortraitShader
	portrait.material = mat
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(portrait)

	box.add_child(_label(title, 36, Color(1, 1, 1, 1)))
	box.add_child(_label(subtitle, 22, Color(0.9, 0.95, 1.0, 1)))


func _label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _on_mode_pressed(mode: SaveManager.GameMode) -> void:
	SaveManager.set_game_mode(mode)
	SceneManager.go_to_enemy_select()
