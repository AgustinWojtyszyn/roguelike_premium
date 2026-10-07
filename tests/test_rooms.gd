extends RefCounted
## Geometria de salas: spawns y props validos, entrada/salida conectadas, nada tapa los pasillos.

func _blocked_rects(room: Room, def: RoomDef) -> Array[Rect2]:
	var out: Array[Rect2] = room.base_solids.duplicate()
	for b in def.blocks:
		out.append(Rect2(float(b[0]), float(b[1]), float(b[2]), float(b[3])))
	for p in def.props:
		out.append(Rect2(float(p[1]), float(p[2]), float(p[3]), float(p[4])))
	return out


func _free(p: Vector2, rects: Array[Rect2], r: float) -> bool:
	for rc in rects:
		var cp := Vector2(clampf(p.x, rc.position.x, rc.end.x), clampf(p.y, rc.position.y, rc.end.y))
		if cp.distance_squared_to(p) < r * r:
			return false
	return true


func _reachable(start: Vector2, rects: Array[Rect2], bounds: Rect2) -> Dictionary:
	var cell := 24.0
	var seen := {}
	var q: Array[Vector2i] = [Vector2i(int(floor(start.x / cell)), int(floor(start.y / cell)))]
	seen[q[0]] = true
	var head := 0
	while head < q.size():
		var c := q[head]
		head += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if seen.has(n):
				continue
			var p := Vector2((float(n.x) + 0.5) * cell, (float(n.y) + 0.5) * cell)
			if not bounds.has_point(p) or not _free(p, rects, 12.0):
				continue
			seen[n] = true
			q.append(n)
	return seen


func run(t) -> void:
	var checked := 0
	for rid in Catalog.rooms:
		var def: RoomDef = Catalog.rooms[rid]
		var sides_in: Array = [""] if def.kind == "survival" else (def.entry_sides if not def.entry_sides.is_empty() else ["W"])
		var sides_out: Array = def.exit_sides if not def.exit_sides.is_empty() else [""]
		for ein in sides_in:
			for eout in sides_out:
				if eout == ein:
					continue
				var room := Room.new()
				room.build_geometry(def, ein, eout)
				var blocked := _blocked_rects(room, def)
				var tag := "%s %s->%s" % [rid, ein, eout]
				checked += 1
				# contencion: todo el perimetro exterior de las zonas transitables esta cubierto por muros solidos
				var leaks := 0
				for run in room.runs:
					var a: float = run["a"]
					var b: float = run["b"]
					var edge: float = run["edge"]
					var v := a + 10.0
					while v < b - 10.0:
						var q: Vector2
						match run["side"]:
							"N": q = Vector2(v, edge - 30.0)
							"S": q = Vector2(v, edge + 30.0)
							"W": q = Vector2(edge - 30.0, v)
							_: q = Vector2(edge + 30.0, v)
						var covered := false
						for sr in room.base_solids:
							if sr.has_point(q):
								covered = true
								break
						if not covered:
							leaks += 1
						v += 25.0
				t.eq(leaks, 0, "%s: muros solidos cubren todo el perimetro (huecos: %d)" % [tag, leaks])
				# props y bloques dentro del suelo
				for p in def.props:
					var r := Rect2(float(p[1]), float(p[2]), float(p[3]), float(p[4]))
					t.check(room.floor_rect.grow(2.0).encloses(r), "%s: prop %s dentro del suelo" % [tag, p[0]])
				for b in def.blocks:
					var r := Rect2(float(b[0]), float(b[1]), float(b[2]), float(b[3]))
					t.check(room.floor_rect.grow(2.0).encloses(r), "%s: bloque dentro del suelo" % tag)
				# nada tapa las bocas de los pasillos
				for corr in room.corridor_rects():
					var mouth := corr.grow_individual(140.0 if corr.size.x > corr.size.y else 0.0, 140.0 if corr.size.x < corr.size.y else 0.0, 140.0 if corr.size.x > corr.size.y else 0.0, 140.0 if corr.size.x < corr.size.y else 0.0)
					for p in def.props:
						var r := Rect2(float(p[1]), float(p[2]), float(p[3]), float(p[4]))
						t.check(not r.intersects(mouth), "%s: prop %s no obstruye el pasillo" % [tag, p[0]])
					for b in def.blocks:
						var r := Rect2(float(b[0]), float(b[1]), float(b[2]), float(b[3]))
						t.check(not r.intersects(mouth), "%s: bloque no obstruye el pasillo" % tag)
				# conectividad: desde la entrada se llega a la salida y a todos los spawns / cofres
				var start := room.entry_walk_target() if ein != "" else Vector2(0, room.floor_rect.end.y - 120.0)
				var seen := _reachable(start, blocked, room.bounds)
				if eout != "":
					var tp := room.exit_trigger.get_center()
					t.check(seen.has(Vector2i(int(floor(tp.x / 24.0)), int(floor(tp.y / 24.0)))), "%s: salida alcanzable" % tag)
				for sp in def.spawns:
					t.check(room.floor_rect.grow(-30.0).has_point(sp), "%s: spawn %s dentro del suelo" % [tag, str(sp)])
					t.check(_free(sp, blocked, 16.0), "%s: spawn %s libre de obstaculos" % [tag, str(sp)])
					t.check(seen.has(Vector2i(int(floor(sp.x / 24.0)), int(floor(sp.y / 24.0)))), "%s: spawn %s alcanzable" % [tag, str(sp)])
				for cs in def.decor.get("chests", []):
					t.check(_free(cs, blocked, 24.0), "%s: cofre libre" % tag)
				room.free()
	t.check(checked >= 25, "se comprobaron combinaciones de sala (%d)" % checked)
