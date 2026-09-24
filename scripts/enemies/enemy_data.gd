extends RefCounted
class_name EnemyData
## Centralized enemy roster + progression order. BattleManager and the Enemy
## Select screen both read from here instead of hardcoding a single "Crab"
## opponent, so adding/rebalancing an enemy never requires touching battle
## logic directly.

## Depth -> backgrounds.png atlas cell (zero-based). See SeaLowAtlas for the
## actual cropping helper.
const BACKGROUND_CELLS: Dictionary = {
	"surface": Vector2i(0, 0),
	"reef": Vector2i(1, 0),
	"coastal_edge": Vector2i(2, 0),
	"mystic_waters": Vector2i(0, 1),
	"royal_depths": Vector2i(1, 1),
	"abyss": Vector2i(2, 1),
}

## Master enemy roster, keyed by enemy key. `progression_index` is the
## player's 0-based position in the fixed unlock order (see section 6/9 of
## the design) — beating the enemy at index N unlocks the enemy at N + 1.
const ENEMIES: Dictionary = {
	# ---------------------------------------------------------------
	# SURFACE
	# ---------------------------------------------------------------
	"little_octo": {
		"display_name": "Little Octo",
		"tier": "starter",
		"depth": "surface",
		"max_hp": 3,
		"atlas": Vector2i(0, 0),
		"progression_index": 0,
	},
	"little_crab": {
		"display_name": "Little Crab",
		"tier": "starter",
		"depth": "surface",
		"max_hp": 3,
		"atlas": Vector2i(1, 0),
		"progression_index": 1,
	},
	"little_shrimp": {
		"display_name": "Little Shrimp",
		"tier": "starter",
		"depth": "surface",
		"max_hp": 3,
		"atlas": Vector2i(2, 0),
		"progression_index": 2,
	},
	"little_fish": {
		"display_name": "Little Fish",
		"tier": "starter",
		"depth": "surface",
		"max_hp": 3,
		"atlas": Vector2i(3, 0),
		"progression_index": 3,
	},
	"turtle": {
		"display_name": "Turtle",
		"tier": "starter",
		"depth": "surface",
		"max_hp": 4,
		"atlas": Vector2i(4, 0),
		"progression_index": 4,
	},

	# ---------------------------------------------------------------
	# REEF
	# ---------------------------------------------------------------
	"octo_bruiser": {
		"display_name": "Octo Bruiser",
		"tier": "medium",
		"depth": "reef",
		"max_hp": 5,
		"atlas": Vector2i(0, 1),
		"progression_index": 5,
	},
	"reef_crab": {
		"display_name": "Reef Crab",
		"tier": "medium",
		"depth": "reef",
		"max_hp": 6,
		"atlas": Vector2i(1, 1),
		"progression_index": 6,
	},
	"pistol_shrimp": {
		"display_name": "Pistol Shrimp",
		"tier": "medium",
		"depth": "reef",
		"max_hp": 6,
		"atlas": Vector2i(2, 1),
		"progression_index": 7,
	},
	"reef_runner": {
		"display_name": "Reef Runner",
		"tier": "medium",
		"depth": "reef",
		"max_hp": 7,
		"atlas": Vector2i(3, 1),
		"progression_index": 8,
	},
	"sea_snake": {
		"display_name": "Sea Snake",
		"tier": "medium",
		"depth": "reef",
		"max_hp": 8,
		"atlas": Vector2i(4, 1),
		"progression_index": 9,
	},

	# ---------------------------------------------------------------
	# COASTAL EDGE
	# ---------------------------------------------------------------
	"kraken_octo": {
		"display_name": "Kraken Octo",
		"tier": "large",
		"depth": "coastal_edge",
		"max_hp": 9,
		"atlas": Vector2i(0, 2),
		"progression_index": 10,
	},
	"king_crab": {
		"display_name": "King Crab",
		"tier": "large",
		"depth": "coastal_edge",
		"max_hp": 10,
		"atlas": Vector2i(1, 2),
		"progression_index": 11,
	},
	"tiger_shrimp": {
		"display_name": "Tiger Shrimp",
		"tier": "large",
		"depth": "coastal_edge",
		"max_hp": 11,
		"atlas": Vector2i(2, 2),
		"progression_index": 12,
	},
	"barracuda": {
		"display_name": "Barracuda",
		"tier": "large",
		"depth": "coastal_edge",
		"max_hp": 12,
		"atlas": Vector2i(3, 2),
		"progression_index": 13,
	},

	# ---------------------------------------------------------------
	# MYSTIC WATERS
	# ---------------------------------------------------------------
	"large_guppy": {
		"display_name": "Large Guppy",
		"tier": "special",
		"depth": "mystic_waters",
		"max_hp": 13,
		"atlas": Vector2i(0, 3),
		"progression_index": 14,
	},
	"electric_eel": {
		"display_name": "Electric Eel",
		"tier": "special",
		"depth": "mystic_waters",
		"max_hp": 14,
		"atlas": Vector2i(4, 2),
		"progression_index": 15,
	},
	"puffer_boss": {
		"display_name": "Puffer Boss",
		"tier": "special",
		"depth": "mystic_waters",
		"max_hp": 15,
		"atlas": Vector2i(1, 3),
		"progression_index": 16,
	},
	"hammerhead_hustler": {
		"display_name": "Hammerhead Hustler",
		"tier": "special",
		"depth": "mystic_waters",
		"max_hp": 16,
		"atlas": Vector2i(2, 3),
		"progression_index": 17,
	},

	# ---------------------------------------------------------------
	# ROYAL DEPTHS
	# ---------------------------------------------------------------
	"magic_mermaid": {
		"display_name": "Magic Mermaid",
		"tier": "royal",
		"depth": "royal_depths",
		"max_hp": 18,
		"atlas": Vector2i(3, 3),
		"progression_index": 18,
	},
	"siren_queen": {
		"display_name": "Siren Queen",
		"tier": "royal",
		"depth": "royal_depths",
		"max_hp": 20,
		"atlas": Vector2i(4, 3),
		"progression_index": 19,
	},
	"sea_king": {
		"display_name": "Sea King",
		"tier": "royal",
		"depth": "royal_depths",
		"max_hp": 22,
		"atlas": Vector2i(0, 4),
		"progression_index": 20,
	},
	"poseidon": {
		"display_name": "Poseidon",
		"tier": "royal",
		"depth": "royal_depths",
		"max_hp": 25,
		"atlas": Vector2i(1, 4),
		"progression_index": 21,
	},

	# ---------------------------------------------------------------
	# ABYSS
	# ---------------------------------------------------------------
	"cthulhu_of_the_deep": {
		"display_name": "Cthulhu of the Deep",
		"tier": "final",
		"depth": "abyss",
		"max_hp": 30,
		"atlas": Vector2i(0, 5),
		"progression_index": 22,
	},
}

