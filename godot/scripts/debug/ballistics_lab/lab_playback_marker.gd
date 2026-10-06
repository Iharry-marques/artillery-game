class_name LabPlaybackMarker
extends Node2D
## Presentation-only marker that replays a precomputed BallisticResult in
## simulation time (scaled by playback_speed). It never simulates physics.

const COLOR: Color = Color(1.0, 1.0, 1.0)
const RADIUS_PX: float = 6.0

var playback_speed: float = 1.0
var _result: BallisticResult
var _time: float = 0.0
var _playing: bool = false


func load_result(result: BallisticResult, autoplay: bool) -> void:
	_result = result
	_time = 0.0
	_playing = autoplay
	_sync_position()


func play() -> void:
	if _result != null and _time >= TrajectoryPlayback.end_time(_result):
		_time = 0.0
	_playing = true


func pause() -> void:
	_playing = false


func restart() -> void:
	_time = 0.0
	_playing = true
	_sync_position()


## Jumps to a simulation time and pauses there.
func seek(time: float) -> void:
	_time = clampf(time, 0.0, TrajectoryPlayback.end_time(_result)) if _result != null else 0.0
	_playing = false
	_sync_position()


func current_time() -> float:
	return _time


func is_playing() -> bool:
	return _playing


func position_units() -> Vector2:
	return TrajectoryPlayback.position_at(_result, _time) if _result != null else Vector2.ZERO


func _process(delta: float) -> void:
	if _playing and _result != null:
		var end: float = TrajectoryPlayback.end_time(_result)
		_time = minf(_time + delta * playback_speed, end)
		if _time >= end:
			_playing = false
		_sync_position()
	queue_redraw()


func _sync_position() -> void:
	position = LabView.units_to_canvas(position_units())


func _draw() -> void:
	var scale: float = LabView.screen_scale(self)
	draw_circle(Vector2.ZERO, RADIUS_PX / scale, COLOR)
	draw_arc(Vector2.ZERO, (RADIUS_PX + 3.0) / scale, 0.0, TAU, 24, COLOR * Color(1, 1, 1, 0.5), 1.5 / scale)
