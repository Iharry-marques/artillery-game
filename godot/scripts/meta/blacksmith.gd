class_name Blacksmith
extends RefCounted
## Blacksmith operations on the local profile (REFERENCE ESTIMATE numbers; no
## real-money mechanics). Every random roll uses the profile's deterministic RNG.

const COMPOSE_POINTS: int = 3
const COMPOSE_CAP: int = 30
const COMPOSE_GOLD: int = 100
const FUSE_INPUT: int = 4
const FUSE_CHANCE: float = 0.85
const FUSE_MAX_RESULT_LEVEL: int = 4
const TRANSFER_GOLD: int = 2000


class Preview:
	extends RefCounted
	var error: String = ""
	var chance: float = 0.0
	var cost: int = 0
	var current_level: int = 0
	var next_level: int = 0
	var gain: StatBlock = StatBlock.new()
	var drops_on_failure: bool = false


class Outcome:
	extends RefCounted
	var ok: bool = false
	var success: bool = false
	var message: String = ""
	var new_level: int = 0


static func preview_strengthen(profile: PlayerProfile, content: ContentDatabase, uid: int, stone_ids: Array[StringName], use_charm: bool, use_guard: bool) -> Preview:
	var preview := Preview.new()
	var item: ItemInstance = profile.find_item(uid)
	if item == null:
		preview.error = "Select an equipment piece"
		return preview
	var def: ItemDefinition = content.item(item.def_id)
	if not def.can_strengthen():
		preview.error = "Only weapons, clothes and hats can be strengthened"
		return preview
	preview.current_level = item.enhance_level
	preview.next_level = item.enhance_level + 1
	if preview.next_level > EnhancementRules.MAX_LEVEL:
		preview.error = "Already at the maximum level (+%d)" % EnhancementRules.MAX_LEVEL
		return preview
	var stones: Array[ItemDefinition] = []
	for stone_id in stone_ids:
		stones.append(content.item(stone_id))
	if stones.is_empty():
		preview.error = "Add strengthen stones"
	elif stones.size() > EnhancementRules.MAX_STONES:
		preview.error = "At most %d stones" % EnhancementRules.MAX_STONES
	elif not _has_materials(profile, stone_ids, use_charm, use_guard):
		preview.error = "Not enough materials in the bag"
	var charm_bonus: float = content.item(&"charm_luck").charm_bonus if use_charm else 0.0
	preview.chance = EnhancementRules.success_chance(preview.next_level, stones, charm_bonus)
	preview.cost = EnhancementRules.gold_cost(preview.next_level)
	preview.gain = EnhancementRules.bonus(def, preview.next_level).plus(EnhancementRules.bonus(def, preview.current_level).scaled(-1.0))
	preview.drops_on_failure = EnhancementRules.drops_on_failure(item.enhance_level, use_guard)
	if preview.error == "" and not profile.wallet.can_afford(CurrencyWallet.Currency.GOLD, preview.cost):
		preview.error = "Not enough gold"
	return preview


static func strengthen(profile: PlayerProfile, content: ContentDatabase, uid: int, stone_ids: Array[StringName], use_charm: bool, use_guard: bool) -> Outcome:
	var outcome := Outcome.new()
	var preview: Preview = preview_strengthen(profile, content, uid, stone_ids, use_charm, use_guard)
	if preview.error != "":
		outcome.message = preview.error
		return outcome
	var item: ItemInstance = profile.find_item(uid)
	profile.wallet.spend(CurrencyWallet.Currency.GOLD, preview.cost)
	for stone_id in stone_ids:
		profile.inventory.remove_quantity(stone_id, 1)
	if use_charm:
		profile.inventory.remove_quantity(&"charm_luck", 1)
	if use_guard:
		profile.inventory.remove_quantity(&"charm_guard", 1)
	profile.bump_counter(&"strengthen_attempts")
	outcome.ok = true
	outcome.success = profile.next_rng().randf() < preview.chance
	if outcome.success:
		item.enhance_level = preview.next_level
		item.bound = true
		outcome.message = "Success! Now +%d." % item.enhance_level
	elif preview.drops_on_failure:
		item.enhance_level -= 1
		outcome.message = "Failed... the item dropped to +%d." % item.enhance_level
	else:
		outcome.message = "Failed. The item kept +%d." % item.enhance_level
	outcome.new_level = item.enhance_level
	return outcome


