class_name Hud
extends Control
## HUD de la run: minimalista. Vida / escudo / energia, arma, progreso de etapas, monedas, pausa y controles tactiles.

var game: Game
var damage_flash: float = 0.0
var banner_text := ""
var banner_sub := ""
var banner_t: float = 0.0
var banner_dur: float = 1.0
var banner_col := Color("c0fff6")
var vignette: GradientTexture2D
var font: Font
var t: float = 0.0
var hp_lag: float = 10.0
var energy_flash: float = 0.0
var coin_k: float = 0.0
var toast_text := ""
var toast_col := Color.WHITE
var toast_t: float = 0.0
var redraw_t: float = 0.0
var boss: Node = null
var boss_frac_lag: float = 1.0
var time_tint: float = 0.0
var safe := Vector4.ZERO


func _ready() -> void:
	font = UiKit.font()
	_reticle = HudReticle.new()
	_reticle.hud = self
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_reticle)
	_reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.62)])
	vignette = GradientTexture2D.new()
	vignette.gradient = g
	vignette.fill = GradientTexture2D.FILL_RADIAL
	vignette.fill_from = Vector2(0.5, 0.5)
	vignette.fill_to = Vector2(1.05, 0.5)
	vignette.width = 256
	vignette.height = 144


func banner(text: String, dur: float, sub: String = "", col: Color = Color("c0fff6")) -> void:
	banner_text = text
	banner_sub = sub
	banner_t = dur
	banner_dur = dur
	banner_col = col


func toast(text: String, col: Color = Color.WHITE) -> void:
	toast_text = text
	toast_col = col
	toast_t = 1.6


func flash_energy() -> void:
	energy_flash = 1.0


func coin_pulse() -> void:
	coin_k = 1.0


func _process(delta: float) -> void:
	t += delta
	damage_flash = maxf(0.0, damage_flash - delta * 2.6)
	banner_t = maxf(0.0, banner_t - delta)
	toast_t = maxf(0.0, toast_t - delta)
	energy_flash = maxf(0.0, energy_flash - delta * 3.0)
	coin_k = maxf(0.0, coin_k - delta * 5.0)
	hp_lag = move_toward(hp_lag, float(game.player.hp), delta * 6.0)
	if boss != null:
		boss_frac_lag = move_toward(boss_frac_lag, boss.hp_frac(), delta * 0.5)
	_reticle.visible = not game.touch_mode
	_reticle.queue_redraw()
	# Redibujo dirigido por cambios (con un latido de 15 Hz para las animaciones suaves)
	redraw_t -= delta
	safe = SafeArea.margins(self)
	HudRects.safe = safe
	var sig := _signature()
	var active := banner_t > 0.0 or toast_t > 0.0 or damage_flash > 0.0 or energy_flash > 0.0 or coin_k > 0.0 or game.input.touch_move_id != -1 or game.input.touch_aim_id != -1
	if sig != _last_sig or active or redraw_t <= 0.0:
		_last_sig = sig
		redraw_t = 0.066
		queue_redraw()


var _last_sig := 0
var _reticle: HudReticle


func _signature() -> int:
	var pl := game.player
	var d := game.director
	var h := pl.hp * 7 + pl.shield * 131 + int(pl.energy) * 977 + pl.cur * 31 + game.run.coins * 3571
	h += int(clampf(pl.ability_cd, 0.0, 99.0) * 8.0) * 17
	if d != null:
		h += d.stage * 101 + d.threats_left() * 1009 + (1 if d.in_combat else 0) * 3
	if boss != null and is_instance_valid(boss):
		h += int(boss.hp_frac() * 200.0) * 13
	return h


func _draw() -> void:
	Prof.begin("hud_draw")
	_draw_all()
	Prof.end("hud_draw")


