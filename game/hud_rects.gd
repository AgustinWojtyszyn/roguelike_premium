class_name HudRects
extends RefCounted
## Rects/centros de los controles tactiles y del boton de pausa (compartidos por Hud y GameInput).

static var safe := Vector4.ZERO


static func pause_rect(vs: Vector2) -> Rect2:
	return Rect2(vs.x - 82.0 - safe.z, 14.0 + safe.y, 66.0, 66.0)


static func swap_center(vs: Vector2) -> Vector2:
	return Vector2(vs.x - 232.0 - safe.z, vs.y - 268.0 - safe.w)


static func ability_center(vs: Vector2) -> Vector2:
	return Vector2(vs.x - 108.0 - safe.z, vs.y - 286.0 - safe.w)
