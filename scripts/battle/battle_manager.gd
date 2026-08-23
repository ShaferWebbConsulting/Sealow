extends Control

const DiceRules = preload("res://scripts/battle/dice_rules.gd")

const OCTO_MAX_HP: int = 12
const CRAB_MAX_HP: int = 10
const OCTO_DICE_COUNT: int = 3
const CRAB_DICE_COUNT: int = 3
const VICTORY_SHELLS: int = 10
const HP_TWEEN_DURATION: float = 0.3

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

## Guards against awarding shells more than once for the same victory, even
## if the victory panel's button is pressed repeatedly.
var victory_reward_given: bool = false

## Tracks the currently running HP bar tween per ProgressBar so a rapid
## sequence of damage events never animates the same bar with overlapping
## tweens (which would cause the fill to jitter/snap).
var _hp_bar_tweens: Dictionary = {}

@onready var message_label: Label = %MessageLabel
@onready var octo_hp_label: Label = %OctoHpLabel
@onready var crab_hp_label: Label = %CrabHpLabel
@onready var octo_hp_bar: ProgressBar = %OctoHpBar
@onready var crab_hp_bar: ProgressBar = %CrabHpBar
@onready var roll_button: Button = %RollButton
@onready var bet_button: Button = %BetButton
@onready var run_button: Button = %RunButton
@onready var rules_button: Button = %RulesButton

@onready var octo_dice_row: HBoxContainer = %OctoDiceRow
@onready var crab_dice_row: HBoxContainer = %CrabDiceRow
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

@onready var run_confirm_panel: Control = %RunConfirmPanel
@onready var stay_button: Button = %StayButton
@onready var confirm_run_button: Button = %ConfirmRunButton

@onready var rules_panel: Control = %RulesPanel
@onready var rules_close_button: Button = %RulesCloseButton


func _ready() -> void:
	roll_button.pressed.connect(_on_roll_pressed)
	run_button.pressed.connect(_on_run_pressed)
	stay_button.pressed.connect(_on_stay_pressed)
	confirm_run_button.pressed.connect(_on_confirm_run_pressed)
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
	victory_reward_given = false

	victory_panel.visible = false
	defeat_panel.visible = false
	rules_panel.visible = false
	run_confirm_panel.visible = false
	crab_damage_label.visible = false
	octo_damage_label.visible = false
	octo_dice_row.visible = false
	crab_dice_row.visible = false
	octo_hand_label.visible = false
	crab_hand_label.visible = false
	octo_hand_label.text = ""
	crab_hand_label.text = ""

	_reset_dice(crab_dice)
	_reset_dice(octo_dice)

	octo_hp_bar.max_value = OCTO_MAX_HP
	crab_hp_bar.max_value = CRAB_MAX_HP
	octo_hp_bar.value = OCTO_MAX_HP
	crab_hp_bar.value = CRAB_MAX_HP

	message_label.text = "What will Octo do?"
	update_ui()


func _reset_dice(dice: Array[Label]) -> void:
	for die in dice:
		die.text = DICE_FACES[0]


func update_ui() -> void:
	octo_hp_label.text = "HP %d / %d" % [octo_hp, OCTO_MAX_HP]
	crab_hp_label.text = "HP %d / %d" % [crab_hp, CRAB_MAX_HP]
	roll_button.disabled = state != BattleState.PLAYER_TURN
	roll_button.visible = state != BattleState.VICTORY and state != BattleState.DEFEAT
	run_button.disabled = state != BattleState.PLAYER_TURN


## Animates a health bar's ProgressBar value toward `new_value` rather than
## snapping instantly, so HP loss reads as a clear, gentle visual change.
## Kills any tween already animating this bar first so rapid successive
## damage events can never leave overlapping tweens fighting over the value.
func _animate_hp_bar(bar: ProgressBar, new_value: int) -> void:
	var existing_tween: Tween = _hp_bar_tweens.get(bar)
	if existing_tween != null and existing_tween.is_valid():
		existing_tween.kill()

	var tween: Tween = create_tween()
	tween.tween_property(bar, "value", float(new_value), HP_TWEEN_DURATION)
	_hp_bar_tweens[bar] = tween


func _on_roll_pressed() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	perform_round()


func _on_rules_pressed() -> void:
	rules_panel.visible = true


func _on_rules_close_pressed() -> void:
	rules_panel.visible = false


func _on_run_pressed() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	run_confirm_panel.visible = true


func _on_stay_pressed() -> void:
	run_confirm_panel.visible = false


## Confirms fleeing the battle. No shells are awarded for running.
func _on_confirm_run_pressed() -> void:
	run_confirm_panel.visible = false
	exiting_scene = true
	SceneManager.go_to_main_menu()


## Runs one full SeaLow round: Octo rolls, Crab rolls, hands are compared,
## and the loser takes damage. Guards against overlapping/duplicate rounds
## by immediately leaving PLAYER_TURN before any awaits happen.
func perform_round() -> void:
	state = BattleState.PLAYER_ROLLING
	octo_hand_label.visible = false
	crab_hand_label.visible = false
	octo_hand_label.text = ""
	crab_hand_label.text = ""
	crab_dice_row.visible = false
	message_label.text = "Little Octo is rolling..."
	update_ui()

	var octo_hand: DiceRules.DiceHand = await _roll_and_animate(octo_dice_row, octo_dice, OCTO_DICE_COUNT, "Little Octo")
	if exiting_scene or not is_inside_tree():
		return

	octo_hand_label.text = _format_hand_display(octo_hand)
	octo_hand_label.visible = true
	message_label.text = "Little Octo rolled..."

	await get_tree().create_timer(0.6).timeout
	if exiting_scene or not is_inside_tree():
		return

	state = BattleState.ENEMY_ROLLING
	message_label.text = "Crab is rolling..."
	update_ui()

	var crab_hand: DiceRules.DiceHand = await _roll_and_animate(crab_dice_row, crab_dice, CRAB_DICE_COUNT, "Crab")
	if exiting_scene or not is_inside_tree():
		return

	crab_hand_label.text = _format_hand_display(crab_hand)
	crab_hand_label.visible = true
	message_label.text = "Crab rolled..."

	state = BattleState.RESOLVING_ROUND
	update_ui()

	await get_tree().create_timer(0.4).timeout
	if exiting_scene or not is_inside_tree():
		return

	_resolve_round(octo_hand, crab_hand)


