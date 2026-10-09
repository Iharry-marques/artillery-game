extends ShellScreen
## The Bag: equipment slots around the character, the item grid with tabs, item
## details and actions (equip, unequip, open, sell), with a stat comparison.

const SLOTS: Array[ItemDefinition.Slot] = [
	ItemDefinition.Slot.WEAPON, ItemDefinition.Slot.HAT, ItemDefinition.Slot.CLOTHES, ItemDefinition.Slot.RING, ItemDefinition.Slot.NECKLACE,
]
const TABS: Array[String] = ["All", "Equipment", "Materials", "Battle items"]
const GRID_COLUMNS: int = 7

var _tab: int = 0
var _selected_uid: int = -1
var _preview: CharacterPreview
var _slot_buttons: Dictionary = {}
var _grid: GridContainer
var _details: VBoxContainer
var _stats_label: Label
var _capacity_label: Label
var _tab_buttons: Array[Button] = []


func screen_title() -> String:
	return "Bag"


func build() -> void:
	var row: HBoxContainer = UiKit.hbox(20)
	content_root.add_child(row)

	var equip_panel: PanelContainer = UiKit.panel()
	equip_panel.custom_minimum_size = Vector2(430, 0)
	row.add_child(equip_panel)
	var equip_column: VBoxContainer = UiKit.vbox(10)
	equip_panel.add_child(equip_column)
	equip_column.add_child(UiKit.label("Equipment", 26, UiKit.GOLD, true))
	var equip_row: HBoxContainer = UiKit.hbox(8)
	equip_column.add_child(equip_row)
	var slot_column: VBoxContainer = UiKit.vbox(8)
	equip_row.add_child(slot_column)
	for slot in SLOTS:
		var button: ItemSlot = ItemSlot.create(84)
		button.caption = ItemDefinition.slot_name(slot)
		button.pressed.connect(func() -> void: _select_equipped(slot))
		slot_column.add_child(button)
		_slot_buttons[slot] = button
	_preview = CharacterPreview.new()
	_preview.custom_minimum_size = Vector2(300, 440)
	equip_row.add_child(_preview)
	_stats_label = UiKit.label("", 17)
	equip_column.add_child(_stats_label)

	var bag_panel: PanelContainer = UiKit.panel()
	bag_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bag_panel)
	var bag_column: VBoxContainer = UiKit.vbox(10)
	bag_panel.add_child(bag_column)
	var tabs: HBoxContainer = UiKit.hbox(8)
	bag_column.add_child(tabs)
	for i in TABS.size():
		var tab_button: Button = UiKit.button(TABS[i], func() -> void: _set_tab(i), "dark", Vector2(130, 44))
		tabs.add_child(tab_button)
		_tab_buttons.append(tab_button)
	tabs.add_child(UiKit.spacer())
	_capacity_label = UiKit.label("", 18, UiKit.TEXT_DIM)
	tabs.add_child(_capacity_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag_column.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = GRID_COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)

	var detail_panel: PanelContainer = UiKit.panel()
	detail_panel.custom_minimum_size = Vector2(380, 0)
	row.add_child(detail_panel)
	_details = UiKit.vbox(10)
	detail_panel.add_child(_details)
	refresh()


func refresh() -> void:
	var p: PlayerProfile = game.profile
	_preview.show_profile(p, game.content)
	for slot in SLOTS:
		var button: ItemSlot = _slot_buttons[slot]
		var item: ItemInstance = p.equipment.get_item(slot)
		if item != null:
			button.show_item(game.content.item(item.def_id), item)
		else:
			button.clear_item()
		button.button_pressed = item != null and item.uid == _selected_uid
	var stats: CharacterStats = game.stats()
	_stats_label.text = "Power %d   HP %d   Harm %d   Armor %d\nAtk %d  Def %d  Agi %d  Luck %d" % [
		stats.combat_power, stats.max_hp, stats.harm, stats.armor, stats.total.attack, stats.total.defense, stats.total.agility, stats.total.luck]
	for i in _tab_buttons.size():
		UiKit.tint(_tab_buttons[i], "primary" if i == _tab else "dark")
	for child in _grid.get_children():
		child.queue_free()
	var shown: int = 0
	for item in p.inventory.items:
		var def: ItemDefinition = game.content.item(item.def_id)
		if not _in_tab(def):
			continue
		var cell: ItemSlot = ItemSlot.create(84)
		cell.show_item(def, item)
		cell.button_pressed = item.uid == _selected_uid
		var uid: int = item.uid
		cell.pressed.connect(func() -> void: _select(uid))
		_grid.add_child(cell)
		shown += 1
	for i in maxi(0, GRID_COLUMNS * 5 - shown):
		var empty: ItemSlot = ItemSlot.create(84)
		empty.disabled = true
		_grid.add_child(empty)
	_capacity_label.text = "%d / %d slots" % [p.inventory.used_slots(), p.inventory.capacity]
	_show_details()
	refresh_top_bar()


