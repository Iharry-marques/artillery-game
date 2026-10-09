extends TestCase
## Proxy art pipeline output (tools/blender/create_reference_character.py) versus
## the gameplay geometry in CombatRules. Presentation metrics, not ballistics.

## How far the art head may sit from the HeadHitbox, in u.
const HEAD_ALIGNMENT_TOLERANCE: float = 0.02
## How much the hitbox radius may differ from the mean visual head radius, in u.
const HEAD_RADIUS_TOLERANCE: float = 0.03
const CHARACTER_HEIGHT_RANGE: Vector2 = Vector2(0.9, 1.2)
const HEAD_SHARE_RANGE: Vector2 = Vector2(0.45, 0.6)


func _art() -> CharacterProxyArt:
	return CharacterProxyArt.load_default()


func test_metadata_and_sprites_load() -> void:
	var art: CharacterProxyArt = _art()
	assert_true(art != null, "proxy_meta.json loads")
	if art == null:
		return
	for key: String in art.bodies:
		var texture: Texture2D = art.bodies[key]
		assert_true(texture != null, "%s sprite loads" % key)
		if texture != null:
			assert_true(Vector2(texture.get_size()) == art.body_size_px, "%s size matches the metadata" % key)
	assert_true(art.weapon != null and art.projectile != null, "weapon and projectile sprites load")
	assert_near(art.pixels_per_unit, 256.0, 0.0, "render resolution: 256 px per u")


func test_character_scale_is_a_chibi_proportion() -> void:
	var art: CharacterProxyArt = _art()
	var height: float = art.total_height_u
	assert_true(height >= CHARACTER_HEIGHT_RANGE.x and height <= CHARACTER_HEIGHT_RANGE.y, "total height %.3f u" % height)
	var head_share: float = 2.0 * art.head_visual_radius_u.y / height
	assert_true(head_share >= HEAD_SHARE_RANGE.x and head_share <= HEAD_SHARE_RANGE.y, "head is %.0f%% of the height" % (head_share * 100.0))
	note("height %.3f u, head %.3f x %.3f u (%.0f%% of height)" % [height, 2.0 * art.head_visual_radius_u.x, 2.0 * art.head_visual_radius_u.y, head_share * 100.0])


func test_head_art_matches_the_head_hitbox() -> void:
	var art: CharacterProxyArt = _art()
	var rules: CombatRules = CombatRules.load_default()
	assert_near(art.head_center_u.x, 0.0, HEAD_ALIGNMENT_TOLERANCE, "art head centred over the FeetAnchor")
	assert_near(art.head_center_u.y, rules.head_center_height, HEAD_ALIGNMENT_TOLERANCE, "art head height vs hitbox height")
	var mean_radius: float = 0.5 * (art.head_visual_radius_u.x + art.head_visual_radius_u.y)
	assert_near(rules.head_radius, mean_radius, HEAD_RADIUS_TOLERANCE, "hitbox radius vs art head radius")
	note("hitbox r %.3f u vs art head %.3f x %.3f u" % [rules.head_radius, art.head_visual_radius_u.x, art.head_visual_radius_u.y])


func test_weapon_geometry_matches_gameplay() -> void:
	var art: CharacterProxyArt = _art()
	var rules: CombatRules = CombatRules.load_default()
	assert_near(art.weapon_pivot_u.x, rules.weapon_pivot_forward, 1e-6, "pivot forward")
	assert_near(art.weapon_pivot_u.y, rules.weapon_pivot_up, 1e-6, "pivot up")
	assert_near(art.weapon_barrel_length_u, rules.weapon_barrel_length, 1e-6, "barrel length = launch distance")
