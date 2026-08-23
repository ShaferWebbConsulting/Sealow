extends Control

const DiceRules = preload("res://scripts/battle/dice_rules.gd")

const OCTO_MAX_HP: int = 12
const CRAB_MAX_HP: int = 10
const OCTO_DICE_COUNT: int = 3
const CRAB_DICE_COUNT: int = 3
const VICTORY_SHELLS: int = 10

const DICE_FACES: Array[String] = [
	"⚀",
	"⚁",
	"⚂",
	"⚃",
	"⚄",
	"⚅",
]

## Only BattleState.PLAYER_TURN allows the Roll button to be pressed. Every
## other state means a turn is currently animating/resolving.
enum BattleState {
	PLAYER_TURN,
	PLAYER_ROLLING,
	ENEMY_ROLLING,
	RESOLVING_ROUND,
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
@onready var rules_button: Button = %RulesButton

@onready var octo_dice: Array[Label] = [%OctoDie1, %OctoDie2, %OctoDie3]
@onready var crab_dice: Array[Label] = [%CrabDie1, %CrabDie2, %CrabDie3]

@onready var octo_hand_label: Label = %OctoHandLabel
@onready var crab_hand_label: Label = %CrabHandLabel

@onready var crab_damage_label: Label = %CrabDamageLabel
@onready var octo_damage_label: Label = %OctoDamageLabel

@onready var victory_panel: Control = %VictoryPanel
@onready var shells_earned_label: Label = %ShellsEarnedLabel
@onready var victory_return_button: Button = %VictoryReturnButton

@onready var defeat_panel: Control = %DefeatPanel
@onready var defeat_retry_button: Button = %DefeatRetryButton
@onready var defeat_return_button: Button = %DefeatReturnButton

@onready var rules_panel: Control = %RulesPanel
@onready var rules_close_button: Button = %RulesCloseButton


func _ready() -> void:
	roll_button.pressed.connect(_on_roll_pressed)
	return_button.pressed.connect(_on_return_home_pressed)
	victory_return_button.pressed.connect(_on_return_home_pressed)
	defeat_return_button.pressed.connect(_on_return_home_pressed)
	defeat_retry_button.pressed.connect(_on_try_again_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	rules_close_button.pressed.connect(_on_rules_close_pressed)
	start_battle()


func _exit_tree() -> void:
	exiting_scene = true


func start_battle() -> void:
	state = BattleState.PLAYER_TURN
	octo_hp = OCTO_MAX_HP
	crab_hp = CRAB_MAX_HP

	victory_panel.visible = false
	defeat_panel.visible = false
	rules_panel.visible = false
	crab_damage_label.visible = false
	octo_damage_label.visible = false
	roll_result_label.text = ""
	octo_hand_label.text = ""
	crab_hand_label.text = ""

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
	perform_round()


func _on_rules_pressed() -> void:
	rules_panel.visible = true


func _on_rules_close_pressed() -> void:
	rules_panel.visible = false


## Runs one full SeaLow round: Octo rolls, Crab rolls, hands are compared,
## and the loser takes damage. Guards against overlapping/duplicate rounds
## by immediately leaving PLAYER_TURN before any awaits happen.
func perform_round() -> void:
	state = BattleState.PLAYER_ROLLING
	roll_result_label.text = ""
	octo_hand_label.text = ""
	crab_hand_label.text = ""
	state_label.text = "Little Octo is rolling..."
	update_ui()

	var octo_hand: DiceRules.DiceHand = await _roll_and_animate(octo_dice, OCTO_DICE_COUNT, "Little Octo")
	if exiting_scene or not is_inside_tree():
		return

	octo_hand_label.text = _format_hand_display(octo_hand)
	state_label.text = "Little Octo rolled %s" % octo_hand.display_name

	await get_tree().create_timer(0.6).timeout
	if exiting_scene or not is_inside_tree():
		return

	state = BattleState.ENEMY_ROLLING
	state_label.text = "Crab is rolling..."
	update_ui()

	var crab_hand: DiceRules.DiceHand = await _roll_and_animate(crab_dice, CRAB_DICE_COUNT, "Crab")
	if exiting_scene or not is_inside_tree():
		return

	crab_hand_label.text = _format_hand_display(crab_hand)
	state_label.text = "Crab rolled %s" % crab_hand.display_name

	state = BattleState.RESOLVING_ROUND
	update_ui()

	await get_tree().create_timer(0.4).timeout
	if exiting_scene or not is_inside_tree():
		return

	_resolve_round(octo_hand, crab_hand)


## Rolls dice (auto-rerolling NO_POINT hands) and animates the result.
## Returns the final scoring DiceHand.
func _roll_and_animate(labels: Array[Label], count: int, creature_name: String) -> DiceRules.DiceHand:
	var attempts: int = 0
	var raw_dice: Array[int] = DiceRules.roll_dice(count)
	var hand: DiceRules.DiceHand = DiceRules.evaluate_hand(raw_dice)

	await animate_dice(labels, raw_dice)
	if exiting_scene or not is_inside_tree():
		return hand

	while hand.hand_type == DiceRules.HandType.NO_POINT and attempts < DiceRules.MAX_REROLLS:
		state_label.text = "No point — rolling again..."
		await get_tree().create_timer(0.25).timeout
		if exiting_scene or not is_inside_tree():
			return hand

		raw_dice = DiceRules.roll_dice(count)
		hand = DiceRules.evaluate_hand(raw_dice)
		await animate_dice(labels, raw_dice)
		if exiting_scene or not is_inside_tree():
			return hand
		attempts += 1

	if hand.hand_type == DiceRules.HandType.NO_POINT:
		# Safety fallback: accept the highest die as the point value.
		var highest: int = hand.dice_values.max()
		hand = DiceRules.DiceHand.new(DiceRules.HandType.POINT, highest, hand.dice_values, "POINT %d" % highest)

	return hand


func _format_hand_display(hand: DiceRules.DiceHand) -> String:
	match hand.hand_type:
		DiceRules.HandType.TIDAL_ROLL:
			return "🌊 TIDAL ROLL! 🌊"
		DiceRules.HandType.WASHED_OUT:
			return "💀 WASHED OUT!"
		_:
			return hand.display_name


func _resolve_round(octo_hand: DiceRules.DiceHand, crab_hand: DiceRules.DiceHand) -> void:
	var result: int = DiceRules.compare_hands(octo_hand, crab_hand)

	if result == 0:
		roll_result_label.text = "TIE!\nNobody takes damage."
		state_label.text = "Tie! Nobody takes damage."
		await get_tree().create_timer(0.75).timeout
		if exiting_scene or not is_inside_tree():
			return
		_start_next_round()
		return

	if result == 1:
		var damage: int = DiceRules.calculate_damage(octo_hand, crab_hand)
		roll_result_label.text = "%s beats %s!\n\n🐙 LITTLE OCTO WINS THE ROUND" % [octo_hand.display_name, crab_hand.display_name]
		apply_damage_to_crab(damage)
		state_label.text = "Crab takes %d damage!" % damage

		if crab_hp <= 0:
			show_victory()
			return
	else:
		var damage: int = DiceRules.calculate_damage(crab_hand, octo_hand)
		roll_result_label.text = "%s beats %s!\n\n🦀 CRAB WINS THE ROUND" % [crab_hand.display_name, octo_hand.display_name]
		apply_damage_to_player(damage)
		state_label.text = "Little Octo takes %d damage!" % damage

		if octo_hp <= 0:
			show_defeat()
			return

	await get_tree().create_timer(0.75).timeout
	if exiting_scene or not is_inside_tree():
		return
	_start_next_round()


func _start_next_round() -> void:
	state = BattleState.PLAYER_TURN
	state_label.text = "Your turn"
	update_ui()


func animate_dice(labels: Array[Label], results: Array[int]) -> void:
	var active_labels: Array[Label] = labels.slice(0, results.size())
	var pulse_tweens: Array[Tween] = []
	for label in active_labels:
		label.visible = true
		pulse_tweens.append(null)

	var duration: float = 0.6
	var step: float = 0.08
	var elapsed: float = 0.0

	while elapsed < duration:
		for i in active_labels.size():
			var label: Label = active_labels[i]
			label.text = DICE_FACES[randi_range(0, 5)]
			if pulse_tweens[i] != null and pulse_tweens[i].is_valid():
				pulse_tweens[i].kill()
			var tween: Tween = create_tween()
			tween.tween_property(label, "scale", Vector2(1.15, 1.15), step * 0.5)
			tween.tween_property(label, "scale", Vector2(1.0, 1.0), step * 0.5)
			pulse_tweens[i] = tween
		await get_tree().create_timer(step).timeout
		if exiting_scene or not is_inside_tree():
			return
		elapsed += step

	for i in active_labels.size():
		active_labels[i].text = DICE_FACES[results[i] - 1]


func apply_damage_to_crab(amount: int) -> void:
	crab_hp = maxi(0, crab_hp - amount)
	update_ui()
	_show_floating_damage(crab_damage_label, amount)


func apply_damage_to_player(amount: int) -> void:
	octo_hp = maxi(0, octo_hp - amount)
	update_ui()
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
