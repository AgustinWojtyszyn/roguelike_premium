class_name AllyTurret
extends Node2D
## Torreta portatil de Orla: dispara al enemigo mas cercano con linea de vision durante 14 s.

var game: Game
var life: float = 14.0
var cd: float = 0.0
var ang: float = 0.0
var t: float = 0.0
var kick: float = 0.0


func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0) * Game.tscale
	t += dt
	life -= dt
	cd -= dt
	kick = maxf(0.0, kick - dt * 8.0)
	if life <= 0.0:
		game.fx.burst(position + Vector2(0, -12), 10, 200.0, Color("36e0d0"), 0.4)
		game.allies.erase(self)
		queue_free()
		return
	var best: Enemy = null
	var bd := 520.0 * 520.0
	for e in game.enemies:
		if not e.targetable():
			continue
		var d := e.position.distance_squared_to(position)
		if d < bd and game.room.los(position + Vector2(0, -12), e.hit_center()):
			bd = d
			best = e
	if best != null:
		var want := (best.hit_center() - (position + Vector2(0, -22))).angle()
		ang = lerp_angle(ang, want, clampf(dt * 14.0, 0.0, 1.0))
		if cd <= 0.0 and absf(angle_difference(ang, want)) < 0.2:
			cd = 0.26
			kick = 1.0
			var m := position + Vector2(0, -22) + Vector2.from_angle(ang) * 22.0
			var b := game.bullets.fire(m, Vector2.from_angle(ang + randf_range(-0.04, 0.04)), 820.0, 0.8, 2.0 * game.player.dmg_mult(), Bullets.Style.PULSE, 0, 0, 30.0)
			b.col = Color("36e0d0")
			b.cat = "ally"
			game.fx.muzzle(m, ang, 0.7, Color("36e0d0"))
			game.sfx.play("smg", -14.0, 1.2, 0.08, 0.04)
	queue_redraw()


func _draw() -> void:
	var ink := Gfx.INK
	Gfx.draw_glow(self, Vector2(0, 0), 24.0, Color(0, 0, 0, 0.5))
	Gfx.grrect(self, Rect2(-13, -12, 26, 12), 3.0, Color("8d9bc0"), Color("424d70"), ink, 2.0)
	Gfx.gell(self, Vector2(0, -20), 10.0, 9.0, Color("e8c040"), Color("a07a10"), ink, 2.0)
	draw_set_transform(Vector2(0, -22), ang, Vector2.ONE)
	Gfx.grrect(self, Rect2(-2 - kick * 3.0, -3.5, 22, 7), 2.0, Color("d3dcf0"), Color("6e7ba0"), ink, 1.8)
	draw_rect(Rect2(8 - kick * 3.0, -1.0, 12, 2), Color("36e0d0"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(-6, -18), 2.0, Color("36e0d0") if int(t * 4.0) % 2 == 0 else Color("0f5a50"))
	var f := clampf(life / 14.0, 0.0, 1.0)
	draw_rect(Rect2(-12, 4, 24.0 * f, 3), Color("36e0d0"))
