class_name Chest
extends Node2D
## Cofre: se abre rapido al acercarte (anillo de 0.35 s), con pop de tapa, destello y loot legible.
## Tipos: coin (monedas), weapon (arma), perk (eleccion de perk), rare (arma epica+ y monedas).

var game: Game
var kind := "coin"
var foot := Rect2()
var opened := false
var hold: float = 0.0
var open_k: float = 0.0
var t: float = 0.0
var pop: float = 0.0

const COLS := {
	"coin": [Color("b88a3a"), Color("6a4a1a"), Color("ffd24a")],
	"weapon": [Color("6a7a9a"), Color("2c3650"), Color("6cc4ff")],
	"perk": [Color("7a5ab0"), Color("352058"), Color("c47bff")],
	"rare": [Color("c9a24a"), Color("5a3a18"), Color("ff4fd8")],
}


static func make(g: Game, k: String, pos: Vector2) -> Chest:
	var c := Chest.new()
	c.game = g
	c.kind = k
	c.position = pos
	c.foot = Rect2(pos.x - 26.0, pos.y - 16.0, 52.0, 18.0)
	c.scale = Vector2(1.25, 1.25)
	return c


func _ready() -> void:
	game.room.add_extra_solid(foot)


func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0)
	t += dt
	pop = maxf(0.0, pop - dt * 5.0)
	if opened:
		open_k = minf(1.0, open_k + dt * 7.0)
		queue_redraw()
		return
	var pl := game.player
	if pl.dead:
		return
	if pl.position.distance_to(position + Vector2(0, 10)) < 54.0:
		hold += dt
		if hold >= 0.35:
			_open()
	else:
		hold = maxf(0.0, hold - dt * 2.0)
	queue_redraw()


func _open() -> void:
	opened = true
	pop = 1.0
	var col: Color = (COLS[kind] as Array)[2]
	var c := position + Vector2(0, -18)
	game.fx.burst(c, 22, 320.0, col, 0.5)
	game.fx.ring(c, 8.0, 80.0, col, 0.35, 4.0)
	game.fx.flash(c, 100.0, Color(col, 0.8), 0.2)
	game.fx.sprite({"coin": "rewards/loot_sparkle", "weapon": "rewards/loot_glow_rare", "perk": "rewards/loot_glow_epic", "rare": "rewards/loot_glow_legendary"}[kind], c + Vector2(0, -6), 30.0, 70.0, 0.55, Color(1, 1, 1, 0.9), 0.0, true)
	game.sfx.play("chest", -2.0)
	game.shake(0.15)
	game.run.chests += 1
	match kind:
		"coin":
			game.pickups.drop_coins(c, 18 + game.run.stage_idx * 4 + randi() % 10)
			game.pickups.drop_energy(c, 10.0)
			game.pickups.drop_energy(c, 10.0)
			if randf() < 0.5:
				game.pickups.drop_heart(c)
		"weapon":
			game.pickups.drop_weapon(c, game.director.roll_weapon(0, 3))
		"perk":
			get_tree().create_timer(0.35).timeout.connect(func(): game.offer_perk("chest"))
		"rare":
			game.pickups.drop_weapon(c, game.director.roll_weapon(2, 4))
			game.pickups.drop_coins(c, 30)
	game.hud.toast({"coin": "¡MONEDAS!", "weapon": "¡ARMA!", "perk": "¡PERK!", "rare": "¡TESORO RARO!"}[kind], col)


## Arte importado por tipo (cerrado / abierto). En el capitulo de anomalias usa las variantes dimensional y corrupta.
const ART := {"coin": "common_chest", "weapon": "uncommon_chest", "perk": "epic_chest", "rare": "legendary_chest"}
const ART_ANOMALY := {"weapon": "dimensional_chest", "perk": "corrupted_chest", "rare": "rare_chest"}
const ART_SCALE := 1.1
const ART_BASE_Y := 41.0   # fila (en el PNG de 48x48) donde apoya la base del cofre


