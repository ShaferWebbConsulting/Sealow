extends Control
## Enemy Select ("Dive Select") screen. Lists the full EnemyData progression
## as cards built dynamically (same pattern as Shop/ItemPopup row-building)
## so adding an enemy to EnemyData is enough — no scene editing required.
##
## Rules (see EnemyData + SaveManager for the actual progression logic):
## - Only unlocked enemies (SaveManager.is_enemy_unlocked()) are selectable.
## - Beaten enemies stay selectable forever.
## - Locked enemies are shown, dimmed, and disabled — never skippable.

const EnemyDataScript = preload("res://scripts/enemies/enemy_data.gd")
const SeaLowAtlasScript = preload("res://scripts/assets/sea_low_atlas.gd")

@onready var enemy_grid: GridContainer = %EnemyGrid
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_refresh()


func _on_back_pressed() -> void:
	SceneManager.go_to_main_menu()


func _refresh() -> void:
	_clear_cards()

	for enemy_key in EnemyDataScript.PROGRESSION_ORDER:
		var enemy: Dictionary = EnemyDataScript.get_enemy(enemy_key)
		enemy_grid.add_child(_build_card(enemy_key, enemy))


func _clear_cards() -> void:
	for child in enemy_grid.get_children():
		child.queue_free()


func _build_card(enemy_key: String, enemy: Dictionary) -> Control:
	var unlocked: bool = SaveManager.is_enemy_unlocked(enemy_key)
	var beaten: bool = SaveManager.is_enemy_beaten(enemy_key)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 260)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.18, 0.24, 0.9)
	style.set_corner_radius_all(16)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Cropped atlas sprite. Dimmed (but still visible) when locked, so the
	# player can preview what's coming without being able to select it.
	var icon: TextureRect = TextureRect.new()
	icon.texture = SeaLowAtlasScript.get_character_texture(enemy["atlas"])
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.35, 0.35, 0.4, 1)
	vbox.add_child(icon)

	var name_label: Label = Label.new()
	name_label.text = String(enemy["display_name"]).to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	var hp_label: Label = Label.new()
	hp_label.text = "❤ %d HP" % int(enemy["max_hp"])
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.add_theme_color_override("font_color", Color(0.678431, 0.72549, 0.741176, 1))
	vbox.add_child(hp_label)

	var depth_label: Label = Label.new()
	depth_label.text = String(enemy["depth"]).replace("_", " ").to_upper()
	depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	depth_label.add_theme_font_size_override("font_size", 12)
	depth_label.add_theme_color_override("font_color", Color(0.34902, 0.784314, 0.698039, 1))
	vbox.add_child(depth_label)

	var status_label: Label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 13)

	if not unlocked:
		status_label.text = "🔒 LOCKED"
		status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 1))
	elif beaten:
		status_label.text = "✓ BEATEN"
		status_label.add_theme_color_override("font_color", Color(0.941176, 0.760784, 0.239216, 1))
	else:
		status_label.text = "UNLOCKED"
		status_label.add_theme_color_override("font_color", Color(0.34902, 0.784314, 0.698039, 1))

	vbox.add_child(status_label)

	var select_button: Button = Button.new()
	select_button.text = "SELECT"
	select_button.custom_minimum_size = Vector2(0, 48)
	select_button.disabled = not unlocked
	select_button.pressed.connect(_on_select_pressed.bind(enemy_key))
	vbox.add_child(select_button)

	return panel


## Persists the chosen enemy and dives straight into battle against it.
func _on_select_pressed(enemy_key: String) -> void:
	if not SaveManager.is_enemy_unlocked(enemy_key):
		return

	SaveManager.set_selected_enemy(enemy_key)
	SceneManager.go_to_battle()
