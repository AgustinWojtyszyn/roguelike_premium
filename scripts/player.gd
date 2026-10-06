class_name Player
extends Node2D
## Protagonista: "Vesper". Armado con partes animadas por codigo.

const SPEED := 262.0
const ACCEL := 3400.0
const DECEL := 4600.0
const RADIUS := 11.0
const HIT_R := 12.0
const MAX_HP := 10

var game: Game
var vel := Vector2.ZERO
var aim := Vector2.RIGHT
var hp: int = MAX_HP
var weapon: int = 0
var cd: float = 0.0
var kick: float = 0.0
var inv: float = 0.0
var flash: float = 0.0
var dead := false
var walk_ph: float = 0.0
var face: float = 1.0
var face_vis: float = 1.0
var t: float = 0.0
var swap_t: float = 0.0
var heat: float = 0.0
var look_q: int = 0
var was_step_sign: float = 1.0
var land_squash: float = 0.0
var using_touch := false

var vis: Node2D
var fmat: ShaderMaterial
var shadow: Part
var body: Node2D
var pack: Part
var antenna: Part
var leg_b: Part
var leg_f: Part
var torso: Part
var head: Part
var scarf: Part
var pivot: Node2D
var arm_b: Part
var wnode: Part
var arm_f: Part
var scarf_pts: Array[Vector2] = []

const HIP_Y := -17.0
const WEAPON_POS := Vector2(12, 2.5)


func build(g: Game) -> void:
	game = g
	shadow = Part.make(self, _paint_shadow)
	vis = Node2D.new()
	fmat = Gfx.flash_material()
	vis.material = fmat
	add_child(vis)
	scarf = Part.make(vis, _paint_scarf)
	body = Node2D.new()
	body.use_parent_material = true
	vis.add_child(body)
	pack = Part.make(body, _paint_pack, Vector2(-9, -26))
	Part.make(pack, _paint_pack_glow, Vector2.ZERO, true)
	antenna = Part.make(body, _paint_antenna, Vector2(-12, -34))
	leg_b = Part.make(body, _paint_leg, Vector2(-5, HIP_Y))
	leg_b.set_meta("dark", true)
	leg_f = Part.make(body, _paint_leg, Vector2(5, HIP_Y))
	leg_f.set_meta("dark", false)
	torso = Part.make(body, _paint_torso, Vector2(0, HIP_Y))
	Part.make(torso, _paint_torso_glow, Vector2.ZERO, true)
	for i in 6:
		scarf_pts.append(Vector2(-4, -33))
	head = Part.make(body, _paint_head, Vector2(1, -34))
	Part.make(head, _paint_head_glow, Vector2.ZERO, true)
	pivot = Node2D.new()
	pivot.use_parent_material = true
	pivot.position = Vector2(0, -26)
	vis.add_child(pivot)
	arm_b = Part.make(pivot, _paint_arm_back)
	wnode = Part.make(pivot, _paint_weapon, WEAPON_POS)
	arm_f = Part.make(pivot, _paint_arm_front)


# =====================================================================
#  DIBUJO DE PARTES
# =====================================================================
func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(1, -1), 24.0, Color(0, 0, 0, 0.6))


func _paint_leg(c: Part) -> void:
	var dark: bool = c.get_meta("dark", false)
	var ink := Gfx.INK
	var a := Color("2b3755") if not dark else Color("1b2338")
	var b := Color("1d2540") if not dark else Color("121829")
	Gfx.gpoly(c, PackedVector2Array([Vector2(-4.5, 0), Vector2(4.5, 0), Vector2(5, 8), Vector2(4.5, 13), Vector2(-4.5, 13), Vector2(-5, 8)]), a, b, ink, 2.0)
	# rodillera
	Gfx.ell(c, Vector2(0.5, 6.5), 4.0, 3.0, Color("56648e") if not dark else Color("3a4566"), ink, 1.5)
	# bota
	var boot := PackedVector2Array([Vector2(-5.5, 11), Vector2(5.5, 11), Vector2(10, 15), Vector2(10.5, 18.5), Vector2(-5.5, 18.5)])
	Gfx.gpoly(c, boot, Color("3a4668") if not dark else Color("232b44"), Color("141a2c"), ink, 2.0)
	c.draw_rect(Rect2(-5, 16, 15, 2.0), Color("0c1020"))
	c.draw_line(Vector2(5, 13), Vector2(9.5, 16.5), Color(1, 1, 1, 0.18 if not dark else 0.06), 1.5)
	c.draw_rect(Rect2(-5, 11.5, 5, 1.6), Color("ff8a3d") if not dark else Color("a35527"))


