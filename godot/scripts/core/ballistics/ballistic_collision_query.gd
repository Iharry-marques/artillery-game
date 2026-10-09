class_name BallisticCollisionQuery
extends RefCounted
## World collision seen by ProjectileSimulation.simulate_with_collisions().
##
## The simulation produces the trajectory; the query only answers "what does the
## straight segment between two consecutive states hit first?". This keeps the
## ballistic core independent of terrain, characters and map bounds.


## First hit on the segment (x0, y0) -> (x1, y1), or null if nothing is hit.
func first_hit(_x0: float, _y0: float, _x1: float, _y1: float) -> BallisticHit:
	push_error("BallisticCollisionQuery.first_hit() must be overridden.")
	return null
