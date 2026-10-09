extends TestCase
## Launch point at the barrel tip, weapon pivot rotation and leaving one's own head.

const EPS: float = 1e-9


func _shooter(facing: int) -> CombatantState:
	return CombatantState.new(0, "S", 10.0, 12.0, facing, CombatRules.load_default())


func test_launch_point_is_the_barrel_tip() -> void:
	var rules: CombatRules = CombatRules.load_default()
	var right: CombatantState = _shooter(1)
	var px: float = right.weapon_pivot_x(rules)
	var py: float = right.weapon_pivot_y(rules)
	assert_near(right.muzzle_x(rules, 0.0), px + rules.weapon_barrel_length, EPS, "0 deg: straight ahead")
	assert_near(right.muzzle_y(rules, 0.0), py, EPS, "0 deg: pivot height")
	assert_near(right.muzzle_x(rules, 90.0), px, 1e-12, "90 deg: straight up")
	assert_near(right.muzzle_y(rules, 90.0), py - rules.weapon_barrel_length, EPS, "90 deg: one barrel above")
	var left: CombatantState = _shooter(-1)
	assert_near(left.muzzle_x(rules, 45.0) - left.feet_x, -(right.muzzle_x(rules, 45.0) - right.feet_x), EPS, "facing mirrors x")
	assert_near(left.muzzle_y(rules, 45.0), right.muzzle_y(rules, 45.0), EPS, "facing keeps y")


func test_weapon_pivot_rotation_follows_the_gameplay_angle() -> void:
	for angle: float in [0.0, 30.0, 80.0, 90.0]:
		assert_near(CombatantView.weapon_rotation(angle), -deg_to_rad(angle), EPS, "%s deg" % angle)


func test_steep_shot_leaves_the_shooters_own_head() -> void:
	var rules: CombatRules = CombatRules.load_default()
	var shooter: CombatantState = _shooter(1)
	var x: float = shooter.muzzle_x(rules, 88.0)
	var y: float = shooter.muzzle_y(rules, 88.0)
	assert_true(shooter.is_inside_head(rules, x, y), "an 88 deg barrel tip starts inside the own head")
	var terrain := TerrainMask.new(400, 400, 0.05)
	var query := CombatWorldQuery.new(terrain, rules, [shooter], shooter)
	assert_true(query.first_hit(x, y, x, y - 0.1) == null, "leaving the own head is not a hit")
	var hx: float = shooter.head_center_x()
	var hy: float = shooter.head_center_y(rules)
	var falling: BallisticHit = query.first_hit(hx, hy - 1.0, hx, hy)
	assert_true(falling != null and falling.collider == shooter, "once outside, the shooter can be hit by its own shot")
