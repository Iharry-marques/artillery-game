class_name TrajectoryPlayback
extends RefCounted
## Presentation-only playback of a precomputed BallisticResult.
##
## Positions come from the result's samples and their simulation times; between
## two samples the marker moves along the straight chord. With dt = 1/60 s and the
## provisional gravity the chord stays within ~2.5e-4 u of the true path. No
## physics is evaluated here.


## Sample position at simulation time `time` (clamped to the recorded range).
static func position_at(result: BallisticResult, time: float) -> Vector2:
	var times: PackedFloat64Array = result.sample_times
	if times.is_empty():
		return Vector2.ZERO
	if time <= times[0]:
		return result.samples[0]
	var last: int = times.size() - 1
	if time >= times[last]:
		return result.samples[last]
	var i: int = times.bsearch(time)
	var t0: float = times[i - 1]
	var t1: float = times[i]
	var weight: float = (time - t0) / (t1 - t0)
	return result.samples[i - 1].lerp(result.samples[i], weight)


static func end_time(result: BallisticResult) -> float:
	var times: PackedFloat64Array = result.sample_times
	return 0.0 if times.is_empty() else times[times.size() - 1]
