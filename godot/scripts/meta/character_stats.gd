class_name CharacterStats
extends RefCounted
## Computed character attributes (REFERENCE ESTIMATES, docs/PRODUCT_SHELL.md):
##   base      = 10 + 3 x (level - 1) for attack, defense, agility and luck
##   equipment = item stats + strengthening bonus + composition bonus
##   HP        = 950 + 50 x level + defense / 8 + equipment HP
##   harm      = weapon harm (unarmed: 40); armor = equipment armor
##   power     = attack + defense + agility + luck + 2 x harm + 3 x armor + HP / 10
## Combat Power is cosmetic, as in the classic game.

const UNARMED_HARM: int = 40

var base: StatBlock
var equipment: StatBlock
var total: StatBlock
var max_hp: int
var harm: int
var armor: int
var combat_power: int
var weapon: ItemDefinition


static func compute(profile: PlayerProfile, content: ContentDatabase) -> CharacterStats:
	var stats := CharacterStats.new()
	var per_stat: int = 10 + 3 * (profile.level - 1)
	stats.base = StatBlock.make(per_stat, per_stat, per_stat, per_stat)
	stats.equipment = StatBlock.new()
	for item in profile.equipment.all_items():
		var def: ItemDefinition = content.item(item.def_id)
		if def == null:
			continue
		stats.equipment = stats.equipment.plus(item_stats(def, item))
		if def.kind == ItemDefinition.Kind.WEAPON:
			stats.weapon = def
	stats.total = stats.base.plus(stats.equipment)
	stats.harm = stats.total.harm if stats.weapon != null else UNARMED_HARM
	stats.armor = stats.total.armor
	stats.max_hp = 950 + 50 * profile.level + stats.total.defense / 8 + stats.total.hp
	stats.combat_power = stats.total.attack + stats.total.defense + stats.total.agility + stats.total.luck + 2 * stats.harm + 3 * stats.armor + stats.max_hp / 10
	return stats


## Item stats including strengthening and composition.
static func item_stats(def: ItemDefinition, item: ItemInstance) -> StatBlock:
	return def.stats.plus(EnhancementRules.bonus(def, item.enhance_level)).plus(item.composed)
