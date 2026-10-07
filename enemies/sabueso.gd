class_name Sabueso
extends RoleCharger
## Sabueso de la fortaleza: lobo de guerra con collar de cadenas y ojos encendidos. Embiste en rafagas cortas.

var legs_p: Part
var body_p: Part
var head_p: Part
var tail_p: Part
var walk_ph := 0.0
var crouch := 0.0


func _build() -> void:
	kind_name = "sabueso"
	hp = 12.0
	radius = 12.0
	hit_r = 16.0
	hit_off = Vector2(0, -12)
	speed = 150.0
	charge_speed = 390.0
	charge_accel = 900.0
	charge_time = 0.65
	rear_time = 0.5
	stun_time = 0.9
	bar_y = -36.0
	glow_col = Color("e0405a")
	spawn_dur = 0.6
	stalk_r = 200.0
	cd_min = 1.2
	cd_max = 2.4
	legs_p = Part.make(vis, _paint_legs, Vector2.ZERO)
	tail_p = Part.make(vis, _paint_tail, Vector2(-17, -14))
	body_p = Part.make(vis, _paint_body, Vector2(0, -13))
	head_p = Part.make(vis, _paint_head, Vector2(18, -17))


func _death_chunks() -> Array:
	return [Color("34304a"), Color("1a1828"), Color("8a8ea8"), Color("e0405a")]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(2, 0), 24.0, Color(0, 0, 0, 0.5))


func _paint_legs(c: Part) -> void:
	var ink := Gfx.INK
	var pairs := [[Vector2(-13, -9), walk_ph + PI, true], [Vector2(10, -9), walk_ph, true], [Vector2(-10, -8), walk_ph, false], [Vector2(13, -8), walk_ph + PI, false]]
	for pr in pairs:
		var hip: Vector2 = pr[0]
		var ph: float = pr[1]
		var swing := sin(ph) * 7.0
		var lift := maxf(0.0, cos(ph)) * 4.5
		var foot := Vector2(hip.x + swing, -lift)
		var knee := Vector2(hip.x + swing * 0.4 + 2.5, hip.y * 0.5 - lift * 0.3)
		c.draw_polyline(PackedVector2Array([hip, knee, foot]), ink, 5.6, true)
		c.draw_polyline(PackedVector2Array([hip, knee, foot]), Color("34304a") if not pr[2] else Color("1e1c30"), 3.2, true)
		c.draw_line(foot, foot + Vector2(3.0, 0.4), ink, 3.2, true)


func _paint_tail(c: Part) -> void:
	var ink := Gfx.INK
	var sw := sin(t * 5.0) * 0.5
	var pts := PackedVector2Array([Vector2.ZERO, Vector2(-8, -3 + sw * 5.0), Vector2(-14, -9 + sw * 8.0)])
	c.draw_polyline(pts, ink, 6.0, true)
	c.draw_polyline(pts, Color("34304a"), 3.4, true)


func _paint_body(c: Part) -> void:
	var ink := Gfx.INK
	var body := PackedVector2Array([Vector2(-19, -1), Vector2(-14, -10), Vector2(2, -12), Vector2(15, -10), Vector2(19, -3), Vector2(16, 5), Vector2(0, 7), Vector2(-15, 5)])
	Gfx.gpoly(c, body, Color("4a4666"), Color("1e1c30"), ink, 2.2)
	# lomo erizado
	for k in 6:
		var x := -12.0 + float(k) * 5.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 2, -10 - float(k % 2)), Vector2(x, -15 - float(k % 2) * 2.0), Vector2(x + 3, -10)]), Color("2a2840"))
	# cadenas
	c.draw_line(Vector2(12, -9), Vector2(14, 5), Color("a8acc8"), 2.4)
	c.draw_line(Vector2(-6, -11), Vector2(-9, 6), Color(0.65, 0.68, 0.8, 0.55), 1.4)
	c.draw_circle(Vector2(0, -2), 1.4, Color("e0405a", 0.8))


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	Gfx.gell(c, Vector2(2, 0), 9.5, 8.0, Color("5a5678"), Color("2a2840"), ink, 2.2)
	Gfx.poly(c, PackedVector2Array([Vector2(-5, -6), Vector2(-3, -13), Vector2(1, -7)]), Color("34304a"), ink, 1.3)
	Gfx.poly(c, PackedVector2Array([Vector2(3, -7), Vector2(7, -13), Vector2(8, -5)]), Color("34304a"), ink, 1.3)
	Gfx.ell(c, Vector2(10, 3), 5.0, 3.4, Color("3a3652"), ink, 1.5)
	c.draw_colored_polygon(PackedVector2Array([Vector2(7, 5), Vector2(9, 5), Vector2(8, 10)]), Color.WHITE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(12, 5), Vector2(14, 5), Vector2(13, 10)]), Color.WHITE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(4, -3), Vector2(10, -2), Vector2(9, 1), Vector2(4, 0)]), Color("ff5a7a").lerp(Color.WHITE, crouch * 0.5))


func _animate(dt: float) -> void:
	var spd := vel.length()
	walk_ph += dt * (4.5 + spd * 0.08)
	var tgt := 0.0
	if state == ST_REAR:
		tgt = rear_k
	elif state == ST_STUN:
		tgt = 0.6
	crouch = lerpf(crouch, tgt, clampf(dt * 14.0, 0.0, 1.0))
	var bob := absf(sin(walk_ph)) * 1.2 * clampf(spd / speed, 0.0, 1.5)
	body_p.position = Vector2(0, -13 - bob + crouch * 4.0)
	body_p.scale = Vector2(1.15 if state == ST_CHARGE else 1.0, 1.0 - crouch * 0.12)
	head_p.position = Vector2(18 + (3.0 if state == ST_CHARGE else 0.0), -17 - bob + crouch * 6.0)
	head_p.rotation = crouch * 0.3
	tail_p.position = Vector2(-17, -14 - bob + crouch * 3.0)
	legs_p.queue_redraw()
	body_p.queue_redraw()
	head_p.queue_redraw()
	tail_p.queue_redraw()
