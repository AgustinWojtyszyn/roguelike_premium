class_name Pickups
extends Node2D
## Monedas, orbes de energia, botiquines y armas del suelo. Un solo nodo (dibujo y logica) con pool: nada de nodos por objeto.

enum K { COIN, ENERGY, HEART, SHIELD, WEAPON }

class Item:
	var kind: int = 0
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var z: float = 0.0
	var vz: float = 0.0
	var value: float = 1.0
	var age: float = 0.0
	var life: float = 40.0
	var id: String = ""
	var hold: float = 0.0
	var lock: float = 0.0
	var tier: int = 0
	var spin: float = 0.0

var game: Game
var items: Array[Item] = []
var _free: Array[Item] = []
var t: float = 0.0
const MAX_ITEMS := 120


func _ready() -> void:
	z_index = 2
	y_sort_enabled = false


func _new(kind: int, pos: Vector2, vel: Vector2, value: float) -> Item:
	if items.size() >= MAX_ITEMS:
		# fusiona: el mas viejo desaparece
		var old := items[0]
		items.remove_at(0)
		_free.append(old)
	var it: Item = _free.pop_back() if not _free.is_empty() else Item.new()
	it.kind = kind
	it.pos = pos
	it.vel = vel
	it.z = 14.0
	it.vz = randf_range(120.0, 220.0)
	it.value = value
	it.age = 0.0
	it.life = 45.0
	it.id = ""
	it.hold = 0.0
	it.lock = 0.35
	it.tier = 0
	it.spin = randf() * TAU
	items.append(it)
	return it


func drop_coins(pos: Vector2, amount: int) -> void:
	var orbs := mini(amount, 9)
	var per := float(amount) / float(orbs)
	for i in orbs:
		var a := randf() * TAU
		_new(K.COIN, pos, Vector2.from_angle(a) * randf_range(60.0, 200.0), per)


func drop_energy(pos: Vector2, amount: float) -> void:
	_new(K.ENERGY, pos, Vector2.from_angle(randf() * TAU) * randf_range(50.0, 150.0), amount)


func drop_heart(pos: Vector2) -> void:
	_new(K.HEART, pos, Vector2.from_angle(randf() * TAU) * randf_range(40.0, 100.0), 1.0)


func drop_shield(pos: Vector2) -> void:
	_new(K.SHIELD, pos, Vector2.from_angle(randf() * TAU) * randf_range(40.0, 100.0), 1.0)


func drop_weapon(pos: Vector2, id: String, lock_t: float = 0.0) -> void:
	var it := _new(K.WEAPON, pos, Vector2.from_angle(randf() * TAU) * randf_range(20.0, 60.0), 1.0)
	it.id = id
	it.life = 600.0
	it.lock = lock_t
	it.tier = Catalog.weapon(id).rarity


func clear_all() -> void:
	for it in items:
		_free.append(it)
	items.clear()


func weapon_near(p: Vector2, r: float) -> Item:
	for it in items:
		if it.kind == K.WEAPON and it.pos.distance_to(p) < r:
			return it
	return null


func _process(delta: float) -> void:
	Prof.begin("pick_proc")
	__process_impl(delta)
	Prof.end("pick_proc")


func __process_impl(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0) * Game.tscale
	t += dt
	var pl := game.player
	var magnet_r := 90.0 + game.run.mod("magnet") * 170.0
	var i := items.size() - 1
	while i >= 0:
		var it := items[i]
		it.age += dt
		it.lock = maxf(0.0, it.lock - dt)
		if it.age > it.life:
			_remove(i)
			i -= 1
			continue
		# fisica sencilla con "altura"
		it.vz -= 640.0 * dt
		it.z += it.vz * dt
		if it.z <= 0.0:
			it.z = 0.0
			if absf(it.vz) > 50.0:
				it.vz = -it.vz * 0.45
			else:
				it.vz = 0.0
			it.vel *= maxf(0.0, 1.0 - 6.0 * dt)
		it.pos += it.vel * dt
		var np := Gfx.push_out(it.pos, 5.0, game.room.rects)
		it.pos = np
		if not pl.dead and it.lock <= 0.0:
			var d := pl.hit_center().distance_to(it.pos)
			if it.kind == K.WEAPON:
				if pl.position.distance_to(it.pos) < 34.0:
					it.hold += dt
					if it.hold >= 0.32:
						_pickup_weapon(it, i)
						i -= 1
						continue
				else:
					it.hold = maxf(0.0, it.hold - dt * 2.0)
			else:
				var att := d < magnet_r and it.age > 0.45
				if att:
					var dir := (pl.hit_center() - it.pos).normalized()
					var spd := 260.0 + (magnet_r - d) * 5.0
					it.vel = it.vel.lerp(dir * spd, clampf(dt * 12.0, 0.0, 1.0))
					it.z = maxf(0.0, it.z - 60.0 * dt)
				if d < 20.0 and it.age > 0.3:
					if _collect(it):
						_remove(i)
						i -= 1
						continue
		i -= 1
	queue_redraw()


func _remove(i: int) -> void:
	_free.append(items[i])
	var last := items.size() - 1
	if i != last:
		items[i] = items[last]
	items.remove_at(last)


