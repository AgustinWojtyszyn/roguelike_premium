class_name HudRects
extends RefCounted
## Rects/centros de los controles tactiles y del boton de pausa (compartidos por Hud y GameInput).

static func pause_rect(vs: Vector2) -> Rect2:
	return Rect2(vs.x - 82.0, 14.0, 66.0, 66.0)


static func swap_center(vs: Vector2) -> Vector2:
	return Vector2(vs.x - 250.0, vs.y - 120.0)


static func ability_center(vs: Vector2) -> Vector2:
	return Vector2(vs.x - 126.0, vs.y - 232.0)
