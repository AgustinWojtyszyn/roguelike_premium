class_name Idolo
extends RoleTotem
## Idolo Vigia: mascara de piedra flotante con ojos de jade y glifos orbitando. Dispara espirales de jade y repara aliados.

var mask_p: Part
var orbit_p: Part
var glow_p: Part


func _build() -> void:
	kind_name = "idolo"
	hp = 40.0
	radius = 18.0
	hit_r = 26.0
	hit_off = Vector2(0, -42)
	muzzle_off = Vector2(0, -42)
	bar_y = -88.0
	glow_col = Color("3dd9a8")
	b_col = Color("3dd9a8")
	b_style = Bullets.Style.RUNE
	pattern_a = "spiral"
	pattern_b = "fan"
	heals = true
	big = true
	spawn_dur = 0.9
	orbit_p = Part.make(vis, _paint_orbit, Vector2(0, -42))
	mask_p = Part.make(vis, _paint_mask, Vector2(0, -42))
	glow_p = Part.make(mask_p, _paint_glow, Vector2.ZERO, true)


func _death_chunks() -> Array:
	return [Color("8a7a62"), Color("4a3e30"), Color("3dd9a8"), Color("e8c06a")]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 34.0, Color(0, 0, 0, 0.5 - sin(hover_t * 2.0) * 0.05))


func _paint_mask(c: Part) -> void:
	var ink := Gfx.INK
	var o := open_k
	# base de cabeza tallada
	var head := PackedVector2Array([Vector2(-24, -28), Vector2(24, -28), Vector2(30, -6), Vector2(22, 24), Vector2(0, 32), Vector2(-22, 24), Vector2(-30, -6)])
	Gfx.gpoly(c, head, Color("9a8a70"), Color("4e4234"), ink, 2.8)
	# corona escalonada
	for k in 3:
		var w := 22.0 - float(k) * 6.0
		var y := -28.0 - float(k) * 8.0
		Gfx.rrect(c, Rect2(-w, y - 8.0, w * 2.0, 9.0), 2.0, Color("b8a888").darkened(float(k) * 0.08), ink, 1.8)
	c.draw_rect(Rect2(-4, -48.0, 8, 4), Color(b_col, 0.5 + 0.5 * o))
	# ojos
	for s in [-1.0, 1.0]:
		var ec := Vector2(s * 11.0, -8.0)
		Gfx.rrect(c, Rect2(ec.x - 8, ec.y - 6, 16, 12), 3.0, Color("0c0a06"), ink, 1.8)
		c.draw_rect(Rect2(ec.x - 6, ec.y - 3.0 * (0.4 + 0.6 * o), 12, 6.0 * (0.4 + 0.6 * o)), b_col.lerp(Color.WHITE, o * 0.6) if o > 0.1 else Color(b_col, 0.35))
	# nariz y boca con colmillos
	c.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(5, 12), Vector2(-5, 12)]), Color("5a4a38"))
	Gfx.rrect(c, Rect2(-14, 14, 28, 9 + o * 6.0), 2.0, Color("0c0a06"), ink, 1.6)
	for k in 4:
		c.draw_colored_polygon(PackedVector2Array([Vector2(-11 + k * 7.0, 14), Vector2(-8 + k * 7.0, 14), Vector2(-9.5 + k * 7.0, 20)]), Color("e8e0c8"))
	# greca de la frente
	c.draw_polyline(PackedVector2Array([Vector2(-18, -20), Vector2(-18, -14), Vector2(-10, -14), Vector2(-10, -20), Vector2(-2, -20)]), Color(b_col, 0.8), 1.6, true)
	c.draw_polyline(PackedVector2Array([Vector2(18, -20), Vector2(18, -14), Vector2(10, -14), Vector2(10, -20), Vector2(2, -20)]), Color(b_col, 0.8), 1.6, true)


func _paint_orbit(c: Part) -> void:
	var ink := Gfx.INK
	for k in 4:
		var a := hover_t * 1.4 + TAU * float(k) / 4.0
		var p := Vector2(cos(a) * 44.0, sin(a) * 14.0 + 4.0)
		var front := sin(a) > 0.0
		var s := 7.0 if front else 5.5
		var pts := PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.8, 0), p + Vector2(0, s), p + Vector2(-s * 0.8, 0)])
		Gfx.poly(c, pts, Color("b8a888") if front else Color("6a5e4c"), ink, 1.6)
		c.draw_circle(p, 2.0, Color(b_col, 0.9 if front else 0.4))


func _paint_glow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(0, -6), 40.0 + open_k * 30.0, Color(b_col, 0.12 + open_k * 0.3))
	if heal_pulse >= 0.0:
		Gfx.draw_glow(c, Vector2(0, -6), 70.0, Color(b_col, 0.4 * (1.0 - heal_pulse / 0.6)))


func _animate(dt: float) -> void:
	var bob := sin(hover_t * 2.4) * 3.0
	mask_p.position = Vector2(0, -42 + bob)
	orbit_p.position = Vector2(0, -42 + bob)
	hit_off = Vector2(0, -42 + bob)
	mask_p.rotation = sin(hover_t * 1.1) * 0.03 + aim_dir.x * 0.04
	mask_p.queue_redraw()
	orbit_p.queue_redraw()
	glow_p.queue_redraw()
	shadow.queue_redraw()