static func compose(profile: PlayerProfile, content: ContentDatabase, uid: int, element_id: StringName) -> Outcome:
	var outcome := Outcome.new()
	var item: ItemInstance = profile.find_item(uid)
	var element: ItemDefinition = content.item(element_id)
	if item == null or not content.item(item.def_id).is_equipment():
		outcome.message = "Select an equipment piece"
		return outcome
	if element == null or element.kind != ItemDefinition.Kind.ELEMENT_STONE or profile.inventory.count(element_id) <= 0:
		outcome.message = "Select an element stone you own"
		return outcome
	var current: int = item.composed.get_stat(element.element)
	if current >= COMPOSE_CAP:
		outcome.message = "%s is already at the composition cap (+%d)" % [String(element.element).capitalize(), COMPOSE_CAP]
		return outcome
	if not profile.wallet.spend(CurrencyWallet.Currency.GOLD, COMPOSE_GOLD):
		outcome.message = "Not enough gold"
		return outcome
	profile.inventory.remove_quantity(element_id, 1)
	item.composed.set(element.element, mini(COMPOSE_CAP, current + COMPOSE_POINTS))
	outcome.ok = true
	outcome.success = true
	outcome.message = "%s +%d composed." % [String(element.element).capitalize(), COMPOSE_POINTS]
	return outcome


static func fuse(profile: PlayerProfile, content: ContentDatabase, stone_level: int) -> Outcome:
	var outcome := Outcome.new()
	var input_id := StringName("stone_%d" % stone_level)
	var output_id := StringName("stone_%d" % (stone_level + 1))
	if stone_level < 1 or stone_level + 1 > FUSE_MAX_RESULT_LEVEL or content.item(output_id) == null:
		outcome.message = "Only Lv1-Lv3 stones can be fused"
		return outcome
	if profile.inventory.count(input_id) < FUSE_INPUT:
		outcome.message = "Need %d x Strengthen Stone Lv%d" % [FUSE_INPUT, stone_level]
		return outcome
	var cost: int = fuse_cost(stone_level)
	if not profile.wallet.spend(CurrencyWallet.Currency.GOLD, cost):
		outcome.message = "Not enough gold"
		return outcome
	profile.inventory.remove_quantity(input_id, FUSE_INPUT)
	outcome.ok = true
	outcome.success = profile.next_rng().randf() < FUSE_CHANCE
	if outcome.success:
		profile.inventory.add(content.item(output_id), 1, profile.uid_allocator())
		outcome.message = "Fusion succeeded: 1 x Strengthen Stone Lv%d." % (stone_level + 1)
	else:
		outcome.message = "Fusion failed. The stones crumbled."
	return outcome


static func fuse_cost(stone_level: int) -> int:
	return 300 * stone_level


static func transfer(profile: PlayerProfile, content: ContentDatabase, from_uid: int, to_uid: int) -> Outcome:
	var outcome := Outcome.new()
	var source: ItemInstance = profile.find_item(from_uid)
	var target: ItemInstance = profile.find_item(to_uid)
	if source == null or target == null or from_uid == to_uid:
		outcome.message = "Select two different items"
		return outcome
	var source_def: ItemDefinition = content.item(source.def_id)
	var target_def: ItemDefinition = content.item(target.def_id)
	if source_def.slot() != target_def.slot() or not source_def.can_strengthen():
		outcome.message = "Both items must be of the same type (weapon, clothes or hat)"
		return outcome
	if source.enhance_level <= target.enhance_level:
		outcome.message = "The source must be strengthened higher than the target"
		return outcome
	if not profile.wallet.spend(CurrencyWallet.Currency.GOLD, TRANSFER_GOLD):
		outcome.message = "Not enough gold"
		return outcome
	target.enhance_level = source.enhance_level
	source.enhance_level = 0
	target.bound = true
	outcome.ok = true
	outcome.success = true
	outcome.new_level = target.enhance_level
	outcome.message = "Transferred +%d to %s." % [target.enhance_level, target_def.display_name]
	return outcome


static func _has_materials(profile: PlayerProfile, stone_ids: Array[StringName], use_charm: bool, use_guard: bool) -> bool:
	var needed: Dictionary = {}
	for stone_id in stone_ids:
		var current: int = needed.get(stone_id, 0)
		needed[stone_id] = current + 1
	if use_charm:
		needed[&"charm_luck"] = 1
	if use_guard:
		needed[&"charm_guard"] = 1
	for id: StringName in needed:
		var amount: int = needed[id]
		if profile.inventory.count(id) < amount:
			return false
	return true
