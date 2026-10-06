extends SceneTree
## Headless test runner without external dependencies.
## Run with tools/run_tests.sh. Exits with status 1 if any test fails.
##
## Discovers res://tests/test_*.gd; each file extends TestCase and every method
## whose name starts with "test_" is a test. Optional user argument:
##   --filter=<substring>   only run tests whose "file::method" contains it

const TESTS_DIR: String = "res://tests"


func _initialize() -> void:
	var filter: String = ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.trim_prefix("--filter=")

	var passed: int = 0
	var failed: int = 0
	for path in _test_files():
		var script: GDScript = load(path) as GDScript
		if script == null or not script.can_instantiate():
			print("FAIL %s (could not load)" % path)
			failed += 1
			continue
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			var test_id: String = "%s::%s" % [path.get_file(), method_name]
			if not method_name.begins_with("test_") or (filter != "" and not test_id.contains(filter)):
				continue
			var test: TestCase = script.new() as TestCase
			var started_ms: int = Time.get_ticks_msec()
			test.call(method_name)
			var elapsed_ms: int = Time.get_ticks_msec() - started_ms
			if test.failures.is_empty():
				passed += 1
				print("PASS %s (%d ms)" % [test_id, elapsed_ms])
			else:
				failed += 1
				print("FAIL %s (%d ms)" % [test_id, elapsed_ms])
				for failure in test.failures:
					print("     - %s" % failure)
			for note in test.notes:
				print("     . %s" % note)

	print("")
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 or passed == 0 else 0)


func _test_files() -> PackedStringArray:
	var files: PackedStringArray = []
	for file in DirAccess.get_files_at(TESTS_DIR):
		if file.begins_with("test_") and file.ends_with(".gd"):
			files.append(TESTS_DIR.path_join(file))
	files.sort()
	return files
