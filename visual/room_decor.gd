class_name RoomDecor
extends RefCounted
## Decoracion contextual con arte importado. Determinista por sala (semilla = id de sala + semilla de la run),
## asi el re-horneado del suelo (al reanudar la app en Android) repite exactamente las mismas piezas.

const MARGIN := 90.0


static func _blocked(room: Room, p: Vector2, pad: float, solids: bool) -> bool:
	if not room.floor_rect.grow(-MARGIN).has_point(p):
		return true
	for sp in room.spawns:
		if p.distance_to(sp) < 70.0 + pad:
			return true
	for r in [room.entry_rect, room.exit_rect, room.seal_rect]:
		if (r as Rect2).size != Vector2.ZERO and (r as Rect2).grow(70.0).has_point(p):
			return true
	if solids:
		for r in room.rects:
			if r.grow(pad).has_point(p):
				return true
	for c in room.def.decor.get("chests", []):
		if p.distance_to(c) < 80.0:
			return true
	return false


static func _rng(room: Room, salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(room.def.id) + room.seed_v * 7 + salt
	return rng


static func _count(spec: Dictionary, rng: RandomNumberGenerator, area_k: float) -> int:
	var n: Array = spec["n"]
	return int(round(float(rng.randi_range(int(n[0]), int(n[1]))) * area_k))


## Se llama desde RoomTheme.paint_floor (capa horneada).
static func paint_floor(ci: CanvasItem, room: Room) -> void:
	if not VisualProfiles.sprites_enabled():
		return
	var t0 := Time.get_ticks_usec()
	_paint_floor(ci, room)
	_paint_authored(ci, room)
	if Boot.has_flag("frametimes"):
		print("  [decor] suelo %.2f ms" % (float(Time.get_ticks_usec() - t0) / 1000.0))


static func _paint_floor(ci: CanvasItem, room: Room) -> void:
	var dec := VisualProfiles.decor(room.def.theme)
	if dec.is_empty():
		return
	var rng := _rng(room, 11)
	var F := room.floor_rect
	var area_k := clampf(F.size.x * F.size.y / (1100.0 * 700.0), 0.6, 1.6)
	var composed: bool = room.def.decor.get("composed", false)
	for spec in dec.get("floor", []):
		# sala compuesta a mano: no se esparcen objetos al azar (los pone `authored`); solo manchas/grietas
		if composed and (spec.get("kind", "obj") != "decal" or str(spec["art"]).contains("gravel")):
			continue
		var tex := AssetCatalog.tex(spec["art"])
		if tex == null:
			continue
		var bb: Array = AssetCatalog.info(spec["art"]).get("bbox", [0, 0, tex.get_width(), tex.get_height()])
		var bw := float(bb[2]) - float(bb[0])
		var bh := float(bb[3]) - float(bb[1])
		var s: float = float(spec.get("s", 1.0))
		if spec.has("h"):
			s = float(spec["h"]) / bh   # piezas Premium: alto de juego explicito (el arte 3D no tiene la escala de pixel-art)
		var decal: bool = spec.get("kind", "obj") == "decal"
		for i in _count(spec, rng, area_k):
			var p := Vector2.ZERO
			var ok := false
			for tries in 14:
				p = Vector2(rng.randf_range(F.position.x, F.end.x), rng.randf_range(F.position.y, F.end.y))
				if not _blocked(room, p, 18.0 if not decal else 0.0, not decal):
					ok = true
					break
			if not ok:
				continue
			var flip := -1.0 if rng.randf() < 0.5 else 1.0
			var col: Color = Color(spec.get("tint", Color.WHITE), float(spec.get("a", 1.0)))
			var w := bw * s
			var h := bh * s
			var src := Rect2(float(bb[0]), float(bb[1]), bw, bh)
			if decal:
				ci.draw_set_transform(p, rng.randf_range(-0.3, 0.3), Vector2(flip, 1.0))
				ci.draw_texture_rect_region(tex, Rect2(-w * 0.5, -h * 0.5, w, h), src, col)
			else:
				ci.draw_set_transform(p, 0.0, Vector2(flip, 1.0))
				Gfx.draw_glow(ci, Vector2(0, -h * 0.1), maxf(w, h) * 0.55, Color(0, 0, 0, 0.35))
				ci.draw_texture_rect_region(tex, Rect2(-w * 0.5, -h, w, h), src, col)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Piezas altas sin colision pegadas al muro norte (se llama una vez desde Room.build, despues de los props).
static func spawn_standing(room: Room, parent: Node2D) -> void:
	if not VisualProfiles.sprites_enabled():
		return
	var dec := VisualProfiles.decor(room.def.theme)
	var stand: Array = dec.get("stand", [])
	if stand.is_empty() or room.def.decor.get("composed", false):
		return
	var rng := _rng(room, 97)
	var F := room.floor_rect
	var occupied: Array[float] = []
	for tp in room.dressing.get("torches", []):
		occupied.append((tp as Vector2).x)
	for spec in stand:
		var tex := AssetCatalog.tex(spec["art"])
		if tex == null:
			continue
		var bb: Array = AssetCatalog.info(spec["art"]).get("bbox", [0, 0, tex.get_width(), tex.get_height()])
		var s: float = float(spec.get("s", 1.0))
		if spec.has("h"):
			s = float(spec["h"]) / maxf(1.0, float(bb[3]) - float(bb[1]))
		for i in _count(spec, rng, 1.0):
			for tries in 12:
				var p := Vector2(rng.randf_range(F.position.x + 110.0, F.end.x - 110.0), F.position.y + 34.0 + rng.randf_range(0.0, 18.0))
				if _blocked(room, p, 26.0, true):
					continue
				var near := false
				for ox in occupied:
					if absf(ox - p.x) < 110.0:
						near = true
				if near:
					continue
				occupied.append(p.x)
				var spr := Sprite2D.new()
				spr.texture = tex
				spr.region_enabled = true
				spr.region_rect = Rect2(float(bb[0]), float(bb[1]), float(bb[2]) - float(bb[0]), float(bb[3]) - float(bb[1]))
				spr.centered = false
				spr.offset = Vector2(-(float(bb[2]) - float(bb[0])) * 0.5, -(float(bb[3]) - float(bb[1])))
				spr.scale = Vector2(s, s) * (1.0 if rng.randf() < 0.5 else 1.0)
				spr.position = p
				spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if absf(s - roundf(s)) < 0.12 and not spec.has("h") else CanvasItem.TEXTURE_FILTER_LINEAR
				spr.modulate = spec.get("tint", Color.WHITE)
				parent.add_child(spr)
				room.standing.append(spr)
				break


## Punto de entrada publico para temas que no usan paint_floor() de RoomDecor (tech): piezas de `decor.authored`.
static func paint_authored(ci: CanvasItem, room: Room) -> void:
	if VisualProfiles.sprites_enabled():
		_paint_authored(ci, room)


## Piezas bajas COMPUESTAS a mano para una sala (def.decor["authored"]): se hornean en el suelo con sombra de contacto.
## Solo cosas pequeñas y planas: lo alto/solido es un Prop con colision, nunca decoracion horneada.
static func _paint_authored(ci: CanvasItem, room: Room) -> void:
	var items: Array = room.def.decor.get("authored", [])
	for spec in items:
		var id: String = ThemeCastle.PRE + str(spec["art"]) if room.def.theme == "castle" else str(spec["art"])
		var tex := AssetCatalog.tex(id)
		if tex == null:
			continue
		var bb: Array = AssetCatalog.info(id).get("bbox", [0, 0, tex.get_width(), tex.get_height()])
		var bw := float(bb[2]) - float(bb[0])
		var bh := float(bb[3]) - float(bb[1])
		var s := float(spec["h"]) / bh
		var p: Vector2 = spec["p"]
		var w := bw * s
		var h := bh * s
		var flip := -1.0 if bool(spec.get("flip", false)) else 1.0
		Gfx.draw_glow(ci, p + Vector2(0, -h * 0.08), maxf(w, h) * 0.62, Color(0, 0, 0, 0.42))
		ci.draw_set_transform(p, 0.0, Vector2(flip, 1.0))
		ci.draw_texture_rect_region(tex, Rect2(-w * 0.5, -h, w, h), Rect2(float(bb[0]), float(bb[1]), bw, bh), spec.get("tint", ThemeCastle.PROP_TINT))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
