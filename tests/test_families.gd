extends RefCounted
## Las familias de enemigos NO se mezclan: cada capitulo solo usa enemigos de su tema (tech / aztec / castle / anomaly)
## en pools, elites, encuentros e invocaciones de jefe. El modo Supervivencia solo mezcla familias entre FASES, nunca dentro de una oleada.

const BOSS_SUMMONS := {"custodio": ["fuse", "mender"], "xocotl": ["cerbatana", "jaguar"], "mariscal": ["sabueso", "caballero"], "vigia": ["fulgor", "acechador"]}


func run(t) -> void:
	for chid in Catalog.chapter_order:
		var ch: ChapterData = Catalog.chapter(chid)
		for pool in [ch.enemy_pool, ch.elite_pool]:
			for id in pool:
				t.eq((Catalog.enemies[id] as EnemyData).family, ch.theme, "cap %s: enemigo %s es de la familia %s" % [chid, id, ch.theme])
		for id in BOSS_SUMMONS.get(ch.boss, []):
			t.eq((Catalog.enemies[id] as EnemyData).family, ch.theme, "cap %s: el jefe invoca %s (familia correcta)" % [chid, id])
		for enc_id in Catalog.encounters:
			var enc: EncounterDef = Catalog.encounters[enc_id]
			if not enc.chapters.has(chid):
				continue
			for wave in enc.waves:
				for e in wave:
					t.eq((Catalog.enemies[e[0]] as EnemyData).family, ch.theme, "encuentro %s (cap %s): %s de la familia correcta" % [enc_id, chid, e[0]])
		# salas del capitulo: su tema debe ser el del capitulo
		for rid in ch.room_pool + ch.cache_rooms + [ch.boss_room]:
			t.eq((Catalog.rooms[rid] as RoomDef).theme, ch.theme, "cap %s: sala %s con el tema del capitulo" % [chid, rid])
