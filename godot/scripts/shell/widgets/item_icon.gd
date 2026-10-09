class_name ItemIcon
extends Control
## Procedural item icon (original): weapons use their Blender sprite, other items
## are drawn shapes in the item colour. Shows rarity frame, stack size and "+N".

var def: ItemDefinition
var quantity: int = 1
var enhance_level: int = 0
var show_frame: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_item(p_def: ItemDefinition, p_quantity: int = 1, p_enhance: int = 0) -> void:
	def = p_def
	quantity = p_quantity
	enhance_level = p_enhance
	queue_redraw()


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var c := size * 0.5
	if show_frame:
		var frame_color: Color = UiKit.rarity_color(def.rarity) if def != null else Color(1, 1, 1, 0.15)
		draw_style_box(UiKit.box(UiKit.NAVY_DEEP, frame_color, 8, 2), Rect2(Vector2.ZERO, size))
	if def == null:
		return
	var col: Color = def.color
	var dark: Color = col.darkened(0.45)
	match def.kind:
		ItemDefinition.Kind.WEAPON:
			var texture: Texture2D = CharacterProxyArt.shared().weapon_texture(def.weapon_art)
			var tex_size: Vector2 = texture.get_size()
			var scale: float = s * 0.95 / tex_size.x
			draw_set_transform(c, -0.6, Vector2.ONE * scale)
			draw_texture(texture, -tex_size * 0.5 + Vector2(-tex_size.x * 0.12, 0))
			draw_set_transform_matrix(Transform2D.IDENTITY)
		ItemDefinition.Kind.CLOTHES:
			var shirt := PackedVector2Array([c + Vector2(-0.3, -0.28) * s, c + Vector2(-0.1, -0.33) * s, c + Vector2(0.1, -0.33) * s,
				c + Vector2(0.3, -0.28) * s, c + Vector2(0.38, -0.05) * s, c + Vector2(0.24, 0.0) * s, c + Vector2(0.24, 0.32) * s,
				c + Vector2(-0.24, 0.32) * s, c + Vector2(-0.24, 0.0) * s, c + Vector2(-0.38, -0.05) * s])
			draw_colored_polygon(shirt, col)
			draw_polyline(shirt + PackedVector2Array([shirt[0]]), dark, 2.0)
		ItemDefinition.Kind.HAT:
			draw_circle(c + Vector2(0, 0.05) * s, s * 0.26, col)
			draw_rect(Rect2(c + Vector2(-0.36, 0.04) * s, Vector2(0.72, 0.12) * s), dark)
			draw_circle(c + Vector2(0.12, -0.12) * s, s * 0.06, Color(1, 1, 1, 0.5))
		ItemDefinition.Kind.RING:
			draw_arc(c + Vector2(0, 0.06) * s, s * 0.22, 0, TAU, 32, col, s * 0.07)
			draw_circle(c + Vector2(0, -0.17) * s, s * 0.1, Color(1.0, 0.95, 0.6))
		ItemDefinition.Kind.NECKLACE:
			draw_arc(c + Vector2(0, -0.1) * s, s * 0.28, 0.2, PI - 0.2, 24, dark, 3.0)
			draw_circle(c + Vector2(0, 0.2) * s, s * 0.13, col)
		ItemDefinition.Kind.STONE, ItemDefinition.Kind.ELEMENT_STONE:
			var gem := PackedVector2Array()
			for i in 6:
				var a: float = TAU * i / 6.0 + PI / 6.0
				gem.append(c + Vector2(cos(a), sin(a)) * s * 0.3)
			draw_colored_polygon(gem, col)
			draw_polyline(gem + PackedVector2Array([gem[0]]), dark, 2.0)
			draw_colored_polygon(PackedVector2Array([gem[3], gem[4], c]), Color(1, 1, 1, 0.35))
			if def.kind == ItemDefinition.Kind.STONE:
				_text(c + Vector2(-0.08, 0.12) * s, str(def.stone_level), s * 0.28)
		ItemDefinition.Kind.CHARM:
			for i in 4:
				var a: float = TAU * i / 4.0
				draw_circle(c + Vector2(cos(a), sin(a)) * s * 0.13, s * 0.13, col)
			draw_line(c, c + Vector2(0.1, 0.32) * s, dark, 3.0)
		ItemDefinition.Kind.PROTECTION:
			var shield := PackedVector2Array([c + Vector2(-0.26, -0.28) * s, c + Vector2(0.26, -0.28) * s, c + Vector2(0.24, 0.05) * s, c + Vector2(0, 0.32) * s, c + Vector2(-0.24, 0.05) * s])
			draw_colored_polygon(shield, col)
			draw_polyline(shield + PackedVector2Array([shield[0]]), dark, 2.0)
		ItemDefinition.Kind.CONSUMABLE:
			draw_rect(Rect2(c - Vector2(0.28, 0.24) * s, Vector2(0.56, 0.48) * s), col)
			draw_rect(Rect2(c - Vector2(0.05, 0.16) * s, Vector2(0.1, 0.32) * s), Color.WHITE)
			draw_rect(Rect2(c - Vector2(0.16, 0.05) * s, Vector2(0.32, 0.1) * s), Color.WHITE)
		ItemDefinition.Kind.BOX:
			draw_rect(Rect2(c - Vector2(0.28, 0.18) * s, Vector2(0.56, 0.46) * s), col)
			draw_rect(Rect2(c - Vector2(0.32, 0.28) * s, Vector2(0.64, 0.14) * s), col.lightened(0.2))
			draw_rect(Rect2(c - Vector2(0.05, 0.28) * s, Vector2(0.1, 0.56) * s), Color(1.0, 0.9, 0.4))
	if enhance_level > 0:
		_text(Vector2(4, s * 0.3), "+%d" % enhance_level, s * 0.24, UiKit.GOLD)
	if quantity > 1:
		_text(Vector2(size.x - s * 0.42, size.y - 6), str(quantity), s * 0.22)


func _text(at: Vector2, text: String, font_size: float, color: Color = UiKit.TEXT) -> void:
	var font: Font = UiKit.bold_font()
	var px: int = maxi(10, roundi(font_size))
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 5, UiKit.OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
