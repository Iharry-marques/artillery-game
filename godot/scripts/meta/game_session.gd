class_name GameSession
extends RefCounted
## The running local game: profile, content, rooms, pending battle and the last
## result. A static singleton (survives scene changes, works in headless tests).
## Every mutating operation autosaves to user://.

const SAVE_PATH: String = "user://reference_clone_save.json"
const STARTER_WEAPON: StringName = &"wpn_sunburst"
const GENERATED_ROOMS: int = 9
const NPC_WEAPONS: Array[StringName] = [&"wpn_sunburst", &"wpn_boulder", &"wpn_spark"]
const NPC_AIM_ERROR_DEGREES: float = 1.8
const ALLY_AIM_ERROR_DEGREES: float = 1.5

static var _instance: GameSession

var content: ContentDatabase
var rules: CombatRules
var save_path: String
var profile: PlayerProfile
var rooms: Array[RoomState] = []
var current_room: RoomState
var pending_battle: BattleSetup
var last_outcome: BattleOutcome
var last_reward: Reward
var last_levels_gained: int = 0
var last_cards: Array[Reward] = []
var card_claimed: int = -1
var selected_instance: StringName = &"sprout_hollow"
var selected_difficulty: int = 0
var party_with_ally: bool = true
var _room_counter: int = 100


static func get_instance() -> GameSession:
	if _instance == null:
		_instance = GameSession.new(SAVE_PATH)
	return _instance


## Tests: a fresh session bound to its own save file.
static func replace_instance(session: GameSession) -> void:
	_instance = session


func _init(p_save_path: String = SAVE_PATH) -> void:
	save_path = p_save_path
	content = ContentCatalog.shared()
	rules = CombatRules.load_default()
	load_save()


# --- Profile and persistence -------------------------------------------------------------


func has_profile() -> bool:
	return profile != null


func load_save() -> bool:
	profile = SaveService.read(save_path)
	return profile != null


func save() -> void:
	if profile != null:
		SaveService.write(save_path, profile)


func delete_save() -> void:
	SaveService.delete(save_path)
	profile = null
	current_room = null
	pending_battle = null
	last_outcome = null


func create_profile(nickname: String, outfit: int) -> PlayerProfile:
	profile = PlayerProfile.new()
	profile.nickname = nickname.strip_edges() if nickname.strip_edges() != "" else "Player"
	profile.outfit = outfit
	profile.wallet.gold = content.starter_wallet.gold
	profile.wallet.coupons = content.starter_wallet.coupons
	profile.wallet.vouchers = content.starter_wallet.vouchers
	for item_id in content.starter_equipment:
		profile.inventory.add(content.item(item_id), 1, profile.uid_allocator())
		var item: ItemInstance = profile.inventory.items[profile.inventory.items.size() - 1]
		profile.equipment.equip(profile.inventory, content, item.uid, profile.level)
	for entry in content.starter_bag:
		var id: StringName = entry["id"]
		profile.inventory.add(content.item(id), DataReader.get_int(entry, "qty", 1), profile.uid_allocator())
	for mail in content.welcome_mails:
		profile.mails.append(MailMessage.from_dict(mail.to_dict()))
	for quest in content.quests:
		profile.quests[quest.id] = {"progress": 0, "claimed": false}
	save()
	return profile


func stats() -> CharacterStats:
	return CharacterStats.compute(profile, content)


## Adds a reward. Items that do not fit go to the mailbox. Returns levels gained.
func grant(reward: Reward) -> int:
	profile.wallet.add(CurrencyWallet.Currency.GOLD, reward.gold)
	profile.wallet.add(CurrencyWallet.Currency.COUPONS, reward.coupons)
	profile.wallet.add(CurrencyWallet.Currency.VOUCHERS, reward.vouchers)
	var overflow: Array[Dictionary] = []
	for entry in reward.items:
		var id: StringName = entry["id"]
		var qty: int = DataReader.get_int(entry, "qty", 1)
		var def: ItemDefinition = content.item(id)
		if def != null and not profile.inventory.add(def, qty, profile.uid_allocator()):
			overflow.append(Reward.item(id, qty))
	if not overflow.is_empty():
		var mail := MailMessage.make(StringName("mail_overflow_%d" % profile.allocate_uid()), "Items from a full bag",
			"Your bag was full, so these items were sent here.", Reward.make(0, 0, overflow))
		profile.mails.append(mail)
	var levels: int = Progression.add_exp(profile, reward.exp)
	if levels > 0:
		record(&"level_reached", 0)
	return levels


# --- Quests and mail ---------------------------------------------------------------------


