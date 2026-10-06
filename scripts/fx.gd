class_name Fx
extends Node2D
## Particulas, decals y destellos. Todo en dos nodos de dibujo (normal + aditivo).

enum K { SPARK, PUFF, RING, FLASH, SHARD, CASING, STAR, ARC, MOTE }

class P:
	var kind: int = 0
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var life: float = 0.0
	var max_life: float = 0.0
	var size: float = 1.0
	var size2: float = 1.0
	var col := Color.WHITE
	var rot: float = 0.0
	var spin: float = 0.0
	var z: float = 0.0
	var vz: float = 0.0
	var drag: float = 0.0
	var poly := PackedVector2Array()
	var add: bool = false
	var aux: float = 0.0
	var target := Vector2.ZERO

class Stain:
	var pos := Vector2.ZERO
	var size: float = 20.0
	var col := Color.BLACK
	var kind: int = 0
	var age: float = 0.0
	var seed: int = 0

const MAX_P := 600
const MAX_DECALS := 70

var ps: Array[P] = []
var decals: Array[Stain] = []
var lay_n: FxLayer
var lay_a: FxLayer
var lay_d: FxLayer


class FxLayer extends Node2D:
	var fx: Fx
	var mode: int = 0
	func _draw() -> void:
		fx.render(self, mode)


func _ready() -> void:
	lay_d = FxLayer.new()
	lay_d.fx = self
	lay_d.mode = 2
	lay_d.z_index = -9
	add_child(lay_d)
	lay_n = FxLayer.new()
	lay_n.fx = self
	lay_n.mode = 0
	lay_n.z_index = 6
	add_child(lay_n)
	lay_a = FxLayer.new()
	lay_a.fx = self
	lay_a.mode = 1
	lay_a.z_index = 12
	lay_a.material = Gfx.add_material()
	add_child(lay_a)


func _new(kind: int, pos: Vector2, life: float, col: Color, add: bool) -> P:
	if ps.size() >= MAX_P:
		ps.remove_at(0)
	var p := P.new()
	p.kind = kind
	p.pos = pos
	p.life = life
	p.max_life = life
	p.col = col
	p.add = add
	ps.append(p)
	return p


func spark(pos: Vector2, dir: Vector2, n: int, spd: float, col: Color, life: float = 0.25, cone: float = 0.7) -> void:
	for i in n:
		var a := dir.angle() + randf_range(-cone, cone)
		var p := _new(K.SPARK, pos, life * randf_range(0.6, 1.2), col, true)
		p.vel = Vector2.from_angle(a) * spd * randf_range(0.4, 1.0)
		p.drag = 4.0
		p.size = randf_range(1.5, 2.6)


func burst(pos: Vector2, n: int, spd: float, col: Color, life: float = 0.35) -> void:
	for i in n:
		var p := _new(K.SPARK, pos, life * randf_range(0.5, 1.2), col, true)
		p.vel = Vector2.from_angle(randf() * TAU) * spd * randf_range(0.3, 1.0)
		p.drag = 3.5
		p.size = randf_range(1.5, 3.0)


func puff(pos: Vector2, vel: Vector2, size: float, col: Color, life: float = 0.5, grow: float = 1.8) -> void:
	var p := _new(K.PUFF, pos, life, col, false)
	p.vel = vel
	p.size = size
	p.size2 = size * grow
	p.drag = 2.5


func ring(pos: Vector2, r0: float, r1: float, col: Color, life: float = 0.3, w: float = 3.0, add: bool = true) -> void:
	var p := _new(K.RING, pos, life, col, add)
	p.size = r0
	p.size2 = r1
	p.aux = w


func flash(pos: Vector2, r: float, col: Color, life: float = 0.12) -> void:
	var p := _new(K.FLASH, pos, life, col, true)
	p.size = r


func muzzle(pos: Vector2, ang: float, sc: float, col: Color) -> void:
	var p := _new(K.STAR, pos, 0.06, col, true)
	p.rot = ang
	p.size = sc
	flash(pos, 26.0 * sc, Color(col, 0.7), 0.08)


