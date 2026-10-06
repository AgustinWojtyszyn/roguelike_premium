class_name Room
extends Node2D
## Una sala jugable: geometria (suelo + pasillos de entrada/salida), colisiones, props, puntos de aparicion
## y capas de dibujo. El aspecto lo pone un RoomTheme; el contenido, un RoomDef.

const BULLET_H := 26.0
const CORR_W := 160.0
const CORR_L := 320.0
const CELL := 20.0

var game: Game
var def: RoomDef
var theme: RoomTheme
var floor_rect: Rect2
var walk: Array[Rect2] = []
var bounds: Rect2
var entry_side := ""
var exit_side := ""
var entry_rect := Rect2()
var exit_rect := Rect2()
var seal_rect := Rect2()
var exit_trigger := Rect2()
var seal_open: float = 0.0
var seal_target: float = 0.0
var has_exit := false
var runs: Array[Dictionary] = []
var rects: Array[Rect2] = []
var bullet_rects: Array = []
var props: Array[Prop] = []
var spawns: Array[Vector2] = []
var spawn_open: PackedFloat32Array = PackedFloat32Array()
var spawn_target: PackedFloat32Array = PackedFloat32Array()
var spawn_glow: PackedFloat32Array = PackedFloat32Array()
var dressing: Dictionary = {}
var t: float = 0.0
var seed_v: int = 0

var floor_node: Node2D
var lights_node: Node2D
var spawn_node: Node2D
var deco_node: Node2D
var wall_node: Node2D
var seal_node: Node2D
var seal_glow_node: Node2D


class Layer extends Node2D:
	var room: Room
	var mode: int = 0
	func _draw() -> void:
		match mode:
			0: room.theme.paint_floor(self, room)
			1: room.theme.paint_lights(self, room)
			2: room.paint_spawns(self)
			3: room.paint_deco(self)
			4: room.paint_walls(self)
			5: room.theme.paint_seal_base(self, room, room.t)
			6: room.theme.paint_seal_glow(self, room, room.t)


func build(g: Game, d: RoomDef, entry: String, exit: String, sd: int = 0) -> void:
	game = g
	def = d
	seed_v = sd
	theme = RoomTheme.create(d.theme)
	entry_side = entry
	exit_side = exit
	has_exit = exit != ""
	floor_rect = Rect2(-d.size * 0.5, d.size)
	walk = [floor_rect]
	if entry != "":
		entry_rect = _corridor_rect(entry)
		walk.append(entry_rect)
	if exit != "":
		exit_rect = _corridor_rect(exit)
		walk.append(exit_rect)
		seal_rect = _seal_for(exit)
		exit_trigger = _trigger_for(exit)
	bounds = walk[0]
	for r in walk:
		bounds = bounds.merge(r)
	_compute_runs()
	_build_solids()
	spawns = d.spawns.duplicate()
	spawn_open.resize(spawns.size())
	spawn_target.resize(spawns.size())
	spawn_glow.resize(spawns.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d.id) + sd
	dressing = theme.build_dressing(self, rng)
	floor_node = _make_layer(0, -30, false)
	wall_node = _make_layer(4, -29, false)
	lights_node = _make_layer(1, -28, true)
	spawn_node = _make_layer(2, -26, false)
	seal_node = _make_layer(5, -25, false)
	deco_node = _make_layer(3, -24, true)
	seal_glow_node = _make_layer(6, -23, true)
	_spawn_props()
	_rebuild_rects()


func _make_layer(mode: int, z: int, additive: bool) -> Node2D:
	var l := Layer.new()
	l.room = self
	l.mode = mode
	l.z_index = z
	if additive:
		l.material = Gfx.add_material()
	add_child(l)
	return l


func exit_dir() -> Vector2:
	match exit_side:
		"N": return Vector2.UP
		"S": return Vector2.DOWN
		"W": return Vector2.LEFT
	return Vector2.RIGHT


func entry_dir() -> Vector2:
	match entry_side:
		"N": return Vector2.UP
		"S": return Vector2.DOWN
		"W": return Vector2.LEFT
	return Vector2.RIGHT


