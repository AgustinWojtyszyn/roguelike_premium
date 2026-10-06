extends Node
## Autoload "Boot": marcadores de arranque (usados por tools/android_cold_start.py) y argumentos de linea de comandos.
## Los marcadores [BOOT 01] / [BOOT 09] / [BOOT 10] son parte del contrato con la regresion de Android.

var args: Dictionary = {}
var _first_frame := true
var _t0 := 0


func _enter_tree() -> void:
	_t0 = Time.get_ticks_msec()
	_parse_args()
	log_stage(1, "main entered")


func _ready() -> void:
	if OS.is_debug_build() and OS.has_feature("android"):
		RenderingServer.frame_post_draw.connect(func(): log_stage(10, "first rendered frame"), CONNECT_ONE_SHOT)


func _process(_delta: float) -> void:
	if _first_frame:
		_first_frame = false
		var vs := get_viewport().get_visible_rect().size
		log_stage(9, "first frame viewport=%s landscape=%s" % [vs, vs.x > vs.y])
		set_process(false)


func log_stage(stage: int, detail: String) -> void:
	if OS.is_debug_build() and OS.has_feature("android"):
		print("[BOOT %02d] PID=%d OS=%s ticks=%d %s" % [stage, OS.get_process_id(), OS.get_name(), Time.get_ticks_msec(), detail])


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if not a.begins_with("--"):
			continue
		var kv := a.substr(2).split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"


func has_flag(name: String) -> bool:
	return args.has(name)


func get_arg(name: String, default: String = "") -> String:
	return str(args.get(name, default))
