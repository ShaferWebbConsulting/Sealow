extends Control

const DiceRules = preload("res://scripts/battle/dice_rules.gd")
const PlayerDataScript = preload("res://scripts/player/player_data.gd")
const ItemDataScript = preload("res://scripts/items/item_data.gd")
const ItemEffectsScript = preload("res://scripts/items/item_effects.gd")

const PLAYER_MAX_HP: int = 12
const CRAB_MAX_HP: int = 10
const PLAYER_DICE_COUNT: int = 3
const CRAB_DICE_COUNT: int = 3
const VICTORY_SHELLS: int = 10
const HP_TWEEN_DURATION: float = 0.3
const DICE_ROLL_DURATION: float = 1.4
const MAX_LOG_ENTRIES_SHOWN: int = 5

## Only BattleState.PLAYER_TURN allows the Roll/Item buttons to be pressed.
## Every other state means a turn is currently animating/resolving.
enum BattleState {
	PLAYER_TURN,
	PLAYER_ROLLING,
	ENEMY_ROLLING,
	RESOLVING_ROUND,
	VICTORY,
	DEFEAT,
	DRAW,
}

var state: BattleState = BattleState.PLAYER_TURN
var player_hp: int = PLAYER_MAX_HP
var crab_hp: int = CRAB_MAX_HP
var exiting_scene: bool = false
var round_number: int = 0

## Structured round-by-round history, kept even after old entries scroll out
## of view, so it can later be reused for a match summary screen.
var battle_log: Array[Dictionary] = []

## Item battle-state flags. Kept isolated here and only ever mutated via
## ItemEffects helpers so the "if would lose, become a draw" / "+2 damage
## next hit" rules aren't scattered through the round-resolution logic.
var trident_armed: bool = false
var shield_armed: bool = false

## Guards against awarding shells more than once for the same victory, even
## if the victory panel's button is pressed repeatedly.
var victory_reward_given: bool = false

## Tracks the currently running HP bar tween per ProgressBar so a rapid
## sequence of damage events never animates the same bar with overlapping
## tweens (which would cause the fill to jitter/snap).
var _hp_bar_tweens: Dictionary = {}

var player_character_type: String = "octopus"

@onready var status_label: Label = %StatusLabel
@onready var octo_hp_label: Label = %OctoHpLabel
@onready var crab_hp_label: Label = %CrabHpLabel
@onready var octo_hp_bar: ProgressBar = %OctoHpBar
@onready var crab_hp_bar: ProgressBar = %CrabHpBar
@onready var roll_button: Button = %RollButton
@onready var item_button: Button = %ItemButton
@onready var run_button: Button = %RunButton
@onready var rules_button: Button = %RulesButton

@onready var player_dice_row: HBoxContainer = %PlayerDiceRow
@onready var crab_dice_row: HBoxContainer = %EnemyDiceRow
@onready var player_dice: Array[Dice] = [%PlayerDie1, %PlayerDie2, %PlayerDie3]
@onready var crab_dice: Array[Dice] = [%EnemyDie1, %EnemyDie2, %EnemyDie3]

@onready var log_scroll: ScrollContainer = %LogScroll
@onready var log_list: VBoxContainer = %LogList

@onready var crab_damage_label: Label = %CrabDamageLabel
@onready var octo_damage_label: Label = %OctoDamageLabel

@onready var player_name_label: Label = %OctoName
@onready var player_sprite_label: Label = %PlayerSprite
@onready var player_body_tint: Panel = %PlayerBodyTint

@onready var victory_panel: Control = %VictoryPanel
@onready var shells_earned_label: Label = %ShellsEarnedLabel
@onready var victory_return_button: Button = %VictoryReturnButton

@onready var defeat_panel: Control = %DefeatPanel
@onready var defeat_retry_button: Button = %DefeatRetryButton
@onready var defeat_return_button: Button = %DefeatReturnButton

