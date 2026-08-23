# SeaLow

Godot 4.x mobile-first prototype for the SeaLow ocean dice battler.

## Current milestone

- Launches to a portrait main menu.
- `DIVE` transitions to the initial Crab battle screen.
- `RETURN HOME` returns to the main menu.

## Tests

Dice hand evaluation/comparison logic has a headless test suite:

```sh
godot --headless --script tests/test_dice_rules.gd
```
