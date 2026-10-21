extends Control
## Enemy Select ("Dive Select") screen. Lists the full EnemyData progression
## as cards built dynamically (same pattern as Shop/ItemPopup row-building)
## so adding an enemy to EnemyData is enough — no scene editing required.
##
## Rules (see EnemyData + SaveManager for the actual progression logic):
## - Story: only unlocked enemies are selectable. Free For All: every enemy is.
## - Beaten enemies stay selectable forever.
## - Locked enemies are shown, dimmed, and disabled — never skippable.

const EnemyDataScript = preload("res://scripts/enemies/enemy_data.gd")
const SeaLowAtlasScript = preload("res://scripts/assets/sea_low_atlas.gd")

@onready var enemy_grid: VBoxContainer = %EnemyGrid
@onready var back_button: Button = %BackButton
@onready var mode_label: Label = %ModeLabel


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	mode_label.text = "FREE FOR ALL" if SaveManager.is_free_for_all() else "STORY MODE"
	_refresh()


func _on_back_pressed() -> void:
	SceneManager.go_to_mode_select()


func _refresh() -> void:
	_clear_cards()

	# Group the progression into one section per depth, in progression order,
	# each drawn over its matching depth background.
	var current_depth: String = ""
	var grid: GridContainer = null

	for enemy_key in EnemyDataScript.PROGRESSION_ORDER:
		var enemy: Dictionary = EnemyDataScript.get_enemy(enemy_key)
		var depth: String = String(enemy["depth"])
		if depth != current_depth:
			current_depth = depth
			grid = _build_section(depth)
		grid.add_child(_build_card(enemy_key, enemy))


func _build_section(depth: String) -> GridContainer:
	var section: PanelContainer = PanelContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.clip_contents = true
	section.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var bg: TextureRect = TextureRect.new()
	bg.texture = SeaLowAtlasScript.get_background_texture(EnemyDataScript.get_background_cell(depth))
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	section.add_child(bg)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.05, 0.1, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	section.add_child(dim)

	var margin: MarginContainer = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	section.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = depth.replace("_", " ").to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("outline_size", 8)
	vbox.add_child(title)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grid)

	enemy_grid.add_child(section)
	return grid


func _clear_cards() -> void:
	for child in enemy_grid.get_children():
		child.queue_free()


func _build_card(enemy_key: String, enemy: Dictionary) -> Control:
	var free_for_all: bool = SaveManager.is_free_for_all()
	var unlocked: bool = SaveManager.is_enemy_selectable(enemy_key)
	var beaten: bool = SaveManager.is_enemy_beaten(enemy_key) and not free_for_all

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 340)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.12, 0.18, 0.88)
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

	# Standalone PNG sprite. Dimmed (but still visible) when locked, so the
	# player can preview what's coming without being able to select it.
	var icon: TextureRect = TextureRect.new()
	icon.texture = EnemyDataScript.get_texture(enemy_key)
	icon.custom_minimum_size = Vector2(0, 128)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.55, 0.55, 0.62, 1)
	vbox.add_child(icon)

	var name_label: Label = Label.new()
	name_label.text = String(enemy["display_name"]).to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	var hp_label: Label = Label.new()
	hp_label.text = "❤ %d HP" % int(enemy["max_hp"])
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 22)
	hp_label.add_theme_color_override("font_color", Color(0.678431, 0.72549, 0.741176, 1))
	vbox.add_child(hp_label)

	var depth_label: Label = Label.new()
	depth_label.text = String(enemy["depth"]).replace("_", " ").to_upper()
	depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	depth_label.add_theme_font_size_override("font_size", 18)
	depth_label.add_theme_color_override("font_color", Color(0.34902, 0.784314, 0.698039, 1))
	vbox.add_child(depth_label)

	var status_label: Label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20)

	if not unlocked:
		status_label.text = "🔒 LOCKED"
		status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 1))
	elif beaten:
		status_label.text = "✓ BEATEN"
		status_label.add_theme_color_override("font_color", Color(0.941176, 0.760784, 0.239216, 1))
	else:
		status_label.text = "AVAILABLE"
		status_label.add_theme_color_override("font_color", Color(0.34902, 0.784314, 0.698039, 1))

	vbox.add_child(status_label)

	var select_button: Button = Button.new()
	select_button.text = "SELECT"
	select_button.custom_minimum_size = Vector2(0, 64)
	select_button.disabled = not unlocked
	select_button.pressed.connect(_on_select_pressed.bind(enemy_key))
	vbox.add_child(select_button)

	return panel


## Persists the chosen enemy and dives straight into battle against it.
func _on_select_pressed(enemy_key: String) -> void:
	if not SaveManager.is_enemy_selectable(enemy_key):
		return

	SaveManager.set_selected_enemy(enemy_key)
	SceneManager.go_to_battle()