func _paint_torso(c: Part) -> void:
	var ink := Gfx.INK
	# cuerpo
	var tb := PackedVector2Array([Vector2(-10, 0), Vector2(10, 0), Vector2(12.5, -6), Vector2(11.5, -15), Vector2(7, -18), Vector2(-7, -18), Vector2(-11.5, -15), Vector2(-12.5, -6)])
	Gfx.gpoly(c, tb, Color("4a5a82"), Color("27304e"), ink, 2.2)
	# placa pectoral
	var cp := PackedVector2Array([Vector2(-7.5, -3.5), Vector2(7.5, -3.5), Vector2(9, -13), Vector2(5, -16.5), Vector2(-5, -16.5), Vector2(-9, -13)])
	Gfx.gpoly(c, cp, Color("e6edf9"), Color("9aabcc"), Color("1a2238"), 1.5)
	c.draw_line(Vector2(-6, -15), Vector2(6, -15), Color(1, 1, 1, 0.8), 1.5)
	# emblema
	Gfx.poly(c, PackedVector2Array([Vector2(0, -13), Vector2(3, -9.5), Vector2(0, -6), Vector2(-3, -9.5)]), Color("27e0cc"), Color("0c4a50"), 1.3)
	# cinturon
	c.draw_rect(Rect2(-11, -2.5, 22, 4), ink)
	c.draw_rect(Rect2(-10, -2, 20, 3), Color("20283f"))
	Gfx.rrect(c, Rect2(-3.5, -3.5, 7, 6), 1.5, Color("ff8a3d"), ink, 1.4)
	for sx in [-8.5, 8.5]:
		Gfx.rrect(c, Rect2(sx - 2.5, -2.5, 5, 6.5), 1.5, Color("39446a"), ink, 1.4)
	# hombreras
	for sx in [-1, 1]:
		var hp_c := Vector2(11.5 * sx, -14.5)
		Gfx.gell(c, hp_c, 6.0, 5.2, Color("8da0cf"), Color("46547d"), ink, 2.0)
		c.draw_line(hp_c + Vector2(-3.5, 0.5), hp_c + Vector2(3.5, 0.5), Color("27e0cc"), 1.6)


func _paint_torso_glow(c: Part) -> void:
	var p := 0.6 + 0.4 * sin(t * 3.0)
	Gfx.draw_glow(c, Vector2(0, -9.5), 11.0, Color(0.15, 0.9, 0.8, 0.5 * p))


func _paint_pack(c: Part) -> void:
	var ink := Gfx.INK
	Gfx.grrect(c, Rect2(-8, -12, 16, 24), 4.0, Color("303b5c"), Color("1a2138"), ink, 2.0)
	Gfx.rrect(c, Rect2(-5, -8, 4, 16), 1.5, Color("0b2a30"), ink, 1.2)
	Gfx.rrect(c, Rect2(1, -8, 4, 16), 1.5, Color("0b2a30"), ink, 1.2)
	c.draw_rect(Rect2(-4, -7, 2, 14), Color("27e0cc"))
	c.draw_rect(Rect2(2, -7, 2, 14), Color("27e0cc"))
	c.draw_rect(Rect2(-8, 8, 16, 3), Color("ff8a3d"))
	c.draw_rect(Rect2(-8, 8, 16, 1), Color(1, 1, 1, 0.2))


