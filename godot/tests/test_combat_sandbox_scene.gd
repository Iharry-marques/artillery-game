extends TestCase
## Smoke test of the reference-clone battle scene: loads without script errors,
## builds the CharacterRoot hierarchy with the proxy art, keeps the 10 u camera and
## turns the weapon with the gameplay angle. No pixel assertions.

const SCENE: String = "res://scenes/gameplay/combat_sandbox.tscn"
const SETTLE_FRAMES: int = 4
const CAMERA_EPS: float = 1e-5


func test_scene_builds_characters_and_keeps_the_battle_width() -> void:
	var packed: PackedScene = load(SCENE) as PackedScene
	assert_true(packed != null, "scene loads")
	if packed == null:
		return
	var sandbox: CombatSandbox = packed.instantiate() as CombatSandbox
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(sandbox)
	for i in SETTLE_FRAMES:
		await tree.process_frame

	var camera: BattleCamera = sandbox.get_node("World/BattleCamera") as BattleCamera
	assert_near(camera.visible_size_units().x, 10.0, CAMERA_EPS, "battle camera is 10 u wide")
	for name: String in ["Player1", "Player2"]:
		var root: CombatantView = sandbox.get_node("World/%s" % name) as CombatantView
		for path: String in ["Visual/Body", "Visual/WeaponPivot/Weapon", "Head/HeadHitbox"]:
			assert_true(root.has_node(path), "%s has %s" % [name, path])
		var body: Sprite2D = root.get_node("Visual/Body") as Sprite2D
		assert_true(body.texture != null, "%s body has proxy art" % name)
		var head: Node2D = root.get_node("Head") as Node2D
		assert_near(-head.position.y / WorldCanvas.PIXELS_PER_UNIT, sandbox.rules.head_center_height, 1e-5, "%s Head node at the hitbox height" % name)

	var combat: CombatMatch = sandbox.combat
	combat.request_angle_step(0, 15)
	await tree.process_frame
	var view: CombatantView = sandbox.get_node("World/Player1") as CombatantView
	assert_near(view.weapon_pivot_rotation(), CombatantView.weapon_rotation(combat.combatants[0].angle), 1e-6, "weapon follows the angle")

	sandbox.queue_free()
	await tree.process_frame
