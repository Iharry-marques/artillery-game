class_name RewardCalculator
extends RefCounted
## Battle rewards (REFERENCE ESTIMATES, tuned for a satisfying local loop):
## PvP win: EXP 120 + 15 x level, Gold 300 + 30 x level; PvP loss: EXP 50 + 5 x level,
## Gold 120. PvE: enemy EXP/Gold of the kills plus the clear bonus, scaled by
## difficulty. Leaving a battle early gives nothing. Flip cards: pick 1 of 4.

const CARD_COUNT: int = 4
const PVP_CARD_POOL: Array[Dictionary] = [
	{"id": &"stone_1", "qty": 2, "weight": 30}, {"id": &"stone_2", "qty": 1, "weight": 14},
	{"id": &"item_heal", "qty": 2, "weight": 20}, {"id": &"elem_attack", "qty": 1, "weight": 10},
	{"id": &"elem_luck", "qty": 1, "weight": 10}, {"id": &"charm_luck", "qty": 1, "weight": 6},
	{"id": &"gold", "qty": 500, "weight": 25},
]


static func battle_reward(outcome: BattleOutcome, level: int, content: ContentDatabase) -> Reward:
	if outcome.surrendered:
		return Reward.new()
	match outcome.mode:
		BattleSetup.Mode.PVP:
			if outcome.victory:
				return Reward.make(120 + 15 * level, 300 + 30 * level)
			return Reward.make(50 + 5 * level, 120)
		BattleSetup.Mode.PVE:
			var scale: float = PveInstanceDefinition.REWARD_SCALE[clampi(outcome.difficulty, 0, 2)]
			var reward := Reward.make(roundi(outcome.enemy_exp * scale), roundi(outcome.enemy_gold * scale))
			var instance: PveInstanceDefinition = content.instance(outcome.instance_id)
			if outcome.victory and instance != null:
				reward.exp += roundi(instance.clear_reward.exp * scale)
				reward.gold += roundi(instance.clear_reward.gold * scale)
			return reward
	return Reward.make(30, 50)


## Four face-down cards drawn from the pool with the profile RNG.
static func draw_cards(outcome: BattleOutcome, content: ContentDatabase, rng: RandomNumberGenerator) -> Array[Reward]:
	var pool: Array[Dictionary] = PVP_CARD_POOL
	if outcome.mode == BattleSetup.Mode.PVE:
		var instance: PveInstanceDefinition = content.instance(outcome.instance_id)
		if instance != null:
			pool = instance.loot
	var cards: Array[Reward] = []
	for i in CARD_COUNT:
		cards.append(_pick(pool, rng))
	return cards


static func _pick(pool: Array[Dictionary], rng: RandomNumberGenerator) -> Reward:
	var total: int = 0
	for entry in pool:
		total += DataReader.get_int(entry, "weight", 1)
	var roll: int = rng.randi_range(1, maxi(1, total))
	for entry in pool:
		roll -= DataReader.get_int(entry, "weight", 1)
		if roll <= 0:
			var id: StringName = entry["id"]
			var qty: int = DataReader.get_int(entry, "qty", 1)
			if id == &"gold":
				return Reward.make(0, qty)
			return Reward.make(0, 0, [Reward.item(id, qty)])
	return Reward.make(0, 100)