func _draw_all() -> void:
	var vs := get_viewport_rect().size
	draw_texture_rect(vignette, Rect2(Vector2.ZERO, vs), false)
	if damage_flash > 0.0:
		draw_texture_rect(vignette, Rect2(Vector2.ZERO, vs), false, Color(1.0, 0.25, 0.3, damage_flash * 1.6))
	if game.enemy_time < 0.99:
		draw_texture_rect(vignette, Rect2(Vector2.ZERO, vs), false, Color(0.3, 0.9, 1.0, 0.5 * (1.0 - game.enemy_time)))
	_draw_vitals()
	if bool(Profile.p.setting("show_fps")):
		UiKit.text(self, Vector2(26.0 + safe.x, 112.0 + safe.y), "%d FPS" % int(Engine.get_frames_per_second()), 14, Color(0.7, 1, 0.8, 0.9), 0, -1.0, 3.0)
	_draw_progress(vs)
	_draw_top_right(vs)
	_draw_boss(vs)
	_draw_banner(vs)
	_draw_toast(vs)
	if game.touch_mode:
		_draw_touch(vs)
	else:
		_draw_weapons_pc(vs)


func _draw_vitals() -> void:
	var pl := game.player
	var p := Vector2(22.0 + safe.x, 18.0 + safe.y)
	var w := 250.0
	UiKit.panel(self, Rect2(p, Vector2(w, 74)), Color(0.02, 0.05, 0.1, 0.6), Color(0.25, 0.9, 0.85, 0.45), 10.0, 1.0, false)
	# vida: un segmento por punto
	var n := pl.max_hp
	var gap := 3.0
	var sw := (w - 28.0 - gap * float(n - 1)) / float(n)
	for i in n:
		var r := Rect2(p.x + 14.0 + float(i) * (sw + gap), p.y + 10.0, sw, 15.0)
		draw_rect(r, Color(0.05, 0.07, 0.12))
		if i < pl.hp:
			var low := pl.hp <= 2
			var col := Color("ff4f6a") if not low else Color("ff7a8a").lerp(Color.WHITE, 0.35 * (0.5 + 0.5 * sin(t * 10.0)))
			draw_rect(r, col)
			draw_rect(Rect2(r.position, Vector2(r.size.x, 4.0)), Color(1, 1, 1, 0.35))
		elif float(i) < hp_lag:
			draw_rect(r, Color(1, 1, 1, 0.8))
		draw_rect(r, Color(0, 0, 0, 0.8), false, 1.5)
	# escudo
	if pl.max_shield > 0:
		var m := pl.max_shield
		var sw2 := (w - 28.0 - gap * float(m - 1)) / float(m)
		for i in m:
			var r := Rect2(p.x + 14.0 + float(i) * (sw2 + gap), p.y + 30.0, sw2, 9.0)
			draw_rect(r, Color(0.04, 0.08, 0.14))
			if i < pl.shield:
				draw_rect(r, Color("4fd0ff"))
				draw_rect(Rect2(r.position, Vector2(r.size.x, 3.0)), Color(1, 1, 1, 0.35))
			draw_rect(r, Color(0, 0, 0, 0.8), false, 1.2)
	# energia
	var ef := pl.energy / maxf(pl.max_energy, 1.0)
	var er := Rect2(p.x + 14.0, p.y + 46.0, w - 28.0 - 56.0, 10.0)
	var ecol := Color("6a9cff").lerp(Color("ff6a6a"), energy_flash)
	UiKit.bar(self, er, ef, ecol)
	UiKit.text(self, Vector2(er.end.x + 10.0, er.position.y + 10.0), "%d" % int(pl.energy), 14, Color(0.75, 0.88, 1.0), 0, 50.0)
	UiIcons.draw(self, "cell", Vector2(p.x + w - 20.0, p.y + 51.0), 7.0, Color("6a9cff"))