func _paint_pack_glow(c: Part) -> void:
	var p := 0.6 + 0.4 * sin(t * 2.4 + 1.0)
	Gfx.draw_glow(c, Vector2(0, 0), 16.0, Color(0.15, 0.9, 0.8, 0.35 * p))


func _paint_antenna(c: Part) -> void:
	var tip := Vector2(-1.5, -14)
	c.draw_line(Vector2.ZERO, tip, Gfx.INK, 3.0, true)
	c.draw_line(Vector2.ZERO, tip, Color("8da0cf"), 1.3, true)
	c.draw_circle(tip, 2.6, Gfx.INK)
	var on := int(t * 2.5) % 2 == 0
	c.draw_circle(tip, 1.8, Color("ff8a3d") if on else Color("8a4a22"))


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	var ly := float(look_q) / 10.0   # -1 (arriba) .. 1 (abajo)
	# cuello + bufanda enrollada
	c.draw_rect(Rect2(-3.5, -4, 7, 5), Color("151b2e"))
	Gfx.rrect(c, Rect2(-8, -5.5, 16, 6.5), 3.0, Color("ff7a2e"), ink, 1.8)
	c.draw_line(Vector2(-5, -3.5), Vector2(5, -3.5), Color("ffc07a"), 1.2, true)
	# casco
	var shell := Gfx.ell_pts(Vector2(1, -13), 13.0, 12.2, 26)
	Gfx.gpoly(c, shell, Color("f2f6fd"), Color("8b9cc0"), ink, 2.4)
	# cresta
	Gfx.poly(c, PackedVector2Array([Vector2(-8, -22), Vector2(0, -26.5), Vector2(8, -22.5), Vector2(3, -21), Vector2(-4, -20.5)]), Color("ff8a3d"), ink, 1.8)
	c.draw_line(Vector2(-5, -23), Vector2(4, -24.5), Color(1, 0.85, 0.6, 0.8), 1.2)
	# oreja
	Gfx.ell(c, Vector2(-5, -10), 4.6, 5.0, Color("1c2440"), ink, 1.8)
	Gfx.ell(c, Vector2(-5, -10), 2.2, 2.4, Color("27e0cc"), Color(0, 0, 0, 0), 0.0)
	if ly < -0.55:
		# mirando hacia arriba: se ve la nuca del casco
		Gfx.rrect(c, Rect2(-6, -19, 14, 10), 3.0, Color("b6c3de"), ink, 1.6)
		for k in 3:
			c.draw_line(Vector2(-3, -17 + k * 3.0), Vector2(5, -17 + k * 3.0), Color("5c6b92"), 1.4)
	else:
		# visor
		var squash := clampf(1.0 - maxf(0.0, -ly) * 1.2, 0.35, 1.0)
		var vy := -12.0 + ly * 2.2
		var vh := 8.2 * squash
		var vp := PackedVector2Array([Vector2(2.5, vy - vh), Vector2(12.5, vy - vh + 1.5), Vector2(14, vy), Vector2(11.5, vy + vh * 0.8), Vector2(3.5, vy + vh)])
		Gfx.gpoly(c, vp, Color("1d3f56"), Color("060b16"), ink, 1.8)
		# reflejo
		c.draw_line(Vector2(5, vy - vh * 0.6), Vector2(11, vy - vh * 0.6 + 0.5), Color(1, 1, 1, 0.55), 1.6, true)
		c.draw_line(Vector2(4.5, vy - vh * 0.2), Vector2(8, vy - vh * 0.2), Color(1, 1, 1, 0.25), 1.2, true)
		# banda luminosa del visor
		c.draw_line(Vector2(4.5, vy + vh * 0.35), Vector2(12, vy + vh * 0.25), Color("5ff7e4"), 2.0, true)


