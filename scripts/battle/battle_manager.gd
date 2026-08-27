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

const SEAWEED_ITEM_KEY: String = "circle_of_seaweed"

## Only the 3 most recent rounds are shown in the compact Recent Rounds log
## (newest first); the full history stays in `battle_log`.
const MAX_LOG_ENTRIES_SHOWN: int = 3

## Attack lunge/shake animation timing.
const ATTACK_LUNGE_DURATION: float = 0.18
const ATTACK_SHAKE_DURATION: float = 0.22
const ATTACK_RETURN_DURATION: float = 0.18


## Only BattleState.PLAYER_TURN allows normal player interaction.
enum BattleState {
	PLAYER_TURN,
	PLAYER_ROLLING,
	ENEMY_ROLLING,
	RESOLVING_ROUND,
	VICTORY,
	DEFEAT,
	DRAW,
	RETRY_PROMPT,
}


var state: BattleState = BattleState.PLAYER_TURN

var player_hp: int = PLAYER_MAX_HP
var crab_hp: int = CRAB_MAX_HP

var exiting_scene: bool = false
var round_number: int = 0


## Structured round-by-round history.
var battle_log: Array[Dictionary] = []


## Temporary combat-item states.
var trident_armed: bool = false
var shield_armed: bool = false


## Guards against awarding shells more than once.
var victory_reward_given: bool = false


## Tracks active HP tweens.
var _hp_bar_tweens: Dictionary = {}


var player_character_type: String = "octopus"


## Original creature positions for attack animations.
var _player_sprite_home: Vector2 = Vector2.ZERO
var _enemy_sprite_home: Vector2 = Vector2.ZERO


@onready var turn_banner: Label = %TurnBanner

@onready var octo_hp_label: Label = %OctoHpLabel
@onready var crab_hp_label: Label = %CrabHpLabel

@onready var octo_hp_bar: ProgressBar = %OctoHpBar
@onready var crab_hp_bar: ProgressBar = %CrabHpBar

@onready var roll_button: Button = %RollButton
@onready var item_button: Button = %ItemButton
@onready var run_button: Button = %RunButton
@onready var rules_button: Button = %RulesButton


@onready var player_roll_label: Label = %PlayerRollLabel
@onready var enemy_roll_label: Label = %EnemyRollLabel

@onready var player_dice_row: HBoxContainer = %PlayerDiceRow
@onready var crab_dice_row: HBoxContainer = %EnemyDiceRow

@onready var player_dice: Array[Dice] = [
	%PlayerDie1,
	%PlayerDie2,
	%PlayerDie3,
]

@onready var crab_dice: Array[Dice] = [
	%EnemyDie1,
	%EnemyDie2,
	%EnemyDie3,
]


@onready var log_scroll: ScrollContainer = %LogScroll
@onready var log_list: VBoxContainer = %LogList


@onready var crab_damage_label: Label = %CrabDamageLabel
@onready var octo_damage_label: Label = %OctoDamageLabel


@onready var player_name_label: Label = %OctoName
@onready var player_sprite_label: Label = %PlayerSprite
@onready var enemy_sprite_label: Label = %EnemySprite
@onready var player_color_dot: Panel = %PlayerColorDot


@onready var victory_panel: Control = %VictoryPanel
@onready var shells_earned_label: Label = %ShellsEarnedLabel
@onready var victory_return_button: Button = %VictoryReturnButton


@onready var defeat_panel: Control = %DefeatPanel
@onready var defeat_retry_button: Button = %DefeatRetryButton
@onready var defeat_return_button: Button = %DefeatReturnButton


@onready var draw_panel: Control = %DrawPanel
@onready var draw_return_button: Button = %DrawReturnButton


