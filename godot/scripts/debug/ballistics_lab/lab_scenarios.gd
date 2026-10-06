class_name LabScenarios
extends RefCounted
## Manual verification scenarios (docs/BALLISTICS_LAB.md). Full Throw angles come
## from the evidence rule, never from hand-typed numbers.

const DEFAULT_ID: String = "A"
const IDS: Array[String] = ["A", "B", "C", "D", "E", "F"]
## Elevation experiment (OQ-20): no known player rule yet.
const ELEVATION_DISTANCE: float = 5.0
const ELEVATION_OFFSET: float = 2.0


static func title(id: String) -> String:
	match id:
		"A":
			return "Classic Full Throw: D 10, angle 80, power 95, no wind"
		"B":
			return "Medium Full Throw: D 5, angle 85, power 95, no wind"
		"C":
			return "Full Throw, headwind 0.5: rule angle"
		"D":
			return "Full Throw, tailwind 0.5: rule angle"
		"E":
			return "Elevation: D 5, target 2 u ABOVE (y = -2), Full Throw angle, OQ-20"
		"F":
			return "Elevation: D 5, target 2 u BELOW (y = +2), Full Throw angle, OQ-20"
	return "Unknown scenario"


static func build(id: String) -> LabShotSetup:
	match id:
		"B":
			return _full_throw(5.0, 0.0, 0.0)
		"C":
			return _full_throw(10.0, 0.0, -0.5)
		"D":
			return _full_throw(10.0, 0.0, 0.5)
		"E":
			return _full_throw(ELEVATION_DISTANCE, -ELEVATION_OFFSET, 0.0)
		"F":
			return _full_throw(ELEVATION_DISTANCE, ELEVATION_OFFSET, 0.0)
	return _full_throw(10.0, 0.0, 0.0)


static func _full_throw(distance: float, vertical_offset: float, wind: float) -> LabShotSetup:
	var setup := LabShotSetup.new(distance, vertical_offset, 0.0, 0.0, wind, 1)
	LabAimingTools.apply_full_throw(setup)
	return setup
