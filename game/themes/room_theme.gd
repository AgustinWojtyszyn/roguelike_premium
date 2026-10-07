class_name RoomTheme
extends RefCounted
## Tema visual de un capitulo: suelo, muros, luces, decoracion viva, puntos de aparicion y sello de salida.
## Las salas (RoomDef) son geometria + contenido; el tema las viste. Un tema nuevo = una subclase.

const FACE_H := 110.0       # alto de la cara frontal de un muro norte
const CORNICE_H := 32.0

var id := "tech"
var accent := Color("27e0cc")
var void_col := Color("04060c")
var tile := 80.0
# colores de bloques solidos internos (muros bajos que dan forma a la sala)
var block_top: Array[Color] = [Color("56648a"), Color("3a4666")]
var block_front: Array[Color] = [Color("2f3956"), Color("1a2036")]
var block_trim := Color("e9a72c")


static func create(theme_id: String) -> RoomTheme:
	match theme_id:
		"aztec":
			return ThemeAztec.new()
		"castle":
			return ThemeCastle.new()
		"anomaly":
			return ThemeAnomaly.new()
	return ThemeTech.new()


## Calcula elementos de decoracion (lamparas, pantallas, antorchas...) UNA vez; lo usan paint_* estaticos y vivos.
func build_dressing(_room: Room, _rng: RandomNumberGenerator) -> Dictionary:
	return {}


func paint_floor(ci: CanvasItem, room: Room) -> void:
	ci.draw_rect(room.bounds.grow(900.0), void_col)
	var idx := 0
	for R in room.walk:
		_floor_panels(ci, R, 4242 + idx * 17)
		idx += 1
	_floor_extras(ci, room)
	RoomDecor.paint_floor(ci, room)


func _floor_panels(_ci: CanvasItem, _R: Rect2, _seed: int) -> void:
	pass


func _floor_extras(_ci: CanvasItem, _room: Room) -> void:
	pass


## Despacho de muros por lado. Los temas implementan _wall_n / _wall_s / _wall_we.
func paint_wall_run(ci: CanvasItem, room: Room, run: Dictionary) -> void:
	var side: String = run["side"]
	var a: float = run["a"]
	var b: float = run["b"]
	var edge: float = run["edge"]
	match side:
		"N":
			_wall_n(ci, room, a - float(run["ext_a"]), b + float(run["ext_b"]), edge)
		"S":
			_wall_s(ci, room, a - float(run["ext_a"]), b + float(run["ext_b"]), edge)
		_:
			_wall_we(ci, room, side, a, b, edge, float(run["ext_a"]), float(run["ext_b"]))


func _wall_n(_ci: CanvasItem, _room: Room, _x0: float, _x1: float, _edge: float) -> void:
	pass


func _wall_s(_ci: CanvasItem, _room: Room, _x0: float, _x1: float, _edge: float) -> void:
	pass


func _wall_we(_ci: CanvasItem, _room: Room, _side: String, _a: float, _b: float, _edge: float, _ea: float, _eb: float) -> void:
	pass


func paint_lights(_ci: CanvasItem, _room: Room) -> void:
	pass


func paint_deco(_ci: CanvasItem, _room: Room, _t: float) -> void:
	pass


## Base estatica de un punto de aparicion (open 0..1).
func paint_spawn(_ci: CanvasItem, _pos: Vector2, _open: float, _t: float, _i: int) -> void:
	pass


## Brillo aditivo del punto de aparicion.
func paint_spawn_glow(_ci: CanvasItem, _pos: Vector2, _glow: float, _t: float, _i: int) -> void:
	pass


func spawn_color() -> Color:
	return Color("c07aff")


## Sello de salida: energia que cierra el pasaje hasta despejar la sala. `open` 0..1.
## Base (capa normal): pilares emisores.
func paint_seal_base(ci: CanvasItem, room: Room, _t: float) -> void:
	var r: Rect2 = room.seal_rect
	var open: float = room.seal_open
	var ink := Gfx.INK
	for k in 2:
		var p := _seal_post(room, k)
		Gfx.rrect(ci, Rect2(p.x - 9, p.y - 14, 18, 28), 4.0, Color("2a3354"), ink, 2.0)
		ci.draw_rect(Rect2(p.x - 3, p.y - 8, 6, 16), Color(0.25, 0.9, 0.5) if open > 0.5 else Color(1.0, 0.45, 0.3))
	if open <= 0.0:
		ci.draw_rect(r.grow(-2), Color(0, 0, 0, 0.0))