func _in_tab(def: ItemDefinition) -> bool:
	match _tab:
		1:
			return def.is_equipment()
		2:
			return def.kind in [ItemDefinition.Kind.STONE, ItemDefinition.Kind.ELEMENT_STONE, ItemDefinition.Kind.CHARM, ItemDefinition.Kind.PROTECTION]
		3:
			return def.kind in [ItemDefinition.Kind.CONSUMABLE, ItemDefinition.Kind.BOX]
	return true


func _set_tab(tab: int) -> void:
	_tab = tab
	refresh()


func _select(uid: int) -> void:
	_selected_uid = uid
	refresh()


func _select_equipped(slot: ItemDefinition.Slot) -> void:
	var item: ItemInstance = game.profile.equipment.get_item(slot)
	_selected_uid = item.uid if item != null else -1
	refresh()


func _show_details() -> void:
	for child in _details.get_children():
		child.queue_free()
	var item: ItemInstance = game.profile.find_item(_selected_uid)
	if item == null:
		_details.add_child(UiKit.label("Select an item", 22, UiKit.TEXT_DIM))
		_details.add_child(UiKit.label("Equip weapons, clothes and accessories\nto change your stats.", 16, UiKit.TEXT_DIM))
		return
	var def: ItemDefinition = game.content.item(item.def_id)
	var equipped: bool = game.profile.is_equipped(item.uid)
	var icon := ItemIcon.new()
	icon.custom_minimum_size = Vector2(140, 140)
	icon.set_item(def, item.quantity, item.enhance_level)
	_details.add_child(icon)
	var title: String = def.display_name + (" +%d" % item.enhance_level if item.enhance_level > 0 else "")
	_details.add_child(UiKit.label(title, 26, UiKit.rarity_color(def.rarity), true))
	_details.add_child(UiKit.label("%s%s" % [ItemDefinition.kind_name(def.kind), "   (equipped)" if equipped else ""], 17, UiKit.TEXT_DIM))
	var description: Label = UiKit.label(def.description, 16)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(340, 0)
	_details.add_child(description)
	if def.is_equipment():
		var lines: PackedStringArray = UiKit.stat_lines(CharacterStats.item_stats(def, item))
		_details.add_child(UiKit.label("\n".join(lines), 18, UiKit.GREEN))
		if def.kind == ItemDefinition.Kind.WEAPON:
			_details.add_child(UiKit.label("Angles %d-%d°   Crater %.2f u" % [def.min_angle, def.max_angle, def.crater_radius], 16, UiKit.TEXT_DIM))
		if def.level_required > 1:
			_details.add_child(UiKit.label("Requires level %d" % def.level_required, 16, UiKit.GREEN if game.profile.level >= def.level_required else UiKit.RED))
		if not equipped:
			_details.add_child(UiKit.label(_compare_text(def, item), 16, UiKit.GOLD))
	var actions: HBoxContainer = UiKit.hbox(8)
	_details.add_child(actions)
	if def.is_equipment() and not equipped:
		actions.add_child(UiKit.button("Equip", func() -> void: _act(game.equip(item.uid), "Equipped!"), "green", Vector2(150, 50)))
	elif equipped:
		actions.add_child(UiKit.button("Unequip", func() -> void: _act(game.unequip(def.slot()), "Unequipped"), "blue", Vector2(150, 50)))
	if def.kind == ItemDefinition.Kind.BOX:
		actions.add_child(UiKit.button("Open", func() -> void: _act(game.use_item(item.uid), "Box opened!"), "gold", Vector2(150, 50)))
	if not equipped and def.sell_gold > 0:
		actions.add_child(UiKit.button("Sell %d" % (def.sell_gold * item.quantity), func() -> void:
			var gold: int = game.sell(item.uid)
			_selected_uid = -1
			_act("" if gold >= 0 else "Cannot sell", "Sold for %d gold" % gold), "red", Vector2(150, 50)))


func _compare_text(def: ItemDefinition, item: ItemInstance) -> String:
	var current: ItemInstance = game.profile.equipment.get_item(def.slot())
	var current_stats := StatBlock.new()
	if current != null:
		current_stats = CharacterStats.item_stats(game.content.item(current.def_id), current)
	var delta: StatBlock = CharacterStats.item_stats(def, item).plus(current_stats.scaled(-1.0))
	var lines: PackedStringArray = UiKit.stat_lines(delta)
	return "If equipped: " + (", ".join(lines) if not lines.is_empty() else "no change")


func _act(error: String, success_text: String) -> void:
	toast(success_text if error == "" else error, error == "")
	refresh()