## Advances quests listening to `event`. level_reached tracks the current level.
func record(event: StringName, amount: int = 1) -> void:
	for quest in content.quests:
		if quest.event != event:
			continue
		var state: Dictionary = quest_state(quest.id)
		var progress: int = state["progress"]
		progress = profile.level if event == &"level_reached" else progress + amount
		state["progress"] = mini(progress, quest.target)
		profile.quests[quest.id] = state


func quest_state(id: StringName) -> Dictionary:
	var state: Dictionary = profile.quests.get(id, {"progress": 0, "claimed": false})
	return state


func quest_complete(quest: QuestDefinition) -> bool:
	var progress: int = quest_state(quest.id)["progress"]
	return progress >= quest.target


func claimable_quests() -> int:
	var count: int = 0
	for quest in content.quests:
		var claimed: bool = quest_state(quest.id)["claimed"]
		if quest_complete(quest) and not claimed:
			count += 1
	return count


func claim_quest(id: StringName) -> String:
	var quest: QuestDefinition = content.quest(id)
	if quest == null:
		return "Unknown quest"
	var state: Dictionary = quest_state(id)
	var claimed: bool = state["claimed"]
	if claimed:
		return "Already claimed"
	if not quest_complete(quest):
		return "Not completed yet"
	state["claimed"] = true
	profile.quests[id] = state
	grant(quest.reward)
	save()
	return ""


func unread_mails() -> int:
	var count: int = 0
	for mail in profile.mails:
		if not mail.read or mail.has_unclaimed_attachment():
			count += 1
	return count


func claim_mail(mail: MailMessage) -> String:
	mail.read = true
	if not mail.has_unclaimed_attachment():
		save()
		return "Nothing to claim"
	mail.claimed = true
	grant(mail.attachment)
	save()
	return ""


# --- Bag, equipment, shop, blacksmith ---------------------------------------------------


func equip(uid: int) -> String:
	var item: ItemInstance = profile.inventory.find(uid)
	var error: String = profile.equipment.equip(profile.inventory, content, uid, profile.level)
	if error == "" and item != null:
		var def: ItemDefinition = content.item(item.def_id)
		if def.kind == ItemDefinition.Kind.WEAPON and def.id != STARTER_WEAPON:
			record(&"equip_new_weapon")
		save()
	return error


func unequip(slot: ItemDefinition.Slot) -> String:
	var error: String = profile.equipment.unequip(profile.inventory, slot)
	if error == "":
		save()
	return error


## Opens a gift box. Returns an error or "".
func use_item(uid: int) -> String:
	var item: ItemInstance = profile.inventory.find(uid)
	if item == null:
		return "Item not found"
	var def: ItemDefinition = content.item(item.def_id)
	if def.kind != ItemDefinition.Kind.BOX:
		return "This item is used in battle or at the Blacksmith"
	profile.inventory.remove_quantity(def.id, 1)
	grant(Reward.make(0, 0, def.box_contents))
	save()
	return ""


func sell(uid: int) -> int:
	var gold: int = ShopService.sell(profile, content, uid)
	if gold >= 0:
		save()
	return gold


func buy(listing: ShopListing, count: int = 1) -> String:
	var error: String = ShopService.buy(profile, content, listing, count)
	if error == "":
		record(&"shop_purchase")
		save()
	return error


func strengthen(uid: int, stones: Array[StringName], use_charm: bool, use_guard: bool) -> Blacksmith.Outcome:
	var outcome: Blacksmith.Outcome = Blacksmith.strengthen(profile, content, uid, stones, use_charm, use_guard)
	if outcome.success:
		record(&"strengthen_success")
	if outcome.ok:
		save()
	return outcome


func compose(uid: int, element_id: StringName) -> Blacksmith.Outcome:
	var outcome: Blacksmith.Outcome = Blacksmith.compose(profile, content, uid, element_id)
	if outcome.ok:
		save()
	return outcome


func fuse(stone_level: int) -> Blacksmith.Outcome:
	var outcome: Blacksmith.Outcome = Blacksmith.fuse(profile, content, stone_level)
	if outcome.ok:
		save()
	return outcome


func transfer(from_uid: int, to_uid: int) -> Blacksmith.Outcome:
	var outcome: Blacksmith.Outcome = Blacksmith.transfer(profile, content, from_uid, to_uid)
	if outcome.ok:
		save()
	return outcome


# --- Game Hall --------------------------------------------------------------------------