func _draw_progress(vs: Vector2) -> void:
	var d := game.director
	if d == null or d.plan.is_empty():
		return
	var n := d.plan.size()
	var w := 34.0 * float(n) + 24.0
	var r := Rect2(vs.x * 0.5 - w * 0.5, 14.0 + safe.y, w, 40.0)
	UiKit.panel(self, r, Color(0.02, 0.05, 0.1, 0.55), Color(0.25, 0.9, 0.85, 0.4), 10.0, 1.0, false)
	for i in n:
		var c := Vector2(r.position.x + 28.0 + float(i) * 34.0, r.position.y + 20.0)
		var kind: String = d.plan[i]["kind"]
		var done := i < d.stage
		var cur := i == d.stage
		var col := Color("27e0cc") if done else (Color("ffd24a") if cur else Color(0.3, 0.38, 0.55))
		if kind == "boss":
			UiIcons.draw(self, "skull", c, 9.5 if cur else 8.0, col)
		elif kind == "cache":
			UiIcons.draw(self, "chest", c, 8.0, col)
		elif kind == "elite":
			UiIcons.draw(self, "star", c, 9.0 if cur else 7.5, col)
		else:
			draw_circle(c, 6.5 if cur else 5.0, col)
			draw_arc(c, 6.5 if cur else 5.0, 0, TAU, 14, UiKit.INK, 1.5, true)
		if cur:
			draw_arc(c, 13.0, 0, TAU, 20, Color(col, 0.5 + 0.3 * sin(t * 5.0)), 1.5, true)
	# amenazas restantes
	var left: int = d.threats_left()
	if left > 0 and d.in_combat and boss == null:
		UiKit.text(self, Vector2(r.position.x, r.end.y + 20.0), "AMENAZAS  %d" % left, 13, Color(1.0, 0.8, 0.85, 0.9), 1, r.size.x, 3.0)


func _draw_top_right(vs: Vector2) -> void:
	var pr := HudRects.pause_rect(vs)
	var cc := pr.get_center()
	draw_circle(cc, 28.0, Color(0.02, 0.05, 0.1, 0.6))
	draw_arc(cc, 28.0, 0, TAU, 30, Color(0.3, 0.95, 0.9, 0.7), 2.5, true)
	UiIcons.draw(self, "pause", cc, 14.0, Color(0.75, 1.0, 0.98, 0.95))
	# monedas
	var coin_txt := UiKit.format_int(game.run.coins)
	var tw := UiKit.text_width(coin_txt, 20)
	var r := Rect2(pr.position.x - tw - 62.0, 22.0 + safe.y, tw + 50.0, 40.0)
	UiKit.pill(self, r, Color(0.02, 0.05, 0.1, 0.62), Color(1.0, 0.82, 0.3, 0.6), 2.0)
	var s := 12.0 + coin_k * 4.0
	UiIcons.draw(self, "coin", Vector2(r.position.x + 22.0, r.get_center().y), s, Color("ffd24a"))
	UiKit.text(self, Vector2(r.position.x + 40.0, r.get_center().y + 7.0), coin_txt, 20, Color("fff0b0"), 0, -1.0, 3.0)


func _draw_boss(vs: Vector2) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var w := minf(560.0, vs.x * 0.5)
	var r := Rect2(vs.x * 0.5 - w * 0.5, 100.0 + safe.y, w, 18.0)
	var col: Color = boss.accent_color()
	UiKit.text(self, Vector2(r.position.x, r.position.y - 6.0), boss.title_text(), 18, col.lightened(0.5), 1, w, 4.0)
	draw_rect(r.grow(3.0), UiKit.INK)
	draw_rect(r, Color(0.08, 0.04, 0.08))
	var f: float = boss.hp_frac()
	draw_rect(Rect2(r.position, Vector2(r.size.x * boss_frac_lag, r.size.y)), Color(1, 1, 1, 0.75))
	draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), col)
	draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y * 0.35)), Color(1, 1, 1, 0.3))
	var phases: Array = boss.phase_marks()
	for m in phases:
		var x: float = r.position.x + r.size.x * float(m)
		draw_line(Vector2(x, r.position.y - 2), Vector2(x, r.end.y + 2), UiKit.INK, 3.0)


func _draw_weapons_pc(vs: Vector2) -> void:
	var pl := game.player
	var base := Vector2(24 + safe.x, vs.y - 92 - safe.w)
	for i in pl.slots.size():
		var wd := pl.slots[i].data
		var r := Rect2(base + Vector2(float(i) * 150.0, 0), Vector2(142, 64))
		var sel := pl.cur == i
		UiKit.panel(self, r, Color(0.02, 0.05, 0.1, 0.72 if sel else 0.4), Color(Rarity.color(wd.rarity), 0.9 if sel else 0.35), 10.0, 1.0, false)
		draw_set_transform(r.position + Vector2(36, 36), 0.0, Vector2(0.72, 0.72) if sel else Vector2(0.6, 0.6))
		WeaponArt.paint(self, wd, 0.0, t)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		UiKit.text(self, r.position + Vector2(8, 14), str(i + 1), 12, Color(0.5, 0.95, 0.9, 0.9))
		if sel:
			draw_rect(Rect2(r.position.x + 8, r.end.y - 4, r.size.x - 16, 3), Rarity.color(wd.rarity))
	var wd := pl.weapon()
	var cost := ("  ·  %.1f EN" % (wd.energy_cost * pl.energy_cost_mult())) if wd.energy_cost > 0.0 else ""
	UiKit.text(self, base + Vector2(2, -8), "%s  ·  %s%s" % [wd.display_name, wd.sub, cost], 14, Color(0.85, 0.97, 1.0, 0.95), 0, -1.0, 3.0)
	# habilidad
	var ab := Vector2(vs.x - 150.0 - safe.z, vs.y - 92.0 - safe.w)
	_ability_chip(Rect2(ab, Vector2(126, 64)))


