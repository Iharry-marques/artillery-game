class_name DamageModel
extends RefCounted
## GAME DESIGN PLACEHOLDER explosion damage, NOT the historical DDTank formula.
##
## damage = base_damage * max(0, 1 - d / damage_radius), where d is the distance
## from the impact point to the nearest point of the head circle (0 for a direct
## hit). No attack/defense/luck/armor/critical stats yet.


static func damage_at_distance(rules: CombatRules, distance: float) -> int:
	if distance >= rules.damage_radius:
		return 0
	return roundi(rules.base_damage * (1.0 - maxf(distance, 0.0) / rules.damage_radius))


static func distance_to_head(rules: CombatRules, combatant: CombatantState, x: float, y: float) -> float:
	var dx: float = x - combatant.head_center_x()
	var dy: float = y - combatant.head_center_y(rules)
	return maxf(0.0, sqrt(dx * dx + dy * dy) - rules.head_radius)


static func damage_to(rules: CombatRules, combatant: CombatantState, x: float, y: float) -> int:
	return damage_at_distance(rules, distance_to_head(rules, combatant, x, y))
