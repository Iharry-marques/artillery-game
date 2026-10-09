class_name CharacterPreview
extends Control
## The player's chibi proxy on a pedestal, holding the equipped weapon at 40 degrees.

var outfit: int = 0
var weapon_art: StringName = &"launcher"
var aiming: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_profile(profile: PlayerProfile, content: ContentDatabase) -> void:
	outfit = profile.outfit
	var weapon: ItemInstance = profile.equipment.get_item(ItemDefinition.Slot.WEAPON)
	weapon_art = content.item(weapon.def_id).weapon_art if weapon != null else &""
	queue_redraw()


func _draw() -> void:
	var art: CharacterProxyArt = CharacterProxyArt.shared()
	var feet := Vector2(size.x * 0.48, size.y * 0.9)
	draw_set_transform(feet, 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, size.x * 0.32, Color(0.05, 0.08, 0.2, 0.35))
	draw_circle(Vector2.ZERO, size.x * 0.27, Color(1.0, 0.85, 0.4, 0.25))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var body: Texture2D = art.body_texture(outfit, aiming)
	var scale: float = size.y * 0.85 / art.body_size_px.y * 1.12
	draw_set_transform(feet, 0.0, Vector2.ONE * scale)
	draw_texture(body, -art.feet_anchor_px)
	if weapon_art != &"":
		var pivot := Vector2(art.weapon_pivot_u.x, -art.weapon_pivot_u.y) * art.pixels_per_unit
		draw_set_transform(feet + pivot * scale, -deg_to_rad(40.0), Vector2.ONE * scale)
		draw_texture(art.weapon_texture(weapon_art), -art.weapon_pivot_px)
	draw_set_transform_matrix(Transform2D.IDENTITY)