func _ability_chip(r: Rect2) -> void:
	var pl := game.player
	var ready := pl.ability_ready()
	var cdf := 1.0 - clampf(pl.ability_cd / maxf(pl.data.ability_cd, 0.1), 0.0, 1.0)
	UiKit.panel(self, r, Color(0.02, 0.05, 0.1, 0.7), Color(1.0, 0.8, 0.3, 0.9) if ready else Color(0.4, 0.5, 0.7, 0.5), 10.0, 1.0, false)
	UiIcons.draw(self, _ability_icon(), r.position + Vector2(30, 32), 14.0, Color("ffd24a") if ready else Color(0.55, 0.62, 0.78))
	UiKit.text(self, r.position + Vector2(56, 24), "ESPACIO", 12, Color(0.7, 0.9, 1.0, 0.9))
	UiKit.text(self, r.position + Vector2(56, 44), pl.data.ability_name.substr(0, 12), 11, Color(0.85, 0.95, 1.0, 0.9), 0, -1.0, 0.0, false)
	draw_rect(Rect2(r.position.x + 8, r.end.y - 5, (r.size.x - 16) * cdf, 3), Color("ffd24a") if ready else Color("6a9cff"))


func _ability_icon() -> String:
	return game.player.data.ability_id


func _draw_banner(vs: Vector2) -> void:
	if banner_t <= 0.0 or banner_text == "":
		return
	var age := banner_dur - banner_t
	var a := clampf(minf(age * 5.0, banner_t * 3.0), 0.0, 1.0)
	var sc := 1.0 + (1.0 - clampf(age * 6.0, 0.0, 1.0)) * 0.25
	var size := int(52 * sc)
	var pos := Vector2(0, vs.y * 0.32)
	UiKit.text(self, pos, banner_text, size, Color(banner_col, a), 1, vs.x, 10.0)
	var w := 260.0 * (0.6 + 0.4 * a)
	draw_rect(Rect2(vs.x * 0.5 - w * 0.5, pos.y + 14, w, 3), Color(0.25, 0.95, 0.88, a * 0.8))
	if banner_sub != "":
		UiKit.text(self, pos + Vector2(0, 46), banner_sub, 22, Color(0.9, 0.95, 1.0, a * 0.9), 1, vs.x, 6.0)


func _draw_toast(vs: Vector2) -> void:
	if toast_t <= 0.0:
		return
	var a := clampf(minf(toast_t * 3.0, 1.0), 0.0, 1.0)
	var y := vs.y * 0.62 - (1.6 - toast_t) * 18.0
	UiKit.text(self, Vector2(0, y), toast_text, 26, Color(toast_col, a), 1, vs.x, 8.0)


func _draw_reticle(ci: Control) -> void:
	var m := get_viewport().get_mouse_position()
	var kick := game.player.kick
	var over_enemy := false
	var wm := game.get_global_mouse_position()
	for e in game.enemies:
		if e.hit_center().distance_to(wm) < e.hit_r:
			over_enemy = true
			break
	var col := Color(0.55, 1.0, 0.95, 0.95) if not over_enemy else Color(1.0, 0.5, 0.75, 1.0)
	var gap := 9.0 + kick * 6.0 + (-2.0 if over_enemy else 0.0)
	for k in 4:
		var a := PI * 0.5 * k + PI * 0.25
		var d := Vector2.from_angle(a)
		ci.draw_line(m + d * gap, m + d * (gap + 8.0), Color(0, 0, 0, 0.7), 4.0, true)
		ci.draw_line(m + d * gap, m + d * (gap + 8.0), col, 2.0, true)
	ci.draw_circle(m, 2.6, Color(0, 0, 0, 0.7))
	ci.draw_circle(m, 1.6, col)