## Circle of Seaweed retry UI.
@onready var seaweed_retry_panel: Control = %SeaweedRetryPanel
@onready var seaweed_owned_label: Label = %SeaweedOwnedLabel
@onready var use_seaweed_button: Button = %UseSeaweedButton
@onready var decline_seaweed_button: Button = %DeclineSeaweedButton


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

	# Circle of Seaweed.
	use_seaweed_button.pressed.connect(_on_use_seaweed_pressed)
	decline_seaweed_button.pressed.connect(_on_decline_seaweed_pressed)

	rules_button.pressed.connect(_on_rules_pressed)
	rules_close_button.pressed.connect(_on_rules_close_pressed)

	item_popup.item_used.connect(_on_item_used)

	_setup_player_character()
	start_battle()

	# Capture sprite home positions after layout has finished.
	await get_tree().process_frame

	_player_sprite_home = player_sprite_label.position
	_enemy_sprite_home = enemy_sprite_label.position


func _exit_tree() -> void:
	exiting_scene = true


## Applies saved player creature/color/name information.
func _setup_player_character() -> void:
	player_character_type = SaveManager.get_character_type()

	player_sprite_label.text = PlayerDataScript.get_emoji(
		player_character_type
	)

	var player_name: String = SaveManager.get_player_name()

	player_name_label.text = "%s %s" % [
		PlayerDataScript.get_emoji(player_character_type),
		player_name.to_upper(),
	]

	var dot_style: StyleBoxFlat = StyleBoxFlat.new()

	dot_style.bg_color = PlayerDataScript.get_color(
		SaveManager.get_character_color()
	)

	dot_style.set_corner_radius_all(20)

	player_color_dot.add_theme_stylebox_override(
		"panel",
		dot_style
	)


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

	# Seaweed retry prompt must always begin hidden.
	seaweed_retry_panel.visible = false

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

	turn_banner.text = "Tap ROLL to begin"

	update_ui()


func update_ui() -> void:
	octo_hp_label.text = "HP %d / %d" % [
		player_hp,
		PLAYER_MAX_HP,
	]

	crab_hp_label.text = "HP %d / %d" % [
		crab_hp,
		CRAB_MAX_HP,
	]

	var in_player_turn: bool = (
		state == BattleState.PLAYER_TURN
	)

	roll_button.disabled = not in_player_turn
	item_button.disabled = not in_player_turn
	run_button.disabled = not in_player_turn

	roll_button.visible = (
		state != BattleState.VICTORY
		and state != BattleState.DEFEAT
		and state != BattleState.DRAW
		and state != BattleState.RETRY_PROMPT
	)


func _animate_hp_bar(
	bar: ProgressBar,
	new_value: int
) -> void:
	var existing_tween: Tween = _hp_bar_tweens.get(bar)

	if (
		existing_tween != null
		and existing_tween.is_valid()
	):
		existing_tween.kill()

	var tween: Tween = create_tween()

	tween.tween_property(
		bar,
		"value",
		float(new_value),
		HP_TWEEN_DURATION
	)

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

	## Circle of Seaweed is NOT manually activated.
	## It is automatically offered when the player is defeated.
	disabled_reasons["circle_of_seaweed"] = "AUTO ON DEFEAT"

	item_popup.open(
		SaveManager.get_inventory(),
		disabled_reasons
	)


func _on_item_used(item_key: String) -> void:
	match item_key:
		"mermaid_scale":
			_use_mermaid_scale()

		"trident":
			_use_trident()

		"turtle_shield":
			_use_turtle_shield()

		"circle_of_seaweed":
			# This item is intentionally automatic.
			# It cannot be consumed from the normal ITEM menu.
			pass

	item_popup.close()


func _use_mermaid_scale() -> void:
	if player_hp >= PLAYER_MAX_HP:
		return

	if not SaveManager.consume_item("mermaid_scale"):
		return

	var healed_hp: int = ItemEffectsScript.apply_heal(
		player_hp,
		PLAYER_MAX_HP
	)

	var healed_amount: int = healed_hp - player_hp

	player_hp = healed_hp

	_animate_hp_bar(
		octo_hp_bar,
		player_hp
	)

	update_ui()

	_log_system_note(
		"🧜 Mermaid Scale used — healed %d HP."
		% healed_amount
	)


