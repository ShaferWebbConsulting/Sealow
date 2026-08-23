extends SceneTree
## Lightweight headless test runner for DiceRules hand evaluation/comparison.
##
## Run with:
##   godot --headless --script tests/test_dice_rules.gd
##
## Exits with code 0 if all assertions pass, 1 otherwise.

const DiceRules = preload("res://scripts/battle/dice_rules.gd")

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	_test_pair_beats_pair_by_pair_value()
	_test_pair_vs_pair_reverse()
	_test_pair_high_die_tiebreak()
	_test_pair_high_die_tiebreak_reverse()
	_test_pair_tie()
	_test_triple_beats_pair()
	_test_evaluate_hand_preserves_pair_and_point()

	if failures > 0:
		print("FAILED: %d/%d checks failed" % [failures, checks])
		quit(1)
	else:
		print("PASSED: %d/%d checks" % [checks, checks])
		quit(0)


func _assert_eq(actual, expected, message: String) -> void:
	checks += 1
	if actual != expected:
		failures += 1
		print("FAIL: %s (expected %s, got %s)" % [message, str(expected), str(actual)])


## [1,1,3] loses to [3,3,2] -- pair value must outrank the unmatched die.
func _test_pair_beats_pair_by_pair_value() -> void:
	var a: DiceRules.DiceHand = DiceRules.evaluate_hand([1, 1, 3])
	var b: DiceRules.DiceHand = DiceRules.evaluate_hand([3, 3, 2])
	_assert_eq(DiceRules.compare_hands(a, b), -1, "[1,1,3] should lose to [3,3,2]")


func _test_pair_vs_pair_reverse() -> void:
	var a: DiceRules.DiceHand = DiceRules.evaluate_hand([2, 2, 6])
	var b: DiceRules.DiceHand = DiceRules.evaluate_hand([5, 5, 1])
	_assert_eq(DiceRules.compare_hands(a, b), -1, "[2,2,6] should lose to [5,5,1]")


## [6,6,1] beats [5,5,6] -- higher pair wins even against a higher high die.
func _test_pair_high_die_tiebreak() -> void:
	var a: DiceRules.DiceHand = DiceRules.evaluate_hand([6, 6, 1])
	var b: DiceRules.DiceHand = DiceRules.evaluate_hand([5, 5, 6])
	_assert_eq(DiceRules.compare_hands(a, b), 1, "[6,6,1] should beat [5,5,6]")


## [3,3,2] loses to [3,3,5] -- same pair, so the unmatched die decides.
func _test_pair_high_die_tiebreak_reverse() -> void:
	var a: DiceRules.DiceHand = DiceRules.evaluate_hand([3, 3, 2])
	var b: DiceRules.DiceHand = DiceRules.evaluate_hand([3, 3, 5])
	_assert_eq(DiceRules.compare_hands(a, b), -1, "[3,3,2] should lose to [3,3,5]")

	var c: DiceRules.DiceHand = DiceRules.evaluate_hand([4, 4, 6])
	var d: DiceRules.DiceHand = DiceRules.evaluate_hand([4, 4, 2])
	_assert_eq(DiceRules.compare_hands(c, d), 1, "[4,4,6] should beat [4,4,2]")


## [4,4,6] ties [4,4,6] -- identical pair and identical high die is a tie.
func _test_pair_tie() -> void:
	var a: DiceRules.DiceHand = DiceRules.evaluate_hand([4, 4, 6])
	var b: DiceRules.DiceHand = DiceRules.evaluate_hand([4, 4, 6])
	_assert_eq(DiceRules.compare_hands(a, b), 0, "[4,4,6] should tie [4,4,6]")

	var c: DiceRules.DiceHand = DiceRules.evaluate_hand([5, 5, 3])
	var d: DiceRules.DiceHand = DiceRules.evaluate_hand([5, 5, 3])
	_assert_eq(DiceRules.compare_hands(c, d), 0, "[5,5,3] should tie [5,5,3]")


func _test_triple_beats_pair() -> void:
	var a: DiceRules.DiceHand = DiceRules.evaluate_hand([2, 2, 2])
	var b: DiceRules.DiceHand = DiceRules.evaluate_hand([6, 6, 5])
	_assert_eq(DiceRules.compare_hands(a, b), 1, "TRIPLE 2 should beat PAIR 6")


func _test_evaluate_hand_preserves_pair_and_point() -> void:
	var hand: DiceRules.DiceHand = DiceRules.evaluate_hand([1, 1, 3])
	_assert_eq(hand.pair_value, 1, "[1,1,3] pair_value should be 1")
	_assert_eq(hand.point_value, 3, "[1,1,3] point_value should be 3")

	var hand2: DiceRules.DiceHand = DiceRules.evaluate_hand([3, 3, 2])
	_assert_eq(hand2.pair_value, 3, "[3,3,2] pair_value should be 3")
	_assert_eq(hand2.point_value, 2, "[3,3,2] point_value should be 2")
