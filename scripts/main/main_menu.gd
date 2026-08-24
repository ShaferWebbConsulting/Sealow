extends Control

const PlayerDataScript = preload("res://scripts/player/player_data.gd")

@onready var dive_button: Button = %DiveButton
@onready var shop_button: Button = %ShopButton
@onready var settings_button: Button = %SettingsButton
@onready var settings_panel: Control = %SettingsPanel
@onready var settings_back_button: Button = %SettingsBackButton
@onready var shells_label: Label = %Shells
@onready var character_emoji_label: Label = %Octo
@onready var character_name_label: Label = %Name
@onready var character_preview_body: Panel = %PreviewBody


func _ready() -> void:
	if not SaveManager.is_character_selected():
		SceneManager.go_to_character_select.call_deferred()
		return

	dive_button.pressed.connect(_on_dive_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	settings_panel.visible = false
	update_player_ui()


## Reads authoritative player state from SaveManager. Called on every
## MainMenu._ready() so the displayed character/shells always reflect the
## latest saved values, including right after a battle victory.
func update_player_ui() -> void:
	shells_label.text = "🐚 %d Shells" % SaveManager.player_shells
	var character_type: String = SaveManager.get_character_type()
	character_emoji_label.text = PlayerDataScript.get_emoji(character_type)
	character_name_label.text = "%s\nLv. %d" % [
		PlayerDataScript.get_display_name(character_type),
		SaveManager.get_level(),
	]

	# Tint only the "body" preview panel behind the creature emoji — the
	# emoji glyph itself (eyes/outline/highlights) is never tinted.
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PlayerDataScript.get_color(SaveManager.get_character_color())
	style.set_corner_radius_all(88)
	character_preview_body.add_theme_stylebox_override("panel", style)


func _on_dive_pressed() -> void:
	SceneManager.go_to_battle()


func _on_shop_pressed() -> void:
	SceneManager.go_to_shop()


func _on_settings_pressed() -> void:
	settings_panel.visible = true


func _on_settings_back_pressed() -> void:
	settings_panel.visible = false
