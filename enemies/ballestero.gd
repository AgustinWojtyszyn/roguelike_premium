class_name Ballestero
extends RoleShooter
## Ballestero: capucha, cota de malla y una ballesta pesada. Mantiene gran distancia; carga con lentitud (se ve el
## virote brillar y la ballesta bajar de punta) y dispara un virote rapido. Despues reposiciona.

var legs_p: Part
var torso_p: Part
var head_p: Part
var bow: Node2D
var bow_p: Part
var glow_p: Part
var walk_ph := 0.0


func _build() -> void:
	kind_name = "ballestero"
	hp = 13.0
	radius = 11.0
	hit_r = 15.0
	hit_off = Vector2(0, -23)
	muzzle_off = Vector2(0, -24)
	speed = 100.0
	bar_y = -54.0
	glow_col = Color("ffd24a")
	b_col = Color("e8d8b0")
	b_style = Bullets.Style.ARROW
	b_speed = 620.0
	burst = 1
	windup = 0.95
	pref_min = 320.0
	pref_max = 470.0
	cd_min = 2.0
	cd_max = 3.2
	lead = 0.55
	rec_t = 0.9
	legs_p = Part.make(vis, _paint_legs, Vector2.ZERO)
	torso_p = Part.make(vis, _paint_torso, Vector2(0, -14))
	head_p = Part.make(vis, _paint_head, Vector2(1, -30))
	bow = Node2D.new()
	bow.use_parent_material = true
	bow.position = Vector2(0, -24)
	vis.add_child(bow)
	bow_p = Part.make(bow, _paint_bow, Vector2(6, 0))
	glow_p = Part.make(bow, _paint_glow, Vector2.ZERO, true)


func _death_chunks() -> Array:
	return [Color("5a4a3a"), Color("8a8ea8"), Color("2a2230"), Color("c8203c")]


func _paint_legs(c: Part) -> void:
	var ink := Gfx.INK
	for s in [-1.0, 1.0]:
		var ph := walk_ph + (0.0 if s > 0.0 else PI)
		var sw := sin(ph) * 4.0
		var lift := maxf(0.0, cos(ph)) * 3.0
		var hip := Vector2(s * 3.5, -14.0)
		var foot := Vector2(s * 3.5 + sw, -lift)
		c.draw_polyline(PackedVector2Array([hip, foot]), ink, 7.0, true)
		c.draw_polyline(PackedVector2Array([hip, foot]), Color("4a3e5a") if s > 0.0 else Color("2e2638"), 4.4, true)
		c.draw_rect(Rect2(foot.x - 3.5, foot.y - 2.0, 8.0, 3.5), Color("1e1822"))


func _paint_torso(c: Part) -> void:
	var ink := Gfx.INK
	Gfx.gpoly(c, PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(9, -10), Vector2(6, -16), Vector2(-6, -16), Vector2(-9, -10)]), Color("6a6e88"), Color("34364a"), ink, 2.2)
	for k in 4:
		c.draw_line(Vector2(-7, -3 - float(k) * 3.4), Vector2(7, -3 - float(k) * 3.4), Color(1, 1, 1, 0.14), 1.2)
	c.draw_line(Vector2(-7, -2), Vector2(8, -12), Color("5a3a22"), 3.0)
	c.draw_rect(Rect2(-9, -2, 18, 3), Color("3a2a22"))


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	var hood := PackedVector2Array([Vector2(-10, 2), Vector2(-11, -10), Vector2(-5, -17), Vector2(5, -17), Vector2(10, -10), Vector2(9, 2), Vector2(3, -2), Vector2(-4, -2)])
	Gfx.gpoly(c, hood, Color("3a3042"), Color("1a1422"), ink, 2.2)
	Gfx.ell(c, Vector2(3, -6), 5.5, 6.5, Color("0c0810"), ink, 1.4)
	c.draw_rect(Rect2(2, -8.4, 7, 2.0), Color(glow_col, 0.6 + windup_k * 0.4))
	c.draw_circle(Vector2(1, -5), 1.0, Color(glow_col, 0.8))


func _paint_bow(c: Part) -> void:
	var ink := Gfx.INK
	var down := windup_k * 0.0
	# culata y carril
	Gfx.grrect(c, Rect2(-8 - recoil * 3.0, -2.5, 34, 5), 1.8, Color("6a4a2c"), Color("34221a"), ink, 1.8)
	# arco (se tensa con windup)
	var flex := 1.0 - windup_k * 0.6
	var bpts := PackedVector2Array([Vector2(18, -14), Vector2(24 - flex * 4.0, -7), Vector2(25 - flex * 3.0, 0), Vector2(24 - flex * 4.0, 7), Vector2(18, 14)])
	c.draw_polyline(bpts, ink, 5.0, true)
	c.draw_polyline(bpts, Color("8a6a3c"), 3.0, true)
	c.draw_line(Vector2(18, -14), Vector2(18 - windup_k * 10.0, 0), Color("e8e0c8"), 1.2)
	c.draw_line(Vector2(18, 14), Vector2(18 - windup_k * 10.0, 0), Color("e8e0c8"), 1.2)
	# virote
	var vx := 10.0 - windup_k * 10.0
	c.draw_line(Vector2(vx, 0), Vector2(34, 0), ink, 3.0, true)
	c.draw_line(Vector2(vx, 0), Vector2(34, 0), Color("c8c0a0"), 1.4, true)
	c.draw_colored_polygon(PackedVector2Array([Vector2(37, 0), Vector2(32, -3), Vector2(32, 3)]), Color("f0f0ff").lerp(Color("ffd24a"), windup_k))


func _paint_glow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(34, 0), 6.0 + windup_k * 20.0, Color(glow_col, 0.1 + windup_k * 0.7))


func _animate(dt: float) -> void:
	var spd := vel.length()
	walk_ph += dt * (4.0 + spd * 0.09)
	recoil = maxf(0.0, recoil - dt * 5.0)
	var bob := absf(sin(walk_ph)) * 1.4 * clampf(spd / speed, 0.0, 1.0)
	torso_p.position = Vector2(0, -14 - bob)
	head_p.position = Vector2(1, -30 - bob * 1.1)
	bow.position = Vector2(0, -24 - bob)
	bow.rotation = aim_dir.angle()
	bow.scale.y = 1.0 if aim_dir.x >= 0.0 else -1.0
	legs_p.queue_redraw()
	torso_p.queue_redraw()
	head_p.queue_redraw()
	bow_p.queue_redraw()
	glow_p.soft_redraw()
