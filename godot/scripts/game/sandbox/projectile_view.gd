class_name ProjectileView
extends Node2D
## Plays back the current flight (presentation only): the shell sprite and its
## fading trail come from the BallisticResult samples at the match's playback time.

const TRAIL_SECONDS: float = 0.7
const TRAIL_WIDTH_PX: float = 7.0
const TRAIL_COLOR: Color = Color(1.0, 0.92, 0.6)
## Time step used to estimate the heading for the sprite rotation.
const HEADING_DT: float = 1.0 / 60.0

var combat: CombatMatch
var art: CharacterProxyArt


func _process(_delta: float) -> void:
	queue_redraw()


func current_position_units() -> Vector2:
	return TrajectoryPlayback.position_at(combat.flight, combat.flight_elapsed)


func _draw() -> void:
	if combat == null or combat.phase != CombatMatch.Phase.FLIGHT or combat.flight == null:
		return
	var flight: BallisticResult = combat.flight
	var now: float = combat.flight_elapsed
	var scale_px: float = WorldCanvas.screen_scale(self)
	var head: Vector2 = WorldCanvas.units_to_canvas(current_position_units())

	var previous: Vector2 = head
	for i in range(flight.samples.size() - 1, -1, -1):
		var age: float = now - flight.sample_times[i]
		if age < 0.0:
			continue
		if age > TRAIL_SECONDS:
			break
		var point: Vector2 = WorldCanvas.units_to_canvas(flight.samples[i])
		var fade: float = 1.0 - age / TRAIL_SECONDS
		draw_line(previous, point, TRAIL_COLOR * Color(1, 1, 1, 0.55 * fade), TRAIL_WIDTH_PX * fade / scale_px)
		previous = point

	var before: Vector2 = WorldCanvas.units_to_canvas(TrajectoryPlayback.position_at(flight, maxf(0.0, now - HEADING_DT)))
	var heading: float = (head - before).angle() if head.distance_to(before) > 0.0001 else 0.0
	var sprite_scale: float = art.sprite_scale()
	draw_set_transform(head, heading, Vector2.ONE * sprite_scale)
	var key: StringName = combat.active().loadout.projectile_art if combat.active().loadout != null else &"shell"
	var texture: Texture2D = art.projectile_texture(key)
	draw_texture(texture, -texture.get_size() * 0.5 if key != &"shell" else -art.projectile_center_px)
	draw_set_transform_matrix(Transform2D.IDENTITY)