func corridor_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if entry_side != "":
		out.append(entry_rect)
	if exit_side != "":
		out.append(exit_rect)
	return out


func _corridor_rect(side: String) -> Rect2:
	var F := floor_rect
	match side:
		"E": return Rect2(F.end.x, -CORR_W * 0.5, CORR_L, CORR_W)
		"W": return Rect2(F.position.x - CORR_L, -CORR_W * 0.5, CORR_L, CORR_W)
		"N": return Rect2(-CORR_W * 0.5, F.position.y - CORR_L, CORR_W, CORR_L)
	return Rect2(-CORR_W * 0.5, F.end.y, CORR_W, CORR_L)


func _seal_for(side: String) -> Rect2:
	var c := _corridor_rect(side)
	match side:
		"E": return Rect2(c.position.x - 6, c.position.y, 24, c.size.y)
		"W": return Rect2(c.end.x - 18, c.position.y, 24, c.size.y)
		"N": return Rect2(c.position.x, c.end.y - 18, c.size.x, 24)
	return Rect2(c.position.x, c.position.y - 6, c.size.x, 24)


func _trigger_for(side: String) -> Rect2:
	var c := _corridor_rect(side)
	match side:
		"E": return Rect2(c.end.x - 90, c.position.y, 90, c.size.y)
		"W": return Rect2(c.position.x, c.position.y, 90, c.size.y)
		"N": return Rect2(c.position.x, c.position.y, c.size.x, 90)
	return Rect2(c.position.x, c.end.y - 90, c.size.x, 90)


## Posicion donde aparece el jugador (dentro del pasillo de entrada) y punto al que camina al entrar.
func entry_spawn() -> Vector2:
	if entry_side == "":
		return Vector2(0, floor_rect.end.y - 120)
	var c := entry_rect
	match entry_side:
		"W": return Vector2(c.position.x + 70, 0)
		"E": return Vector2(c.end.x - 70, 0)
		"N": return Vector2(0, c.position.y + 70)
	return Vector2(0, c.end.y - 70)


func entry_walk_target() -> Vector2:
	var F := floor_rect
	match entry_side:
		"W": return Vector2(F.position.x + 90, 0)
		"E": return Vector2(F.end.x - 90, 0)
		"N": return Vector2(0, F.position.y + 90)
		"S": return Vector2(0, F.end.y - 90)
	return Vector2(0, F.end.y - 120)


func in_exit_gap(x: float, side: String) -> bool:
	for r in corridor_rects():
		if side == "N" and r.size.x < r.size.y and r.end.y <= floor_rect.position.y + 1.0:
			return x > r.position.x - 40.0 and x < r.end.x + 40.0
		if side == "S" and r.size.x < r.size.y and r.position.y >= floor_rect.end.y - 1.0:
			return x > r.position.x - 40.0 and x < r.end.x + 40.0
	return false


# ------------------------------------------------------------------ geometria
func _in_walk(p: Vector2) -> bool:
	for r in walk:
		if r.has_point(p):
			return true
	return false


func _edge_segments(r: Rect2, side: String) -> Array:
	var horiz := side == "N" or side == "S"
	var lo := r.position.x if horiz else r.position.y
	var hi := r.end.x if horiz else r.end.y
	var line: float
	match side:
		"N": line = r.position.y
		"S": line = r.end.y
		"W": line = r.position.x
		_: line = r.end.x
	var segs: Array = [[lo, hi]]
	for o in walk:
		if o == r:
			continue
		var touches := false
		var o_lo: float
		var o_hi: float
		match side:
			"N":
				touches = is_equal_approx(o.end.y, line)
				o_lo = o.position.x
				o_hi = o.end.x
			"S":
				touches = is_equal_approx(o.position.y, line)
				o_lo = o.position.x
				o_hi = o.end.x
			"W":
				touches = is_equal_approx(o.end.x, line)
				o_lo = o.position.y
				o_hi = o.end.y
			_:
				touches = is_equal_approx(o.position.x, line)
				o_lo = o.position.y
				o_hi = o.end.y
		if not touches:
			continue
		var nsegs: Array = []
		for s in segs:
			if o_hi <= s[0] or o_lo >= s[1]:
				nsegs.append(s)
				continue
			if o_lo > s[0]:
				nsegs.append([s[0], o_lo])
			if o_hi < s[1]:
				nsegs.append([o_hi, s[1]])
		segs = nsegs
	return segs


