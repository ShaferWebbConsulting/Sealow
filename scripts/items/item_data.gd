extends Resource
class_name ItemData
## Static description of a consumable battle item. Keep new items additive:
## add an enum entry + catalog entry here rather than hardcoding item logic
## in battle_manager.gd. Actual gameplay effects live in item_effects.gd.

enum ItemId {
	TURTLE_SHIELD,
	TRIDENT,
	MERMAID_SCALE,
	SEAWEED_CIRCLE,
}

## MVP shop pricing: every item costs exactly 1 shell.
const SHOP_COST_SHELLS: int = 1

## Standalone item PNGs. Circle of Seaweed has no PNG yet, so it keeps its
## emoji icon (see get_texture()).
const ITEM_TEXTURE_PATHS: Dictionary = {
	"trident": "res://assets/characters/trident.png",
	"turtle_shield": "res://assets/characters/turtle_shield.png",
	"mermaid_scale": "res://assets/characters/mermaid_scale.png",
}

@export var id: int = ItemId.TURTLE_SHIELD
@export var display_name: String = ""
@export var icon: String = ""
@export var description: String = ""


func _init(p_id: int = ItemId.TURTLE_SHIELD, p_display_name: String = "", p_icon: String = "", p_description: String = "") -> void:
	id = p_id
	display_name = p_display_name
	icon = p_icon
	description = p_description


## Save-file key for this item id (used in the inventory dictionary).
static func id_to_key(item_id: int) -> String:
	match item_id:
		ItemId.TURTLE_SHIELD:
			return "turtle_shield"
		ItemId.TRIDENT:
			return "trident"
		ItemId.MERMAID_SCALE:
			return "mermaid_scale"
		ItemId.SEAWEED_CIRCLE:
			return "seaweed_circle"
	return ""


static func key_to_id(key: String) -> int:
	match key:
		"turtle_shield":
			return ItemId.TURTLE_SHIELD
		"trident":
			return ItemId.TRIDENT
		"mermaid_scale":
			return ItemId.MERMAID_SCALE
		"seaweed_circle":
			return ItemId.SEAWEED_CIRCLE
	return -1


## Returns the standalone PNG icon for `item_id`, or null if that item
## doesn't have dedicated art (callers then fall back to the emoji `icon`).
static func get_texture(item_id: int) -> Texture2D:
	var key: String = id_to_key(item_id)
	var path: String = String(ITEM_TEXTURE_PATHS.get(key, ""))
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## The full list of items the game currently knows about. Purchasable-with-
## shells items later can simply be appended here.
static func get_catalog() -> Array[ItemData]:
	return [
		ItemData.new(
			ItemId.TURTLE_SHIELD,
			"Turtle Shield",
			"🐢",
			"If you would lose this battle, the Turtle Shield saves you and the result becomes a draw."
		),
		ItemData.new(
			ItemId.TRIDENT,
			"Trident",
			"🔱",
			"Add 2 damage to your next successful attack."
		),
		ItemData.new(
			ItemId.MERMAID_SCALE,
			"Mermaid Scale",
			"🧜",
			"Restore 2 HP."
		),
		ItemData.new(
			ItemId.SEAWEED_CIRCLE,
			"Seaweed Circle",
			"🌿",
			"Roll again if you lose."
		),
	]
