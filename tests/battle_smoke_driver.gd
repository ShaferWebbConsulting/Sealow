extends Node
## Headless smoke-test driver: instances the Battle scene as a child (so
## SaveManager/SceneManager autoloads are available, since this runs as the
## normal main scene rather than via --script), then repeatedly calls
## perform_round() until the battle ends or a safety cap is hit. Prints
## progress so a human/CI log can sanity-check HP, damage, and log behavior.
##
## Run with:
##   godot --headless --path . --quit-after 20 res://tests/BattleSmoke.tscn

var _battle: Control
var _rounds_triggered: int = 0
const MAX_ROUNDS: int = 40


func _ready() -> void:
	_battle = load("res://scenes/battle/Battle.tscn").instantiate()
	add_child(_battle)


func _process(_delta: float) -> void:
	if _battle == null:
		return
	if _battle.player_hp <= 0 or _battle.crab_hp <= 0:
		_finish()
		return
	if _rounds_triggered >= MAX_ROUNDS:
		_finish()
		return
	if _battle.state == _battle.BattleState.PLAYER_TURN:
		_rounds_triggered += 1
		print("Triggering round %d (player_hp=%d crab_hp=%d)" % [_rounds_triggered, _battle.player_hp, _battle.crab_hp])
		_battle.perform_round()


func _finish() -> void:
	print("DONE: player_hp=%d crab_hp=%d rounds_triggered=%d log_entries=%d" % [
		_battle.player_hp, _battle.crab_hp, _rounds_triggered, _battle.battle_log.size(),
	])
	for entry in _battle.battle_log:
		print(entry)
	set_process(false)
	get_tree().quit(0)
