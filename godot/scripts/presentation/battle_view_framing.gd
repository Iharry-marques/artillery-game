class_name BattleViewFraming
extends RefCounted
## Camera framing math shared by the Lab and the sandbox (presentation only).
##
## Battle View shows exactly GameMetrics.battle_view_width_units horizontally,
## whatever the viewport resolution; the aspect ratio only changes how much
## vertical world space is visible.


## Camera zoom that makes viewport_width_px show visible_width_units.
static func zoom_for_width(viewport_width_px: float, visible_width_units: float) -> float:
	return viewport_width_px / (visible_width_units * WorldCanvas.PIXELS_PER_UNIT)


static func visible_width_units(viewport_width_px: float, zoom: float) -> float:
	return viewport_width_px / (zoom * WorldCanvas.PIXELS_PER_UNIT)


static func visible_height_units(viewport_height_px: float, zoom: float) -> float:
	return viewport_height_px / (zoom * WorldCanvas.PIXELS_PER_UNIT)


## Largest zoom that keeps a span (in units) fully visible.
static func zoom_to_fit(viewport_size_px: Vector2, span_units: Vector2) -> float:
	return minf(
		viewport_size_px.x / (span_units.x * WorldCanvas.PIXELS_PER_UNIT),
		viewport_size_px.y / (span_units.y * WorldCanvas.PIXELS_PER_UNIT)
	)
