class_name LabAimingTools
extends RefCounted
## Developer aiming helpers. They only PREDICT, through BallisticEvidence (human
## aiming techniques) and BallisticSolver (numerical inverse problems). They never
## change how a shot flies, and they never clamp a result to look plausible.

## Range a player can normally aim at. Values outside are shown, not clamped (OQ-22).
const NORMAL_MIN_ANGLE: float = 0.0
const NORMAL_MAX_ANGLE: float = 90.0


class SolveOutcome:
	extends RefCounted
	var quantity: String
	var requested: String
	var value: float
	var found: bool
	var note: String = ""

	func _init(p_quantity: String, p_requested: String, p_value: float) -> void:
		quantity = p_quantity
		requested = p_requested
		value = p_value
		found = not is_nan(p_value)


## Full Throw preset (evidence-based aiming technique E-02/E-03/E-04):
## power 95, angle = 90 - D + 2 * relative wind. Returns the preset angle.
static func apply_full_throw(setup: LabShotSetup) -> float:
	setup.power = BallisticEvidence.FULL_THROW_POWER
	setup.angle = BallisticEvidence.full_throw_angle(setup.distance, setup.relative_wind())
	return setup.angle


static func is_outside_normal_range(angle: float) -> bool:
	return angle < NORMAL_MIN_ANGLE or angle > NORMAL_MAX_ANGLE


## Angle that lands exactly on the target with the current power, wind and height.
static func solve_angle(setup: LabShotSetup, params: BallisticParameters, high_arc: bool) -> SolveOutcome:
	var lo: float = BallisticEvidence.HIGH_BRANCH_MIN_ANGLE if high_arc else BallisticEvidence.LOW_BRANCH_MIN_ANGLE
	var hi: float = BallisticEvidence.HIGH_BRANCH_MAX_ANGLE if high_arc else BallisticEvidence.LOW_BRANCH_MAX_ANGLE
	var value: float = BallisticSolver.solve_angle(
		params, setup.distance, setup.power, setup.relative_wind(), lo, hi, setup.target_y()
	)
	var requested: String = "%s arc in [%s, %s] deg | D %.3f, y %+.3f, power %.3f, rel. wind %+.2f" % [
		"high" if high_arc else "low", lo, hi, setup.distance, setup.target_y(), setup.power, setup.relative_wind()
	]
	return SolveOutcome.new("angle", requested, value)


## Power that lands exactly on the target with the current angle, wind and height.
static func solve_power(setup: LabShotSetup, params: BallisticParameters) -> SolveOutcome:
	var value: float = BallisticSolver.solve_power(
		params,
		setup.distance,
		setup.angle,
		setup.relative_wind(),
		BallisticEvidence.SEARCH_MIN_POWER,
		BallisticEvidence.SEARCH_MAX_POWER,
		setup.target_y()
	)
	var requested: String = "power in [%s, %s] | D %.3f, y %+.3f, angle %.3f, rel. wind %+.2f" % [
		BallisticEvidence.SEARCH_MIN_POWER, BallisticEvidence.SEARCH_MAX_POWER,
		setup.distance, setup.target_y(), setup.angle, setup.relative_wind()
	]
	var outcome := SolveOutcome.new("power", requested, value)
	if outcome.found and value > BallisticEvidence.GAUGE_MAX_POWER:
		outcome.note = "above the 0-100 power gauge"
	return outcome