@onready var draw_panel: Control = %DrawPanel
@onready var draw_return_button: Button = %DrawReturnButton

@onready var run_confirm_panel: Control = %RunConfirmPanel
@onready var stay_button: Button = %StayButton
@onready var confirm_run_button: Button = %ConfirmRunButton

@onready var rules_panel: Control = %RulesPanel
@onready var rules_close_button: Button = %RulesCloseButton

@onready var item_popup: ItemPopup = %ItemPopup


func _ready() -> void:
	roll_button.pressed.connect(_on_roll_pressed)
	item_button.pressed.connect(_on_item_pressed)
	run_button.pressed.connect(_on_run_pressed)
	stay_button.pressed.connect(_on_stay_pressed)
	confirm_run_button.pressed.connect(_on_confirm_run_pressed)
	victory_return_button.pressed.connect(_on_return_home_pressed)
	defeat_return_button.pressed.connect(_on_return_home_pressed)
	defeat_retry_button.pressed.connect(_on_try_again_pressed)
	draw_return_button.pressed.connect(_on_return_home_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	rules_close_button.pressed.connect(_on_rules_close_pressed)
	item_popup.item_used.connect(_on_item_used)

	_setup_player_character()
	start_battle()


func _exit_tree() -> void:
	exiting_scene = true


## Applies the player's saved creature choice to the name/sprite/HP-bar
## labels and tints the body-preview panel with their chosen color. The
## emoji glyph itself is never tinted (see PlayerData.CHARACTER_COLORS doc).
func _setup_player_character() -> void:
	player_character_type = SaveManager.get_character_type()
	player_sprite_label.text = PlayerDataScript.get_emoji(player_character_type)
	player_name_label.text = "%s %s" % [
		PlayerDataScript.get_emoji(player_character_type),
		PlayerDataScript.get_display_name(player_character_type).to_upper(),
	]

	var tint_style: StyleBoxFlat = StyleBoxFlat.new()
	tint_style.bg_color = PlayerDataScript.get_color(SaveManager.get_character_color())
	tint_style.bg_color.a = 0.22
	tint_style.set_corner_radius_all(400)
	player_body_tint.add_theme_stylebox_override("panel", tint_style)


func start_battle() -> void:
	state = BattleState.PLAYER_TURN
	player_hp = PLAYER_MAX_HP
	crab_hp = CRAB_MAX_HP
	victory_reward_given = false
	round_number = 0
	battle_log.clear()
	trident_armed = false
	shield_armed = false

	victory_panel.visible = false
	defeat_panel.visible = false
	draw_panel.visible = false
	rules_panel.visible = false
	run_confirm_panel.visible = false
	crab_damage_label.visible = false
	octo_damage_label.visible = false
	player_dice_row.visible = false
	crab_dice_row.visible = false

	for die in player_dice:
		die.set_value(1)
	for die in crab_dice:
		die.set_value(1)

	for child in log_list.get_children():
		child.queue_free()

	octo_hp_bar.max_value = PLAYER_MAX_HP
	crab_hp_bar.max_value = CRAB_MAX_HP
	octo_hp_bar.value = PLAYER_MAX_HP
	crab_hp_bar.value = CRAB_MAX_HP

	status_label.text = "Tap ROLL to begin"
	update_ui()


func update_ui() -> void:
	octo_hp_label.text = "HP %d / %d" % [player_hp, PLAYER_MAX_HP]
	crab_hp_label.text = "HP %d / %d" % [crab_hp, CRAB_MAX_HP]
	var in_player_turn: bool = state == BattleState.PLAYER_TURN
	roll_button.disabled = not in_player_turn
	roll_button.visible = state != BattleState.VICTORY and state != BattleState.DEFEAT and state != BattleState.DRAW
	run_button.disabled = not in_player_turn
	item_button.disabled = not in_player_turn


## Animates a health bar's ProgressBar value toward `new_value` rather than
## snapping instantly, so HP loss/gain reads as a clear, gentle visual change.
## Kills any tween already animating this bar first so rapid successive
## damage/heal events can never leave overlapping tweens fighting over the
## value.
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


## ------------------------------------------------------------------
## Items
## ------------------------------------------------------------------

func _on_item_pressed() -> void:
	if state != BattleState.PLAYER_TURN:
		return

	var disabled_reasons: Dictionary = {}
	if player_hp >= PLAYER_MAX_HP:
		disabled_reasons["mermaid_scale"] = "HP FULL"
	if trident_armed:
		disabled_reasons["trident"] = "ALREADY ARMED"
	if shield_armed:
		disabled_reasons["turtle_shield"] = "ALREADY ARMED"

	item_popup.open(SaveManager.data.get("inventory", {}), disabled_reasons)


func _on_item_used(item_key: String) -> void:
	match item_key:
		"mermaid_scale":
			_use_mermaid_scale()
		"trident":
			_use_trident()
		"turtle_shield":
			_use_turtle_shield()
	item_popup.close()


func _use_mermaid_scale() -> void:
	if player_hp >= PLAYER_MAX_HP:
		return
	if not SaveManager.consume_item("mermaid_scale"):
		return

	var healed_hp: int = ItemEffectsScript.apply_heal(player_hp, PLAYER_MAX_HP)
	var healed_amount: int = healed_hp - player_hp
	player_hp = healed_hp
	_animate_hp_bar(octo_hp_bar, player_hp)
	update_ui()
	_log_system_note("🧜 Mermaid Scale used — healed %d HP." % healed_amount)


func _use_trident() -> void:
	if trident_armed:
		return
	if not SaveManager.consume_item("trident"):
		return
	trident_armed = true
	_log_system_note("🔱 Trident armed — next hit deals +%d damage." % ItemEffectsScript.TRIDENT_BONUS_DAMAGE)


func _use_turtle_shield() -> void:
	if shield_armed:
		return
	if not SaveManager.consume_item("turtle_shield"):
		return
	shield_armed = true
	_log_system_note("🐢 Turtle Shield armed — a defeat will become a draw.")


## Appends a short, single-line note to the battle log (used for item
## activations) rather than the full round-summary format.
func _log_system_note(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.8, 1.0))
	log_list.add_child(label)
	_trim_log_display()
	_scroll_log_to_bottom()


