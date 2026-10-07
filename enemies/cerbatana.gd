class_name Cerbatana
extends RoleShooter
## Cazador de cerbatana: tocado de plumas, pintura de guerra y un tubo largo que escupe dardos de jade en rafaga.

var legs_p: Part
var torso_p: Part
var head_p: Part
var pipe: Node2D
var pipe_p: Part
var glow_p: Part
var walk_ph := 0.0


func _build() -> void:
	kind_name = "cerbatana"
	hp = 11.0
	radius = 11.0
	hit_r = 15.0
	hit_off = Vector2(0, -22)
	muzzle_off = Vector2(0, -24)
	speed = 112.0
	bar_y = -52.0
	glow_col = Color("3dd9a8")
	b_col = Color("3dd9a8")
	b_style = Bullets.Style.SHARD
	b_speed = 340.0
	burst = 3
	burst_gap = 0.13
	windup = 0.5
	pref_min = 230.0
	pref_max = 380.0
	lead = 0.35
	legs_p = Part.make(vis, _paint_legs, Vector2(0, 0))
	torso_p = Part.make(vis, _paint_torso, Vector2(0, -14))
	head_p = Part.make(vis, _paint_head, Vector2(1, -30))
	pipe = Node2D.new()
	pipe.use_parent_material = true
	pipe.position = Vector2(0, -24)
	vis.add_child(pipe)
	pipe_p = Part.make(pipe, _paint_pipe, Vector2(4, 0))
	glow_p = Part.make(pipe, _paint_glow, Vector2(0, 0), true)


func _death_chunks() -> Array:
	return [Color("a8442a"), Color("3dd9a8"), Color("d9a24a"), Color("3a2a22")]


func _paint_legs(c: Part) -> void:
	var ink := Gfx.INK
	for s in [-1.0, 1.0]:
		var sw := sin(walk_ph + (0.0 if s > 0.0 else PI)) * 4.0
		var lift := maxf(0.0, cos(walk_ph + (0.0 if s > 0.0 else PI))) * 3.0
		var hip := Vector2(s * 3.5, -14.0)
		var foot := Vector2(s * 3.5 + sw, -lift)
		c.draw_polyline(PackedVector2Array([hip, foot]), ink, 7.0, true)
		c.draw_polyline(PackedVector2Array([hip, foot]), Color("8a5a3a") if s > 0.0 else Color("5a3a28"), 4.4, true)
		c.draw_rect(Rect2(foot.x - 3.5, foot.y - 2.0, 8.0, 3.5), Color("3a2a22"))
		c.draw_line(Vector2(foot.x - 3.0, foot.y - 6.0), Vector2(foot.x + 3.0, foot.y - 6.0), Color("3dd9a8"), 1.6)


func _paint_torso(c: Part) -> void:
	var ink := Gfx.INK
	Gfx.gpoly(c, PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(9, -10), Vector2(6, -16), Vector2(-6, -16), Vector2(-9, -10)]), Color("a8442a"), Color("5a2414"), ink, 2.2)
	# taparrabo y peto de jade
	Gfx.gpoly(c, PackedVector2Array([Vector2(-6, -2), Vector2(6, -2), Vector2(4, 8), Vector2(-4, 8)]), Color("d9a24a"), Color("8a5a1c"), ink, 1.4)
	Gfx.poly(c, PackedVector2Array([Vector2(0, -13), Vector2(4, -9), Vector2(0, -5), Vector2(-4, -9)]), Color("3dd9a8"), ink, 1.4)
	c.draw_line(Vector2(-8, -10), Vector2(8, -10), Color("e8c06a"), 1.6)


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	# plumas
	for k in 7:
		var a := -PI * 0.5 + (float(k) - 3.0) * 0.28
		var tip := Vector2(cos(a), sin(a)) * 18.0 + Vector2(0, -6)
		var col := Color("3dd9a8") if k % 2 == 0 else Color("e0405a")
		c.draw_line(Vector2(0, -8), tip, ink, 5.0, true)
		c.draw_line(Vector2(0, -8), tip, col, 3.0, true)
	Gfx.ell(c, Vector2(0, -2), 8.0, 8.4, Color("d9a070"), ink, 2.0)
	# pintura de guerra
	c.draw_rect(Rect2(-6, -3.5, 12, 2.4), Color("1a1410"))
	c.draw_line(Vector2(2, -1), Vector2(2, 5), Color("3dd9a8"), 1.6)
	c.draw_circle(Vector2(3.0, -2.2), 1.2, Color.WHITE)
	Gfx.poly(c, PackedVector2Array([Vector2(-8, -8), Vector2(0, -12), Vector2(8, -8)]), Color("e8c06a"), ink, 1.6)


func _paint_pipe(c: Part) -> void:
	var ink := Gfx.INK
	var kick := recoil * 3.0
	Gfx.grrect(c, Rect2(-6 - kick, -2.5, 32, 5), 2.0, Color("c8a060"), Color("6a4a22"), ink, 1.8)
	c.draw_line(Vector2(2 - kick, 0), Vector2(22 - kick, 0), Color("3dd9a8", 0.6 + windup_k * 0.4), 1.6)
	c.draw_circle(Vector2(26 - kick, 0), 2.4, Color("3dd9a8").lerp(Color.WHITE, windup_k * 0.7))


func _paint_glow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(30, 0), 8.0 + windup_k * 18.0, Color(0.24, 0.85, 0.65, 0.2 + windup_k * 0.6))


func _animate(dt: float) -> void:
	var spd := vel.length()
	walk_ph += dt * (4.0 + spd * 0.09)
	recoil = maxf(0.0, recoil - dt * 6.0)
	var bob := absf(sin(walk_ph)) * 1.4 * clampf(spd / speed, 0.0, 1.0)
	torso_p.position = Vector2(0, -14 - bob)
	head_p.position = Vector2(1, -30 - bob * 1.1 - windup_k * 1.0)
	pipe.position = Vector2(0, -24 - bob)
	pipe.rotation = aim_dir.angle()
	pipe.scale.y = 1.0 if aim_dir.x >= 0.0 else -1.0
	legs_p.queue_redraw()
	torso_p.queue_redraw()
	pipe_p.queue_redraw()
	glow_p.soft_redraw()