func _collect(it: Item) -> bool:
	var pl := game.player
	match it.kind:
		K.COIN:
			var v := int(round(it.value))
			game.run.coins += v
			game.sfx.play("coin", -10.0, 1.0 + randf() * 0.25, 0.04, 0.03)
			game.fx.spark(it.pos, Vector2.UP, 3, 120.0, Color("ffd24a"), 0.2, 1.0)
			game.hud.coin_pulse()
		K.ENERGY:
			if pl.energy >= pl.max_energy - 0.5:
				return false
			pl.add_energy(it.value)
			game.sfx.play("pickup", -12.0, 1.2, 0.05, 0.04)
			game.fx.spark(it.pos, Vector2.UP, 3, 120.0, Color("6cc4ff"), 0.2, 1.0)
		K.HEART:
			if pl.hp >= pl.max_hp:
				return false
			pl.heal(1 + (1 if pl.passive_is("triage") else 0))
			game.fx.sprite("rewards/heal", pl.hit_center() + Vector2(0, -12), 22.0, 38.0, 0.45, Color(1, 1, 1, 0.95), 0.0, true)
		K.SHIELD:
			if pl.shield >= pl.max_shield:
				return false
			pl.add_shield(1)
			game.sfx.play("pickup", -8.0)
			game.fx.ring(pl.hit_center(), 4.0, 30.0, Color("8fe8ff"), 0.3, 2.5)
	return true


func _pickup_weapon(it: Item, idx: int) -> void:
	var pl := game.player
	var old := pl.equip_weapon(it.id)
	game.fx.ring(it.pos, 4.0, 46.0, Rarity.color(it.tier), 0.35, 3.0)
	game.fx.burst(it.pos, 14, 220.0, Rarity.color(it.tier), 0.5)
	game.fx.sprite("rewards/loot_sparkle", it.pos, 24.0, 56.0, 0.4, Color(1, 1, 1, 0.95), 0.0, true)
	game.hud.toast("%s" % Catalog.weapon(it.id).display_name, Rarity.color(it.tier))
	_remove(idx)
	if old != "":
		drop_weapon(pl.position + Vector2(randf_range(-30, 30), 30), old, 1.6)


func _draw() -> void:
	Prof.begin("pick_draw")
	__draw_impl()
	Prof.end("pick_draw")


func __draw_impl() -> void:
	for it in items:
		var sp := it.pos - Vector2(0, it.z)
		var shadow_a := 0.35 * clampf(1.0 - it.z / 50.0, 0.3, 1.0)
		Gfx.draw_glow(self, it.pos + Vector2(0, 2), 7.0, Color(0, 0, 0, shadow_a))
		var blink := 1.0
		if it.life - it.age < 4.0 and it.kind != K.WEAPON:
			blink = 0.4 if int(t * 12.0) % 2 == 0 else 1.0
		match it.kind:
			K.COIN:
				var sq := absf(cos(it.age * 6.0 + it.spin))
				var rx := 4.2 * (0.35 + 0.65 * sq)
				Gfx.ell(self, sp, rx, 4.4, Color("ffd24a", blink), Color("7a4a10", blink), 1.4)
				if sq > 0.4:
					draw_arc(sp, 2.2, 0.0, TAU, 8, Color(1, 0.95, 0.7, 0.8 * blink), 1.0)
				Gfx.draw_glow(self, sp, 12.0, Color(1.0, 0.8, 0.2, 0.18 * blink))
			K.ENERGY:
				var p := sp + Vector2(0, sin(it.age * 4.0 + it.spin) * 1.5)
				draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5.5), p + Vector2(4, 0), p + Vector2(0, 5.5), p + Vector2(-4, 0)]), Color(0.45, 0.8, 1.0, blink))
				draw_circle(p, 1.6, Color(1, 1, 1, blink))
				Gfx.draw_glow(self, p, 14.0, Color(0.4, 0.75, 1.0, 0.3 * blink))
			K.HEART:
				var p := sp + Vector2(0, sin(it.age * 3.0 + it.spin) * 2.0)
				Gfx.ell(self, p + Vector2(-3, -1), 3.6, 3.6, Color("ff5f7a", blink), Gfx.INK, 1.2)
				Gfx.ell(self, p + Vector2(3, -1), 3.6, 3.6, Color("ff5f7a", blink), Gfx.INK, 1.2)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-6.4, 0), p + Vector2(6.4, 0), p + Vector2(0, 7.5)]), Color("ff5f7a", blink))
				Gfx.draw_glow(self, p, 16.0, Color(1.0, 0.3, 0.45, 0.25 * blink))
			K.SHIELD:
				var p := sp + Vector2(0, sin(it.age * 3.0 + it.spin) * 2.0)
				draw_colored_polygon(PackedVector2Array([p + Vector2(0, -7), p + Vector2(6, -3), p + Vector2(4, 5), p + Vector2(0, 8), p + Vector2(-4, 5), p + Vector2(-6, -3)]), Color(0.45, 0.9, 1.0, blink))
				Gfx.draw_glow(self, p, 16.0, Color(0.4, 0.9, 1.0, 0.25 * blink))
			K.WEAPON:
				var wd := Catalog.weapon(it.id)
				var col := Rarity.color_anim(wd.rarity, t)
				var p := it.pos + Vector2(0, -20.0 - it.z + sin(it.age * 2.5) * 3.0)
				# haz vertical de rareza
				draw_line(it.pos, it.pos + Vector2(0, -60.0), Color(col, 0.18), 10.0)
				draw_line(it.pos, it.pos + Vector2(0, -50.0), Color(col, 0.35), 3.0)
				Gfx.draw_glow(self, it.pos + Vector2(0, -6), 34.0, Color(col, 0.25))
				draw_set_transform(p + Vector2(-14, 2), 0.0, Vector2(0.62, 0.62))
				WeaponArt.paint(self, wd, 0.0, t)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				if it.hold > 0.0:
					draw_arc(it.pos, 26.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(it.hold / 0.32, 0.0, 1.0), 24, Color(col, 0.95), 3.5, true)
				else:
					draw_arc(it.pos, 24.0, 0, TAU, 24, Color(col, 0.35), 1.6, true)