## ------------------------------------------------------------------
## Round flow
## ------------------------------------------------------------------

## Runs one full SeaLow round: player rolls, Crab rolls, hands are compared,
## and the loser takes damage. Guards against overlapping/duplicate rounds
## by immediately leaving PLAYER_TURN before any awaits happen.
func perform_round() -> void:
	state = BattleState.PLAYER_ROLLING
	crab_dice_row.visible = false
	status_label.text = "Rolling..."
	update_ui()

	var player_hand: DiceRules.DiceHand = await _roll_and_animate(player_dice_row, player_dice, PLAYER_DICE_COUNT)
	if exiting_scene or not is_inside_tree():
		return

	await get_tree().create_timer(0.3).timeout
	if exiting_scene or not is_inside_tree():
		return

	state = BattleState.ENEMY_ROLLING
	update_ui()

	var crab_hand: DiceRules.DiceHand = await _roll_and_animate(crab_dice_row, crab_dice, CRAB_DICE_COUNT)
	if exiting_scene or not is_inside_tree():
		return

	state = BattleState.RESOLVING_ROUND
	update_ui()

	await get_tree().create_timer(0.3).timeout
	if exiting_scene or not is_inside_tree():
		return

	_resolve_round(player_hand, crab_hand)


## Rolls dice (auto-rerolling NO_POINT hands) and plays the satisfying
## multi-stage roll animation for the whole row in parallel. Returns the
## final scoring DiceHand.
func _roll_and_animate(row: HBoxContainer, dice_nodes: Array[Dice], count: int) -> DiceRules.DiceHand:
	row.visible = true
	var attempts: int = 0
	var raw_dice: Array[int] = DiceRules.roll_dice(count)
	var hand: DiceRules.DiceHand = DiceRules.evaluate_hand(raw_dice)

	await _animate_dice_row(dice_nodes, raw_dice)
	if exiting_scene or not is_inside_tree():
		return hand

	while hand.hand_type == DiceRules.HandType.NO_POINT and attempts < DiceRules.MAX_REROLLS:
		raw_dice = DiceRules.roll_dice(count)
		hand = DiceRules.evaluate_hand(raw_dice)
		await _animate_dice_row(dice_nodes, raw_dice, 0.8)
		if exiting_scene or not is_inside_tree():
			return hand
		attempts += 1

	if hand.hand_type == DiceRules.HandType.NO_POINT:
		hand = DiceRules.fallback_hand(hand)

	return hand