func _use_trident() -> void:
	if trident_armed:
		return

	if not SaveManager.consume_item("trident"):
		return

	trident_armed = true

	_log_system_note(
		"🔱 Trident armed — next hit deals +%d damage."
		% ItemEffectsScript.TRIDENT_BONUS_DAMAGE
	)


func _use_turtle_shield() -> void:
	if shield_armed:
		return

	if not SaveManager.consume_item("turtle_shield"):
		return

	shield_armed = true

	_log_system_note(
		"🐢 Turtle Shield armed — a defeat will become a draw."
	)


func _log_system_note(text: String) -> void:
	var label: Label = Label.new()

	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	label.add_theme_font_size_override(
		"font_size",
		14
	)

	label.add_theme_color_override(
		"font_color",
		Color(0.7, 0.85, 0.8, 1.0)
	)

	log_list.add_child(label)
	log_list.move_child(label, 0)

	_trim_log_display()


## ------------------------------------------------------------------
## Round flow
## ------------------------------------------------------------------

func perform_round() -> void:
	state = BattleState.PLAYER_ROLLING

	crab_dice_row.visible = false

	_set_turn_banner(
		"🐙 %s IS ROLLING"
		% SaveManager.get_player_name().to_upper()
	)

	update_ui()

	var player_hand: DiceRules.DiceHand = await _roll_and_animate(
		player_dice_row,
		player_dice,
		PLAYER_DICE_COUNT
	)

	if exiting_scene or not is_inside_tree():
		return

	await get_tree().create_timer(0.5).timeout

	if exiting_scene or not is_inside_tree():
		return

	state = BattleState.ENEMY_ROLLING

	_set_turn_banner(
		"🦀 CRAB IS ROLLING"
	)

	update_ui()

	var crab_hand: DiceRules.DiceHand = await _roll_and_animate(
		crab_dice_row,
		crab_dice,
		CRAB_DICE_COUNT
	)

	if exiting_scene or not is_inside_tree():
		return

	state = BattleState.RESOLVING_ROUND

	update_ui()

	await get_tree().create_timer(.5).timeout

	if exiting_scene or not is_inside_tree():
		return

	await _resolve_round(
		player_hand,
		crab_hand
	)


func _set_turn_banner(text: String) -> void:
	turn_banner.text = text


func _roll_and_animate(
	row: HBoxContainer,
	dice_nodes: Array[Dice],
	count: int
) -> DiceRules.DiceHand:
	row.visible = true

	var attempts: int = 0

	var raw_dice: Array[int] = DiceRules.roll_dice(
		count
	)

	var hand: DiceRules.DiceHand = DiceRules.evaluate_hand(
		raw_dice
	)

	await _animate_dice_row(
		dice_nodes,
		raw_dice
	)

	if exiting_scene or not is_inside_tree():
		return hand

	while (
		hand.hand_type == DiceRules.HandType.NO_POINT
		and attempts < DiceRules.MAX_REROLLS
	):
		raw_dice = DiceRules.roll_dice(
			count
		)

		hand = DiceRules.evaluate_hand(
			raw_dice
		)

		await _animate_dice_row(
			dice_nodes,
			raw_dice,
			0.8
		)

		if exiting_scene or not is_inside_tree():
			return hand

		attempts += 1

	if hand.hand_type == DiceRules.HandType.NO_POINT:
		hand = DiceRules.fallback_hand(
			hand
		)

	return hand