## Fixed unlock order, indexed by progression_index. A new save unlocks only
## PROGRESSION_ORDER[0] ("little_octo"); beating the enemy at index N unlocks
## PROGRESSION_ORDER[N + 1], if any.
const PROGRESSION_ORDER: Array[String] = [
	"little_octo", "little_crab", "little_shrimp", "little_fish", "turtle",
	"octo_bruiser", "reef_crab", "pistol_shrimp", "reef_runner", "sea_snake",
	"kraken_octo", "king_crab", "tiger_shrimp", "barracuda",
	"large_guppy", "electric_eel", "puffer_boss", "hammerhead_hustler",
	"magic_mermaid", "siren_queen", "sea_king", "poseidon",
	"cthulhu_of_the_deep",
]


## Returns the enemy definition dictionary for `key`, or an empty dictionary
## if unknown.
static func get_enemy(key: String) -> Dictionary:
	return ENEMIES.get(key, {})


## Returns the backgrounds.png atlas cell for a given depth (e.g. "surface").
## Falls back to the surface cell if the depth is unrecognized.
static func get_background_cell(depth: String) -> Vector2i:
	return BACKGROUND_CELLS.get(depth, BACKGROUND_CELLS["surface"])


## The very first enemy in the progression (used to seed a new save's
## unlocked/selected enemy).
static func get_first_enemy_key() -> String:
	return PROGRESSION_ORDER[0]


## Returns the enemy key that comes immediately after `key` in the
## progression, or "" if `key` is the final enemy (or unrecognized).
static func get_next_enemy_key(key: String) -> String:
	var index: int = PROGRESSION_ORDER.find(key)
	if index == -1 or index + 1 >= PROGRESSION_ORDER.size():
		return ""
	return PROGRESSION_ORDER[index + 1]
