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
	L.append(_chapter("ch2", "TEMPLO DE JADE", "Civilización antigua · Ruinas conectadas", "aztec", 1, "ch2", Color("3dd9a8"),
		["templo_patio", "sala_serpientes", "camara_jade", "mirador_sol"], ["tesoro_azteca"], "gran_altar",
		["jaguar", "cerbatana", "idolo"], ["idolo", "jaguar"], "", "drops_ch2", 1.25, "ch1",
		"Bajo la estación dormía algo más antiguo: un templo cuyos circuitos son de jade y cuyos guardianes nunca durmieron."))
	L.append(_chapter("ch3", "FORTALEZA ESCARLATA", "Caballeros · Murallas oscuras", "castle", 2, "ch3", Color("e0405a"),
		["patio_armas", "gran_salon", "mazmorra", "murallas"], ["armeria_tesoro"], "sala_trono",
		["caballero", "ballestero", "sabueso"], ["caballero", "ballestero"], "", "drops_ch3", 1.55, "ch2",
		"Una fortaleza que no figura en ningún mapa y que cada noche cambia de dueño. Sus caballeros ya no recuerdan por quién luchan."))
	L.append(_chapter("ch4", "GRIETA INTERDIMENSIONAL", "Anomalías · Realidad inestable", "anomaly", 3, "ch4", Color("ff4fd8"),
		["fractura", "bucle_gravedad", "camara_espejo", "puente_roto"], ["relicario_vacio"], "nucleo_anomalo",
		["fulgor", "acechador", "ojo"], ["ojo", "acechador"], "", "drops_ch4", 1.9, "ch3",
		"Donde la realidad se rasga, las reglas se doblan. Nada de lo que veas estará mucho tiempo en el mismo sitio."))
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
			["barrel", -220, -60, 30, 22], ["barrel", 190, 80, 30, 22], ["crate_s", 320, -80, 44, 34], ["crate_s", -360, 100, 44, 34],
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
			["pillar", 20, -40, 40, 34], ["barrel", -420, 70, 30, 22], ["barrel", 400, -80, 30, 22], ["crate_s", -200, 210, 44, 34],
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
	# ---------------------------------------------------------------- CAPITULO 2: azteca tecnologica
	L.append(_room("templo_patio", "Patio del Templo", "aztec", Vector2(1250, 680), "combat", {
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"props": [
			["glyph_pillar", -440, -230, 40, 34], ["glyph_pillar", 400, -230, 40, 34], ["glyph_pillar", -440, 200, 40, 34], ["glyph_pillar", 400, 200, 40, 34],
			["brazier", -560, -280, 34, 26], ["brazier", 530, -280, 34, 26], ["brazier", -560, 250, 34, 26], ["brazier", 530, 250, 34, 26],
			["stone_block", -200, -60, 70, 50], ["stone_block", 140, 30, 70, 50], ["urn", -330, 120, 28, 22], ["urn", 300, -150, 28, 22], ["urn", 80, 240, 28, 22],
		],
		"spawns": _sp([Vector2(-540, -190), Vector2(540, -190), Vector2(-540, 190), Vector2(540, 190), Vector2(0, -250), Vector2(0, 260)]),
		"decor": {"emblem": "sun", "stains": 8, "litter": 22, "jade_lines": [PackedVector2Array([Vector2(-625, 90), Vector2(-420, 90), Vector2(-420, 160), Vector2(-200, 160)]), PackedVector2Array([Vector2(625, -80), Vector2(420, -80), Vector2(420, -150), Vector2(200, -150)])]},
	}))
	L.append(_room("sala_serpientes", "Sala de las Serpientes", "aztec", Vector2(1400, 580), "combat", {
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"blocks": [[-330, -70, 240, 38, "plain"], [90, 40, 240, 38, "plain"]],
		"props": [
			["totem", -560, -240, 50, 34], ["totem", 510, -240, 50, 34], ["totem", -560, 210, 50, 34], ["totem", 510, 210, 50, 34],
			["brazier", -40, -250, 34, 26], ["brazier", 20, 230, 34, 26], ["urn", -450, 80, 28, 22], ["urn", 420, -110, 28, 22], ["stone_block", -90, 130, 70, 50],
		],
		"spawns": _sp([Vector2(-640, -170), Vector2(640, -170), Vector2(-640, 170), Vector2(640, 170), Vector2(-250, 150), Vector2(250, -150)]),
		"decor": {"stains": 6, "litter": 24, "jade_lines": [PackedVector2Array([Vector2(-700, 0), Vector2(-480, 0), Vector2(-480, -80), Vector2(-330, -80)]), PackedVector2Array([Vector2(700, 20), Vector2(480, 20), Vector2(480, 100), Vector2(330, 100)])]},
	}))
	L.append(_room("camara_jade", "Cámara de Jade", "aztec", Vector2(1150, 700), "combat", {
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"blocks": [[-110, -70, 220, 120, "altar"]],
		"props": [
			["glyph_pillar", -400, -220, 40, 34], ["glyph_pillar", 360, -220, 40, 34], ["glyph_pillar", -400, 200, 40, 34], ["glyph_pillar", 360, 200, 40, 34],
			["urn", -250, 0, 28, 22], ["urn", 230, -10, 28, 22], ["brazier", -150, -270, 34, 26], ["brazier", 120, 250, 34, 26],
		],
		"spawns": _sp([Vector2(-480, -290), Vector2(480, -290), Vector2(-480, 290), Vector2(480, 290), Vector2(-300, 0), Vector2(300, 0)]),
		"decor": {"emblem": "sun", "emblem_pos": Vector2(0, -10), "stains": 8, "litter": 20},
	}))
	L.append(_room("mirador_sol", "Mirador del Sol", "aztec", Vector2(1300, 720), "combat", {
		"entry_sides": ["W", "S"], "exit_sides": ["E", "N"],
		"blocks": [[-650, -360, 300, 230, "plain"]],
		"props": [
			["totem", 400, -250, 50, 34], ["glyph_pillar", -100, -250, 40, 34], ["stone_block", -200, 60, 70, 50], ["stone_block", 150, 160, 70, 50],
			["brazier", 540, 270, 34, 26], ["brazier", -560, 270, 34, 26], ["urn", 60, -60, 28, 22], ["urn", 350, 40, 28, 22],
		],
		"spawns": _sp([Vector2(-540, 250), Vector2(560, -230), Vector2(560, 250), Vector2(-190, -240), Vector2(250, 20), Vector2(-330, 0)]),
		"decor": {"stains": 8, "litter": 26},
	}))
	L.append(_room("tesoro_azteca", "Cámara del Tesoro", "aztec", Vector2(900, 560), "cache", {
		"entry_sides": ["W", "E", "S"], "exit_sides": ["E", "W", "N"],
		"props": [["brazier", -300, -230, 34, 26], ["brazier", 270, -230, 34, 26], ["glyph_pillar", -330, 110, 40, 34], ["glyph_pillar", 290, 110, 40, 34]],
		"spawns": _sp([]),
		"decor": {"emblem": "sun", "stains": 4, "litter": 12, "chests": [Vector2(-170, -20), Vector2(0, -50), Vector2(170, -20)]},
	}))
	L.append(_room("gran_altar", "Gran Altar del Sol", "aztec", Vector2(1300, 800), "boss", {
		"entry_sides": ["W", "E", "S"], "exit_sides": [],
		"props": [["totem", -450, -270, 50, 34], ["totem", 400, -270, 50, 34], ["glyph_pillar", -450, 250, 40, 34], ["glyph_pillar", 410, 250, 40, 34], ["brazier", -200, -300, 34, 26], ["brazier", 170, -300, 34, 26]],
		"spawns": _sp([Vector2(-540, -300), Vector2(540, -300), Vector2(-540, 300), Vector2(540, 300), Vector2(0, -330), Vector2(0, 340)]),
		"decor": {"emblem": "sun", "stains": 10, "litter": 30},
	}))
	# ---------------------------------------------------------------- CAPITULO 3: fortaleza oscura
	L.append(_room("patio_armas", "Patio de Armas", "castle", Vector2(1300, 680), "combat", {
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"props": [
			["statue", -430, -240, 56, 36], ["statue", 380, -240, 56, 36], ["column", -140, -110, 40, 34], ["column", 100, 100, 40, 34],
			["weapon_rack", -470, 90, 90, 26], ["weapon_rack", 400, -60, 90, 26], ["wood_crate", -300, 170, 40, 30], ["wood_barrel", -340, 215, 28, 22], ["wood_crate", 340, 190, 40, 30], ["wood_barrel", 300, -170, 28, 22],
		],
		"spawns": _sp([Vector2(-560, -200), Vector2(560, -200), Vector2(-560, 200), Vector2(560, 200), Vector2(0, -260), Vector2(0, 270)]),
		"decor": {"emblem": "sigil", "stains": 9, "litter": 22},
	}))
	L.append(_room("gran_salon", "Gran Salón", "castle", Vector2(1450, 600), "combat", {
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"props": [
			["table", -380, -90, 220, 44], ["table", 160, 50, 220, 44], ["column", -620, -250, 40, 34], ["column", 580, -250, 40, 34], ["column", -620, 210, 40, 34], ["column", 580, 210, 40, 34],
			["wood_barrel", -100, 200, 28, 22], ["wood_barrel", 120, -200, 28, 22], ["wood_crate", 300, -180, 40, 30],
		],
		"spawns": _sp([Vector2(-660, -150), Vector2(660, -150), Vector2(-660, 150), Vector2(660, 150), Vector2(-120, 110), Vector2(180, -120)]),
		"decor": {"carpet": true, "stains": 7, "litter": 26},
	}))
	L.append(_room("mazmorra", "Mazmorra", "castle", Vector2(1100, 680), "combat", {
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"blocks": [[-330, -250, 40, 190, "plain"], [290, 60, 40, 190, "plain"], [-100, -30, 200, 36, "plain"]],
		"props": [["wood_barrel", -460, 150, 28, 22], ["wood_barrel", 400, -180, 28, 22], ["wood_crate", -230, 200, 40, 30], ["wood_crate", 190, -210, 40, 30], ["statue", 40, 220, 56, 36], ["column", -520, -320, 40, 34]],
		"spawns": _sp([Vector2(-440, -270), Vector2(440, -270), Vector2(-440, 280), Vector2(440, 280), Vector2(-20, 120), Vector2(-20, -140)]),
		"decor": {"stains": 11, "litter": 24},
	}))
	L.append(_room("murallas", "Murallas", "castle", Vector2(1300, 700), "combat", {
		"entry_sides": ["W", "S"], "exit_sides": ["E", "N"],
		"blocks": [[330, -350, 320, 220, "plain"]],
		"props": [["column", -300, -240, 40, 34], ["column", -60, 150, 40, 34], ["statue", -430, 30, 56, 36], ["wood_crate", 120, 200, 40, 30], ["wood_barrel", 160, 250, 28, 22], ["weapon_rack", -200, -330, 90, 26], ["wood_crate", 460, 100, 40, 30]],
		"spawns": _sp([Vector2(-540, 250), Vector2(560, 250), Vector2(-540, -220), Vector2(120, -240), Vector2(300, 40), Vector2(-250, 60)]),
		"decor": {"stains": 8, "litter": 26},
	}))
	L.append(_room("armeria_tesoro", "Armería Olvidada", "castle", Vector2(900, 560), "cache", {
		"entry_sides": ["W", "E", "S"], "exit_sides": ["E", "W", "N"],
		"props": [["weapon_rack", -380, -250, 90, 26], ["weapon_rack", 290, -250, 90, 26], ["column", -330, 120, 40, 34], ["column", 290, 120, 40, 34]],
		"spawns": _sp([]),
		"decor": {"emblem": "sigil", "stains": 4, "litter": 12, "chests": [Vector2(-170, -20), Vector2(0, -50), Vector2(170, -20)]},
	}))
	L.append(_room("sala_trono", "Sala del Trono", "castle", Vector2(1300, 800), "boss", {
		"entry_sides": ["W", "E", "S"], "exit_sides": [],
		"props": [["statue", -460, -280, 56, 36], ["statue", 410, -280, 56, 36], ["column", -460, 250, 40, 34], ["column", 420, 250, 40, 34], ["column", -150, -300, 40, 34], ["column", 110, -300, 40, 34]],
		"spawns": _sp([Vector2(-540, -300), Vector2(540, -300), Vector2(-540, 300), Vector2(540, 300), Vector2(0, -330), Vector2(0, 340)]),
		"decor": {"emblem": "sigil", "carpet": true, "stains": 10, "litter": 30},
	}))
	# ---------------------------------------------------------------- CAPITULO 4: interdimensional
	L.append(_room("fractura", "Fractura", "anomaly", Vector2(1250, 700), "combat", {
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"props": [["crystal", -300, -150, 60, 36], ["crystal", 260, 130, 60, 36], ["rift_stone", -80, 60, 50, 34], ["rift_stone", 120, -190, 50, 34], ["anomaly_box", -450, 190, 40, 30], ["anomaly_box", 430, -200, 40, 30], ["orb_pillar", -20, -270, 40, 34]],
		"spawns": _sp([Vector2(-540, -250), Vector2(540, -250), Vector2(-540, 250), Vector2(540, 250), Vector2(0, 280), Vector2(-250, -20)]),
		"decor": {"emblem": "tri", "stains": 6, "litter": 10},
	}))
	L.append(_room("bucle_gravedad", "Bucle de Gravedad", "anomaly", Vector2(1100, 720), "combat", {
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"blocks": [[-60, -90, 120, 180, "plain"]],
		"props": [["rift_stone", -300, -220, 50, 34], ["rift_stone", 260, 200, 50, 34], ["crystal", -420, 150, 60, 36], ["crystal", 360, -160, 60, 36], ["anomaly_box", 200, -60, 40, 30], ["anomaly_box", -240, 60, 40, 30]],
		"spawns": _sp([Vector2(-460, -290), Vector2(460, -290), Vector2(-460, 290), Vector2(460, 290), Vector2(0, -300), Vector2(0, 310)]),
		"decor": {"emblem": "tri", "emblem_pos": Vector2(0, 0), "stains": 6, "litter": 8},
	}))
	L.append(_room("camara_espejo", "Cámara del Espejo", "anomaly", Vector2(1300, 640), "combat", {
		"entry_sides": ["W", "E"], "exit_sides": ["E", "W"],
		"props": [["orb_pillar", -400, -200, 40, 34], ["orb_pillar", 360, -200, 40, 34], ["orb_pillar", -400, 170, 40, 34], ["orb_pillar", 360, 170, 40, 34], ["crystal", -40, -40, 60, 36], ["anomaly_box", -200, 150, 40, 30], ["anomaly_box", 180, -150, 40, 30]],
		"spawns": _sp([Vector2(-570, -170), Vector2(570, -170), Vector2(-570, 170), Vector2(570, 170), Vector2(-200, -40), Vector2(240, 60)]),
		"decor": {"emblem": "tri", "stains": 6, "litter": 8},
	}))
	L.append(_room("puente_roto", "Puente Roto", "anomaly", Vector2(1400, 560), "combat", {
		"entry_sides": ["W", "S"], "exit_sides": ["E", "N"],
		"blocks": [[-500, -250, 300, 80, "plain"], [200, 170, 300, 80, "plain"]],
		"props": [["crystal", -80, -160, 60, 36], ["rift_stone", 80, 40, 50, 34], ["rift_stone", -300, 90, 50, 34], ["anomaly_box", 420, -150, 40, 30], ["orb_pillar", -10, 190, 40, 34]],
		"spawns": _sp([Vector2(-640, -160), Vector2(640, -160), Vector2(-640, 170), Vector2(640, 170), Vector2(-120, 0), Vector2(300, -50)]),
		"decor": {"stains": 6, "litter": 8},
	}))
	L.append(_room("relicario_vacio", "Relicario del Vacío", "anomaly", Vector2(900, 560), "cache", {
		"entry_sides": ["W", "E", "S"], "exit_sides": ["E", "W", "N"],
		"props": [["crystal", -330, -150, 60, 36], ["crystal", 270, -150, 60, 36], ["orb_pillar", -330, 110, 40, 34], ["orb_pillar", 290, 110, 40, 34]],
		"spawns": _sp([]),
		"decor": {"emblem": "tri", "stains": 4, "litter": 6, "chests": [Vector2(-170, -20), Vector2(0, -50), Vector2(170, -20)]},
	}))
	L.append(_room("nucleo_anomalo", "Núcleo Anómalo", "anomaly", Vector2(1300, 800), "boss", {
		"entry_sides": ["W", "E", "S"], "exit_sides": [],
		"props": [["orb_pillar", -450, -270, 40, 34], ["orb_pillar", 410, -270, 40, 34], ["crystal", -450, 230, 60, 36], ["crystal", 390, 230, 60, 36], ["rift_stone", -100, -300, 50, 34], ["rift_stone", 60, 320, 50, 34]],
		"spawns": _sp([Vector2(-540, -300), Vector2(540, -300), Vector2(-540, 300), Vector2(540, 300), Vector2(0, -330), Vector2(0, 340)]),
		"decor": {"emblem": "tri", "stains": 8, "litter": 10},
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
	# ---- CAPITULO 2
	L.append(_enc("c2_t1_a", ["ch2"], 1, [[["cerbatana", 0.0], ["cerbatana", 1.0]], [["jaguar", 0.0], ["cerbatana", 1.2]]]))
	L.append(_enc("c2_t1_b", ["ch2"], 1, [[["jaguar", 0.0], ["cerbatana", 0.8]], [["cerbatana", 0.0], ["cerbatana", 0.8], ["cerbatana", 1.6]]]))
	L.append(_enc("c2_t2_a", ["ch2"], 2, [[["jaguar", 0.0], ["jaguar", 1.0], ["cerbatana", 1.8]], [["idolo", 0.0], ["cerbatana", 1.0], ["cerbatana", 1.8]], [["jaguar", 0.0], ["cerbatana", 0.8], ["cerbatana", 1.6]]]))
	L.append(_enc("c2_t2_b", ["ch2"], 2, [[["cerbatana", 0.0], ["cerbatana", 0.8], ["jaguar", 1.6]], [["jaguar", 0.0], ["jaguar", 0.9], ["idolo", 1.8]], [["cerbatana", 0.0], ["jaguar", 1.0], ["cerbatana", 1.8]]]))
	L.append(_enc("c2_t3_a", ["ch2"], 3, [[["jaguar", 0.0], ["jaguar", 0.8], ["cerbatana", 1.6], ["cerbatana", 2.2]], [["idolo", 0.0], ["jaguar", 1.2], ["jaguar", 2.0]], [["idolo", 0.0], ["cerbatana", 1.0], ["cerbatana", 1.6], ["jaguar", 2.4]]], ["elite"]))
	L.append(_enc("c2_t4_a", ["ch2"], 4, [[["jaguar", 0.0], ["jaguar", 0.7], ["cerbatana", 1.4], ["cerbatana", 2.0]], [["idolo", 0.0], ["idolo", 1.5], ["jaguar", 2.4]], [["jaguar", 0.0], ["jaguar", 0.6], ["jaguar", 1.2], ["cerbatana", 1.8], ["cerbatana", 2.4]]], ["finale"]))
	# ---- CAPITULO 3
	L.append(_enc("c3_t1_a", ["ch3"], 1, [[["sabueso", 0.0], ["sabueso", 0.8]], [["ballestero", 0.0], ["sabueso", 1.0]]]))
	L.append(_enc("c3_t1_b", ["ch3"], 1, [[["ballestero", 0.0], ["ballestero", 1.2]], [["sabueso", 0.0], ["sabueso", 0.7], ["ballestero", 1.5]]]))
	L.append(_enc("c3_t2_a", ["ch3"], 2, [[["caballero", 0.0], ["sabueso", 1.4]], [["ballestero", 0.0], ["ballestero", 1.0], ["sabueso", 1.8]], [["caballero", 0.0], ["ballestero", 1.4]]]))
	L.append(_enc("c3_t2_b", ["ch3"], 2, [[["sabueso", 0.0], ["sabueso", 0.6], ["sabueso", 1.2], ["ballestero", 2.0]], [["caballero", 0.0], ["sabueso", 1.6]], [["ballestero", 0.0], ["ballestero", 0.9], ["caballero", 2.0]]]))
	L.append(_enc("c3_t3_a", ["ch3"], 3, [[["caballero", 0.0], ["caballero", 1.4], ["ballestero", 2.2]], [["sabueso", 0.0], ["sabueso", 0.6], ["ballestero", 1.4], ["ballestero", 2.0]], [["caballero", 0.0], ["sabueso", 1.2], ["sabueso", 1.8], ["ballestero", 2.4]]], ["elite"]))
	L.append(_enc("c3_t4_a", ["ch3"], 4, [[["caballero", 0.0], ["caballero", 1.2], ["ballestero", 2.0], ["ballestero", 2.6]], [["sabueso", 0.0], ["sabueso", 0.5], ["sabueso", 1.0], ["caballero", 1.8]], [["caballero", 0.0], ["caballero", 1.0], ["ballestero", 1.8], ["sabueso", 2.4]]], ["finale"]))
	# ---- CAPITULO 4
	L.append(_enc("c4_t1_a", ["ch4"], 1, [[["fulgor", 0.0], ["fulgor", 1.0]], [["acechador", 0.0], ["fulgor", 1.2]]]))
	L.append(_enc("c4_t1_b", ["ch4"], 1, [[["fulgor", 0.0], ["fulgor", 0.9], ["fulgor", 1.8]], [["acechador", 0.0], ["fulgor", 1.0]]]))
	L.append(_enc("c4_t2_a", ["ch4"], 2, [[["acechador", 0.0], ["acechador", 1.2], ["fulgor", 1.8]], [["ojo", 0.0], ["fulgor", 1.0], ["fulgor", 1.8]], [["acechador", 0.0], ["fulgor", 0.8], ["fulgor", 1.6]]]))
	L.append(_enc("c4_t2_b", ["ch4"], 2, [[["fulgor", 0.0], ["fulgor", 0.8], ["acechador", 1.6]], [["acechador", 0.0], ["acechador", 1.0], ["ojo", 1.8]], [["fulgor", 0.0], ["fulgor", 0.8], ["fulgor", 1.6], ["acechador", 2.2]]]))
	L.append(_enc("c4_t3_a", ["ch4"], 3, [[["acechador", 0.0], ["acechador", 1.0], ["fulgor", 1.8], ["fulgor", 2.4]], [["ojo", 0.0], ["acechador", 1.4], ["acechador", 2.2]], [["ojo", 0.0], ["fulgor", 1.0], ["fulgor", 1.6], ["acechador", 2.4]]], ["elite"]))
	L.append(_enc("c4_t4_a", ["ch4"], 4, [[["acechador", 0.0], ["acechador", 0.8], ["fulgor", 1.4], ["fulgor", 2.0]], [["ojo", 0.0], ["ojo", 1.5], ["acechador", 2.4]], [["acechador", 0.0], ["acechador", 0.6], ["acechador", 1.2], ["fulgor", 1.8], ["fulgor", 2.4]]], ["finale"]))
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
	for k in ["drops_ch2", "drops_ch3", "drops_ch4"]:
		var dd := LootTable.new()
		dd.id = k
		dd.entries = d.entries.duplicate(true)
		L.append(dd)
	var bl := LootTable.new()
	bl.id = "boss_ch1"
	bl.entries = [{"type": "rare", "w": 1.0, "tier_min": 2, "tier_max": 4}]
	L.append(bl)
	return L