func _compute_runs() -> void:
	runs.clear()
	for r in walk:
		for side in ["N", "S", "W", "E"]:
			var horiz: bool = side == "N" or side == "S"
			var line: float
			match side:
				"N": line = r.position.y
				"S": line = r.end.y
				"W": line = r.position.x
				_: line = r.end.x
			for s in _edge_segments(r, side):
				var lo: float = s[0]
				var hi: float = s[1]
				var ea := 0.0
				var eb := 0.0
				# esquinas convexas: el muro se prolonga para cerrar el vertice
				var r_lo: float = r.position.x if horiz else r.position.y
				var r_hi: float = r.end.x if horiz else r.end.y
				if is_equal_approx(lo, r_lo) and _convex_corner(r, side, true):
					ea = 50.0
				if is_equal_approx(hi, r_hi) and _convex_corner(r, side, false):
					eb = 50.0
				runs.append({"side": side, "a": lo, "b": hi, "edge": line, "ext_a": ea, "ext_b": eb, "rect": r})


func _convex_corner(r: Rect2, side: String, low_end: bool) -> bool:
	# punto justo fuera del vertice, siguiendo la direccion perpendicular
	var p: Vector2
	match side:
		"N", "S":
			var x := r.position.x - 2.0 if low_end else r.end.x + 2.0
			var y := (r.position.y + 2.0) if side == "N" else (r.end.y - 2.0)
			p = Vector2(x, y)
		_:
			var y2 := r.position.y - 2.0 if low_end else r.end.y + 2.0
			var x2 := (r.position.x + 2.0) if side == "W" else (r.end.x - 2.0)
			p = Vector2(x2, y2)
	return not _in_walk(p)


## Descompone todo lo que NO es transitable (dentro de un margen) en rectangulos solidos.
func _build_solids() -> void:
	var region := bounds.grow_individual(180.0, 260.0, 180.0, 180.0)
	var x0 := floorf(region.position.x / CELL) * CELL
	var y0 := floorf(region.position.y / CELL) * CELL
	var x1 := ceilf(region.end.x / CELL) * CELL
	var y1 := ceilf(region.end.y / CELL) * CELL
	var open_runs: Array = []   # runs en curso: [xa, xb, ystart]
	var solids: Array[Rect2] = []
	var y := y0
	while y < y1:
		var cur: Array = []
		var x := x0
		var start := -1.0
		while x < x1:
			var is_walk := _in_walk(Vector2(x + CELL * 0.5, y + CELL * 0.5))
			if not is_walk and start < 0.0:
				start = x
			elif is_walk and start >= 0.0:
				cur.append([start, x])
				start = -1.0
			x += CELL
		if start >= 0.0:
			cur.append([start, x1])
		# fusion vertical con runs abiertos identicos
		var next_open: Array = []
		for c in cur:
			var found := -1
			for k in open_runs.size():
				if is_equal_approx(open_runs[k][0], c[0]) and is_equal_approx(open_runs[k][1], c[1]):
					found = k
					break
			if found >= 0:
				next_open.append(open_runs[found])
				open_runs.remove_at(found)
			else:
				next_open.append([c[0], c[1], y])
		for o in open_runs:
			solids.append(Rect2(o[0], o[2], o[1] - o[0], y - o[2]))
		open_runs = next_open
		y += CELL
	for o in open_runs:
		solids.append(Rect2(o[0], o[2], o[1] - o[0], y1 - o[2]))
	base_solids = solids


var base_solids: Array[Rect2] = []
var extra_solids: Array[Rect2] = []


