class_name SaveService
extends RefCounted
## Local JSON save in user:// (no external services).


static func exists(path: String) -> bool:
	return FileAccess.file_exists(path)


static func write(path: String, profile: PlayerProfile) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write save %s" % path)
		return false
	file.store_string(JSON.stringify(profile.to_dict(), "\t"))
	file.close()
	return true


static func read(path: String) -> PlayerProfile:
	if not exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("Save %s is unreadable" % path)
		return null
	var data: Dictionary = parsed
	return PlayerProfile.from_dict(data)


static func delete(path: String) -> void:
	if exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