## Regenerates the simulated room list.
func refresh_rooms() -> void:
	rooms.clear()
	var rng: RandomNumberGenerator = profile.next_rng()
	for i in GENERATED_ROOMS:
		var room := RoomState.new()
		_room_counter += 1
		room.id = _room_counter
		room.room_name = content.room_names[rng.randi_range(0, content.room_names.size() - 1)]
		room.mode = RoomState.Mode.DUEL if rng.randf() < 0.6 else RoomState.Mode.TEAM
		room.map_id = content.pvp_maps[rng.randi_range(0, content.pvp_maps.size() - 1)]
		room.locked = rng.randf() < 0.18
		room.state = RoomState.State.PLAYING if rng.randf() < 0.25 else RoomState.State.WAITING
		var occupants: int = rng.randi_range(1, room.capacity() - (0 if room.state == RoomState.State.PLAYING else 1))
		for j in occupants:
			var member: RoomState.Member = _npc_member(rng, j % 2, j == 0)
			room.add_member(member)
		rooms.append(room)


func create_room(room_name: String, mode: RoomState.Mode, map_id: StringName) -> RoomState:
	var room := RoomState.new()
	_room_counter += 1
	room.id = _room_counter
	room.room_name = room_name.strip_edges() if room_name.strip_edges() != "" else "%s's room" % profile.nickname
	room.mode = mode
	room.map_id = map_id
	var me: RoomState.Member = _player_member()
	me.is_host = true
	me.ready = true
	room.add_member(me)
	current_room = room
	return room


func join_room(room: RoomState) -> String:
	if room.state != RoomState.State.WAITING:
		return "This room is already playing"
	if room.locked:
		return "This room is password protected"
	if room.is_full():
		return "This room is full"
	var me: RoomState.Member = _player_member()
	me.team = room.free_team()
	room.add_member(me)
	current_room = room
	return ""


func fill_room_with_ai() -> void:
	var rng: RandomNumberGenerator = profile.next_rng()
	while not current_room.is_full():
		var member: RoomState.Member = _npc_member(rng, current_room.free_team(), false)
		member.ready = true
		current_room.add_member(member)


func leave_room() -> void:
	if current_room != null:
		var others: Array[RoomState.Member] = []
		for member in current_room.members:
			if not member.is_player:
				others.append(member)
		current_room.members = others
	current_room = null


func _player_member() -> RoomState.Member:
	var member := RoomState.Member.new()
	member.display_name = profile.nickname
	member.level = profile.level
	member.is_player = true
	var weapon: ItemInstance = profile.equipment.get_item(ItemDefinition.Slot.WEAPON)
	member.weapon_id = weapon.def_id if weapon != null else STARTER_WEAPON
	return member


func _npc_member(rng: RandomNumberGenerator, team: int, host: bool) -> RoomState.Member:
	var member := RoomState.Member.new()
	member.display_name = content.npc_names[rng.randi_range(0, content.npc_names.size() - 1)]
	member.team = team
	member.level = clampi(profile.level + rng.randi_range(-1, 2), 1, Progression.MAX_LEVEL)
	member.is_host = host
	member.ready = not host and rng.randf() < 0.7
	member.weapon_id = NPC_WEAPONS[rng.randi_range(0, NPC_WEAPONS.size() - 1)]
	return member


# --- Battles ----------------------------------------------------------------------------


func build_pvp_setup(room: RoomState) -> BattleSetup:
	var setup := BattleSetup.new()
	setup.mode = BattleSetup.Mode.PVP
	setup.room_name = room.room_name
	setup.maps = [room.map_id]
	setup.battle_seed = profile.next_rng().randi()
	for member in room.members:
		var participant: BattleSetup.Participant = _member_participant(member)
		if member.team == 0:
			setup.players.append(participant)
		else:
			setup.opponents.append(participant)
	return setup


