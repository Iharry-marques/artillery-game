class_name DamageFormula
extends RefCounted
## Stat-based damage (REFERENCE ESTIMATE after the classic description in
## research/DDTANK_DEEP_RESEARCH.md section 11, not the exact historical code):
##   raw       = harm x (1 + attack / 1000)
##   defense   mitigation = defense / (defense + 1000)        (1000 -> 50%)
##   armor     mitigation = min(0.6, armor x 0.0005)          (30 -> 1.5%)
##   critical  chance = luck / 4000 (100 luck -> 2.5%), x1.5
##   final     = raw x (1 - defense) x (1 - armor) x falloff [x crit]

const CRIT_MULTIPLIER: float = 1.5
const ARMOR_PER_POINT: float = 0.0005
const ARMOR_CAP: float = 0.6


static func damage(attacker: CombatLoadout, target: CombatLoadout, falloff: float, crit_roll: float) -> int:
	if falloff <= 0.0:
		return 0
	var raw: float = attacker.harm * (1.0 + attacker.attack / 1000.0)
	var defense: float = target.defense / (target.defense + 1000.0)
	var armor: float = minf(ARMOR_CAP, target.armor * ARMOR_PER_POINT)
	var value: float = raw * (1.0 - defense) * (1.0 - armor) * falloff
	if crit_roll < attacker.luck / 4000.0:
		value *= CRIT_MULTIPLIER
	return maxi(1, roundi(value))
