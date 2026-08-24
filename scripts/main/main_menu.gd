extends Control

const PlayerDataScript = preload("res://scripts/player/player_data.gd")

@onready var dive_button: Button = %DiveButton
@onready var shop_button: Button = %ShopButton
@onready var settings_button: Button = %SettingsButton

@onready var settings_panel: Control = %SettingsPanel
@onready var settings_back_button: Button = %SettingsBackButton

@onready var shells_label: Label = %Shells
@onready var character_emoji_label: Label = %Octo
@onready var player_name_button: Button = %Name
@onready var character_preview_body: Panel = %PreviewBody

@onready var name_edit_panel: Control = %NameEditPanel
@onready var name_input: LineEdit = %NameInput
@onready var save_name_button: Button = %SaveNameButton
@onready var cancel_name_button: Button = %CancelNameButton


func _ready() -> void:
	if not SaveManager.is_character_selected():
		SceneManager.go_to_character_select.call_deferred()
		return

	# Main navigation.
	dive_button.pressed.connect(_on_dive_pressed)
	shop_button.pressed.connect(_on_shop_pressed)

	# Settings.
	settings_button.pressed.connect(_on_settings_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)

	# Player name editing.
	player_name_button.pressed.connect(_on_name_pressed)
	save_name_button.pressed.connect(_on_save_name_pressed)
	cancel_name_button.pressed.connect(_on_cancel_name_pressed)

	# Pressing Enter / Done on the keyboard also saves the name.
	name_input.text_submitted.connect(_on_name_submitted)

	# Start with popups hidden.
	settings_panel.visible = false
	name_edit_panel.visible = false

	update_player_ui()


## Reads authoritative player state from SaveManager.
## Called whenever the Main Menu loads and after changing the player's name.
func update_player_ui() -> void:
	shells_label.text = "🐚 %d Shells" % SaveManager.player_shells

	var character_type: String = SaveManager.get_character_type()
	var player_name: String = SaveManager.get_player_name()
	var creature_name: String = PlayerDataScript.get_display_name(character_type)

	character_emoji_label.text = PlayerDataScript.get_emoji(character_type)

	# The player's custom name is shown first.
	# The creature type and level appear below it.
	player_name_button.text = "%s\n%s · Lv. %d" % [
		player_name,
		creature_name,
		SaveManager.get_level(),
	]

	# Tint only the "body" preview panel behind the creature emoji.
	# The emoji glyph itself remains untinted.
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PlayerDataScript.get_color(
		SaveManager.get_character_color()
	)
	style.set_corner_radius_all(88)

	character_preview_body.add_theme_stylebox_override(
		"panel",
		style
	)


func _on_dive_pressed() -> void:
	SceneManager.go_to_battle()


func _on_shop_pressed() -> void:
	SceneManager.go_to_shop()


func _on_settings_pressed() -> void:
	# Don't allow both popups to be open at once.
	name_edit_panel.visible = false
	settings_panel.visible = true


func _on_settings_back_pressed() -> void:
	settings_panel.visible = false


## Opens the rename popup when the displayed player name is tapped.
func _on_name_pressed() -> void:
	# Don't allow both popups to be open at once.
	settings_panel.visible = false

	# Pre-fill the input with the player's current name.
	name_input.text = SaveManager.get_player_name()

	name_edit_panel.visible = true

	# Put keyboard focus into the input and select the current name
	# so it can easily be replaced.
	name_input.grab_focus()
	name_input.select_all()


## Saves the player's new name.
func _on_save_name_pressed() -> void:
	var new_name: String = name_input.text.strip_edges()

	# Do not save an empty name.
	if new_name.is_empty():
		return

	SaveManager.set_player_name(new_name)

	name_edit_panel.visible = false
	name_input.release_focus()

	# Immediately refresh the Main Menu.
	update_player_ui()


## Closes the rename popup without saving.
func _on_cancel_name_pressed() -> void:
	name_edit_panel.visible = false
	name_input.release_focus()


## Pressing Enter / Return / Done in the LineEdit saves the name.
func _on_name_submitted(_new_text: String) -> void:
	_on_save_name_pressed()
