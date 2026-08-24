extends Resource
class_name ItemData
## Static description of a consumable battle item. Keep new items additive:
## add an enum entry + catalog entry here rather than hardcoding item logic
## in battle_manager.gd. Actual gameplay effects live in item_effects.gd.

enum ItemId {
	TURTLE_SHIELD,
	TRIDENT,
	MERMAID_SCALE,
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
	return ""


static func key_to_id(key: String) -> int:
	match key:
		"turtle_shield":
			return ItemId.TURTLE_SHIELD
		"trident":
			return ItemId.TRIDENT
		"mermaid_scale":
			return ItemId.MERMAID_SCALE
	return -1


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
	]
