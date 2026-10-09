class_name ItemDefinition
extends RefCounted
## Static item template (the classic "template vs instance" split). Content lives
## in ContentCatalog; nothing here is historical data.

enum Kind { WEAPON, CLOTHES, HAT, RING, NECKLACE, STONE, ELEMENT_STONE, CHARM, PROTECTION, CONSUMABLE, BOX }
enum Slot { NONE, WEAPON, CLOTHES, HAT, RING, NECKLACE }

var id: StringName
var display_name: String
var kind: Kind
var description: String = ""
## 0 common, 1 fine, 2 rare, 3 epic (frame colour only).
var rarity: int = 0
var stats: StatBlock = StatBlock.new()
var max_stack: int = 1
var price_gold: int = 0
var price_coupons: int = 0
var sell_gold: int = 0
var level_required: int = 1
## Icon colour used by the procedural item icons.
var color: Color = Color.WHITE

# Weapon gameplay data (only for Kind.WEAPON).
var min_angle: int = 0
var max_angle: int = 90
var crater_radius: float = 0.6
var damage_radius: float = 1.0
var weapon_art: StringName = &"launcher"
var projectile_art: StringName = &"shell"
var weapon_style: String = ""

# Materials.
var stone_level: int = 0
## For element stones: &"attack", &"defense", &"agility" or &"luck".
var element: StringName = &""
## For charms: added strengthening chance (0..1).
var charm_bonus: float = 0.0

# Consumables and boxes.
var heal_amount: int = 0
var box_contents: Array[Dictionary] = []


func is_stackable() -> bool:
	return max_stack > 1


func is_equipment() -> bool:
	return slot() != Slot.NONE


func slot() -> Slot:
	match kind:
		Kind.WEAPON:
			return Slot.WEAPON
		Kind.CLOTHES:
			return Slot.CLOTHES
		Kind.HAT:
			return Slot.HAT
		Kind.RING:
			return Slot.RING
		Kind.NECKLACE:
			return Slot.NECKLACE
	return Slot.NONE


func can_strengthen() -> bool:
	return kind == Kind.WEAPON or kind == Kind.CLOTHES or kind == Kind.HAT


static func slot_name(value: Slot) -> String:
	return ["-", "Weapon", "Clothes", "Hat", "Ring", "Necklace"][value]


static func kind_name(value: Kind) -> String:
	return ["Weapon", "Clothes", "Hat", "Ring", "Necklace", "Strengthen Stone", "Element Stone", "Charm", "Protection", "Battle Item", "Gift Box"][value]