func _paint_head_glow(c: Part) -> void:
	var ly := float(look_q) / 10.0
	if ly < -0.55:
		return
	var vy := -12.0 + ly * 2.2
	Gfx.draw_glow(c, Vector2(9, vy), 14.0, Color(0.25, 0.95, 0.9, 0.5))


func _paint_scarf(c: Part) -> void:
	var n := scarf_pts.size()
	for i in range(n - 1):
		var p0 := scarf_pts[i]
		var p1 := scarf_pts[i + 1]
		var d := p1 - p0
		if d.length() < 0.01:
			continue
		var nr := Vector2(-d.y, d.x).normalized()
		var w0 := lerpf(4.2, 1.2, float(i) / float(n - 1))
		var w1 := lerpf(4.2, 1.2, float(i + 1) / float(n - 1))
		var quad := PackedVector2Array([p0 + nr * w0, p1 + nr * w1, p1 - nr * w1, p0 - nr * w0])
		c.draw_colored_polygon(quad, Color("ff7a2e") if i % 2 == 0 else Color("ff8f45"))
		c.draw_line(quad[0], quad[1], Gfx.INK, 2.0, true)
		c.draw_line(quad[3], quad[2], Gfx.INK, 2.0, true)
	var tip := scarf_pts[n - 1]
	c.draw_circle(tip, 1.6, Gfx.INK)


func _paint_arm_back(c: Part) -> void:
	_arm(c, Vector2(-2, -2.5), wnode.position + Weapons.W[weapon]["grip2"], true)


func _paint_arm_front(c: Part) -> void:
	_arm(c, Vector2(1, 2.5), wnode.position + Vector2(0.5, 1.0), false)


func _arm(c: Part, shoulder: Vector2, hand: Vector2, back: bool) -> void:
	var ink := Gfx.INK
	var elbow := Gfx.elbow(shoulder, hand, 10.5, 9.5, 1.0)
	var sleeve := Color("3a4a74") if not back else Color("27304f")
	Gfx.limb(c, PackedVector2Array([shoulder, elbow, hand]), sleeve, 6.0, ink)
	# brazalete
	var bp := elbow.lerp(hand, 0.55)
	c.draw_circle(bp, 3.4, Color("27e0cc") if not back else Color("1a8a80"))
	c.draw_circle(bp, 2.0, Color("0c3036"))
	# guante
	c.draw_circle(hand, 4.6, ink)
	c.draw_circle(hand, 3.5, Color("e4ebf8") if not back else Color("9aa8c6"))


func _paint_weapon(c: Part) -> void:
	Weapons.paint(c, weapon, heat)


# =====================================================================
#  LOGICA
# =====================================================================
func setup_weapon(i: int, quiet: bool = false) -> void:
	weapon = i
	cd = maxf(cd, 0.15)
	swap_t = 1.0
	arm_b.queue_redraw()
	wnode.queue_redraw()
	if not quiet:
		game.sfx.play("swap", -4.0)


func muzzle_world() -> Vector2:
	return pivot.to_global(wnode.position + Weapons.W[weapon]["muzzle"])


func hit_center() -> Vector2:
	return position + Vector2(0, -26)


func can_be_hit() -> bool:
	return not dead and inv <= 0.0


func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0) * Game.tscale
	t += dt
	if dead:
		_update_dead(dt)
		return
	_move(dt)
	_aim(dt)
	_fire(dt)
	_animate(dt)


func _move(dt: float) -> void:
	var dir := game.move_input()
	var tgt := dir * SPEED
	var a := ACCEL if dir != Vector2.ZERO else DECEL
	vel = vel.move_toward(tgt, a * dt)
	var old := position
	var np := Gfx.push_out(position + vel * dt, RADIUS, game.room.rects)
	if dt > 0.0:
		var actual := (np - old) / dt
		# elimina la velocidad contra la pared, conserva el deslizamiento
		if actual.length() < vel.length() - 1.0:
			vel = vel.lerp(actual, 0.6)
	position = np


