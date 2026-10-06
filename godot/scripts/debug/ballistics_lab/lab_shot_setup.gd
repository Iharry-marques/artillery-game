class_name LabShotSetup
extends RefCounted
## One Lab experiment, in world units (u). The shooter's reference point is the
## origin (0, 0); no hitbox and no muzzle offset (OQ-09).
##
## vertical_offset follows the Godot convention used by the whole simulation:
## y grows DOWNWARD, so +2 means the target is 2 u BELOW the shooter and -2 means
## 2 u ABOVE. The target sits at (facing * distance, vertical_offset).

var distance: float
var vertical_offset: float
var angle: float
var power: float
## World wind: positive pushes toward +x regardless of facing.
var wind: float
var facing: int


func _init(
	p_distance: float,
	p_vertical_offset: float,
	p_angle: float,
	p_power: float,
	p_wind: float = 0.0,
	p_facing: int = 1
) -> void:
	distance = p_distance
	vertical_offset = p_vertical_offset
	angle = p_angle
	power = p_power
	wind = p_wind
	facing = p_facing


func copy() -> LabShotSetup:
	return LabShotSetup.new(distance, vertical_offset, angle, power, wind, facing)


func target_x() -> float:
	return facing * distance


func target_y() -> float:
	return vertical_offset


## Positive when the target is above the shooter (the opposite sign of y).
func height_above_shooter() -> float:
	return -vertical_offset


## Wind as the shooter feels it: positive = tailwind, negative = headwind.
func relative_wind() -> float:
	return wind * facing


func to_shot_parameters() -> ShotParameters:
	return ShotParameters.new(angle, power, wind, facing)


## Runs the real ProjectileSimulation; the impact is the descending crossing of the
## target's horizontal plane. The Lab never computes trajectories itself.
func simulate(params: BallisticParameters) -> BallisticResult:
	return ProjectileSimulation.simulate_to_plane(to_shot_parameters(), params, target_y(), true)


## impact_x - target_x, or NAN when the shot never reached the target plane.
func impact_error(result: BallisticResult) -> float:
	return result.impact_x - target_x() if result.hit_plane() else NAN


## Error measured along the shot direction: positive = long, negative = short.
func impact_error_along_shot(result: BallisticResult) -> float:
	return impact_error(result) * facing