## Plays each die's roll animation in parallel (fire-and-forget, then awaits
## every die's `roll_finished` signal) so a row of 3 dice settles together
## rather than one at a time.
func _animate_dice_row(dice_nodes: Array[Dice], results: Array[int], duration: float = DICE_ROLL_DURATION) -> void:
	for i in dice_nodes.size():
		dice_nodes[i].play_roll_animation(results[i], duration)
	for die in dice_nodes:
		await die.roll_finished


func _resolve_round(player_hand: DiceRules.DiceHand, crab_hand: DiceRules.DiceHand) -> void:
	# Defensive guard: _roll_and_animate can return early with an unresolved
	# NO_POINT hand if the scene is exiting mid-round. Never score that case.
	if player_hand.hand_type == DiceRules.HandType.NO_POINT or crab_hand.hand_type == DiceRules.HandType.NO_POINT:
		return

	round_number += 1
	var result: int = DiceRules.compare_hands(player_hand, crab_hand)

	if result == 0:
		status_label.text = "Round %d: TIE — no damage." % round_number
		_append_round_log(round_number, player_hand, 0, crab_hand, 0, true)
		await get_tree().create_timer(0.9).timeout
		if exiting_scene or not is_inside_tree():
			return
		_start_next_round()
		return

	if result == 1:
		var base_damage: int = DiceRules.calculate_damage(player_hand, crab_hand)
		var bonus_result: Dictionary = ItemEffectsScript.apply_damage_bonus(base_damage, trident_armed)
		var damage: int = bonus_result["damage"]
		if bonus_result["consumed"]:
			trident_armed = false

		apply_damage_to_crab(damage)
		status_label.text = "Round %d: You dealt %d damage!" % [round_number, damage]
		_append_round_log(round_number, player_hand, damage, crab_hand, 0, false, bonus_result["consumed"])

		if crab_hp <= 0:
			await get_tree().create_timer(0.8).timeout
			if exiting_scene or not is_inside_tree():
				return
			show_victory()
			return
	else:
		var damage: int = DiceRules.calculate_damage(crab_hand, player_hand)
		apply_damage_to_player(damage)
		status_label.text = "Round %d: Crab dealt %d damage!" % [round_number, damage]
		_append_round_log(round_number, player_hand, 0, crab_hand, damage, false)

		if player_hp <= 0:
			await get_tree().create_timer(0.8).timeout
			if exiting_scene or not is_inside_tree():
				return
			if ItemEffectsScript.resolve_defeat(shield_armed):
				shield_armed = false
				show_draw()
			else:
				show_defeat()
			return

	await get_tree().create_timer(0.9).timeout
	if exiting_scene or not is_inside_tree():
		return
	_start_next_round()


## ------------------------------------------------------------------
## Battle log
## ------------------------------------------------------------------