func _aim(dt: float) -> void:
	var o := pivot.global_position
	var a := game.aim_input(o)
	if a != Vector2.ZERO:
		aim = a.normalized()
	var f := face
	if absf(aim.x) > 0.12:
		f = 1.0 if aim.x > 0.0 else -1.0
	face = f


func _fire(dt: float) -> void:
	cd -= dt
	heat = maxf(0.0, heat - dt * 3.0)
	var w: Dictionary = Weapons.W[weapon]
	if game.fire_input() and cd <= 0.0 and not game.over:
		cd = w["rate"]
		_shoot(w)
	kick = maxf(0.0, kick - dt * (7.0 if weapon != 1 else 4.5))


func _shoot(w: Dictionary) -> void:
	var m := muzzle_world()
	var base := aim.angle()
	var cnt: int = w["count"]
	for i in cnt:
		var ang := base
		if cnt > 1:
			ang += (float(i) - float(cnt - 1) * 0.5) * (w["spread"] * 2.0 / float(cnt - 1)) + randf_range(-0.05, 0.05)
		else:
			ang += randf_range(-w["spread"], w["spread"])
		var life: float = w["life"]
		var spd: float = w["speed"]
		if cnt > 1:
			life *= randf_range(0.8, 1.15)
			spd *= randf_range(0.88, 1.1)
		game.bullets.fire(m, Vector2.from_angle(ang), spd, life, w["dmg"], w["kind"], 0, w["pierce"], w["knock"])
	kick = 1.0
	heat = minf(1.0, heat + (0.25 if weapon == 0 else 1.0))
	wnode.queue_redraw()
	var col: Color = w["col"]
	game.fx.muzzle(m, base, 1.0 if weapon == 0 else (1.5 if weapon == 1 else 1.25), col)
	if weapon == 1:
		game.fx.spark(m, aim, 8, 520.0, col, 0.3, 0.55)
		game.fx.puff(m + aim * 8.0, aim * 90.0, 10.0, Color(0.7, 0.72, 0.8, 0.4), 0.45, 2.4)
	elif weapon == 2:
		game.fx.ring(m + aim * 6.0, 4.0, 26.0, col, 0.18, 2.5)
		game.fx.spark(m, aim, 6, 420.0, col, 0.22, 0.35)
	if w["casing"]:
		var side := Vector2(-aim.y, aim.x) * face
		game.fx.casing(position + Vector2(0, -26) + aim * 6.0, (side * 0.8 + Vector2(0, -0.4)).normalized())
	var sname: String = ["smg", "maul", "rail"][weapon]
	game.sfx.play(sname, -6.0 if weapon == 0 else -2.0, 1.0, 0.06)
	game.shake(w["shake"])
	# retroceso del cuerpo
	vel -= aim * (14.0 if weapon == 0 else (95.0 if weapon == 1 else 55.0))


