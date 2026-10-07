class_name Part
extends Node2D
## Pieza dibujada por codigo: permite armar personajes con partes animables.

var painter: Callable
var _last_redraw_ms := 0


static func make(parent: Node, paint: Callable, pos: Vector2 = Vector2.ZERO, additive: bool = false) -> Part:
	var p := Part.new()
	p.painter = paint
	p.position = pos
	if additive:
		p.material = Gfx.add_material()
	else:
		p.use_parent_material = true
	parent.add_child(p)
	return p


## Redibujo limitado (por defecto 20 Hz): para brillos y pulsos lentos que no necesitan cada frame.
func soft_redraw(interval_ms: int = 50) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_redraw_ms >= interval_ms:
		_last_redraw_ms = now
		queue_redraw()


func _draw() -> void:
	Prof.begin("part_draw")
	__draw_impl()
	Prof.end("part_draw")


func __draw_impl() -> void:
	if painter.is_valid():
		painter.call(self)
