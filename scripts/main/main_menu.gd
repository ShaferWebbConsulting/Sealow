extends Control

@onready var dive_button: Button = %DiveButton
@onready var settings_button: Button = %SettingsButton
@onready var settings_panel: Control = %SettingsPanel
@onready var settings_back_button: Button = %SettingsBackButton
@onready var shells_label: Label = %Shells


func _ready() -> void:
	dive_button.pressed.connect(_on_dive_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	settings_panel.visible = false
	update_player_ui()


## Reads the single authoritative shell total from SaveManager. Called on
## every MainMenu._ready() so the displayed total always reflects the
## latest saved value, including right after a battle victory.
func update_player_ui() -> void:
	shells_label.text = "🐚 %d Shells" % SaveManager.player_shells


func _on_dive_pressed() -> void:
	SceneManager.go_to_battle()


func _on_settings_pressed() -> void:
	settings_panel.visible = true


func _on_settings_back_pressed() -> void:
	settings_panel.visible = false
