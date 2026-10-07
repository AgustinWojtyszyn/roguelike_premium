class_name ArenaHazard
extends Node2D
## Peligro simple de las arenas de supervivencia: una zona rectangular con ciclo reposo -> aviso (0,9 s, parpadea) -> activa (0,6 s).
## Dana al jugador (1) y a los enemigos que pisen la zona activa: sirve para jugar con el espacio, no es un muro invisible.
## Estilo por familia: electrico (tech), pinchos de jade (aztec), llamaradas (castle), pulso del vacio (anomaly).

const REST := 0.0
const WARN := 1.0
const ACTIVE := 2.0
const WARN_T := 0.9
const ACTIVE_T := 0.6

var game: Game
var rect := Rect2()
var theme := "tech"
var state := REST
var st := 0.0
var rest_t := 3.0
var hit_cd := 0.0
var _redraw := 0.0

## Zonas por arena (relativas al centro): franjas en los pasillos libres entre columnas y piezas grandes.
const ZONES := [Rect2(-90, -172, 180, 46), Rect2(-90, 126, 180, 46), Rect2(-48, -22, 96, 44)]

const COLS := {"tech": Color("3df2dc"), "aztec": Color("ffb23d"), "castle": Color("ff6a2a"), "anomaly": Color("ff4fd8")}


static func spawn_all(g: Game, room: Room, parent: Node) -> Array[ArenaHazard]:
	var out: Array[ArenaHazard] = []
	for i in ZONES.size():
		var h := ArenaHazard.new()
		h.game = g
		h.rect = ZONES[i]
		h.theme = room.def.theme
		h.rest_t = 2.0 + float(i) * 1.7
		h.z_index = -22          # sobre el suelo, bajo los actores
		parent.add_child(h)
		out.append(h)
	return out


func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0) * Game.tscale
	if game.over or game.director == null or game.director.transition:
		return
	st += dt
	hit_cd = maxf(0.0, hit_cd - dt)
	match state:
		REST:
			if st >= rest_t and game.director.in_combat:
				_go(WARN)
		WARN:
			_redraw -= dt
			if _redraw <= 0.0:
				_redraw = 0.06
				queue_redraw()
			if st >= WARN_T:
				_go(ACTIVE)
				game.sfx.play("slam", -12.0, 1.3, 0.1, 0.05)
				game.fx.flash(rect.get_center(), maxf(rect.size.x, rect.size.y) * 0.7, Color(COLS[theme], 0.7), 0.2)
		ACTIVE:
			_redraw -= dt
			if _redraw <= 0.0:
				_redraw = 0.05
				queue_redraw()
			_damage()
			if st >= ACTIVE_T:
				rest_t = randf_range(3.2, 5.2)
				_go(REST)


func _go(s: int) -> void:
	state = s
	st = 0.0
	queue_redraw()


func _damage() -> void:
	if hit_cd > 0.0:
		return
	var hit := false
	var pl := game.player
	if not pl.dead and rect.grow(-2.0).has_point(pl.position + Vector2(0, -4)) and pl.can_be_hit():
		pl.take_damage(1, Vector2(0, 1), 60.0)
		hit = true
	for e in game.enemies.duplicate():
		if is_instance_valid(e) and e.targetable() and rect.has_point(e.position) and not (e is Boss):
			game.hit_enemy_direct(e, 5.0, Vector2.UP, 120.0, e.hit_center(), "hazard")
			hit = true
	if hit:
		hit_cd = 0.3


func _draw() -> void:
	var col: Color = COLS[theme]
	var r := rect
	match state:
		REST:
			# marca tenue permanente para que la zona se lea antes de que avise
			draw_rect(r, Color(col, 0.07))
			draw_rect(r, Color(col, 0.28), false, 1.5)
		WARN:
			var k := clampf(st / WARN_T, 0.0, 1.0)
			var blink := 0.5 + 0.5 * sin(st * 28.0)
			draw_rect(r, Color(col, 0.10 + 0.22 * blink))
			draw_rect(r, Color(col, 0.7 + 0.3 * blink), false, 2.5)
			draw_rect(Rect2(r.position, Vector2(r.size.x * k, 4.0)), Color(1, 1, 1, 0.8))
		ACTIVE:
			draw_rect(r, Color(col, 0.55))
			draw_rect(r, Color(1, 1, 1, 0.9), false, 2.5)
			match theme:
				"tech":
					for i in 5:
						var x := r.position.x + (float(i) + 0.5) * r.size.x / 5.0
						var pts := PackedVector2Array([Vector2(x, r.position.y), Vector2(x + randf_range(-9, 9), r.position.y + r.size.y * 0.33), Vector2(x + randf_range(-9, 9), r.position.y + r.size.y * 0.66), Vector2(x, r.end.y)])
						draw_polyline(pts, Color(1, 1, 1, 0.95), 2.0, true)
				"aztec":
					for i in 6:
						var x2 := r.position.x + (float(i) + 0.5) * r.size.x / 6.0
						draw_colored_polygon(PackedVector2Array([Vector2(x2 - 7, r.end.y), Vector2(x2, r.position.y - 6), Vector2(x2 + 7, r.end.y)]), Color("fff2c0"))
				"castle":
					for i in 5:
						var x3 := r.position.x + (float(i) + 0.5) * r.size.x / 5.0
						draw_colored_polygon(PackedVector2Array([Vector2(x3 - 9, r.end.y), Vector2(x3 + randf_range(-4, 4), r.position.y - 14), Vector2(x3 + 9, r.end.y)]), Color("ffd24a", 0.9))
				_:
					draw_arc(r.get_center(), r.size.y * 0.5 + 8.0 * sin(st * 20.0), 0.0, TAU, 28, Color(1, 1, 1, 0.9), 2.0, true)
