class_name DungeonGenerator
extends RefCounted
## Generador de run. Combina bloques CURADOS (salas + encuentros) con una semilla. Salida: lista de etapas
## [{kind, room, encounter, elite, entry, exit, perk_after, name}]. Determinista: misma semilla => misma run.

const OPP := {"W": "E", "E": "W", "N": "S", "S": "N"}


static func generate(chapter: ChapterData, seed_v: int, rooms: Dictionary, encounters: Dictionary) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var plan: Array[Dictionary] = []
	var used_rooms: Array[String] = []
	var combat_idx := 0
	var need_entry := ""
	for i in chapter.stage_plan.size():
		var kind: String = chapter.stage_plan[i]
		var pool: Array[String]
		match kind:
			"cache":
				pool = chapter.cache_rooms
			"boss":
				pool = [chapter.boss_room]
			_:
				pool = chapter.room_pool
		var room_id := _pick_room(rng, pool, rooms, used_rooms, need_entry)
		used_rooms.append(room_id)
		var def: RoomDef = rooms[room_id]
		var entry := need_entry
		if entry == "" or not (entry in def.entry_sides):
			entry = def.entry_sides[0] if not def.entry_sides.is_empty() else "W"
		var exit := ""
		if kind != "boss" and not def.exit_sides.is_empty():
			var opts: Array = def.exit_sides.filter(func(s): return s != entry)
			if opts.is_empty():
				opts = def.exit_sides
			exit = opts[rng.randi_range(0, opts.size() - 1)]
		var enc_id := ""
		var tier := 0
		match kind:
			"combat":
				tier = 1 if combat_idx == 0 else 2
				combat_idx += 1
			"elite":
				tier = 3
			"boss":
				tier = 4
		if kind != "cache":
			enc_id = _pick_encounter(rng, chapter.id, tier, encounters)
		plan.append({
			"kind": kind, "room": room_id, "encounter": enc_id, "elite": kind == "elite",
			"entry": entry, "exit": exit, "perk_after": i in chapter.perk_after, "name": def.display_name,
		})
		need_entry = OPP.get(exit, "")
	return plan


static func _pick_room(rng: RandomNumberGenerator, pool: Array[String], rooms: Dictionary, used: Array[String], need_entry: String) -> String:
	var cands: Array[String] = []
	for id in pool:
		if used.has(id):
			continue
		if need_entry == "" or need_entry in (rooms[id] as RoomDef).entry_sides:
			cands.append(id)
	if cands.is_empty():
		for id in pool:
			if not used.has(id):
				cands.append(id)
	if cands.is_empty():
		cands = pool.duplicate()
	return cands[rng.randi_range(0, cands.size() - 1)]


static func _pick_encounter(rng: RandomNumberGenerator, chapter_id: String, tier: int, encounters: Dictionary) -> String:
	var ids: Array[String] = []
	for k in encounters:
		var e: EncounterDef = encounters[k]
		if chapter_id in e.chapters and e.tier == tier:
			ids.append(k)
	if ids.is_empty():
		# el tier mas cercano disponible
		var best_gap := 99
		for k in encounters:
			var e: EncounterDef = encounters[k]
			if chapter_id in e.chapters and absi(e.tier - tier) < best_gap:
				best_gap = absi(e.tier - tier)
		for k in encounters:
			var e: EncounterDef = encounters[k]
			if chapter_id in e.chapters and absi(e.tier - tier) == best_gap:
				ids.append(k)
	ids.sort()
	if ids.is_empty():
		return ""
	return ids[rng.randi_range(0, ids.size() - 1)]