func build_pve_setup(instance_id: StringName, difficulty: int, with_ally: bool) -> BattleSetup:
	var instance: PveInstanceDefinition = content.instance(instance_id)
	var setup := BattleSetup.new()
	setup.mode = BattleSetup.Mode.PVE
	setup.instance_id = instance_id
	setup.difficulty = difficulty
	setup.room_name = instance.display_name
	setup.battle_seed = profile.next_rng().randi()
	var me := RoomState.Member.new()
	me.display_name = profile.nickname
	me.is_player = true
	setup.players.append(_member_participant(me))
	if with_ally:
		var ally := RoomState.Member.new()
		ally.display_name = content.npc_names[profile.next_rng().randi_range(0, content.npc_names.size() - 1)]
		ally.level = profile.level
		ally.weapon_id = &"wpn_boulder"
		var participant: BattleSetup.Participant = _member_participant(ally)
		participant.aim_error_degrees = ALLY_AIM_ERROR_DEGREES
		participant.visual = &"player_blue" if profile.outfit == 1 else &"player_red"
		setup.players.append(participant)
	var hp_scale: float = PveInstanceDefinition.HP_SCALE[difficulty]
	var damage_scale: float = PveInstanceDefinition.DAMAGE_SCALE[difficulty]
	for stage in instance.stages:
		var map_id: StringName = stage["map"]
		var title: String = stage["title"]
		setup.maps.append(map_id)
		setup.stage_titles.append(title)
		var enemies: Array[BattleSetup.Participant] = []
		var stage_enemies: Array = stage["enemies"]
		for entry: Dictionary in stage_enemies:
			var enemy_id: StringName = entry["enemy"]
			var def: EnemyDefinition = content.enemy(enemy_id)
			var participant := BattleSetup.Participant.new()
			participant.display_name = def.display_name
			participant.team = 1
			participant.controller = _enemy_controller(def.behavior)
			participant.loadout = CombatLoadout.from_enemy(def, hp_scale, damage_scale)
			participant.visual = def.visual
			participant.spawn_x = DataReader.get_float(entry, "x", NAN)
			participant.aim_error_degrees = def.aim_error_degrees
			participant.reach = def.reach
			participant.move_budget = def.move_budget
			participant.exp_reward = def.exp_reward
			participant.gold_reward = def.gold_reward
			enemies.append(participant)
		setup.stage_enemies.append(enemies)
	return setup


func _enemy_controller(behavior: EnemyDefinition.Behavior) -> BattleSetup.Controller:
	match behavior:
		EnemyDefinition.Behavior.MELEE:
			return BattleSetup.Controller.ENEMY_MELEE
		EnemyDefinition.Behavior.BOSS:
			return BattleSetup.Controller.BOSS
	return BattleSetup.Controller.ENEMY_ARTILLERY


func _member_participant(member: RoomState.Member) -> BattleSetup.Participant:
	var participant := BattleSetup.Participant.new()
	participant.display_name = member.display_name
	participant.team = member.team
	participant.is_local_player = member.is_player
	participant.controller = BattleSetup.Controller.HUMAN if member.is_player else BattleSetup.Controller.AI_ARTILLERY
	participant.visual = &"player_blue" if member.team == 0 else &"player_red"
	participant.aim_error_degrees = NPC_AIM_ERROR_DEGREES
	if member.is_player:
		# The chosen outfit; the team shows in the name and HUD colours.
		participant.visual = &"player_red" if profile.outfit == 1 else &"player_blue"
		participant.loadout = CombatLoadout.from_player(stats(), rules)
		participant.loadout.heal_items = profile.inventory.count(&"item_heal")
		participant.loadout.heal_amount = content.item(&"item_heal").heal_amount
	else:
		participant.loadout = CombatLoadout.from_player(_npc_stats(member), rules)
	return participant


func _npc_stats(member: RoomState.Member) -> CharacterStats:
	var npc := PlayerProfile.new()
	npc.level = member.level
	for item_id: StringName in [member.weapon_id, &"clo_cotton", &"hat_cap"]:
		npc.inventory.add(content.item(item_id), 1, npc.uid_allocator())
		var item: ItemInstance = npc.inventory.items[npc.inventory.items.size() - 1]
		npc.equipment.equip(npc.inventory, content, item.uid, Progression.MAX_LEVEL)
	return CharacterStats.compute(npc, content)


## Applies a finished battle: rewards, counters, quests, used items, flip cards.
func finish_battle(outcome: BattleOutcome) -> Reward:
	last_outcome = outcome
	last_reward = RewardCalculator.battle_reward(outcome, profile.level, content)
	if outcome.heal_items_used > 0:
		profile.inventory.remove_quantity(&"item_heal", outcome.heal_items_used)
	if not outcome.surrendered:
		profile.bump_counter(&"battles")
		record(&"battle_finished")
	if outcome.victory and outcome.mode == BattleSetup.Mode.PVP:
		profile.bump_counter(&"pvp_wins")
		record(&"pvp_win")
	if outcome.victory and outcome.mode == BattleSetup.Mode.PVE:
		profile.bump_counter(&"pve_clears")
		record(&"pve_clear")
	last_levels_gained = grant(last_reward)
	last_cards.clear()
	if outcome.victory:
		last_cards = RewardCalculator.draw_cards(outcome, content, profile.next_rng())
	card_claimed = -1
	pending_battle = null
	if current_room != null:
		current_room.state = RoomState.State.WAITING
		for member in current_room.members:
			member.ready = member.is_host or not member.is_player
	save()
	return last_reward


func claim_card(index: int) -> Reward:
	if card_claimed >= 0 or index < 0 or index >= last_cards.size():
		return null
	card_claimed = index
	var reward: Reward = last_cards[index]
	grant(reward)
	save()
	return reward
