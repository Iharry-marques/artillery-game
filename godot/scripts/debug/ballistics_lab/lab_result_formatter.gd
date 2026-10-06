class_name LabResultFormatter
extends RefCounted
## Builds the compact plain-text read-out of the Ballistics Lab (monospace).


static func format(
	setup: LabShotSetup,
	result: BallisticResult,
	metrics: GameMetrics,
	camera_mode: LabDebugCamera.Mode,
	visible_units: Vector2
) -> String:
	var lines: PackedStringArray = []
	var angle_flag: String = "  OUTSIDE 0-90 (OQ-22)" if LabAimingTools.is_outside_normal_range(setup.angle) else ""
	lines.append("SHOT   angle %.3f deg  power %.3f%s" % [setup.angle, setup.power, angle_flag])
	lines.append("       wind %+.2f world, %s, facing %s" % [
		setup.wind, _relative_wind_text(setup.relative_wind()), "right" if setup.facing > 0 else "left"
	])
	lines.append("       launch speed %.4f u/s" % result.launch_speed)
	lines.append("TARGET x %.4f  y %+.4f (%s)" % [setup.target_x(), setup.target_y(), _height_text(setup.height_above_shooter())])
	lines.append("RESULT %s" % result.termination_name())
	if result.hit_plane():
		var along: float = setup.impact_error_along_shot(result)
		lines.append("       impact x %.4f  error %+.4f u (%s)" % [result.impact_x, setup.impact_error(result), "long" if along > 0.0 else "short"])
	else:
		lines.append("       NO IMPACT on the target plane")
	lines.append("       flight time %.4f s  [time scale PROVISIONAL]" % result.flight_time)
	lines.append("       apex x %.4f  y %.4f" % [result.apex_x, result.apex_y])
	lines.append("       max height %.4f u above launch" % -result.apex_y)
	lines.append("       steps %d (dt %.6f s)" % [result.step_count, metrics.time_step])
	lines.append("MODEL  K %.6f u, wind ratio %.6f  [CALIBRATED]" % [metrics.ballistic_k, metrics.wind_accel_ratio])
	lines.append("       gravity %.4f u/s^2  [PROVISIONAL]" % metrics.gravity)
	lines.append("RULE   Full Throw here: %.3f deg @ power %s (evidence)" % [
		BallisticEvidence.full_throw_angle(setup.distance, setup.relative_wind()), BallisticEvidence.FULL_THROW_POWER
	])
	lines.append("VIEW   %s  %.3f x %.3f u" % [LabDebugCamera.mode_name(camera_mode), visible_units.x, visible_units.y])
	return "\n".join(lines)


static func _relative_wind_text(relative_wind: float) -> String:
	if relative_wind > 0.0:
		return "tailwind %.2f" % relative_wind
	if relative_wind < 0.0:
		return "headwind %.2f" % -relative_wind
	return "calm"


static func _height_text(height: float) -> String:
	if height > 0.0:
		return "%.2f u ABOVE shooter" % height
	if height < 0.0:
		return "%.2f u BELOW shooter" % -height
	return "level with shooter"