func _animate_dice_row(
	dice_nodes: Array[Dice],
	results: Array[int],
	duration: float = DICE_ROLL_DURATION
) -> void:
	var remaining: Array[int] = [
		dice_nodes.size()
	]

	var on_die_done := func(
		_final_value: int
	) -> void:
		remaining[0] -= 1

	for i in dice_nodes.size():
		dice_nodes[i].roll_finished.connect(
			on_die_done,
			CONNECT_ONE_SHOT
		)

		dice_nodes[i].play_roll_animation(
			results[i],
			duration
		)

	while remaining[0] > 0:
		await get_tree().process_frame

		if exiting_scene or not is_inside_tree():
			return


func _resolve_round(
	player_hand: DiceRules.DiceHand,
	crab_hand: DiceRules.DiceHand
) -> void:
	if (
		player_hand.hand_type == DiceRules.HandType.NO_POINT
		or crab_hand.hand_type == DiceRules.HandType.NO_POINT
	):
		return

	round_number += 1

	var result: int = DiceRules.compare_hands(
		player_hand,
		crab_hand
	)

	if result == 0:
		_set_turn_banner(
			"TIE — ROLL AGAIN"
		)

		_append_round_log(
			round_number,
			true,
			false,
			"",
			0,
			false
		)

		await get_tree().create_timer(
			0.9
		).timeout

		if exiting_scene or not is_inside_tree():
			return

		_start_next_round()

		return

	var player_won: bool = result == 1

	var winner_hand: DiceRules.DiceHand = (
		player_hand
		if player_won
		else crab_hand
	)

	var loser_hand: DiceRules.DiceHand = (
		crab_hand
		if player_won
		else player_hand
	)

	var result_type_label: String = DiceRules.result_label(
		winner_hand,
		loser_hand
	)

	var base_damage: int = DiceRules.damage_for_result(
		winner_hand,
		loser_hand
	)

	var damage: int = base_damage
	var trident_used: bool = false

	if player_won:
		var bonus_result: Dictionary = ItemEffectsScript.apply_damage_bonus(
			base_damage,
			trident_armed
		)

		damage = int(
			bonus_result["damage"]
		)

		trident_used = bool(
			bonus_result["consumed"]
		)

		if trident_used:
			trident_armed = false

	var trident_tag: String = (
		" 🔱"
		if trident_used
		else ""
	)

	_set_turn_banner(
		"%s!\n%s\n-%d HP%s"
		% [
			"YOU WIN" if player_won else "CRAB WINS",
			result_type_label,
			damage,
			trident_tag,
		]
	)

	_append_round_log(
		round_number,
		false,
		player_won,
		result_type_label,
		damage,
		trident_used
	)

	await get_tree().create_timer(
		0.8
	).timeout

	if exiting_scene or not is_inside_tree():
		return


	if player_won:
		await _play_attack_animation(
			player_sprite_label,
			enemy_sprite_label,
			_player_sprite_home,
			_enemy_sprite_home
		)

		if exiting_scene or not is_inside_tree():
			return

		apply_damage_to_crab(
			damage
		)

		if crab_hp <= 0:
			await get_tree().create_timer(
				0.6
			).timeout

			if exiting_scene or not is_inside_tree():
				return

			show_victory()

			return

	else:
		await _play_attack_animation(
			enemy_sprite_label,
			player_sprite_label,
			_enemy_sprite_home,
			_player_sprite_home
		)

		if exiting_scene or not is_inside_tree():
			return

		apply_damage_to_player(
			damage
		)

		if player_hp <= 0:
			await get_tree().create_timer(
				0.6
			).timeout

			if exiting_scene or not is_inside_tree():
				return

			_handle_player_defeat()

			return


	await get_tree().create_timer(
		5
	).timeout

	if exiting_scene or not is_inside_tree():
		return

	_start_next_round()


## ------------------------------------------------------------------
## Defeat / protection / retry resolution
## ------------------------------------------------------------------

