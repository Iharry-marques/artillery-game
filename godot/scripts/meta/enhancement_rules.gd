class_name EnhancementRules
extends RefCounted
## Strengthening bonuses and success odds (REFERENCE ESTIMATES inspired by the
## classic curve: easy early levels, steep falloff after +4; no real-money hooks).

const MAX_LEVEL: int = 12
## Chance multiplier for reaching level N (index = N).
const LEVEL_FACTOR: Array[float] = [1.0, 1.0, 0.85, 0.7, 0.55, 0.38, 0.26, 0.17, 0.11, 0.07, 0.045, 0.03, 0.02]
## Base chance contributed by one strengthen stone of level N (index = N).
const STONE_POWER: Array[float] = [0.0, 0.3, 0.55, 0.85, 1.2]
const MAX_STONES: int = 3
## Below this level a failed attempt never drops the item.
const SAFE_LEVEL: int = 3


## Stat bonus granted by `level` strengthening on `def`.
static func bonus(def: ItemDefinition, level: int) -> StatBlock:
	if level <= 0:
		return StatBlock.new()
	match def.kind:
		ItemDefinition.Kind.WEAPON:
			return StatBlock.make(3 * level, 0, 0, 0, roundi(def.stats.harm * 0.09 * level))
		ItemDefinition.Kind.CLOTHES, ItemDefinition.Kind.HAT:
			return StatBlock.make(0, 3 * level, 0, 0, 0, roundi(maxi(def.stats.armor, 4) * 0.12 * level))
	return StatBlock.new()


static func success_chance(target_level: int, stones: Array[ItemDefinition], charm_bonus: float) -> float:
	if target_level > MAX_LEVEL or stones.is_empty():
		return 0.0
	var power: float = 0.0
	for stone in stones:
		power += STONE_POWER[clampi(stone.stone_level, 0, STONE_POWER.size() - 1)]
	return clampf(power * LEVEL_FACTOR[target_level] + charm_bonus, 0.0, 1.0)


static func gold_cost(target_level: int) -> int:
	return 150 * target_level * target_level + 100


static func drops_on_failure(current_level: int, protected: bool) -> bool:
	return not protected and current_level >= SAFE_LEVEL
