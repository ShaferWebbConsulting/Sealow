extends RefCounted
## SeaLow / Cee-Lo inspired three-dice hand evaluation.
##
## This module is intentionally UI-agnostic: it only knows how to roll,
## sort, evaluate and compare dice hands. `battle_manager.gd` (or a future
## PvP battle controller) is responsible for animation, HP, and state.

## Ranking order matters: higher enum value == stronger hand category.
## NO_POINT is ranked below WASHED_OUT (rather than merely "not scoring") so
## that if an unresolved NO_POINT hand ever reached compare_hands (it never
## should, since callers must reroll until scoring), it would always lose
## rather than incorrectly beating the intentionally weakest scoring hand.
enum HandType {
	NO_POINT, ## Non-scoring roll. Should never survive to comparison; auto-rerolled.
	WASHED_OUT, ## 1-2-3, weakest scoring hand.
	POINT, ## Pair + unmatched die. pair_value holds the pair, point_value holds the unmatched die (1-6).
	TRIPLE, ## Three matching dice. point_value holds the triple's face value (1-6).
	TIDAL_ROLL, ## 4-5-6, strongest possible hand.
}

const MAX_REROLLS: int = 20

## Result of evaluating a single three-dice roll.
class DiceHand:
	var hand_type: int
	## For POINT hands, the value of the matching pair (1-6). Ranked before
	## point_value so e.g. PAIR 3 always beats PAIR 1 regardless of the
	## unmatched die. Unused (left at -1) for non-POINT hand types.
	var pair_value: int
	var point_value: int
	var dice_values: Array[int]
	var display_name: String

	func _init(p_hand_type: int, p_point_value: int, p_dice_values: Array[int], p_display_name: String, p_pair_value: int = -1) -> void:
		hand_type = p_hand_type
		pair_value = p_pair_value
		point_value = p_point_value
		dice_values = p_dice_values
		display_name = p_display_name


## Rolls `count` six-sided dice and returns the raw (unsorted) values.
static func roll_dice(count: int) -> Array[int]:
	var results: Array[int] = []
	for i in count:
		results.append(randi_range(1, 6))
	return results


## Evaluates three dice values into a DiceHand. Dice are sorted first so the
## caller never needs to think about original roll order.
static func evaluate_hand(dice: Array[int]) -> DiceHand:
	var sorted_dice: Array[int] = dice.duplicate()
	sorted_dice.sort()

	if sorted_dice == [4, 5, 6]:
		return DiceHand.new(HandType.TIDAL_ROLL, 7, sorted_dice, "TIDAL ROLL")

	if sorted_dice == [1, 2, 3]:
		return DiceHand.new(HandType.WASHED_OUT, 0, sorted_dice, "WASHED OUT")

	if sorted_dice[0] == sorted_dice[1] and sorted_dice[1] == sorted_dice[2]:
		var triple_value: int = sorted_dice[0]
		return DiceHand.new(HandType.TRIPLE, triple_value, sorted_dice, "TRIPLE %d" % triple_value)

	if sorted_dice[0] == sorted_dice[1]:
		var pair: int = sorted_dice[0]
		var point: int = sorted_dice[2]
		return DiceHand.new(HandType.POINT, point, sorted_dice, "PAIR %d • HIGH %d" % [pair, point], pair)

	if sorted_dice[1] == sorted_dice[2]:
		var pair_val: int = sorted_dice[1]
		var point_val: int = sorted_dice[0]
		return DiceHand.new(HandType.POINT, point_val, sorted_dice, "PAIR %d • HIGH %d" % [pair_val, point_val], pair_val)

	return DiceHand.new(HandType.NO_POINT, -1, sorted_dice, "NO POINT")


## Builds the safety-fallback hand used when MAX_REROLLS is exhausted without
## a scoring hand. Treats the highest die as a pseudo-pair value and the
## second-highest die as the point/tiebreaker, so the round can still resolve
## using the same pair-first comparison as a real POINT hand, and two
## fallback hands still tiebreak meaningfully. Should almost never be needed
## in practice.
static func fallback_hand(no_point_hand: DiceHand) -> DiceHand:
	var sorted_dice: Array[int] = no_point_hand.dice_values.duplicate()
	sorted_dice.sort()
	var highest: int = sorted_dice[2]
	var second_highest: int = sorted_dice[1]
	return DiceHand.new(HandType.POINT, second_highest, no_point_hand.dice_values, "PAIR %d • HIGH %d" % [highest, second_highest], highest)


## Compares two evaluated hands.
## Returns 1 if player_hand wins, -1 if enemy_hand wins, 0 on a tie.
static func compare_hands(player_hand: DiceHand, enemy_hand: DiceHand) -> int:
	if player_hand.hand_type != enemy_hand.hand_type:
		return 1 if player_hand.hand_type > enemy_hand.hand_type else -1

	# Pair hands must be ranked by pair value first, and only fall back to
	# the unmatched die (point_value) as a tiebreaker when both pairs match.
	if player_hand.hand_type == HandType.POINT:
		if player_hand.pair_value != enemy_hand.pair_value:
			return 1 if player_hand.pair_value > enemy_hand.pair_value else -1

	if player_hand.point_value != enemy_hand.point_value:
		return 1 if player_hand.point_value > enemy_hand.point_value else -1

	return 0


## Determines damage dealt by the winning hand. `loser_hand` is used only to
## check for the Washed Out bonus.
static func calculate_damage(winner_hand: DiceHand, loser_hand: DiceHand) -> int:
	var damage: int = 0
	match winner_hand.hand_type:
		HandType.TIDAL_ROLL:
			damage = 4
		HandType.TRIPLE:
			damage = 3
		_:
			damage = 2

	if loser_hand.hand_type == HandType.WASHED_OUT:
		damage += 1

	return damage