func _seal_post(room: Room, k: int) -> Vector2:
	var r: Rect2 = room.seal_rect
	var horizontal: bool = room.exit_side == "N" or room.exit_side == "S"
	if horizontal:
		return Vector2(r.position.x + 4.0 if k == 0 else r.end.x - 4.0, r.get_center().y)
	return Vector2(r.get_center().x, r.position.y + 4.0 if k == 0 else r.end.y - 4.0)


## Brillo (capa aditiva): campo de energia que se disuelve al abrir.
func paint_seal_glow(ci: CanvasItem, room: Room, t: float) -> void:
	var r: Rect2 = room.seal_rect
	var open: float = room.seal_open
	var horizontal: bool = room.exit_side == "N" or room.exit_side == "S"
	var col := accent
	if open > 0.98:
		# indicador de pasaje: chevrones que avanzan hacia la salida
		var dir := room.exit_dir()
		for k in 3:
			var f := fposmod(t * 0.9 + float(k) / 3.0, 1.0)
			var p := room.exit_trigger.get_center() - dir * 120.0 + dir * f * 120.0
			var pa := sin(f * PI)
			var nrm := Vector2(-dir.y, dir.x)
			var pts := PackedVector2Array([p + dir * 8.0, p - dir * 4.0 + nrm * 12.0, p - dir * 4.0 - nrm * 12.0])
			ci.draw_polyline(PackedVector2Array([p - dir * 4.0 + nrm * 12.0, p + dir * 8.0, p - dir * 4.0 - nrm * 12.0]), Color(col, 0.8 * pa), 3.0, true)
		Gfx.draw_glow(ci, room.exit_trigger.get_center(), 90.0, Color(col, 0.15 + 0.05 * sin(t * 3.0)))
		return
	var a := 1.0 - open
	var n := 9
	for i in n:
		var f := float(i) / float(n - 1)
		var flick := 0.6 + 0.4 * sin(t * 14.0 + float(i) * 1.7)
		if horizontal:
			var x := r.position.x + 14.0 + f * (r.size.x - 28.0)
			ci.draw_line(Vector2(x, r.position.y - 4), Vector2(x, r.end.y + 4), Color(col, 0.55 * a * flick), 3.0, true)
		else:
			var y := r.position.y + 14.0 + f * (r.size.y - 28.0)
			ci.draw_line(Vector2(r.position.x - 4, y), Vector2(r.end.x + 4, y), Color(col, 0.55 * a * flick), 3.0, true)
	Gfx.draw_glow(ci, r.get_center(), maxf(r.size.x, r.size.y) * 0.8, Color(col, 0.18 * a))


## Bloque solido interno (se dibuja dentro de un Prop con y-sort; `ci` es ese Prop).
func paint_block(ci: CanvasItem, f: Rect2, h: float, style: String, t: float) -> void:
	var ink := Gfx.INK
	var top := Rect2(f.position.x, f.position.y - h, f.size.x, f.size.y)
	var front := Rect2(f.position.x, f.end.y - h, f.size.x, h)
	Gfx.draw_glow(ci, Vector2(f.get_center().x + 6.0, f.end.y - f.size.y * 0.2), maxf(f.size.x, f.size.y) * 0.7 + 12.0, Color(0, 0, 0, 0.5))
	Gfx.grrect(ci, front, 2.0, block_front[0], block_front[1], ink, 2.0)
	Gfx.grrect(ci, top, 3.0, block_top[0], block_top[1], ink, 2.0)
	ci.draw_line(top.position + Vector2(3, 2), Vector2(top.end.x - 3, top.position.y + 2), Color(1, 1, 1, 0.16), 1.5)
	var x := front.position.x + 130.0
	while x < front.end.x - 20.0:
		ci.draw_line(Vector2(x, front.position.y + 3), Vector2(x, front.end.y - 3), Color(0, 0, 0, 0.35), 2.0)
		x += 130.0
	_block_dressing(ci, f, top, front, style, t)


func _block_dressing(ci: CanvasItem, _f: Rect2, _top: Rect2, front: Rect2, _style: String, _t: float) -> void:
	# franja de color en la base
	ci.draw_rect(Rect2(front.position.x + 3, front.end.y - 8, front.size.x - 6, 3), Color(block_trim, 0.7))
