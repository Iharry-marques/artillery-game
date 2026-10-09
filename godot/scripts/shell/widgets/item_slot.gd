class_name ItemSlot
extends Button
## A clickable inventory/equipment cell holding an ItemIcon.

var uid: int = -1
var payload: Variant
var icon_view: ItemIcon
var caption: String = ""


static func create(slot_size: float = 76.0) -> ItemSlot:
	var slot := ItemSlot.new()
	slot.custom_minimum_size = Vector2(slot_size, slot_size)
	slot.toggle_mode = true
	slot.add_theme_stylebox_override("normal", UiKit.box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 8, 0))
	slot.add_theme_stylebox_override("hover", UiKit.box(Color(1, 1, 1, 0.08), UiKit.SKY, 8, 2))
	slot.add_theme_stylebox_override("pressed", UiKit.box(Color(1, 0.8, 0.3, 0.12), UiKit.GOLD, 8, 3))
	slot.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	slot.icon_view = ItemIcon.new()
	slot.icon_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(slot.icon_view)
	return slot


func show_item(def: ItemDefinition, item: ItemInstance) -> void:
	uid = item.uid if item != null else -1
	icon_view.set_item(def, item.quantity if item != null else 1, item.enhance_level if item != null else 0)
	tooltip_text = def.display_name if def != null else caption


func clear_item() -> void:
	uid = -1
	icon_view.set_item(null)
	tooltip_text = caption


func _draw() -> void:
	if icon_view.def == null and caption != "":
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(6, size.y * 0.55), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x - 12, 13, UiKit.TEXT_DIM)
