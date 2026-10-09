class_name ProjectileView
extends Node2D
## Plays back the current flight (presentation only): the projectile and its trail
## come from the BallisticResult samples at the match's playback time.

const PROJECTILE_RADIUS_UNITS: float = 0.08
const TRAIL_COLOR: Color = Color(1.0, 0.95, 0.7, 0.45)
const PROJECTILE_COLOR: Color = Color(1.0, 0.95, 0.75)
const TRAIL_WIDTH_PX: float = 2.0

var combat: CombatMatch


func _process(_delta: float) -> void:
	queue_redraw()


func current_position_units() -> Vector2:
	return TrajectoryPlayback.position_at(combat.flight, combat.flight_elapsed)


func _draw() -> void:
	if combat == null or combat.phase != CombatMatch.Phase.FLIGHT or combat.flight == null:
		return
	var flight: BallisticResult = combat.flight
	var points := PackedVector2Array()
	for i in flight.samples.size():
		if flight.sample_times[i] > combat.flight_elapsed:
			break
		points.append(WorldCanvas.units_to_canvas(flight.samples[i]))
	var head: Vector2 = WorldCanvas.units_to_canvas(current_position_units())
	points.append(head)
	if points.size() >= 2:
		draw_polyline(points, TRAIL_COLOR, TRAIL_WIDTH_PX / WorldCanvas.screen_scale(self), true)
	draw_circle(head, PROJECTILE_RADIUS_UNITS * WorldCanvas.PIXELS_PER_UNIT, PROJECTILE_COLOR)
