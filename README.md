# SeaLow

Godot 4.x mobile-first prototype for the SeaLow ocean dice battler.

## Running it locally

1. Install **Godot 4.x** (the project targets the Godot 4 feature set; any
   recent 4.x release of the standard/GL Compatibility editor works).
   Download it from https://godotengine.org/download.
2. Launch the Godot editor and choose **Import**, then select this
   repository's `project.godot` file.
3. Once the project is open, press **Run Project** (the ▶ button in the
   top-right corner, or `F5`). Godot will run the `MainMenu.tscn` scene
   (configured as `run/main_scene` in `project.godot`).
4. The game window opens in the portrait mobile resolution the project is
   authored for (720×1280). Use your mouse to click buttons the same way a
   finger tap would work on a phone.

### Running headless (no editor UI)

You can also boot the project from the command line with a headless Godot
binary, which is useful for quick smoke tests or CI:

```sh
godot --headless --quit-after 60 res://scenes/main/MainMenu.tscn
```

### Tests

Dice hand evaluation/comparison logic has a headless test suite:

```sh
godot --headless --script tests/test_dice_rules.gd
```

### Save data

Player progress is stored locally by the `SaveManager` autoload at
`user://sealow_save.json` (JSON). Deleting this file resets the game to a
fresh install (Character Select will run again). See
[`docs/USERGUIDE.md`](docs/USERGUIDE.md) for exactly where `user://` maps to
on your OS.

## Current milestone: SeaLow v0.2

- **First-time Character Select**: new players choose a starter sea
  creature (Octopus / Crab / Shrimp / Fish) and a pastel body color before
  ever seeing the Main Menu. The choice is saved and skipped on future
  launches.
- **Main Menu** shows the player's selected creature, display name
  ("Little Octo", "Little Crab", …), level, and shell total.
- **Battle screen** shows the player's selected creature (instead of always
  showing the Octopus) facing the Crab enemy, with:
  - Large, polished, ocean-themed **Dice** (`scenes/ui/Dice.tscn`) — rounded
    squares with soft aqua/seafoam coloring, an ocean-blue border, large
    high-contrast pips, a subtle shadow, and a tiny bubble accent. Dice are
    a reusable component (`set_value()`, `set_rolling()`).
  - A slower, more satisfying **roll animation** (~1.2–1.6s): faces cycle
    quickly at first, gradually slow down, and the die settles on its
    final value with a small scale bounce.
  - A **compact battle log** (`Round 1 / Round 2 / …`) showing the latest
    few rounds instead of a wall of status text, with the newest round on
    top and older rounds scrollable.
  - An **ITEM** button (replacing the old placeholder BET button) that
    opens a small popup for using one of three consumable items:
    - 🐢 **Turtle Shield** — if the player would lose the battle while the
      shield is armed, the result becomes a **DRAW** instead of a defeat.
    - 🔱 **Trident** — adds +2 damage to the player's next successful hit.
    - 🧜 **Mermaid Scale** — restores 2 HP immediately (capped at max HP).
- **Persistence**: character type/color, shells, level, battles won, and
  item inventory counts are saved after character creation, battle wins,
  and item use, and are restored (with safe defaults for missing/old
  fields) on the next launch.

See [`docs/USERGUIDE.md`](docs/USERGUIDE.md) for a walkthrough with
screenshots.

## Project structure

```
scenes/
    main/MainMenu.tscn            Main Menu (shows selected character)
    character_select/
        CharacterSelect.tscn      First-run creature + color picker
    battle/Battle.tscn            Battle screen (Crab vs. player creature)
    ui/
        Dice.tscn                 Reusable ocean-themed die
        ItemPopup.tscn            Reusable item-use popup/bottom sheet

scripts/
    systems/
        save_manager.gd           Autoload; persists PlayerData to user://
        scene_manager.gd          Autoload; scene transition helpers
    player/
        player_data.gd            Save schema, creature + pastel color data
    items/
        item_data.gd              Item catalog (Turtle Shield/Trident/Mermaid Scale)
        item_effects.gd           Isolated item gameplay effects
    battle/
        battle_manager.gd         Battle state machine, dice rolls, log, items
        dice_rules.gd             Hand evaluation/comparison rules
    ui/
        dice.gd, dice_pips.gd     Dice component logic + pip rendering
        item_popup.gd             Item popup logic
    character_select/
        character_select.gd       Character Select screen logic
    main/
        main_menu.gd              Main Menu logic
```

## Manual steps after pulling this update

Because these changes were authored and validated with a headless Godot
binary (no editor GUI was available in that environment), please do the
following once after pulling, from inside the Godot editor:

1. Open the project normally in the Godot 4 editor at least once. This
   regenerates `.godot/global_script_class_cache.cfg` and resolves/repairs
   any `uid://` references for the new scenes/scripts
   (`Dice.tscn`, `ItemPopup.tscn`, `CharacterSelect.tscn`, and the new
   scripts under `scripts/items/`, `scripts/player/`, `scripts/ui/`,
   `scripts/character_select/`). You may see the editor briefly reimport
   resources; this is expected and only needs to happen once.
2. If you have an existing local save file from before v0.2
   (`user://sealow_save.json`), no action is required — it will be
   migrated automatically the next time the game loads (old
   `player_shells` values and missing fields are merged with new
   defaults). If you'd like to test the full first-run flow (Character
   Select, etc.), delete that file before launching.
3. No new external art assets were added; the project already represents
   the Octopus and Crab as emoji-based `Label` nodes, and this update keeps
   that same lightweight approach for Shrimp and Fish (and for dice/items),
   which are drawn with built-in Godot UI nodes (`Panel`, `Label`, custom
   `_draw()` pips) as temporary placeholders per the v0.2 scope. Swap in
   real sprites later by replacing the relevant `Label`/`Panel` nodes with
   `TextureRect` nodes — no script changes should be required as long as
   the same node names are preserved.