## Loss priority:
##
## 1. Armed Turtle Shield -> DRAW
## 2. Circle of Seaweed available -> offer RETRY
## 3. Otherwise -> normal DEFEAT
func _handle_player_defeat() -> void:
	## Turtle Shield gets first priority.
	if ItemEffectsScript.resolve_defeat(
		shield_armed
	):
		shield_armed = false
		show_draw()
		return

	var seaweed_count: int = SaveManager.get_item_count(
		SEAWEED_ITEM_KEY
	)

	## Seaweed is only offered if the player actually owns one.
	if ItemEffectsScript.resolve_retry(
		seaweed_count > 0
	):
		_show_seaweed_retry(
			seaweed_count
		)
		return

	show_defeat()


func _show_seaweed_retry(
	count: int
) -> void:
	state = BattleState.RETRY_PROMPT

	turn_banner.text = "THE SEAWEED CALLS..."

	seaweed_owned_label.text = (
		"Owned: %d"
		% count
	)

	seaweed_retry_panel.visible = true

	update_ui()


## Player chooses to consume one Circle of Seaweed and restart this exact
## battle from full HP.
func _on_use_seaweed_pressed() -> void:
	if state != BattleState.RETRY_PROMPT:
		return

	var consumed: bool = SaveManager.consume_item(
		SEAWEED_ITEM_KEY
	)

	## Defensive fallback: if inventory somehow changed before the player
	## pressed the button, simply continue to normal defeat.
	if not consumed:
		seaweed_retry_panel.visible = false
		show_defeat()
		return

	seaweed_retry_panel.visible = false

	restart_battle()


## Player keeps the Seaweed and accepts the normal defeat instead.
func _on_decline_seaweed_pressed() -> void:
	if state != BattleState.RETRY_PROMPT:
		return

	seaweed_retry_panel.visible = false

	show_defeat()


## ------------------------------------------------------------------
## Attack animation
## ------------------------------------------------------------------

