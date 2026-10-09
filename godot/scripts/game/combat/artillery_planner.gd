class_name ArtilleryPlanner
extends RefCounted
## Simple competent artillery AI (pure): asks BallisticSolver for the angle that
## lands on the target's head at a few candidate powers, inside the shooter's
## angle limits and with the current wind, then adds aim error. The shooter must
## already face the target (the launch point depends on facing and angle).

const CANDIDATE_POWERS: Array[float] = [90.0, 78.0, 66.0, 54.0, 98.0, 42.0]
const LAUNCH_POINT_ITERATIONS: int = 3
const FALLBACK_POWER: float = 70.0
const MIN_POWER: float = 5.0


## Returns (angle, power). Never NAN: falls back to a lob if nothing is solvable.
static func plan(battle: CombatMatch, shooter: CombatantState, target: CombatantState, rng: RandomNumberGenerator) -> Vector2:
	var limits: Vector2i = battle.angle_limits(shooter)
	var solved := Vector2(NAN, NAN)
	for candidate in CANDIDATE_POWERS:
		var angle: float = _solve(battle, shooter, target, candidate, limits)
		if not is_nan(angle):
			solved = Vector2(angle, candidate)
			break
	if is_nan(solved.x):
		solved = Vector2(clampf(65.0, limits.x, limits.y), FALLBACK_POWER)
	var error: float = shooter.aim_error_degrees
	var angle_out: float = clampf(solved.x + rng.randfn(0.0, error), limits.x, limits.y)
	var power_out: float = clampf(solved.y + rng.randfn(0.0, error * 0.6), MIN_POWER, battle.rules.power_max)
	return Vector2(angle_out, power_out)


static func _solve(battle: CombatMatch, shooter: CombatantState, target: CombatantState, power: float, limits: Vector2i) -> float:
	var branches: Array[Vector2] = [
		Vector2(maxf(45.0, limits.x), minf(89.0, limits.y)),
		Vector2(maxf(1.0, limits.x), minf(45.0, limits.y)),
	]
	for branch in branches:
		if branch.x >= branch.y:
			continue
		var guess: float = (branch.x + branch.y) * 0.5
		var angle: float = NAN
		for i in LAUNCH_POINT_ITERATIONS:
			var mx: float = shooter.muzzle_x(battle.rules, guess)
			var my: float = shooter.muzzle_y(battle.rules, guess)
			var distance: float = (target.head_center_x() - mx) * shooter.facing
			if distance <= 0.05:
				break
			angle = BallisticSolver.solve_angle(
				battle.params, distance, power, battle.wind * shooter.facing, branch.x, branch.y, target.head_center_y() - my
			)
			if is_nan(angle):
				break
			guess = angle
		if not is_nan(angle):
			return angle
	return NAN
