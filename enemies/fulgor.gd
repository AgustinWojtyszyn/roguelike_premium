class_name Fulgor
extends RoleShooter
## Fulgor: una esfera de realidad rota que flota con un halo y fragmentos orbitando. Se carga (halo se contrae, brillo
## magenta) y escupe un abanico de runas. Se desplaza en zigzag, nunca en linea recta.

var core_p: Part
var halo_p: Part
var glow_p: Part
var hover_t := 0.0
const HOVER := 30.0


func _build() -> void:
	kind_name = "fulgor"
	hp = 15.0
	radius = 12.0
	hit_r = 17.0
	hit_off = Vector2(0, -HOVER - 2.0)
	muzzle_off = Vector2(0, -HOVER)
	speed = 100.0
	bar_y = -HOVER - 34.0
	glow_col = Color("ff4fd8")
	b_col = Color("ff4fd8")
	b_style = Bullets.Style.RUNE
	b_speed = 250.0
	burst = 1
	fan_n = 5
	fan_ang = 0.22
	windup = 0.6
	pref_min = 230.0
	pref_max = 380.0
	cd_min = 1.8
	cd_max = 3.0
	rec_t = 0.8
	spawn_dur = 0.8
	halo_p = Part.make(vis, _paint_halo, Vector2(0, -HOVER))
	core_p = Part.make(vis, _paint_core, Vector2(0, -HOVER))
	glow_p = Part.make(vis, _paint_glow, Vector2(0, -HOVER), true)


func _death_chunks() -> Array:
	return [Color("3a2470"), Color("1a0f30"), Color("ff4fd8"), Color("4fffe8")]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 22.0, Color(0, 0, 0, 0.45 - sin(hover_t * 2.0) * 0.04))


func _paint_halo(c: Part) -> void:
	var ink := Gfx.INK
	var r := 21.0 - windup_k * 6.0
	for k in 5:
		var a := hover_t * (1.6 + windup_k * 4.0) + TAU * float(k) / 5.0
		var p := Vector2(cos(a), sin(a) * 0.6) * r
		var pts := PackedVector2Array([p + Vector2(0, -5), p + Vector2(3.4, 0), p + Vector2(0, 5), p + Vector2(-3.4, 0)])
		Gfx.poly(c, pts, Color("5a2ea0") if sin(a) > 0.0 else Color("34205a"), ink, 1.4)
		c.draw_line(pts[0], pts[1], Color("4fffe8"), 1.3)


func _paint_core(c: Part) -> void:
	var ink := Gfx.INK
	var j := 0.0 if int(hover_t * 6.0) % 11 != 0 else 1.6
	Gfx.gell(c, Vector2(j, 0), 12.0, 12.0, Color("2a1650"), Color("0a0418"), ink, 2.4)
	var iris := Color("ff4fd8").lerp(Color.WHITE, windup_k * 0.6)
	c.draw_circle(Vector2(j, 0) + aim_dir * 3.0, 6.0 + windup_k * 2.0, iris)
	c.draw_circle(Vector2(j, 0) + aim_dir * 4.0, 2.4, Color.WHITE)
	c.draw_arc(Vector2(j, 0), 12.0, PI * 1.1, PI * 1.6, 8, Color("4fffe8", 0.8), 1.6, true)
	# glitch scan
	var sy := -8.0 + fposmod(hover_t * 14.0, 16.0)
	c.draw_line(Vector2(-10, sy), Vector2(10, sy), Color(1, 1, 1, 0.3), 1.2)


func _paint_glow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 22.0 + windup_k * 22.0, Color(1.0, 0.3, 0.85, 0.3 + windup_k * 0.5))


func _animate(dt: float) -> void:
	hover_t += dt
	recoil = maxf(0.0, recoil - dt * 6.0)
	var bob := sin(hover_t * 3.0) * 2.6
	core_p.position = Vector2(0, -HOVER + bob)
	halo_p.position = Vector2(0, -HOVER + bob)
	glow_p.position = Vector2(0, -HOVER + bob)
	hit_off = Vector2(0, -HOVER - 2.0 + bob)
	muzzle_off = Vector2(0, -HOVER + bob)
	core_p.queue_redraw()
	halo_p.queue_redraw()
	glow_p.queue_redraw()
	shadow.queue_redraw()