func _spawn_props() -> void:
	for d in def.blocks:
		# [x, y, w, h, style]  -> bloque solido de pared con altura
		var r := Rect2(float(d[0]), float(d[1]), float(d[2]), float(d[3]))
		var p := Prop.create(game, "block", r, str(d[4]) if d.size() > 4 else "")
		props.append(p)
		game.ysort.add_child(p)
	for d in def.props:
		var r := Rect2(float(d[1]), float(d[2]), float(d[3]), float(d[4]))
		var p := Prop.create(game, str(d[0]), r)
		props.append(p)
		game.ysort.add_child(p)


func remove_prop(p: Prop) -> void:
	props.erase(p)
	p.queue_free()
	_rebuild_rects()


func _rebuild_rects() -> void:
	rects.clear()
	bullet_rects.clear()
	for w in base_solids:
		rects.append(w)
		bullet_rects.append([Rect2(w.position.x, w.position.y - BULLET_H, w.size.x, w.size.y), null])
	if seal_open < 0.98 and has_exit:
		rects.append(seal_rect)
		bullet_rects.append([seal_rect, null])
	for p in props:
		rects.append(p.foot)
		bullet_rects.append([Rect2(p.foot.position.x, p.foot.position.y - BULLET_H, p.foot.size.x, p.foot.size.y), p])
	for r in extra_solids:
		rects.append(r)
		bullet_rects.append([Rect2(r.position.x, r.position.y - BULLET_H, r.size.x, r.size.y), null])


func add_extra_solid(r: Rect2) -> void:
	extra_solids.append(r)
	rects.append(r)
	bullet_rects.append([Rect2(r.position.x, r.position.y - BULLET_H, r.size.x, r.size.y), null])


func los(a: Vector2, b: Vector2) -> bool:
	for r in rects:
		if Gfx.seg_rect(a, b, r) >= 0.0:
			return false
	return true


func free_point(p: Vector2, r: float) -> bool:
	if not bounds.has_point(p):
		return false
	for rc in rects:
		var rr: Rect2 = rc
		var cp := Vector2(clampf(p.x, rr.position.x, rr.end.x), clampf(p.y, rr.position.y, rr.end.y))
		if cp.distance_squared_to(p) < r * r:
			return false
	return true


func in_main_floor(p: Vector2) -> bool:
	return floor_rect.has_point(p)


func set_exit_open(open: bool) -> void:
	seal_target = 1.0 if open else 0.0
	if open:
		_rebuild_rects_deferred = true


var _rebuild_rects_deferred := false


func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0)
	t += dt
	var changed := false
	for i in spawn_open.size():
		var o := spawn_open[i]
		var tg := spawn_target[i]
		if absf(o - tg) > 0.001:
			spawn_open[i] = move_toward(o, tg, dt * (3.5 if tg > o else 2.2))
			changed = true
		spawn_glow[i] = move_toward(spawn_glow[i], tg, dt * 4.0)
	if changed:
		spawn_node.queue_redraw()
	if absf(seal_open - seal_target) > 0.001:
		seal_open = move_toward(seal_open, seal_target, dt * 1.6)
		seal_node.queue_redraw()
		if seal_open >= 0.98 and _rebuild_rects_deferred:
			_rebuild_rects_deferred = false
			_rebuild_rects()
	deco_node.queue_redraw()
	seal_glow_node.queue_redraw()


func open_spawn(i: int, open: bool) -> void:
	spawn_target[i] = 1.0 if open else 0.0


func paint_spawns(ci: CanvasItem) -> void:
	for i in spawns.size():
		theme.paint_spawn(ci, spawns[i], spawn_open[i], t, i)


func paint_deco(ci: CanvasItem) -> void:
	theme.paint_deco(ci, self, t)
	for i in spawns.size():
		theme.paint_spawn_glow(ci, spawns[i], spawn_glow[i], t, i)


func paint_walls(ci: CanvasItem) -> void:
	# primero laterales y sur, al final los muros norte (se superponen en las esquinas)
	for pass_i in 3:
		for run in runs:
			var s: String = run["side"]
			var order := 0 if (s == "W" or s == "E") else (1 if s == "S" else 2)
			if order == pass_i:
				theme.paint_wall_run(ci, self, run)