func shard(pos: Vector2, vel: Vector2, vz: float, col: Color, size: float = 3.0, glow_col: Color = Color(0, 0, 0, 0)) -> void:
	var p := _new(K.SHARD, pos, randf_range(1.2, 2.2), col, false)
	p.vel = vel
	p.z = 10.0
	p.vz = vz
	p.size = size
	p.rot = randf() * TAU
	p.spin = randf_range(-14.0, 14.0)
	p.drag = 1.5
	var n := randi_range(3, 5)
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n) + randf_range(-0.3, 0.3)
		pts.append(Vector2.from_angle(a) * size * randf_range(0.6, 1.3))
	p.poly = pts
	p.target = Vector2(glow_col.r, glow_col.g)
	p.aux = glow_col.a
	p.size2 = glow_col.b


func casing(pos: Vector2, dir: Vector2) -> void:
	var p := _new(K.CASING, pos, 2.5, Color("d9a441"), false)
	p.vel = dir * randf_range(50.0, 90.0)
	p.z = 18.0
	p.vz = randf_range(60.0, 110.0)
	p.rot = randf() * TAU
	p.spin = randf_range(-20.0, 20.0)
	p.drag = 2.0


func arc(pos: Vector2, ang: float, r: float, col: Color, life: float = 0.16, sweep: float = 2.2) -> void:
	var p := _new(K.ARC, pos, life, col, true)
	p.rot = ang
	p.size = r
	p.aux = sweep


func mote(pos: Vector2, target_fn_pos: Vector2, col: Color, life: float = 0.4) -> void:
	# particula que fluye hacia un punto (anticipacion de carga)
	var p := _new(K.MOTE, pos, life, col, true)
	p.target = target_fn_pos
	p.size = randf_range(1.6, 2.8)


func add_decal(pos: Vector2, kind: int, size: float, col: Color) -> void:
	if decals.size() >= MAX_DECALS:
		decals.remove_at(0)
	var d := Stain.new()
	d.pos = pos
	d.kind = kind
	d.size = size
	d.col = col
	d.seed = randi()
	decals.append(d)


func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0) * Game.tscale
	var i := ps.size() - 1
	while i >= 0:
		var p := ps[i]
		p.life -= dt
		if p.life <= 0.0:
			ps.remove_at(i)
			i -= 1
			continue
		match p.kind:
			K.SHARD, K.CASING:
				p.vz -= 520.0 * dt
				p.z += p.vz * dt
				p.pos += p.vel * dt
				if p.z <= 0.0:
					p.z = 0.0
					if absf(p.vz) > 60.0:
						p.vz = -p.vz * 0.38
						p.vel *= 0.6
						p.spin *= 0.5
					else:
						p.vz = 0.0
						p.vel = p.vel.move_toward(Vector2.ZERO, 400.0 * dt)
						p.spin = 0.0
				p.rot += p.spin * dt
			K.MOTE:
				var t := 1.0 - p.life / p.max_life
				p.pos = p.pos.lerp(p.target, clampf(dt * (4.0 + t * 8.0), 0.0, 1.0))
			_:
				p.pos += p.vel * dt
				p.vel *= maxf(0.0, 1.0 - p.drag * dt)
		i -= 1
	for d in decals:
		d.age += dt
	lay_n.queue_redraw()
	lay_a.queue_redraw()
	lay_d.queue_redraw()