func _play_attack_animation(
	attacker: Label,
	defender: Label,
	attacker_home: Vector2,
	defender_home: Vector2
) -> void:
	if attacker_home == Vector2.ZERO:
		attacker_home = attacker.position

	if defender_home == Vector2.ZERO:
		defender_home = defender.position

	var toward: Vector2 = (
		defender_home - attacker_home
	)

	var lunge_offset: Vector2 = Vector2.ZERO

	if toward.length() > 0.0:
		lunge_offset = (
			toward.normalized()
			* minf(
				toward.length() * 0.35,
				60.0
			)
		)

	var lunge_tween: Tween = create_tween()

	lunge_tween.tween_property(
		attacker,
		"position",
		attacker_home + lunge_offset,
		ATTACK_LUNGE_DURATION
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	await lunge_tween.finished

	if exiting_scene or not is_inside_tree():
		return

	var shake_tween: Tween = create_tween()

	var shake_amount: float = 10.0

	shake_tween.tween_property(
		defender,
		"position:x",
		defender_home.x + shake_amount,
		ATTACK_SHAKE_DURATION * 0.25
	)

	shake_tween.tween_property(
		defender,
		"position:x",
		defender_home.x - shake_amount,
		ATTACK_SHAKE_DURATION * 0.25
	)

	shake_tween.tween_property(
		defender,
		"position:x",
		defender_home.x,
		ATTACK_SHAKE_DURATION * 0.5
	)

	await shake_tween.finished

	if exiting_scene or not is_inside_tree():
		return

	var return_tween: Tween = create_tween()

	return_tween.tween_property(
		attacker,
		"position",
		attacker_home,
		ATTACK_RETURN_DURATION
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	await return_tween.finished


## ------------------------------------------------------------------
## Battle log
## ------------------------------------------------------------------

func _append_round_log(
	p_round_number: int,
	is_tie: bool,
	player_won: bool,
	result_type_label: String,
	damage: int,
	trident_used: bool
) -> void:
	var entry: Dictionary = {
		"round": p_round_number,
		"is_tie": is_tie,
		"player_won": player_won,
		"result_type_label": result_type_label,
		"damage": damage,
		"trident_used": trident_used,
	}

	battle_log.append(
		entry
	)

	_render_log_entry(
		entry
	)


func _render_log_entry(
	entry: Dictionary
) -> void:
	var label: Label = Label.new()

	label.add_theme_font_size_override(
		"font_size",
		15
	)

	if entry["is_tie"]:
		label.text = (
			"R%d: 🤝 TIE · Roll again"
			% entry["round"]
		)

	else:
		var player_emoji: String = PlayerDataScript.get_emoji(
			player_character_type
		)

		var winner_emoji: String = (
			player_emoji
			if entry["player_won"]
			else "🦀"
		)

		var loser_name: String = (
			"Crab"
			if entry["player_won"]
			else SaveManager.get_player_name()
		)

		var trident_suffix: String = (
			" 🔱"
			if entry["trident_used"]
			else ""
		)

		label.text = (
			"R%d: %s won with %s%s   %s -%d HP"
			% [
				entry["round"],
				winner_emoji,
				entry["result_type_label"],
				trident_suffix,
				loser_name,
				entry["damage"],
			]
		)

	log_list.add_child(
		label
	)

	log_list.move_child(
		label,
		0
	)

	_trim_log_display()


func _trim_log_display() -> void:
	while (
		log_list.get_child_count()
		> MAX_LOG_ENTRIES_SHOWN
	):
		var oldest: Node = log_list.get_child(
			log_list.get_child_count() - 1
		)

		log_list.remove_child(
			oldest
		)

		oldest.queue_free()


func _start_next_round() -> void:
	state = BattleState.PLAYER_TURN

	player_dice_row.visible = false
	crab_dice_row.visible = false

	turn_banner.text = "Tap ROLL to begin"

	update_ui()


func apply_damage_to_crab(
	amount: int
) -> void:
	crab_hp = maxi(
		0,
		crab_hp - amount
	)

	update_ui()

	_animate_hp_bar(
		crab_hp_bar,
		crab_hp
	)

	_show_floating_damage(
		crab_damage_label,
		amount
	)


func apply_damage_to_player(
	amount: int
) -> void:
	player_hp = maxi(
		0,
		player_hp - amount
	)

	update_ui()

	_animate_hp_bar(
		octo_hp_bar,
		player_hp
	)

	_show_floating_damage(
		octo_damage_label,
		amount
	)


func _show_floating_damage(
	label: Label,
	amount: int
) -> void:
	label.text = "-%d" % amount

	label.visible = true
	label.modulate.a = 1.0
	label.position.y = 0.0

	var tween: Tween = create_tween()

	tween.tween_property(
		label,
		"position:y",
		-30.0,
		0.6
	)

	tween.parallel().tween_property(
		label,
		"modulate:a",
		0.0,
		0.6
	)

	tween.tween_callback(
		func() -> void:
			label.visible = false
	)


func show_victory() -> void:
	state = BattleState.VICTORY

	turn_banner.text = "VICTORY!"

	update_ui()

	_award_victory_shells()

	SaveManager.register_battle_win()

	victory_panel.visible = true


func _award_victory_shells() -> void:
	if victory_reward_given:
		return

	victory_reward_given = true

	shells_earned_label.text = (
		"+%d Shells"
		% VICTORY_SHELLS
	)

	SaveManager.add_shells(
		VICTORY_SHELLS
	)


func show_defeat() -> void:
	state = BattleState.DEFEAT

	turn_banner.text = "DEFEAT..."

	seaweed_retry_panel.visible = false

	update_ui()

	defeat_panel.visible = true


func show_draw() -> void:
	state = BattleState.DRAW

	turn_banner.text = "DRAW."

	seaweed_retry_panel.visible = false

	update_ui()

	draw_panel.visible = true


func restart_battle() -> void:
	start_battle()


func _on_try_again_pressed() -> void:
	restart_battle()


func _on_return_home_pressed() -> void:
	exiting_scene = true

	SceneManager.go_to_main_menu()
