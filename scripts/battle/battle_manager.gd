extends Control

const OCTO_MAX_HP: int = 12
const CRAB_MAX_HP: int = 10
const CRAB_ARMOR: int = 1
const OCTO_DICE_COUNT: int = 3
const CRAB_DICE_COUNT: int = 2
const VICTORY_SHELLS: int = 10

const DICE_FACES: Array[String] = [
	"⚀",
	"⚁",
	"⚂",
	"⚃",
	"⚄",
	"⚅",
]

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
var exiting_scene: bool = false

@onready var state_label: Label = %StateLabel
@onready var roll_result_label: Label = %RollResultLabel
@onready var octo_hp_label: Label = %OctoHpLabel
@onready var crab_hp_label: Label = %CrabHpLabel
@onready var roll_button: Button = %RollButton
@onready var return_button: Button = %ReturnHomeButton

@onready var octo_dice: Array[Label] = [%OctoDie1, %OctoDie2, %OctoDie3]
@onready var crab_dice: Array[Label] = [%CrabDie1, %CrabDie2]

@onready var crab_damage_label: Label = %CrabDamageLabel
@onready var octo_damage_label: Label = %OctoDamageLabel

@onready var victory_panel: Control = %VictoryPanel
@onready var shells_earned_label: Label = %ShellsEarnedLabel
@onready var victory_return_button: Button = %VictoryReturnButton

@onready var defeat_panel: Control = %DefeatPanel
@onready var defeat_retry_button: Button = %DefeatRetryButton
@onready var defeat_return_button: Button = %DefeatReturnButton


func _ready() -> void:
	roll_button.pressed.connect(_on_roll_pressed)
	return_button.pressed.connect(_on_return_home_pressed)
	victory_return_button.pressed.connect(_on_return_home_pressed)
	defeat_return_button.pressed.connect(_on_return_home_pressed)
	defeat_retry_button.pressed.connect(_on_try_again_pressed)
	start_battle()


func _exit_tree() -> void:
	exiting_scene = true


func start_battle() -> void:
	state = BattleState.PLAYER_TURN
	octo_hp = OCTO_MAX_HP
	crab_hp = CRAB_MAX_HP

	victory_panel.visible = false
	defeat_panel.visible = false
	crab_damage_label.visible = false
	octo_damage_label.visible = false
	roll_result_label.text = ""

	_reset_dice(crab_dice)
	_reset_dice(octo_dice)

	state_label.text = "Your turn"
	update_ui()


func _reset_dice(dice: Array[Label]) -> void:
	for die in dice:
		die.text = DICE_FACES[0]


func update_ui() -> void:
	octo_hp_label.text = "HP %d / %d" % [octo_hp, OCTO_MAX_HP]
	crab_hp_label.text = "HP %d / %d" % [crab_hp, CRAB_MAX_HP]
	roll_button.disabled = state != BattleState.PLAYER_TURN
	roll_button.visible = state != BattleState.VICTORY and state != BattleState.DEFEAT


func _on_roll_pressed() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	roll_button.disabled = true
	perform_player_turn()


func perform_player_turn() -> void:
	state = BattleState.PLAYER_ROLLING
	state_label.text = "I'm rolling..."
	roll_result_label.text = ""
	update_ui()

	var results: Array[int] = roll_dice(OCTO_DICE_COUNT)
	await animate_dice(octo_dice, results)
	if exiting_scene or not is_inside_tree():
		return

	var total: int = 0
	for value in results:
		total += value
	roll_result_label.text = "You rolled %d!" % total

	var damage: int = calculate_player_damage(total)
	apply_damage_to_crab(damage)

	if crab_hp <= 0:
		show_victory()
		return

	await get_tree().create_timer(0.75).timeout
	if exiting_scene or not is_inside_tree():
		return

	await perform_enemy_turn()


func perform_enemy_turn() -> void:
	state = BattleState.ENEMY_TURN
	state_label.text = "Crab turn"
	update_ui()

	state = BattleState.ENEMY_ROLLING
	state_label.text = "Opponent is rolling..."
	update_ui()

	var results: Array[int] = roll_dice(CRAB_DICE_COUNT)
	await animate_dice(crab_dice, results)
	if exiting_scene or not is_inside_tree():
		return

	var total: int = 0
	for value in results:
		total += value
	roll_result_label.text = "Crab rolled %d + %d = %d" % [results[0], results[1], total]

	var damage: int = calculate_enemy_damage(total)
	apply_damage_to_player(damage)

	if octo_hp <= 0:
		show_defeat()
		return

	await get_tree().create_timer(0.5).timeout
	if exiting_scene or not is_inside_tree():
		return

	state = BattleState.PLAYER_TURN
	state_label.text = "Your turn"
	update_ui()


func roll_dice(count: int) -> Array[int]:
	var results: Array[int] = []
	for i in count:
		results.append(randi_range(1, 6))
	return results


func animate_dice(labels: Array[Label], results: Array[int]) -> void:
	var active_labels: Array[Label] = labels.slice(0, results.size())
	for label in active_labels:
		label.visible = true

	var duration: float = 0.6
	var step: float = 0.08
	var elapsed: float = 0.0

	while elapsed < duration:
		for label in active_labels:
			label.text = DICE_FACES[randi_range(0, 5)]
			var tween: Tween = create_tween()
			tween.tween_property(label, "scale", Vector2(1.15, 1.15), step * 0.5)
			tween.tween_property(label, "scale", Vector2(1.0, 1.0), step * 0.5)
		await get_tree().create_timer(step).timeout
		if exiting_scene or not is_inside_tree():
			return
		elapsed += step

	for i in active_labels.size():
		active_labels[i].text = DICE_FACES[results[i] - 1]


func calculate_player_damage(total: int) -> int:
	var raw_damage: int = maxi(1, floori(float(total) / 4.0))
	var final_damage: int = maxi(1, raw_damage - CRAB_ARMOR)
	return final_damage


func calculate_enemy_damage(total: int) -> int:
	return maxi(1, floori(float(total) / 5.0))


func apply_damage_to_crab(amount: int) -> void:
	crab_hp = maxi(0, crab_hp - amount)
	update_ui()
	state_label.text = "Crab takes %d damage!" % amount
	_show_floating_damage(crab_damage_label, amount)


func apply_damage_to_player(amount: int) -> void:
	octo_hp = maxi(0, octo_hp - amount)
	update_ui()
	state_label.text = "Little Octo takes %d damage!" % amount
	_show_floating_damage(octo_damage_label, amount)


func _show_floating_damage(label: Label, amount: int) -> void:
	label.text = "-%d" % amount
	label.visible = true
	label.modulate.a = 1.0
	label.position.y = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(label, "position:y", -30.0, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func() -> void:
		label.visible = false
	)


func show_victory() -> void:
	state = BattleState.VICTORY
	state_label.text = "Victory!"
	update_ui()

	_award_victory_shells()
	victory_panel.visible = true


func _award_victory_shells() -> void:
	shells_earned_label.text = "+%d Shells" % VICTORY_SHELLS
	var save_manager: Node = get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("add_shells"):
		save_manager.add_shells(VICTORY_SHELLS)


func show_defeat() -> void:
	state = BattleState.DEFEAT
	state_label.text = "Defeat..."
	update_ui()
	defeat_panel.visible = true


func restart_battle() -> void:
	start_battle()


func _on_try_again_pressed() -> void:
	restart_battle()


func _on_return_home_pressed() -> void:
	exiting_scene = true
	SceneManager.go_to_main_menu()
