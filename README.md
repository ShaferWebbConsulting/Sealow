# SeaLow

Godot 4.x mobile-first prototype for the SeaLow ocean dice battler.

## Current milestone

- Launches to a portrait main menu with a redesigned ocean-themed layout.
- Shell currency is persisted via the `SaveManager` autoload (`user://sealow_save.json`)
  and shown on the Main Menu, always reflecting the latest saved total.
- `SETTINGS` opens a mock settings panel (Music/SFX are real; Vibration,
  Difficulty and Ocean Theme are explicitly labeled `MOCK`) with a `← BACK`
  button that always returns to the Main Menu.
- `DIVE` transitions to a redesigned Crab battle screen: enemy card/sprite
  upper area, player card/sprite lower area, animated HP bars, a dedicated
  battle message panel, and a ROLL / BET (mock) / RUN / RULES action menu.
- `RUN` asks for confirmation before returning to the Main Menu (no shells
  awarded).
- `RULES` opens a scrollable rules panel with a `← BACK` button.
- `RETURN HOME` returns to the main menu.

## Tests

Dice hand evaluation/comparison logic has a headless test suite:

```sh
godot --headless --script tests/test_dice_rules.gd
```