func _art_id() -> String:
	if game != null and game.chapter != null and game.chapter.theme == "anomaly" and ART_ANOMALY.has(kind):
		return ART_ANOMALY[kind]
	return ART.get(kind, "")


func _draw_art(cols: Array) -> bool:
	if not VisualProfiles.sprites_enabled():
		return false
	var id := _art_id()
	var closed := AssetCatalog.tex("rpg/chests/" + id)
	var open_t := AssetCatalog.tex("rpg/chests/" + id + "_open")
	if closed == null or open_t == null:
		return false
	var tex: Texture2D = open_t if opened else closed
	var scl := 1.0 + pop * 0.12
	var sz := tex.get_size() * ART_SCALE
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(scl, 2.0 - scl))
	if open_k > 0.0:
		Gfx.draw_glow(self, Vector2(0, -16), 26.0 + open_k * 22.0, Color(cols[2], 0.55 * open_k))
	draw_texture_rect(tex, Rect2(-sz.x * 0.5, -ART_BASE_Y * ART_SCALE, sz.x, sz.y), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not opened:
		var p := 0.5 + 0.5 * sin(t * 3.0 + position.x)
		Gfx.draw_glow(self, Vector2(0, -12), 38.0, Color(cols[2], 0.12 + 0.1 * p))
		_draw_hold_ring(cols)
	return true


func _draw_hold_ring(cols: Array) -> void:
	if hold > 0.0:
		draw_arc(Vector2(0, -12), 32.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(hold / 0.35, 0.0, 1.0), 24, Color(cols[2], 0.95), 4.0, true)


func _draw() -> void:
	var cols: Array = COLS[kind]
	var ink := Gfx.INK
	Gfx.draw_glow(self, Vector2(0, 2), 36.0, Color(0, 0, 0, 0.5))
	if _draw_art(cols):
		return
	var w := 44.0
	var bh := 24.0
	var scl := 1.0 + pop * 0.12
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(scl, 2.0 - scl))
	# cuerpo
	var body := Rect2(-w * 0.5, -bh, w, bh)
	Gfx.grrect(self, body, 3.0, cols[0], cols[1], ink, 2.0)
	draw_rect(Rect2(-w * 0.5 + 2, -bh + 8, w - 4, 3), Color(cols[2], 0.9))
	draw_rect(Rect2(-w * 0.5 + 3, -bh + 2, 4, bh - 4), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(w * 0.5 - 7, -bh + 2, 4, bh - 4), Color(0, 0, 0, 0.25))
	# tapa (se abre hacia arriba)
	var lid_h := 12.0
	var ang := open_k * 1.25
	var hinge := Vector2(0, -bh)
	draw_set_transform(hinge, 0.0, Vector2(scl, 1.0))
	var lid := PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0), Vector2(w * 0.5 - 3.0, -lid_h * cos(ang) - 2.0 * sin(ang) * 6.0), Vector2(-w * 0.5 + 3.0, -lid_h * cos(ang) - 2.0 * sin(ang) * 6.0)])
	if open_k > 0.0:
		Gfx.draw_glow(self, Vector2(0, -6), 26.0 + open_k * 20.0, Color(cols[2], 0.6 * open_k))
		draw_rect(Rect2(-w * 0.5 + 3, -6, w - 6, 5), Color(cols[2].lightened(0.4), 0.9))
	Gfx.gpoly(self, lid, (cols[0] as Color).lightened(0.15), cols[0], ink, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not opened:
		# cerradura y brillo de reclamo
		Gfx.rrect(self, Rect2(-4, -bh - 2, 8, 9), 2.0, Color("2a2230"), ink, 1.4)
		draw_circle(Vector2(0, -bh + 2), 1.6, cols[2])
		var p := 0.5 + 0.5 * sin(t * 3.0 + position.x)
		Gfx.draw_glow(self, Vector2(0, -bh * 0.5), 38.0, Color(cols[2], 0.12 + 0.1 * p))
		if hold > 0.0:
			draw_arc(Vector2(0, -bh * 0.5), 32.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(hold / 0.35, 0.0, 1.0), 24, Color(cols[2], 0.95), 4.0, true)