## Rolls dice (auto-rerolling NO_POINT hands) and animates the result.
## Returns the final scoring DiceHand.
func _roll_and_animate(row: HBoxContainer, labels: Array[Label], count: int, creature_name: String) -> DiceRules.DiceHand:
	row.visible = true
	var attempts: int = 0
	var raw_dice: Array[int] = DiceRules.roll_dice(count)
	var hand: DiceRules.DiceHand = DiceRules.evaluate_hand(raw_dice)

	await animate_dice(labels, raw_dice)
	if exiting_scene or not is_inside_tree():
		return hand

	while hand.hand_type == DiceRules.HandType.NO_POINT and attempts < DiceRules.MAX_REROLLS:
		message_label.text = "%s: No point — rolling again..." % creature_name
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
		hand = DiceRules.fallback_hand(hand)

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
	# Defensive guard: _roll_and_animate can return early with an unresolved
	# NO_POINT hand if the scene is exiting mid-round. Never score that case.
	if octo_hand.hand_type == DiceRules.HandType.NO_POINT or crab_hand.hand_type == DiceRules.HandType.NO_POINT:
		return

	var result: int = DiceRules.compare_hands(octo_hand, crab_hand)

	if result == 0:
		message_label.text = "TIE!\nNobody takes damage."
		await get_tree().create_timer(0.75).timeout
		if exiting_scene or not is_inside_tree():
			return
		_start_next_round()
		return

	if result == 1:
		var damage: int = DiceRules.calculate_damage(octo_hand, crab_hand)
		apply_damage_to_crab(damage)
		message_label.text = "%s\n\nLittle Octo wins the round!\nCrab takes %d damage." % [_format_round_summary(octo_hand, crab_hand), damage]

		if crab_hp <= 0:
			await get_tree().create_timer(0.75).timeout
			if exiting_scene or not is_inside_tree():
				return
			show_victory()
			return
	else:
		var damage: int = DiceRules.calculate_damage(crab_hand, octo_hand)
		apply_damage_to_player(damage)
		message_label.text = "%s\n\nCrab wins the round!\nLittle Octo takes %d damage." % [_format_round_summary(crab_hand, octo_hand), damage]

		if octo_hp <= 0:
			await get_tree().create_timer(0.75).timeout
			if exiting_scene or not is_inside_tree():
				return
			show_defeat()
			return

	await get_tree().create_timer(1.1).timeout
	if exiting_scene or not is_inside_tree():
		return
	_start_next_round()


## Builds the "X beats Y" summary shown above the round result. When both
## hands are pair hands that share the same pair value, calls that out
## explicitly before comparing the unmatched (high) die, since that's the
## tiebreaker that actually decided the round.
func _format_round_summary(winner_hand: DiceRules.DiceHand, loser_hand: DiceRules.DiceHand) -> String:
	if winner_hand.hand_type == DiceRules.HandType.POINT and loser_hand.hand_type == DiceRules.HandType.POINT and winner_hand.pair_value == loser_hand.pair_value:
		return "Both have PAIR %d — HIGH %d beats HIGH %d!" % [winner_hand.pair_value, winner_hand.point_value, loser_hand.point_value]

	return "%s beats %s!" % [winner_hand.display_name, loser_hand.display_name]


func _start_next_round() -> void:
	state = BattleState.PLAYER_TURN
	octo_dice_row.visible = false
	crab_dice_row.visible = false
	octo_hand_label.visible = false
	crab_hand_label.visible = false
	message_label.text = "What will Octo do?"
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
	_animate_hp_bar(crab_hp_bar, crab_hp)
	_show_floating_damage(crab_damage_label, amount)


func apply_damage_to_player(amount: int) -> void:
	octo_hp = maxi(0, octo_hp - amount)
	update_ui()
	_animate_hp_bar(octo_hp_bar, octo_hp)
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
	message_label.text = "Victory!"
	update_ui()

	_award_victory_shells()
	victory_panel.visible = true


## Awards the victory shell reward exactly once per battle, guarded by
## `victory_reward_given` so repeated button presses on the victory panel
## can never double (or triple) award shells. SaveManager is the single
## authoritative source of truth for the player's shell total.
func _award_victory_shells() -> void:
	if victory_reward_given:
		return
	victory_reward_given = true

	shells_earned_label.text = "+%d Shells" % VICTORY_SHELLS
	SaveManager.add_shells(VICTORY_SHELLS)


func show_defeat() -> void:
	state = BattleState.DEFEAT
	message_label.text = "Defeat..."
	update_ui()
	defeat_panel.visible = true


func restart_battle() -> void:
	start_battle()


func _on_try_again_pressed() -> void:
	restart_battle()


func _on_return_home_pressed() -> void:
	exiting_scene = true
	SceneManager.go_to_main_menu()
