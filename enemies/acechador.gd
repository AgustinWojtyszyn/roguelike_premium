class_name Acechador
extends RoleCharger
## Acechador: horror insectoide de patas largas con un nucleo que late. Se encorva (postura), el nucleo se enciende,
## y se lanza con aceleracion gradual. Si choca con una pared queda aturdido.

var legs_p: Part
var body_p: Part
var head_p: Part
var glow_p: Part
var walk_ph := 0.0
var crouch := 0.0


func _build() -> void:
	kind_name = "acechador"
	hp = 26.0
	radius = 14.0
	hit_r = 19.0
	hit_off = Vector2(0, -18)
	speed = 120.0
	charge_speed = 340.0
	charge_accel = 520.0
	charge_time = 0.9
	rear_time = 0.85
	stun_time = 1.3
	bar_y = -48.0
	glow_col = Color("ff4fd8")
	spawn_dur = 0.8
	legs_p = Part.make(vis, _paint_legs, Vector2.ZERO)
	body_p = Part.make(vis, _paint_body, Vector2(0, -22))
	head_p = Part.make(vis, _paint_head, Vector2(16, -26))
	glow_p = Part.make(body_p, _paint_glow, Vector2.ZERO, true)


func _death_chunks() -> Array:
	return [Color("3a2470"), Color("120a2a"), Color("ff4fd8"), Color("4fffe8")]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(0, 0), 30.0, Color(0, 0, 0, 0.5))


func _paint_legs(c: Part) -> void:
	var ink := Gfx.INK
	for layer in 2:
		for i in 3:
			var hx := -12.0 + float(i) * 11.0
			var hip := Vector2(hx, -20.0 + (2.0 if layer == 1 else 0.0))
			var ph := walk_ph + float(i) * 2.0 + (PI if (i % 2 == 0) != (layer == 1) else 0.0)
			var step := sin(ph) * 9.0
			var lift := maxf(0.0, cos(ph)) * 7.0
			var foot := Vector2(hx + step + float(i - 1) * 6.0, -lift)
			var knee := Vector2(hx + float(i - 1) * 10.0 + step * 0.3, -40.0 - lift * 0.2 + crouch * 6.0)
			var col := Color("4a2a8a") if layer == 1 else Color("2a1654")
			c.draw_polyline(PackedVector2Array([hip, knee, foot]), ink, 5.2, true)
			c.draw_polyline(PackedVector2Array([hip, knee, foot]), col, 3.0, true)
			c.draw_circle(knee, 2.0, Color("4fffe8", 0.9) if layer == 1 else Color("2a8a80", 0.7))


func _paint_body(c: Part) -> void:
	var ink := Gfx.INK
	var body := PackedVector2Array([Vector2(-18, 2), Vector2(-14, -9), Vector2(0, -12), Vector2(14, -8), Vector2(18, 0), Vector2(10, 8), Vector2(-8, 8)])
	Gfx.gpoly(c, body, Color("5a34a0"), Color("1c0e3c"), ink, 2.4)
	# placas
	for k in 3:
		var x := -10.0 + float(k) * 8.0
		c.draw_polyline(PackedVector2Array([Vector2(x, -10), Vector2(x - 2, -2), Vector2(x - 1, 6)]), Color(0.02, 0.0, 0.08, 0.7), 1.8, true)
	# nucleo que late
	var pulse := 0.5 + 0.5 * sin(t * (4.0 + crouch * 14.0))
	c.draw_circle(Vector2(0, -2), 4.0 + pulse * 1.6, Color("ff4fd8").lerp(Color.WHITE, crouch * 0.5))
	c.draw_arc(Vector2(0, -2), 6.5, 0, TAU, 12, Color("4fffe8", 0.8), 1.4, true)
	# espinas dorsales
	for k in 3:
		c.draw_colored_polygon(PackedVector2Array([Vector2(-8 + float(k) * 8.0, -11), Vector2(-6 + float(k) * 8.0, -19), Vector2(-3 + float(k) * 8.0, -10)]), Color("2a1654"))


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	Gfx.gell(c, Vector2(2, 0), 8.0, 6.6, Color("4a2a8a"), Color("1c0e3c"), ink, 2.0)
	for s in [-1.0, 1.0]:
		c.draw_circle(Vector2(5, s * 3.0), 2.0, Color("4fffe8"))
	c.draw_polyline(PackedVector2Array([Vector2(9, 2), Vector2(13, 5), Vector2(11, 8)]), ink, 3.4, true)
	c.draw_polyline(PackedVector2Array([Vector2(9, 2), Vector2(13, 5), Vector2(11, 8)]), Color("e8e0ff"), 1.6, true)
	c.draw_polyline(PackedVector2Array([Vector2(9, -2), Vector2(13, -5), Vector2(11, -8)]), ink, 3.4, true)
	c.draw_polyline(PackedVector2Array([Vector2(9, -2), Vector2(13, -5), Vector2(11, -8)]), Color("e8e0ff"), 1.6, true)


func _paint_glow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(0, -2), 18.0 + crouch * 24.0, Color(1.0, 0.3, 0.85, 0.25 + crouch * 0.5))


func _animate(dt: float) -> void:
	var spd := vel.length()
	walk_ph += dt * (3.5 + spd * 0.06)
	var tgt := 0.0
	if state == ST_REAR:
		tgt = rear_k
	elif state == ST_STUN:
		tgt = 0.8
	crouch = lerpf(crouch, tgt, clampf(dt * 10.0, 0.0, 1.0))
	var bob := absf(sin(walk_ph)) * 1.5 * clampf(spd / speed, 0.0, 1.5)
	body_p.position = Vector2(0, -22 - bob + crouch * 7.0)
	body_p.rotation = -crouch * 0.12
	head_p.position = Vector2(16 + (2.0 if state == ST_CHARGE else 0.0), -26 - bob + crouch * 10.0)
	head_p.rotation = crouch * 0.3
	legs_p.queue_redraw()
	body_p.queue_redraw()
	head_p.queue_redraw()
	glow_p.queue_redraw()
