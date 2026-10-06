class_name ContentDungeons
extends RefCounted
## Capitulos, salas curadas, encuentros, jefes y tablas de loot. La generacion procedural COMBINA estas piezas
## (sala + encuentro + lados de entrada/salida + semilla); nunca inventa geometria.

static func _room(id: String, nm: String, theme: String, size: Vector2, kind: String, p: Dictionary) -> RoomDef:
	var r := RoomDef.new()
	r.id = id
	r.display_name = nm
	r.theme = theme
	r.size = size
	r.kind = kind
	for k in p:
		r.set(k, p[k])
	return r


static func _sp(arr: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for v in arr:
		out.append(v)
	return out


static func chapters() -> Array[ChapterData]:
	var L: Array[ChapterData] = []
	L.append(_chapter("ch1", "CIRCUITOS CORRUPTOS", "Estación Cinder · Sector de mantenimiento", "tech", 0, "ch1", Color("27e0cc"),
		["maintenance", "server_hall", "reactor_chamber", "cargo_bay", "coolant_plant"], ["vault"], "core_arena",
		["skitter", "lancer", "sentry", "fuse", "aegis", "mender"], ["brute", "aegis"], "custodio", "drops_ch1", 1.0, "",
		"Una estación de investigación cuyo sistema operativo despertó con hambre. Los drones de mantenimiento ya no limpian: cazan."))
	return L


static func _chapter(id: String, nm: String, sub: String, theme: String, order: int, music: String, accent: Color, rooms: Array, caches: Array, boss_room: String, pool: Array, elites: Array, boss: String, loot: String, diff: float, req: String, desc: String) -> ChapterData:
	var c := ChapterData.new()
	c.id = id
	c.display_name = nm
	c.subtitle = sub
	c.description = desc
	c.theme = theme
	c.order = order
	c.music = music
	c.accent = accent
	c.room_pool = Array(rooms, TYPE_STRING, "", null)
	c.cache_rooms = Array(caches, TYPE_STRING, "", null)
	c.boss_room = boss_room
	c.enemy_pool = Array(pool, TYPE_STRING, "", null)
	c.elite_pool = Array(elites, TYPE_STRING, "", null)
	c.boss = boss
	c.loot_table = loot
	c.difficulty = diff
	c.unlock_requires = req
	return c


static func rooms() -> Array[RoomDef]:
	var L: Array[RoomDef] = []
	# ---------------------------------------------------------------- CAPITULO 1
	L.append(_room("maintenance", "Sala de Mantenimiento", "tech", Vector2(1200, 640), "combat", {
		"original": true,
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"props": [
			["crate_l", -420, -190, 100, 56], ["crate_s", -310, -168, 44, 34], ["barrel", -395, -120, 30, 22],
			["tank", 330, -250, 64, 44], ["terminal", 110, -314, 84, 34], ["pillar", -190, -110, 40, 34],
			["pillar", 200, 110, 40, 34], ["barrier_h", -140, 150, 170, 22], ["barrier_v", 340, -20, 22, 130],
			["crate_s", 300, 232, 44, 34], ["crate_s", 348, 250, 44, 34], ["barrel", 268, 206, 30, 22],
			["crate_s", -300, 226, 44, 34], ["barrel", -252, 246, 30, 22],
		],
		"spawns": _sp([Vector2(-515, -245), Vector2(515, -235), Vector2(-515, 235), Vector2(515, 245), Vector2(-15, -252), Vector2(-10, 262)]),
		"decor": {
			"emblem": "hex", "lane": true, "stains": 9, "litter": 26,
			"traces": [
				PackedVector2Array([Vector2(-600, -90), Vector2(-470, -90), Vector2(-470, -40), Vector2(-250, -40), Vector2(-250, -2), Vector2(-150, -2)]),
				PackedVector2Array([Vector2(600, 80), Vector2(450, 80), Vector2(450, 20), Vector2(260, 20), Vector2(260, 4), Vector2(150, 4)]),
				PackedVector2Array([Vector2(-100, -320), Vector2(-100, -230), Vector2(-60, -230), Vector2(-60, -120), Vector2(-4, -120), Vector2(-4, -80)]),
				PackedVector2Array([Vector2(160, 320), Vector2(160, 250), Vector2(110, 250), Vector2(110, 130), Vector2(8, 130), Vector2(8, 82)]),
				PackedVector2Array([Vector2(-600, 150), Vector2(-420, 150), Vector2(-420, 60), Vector2(-280, 60), Vector2(-280, 30), Vector2(-130, 30)]),
			],
			"cables": [
				[Vector2(-600, 200), Vector2(-540, 215), Vector2(-470, 190), Vector2(-420, 215)],
				[Vector2(600, -150), Vector2(540, -135), Vector2(480, -160), Vector2(430, -140), Vector2(400, -150)],
				[Vector2(200, -300), Vector2(215, -250), Vector2(190, -210), Vector2(225, -170)],
				[Vector2(-100, 320), Vector2(-90, 290), Vector2(-120, 265), Vector2(-90, 240)],
			],
		},
	}))
	var rack_props: Array = []
	for i in 7:
		rack_props.append(["rack", -500 + i * 148, -254, 84, 30])
		if i != 3:
			rack_props.append(["rack", -500 + i * 148, 224, 84, 30])
	rack_props.append(["barrier_h", -130, -28, 260, 22])
	rack_props.append(["terminal", 10, 214, 84, 34])
	L.append(_room("server_hall", "Pasillo de Servidores", "tech", Vector2(1400, 560), "combat", {
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"props": rack_props,
		"spawns": _sp([Vector2(-625, -170), Vector2(625, -170), Vector2(-625, 170), Vector2(625, 170), Vector2(-250, 0), Vector2(250, 0)]),
		"decor": {"hazard": [Rect2(-520, -10, 1040, 20)], "stains": 6, "litter": 30, "no_screens": false,
			"traces": [PackedVector2Array([Vector2(-700, 60), Vector2(-500, 60), Vector2(-500, 120), Vector2(-200, 120)]), PackedVector2Array([Vector2(700, -80), Vector2(480, -80), Vector2(480, -130), Vector2(200, -130)])]},
	}))
	L.append(_room("reactor_chamber", "Cámara del Reactor", "tech", Vector2(1100, 700), "combat", {
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"props": [
			["reactor", -90, -30, 180, 84],
			["pillar", -330, -200, 40, 34], ["pillar", 290, -200, 40, 34], ["pillar", -330, 190, 40, 34], ["pillar", 290, 190, 40, 34],
			["barrel", -220, -60, 30, 22], ["barrel", 190, 80, 30, 22], ["crate_s", 380, -80, 44, 34], ["crate_s", -420, 100, 44, 34],
		],
		"spawns": _sp([Vector2(-470, -290), Vector2(470, -290), Vector2(-470, 290), Vector2(470, 290), Vector2(0, -300), Vector2(0, 310)]),
		"decor": {"emblem": "core", "emblem_pos": Vector2(0, 10), "stains": 8, "litter": 22},
	}))
	L.append(_room("cargo_bay", "Bahía de Carga", "tech", Vector2(1300, 720), "combat", {
		"entry_sides": ["W", "S"], "exit_sides": ["E", "N"],
		"blocks": [[330, -360, 320, 230, "machine"]],
		"props": [
			["crate_l", -480, -230, 100, 56], ["crate_l", -480, -150, 100, 56], ["crate_s", -370, -200, 44, 34],
			["crate_l", 120, 200, 100, 56], ["crate_s", 230, 232, 44, 34], ["barrel", 90, 150, 30, 22],
			["terminal", -120, -354, 84, 34], ["barrier_v", -180, 40, 22, 160], ["barrel", 400, 160, 30, 22], ["crate_s", 500, 240, 44, 34],
		],
		"spawns": _sp([Vector2(-560, 250), Vector2(560, 270), Vector2(-120, -240), Vector2(200, -60), Vector2(-560, -60), Vector2(450, 100)]),
		"decor": {"lane": true, "stains": 10, "litter": 34, "hazard": [Rect2(-620, 270, 520, 14)]},
	}))
	L.append(_room("coolant_plant", "Planta de Refrigeración", "tech", Vector2(1250, 640), "combat", {
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"blocks": [[-420, -170, 300, 40, "plain"], [120, 130, 300, 40, "plain"]],
		"props": [
			["tank", -80, -270, 64, 44], ["tank", 60, 220, 64, 44], ["terminal", 300, -300, 84, 34],
			["pillar", 20, -40, 40, 34], ["barrel", -500, 70, 30, 22], ["barrel", 480, -80, 30, 22], ["crate_s", -200, 210, 44, 34],
		],
		"spawns": _sp([Vector2(-560, -240), Vector2(560, -240), Vector2(-560, 240), Vector2(560, 240), Vector2(-250, 50), Vector2(300, -60)]),
		"decor": {"stains": 7, "litter": 24, "traces": [PackedVector2Array([Vector2(-625, 40), Vector2(-420, 40), Vector2(-420, 100), Vector2(-250, 100)])]},
	}))
	L.append(_room("vault", "Cámara Sellada", "tech", Vector2(900, 560), "cache", {
		"entry_sides": ["W", "E", "S"], "exit_sides": ["E", "W", "N"],
		"props": [["terminal", -60, -254, 84, 34], ["pillar", -330, -150, 40, 34], ["pillar", 290, -150, 40, 34], ["pillar", -330, 120, 40, 34], ["pillar", 290, 120, 40, 34]],
		"spawns": _sp([]),
		"decor": {"emblem": "hex", "emblem_pos": Vector2(0, 0), "stains": 4, "litter": 12,
			"chests": [Vector2(-170, -20), Vector2(0, -50), Vector2(170, -20)]},
	}))
	L.append(_room("core_arena", "Núcleo del Custodio", "tech", Vector2(1300, 800), "boss", {
		"entry_sides": ["W", "E", "S"], "exit_sides": [],
		"props": [["pillar", -430, -240, 40, 34], ["pillar", 390, -240, 40, 34], ["pillar", -430, 230, 40, 34], ["pillar", 390, 230, 40, 34]],
		"spawns": _sp([Vector2(-540, -300), Vector2(540, -300), Vector2(-540, 300), Vector2(540, 300)]),
		"decor": {"emblem": "hex", "emblem_pos": Vector2(0, 0), "lane": true, "stains": 10, "litter": 30},
	}))
	return L


static func _enc(id: String, chapters_: Array, tier: int, waves: Array, tags: Array = []) -> EncounterDef:
	var e := EncounterDef.new()
	e.id = id
	e.chapters = Array(chapters_, TYPE_STRING, "", null)
	e.tier = tier
	e.waves = waves
	e.tags = Array(tags, TYPE_STRING, "", null)
	return e


static func encounters() -> Array[EncounterDef]:
	var L: Array[EncounterDef] = []
	# ---- CAPITULO 1
	L.append(_enc("c1_orig", ["ch1"], 2, [
		[["skitter", 0.0], ["skitter", 0.9], ["lancer", 2.3]],
		[["skitter", 0.0], ["lancer", 0.9], ["skitter", 1.8], ["lancer", 3.2]],
		[["brute", 0.0], ["lancer", 2.4], ["skitter", 3.6]],
	], ["classic"]))
	L.append(_enc("c1_t1_a", ["ch1"], 1, [[["skitter", 0.0], ["skitter", 0.8], ["skitter", 1.6]], [["lancer", 0.0], ["skitter", 1.0]]]))
	L.append(_enc("c1_t1_b", ["ch1"], 1, [[["skitter", 0.0], ["fuse", 1.0], ["fuse", 1.8]], [["lancer", 0.0], ["lancer", 1.4]]]))
	L.append(_enc("c1_t1_c", ["ch1"], 1, [[["sentry", 0.0], ["skitter", 0.6], ["skitter", 1.4]], [["lancer", 0.0], ["skitter", 0.8]]]))
	L.append(_enc("c1_t2_a", ["ch1"], 2, [[["skitter", 0.0], ["skitter", 0.8], ["aegis", 1.6]], [["lancer", 0.0], ["lancer", 1.2], ["fuse", 1.8]], [["skitter", 0.0], ["mender", 1.0], ["lancer", 2.0]]]))
	L.append(_enc("c1_t2_b", ["ch1"], 2, [[["sentry", 0.0], ["sentry", 0.8], ["skitter", 1.8]], [["fuse", 0.0], ["fuse", 0.6], ["fuse", 1.2], ["lancer", 2.0]], [["aegis", 0.0], ["lancer", 1.5], ["skitter", 2.4]]]))
	L.append(_enc("c1_t3_a", ["ch1"], 3, [[["skitter", 0.0], ["skitter", 0.7], ["lancer", 1.4], ["fuse", 2.0]], [["brute", 0.0], ["mender", 1.8], ["lancer", 2.8]], [["aegis", 0.0], ["aegis", 1.2], ["sentry", 2.0], ["skitter", 2.6]]], ["elite"]))
	L.append(_enc("c1_t3_b", ["ch1"], 3, [[["sentry", 0.0], ["lancer", 0.8], ["lancer", 1.6]], [["brute", 0.0], ["skitter", 1.4], ["skitter", 2.2], ["mender", 3.0]], [["fuse", 0.0], ["fuse", 0.5], ["fuse", 1.0], ["aegis", 1.8], ["lancer", 2.6]]], ["elite"]))
	L.append(_enc("c1_boss_adds", ["ch1"], 4, [[["skitter", 0.0], ["skitter", 0.8]]], ["boss"]))
	return L


static func bosses() -> Array[BossData]:
	var L: Array[BossData] = []
	var b := BossData.new()
	b.id = "custodio"
	b.display_name = "CUSTODIO"
	b.title = "Custodio del Núcleo"
	b.chapter = "ch1"
	b.script_path = "res://bosses/boss_custodio.gd"
	b.hp = 520.0
	b.phases = [1.0, 0.62, 0.3]
	b.accent = Color("ff4fa8")
	b.coins = 60
	b.guaranteed_loot = "boss_ch1"
	L.append(b)
	return L


static func loot_tables() -> Array[LootTable]:
	var L: Array[LootTable] = []
	var d := LootTable.new()
	d.id = "drops_ch1"
	d.entries = [
		{"type": "coins", "w": 46.0, "min": 1, "max": 2},
		{"type": "energy", "w": 26.0, "min": 6, "max": 9},
		{"type": "heart", "w": 5.0},
		{"type": "shield", "w": 6.0},
		{"type": "nothing", "w": 42.0},
	]
	L.append(d)
	var bl := LootTable.new()
	bl.id = "boss_ch1"
	bl.entries = [{"type": "rare", "w": 1.0, "tier_min": 2, "tier_max": 4}]
	L.append(bl)
	return L
