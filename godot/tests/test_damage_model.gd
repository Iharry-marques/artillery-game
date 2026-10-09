extends TestCase
## Placeholder linear-falloff damage (GAME DESIGN PLACEHOLDER, not historical).


func test_center_impact_gives_maximum_damage() -> void:
	var rules: CombatRules = CombatRules.load_default()
	assert_true(DamageModel.damage_at_distance(rules, 0.0) == roundi(rules.base_damage), "full damage at d = 0")
	var target := CombatantState.new(0, "T", 5.0, 5.0, 1, rules)
	var hx: float = target.head_center_x()
	var hy: float = target.head_center_y(rules)
	assert_true(DamageModel.damage_to(rules, target, hx, hy) == roundi(rules.base_damage), "direct head hit")
	assert_true(DamageModel.damage_to(rules, target, hx + rules.head_radius, hy) == roundi(rules.base_damage), "on the head edge")


func test_damage_decreases_towards_the_edge() -> void:
	var rules: CombatRules = CombatRules.load_default()
	var half: int = DamageModel.damage_at_distance(rules, rules.damage_radius * 0.5)
	assert_true(half == roundi(rules.base_damage * 0.5), "half damage at half radius, got %d" % half)
	assert_true(DamageModel.damage_at_distance(rules, rules.damage_radius * 0.9) < half, "less near the edge")


func test_outside_radius_gives_zero() -> void:
	var rules: CombatRules = CombatRules.load_default()
	assert_true(DamageModel.damage_at_distance(rules, rules.damage_radius) == 0, "zero at the radius")
	assert_true(DamageModel.damage_at_distance(rules, rules.damage_radius * 3.0) == 0, "zero beyond it")
