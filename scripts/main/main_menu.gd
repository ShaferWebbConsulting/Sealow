extends Control

@onready var dive_button: Button = %DiveButton

func _ready() -> void:
	dive_button.pressed.connect(_on_dive_pressed)

func _on_dive_pressed() -> void:
	SceneManager.go_to_battle()
