class_name Jaguar
extends RoleCharger
## Jaguar de obsidiana: felino de oro viejo con manchas de obsidiana y vetas de jade. Acecha en curvas, se agazapa
## (cuerpo bajo, cola tensa, ojos brillando) y arranca una carrera que acelera: se esquiva de lado.

var legs_p: Part
var body_p: Part
var head_p: Part
var tail_p: Part
var glow_p: Part
var walk_ph := 0.0
var crouch := 0.0


func _build() -> void:
	kind_name = "jaguar"
	hp = 20.0
	radius = 15.0
	hit_r = 19.0
	hit_off = Vector2(0, -14)
	speed = 135.0
	charge_speed = 350.0
	bar_y = -42.0
	glow_col = Color("3dd9a8")
	spawn_dur = 0.7
	legs_p = Part.make(vis, _paint_legs, Vector2(0, 0))
	tail_p = Part.make(vis, _paint_tail, Vector2(-20, -16))
	body_p = Part.make(vis, _paint_body, Vector2(0, -15))
	head_p = Part.make(vis, _paint_head, Vector2(21, -19))
	glow_p = Part.make(head_p, _paint_glow, Vector2.ZERO, true)


func _death_chunks() -> Array:
	return [Color("d9a24a"), Color("8a5a1c"), Color("1a1410"), Color("3dd9a8")]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(2, 0), 28.0, Color(0, 0, 0, 0.5))


func _leg(c: Part, hip: Vector2, ph: float, dark: bool) -> void:
	var ink := Gfx.INK
	var swing := sin(ph) * 8.0
	var lift := maxf(0.0, cos(ph)) * 5.0
	var foot := Vector2(hip.x + swing, -lift)
	var knee := Vector2(hip.x + swing * 0.4 + 3.0, hip.y * 0.5 - lift * 0.3)
	var col := Color("b8883a") if not dark else Color("6a4a1c")
	c.draw_polyline(PackedVector2Array([hip, knee, foot]), ink, 6.0, true)
	c.draw_polyline(PackedVector2Array([hip, knee, foot]), col, 3.6, true)
	c.draw_line(foot, foot + Vector2(3.5, 0.5), ink, 3.6, true)
	c.draw_line(foot + Vector2(1, 0), foot + Vector2(4.5, 0.5), Color("1a1410"), 1.6, true)


func _paint_legs(c: Part) -> void:
	_leg(c, Vector2(-16, -10), walk_ph + PI, true)
	_leg(c, Vector2(12, -10), walk_ph, true)
	_leg(c, Vector2(-12, -9), walk_ph, false)
	_leg(c, Vector2(16, -9), walk_ph + PI, false)


func _paint_tail(c: Part) -> void:
	var ink := Gfx.INK
	var sw := sin(t * 3.0) * 0.4 + crouch * -0.6
	var pts := PackedVector2Array([Vector2.ZERO, Vector2(-10, -4 + sw * 8.0), Vector2(-18, -14 + sw * 14.0), Vector2(-20, -24 + sw * 16.0)])
	c.draw_polyline(pts, ink, 7.0, true)
	c.draw_polyline(pts, Color("c8963f"), 4.2, true)
	c.draw_circle(pts[3], 3.2, Color("1a1410"))


func _paint_body(c: Part) -> void:
	var ink := Gfx.INK
	var body := PackedVector2Array([Vector2(-22, -2), Vector2(-17, -12), Vector2(0, -15), Vector2(16, -13), Vector2(22, -6), Vector2(20, 5), Vector2(0, 8), Vector2(-18, 6)])
	Gfx.gpoly(c, body, Color("e0b058"), Color("8a5a1c"), ink, 2.4)
	# manchas de obsidiana
	for p in [Vector2(-10, -6), Vector2(2, -9), Vector2(12, -4), Vector2(-3, 0), Vector2(-14, 1)]:
		c.draw_circle(p, 2.8, Color("1a1410"))
		c.draw_circle(p, 1.2, Color("3dd9a8", 0.7))
	# collar de jade
	c.draw_line(Vector2(14, -12), Vector2(17, 4), Color("3dd9a8"), 2.4)
	c.draw_line(Vector2(-4, -15), Vector2(-4, 8), Color(0, 0, 0, 0.25), 1.6)


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	Gfx.gell(c, Vector2(2, 0), 11.0, 9.0, Color("e8bc62"), Color("9a6a22"), ink, 2.2)
	# orejas
	Gfx.poly(c, PackedVector2Array([Vector2(-5, -7), Vector2(-3, -14), Vector2(2, -8)]), Color("c8963f"), ink, 1.4)
	Gfx.poly(c, PackedVector2Array([Vector2(3, -8), Vector2(7, -14), Vector2(9, -6)]), Color("c8963f"), ink, 1.4)
	# hocico y colmillos
	Gfx.ell(c, Vector2(11, 3), 5.5, 4.0, Color("f0d090"), ink, 1.6)
	c.draw_colored_polygon(PackedVector2Array([Vector2(8, 5), Vector2(10, 5), Vector2(9, 10)]), Color.WHITE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(13, 5), Vector2(15, 5), Vector2(14, 10)]), Color.WHITE)
	# ojo
	var glow := 0.5 + crouch * 0.5
	c.draw_colored_polygon(PackedVector2Array([Vector2(5, -3), Vector2(11, -2), Vector2(10, 1), Vector2(5, 0)]), Color("3dd9a8").lerp(Color.WHITE, glow * 0.5))
	c.draw_circle(Vector2(0, -1), 1.4, Color("1a1410"))


func _paint_glow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(8, -1), 12.0 + crouch * 14.0, Color(0.24, 0.85, 0.65, 0.3 + crouch * 0.5))


func _animate(dt: float) -> void:
	var spd := vel.length()
	walk_ph += dt * (4.0 + spd * 0.075)
	var tgt := 0.0
	if state == ST_REAR:
		tgt = rear_k
	elif state == ST_STUN:
		tgt = 0.5
	crouch = lerpf(crouch, tgt, clampf(dt * 12.0, 0.0, 1.0))
	var stretch := 1.0
	if state == ST_CHARGE:
		stretch = 1.15
	var bob := absf(sin(walk_ph)) * 1.2 * clampf(spd / speed, 0.0, 1.5)
	body_p.position = Vector2(0, -15 - bob + crouch * 4.0)
	body_p.scale = Vector2(stretch, 1.0 - crouch * 0.1)
	body_p.rotation = -crouch * 0.1
	head_p.position = Vector2(21 + (3.0 if state == ST_CHARGE else 0.0), -19 - bob + crouch * 7.0)
	head_p.rotation = crouch * 0.25 + (0.15 if state == ST_CHARGE else 0.0)
	tail_p.position = Vector2(-20, -16 - bob + crouch * 3.0)
	legs_p.queue_redraw()
	body_p.queue_redraw()
	head_p.queue_redraw()
	tail_p.queue_redraw()
	glow_p.soft_redraw()
