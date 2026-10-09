class_name CombatLoadout
extends RefCounted
## Battle-relevant numbers of one combatant, derived from CharacterStats (players)
## or EnemyDefinition (monsters). Ballistics stay universal; only damage, HP,
## angle limits, crater size and hit geometry vary.

var max_hp: int = 1000
var attack: int = 0
var defense: int = 0
var agility: int = 0
var luck: int = 0
var harm: int = 100
var armor: int = 0
var min_angle: int = 0
var max_angle: int = 90
var crater_radius: float = 0.6
var damage_radius: float = 1.0
var head_radius: float = 0.25
var head_center_height: float = 0.72
var weapon_art: StringName = &"launcher"
var projectile_art: StringName = &"shell"
var anchored: bool = false
## Healing Kits carried into battle (consumed from the Bag afterwards).
var heal_items: int = 0
var heal_amount: int = 0


static func from_player(stats: CharacterStats, rules: CombatRules) -> CombatLoadout:
	var loadout := CombatLoadout.new()
	loadout.max_hp = stats.max_hp
	loadout.attack = stats.total.attack
	loadout.defense = stats.total.defense
	loadout.agility = stats.total.agility
	loadout.luck = stats.total.luck
	loadout.harm = stats.harm
	loadout.armor = stats.armor
	loadout.head_radius = rules.head_radius
	loadout.head_center_height = rules.head_center_height
	if stats.weapon != null:
		loadout.min_angle = stats.weapon.min_angle
		loadout.max_angle = stats.weapon.max_angle
		loadout.crater_radius = stats.weapon.crater_radius
		loadout.damage_radius = stats.weapon.damage_radius
		loadout.weapon_art = stats.weapon.weapon_art
		loadout.projectile_art = stats.weapon.projectile_art
	return loadout


static func from_enemy(def: EnemyDefinition, hp_scale: float, damage_scale: float) -> CombatLoadout:
	var loadout := CombatLoadout.new()
	loadout.max_hp = roundi(def.max_hp * hp_scale)
	loadout.attack = def.stats.attack
	loadout.defense = def.stats.defense
	loadout.agility = def.stats.agility
	loadout.luck = def.stats.luck
	loadout.harm = roundi(def.stats.harm * damage_scale)
	loadout.armor = def.stats.armor
	loadout.min_angle = def.min_angle
	loadout.max_angle = def.max_angle
	loadout.crater_radius = def.crater_radius
	loadout.damage_radius = def.damage_radius
	loadout.head_radius = def.head_radius
	loadout.head_center_height = def.head_center_height
	loadout.anchored = def.anchored
	loadout.weapon_art = &""
	loadout.projectile_art = &"pebble" if def.behavior == EnemyDefinition.Behavior.ARTILLERY else &"boulder"
	return loadout