func _animate(dt: float) -> void:
	var spd := vel.length()
	var amp := clampf(spd / SPEED, 0.0, 1.0)
	# fase de caminata (invertida si camina de espaldas al apuntado)
	var dirsign := 1.0
	if absf(vel.x) > 20.0 and signf(vel.x) != face:
		dirsign = -1.0
	walk_ph += dt * (spd * 0.082) * dirsign
	var sw := sin(walk_ph)
	var sw2 := sin(walk_ph + PI)
	var vertical := clampf(absf(vel.y) / maxf(spd, 1.0), 0.0, 1.0)
	var horiz := 1.0 - vertical * 0.6
	# giro del cuerpo (voltear con un pequeño squash)
	face_vis = move_toward(face_vis, face, dt * 16.0)
	body.scale.x = face_vis if absf(face_vis) > 0.08 else 0.08 * face
	# piernas
	leg_f.position = Vector2(5, HIP_Y - maxf(0.0, sw) * 3.2 * amp)
	leg_b.position = Vector2(-5, HIP_Y - maxf(0.0, sw2) * 3.2 * amp)
	leg_f.rotation = sw * 0.55 * amp * horiz
	leg_b.rotation = sw2 * 0.55 * amp * horiz
	leg_f.scale.y = 1.0 - absf(sw) * 0.12 * amp * vertical
	leg_b.scale.y = 1.0 - absf(sw2) * 0.12 * amp * vertical
	# rebote del cuerpo
	var bob := absf(sw) * 2.4 * amp
	var breath := sin(t * 2.3) * 0.9 * (1.0 - amp)
	body.position.y = -bob + breath * 0.4
	body.rotation = clampf(vel.x / SPEED, -1.0, 1.0) * 0.09 * face_vis
	torso.scale = Vector2(1.0 + breath * 0.012, 1.0 + (breath * 0.035) + (kick * -0.03))
	torso.position.y = HIP_Y
	# cabeza: sigue la mira con retraso, respira
	var ly := clampf(aim.y, -1.0, 1.0)
	var q := int(round(ly * 10.0 / 2.0)) * 2
	if q != look_q:
		look_q = q
		head.queue_redraw()
		head.get_child(0).queue_redraw()
	head.position = Vector2(1.0 + kick * -1.0, -34.0 + sin(t * 2.3 + 0.6) * 0.5 * (1.0 - amp) + ly * 0.8)
	head.rotation = lerpf(head.rotation, aim.y * 0.12 * face_vis, clampf(dt * 14.0, 0.0, 1.0)) + 0.0
	antenna.rotation = sin(t * 3.0) * 0.08 - vel.x * 0.0012 * face_vis + sin(walk_ph * 2.0) * 0.1 * amp
	antenna.queue_redraw()
	pack.position.y = -26.0 + sin(walk_ph * 2.0) * 0.8 * amp
	# bufanda
	_update_scarf(dt, amp)
	# pivote/arma
	pivot.position = Vector2(0, -26.0 - bob * 0.9 + breath * 0.3)
	pivot.rotation = aim.angle()
	pivot.scale.y = face
	# retroceso visual
	var w: Dictionary = Weapons.W[weapon]
	var kk := kick * kick
	swap_t = maxf(0.0, swap_t - dt * 5.0)
	wnode.position = WEAPON_POS + Vector2(-kk * w["kick"], 0.0) + Vector2(0, sin(walk_ph * 2.0) * 0.8 * amp + sin(t * 2.3) * 0.4 * (1.0 - amp))
	wnode.rotation = -kk * 0.16 + swap_t * swap_t * 1.1
	arm_b.queue_redraw()
	arm_f.queue_redraw()
	wnode.queue_redraw()
	head.get_child(0).queue_redraw()
	torso.get_child(0).queue_redraw()
	pack.get_child(0).queue_redraw()
	# empuje de la figura entera al disparar
	vis.position = -aim * kk * 1.8
	# invulnerabilidad / flash
	inv = maxf(0.0, inv - dt)
	flash = maxf(0.0, flash - dt * 7.0)
	fmat.set_shader_parameter("flash", flash)
	vis.modulate.a = 1.0 if inv <= 0.0 else (0.45 if int(t * 22.0) % 2 == 0 else 1.0)
	# pasos
	var s := signf(sw)
	if s != was_step_sign and spd > 60.0:
		was_step_sign = s
		game.fx.puff(position + Vector2(randf_range(-4, 4), -1), Vector2(-vel.x * 0.1, -8), 6.0, Color(0.6, 0.66, 0.8, 0.28), 0.4, 2.2)
		game.sfx.play("step", -16.0, 1.0, 0.15, 0.06)
	elif spd <= 60.0:
		was_step_sign = s
	shadow.scale = Vector2(1.0 - bob * 0.01, 1.0)


