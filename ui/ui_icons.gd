class_name UiIcons
extends RefCounted
## Iconos vectoriales (habilidades, perks, monedas...). Se dibujan centrados en `c` con tamano `s` (radio aprox).

static func draw(ci: CanvasItem, id: String, c: Vector2, s: float, col: Color, dark: Color = Color(0.03, 0.05, 0.1, 0.9)) -> void:
	match id:
		"overclock", "bolt", "zap":
			var p := PackedVector2Array([c + Vector2(0.15, -1.0) * s, c + Vector2(-0.55, 0.1) * s, c + Vector2(-0.05, 0.1) * s, c + Vector2(-0.25, 1.0) * s, c + Vector2(0.55, -0.15) * s, c + Vector2(0.05, -0.15) * s])
			ci.draw_colored_polygon(p, col)
			_outline(ci, p, dark, maxf(1.5, s * 0.1))
		"mirror", "shield", "bulwark":
			var p := PackedVector2Array([c + Vector2(0, -1.0) * s, c + Vector2(0.8, -0.6) * s, c + Vector2(0.65, 0.4) * s, c + Vector2(0, 1.0) * s, c + Vector2(-0.65, 0.4) * s, c + Vector2(-0.8, -0.6) * s])
			ci.draw_colored_polygon(p, col)
			_outline(ci, p, dark, maxf(1.5, s * 0.1))
			if id == "mirror":
				ci.draw_line(c + Vector2(-0.3, 0.5) * s, c + Vector2(0.4, -0.5) * s, Color(1, 1, 1, 0.9), s * 0.14, true)
			else:
				ci.draw_line(c + Vector2(0, -0.6) * s, c + Vector2(0, 0.55) * s, dark, s * 0.14, true)
		"nanocloud", "heart", "cross":
			ci.draw_rect(Rect2(c + Vector2(-0.22, -0.8) * s, Vector2(0.44, 1.6) * s), col)
			ci.draw_rect(Rect2(c + Vector2(-0.8, -0.22) * s, Vector2(1.6, 0.44) * s), col)
			ci.draw_rect(Rect2(c + Vector2(-0.22, -0.8) * s, Vector2(0.44, 1.6) * s), dark, false, maxf(1.5, s * 0.08))
			ci.draw_rect(Rect2(c + Vector2(-0.8, -0.22) * s, Vector2(1.6, 0.44) * s), dark, false, maxf(1.5, s * 0.08))
		"turret":
			ci.draw_circle(c + Vector2(0, 0.35) * s, s * 0.6, col)
			ci.draw_rect(Rect2(c + Vector2(0.1, -0.35) * s, Vector2(0.95, 0.4) * s), col)
			ci.draw_arc(c + Vector2(0, 0.35) * s, s * 0.6, 0, TAU, 16, dark, maxf(1.5, s * 0.1), true)
			ci.draw_rect(Rect2(c + Vector2(-0.7, 0.85) * s, Vector2(1.4, 0.25) * s), dark)
		"mark", "aim", "eye":
			ci.draw_arc(c, s * 0.7, 0, TAU, 20, col, maxf(2.0, s * 0.15), true)
			ci.draw_circle(c, s * 0.18, col)
			for k in 4:
				var d := Vector2.from_angle(PI * 0.5 * float(k))
				ci.draw_line(c + d * s * 0.5, c + d * s * 1.0, col, maxf(2.0, s * 0.15), true)
		"whirl":
			ci.draw_arc(c, s * 0.7, 0.3, TAU - 0.5, 20, col, maxf(2.5, s * 0.2), true)
			var tip := c + Vector2.from_angle(TAU - 0.5) * s * 0.7
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-0.3, -0.5) * s, tip + Vector2(0.45, 0.2) * s, tip + Vector2(-0.5, 0.35) * s]), col)
		"phase", "ghost":
			var p := PackedVector2Array([c + Vector2(-0.7, 0.9) * s, c + Vector2(-0.7, -0.2) * s, c + Vector2(-0.4, -0.85) * s, c + Vector2(0.4, -0.85) * s, c + Vector2(0.7, -0.2) * s, c + Vector2(0.7, 0.9) * s, c + Vector2(0.35, 0.6) * s, c + Vector2(0, 0.9) * s, c + Vector2(-0.35, 0.6) * s])
			ci.draw_colored_polygon(p, col)
			_outline(ci, p, dark, maxf(1.5, s * 0.1))
			ci.draw_circle(c + Vector2(-0.25, -0.2) * s, s * 0.14, dark)
			ci.draw_circle(c + Vector2(0.25, -0.2) * s, s * 0.14, dark)
		"roar":
			for k in 3:
				ci.draw_arc(c + Vector2(-0.4, 0) * s, s * (0.45 + 0.3 * float(k)), -0.9, 0.9, 10, col, maxf(2.0, s * 0.16), true)
			ci.draw_circle(c + Vector2(-0.55, 0), s * 0.22, col)
		"storm":
			var p := PackedVector2Array([c + Vector2(0.3, -1.0) * s, c + Vector2(-0.6, 0.2) * s, c + Vector2(-0.05, 0.2) * s, c + Vector2(-0.35, 1.0) * s, c + Vector2(0.65, -0.3) * s, c + Vector2(0.1, -0.3) * s])
			ci.draw_colored_polygon(p, col)
			_outline(ci, p, dark, maxf(1.5, s * 0.1))
			ci.draw_arc(c, s * 0.95, 0.4, 2.3, 10, Color(col, 0.6), maxf(1.5, s * 0.1), true)
		"echo", "clock":
			ci.draw_arc(c, s * 0.8, 0, TAU, 24, col, maxf(2.0, s * 0.16), true)
			ci.draw_line(c, c + Vector2(0, -0.55) * s, col, maxf(2.0, s * 0.14), true)
			ci.draw_line(c, c + Vector2(0.4, 0.2) * s, col, maxf(2.0, s * 0.14), true)
		"boot":
			var p := PackedVector2Array([c + Vector2(-0.4, -0.9) * s, c + Vector2(0.2, -0.9) * s, c + Vector2(0.2, 0.1) * s, c + Vector2(0.9, 0.4) * s, c + Vector2(0.9, 0.9) * s, c + Vector2(-0.4, 0.9) * s])
			ci.draw_colored_polygon(p, col)
			_outline(ci, p, dark, maxf(1.5, s * 0.1))
		"cell":
			ci.draw_rect(Rect2(c + Vector2(-0.55, -0.7) * s, Vector2(1.1, 1.5) * s), col)
			ci.draw_rect(Rect2(c + Vector2(-0.25, -0.95) * s, Vector2(0.5, 0.25) * s), col)
			ci.draw_rect(Rect2(c + Vector2(-0.55, -0.7) * s, Vector2(1.1, 1.5) * s), dark, false, maxf(1.5, s * 0.09))
			ci.draw_rect(Rect2(c + Vector2(-0.35, 0.1) * s, Vector2(0.7, 0.55) * s), Color(1, 1, 1, 0.65))
		"coin":
			ci.draw_circle(c, s * 0.85, col)
			ci.draw_arc(c, s * 0.85, 0, TAU, 20, dark, maxf(1.5, s * 0.12), true)
			ci.draw_arc(c, s * 0.5, 0, TAU, 16, Color(1, 1, 1, 0.5), maxf(1.2, s * 0.09), true)
		"gem":
			var p := PackedVector2Array([c + Vector2(0, -0.95) * s, c + Vector2(0.8, -0.2) * s, c + Vector2(0.5, 0.85) * s, c + Vector2(-0.5, 0.85) * s, c + Vector2(-0.8, -0.2) * s])
			ci.draw_colored_polygon(p, col)
			_outline(ci, p, dark, maxf(1.5, s * 0.1))
			ci.draw_line(c + Vector2(-0.8, -0.2) * s, c + Vector2(0.8, -0.2) * s, Color(1, 1, 1, 0.6), maxf(1.2, s * 0.08), true)
		"magnet":
			ci.draw_arc(c + Vector2(0, 0.1) * s, s * 0.65, PI, TAU, 14, col, maxf(3.0, s * 0.3), true)
			ci.draw_line(c + Vector2(-0.65, 0.1) * s, c + Vector2(-0.65, 0.8) * s, col, maxf(3.0, s * 0.3))
			ci.draw_line(c + Vector2(0.65, 0.1) * s, c + Vector2(0.65, 0.8) * s, col, maxf(3.0, s * 0.3))
		"bounce":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-0.8, -0.6) * s, c + Vector2(-0.1, 0.5) * s, c + Vector2(0.4, -0.3) * s, c + Vector2(0.9, 0.5) * s]), col, maxf(2.5, s * 0.2), true)
		"boom":
			for k in 8:
				var d := Vector2.from_angle(TAU * float(k) / 8.0)
				ci.draw_line(c + d * s * 0.35, c + d * s * (1.0 if k % 2 == 0 else 0.7), col, maxf(2.0, s * 0.16), true)
			ci.draw_circle(c, s * 0.3, col)
		"star":
			var pts := PackedVector2Array()
			for k in 10:
				var r := s if k % 2 == 0 else s * 0.45
				pts.append(c + Vector2.from_angle(-PI * 0.5 + TAU * float(k) / 10.0) * r)
			ci.draw_colored_polygon(pts, col)
			_outline(ci, pts, dark, maxf(1.5, s * 0.08))
		"swap":
			ci.draw_arc(c, s * 0.7, 0.2, PI - 0.3, 10, col, maxf(2.5, s * 0.18), true)
			ci.draw_arc(c, s * 0.7, PI + 0.2, TAU - 0.3, 10, col, maxf(2.5, s * 0.18), true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.9, 0.1) * s, c + Vector2(0.35, -0.2) * s, c + Vector2(0.4, 0.5) * s]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.9, -0.1) * s, c + Vector2(-0.35, 0.2) * s, c + Vector2(-0.4, -0.5) * s]), col)
		"pause":
			ci.draw_rect(Rect2(c + Vector2(-0.55, -0.7) * s, Vector2(0.42, 1.4) * s), col)
			ci.draw_rect(Rect2(c + Vector2(0.13, -0.7) * s, Vector2(0.42, 1.4) * s), col)
		"play":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.5, -0.8) * s, c + Vector2(0.8, 0) * s, c + Vector2(-0.5, 0.8) * s]), col)
		"gear":
			for k in 8:
				var d := Vector2.from_angle(TAU * float(k) / 8.0)
				ci.draw_line(c + d * s * 0.6, c + d * s * 0.95, col, maxf(3.0, s * 0.28), true)
			ci.draw_circle(c, s * 0.68, col)
			ci.draw_circle(c, s * 0.3, dark)
		"lock":
			ci.draw_arc(c + Vector2(0, -0.2) * s, s * 0.5, PI, TAU, 12, col, maxf(2.5, s * 0.2), true)
			ci.draw_rect(Rect2(c + Vector2(-0.7, -0.2) * s, Vector2(1.4, 1.1) * s), col)
			ci.draw_circle(c + Vector2(0, 0.3) * s, s * 0.14, dark)
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-0.7, 0.05) * s, c + Vector2(-0.2, 0.6) * s, c + Vector2(0.8, -0.6) * s]), col, maxf(3.0, s * 0.25), true)
		"sword":
			ci.draw_line(c + Vector2(-0.7, 0.7) * s, c + Vector2(0.7, -0.7) * s, col, maxf(3.0, s * 0.26), true)
			ci.draw_line(c + Vector2(-0.6, 0.15) * s, c + Vector2(-0.15, 0.6) * s, col, maxf(3.0, s * 0.22), true)
		"chest":
			ci.draw_rect(Rect2(c + Vector2(-0.9, -0.05) * s, Vector2(1.8, 0.95) * s), col)
			ci.draw_rect(Rect2(c + Vector2(-0.9, -0.05) * s, Vector2(1.8, 0.95) * s), dark, false, maxf(1.5, s * 0.1))
			var lid := PackedVector2Array([c + Vector2(-0.9, -0.05) * s, c + Vector2(-0.75, -0.7) * s, c + Vector2(0.75, -0.7) * s, c + Vector2(0.9, -0.05) * s])
			ci.draw_colored_polygon(lid, col.lightened(0.15))
			_outline(ci, lid, dark, maxf(1.5, s * 0.1))
			ci.draw_rect(Rect2(c + Vector2(-0.14, -0.2) * s, Vector2(0.28, 0.5) * s), dark)
			ci.draw_line(c + Vector2(-0.9, 0.3) * s, c + Vector2(0.9, 0.3) * s, dark, maxf(1.2, s * 0.08))
		"gift":
			ci.draw_rect(Rect2(c + Vector2(-0.8, -0.2) * s, Vector2(1.6, 1.0) * s), col)
			ci.draw_rect(Rect2(c + Vector2(-0.9, -0.55) * s, Vector2(1.8, 0.4) * s), col.lightened(0.15))
			ci.draw_rect(Rect2(c + Vector2(-0.14, -0.55) * s, Vector2(0.28, 1.35) * s), Color.WHITE)
			ci.draw_arc(c + Vector2(-0.3, -0.75) * s, s * 0.3, 0, TAU, 8, Color.WHITE, maxf(1.5, s * 0.1), true)
			ci.draw_arc(c + Vector2(0.3, -0.75) * s, s * 0.3, 0, TAU, 8, Color.WHITE, maxf(1.5, s * 0.1), true)
		"skull":
			ci.draw_circle(c + Vector2(0, -0.1) * s, s * 0.75, col)
			ci.draw_rect(Rect2(c + Vector2(-0.4, 0.4) * s, Vector2(0.8, 0.55) * s), col)
			ci.draw_circle(c + Vector2(-0.3, -0.15) * s, s * 0.2, dark)
			ci.draw_circle(c + Vector2(0.3, -0.15) * s, s * 0.2, dark)
		"chev_l":
			ci.draw_polyline(PackedVector2Array([c + Vector2(0.45, -0.8) * s, c + Vector2(-0.4, 0) * s, c + Vector2(0.45, 0.8) * s]), col, maxf(3.0, s * 0.3), true)
		"chev_r":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-0.45, -0.8) * s, c + Vector2(0.4, 0) * s, c + Vector2(-0.45, 0.8) * s]), col, maxf(3.0, s * 0.3), true)
		"door":
			ci.draw_rect(Rect2(c + Vector2(-0.55, -0.9) * s, Vector2(1.1, 1.8) * s), col)
			ci.draw_rect(Rect2(c + Vector2(-0.55, -0.9) * s, Vector2(1.1, 1.8) * s), dark, false, maxf(1.5, s * 0.1))
			ci.draw_circle(c + Vector2(0.25, 0.1) * s, s * 0.12, dark)
		"news":
			ci.draw_rect(Rect2(c + Vector2(-0.8, -0.7) * s, Vector2(1.6, 1.4) * s), col)
			for k in 3:
				ci.draw_line(c + Vector2(-0.5, -0.3 + k * 0.4) * s, c + Vector2(0.5, -0.3 + k * 0.4) * s, dark, maxf(1.5, s * 0.1))
		"person":
			ci.draw_circle(c + Vector2(0, -0.4) * s, s * 0.4, col)
			ci.draw_arc(c + Vector2(0, 1.0) * s, s * 0.8, PI, TAU, 12, col, maxf(3.0, s * 0.35), true)
		"target":
			ci.draw_arc(c, s * 0.8, 0, TAU, 20, col, maxf(2.0, s * 0.14), true)
			ci.draw_arc(c, s * 0.4, 0, TAU, 14, col, maxf(2.0, s * 0.14), true)
		"cart":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-0.9, -0.7) * s, c + Vector2(-0.6, -0.7) * s, c + Vector2(-0.3, 0.4) * s, c + Vector2(0.7, 0.4) * s, c + Vector2(0.85, -0.3) * s, c + Vector2(-0.5, -0.3) * s]), col, maxf(2.5, s * 0.2), true)
			ci.draw_circle(c + Vector2(-0.15, 0.8) * s, s * 0.17, col)
			ci.draw_circle(c + Vector2(0.55, 0.8) * s, s * 0.17, col)
		"book":
			ci.draw_rect(Rect2(c + Vector2(-0.8, -0.7) * s, Vector2(1.6, 1.4) * s), col)
			ci.draw_line(c + Vector2(0, -0.7) * s, c + Vector2(0, 0.7) * s, dark, maxf(1.5, s * 0.1))
		_:
			ci.draw_circle(c, s * 0.6, col)


static func _outline(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	var p := pts.duplicate()
	p.append(pts[0])
	ci.draw_polyline(p, col, w, true)
