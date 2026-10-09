class_name BallisticResult
extends RefCounted
## Outcome of one simulated shot.

enum Termination {
	## Crossed the reference plane while descending, after having risen above it.
	IMPACT_PLANE,
	## Reached BallisticParameters.max_time without terminating.
	MAX_TIME,
	## Started moving down without ever rising above the reference plane.
	NO_ASCENT,
	## A BallisticCollisionQuery reported a hit (see `hit`).
	COLLISION,
}

var termination: Termination
var launch_speed: float
## Plane crossing when hit_plane(); otherwise the last simulated position.
var impact_x: float
var impact_y: float
## Time of the plane crossing, or of the last simulated state when there was no impact.
var flight_time: float
var apex_x: float
var apex_y: float
var apex_time: float
var step_count: int
## Positions at every full step plus the terminal point. Single precision; for display only.
var samples: PackedVector2Array = PackedVector2Array()
## Simulation time (s) of each entry in samples, same length. Used for playback.
var sample_times: PackedFloat64Array = PackedFloat64Array()
## Set when termination == COLLISION.
var hit: BallisticHit


func hit_plane() -> bool:
	return termination == Termination.IMPACT_PLANE


func termination_name() -> String:
	return Termination.keys()[termination]