func _update_scarf(dt: float, amp: float) -> void:
	var anchor := Vector2(-4.0 * face_vis, -33.0 + body.position.y * 0.5)
	scarf_pts[0] = anchor
	var rest := Vector2(-face_vis * 5.2, 1.4)
	for i in range(1, scarf_pts.size()):
		var want := scarf_pts[i - 1] + rest + Vector2(0, sin(t * 7.0 + i * 0.9) * (0.6 + amp * 1.0))
		want -= vel * 0.012 * float(i)
		scarf_pts[i] = scarf_pts[i].lerp(want, clampf(dt * (22.0 - float(i) * 2.0), 0.0, 1.0))
		# no hundir la bufanda en la espalda
		var d := scarf_pts[i] - scarf_pts[i - 1]
		if d.length() > 6.5:
			scarf_pts[i] = scarf_pts[i - 1] + d.normalized() * 6.5
	scarf.queue_redraw()


func take_damage(n: int, dir: Vector2, knock: float = 120.0) -> void:
	if dead or inv > 0.0 or game.god:
		return
	hp -= n
	inv = 1.0
	flash = 1.0
	vel += dir * knock
	game.shake(0.45)
	game.hitstop(0.07)
	game.hud_flash()
	game.sfx.play("hurt", -2.0)
	game.fx.burst(hit_center(), 10, 260.0, Color("9fe9ff"), 0.35)
	game.fx.ring(hit_center(), 6.0, 34.0, Color("bff3ff"), 0.22, 3.0)
	if hp <= 0:
		hp = 0
		die(dir)


func heal(n: int) -> void:
	hp = mini(MAX_HP, hp + n)
	game.fx.ring(position + Vector2(0, -20), 8.0, 40.0, Color("5fffc8"), 0.45, 3.0)
	game.fx.burst(position + Vector2(0, -22), 12, 160.0, Color("5fffc8"), 0.6)


var death_t: float = 0.0
var death_dirv := Vector2.RIGHT


func die(dir: Vector2) -> void:
	dead = true
	death_t = 0.0
	death_dirv = dir
	game.sfx.play("player_die", 0.0)
	game.game_over()
	var c := hit_center()
	game.fx.burst(c, 30, 380.0, Color("9fe9ff"), 0.7)
	game.fx.ring(c, 10.0, 90.0, Color("bff3ff"), 0.4, 4.0)
	game.fx.flash(c, 120.0, Color(0.6, 0.95, 1.0, 0.9), 0.25)
	for i in 8:
		game.fx.shard(c, Vector2.from_angle(randf() * TAU) * randf_range(60, 200), randf_range(80, 200), Color("46547d"), randf_range(3, 5.5), Color(0.15, 0.9, 0.8, 0.8))
	game.fx.add_decal(position, 0, 38.0, Color.BLACK)
	# el casco sale volando
	var tw := create_tween().set_parallel(true)
	tw.tween_property(head, "position", head.position + Vector2(-dir.x * 34.0, 12.0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(head, "rotation", -dir.x * 2.8, 0.5)
	tw.tween_property(pivot, "position", pivot.position + Vector2(dir.x * 22.0, 14.0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(pivot, "rotation", pivot.rotation + 2.0, 0.4)


func _update_dead(dt: float) -> void:
	death_t += dt
	flash = maxf(0.0, flash - dt * 5.0)
	fmat.set_shader_parameter("flash", flash)
	var k := Gfx.ease_out(death_t / 0.45)
	body.rotation = -death_dirv.x * 1.45 * k
	body.position.y = 8.0 * k
	body.position.x = -death_dirv.x * 6.0 * k
	leg_f.rotation = 0.5 * k
	leg_b.rotation = -0.4 * k
	scarf.visible = death_t < 0.1
	vis.modulate.a = clampf(1.0 - (death_t - 1.6) / 0.8, 0.35, 1.0)
	if death_t < 0.2:
		vel *= 0.9
		position = Gfx.push_out(position + vel * dt, RADIUS, game.room.rects)
	arm_b.visible = false
	arm_f.visible = false
