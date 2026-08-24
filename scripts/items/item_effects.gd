extends RefCounted
class_name ItemEffects
## Isolates the precise gameplay effect of each consumable item so
## battle_manager.gd only has to call these helpers instead of hardcoding
## item-specific branching throughout the round-resolution logic.

const TRIDENT_BONUS_DAMAGE: int = 2
const MERMAID_SCALE_HEAL: int = 2


## Mermaid Scale: heals `amount` HP, clamped to [0, max_hp]. Returns the new HP.
static func apply_heal(current_hp: int, max_hp: int, amount: int = MERMAID_SCALE_HEAL) -> int:
	return clampi(current_hp + amount, 0, max_hp)


## Trident: if armed, adds `bonus` to base_damage. Returns a dictionary with
## the resulting damage and whether the bonus was consumed, so the caller
## knows to clear its "trident armed" flag.
static func apply_damage_bonus(base_damage: int, is_armed: bool, bonus: int = TRIDENT_BONUS_DAMAGE) -> Dictionary:
	if not is_armed:
		return {"damage": base_damage, "consumed": false}
	return {"damage": base_damage + bonus, "consumed": true}


## Turtle Shield: if armed, it saves the player from an otherwise-lethal
## defeat and the battle becomes a DRAW instead. Returns true if the shield
## should trigger (i.e. it was armed).
static func resolve_defeat(is_armed: bool) -> bool:
	return is_armed
