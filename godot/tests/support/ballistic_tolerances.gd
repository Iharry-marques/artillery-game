class_name BallisticTolerances
extends RefCounted
## Test tolerances, chosen AFTER measuring the calibrated model
## (tools/ballistics/reports/calibration_report.md, docs/PHYSICS_MODEL.md section 6).
## They are regression guards just above the measured errors, not targets.

## Full Throw zero-wind impact error. Measured max 0.0701 u (D = 10).
const FULL_THROW_MAX_IMPACT_ERROR: float = 0.075
## Full Throw zero-wind mean absolute error over D = 1..10. Measured 0.0316 u.
const FULL_THROW_MEAN_IMPACT_ERROR: float = 0.035
## Wind correction versus the 2-degrees-per-wind rule. Measured max 0.0353 degrees.
const WIND_CORRECTION_ERROR_DEGREES: float = 0.04
## Impact error when aiming with angle = 90 - D + 2 * wind, |wind| <= 1.
## Measured max 0.1024 u (D = 10, headwind 1.0): zero-wind and wind errors add up.
const WIND_RULE_IMPACT_ERROR: float = 0.11
const WIND_RULE_TEST_WINDS: Array[float] = [-1.0, -0.5, 0.5, 1.0]

## Results that must be identical up to floating-point rounding. Measured <= 1.5e-13.
const NUMERICAL_EQUIVALENCE: float = 1e-9
