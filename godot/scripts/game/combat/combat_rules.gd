class_name CombatRules
extends Resource
## Playtest placeholders for the combat sandbox (docs/COMBAT_SANDBOX.md).
## Values live in res://config/combat_rules.tres. NONE of them is historical or
## calibrated: they are ESTIMATED / GAME DESIGN PLACEHOLDER values to be judged by
## playing. Calibrated ballistics stay in GameMetrics.

const DEFAULT_PATH: String = "res://config/combat_rules.tres"

@export_group("Map (ESTIMATED)")
@export var map_width: float = 0.0
@export var map_height: float = 0.0
@export var terrain_cell_size: float = 0.0
@export var ground_level_y: float = 0.0
@export var spawn_x: PackedFloat64Array = PackedFloat64Array()
## Characters and projectiles below map_height + death_margin are out.
@export var death_margin: float = 0.0

@export_group("Character (ESTIMATED)")
@export var head_radius: float = 0.0
## Height of the head centre above the FeetAnchor.
@export var head_center_height: float = 0.0
@export var body_width: float = 0.0
@export var body_height: float = 0.0
## Half distance between the outer support probes under the feet.
@export var foot_half_width: float = 0.0
## Provisional launch point relative to the FeetAnchor (OQ-09): forward along facing, up.
@export var muzzle_forward: float = 0.0
@export var muzzle_up: float = 0.0
@export var starting_hp: int = 0

@export_group("Movement (GAME DESIGN PLACEHOLDER)")
@export var move_speed: float = 0.0
@export var movement_budget: float = 0.0
@export var max_slope_degrees: float = 0.0
@export var fall_speed: float = 0.0

@export_group("Aim and power (GAME DESIGN PLACEHOLDER)")
@export var angle_min: int = 0
@export var angle_max: int = 0
@export var initial_angle: int = 0
## Seconds between 1-degree steps while an angle key is held.
@export var angle_repeat_interval: float = 0.0
## Seconds to charge from 0 to power_max (OQ-10).
@export var power_charge_time: float = 0.0
@export var power_max: float = 0.0

@export_group("Explosion (GAME DESIGN PLACEHOLDER)")
@export var base_damage: float = 0.0
@export var damage_radius: float = 0.0
@export var crater_radius: float = 0.0

@export_group("Wind (GAME DESIGN PLACEHOLDER)")
@export var wind_max: float = 0.0
@export var wind_step: float = 0.0
@export var wind_seed: int = 0

@export_group("Flow and camera (GAME DESIGN PLACEHOLDER)")
## Seconds the camera stays on the impact before the next turn.
@export var impact_hold_time: float = 0.0
## Multiplier of simulated time for projectile playback (1 = real simulated time).
@export var flight_playback_speed: float = 1.0
## Exponential camera smoothing rate (1/s) when moving between framings.
@export var camera_follow_rate: float = 0.0
## Active player's feet at this fraction of the view height (from the top).
@export var turn_framing_fraction: float = 0.0


static func load_default() -> CombatRules:
	return load(DEFAULT_PATH) as CombatRules


func death_y() -> float:
	return map_height + death_margin