## Records a structured round entry (kept forever in `battle_log` for future
## match-summary use) and appends a compact display line to the visible log.
func _append_round_log(
	p_round_number: int,
	player_hand: DiceRules.DiceHand,
	player_damage: int,
	crab_hand: DiceRules.DiceHand,
	crab_damage: int,
	is_tie: bool,
	trident_used: bool = false
) -> void:
	var entry: Dictionary = {
		"round": p_round_number,
		"player_dice": player_hand.dice_values,
		"player_damage": player_damage,
		"crab_dice": crab_hand.dice_values,
		"crab_damage": crab_damage,
		"is_tie": is_tie,
		"trident_used": trident_used,
	}
	battle_log.append(entry)
	_render_log_entry(entry)


func _render_log_entry(entry: Dictionary) -> void:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)

	var player_emoji: String = PlayerDataScript.get_emoji(player_character_type)
	var player_dice_text: String = _format_dice_values(entry["player_dice"])
	var crab_dice_text: String = _format_dice_values(entry["crab_dice"])

	if entry["is_tie"]:
		label.text = "Round %d\n%s %s  🦀 %s  → TIE" % [
			entry["round"], player_emoji, player_dice_text, crab_dice_text,
		]
	elif entry["player_damage"] > 0:
		var trident_suffix: String = " 🔱" if entry["trident_used"] else ""
		label.text = "Round %d\n%s %s → %d dmg%s\n🦀 %s → 0 dmg" % [
			entry["round"], player_emoji, player_dice_text, entry["player_damage"], trident_suffix, crab_dice_text,
		]
	else:
		label.text = "Round %d\n%s %s → 0 dmg\n🦀 %s → %d dmg" % [
			entry["round"], player_emoji, player_dice_text, crab_dice_text, entry["crab_damage"],
		]

	log_list.add_child(label)
	_trim_log_display()
	_scroll_log_to_bottom()


func _format_dice_values(values: Array[int]) -> String:
	var parts: PackedStringArray = []
	for value in values:
		parts.append(str(value))
	return "(%s)" % ",".join(parts)


## Keeps only the most recent MAX_LOG_ENTRIES_SHOWN entries visible so the
## log stays compact on mobile; older entries remain in `battle_log`.
func _trim_log_display() -> void:
	while log_list.get_child_count() > MAX_LOG_ENTRIES_SHOWN:
		var oldest: Node = log_list.get_child(0)
		log_list.remove_child(oldest)
		oldest.queue_free()


func _scroll_log_to_bottom() -> void:
	await get_tree().process_frame
	if is_inside_tree():
		log_scroll.scroll_vertical = int(log_scroll.get_v_scroll_bar().max_value)


func _start_next_round() -> void:
	state = BattleState.PLAYER_TURN
	player_dice_row.visible = false
	crab_dice_row.visible = false
	status_label.text = "Tap ROLL to begin"
	update_ui()


func apply_damage_to_crab(amount: int) -> void:
	crab_hp = maxi(0, crab_hp - amount)
	update_ui()
	_animate_hp_bar(crab_hp_bar, crab_hp)
	_show_floating_damage(crab_damage_label, amount)


func apply_damage_to_player(amount: int) -> void:
	player_hp = maxi(0, player_hp - amount)
	update_ui()
	_animate_hp_bar(octo_hp_bar, player_hp)
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
	status_label.text = "Victory!"
	update_ui()

	_award_victory_shells()
	SaveManager.register_battle_win()
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
	status_label.text = "Defeat..."
	update_ui()
	defeat_panel.visible = true


## Turtle Shield triggered: the opponent is NOT counted as defeated, the
## player receives no victory reward, and the player simply returns home.
func show_draw() -> void:
	state = BattleState.DRAW
	status_label.text = "Draw."
	update_ui()
	draw_panel.visible = true


func restart_battle() -> void:
	start_battle()


func _on_try_again_pressed() -> void:
	restart_battle()


func _on_return_home_pressed() -> void:
	exiting_scene = true
	SceneManager.go_to_main_menu()
