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
var enemy_cycle_running: bool = false
var exiting_scene: bool = false

@onready var state_label: Label = %StateLabel
@onready var octo_hp_label: Label = %OctoHpLabel
@onready var crab_hp_label: Label = %CrabHpLabel
@onready var roll_button: Button = %RollButton
@onready var return_button: Button = %ReturnHomeButton

func _ready() -> void:
	roll_button.pressed.connect(_on_roll_pressed)
	return_button.pressed.connect(_on_return_home_pressed)
	_refresh_ui()

func _exit_tree() -> void:
	exiting_scene = true

func _refresh_ui() -> void:
	octo_hp_label.text = "HP %d / %d" % [octo_hp, OCTO_MAX_HP]
	crab_hp_label.text = "HP %d / %d" % [crab_hp, CRAB_MAX_HP]
	state_label.text = _state_text(state)
	roll_button.disabled = state != BattleState.PLAYER_TURN

func _state_text(current_state: BattleState) -> String:
	match current_state:
		BattleState.PLAYER_TURN:
			return "Your turn"
		BattleState.PLAYER_ROLLING:
			return "Rolling..."
		BattleState.ENEMY_TURN:
			return "Crab turn"
		BattleState.ENEMY_ROLLING:
			return "Crab rolling..."
		BattleState.VICTORY:
			return "Victory!"
		BattleState.DEFEAT:
			return "Defeat..."
		_:
			return ""

func _on_roll_pressed() -> void:
	if state != BattleState.PLAYER_TURN or enemy_cycle_running:
		return
	enemy_cycle_running = true
	state = BattleState.PLAYER_ROLLING
	_refresh_ui()
	await _run_enemy_cycle()
	enemy_cycle_running = false

func _run_enemy_cycle() -> void:
	await get_tree().create_timer(0.35).timeout
	if exiting_scene or not is_inside_tree():
		return
	state = BattleState.ENEMY_TURN
	_refresh_ui()
	await get_tree().create_timer(0.75).timeout
	if exiting_scene or not is_inside_tree():
		return
	state = BattleState.ENEMY_ROLLING
	_refresh_ui()
	await get_tree().create_timer(0.35).timeout
	if exiting_scene or not is_inside_tree():
		return
	state = BattleState.PLAYER_TURN
	_refresh_ui()

func _on_return_home_pressed() -> void:
	exiting_scene = true
	SceneManager.go_to_main_menu()
