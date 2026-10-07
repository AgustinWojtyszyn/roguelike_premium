class_name SafeArea
extends RefCounted
## Margenes de area segura (notch / esquinas redondeadas / barra de gestos) en unidades del viewport.
## En escritorio devuelve ceros.  Vector4: x = izquierda, y = arriba, z = derecha, w = abajo.

static func margins(node: Node) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or node.get_viewport() == null:
		return Vector4.ZERO
	var vs := node.get_viewport().get_visible_rect().size
	var s := vs.x / float(win.x)
	var r := DisplayServer.get_display_safe_area()
	if r.size.x <= 0:
		return Vector4.ZERO
	var scr := DisplayServer.screen_get_size()
	return Vector4(maxf(0.0, float(r.position.x)) * s, maxf(0.0, float(r.position.y)) * s, maxf(0.0, float(scr.x - r.end.x)) * s, maxf(0.0, float(scr.y - r.end.y)) * s)
