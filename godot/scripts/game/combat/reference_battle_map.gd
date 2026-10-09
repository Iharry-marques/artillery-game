class_name ReferenceBattleMap
extends RefCounted
## The default battlefield ("Sunny Meadow" layout) with the spawn pads of
## CombatRules.spawn_x. Used by the plain sandbox; battle setups use
## MapDefinition content through BattleMapBuilder.


static func definition(rules: CombatRules) -> MapDefinition:
	var def: MapDefinition = ContentCatalog.shared().map(&"meadow")
	var copy := MapDefinition.new()
	copy.id = def.id
	copy.display_name = def.display_name
	copy.ground_level_y = rules.ground_level_y
	copy.features = def.features
	copy.ripples = def.ripples
	copy.islands = def.islands
	copy.left_pads = PackedFloat64Array([rules.spawn_x[0]])
	copy.right_pads = PackedFloat64Array([rules.spawn_x[1]])
	return copy


static func build(rules: CombatRules) -> TerrainMask:
	return BattleMapBuilder.build(definition(rules), rules)
