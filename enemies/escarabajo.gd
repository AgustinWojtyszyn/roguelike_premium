class_name Escarabajo
extends RoleMelee
## Escarabajo de jade: diminuto y veloz. Aparece en enjambres invocados; muerde tras una breve carga del caparazon.

var legs_p: Part
var body_p: Part
var walk_ph := 0.0


func _build() -> void:
	kind_name = "escarabajo"
	hp = 4.0
	radius = 8.0
	hit_r = 11.0
	hit_off = Vector2(0, -8)
	speed = 185.0
	bar_y = -24.0
	glow_col = Color("3dd9a8")
	spawn_dur = 0.45
	ring_r = 130.0
	approach_mult = 1.2
	windup = 0.32
	strike_dur = 0.1
	rec_dur = 0.6
	reach = 34.0
	attack_cd_min = 1.0
	attack_cd_max = 2.2
	legs_p = Part.make(vis, _paint_legs, Vector2.ZERO)
	body_p = Part.make(vis, _paint_body, Vector2(0, -8))


func _death_chunks() -> Array:
	return [Color("1a4a3a"), Color("3dd9a8"), Color("0a2018"), Color("e8c06a")]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 12.0, Color(0, 0, 0, 0.45))


func _paint_legs(c: Part) -> void:
	var ink := Gfx.INK
	for i in 3:
		for s in [-1.0, 1.0]:
			var ph := walk_ph + float(i) * 2.1 + (PI if s > 0.0 else 0.0)
			var x := -5.0 + float(i) * 5.0
			var foot := Vector2(x + sin(ph) * 3.0, -maxf(0.0, cos(ph)) * 2.0 + s * 0.0)
			var hip := Vector2(x, -6.0)
			c.draw_line(hip, Vector2(foot.x, foot.y), ink, 3.4, true)
			c.draw_line(hip, Vector2(foot.x, foot.y), Color("1e5a46"), 1.8, true)


func _paint_body(c: Part) -> void:
	var ink := Gfx.INK
	var open := windup_k
	Gfx.gell(c, Vector2(0, 0), 10.0, 7.0, Color("2a8a6a"), Color("0e3a2c"), ink, 2.0)
	c.draw_line(Vector2(-9, 0), Vector2(9, 0), Color(0, 0, 0, 0.5), 1.4)
	for s in [-1.0, 1.0]:
		var wing := PackedVector2Array([Vector2(0, -2), Vector2(-10 + open * 3.0, s * (7.0 + open * 5.0)), Vector2(6, s * 8.0)])
		if open > 0.1:
			c.draw_colored_polygon(wing, Color(0.6, 1.0, 0.9, 0.35))
	Gfx.gell(c, Vector2(11, 0), 4.6, 4.2, Color("3aa07a"), Color("1a5a44"), ink, 1.6)
	c.draw_circle(Vector2(13, -1.4), 1.2, Color("e8ffe8"))
	c.draw_circle(Vector2(13, 1.4), 1.2, Color("e8ffe8"))
	c.draw_polyline(PackedVector2Array([Vector2(15, -1), Vector2(19, -4), Vector2(21, -2)]), ink, 2.4, true)
	c.draw_polyline(PackedVector2Array([Vector2(15, 1), Vector2(19, 4), Vector2(21, 2)]), ink, 2.4, true)
	c.draw_circle(Vector2(-2, -2), 1.6, Color("e8c06a"))
	c.draw_circle(Vector2(3, 2), 1.4, Color("e8c06a"))


func _animate(dt: float) -> void:
	walk_ph += dt * (10.0 + vel.length() * 0.06)
	body_p.position = Vector2(0, -8 - absf(sin(walk_ph)) * 1.0 - windup_k * 2.0)
	body_p.scale = Vector2(1.0 + windup_k * 0.2, 1.0 - windup_k * 0.2)
	legs_p.queue_redraw()
	body_p.queue_redraw()
