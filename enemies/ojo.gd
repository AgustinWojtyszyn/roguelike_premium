class_name Ojo
extends RoleTotem
## Ojo del Vacio: un ojo gigante entre fragmentos de realidad. La pupila sigue al jugador; se abre para soltar
## anillos y espirales de energia anomala.

var eye_p: Part
var frag_p: Part
var glow_p: Part
var look := Vector2.ZERO


func _build() -> void:
	kind_name = "ojo"
	hp = 42.0
	radius = 18.0
	hit_r = 26.0
	hit_off = Vector2(0, -44)
	muzzle_off = Vector2(0, -44)
	bar_y = -86.0
	glow_col = Color("ff4fd8")
	b_col = Color("ff4fd8")
	b_style = Bullets.Style.ORB
	pattern_a = "ring"
	pattern_b = "spiral"
	big = true
	spawn_dur = 0.9
	frag_p = Part.make(vis, _paint_frag, Vector2(0, -44))
	eye_p = Part.make(vis, _paint_eye, Vector2(0, -44))
	glow_p = Part.make(eye_p, _paint_glow, Vector2.ZERO, true)


func _death_chunks() -> Array:
	return [Color("3a2470"), Color("120a2a"), Color("ff4fd8"), Color("4fffe8")]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 30.0, Color(0, 0, 0, 0.45 - sin(hover_t * 2.0) * 0.05))


func _paint_eye(c: Part) -> void:
	var ink := Gfx.INK
	var o := open_k
	var lid := 0.35 + 0.65 * o
	# globo
	Gfx.gell(c, Vector2.ZERO, 30.0, 22.0 * lid + 4.0, Color("e8e0f4"), Color("8a70b8"), ink, 2.8)
	# venas
	for k in 5:
		var a := float(k) * 1.26 + 0.4
		c.draw_line(Vector2.from_angle(a) * 27.0, Vector2.from_angle(a) * 14.0, Color(1.0, 0.3, 0.7, 0.5), 1.2)
	# iris + pupila (sigue al jugador)
	var ip := look * 9.0
	c.draw_circle(ip, 14.0 * (0.7 + 0.3 * lid), ink)
	c.draw_circle(ip, 12.0 * (0.7 + 0.3 * lid), Color("c0308a").lerp(Color("4fffe8"), o * 0.5))
	c.draw_circle(ip, 6.0 + o * 2.0, Color("0a0418"))
	c.draw_circle(ip + Vector2(-3, -3), 2.4, Color(1, 1, 1, 0.9))
	# parpados con borde
	c.draw_arc(Vector2.ZERO, 30.0, PI * 1.05, PI * 1.95, 18, ink, 4.0, true)
	c.draw_arc(Vector2.ZERO, 30.0, PI * 0.05, PI * 0.95, 18, ink, 4.0, true)


func _paint_frag(c: Part) -> void:
	var ink := Gfx.INK
	for k in 6:
		var a := hover_t * 0.8 + TAU * float(k) / 6.0
		var r := 46.0 + sin(hover_t * 1.5 + float(k)) * 4.0
		var p := Vector2(cos(a) * r, sin(a) * r * 0.45 + 2.0)
		var s := 8.0 + float(k % 3) * 2.0
		var pts := PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.6, 0), p + Vector2(0, s), p + Vector2(-s * 0.6, 0)])
		Gfx.poly(c, pts, Color("3a2470") if sin(a) > 0.0 else Color("22154a"), ink, 1.6)
		c.draw_line(pts[0], pts[1], Color("4fffe8", 0.8), 1.4)


func _paint_glow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 40.0 + open_k * 40.0, Color(b_col, 0.12 + open_k * 0.35))


func _animate(dt: float) -> void:
	var bob := sin(hover_t * 2.0) * 3.0
	look = look.lerp(aim_dir, clampf(dt * 8.0, 0.0, 1.0))
	eye_p.position = Vector2(0, -44 + bob)
	frag_p.position = Vector2(0, -44 + bob)
	hit_off = Vector2(0, -44 + bob)
	eye_p.queue_redraw()
	frag_p.queue_redraw()
	glow_p.soft_redraw()
	shadow.soft_redraw()
