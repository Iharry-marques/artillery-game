class_name MetaFixture
extends RefCounted
## Fresh GameSession on a throwaway save file for domain tests.

const TEST_SAVE: String = "user://test_meta_save.json"


static func session(nickname: String = "Tester") -> GameSession:
	SaveService.delete(TEST_SAVE)
	var game := GameSession.new(TEST_SAVE)
	game.create_profile(nickname, 0)
	return game


static func cleanup() -> void:
	SaveService.delete(TEST_SAVE)
