class_name Part
extends Node2D
## Pieza dibujada por codigo: permite armar personajes con partes animables.

var painter: Callable


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


func _draw() -> void:
	if painter.is_valid():
		painter.call(self)
