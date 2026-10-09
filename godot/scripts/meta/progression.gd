class_name Progression
extends RefCounted
## Simple EXP curve (REFERENCE ESTIMATE): next level needs 100 + 60 x (level - 1)
## + 20 x (level - 1)^2 EXP. Not the historical table.

const MAX_LEVEL: int = 40


static func exp_to_next(level: int) -> int:
	var n: int = level - 1
	return 100 + 60 * n + 20 * n * n


## Adds EXP and returns how many levels were gained.
static func add_exp(profile: PlayerProfile, amount: int) -> int:
	var gained: int = 0
	profile.exp += maxi(0, amount)
	while profile.level < MAX_LEVEL and profile.exp >= exp_to_next(profile.level):
		profile.exp -= exp_to_next(profile.level)
		profile.level += 1
		gained += 1
	if profile.level >= MAX_LEVEL:
		profile.exp = 0
	return gained
