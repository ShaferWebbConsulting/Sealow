extends RefCounted
class_name PlayerData
## Static schema/reference data for the persisted player profile. SaveManager
## (an autoload) owns the actual live save dictionary and reads/writes
## user://sealow_save.json; this class just centralizes defaults, character
## metadata and merge-with-defaults logic so it isn't duplicated anywhere.

const DEFAULT_SAVE: Dictionary = {
	"character_selected": false,
	"character_type": "octopus",
	"character_color": "seafoam",
	"shells": 10,
	"level": 1,
	"battles_won": 0,
	"inventory": {
		"turtle_shield": 1,
		"trident": 1,
		"mermaid_scale": 1,
		"seaweed_circle": 1,
	},
	## Persistent player max HP (see Shop's +1 Max HP upgrade). Battle no
	## longer hardcodes PLAYER_MAX_HP — it always reads this via
	## SaveManager.get_max_hp().
	"max_hp": 12,
	## Enemy progression (see EnemyData for the full roster + unlock order).
	## A brand-new save starts with only the first enemy unlocked.
	"selected_enemy": "little_octo",
	"beaten_enemies": [],
	"unlocked_enemies": ["little_octo"],
}

## Metadata for each selectable starter creature. Gameplay stats are
## intentionally identical for all of them in v0.2 — this is a cosmetic /
## identity choice only. `atlas` points at the matching cell in
## charactersList.png (Row 1 — Starter/Surface) so Character Select and
## Battle can render real art instead of an emoji glyph.
const CHARACTER_TYPES: Dictionary = {
	"octopus": {"emoji": "🐙", "display_name": "Little Octo", "atlas": Vector2i(0, 0)},
	"crab": {"emoji": "🦀", "display_name": "Little Crab", "atlas": Vector2i(1, 0)},
	"shrimp": {"emoji": "🦐", "display_name": "Little Shrimp", "atlas": Vector2i(2, 0)},
	"fish": {"emoji": "🐟", "display_name": "Little Fish", "atlas": Vector2i(3, 0)},
	"SeaSnake": {"emoji": "🐍", "display_name": "Snake coming soon...", "atlas": Vector2i(4, 1)},
	#TODO IMPLEMENT SNAKE

}

## Ordered list of selectable creature keys (drives Character Select layout).
const CHARACTER_ORDER: Array[String] = ["octopus", "crab", "shrimp", "fish"]

## Pastel color palette used for the body-tint swatch on Character Select.
## NOTE: today this only tints a background "body" swatch behind the
## creature emoji — the emoji glyph itself (eyes/outline/highlights) is never
## tinted. If/when creature artwork is split into layered sprites, this same
## color should be applied only to the tintable body layer.
const CHARACTER_COLORS: Dictionary = {
	"seafoam": Color(0.6, 0.9, 0.82, 1.0),
	"coral": Color(1.0, 0.65, 0.6, 1.0),
	"lavender": Color(0.78, 0.72, 0.95, 1.0),
	"baby_blue": Color(0.68, 0.85, 0.98, 1.0),
	"peach": Color(1.0, 0.78, 0.65, 1.0),
	"mint": Color(0.68, 0.95, 0.78, 1.0),
	"soft_pink": Color(0.98, 0.72, 0.85, 1.0),
	"sunny_yellow": Color(1.0, 0.9, 0.55, 1.0),
}

const CHARACTER_COLOR_ORDER: Array[String] = [
	"seafoam", "coral", "lavender", "baby_blue",
	"peach", "mint", "soft_pink", "sunny_yellow",
]


static func get_emoji(character_type: String) -> String:
	var info: Dictionary = CHARACTER_TYPES.get(character_type, CHARACTER_TYPES["octopus"])
	return info["emoji"]


## charactersList.png atlas cell (zero-based Vector2i(column, row)) for the
## given playable creature. Use with SeaLowAtlas.get_character_texture().
static func get_atlas_cell(character_type: String) -> Vector2i:
	var info: Dictionary = CHARACTER_TYPES.get(character_type, CHARACTER_TYPES["octopus"])
	return info.get("atlas", Vector2i(0, 0))


static func get_display_name(character_type: String) -> String:
	var info: Dictionary = CHARACTER_TYPES.get(character_type, CHARACTER_TYPES["octopus"])
	return info["display_name"]


static func get_color(character_color: String) -> Color:
	return CHARACTER_COLORS.get(character_color, CHARACTER_COLORS["seafoam"])


## Recursively merges `data` on top of a duplicate of `defaults`, so older
## save files missing newer fields are backfilled instead of crashing, and
## unknown/corrupted values simply fall back to the default shape.
static func merge_with_defaults(data: Dictionary, defaults: Dictionary = DEFAULT_SAVE) -> Dictionary:
	var result: Dictionary = defaults.duplicate(true)
	for key in data.keys():
		if result.has(key) and typeof(result[key]) == TYPE_DICTIONARY and typeof(data[key]) == TYPE_DICTIONARY:
			result[key] = merge_with_defaults(data[key], result[key])
		else:
			result[key] = data[key]
	return result
