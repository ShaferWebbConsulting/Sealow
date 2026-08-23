extends Control

const OCTO_MAX_HP: int = 12
const CRAB_MAX_HP: int = 10

enum BattleState {
	PLAYER_TURN,
	PLAYER_ROLLING,
	ENEMY_TURN,
	ENEMY_ROLLING,
	VICTORY,
	DEFEAT,
}

var state: BattleState = BattleState.PLAYER_TURN
var octo_hp: int = OCTO_MAX_HP
var crab_hp: int = CRAB_MAX_HP

@onready var state_label: Label = %StateLabel
@onready var octo_hp_label: Label = %OctoHpLabel
@onready var crab_hp_label: Label = %CrabHpLabel
@onready var roll_button: Button = %RollButton
@onready var return_button: Button = %ReturnHomeButton

func _ready() -> void:
	roll_button.pressed.connect(_on_roll_pressed)
	return_button.pressed.connect(_on_return_home_pressed)
	_refresh_ui()

func _refresh_ui() -> void:
	octo_hp_label.text = "HP %d / %d" % [octo_hp, OCTO_MAX_HP]
	crab_hp_label.text = "HP %d / %d" % [crab_hp, CRAB_MAX_HP]
	state_label.text = "Your turn"
	roll_button.disabled = state != BattleState.PLAYER_TURN

func _on_roll_pressed() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	state = BattleState.PLAYER_ROLLING
	state_label.text = "Dice combat is coming next milestone..."
	roll_button.disabled = true

func _on_return_home_pressed() -> void:
	SceneManager.go_to_main_menu()