func render(ci: CanvasItem, mode: int) -> void:
	if mode == 2:
		_render_decals(ci)
		return
	var want_add := mode == 1
	for p in ps:
		if p.add != want_add:
			continue
		var t := 1.0 - p.life / p.max_life
		var a := 1.0 - t
		match p.kind:
			K.SPARK:
				var l := clampf(p.vel.length() * 0.045, 2.0, 16.0)
				var d := p.vel.normalized() if p.vel.length() > 1.0 else Vector2.RIGHT
				var c := Color(p.col, a)
				ci.draw_line(p.pos, p.pos - d * l, c, p.size, true)
				ci.draw_line(p.pos, p.pos - d * l * 0.5, Color(1, 1, 1, a * 0.9), p.size * 0.5, true)
			K.PUFF:
				var r := lerpf(p.size, p.size2, Gfx.ease_out(t))
				Gfx.draw_glow(ci, p.pos, r, Color(p.col, p.col.a * a * a))
			K.RING:
				var r := lerpf(p.size, p.size2, Gfx.ease_out(t))
				ci.draw_arc(p.pos, r, 0.0, TAU, 40, Color(p.col, p.col.a * a), maxf(1.0, p.aux * a), true)
			K.FLASH:
				Gfx.draw_glow(ci, p.pos, p.size * (1.0 - t * 0.4), Color(p.col, p.col.a * a))
			K.STAR:
				ci.draw_set_transform(p.pos, p.rot, Vector2.ONE * p.size)
				var pts := PackedVector2Array([Vector2(-4, 0), Vector2(2, -5), Vector2(14, -2), Vector2(26, 0), Vector2(14, 2), Vector2(2, 5)])
				ci.draw_colored_polygon(pts, Color(p.col, 0.9))
				var pts2 := PackedVector2Array([Vector2(-2, 0), Vector2(6, -2.5), Vector2(18, 0), Vector2(6, 2.5)])
				ci.draw_colored_polygon(pts2, Color(1, 1, 1, 1))
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			K.ARC:
				var r := p.size * (0.75 + 0.35 * Gfx.ease_out(t))
				var half: float = p.aux * 0.5
				var c := Color(p.col, a)
				ci.draw_arc(p.pos, r, p.rot - half, p.rot + half, 20, c, 6.0 * a + 1.0, true)
				ci.draw_arc(p.pos, r - 3.0, p.rot - half * 0.8, p.rot + half * 0.8, 20, Color(1, 1, 1, a), 2.0, true)
			K.MOTE:
				ci.draw_circle(p.pos, p.size, Color(p.col, 0.4 + 0.6 * t))
				ci.draw_circle(p.pos, p.size * 0.5, Color(1, 1, 1, 0.8))
			K.SHARD:
				var sp := p.pos - Vector2(0, p.z)
				var fa := minf(1.0, p.life * 2.0)
				ci.draw_set_transform(sp, p.rot, Vector2.ONE)
				ci.draw_colored_polygon(p.poly, Color(p.col, fa))
				if p.aux > 0.0:
					ci.draw_colored_polygon(p.poly, Color(p.target.x, p.target.y, p.size2, p.aux * fa * 0.6))
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			K.CASING:
				var sp := p.pos - Vector2(0, p.z)
				var fa := minf(1.0, p.life * 2.0)
				ci.draw_set_transform(sp, p.rot, Vector2.ONE)
				ci.draw_rect(Rect2(-2.0, -1.0, 4.0, 2.0), Color(p.col, fa))
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _render_decals(ci: CanvasItem) -> void:
	for d in decals:
		var fade := clampf(1.0 - (d.age - 14.0) / 10.0, 0.0, 1.0)
		var s := d.size
		match d.kind:
			0: # quemadura suave
				Gfx.draw_glow(ci, d.pos, s, Color(0, 0, 0, 0.55 * fade))
				Gfx.draw_glow(ci, d.pos, s * 0.45, Color(0, 0, 0, 0.5 * fade))
			1: # grieta radial
				var rng := RandomNumberGenerator.new()
				rng.seed = d.seed
				for k in 7:
					var a := rng.randf() * TAU
					var l := s * rng.randf_range(0.5, 1.0)
					var mid := d.pos + Vector2.from_angle(a + rng.randf_range(-0.3, 0.3)) * l * 0.5
					ci.draw_polyline(PackedVector2Array([d.pos, mid, d.pos + Vector2.from_angle(a) * l]), Color(0.02, 0.03, 0.06, 0.85 * fade), 2.0, true)
				Gfx.draw_glow(ci, d.pos, s * 0.7, Color(0, 0, 0, 0.35 * fade))
