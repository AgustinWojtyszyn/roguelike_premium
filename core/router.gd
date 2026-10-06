extends Node
## Autoload "Router": cambio de escena con transicion corta (barrido diagonal) y paso de parametros.

const SCENES := {
	"home": "res://scenes/home.tscn",
	"run": "res://scenes/run.tscn",
}

var params: Dictionary = {}
var busy := false
var _layer: CanvasLayer
var _wipe: Control
var _k: float = 0.0     # 0 = descubierto, 1 = cubierto
var _reveal := false
var _col := Color("070a13")


class Wipe extends Control:
	var router
	func _draw() -> void:
		var k: float = router._k
		if k <= 0.001:
			return
		var s := size
		var skew := s.y * 0.35
		var reveal: bool = router._reveal
		var edge := s.x * 1.4 * ((1.0 - k) if reveal else k) - skew
		var pts: PackedVector2Array
		if reveal:
			pts = PackedVector2Array([Vector2(edge + skew, -10), Vector2(s.x + 10, -10), Vector2(s.x + 10, s.y + 10), Vector2(edge - skew, s.y + 10)])
		else:
			pts = PackedVector2Array([Vector2(-10, -10), Vector2(edge + skew, -10), Vector2(edge - skew, s.y + 10), Vector2(-10, s.y + 10)])
		draw_colored_polygon(pts, router._col)
		var line := PackedVector2Array([Vector2(edge + skew, -10), Vector2(edge - skew, s.y + 10)])
		draw_polyline(line, Color(0.3, 0.95, 0.9, 0.9 * k), 6.0, true)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_wipe = Wipe.new()
	_wipe.router = self
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_wipe)


func goto(key: String, p: Dictionary = {}, color: Color = Color("070a13")) -> void:
	if busy:
		return
	busy = true
	params = p
	_col = color
	var path: String = SCENES.get(key, key)
	_reveal = false
	var tw := create_tween()
	tw.tween_method(_set_k, 0.0, 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	get_tree().paused = false
	Engine.time_scale = 1.0
	Game.tscale = 1.0
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Router: no se pudo cargar %s (%d)" % [path, err])
	await get_tree().process_frame
	await get_tree().process_frame
	_reveal = true
	var tw2 := create_tween()
	tw2.tween_method(_set_k, 1.0, 0.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw2.finished
	busy = false


func _set_k(v: float) -> void:
	_k = v
	_wipe.queue_redraw()
