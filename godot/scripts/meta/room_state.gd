class_name RoomState
extends RefCounted
## A Game Hall battle room (simulated locally: no networking). Team 0 = Blue,
## team 1 = Red. The host starts the match once every other member is ready.

enum Mode { DUEL, TEAM }
enum State { WAITING, PLAYING }


class Member:
	extends RefCounted
	var display_name: String
	var team: int = 0
	var level: int = 1
	var is_player: bool = false
	var is_host: bool = false
	var ready: bool = false
	var weapon_id: StringName = &"wpn_sunburst"


var id: int
var room_name: String
var mode: Mode = Mode.DUEL
var map_id: StringName = &"meadow"
var locked: bool = false
var state: State = State.WAITING
var members: Array[Member] = []


func team_size() -> int:
	return 1 if mode == Mode.DUEL else 2


func capacity() -> int:
	return team_size() * 2


func count_team(team: int) -> int:
	var total: int = 0
	for member in members:
		if member.team == team:
			total += 1
	return total


func is_full() -> bool:
	return members.size() >= capacity()


func host() -> Member:
	for member in members:
		if member.is_host:
			return member
	return null


func player() -> Member:
	for member in members:
		if member.is_player:
			return member
	return null


func free_team() -> int:
	if count_team(0) < team_size():
		return 0
	if count_team(1) < team_size():
		return 1
	return -1


func add_member(member: Member) -> bool:
	var team: int = member.team
	if count_team(team) >= team_size():
		team = free_team()
	if team < 0:
		return false
	member.team = team
	members.append(member)
	return true


func switch_team(member: Member) -> bool:
	var other: int = 1 - member.team
	if count_team(other) >= team_size():
		return false
	member.team = other
	return true


## "" when the host may start; otherwise the reason.
func start_blocker() -> String:
	if count_team(0) == 0 or count_team(1) == 0:
		return "Both teams need at least one player"
	for member in members:
		if not member.is_host and not member.ready:
			return "Waiting for everyone to be ready"
	return ""


static func mode_name(value: Mode) -> String:
	return ["1v1 Free", "2v2 Free"][value]
