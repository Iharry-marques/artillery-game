class_name TerrainMask
extends RefCounted
## Destructible terrain as an occupancy grid (DECISIONS D-025).
##
## World units (u), y grows downward, origin at the top-left corner of the map.
## Cell (col, row) covers [col*cell, (col+1)*cell) x [row*cell, (row+1)*cell).
## Anything outside the grid is empty. Overhangs and floating pieces are allowed:
## terrain has no gravity of its own.

var columns: int
var rows: int
var cell_size: float
## Incremented on every change so views know when to refresh.
var version: int = 0
var _cells: PackedByteArray


func _init(p_columns: int, p_rows: int, p_cell_size: float) -> void:
	columns = p_columns
	rows = p_rows
	cell_size = p_cell_size
	_cells = PackedByteArray()
	_cells.resize(columns * rows)


func width_units() -> float:
	return columns * cell_size


func height_units() -> float:
	return rows * cell_size


func is_solid(x: float, y: float) -> bool:
	return is_solid_cell(floori(x / cell_size), floori(y / cell_size))


func is_solid_cell(col: int, row: int) -> bool:
	if col < 0 or row < 0 or col >= columns or row >= rows:
		return false
	return _cells[row * columns + col] != 0


func set_cell(col: int, row: int, solid: bool) -> void:
	if col >= 0 and row >= 0 and col < columns and row < rows:
		_cells[row * columns + col] = 1 if solid else 0


func solid_cell_count() -> int:
	return _cells.count(1)


## Fills every column from its surface (world y of the top, per column) down to the bottom.
func fill_below_surface(surface_y: Callable) -> void:
	for col in columns:
		var top: float = surface_y.call((col + 0.5) * cell_size)
		for row in rows:
			_cells[row * columns + col] = 1 if (row + 0.5) * cell_size >= top else 0
	version += 1


## Marks the cells whose centres lie inside the rectangle as solid.
func fill_rect(rect_units: Rect2) -> void:
	_set_cells_in_rect(rect_units, true)
	version += 1


## Removes the cells whose centres lie inside the circle. Returns the changed cell
## region (empty if nothing changed).
func carve_circle(cx: float, cy: float, radius: float) -> Rect2i:
	var col_min: int = maxi(0, floori((cx - radius) / cell_size))
	var col_max: int = mini(columns - 1, floori((cx + radius) / cell_size))
	var row_min: int = maxi(0, floori((cy - radius) / cell_size))
	var row_max: int = mini(rows - 1, floori((cy + radius) / cell_size))
	var radius_squared: float = radius * radius
	var changed := false
	for row in range(row_min, row_max + 1):
		var dy: float = (row + 0.5) * cell_size - cy
		for col in range(col_min, col_max + 1):
			var dx: float = (col + 0.5) * cell_size - cx
			var index: int = row * columns + col
			if dx * dx + dy * dy <= radius_squared and _cells[index] != 0:
				_cells[index] = 0
				changed = true
	if not changed:
		return Rect2i()
	version += 1
	return Rect2i(col_min, row_min, col_max - col_min + 1, row_max - row_min + 1)


## Fraction along the segment (x0, y0) -> (x1, y1) where it first enters a solid
## cell, or -1 if it never does. Exact grid traversal (Amanatides-Woo), so no
## segment can tunnel through a cell however long it is. 0 if it starts inside.
func segment_hit(x0: float, y0: float, x1: float, y1: float) -> float:
	var col: int = floori(x0 / cell_size)
	var row: int = floori(y0 / cell_size)
	if is_solid_cell(col, row):
		return 0.0
	var dx: float = x1 - x0
	var dy: float = y1 - y0
	var step_col: int = 1 if dx > 0.0 else (-1 if dx < 0.0 else 0)
	var step_row: int = 1 if dy > 0.0 else (-1 if dy < 0.0 else 0)
	var t_max_x: float = INF
	var t_max_y: float = INF
	var t_delta_x: float = INF
	var t_delta_y: float = INF
	if step_col != 0:
		t_max_x = ((col + (1 if step_col > 0 else 0)) * cell_size - x0) / dx
		t_delta_x = cell_size / absf(dx)
	if step_row != 0:
		t_max_y = ((row + (1 if step_row > 0 else 0)) * cell_size - y0) / dy
		t_delta_y = cell_size / absf(dy)
	var end_col: int = floori(x1 / cell_size)
	var end_row: int = floori(y1 / cell_size)
	var remaining: int = absi(end_col - col) + absi(end_row - row) + 1
	while remaining > 0:
		remaining -= 1
		var t: float
		if t_max_x < t_max_y:
			col += step_col
			t = t_max_x
			t_max_x += t_delta_x
		else:
			row += step_row
			t = t_max_y
			t_max_y += t_delta_y
		if t > 1.0:
			return -1.0
		if is_solid_cell(col, row):
			return maxf(t, 0.0)
	return -1.0


## World y of the top of the first solid cell in the column of x, scanning down
## from world y `from_y` (inclusive). NAN if there is no solid cell below.
func ground_below(x: float, from_y: float) -> float:
	var col: int = floori(x / cell_size)
	if col < 0 or col >= columns:
		return NAN
	for row in range(maxi(0, floori(from_y / cell_size)), rows):
		if _cells[row * columns + col] != 0:
			return row * cell_size
	return NAN


func _set_cells_in_rect(rect_units: Rect2, solid: bool) -> void:
	for row in rows:
		var y: float = (row + 0.5) * cell_size
		if y < rect_units.position.y or y >= rect_units.end.y:
			continue
		for col in columns:
			var x: float = (col + 0.5) * cell_size
			if x >= rect_units.position.x and x < rect_units.end.x:
				_cells[row * columns + col] = 1 if solid else 0
