class_name BallisticEvidence
extends RefCounted
## Reference relationships used to calibrate and test the ballistic model.
##
## These are evidence and test scenarios, NOT physics: nothing in
## scripts/core/ballistics reads them. Evidence IDs refer to docs/EVIDENCE_MATRIX.md.

# --- Full Throw (PLAYER VERIFIED: E-02, E-03, E-04) -------------------------

const FULL_THROW_POWER: float = 95.0
## Zero-wind rule: angle = FULL_THROW_ANGLE_BASE - distance.
const FULL_THROW_ANGLE_BASE: float = 90.0
const FULL_THROW_DISTANCES: Array[float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
## Degrees of correction per 1.0 of wind (tailwind raises the angle, headwind lowers it).
const FULL_THROW_WIND_FACTOR: float = 2.0

# --- Wind calibration scenario --------------------------------------------

## D = 1 and 2 are left out: their tailwind solutions need angles above 90 degrees.
const WIND_CALIBRATION_DISTANCES: Array[float] = [3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
const WIND_CALIBRATION_MAGNITUDE: float = 1.0
## Extra wind magnitudes used to check that the rule stays linear.
const WIND_RULE_CHECK_WINDS: Array[float] = [-2.0, -1.0, -0.5, 0.5, 1.0, 2.0]
const WIND_RULE_CHECK_DISTANCES: Array[float] = [3.0, 5.0, 10.0]

# --- Time-step invariance check -------------------------------------------

const TIME_STEP_VARIANTS: Array[float] = [1.0 / 30.0, 1.0 / 60.0, 1.0 / 120.0]
const TIME_STEP_LABELS: Array[String] = ["1/30", "1/60", "1/120"]
## (angle, power, relative wind): Full Throw D = 3, 5, 10, a headwind Full Throw
## and a low-angle tailwind shot.
const TIME_STEP_CHECK_SHOTS: Array[Vector3] = [
	Vector3(87.0, 95.0, 0.0),
	Vector3(85.0, 95.0, 0.0),
	Vector3(80.0, 95.0, 0.0),
	Vector3(78.0, 95.0, -1.0),
	Vector3(30.0, 60.0, 1.0),
]

# --- Time scale (ESTIMATED / LOW, DECISIONS D-010) ------------------------

## Provisional flight time of the Full Throw at FLIGHT_TIME_REFERENCE_DISTANCE.
const PROVISIONAL_FULL_THROW_FLIGHT_TIME: float = 4.0
const FLIGHT_TIME_REFERENCE_DISTANCE: float = 10.0
## Alternative flight times shown in the report to make the dependency visible.
const FLIGHT_TIME_ALTERNATIVES: Array[float] = [3.0, 4.0, 5.0, 6.0]

# --- Predictions for other techniques (COMMUNITY RESEARCH, LOW) -----------

const TECHNIQUE_ANGLES: Array[float] = [20.0, 30.0, 50.0, 65.0]
const TECHNIQUE_DISTANCES: Array[float] = [1.0, 3.0, 5.0, 10.0]
## Community wind factor claims in degrees per 1.0 wind; NAN = no claim (E-13, E-16, E-17).
const COMMUNITY_WIND_FACTORS: Dictionary = {20.0: NAN, 30.0: 1.0, 50.0: 2.0, 65.0: 2.0}
## 30-degree power table: distance -> power (E-13).
const COMMUNITY_30_DEGREE_ANGLE: float = 30.0
const COMMUNITY_30_DEGREE_POWER: Dictionary = {1.0: 14.0, 5.0: 32.0, 10.0: 47.5}

## Half Throw claim (E-15): power ~60 with angle = 90 - 2 * distance.
const HALF_THROW_RESEARCH_POWER: float = 60.0
const HALF_THROW_ANGLE_PER_DISTANCE: float = 2.0

# --- Solver search ranges (exploration, not game rules) -------------------

## High branch: impact decreases monotonically as the angle rises from 45 to 90.
const HIGH_BRANCH_MIN_ANGLE: float = 45.0
const HIGH_BRANCH_MAX_ANGLE: float = 90.0
## Low branch: impact increases monotonically from a near-flat shot up to 45.
const LOW_BRANCH_MIN_ANGLE: float = 0.5
const LOW_BRANCH_MAX_ANGLE: float = 45.0
## Power range explored by predictions; values above 100 are reported as out of gauge.
const SEARCH_MIN_POWER: float = 0.01
const SEARCH_MAX_POWER: float = 200.0
const GAUGE_MAX_POWER: float = 100.0


## Player rule for the Full Throw, as a prediction (never used by the physics).
static func full_throw_angle(distance: float, relative_wind: float) -> float:
	return FULL_THROW_ANGLE_BASE - distance + FULL_THROW_WIND_FACTOR * relative_wind


static func half_throw_angle(distance: float) -> float:
	return FULL_THROW_ANGLE_BASE - HALF_THROW_ANGLE_PER_DISTANCE * distance


static func angle_branch(technique_angle: float) -> Vector2:
	if technique_angle >= HIGH_BRANCH_MIN_ANGLE:
		return Vector2(HIGH_BRANCH_MIN_ANGLE, HIGH_BRANCH_MAX_ANGLE)
	return Vector2(LOW_BRANCH_MIN_ANGLE, LOW_BRANCH_MAX_ANGLE)
