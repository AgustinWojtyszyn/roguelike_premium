extends SceneTree
## Ejecutor de pruebas headless:  godot --headless --path . --script tests/run_tests.gd
## Cada archivo tests/test_*.gd define `func run(t)` y usa t.check(cond, mensaje) / t.eq(a, b, mensaje).

var passed := 0
var failed := 0
var current := ""


func _initialize() -> void:
	await _run_all()


func _run_all() -> void:
	var dir := DirAccess.open("res://tests")
	var files: Array[String] = []
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(f)
	files.sort()
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	for f in files:
		if only != "" and not f.contains(only):
			continue
		current = f
		var scr: GDScript = load("res://tests/" + f)
		if scr == null:
			failed += 1
			print("FAIL  %s: no compila" % f)
			continue
		var inst = scr.new()
		await inst.run(self)
	print("\n== %d OK, %d FALLOS ==" % [passed, failed])
	quit(1 if failed > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL  [%s] %s" % [current, msg])


func eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		passed += 1
	else:
		failed += 1
		print("FAIL  [%s] %s  (obtenido %s, esperado %s)" % [current, msg, str(a), str(b)])