func _draw_touch(vs: Vector2) -> void:
	var lo := game.input.touch_move_o if game.input.touch_move_id != -1 else Vector2(150.0 + safe.x, vs.y - 150.0 - safe.w)
	var lk := game.input.touch_move_p if game.input.touch_move_id != -1 else lo
	var la := 0.5 if game.input.touch_move_id != -1 else 0.22
	_stick(lo, lk, la)
	var ro := game.input.touch_aim_o if game.input.touch_aim_id != -1 else Vector2(vs.x - 170, vs.y - 112)
	var rk := game.input.touch_aim_p if game.input.touch_aim_id != -1 else ro
	var ra := 0.5 if game.input.touch_aim_id != -1 else 0.22
	_stick(ro, rk, ra, true)
	if game.input.touch_aim_id != -1:
		var d := rk - ro
		if d.length() > 6.0:
			var dd := d.normalized()
			var firing := d.length() > 26.0
			draw_circle(ro + dd * 70.0, 5.0, Color(1.0, 0.6, 0.8, 0.9) if firing else Color(0.6, 1, 1, 0.5))
	# cambio de arma
	var pl := game.player
	var sc := HudRects.swap_center(vs)
	if pl.slots.size() > 1:
		draw_circle(sc, 42.0, Color(0.02, 0.05, 0.1, 0.55))
		draw_arc(sc, 42.0, 0, TAU, 36, Color(Rarity.color(pl.weapon().rarity), 0.85), 3.0, true)
		draw_set_transform(sc + Vector2(-17, 3), 0.0, Vector2(0.62, 0.62))
		WeaponArt.paint(self, pl.weapon(), 0.0, t)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		UiIcons.draw(self, "swap", sc + Vector2(24, -26), 9.0, Color(0.8, 0.95, 1.0, 0.9))
	# habilidad
	var ac := HudRects.ability_center(vs)
	var ready := pl.ability_ready()
	var cdf := 1.0 - clampf(pl.ability_cd / maxf(pl.data.ability_cd, 0.1), 0.0, 1.0)
	var hot := Color("ffd24a") if ready else Color(0.45, 0.55, 0.75)
	if ready:
		Gfx.draw_glow(self, ac, 70.0, Color(1.0, 0.8, 0.3, 0.2 + 0.1 * sin(t * 5.0)))
	draw_circle(ac, 48.0, Color(0.02, 0.05, 0.1, 0.65))
	draw_arc(ac, 48.0, -PI * 0.5, -PI * 0.5 + TAU * cdf, 40, hot, 5.0, true)
	draw_arc(ac, 48.0, 0, TAU, 40, Color(hot, 0.25), 2.0, true)
	UiIcons.draw(self, _ability_icon(), ac, 20.0, hot)
	UiKit.text(self, ac + Vector2(-40, 66), "%d EN" % pl.data.ability_cost, 12, Color(0.7, 0.85, 1.0, 0.85), 1, 80.0, 3.0)


func _stick(o: Vector2, k: Vector2, a: float, red: bool = false) -> void:
	var base := Color(0.3, 0.95, 0.9, a)
	if red:
		base = Color(0.6, 0.9, 1.0, a)
	draw_circle(o, 70.0, Color(0.02, 0.05, 0.1, a * 0.8))
	draw_arc(o, 70.0, 0, TAU, 48, base, 3.0, true)
	draw_arc(o, 30.0, 0, TAU, 32, Color(base, a * 0.5), 1.5, true)
	var kk := o + (k - o).limit_length(70.0)
	draw_circle(kk, 30.0, Color(0.05, 0.15, 0.2, a + 0.2))
	draw_circle(kk, 26.0, Color(base, a + 0.15))
	draw_circle(kk, 14.0, Color(1, 1, 1, a * 0.5))


class HudReticle extends Control:
	var hud: Hud
	func _draw() -> void:
		hud._draw_reticle(self)
