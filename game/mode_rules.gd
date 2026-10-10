class_name ModeRules
extends RefCounted
## Modos de juego: CAMPANA (principal, 4 capitulos x 5 etapas = 20 niveles, una familia por capitulo), SUPERVIVENCIA (arenas
## propias, oleadas infinitas, familias por FASES), BOSS RUSH (los 4 jefes seguidos) y DESAFIO (campana con reglas especiales).
## Solo datos y funciones puras: el RunDirector las consulta; la campana no cambia.

const CAMPAIGN := "campaign"
const SURVIVAL := "survival"
const BOSS_RUSH := "bossrush"
const CHALLENGE := "challenge"
const HORDE := "horde"
const TIME_ATTACK := "timeattack"
const EXPEDITION := "expedition"
const ORDER := [CAMPAIGN, SURVIVAL, BOSS_RUSH, CHALLENGE, HORDE, TIME_ATTACK, EXPEDITION]
## Modos que se juegan en la familia (capitulo) elegida en el inicio, igual que la campana.
const CHAPTER_MODES := [CAMPAIGN, CHALLENGE, HORDE, TIME_ATTACK, EXPEDITION]

const NAMES := {CAMPAIGN: "CAMPAÑA", SURVIVAL: "SUPERVIVENCIA", BOSS_RUSH: "BOSS RUSH", CHALLENGE: "DESAFÍO",
	HORDE: "HORDA INFINITA", TIME_ATTACK: "CONTRARRELOJ", EXPEDITION: "EXPEDICIÓN"}
const GOALS := {
	CAMPAIGN: "Completa los 4 capítulos.", SURVIVAL: "Aguanta las oleadas de las 4 familias.", BOSS_RUSH: "Derrota a los 4 jefes.",
	CHALLENGE: "Gana con una regla especial.", HORDE: "Llega a la oleada más alta. Sin final.",
	TIME_ATTACK: "Limpia 5 salas lo más rápido posible.", EXPEDITION: "Cruza el capítulo por rutas y vence al jefe.",
}
const DESCS := {
	CAMPAIGN: "20 niveles en 4 capítulos. Cada capítulo es una familia de enemigos distinta.",
	SURVIVAL: "Arenas compactas y oleadas sin fin. Una fase por familia: eléctrica, azteca, medieval, interdimensional.",
	BOSS_RUSH: "Los 4 jefes seguidos. Entre jefes: recupera algo, elige arma y mejora.",
	CHALLENGE: "La campaña con una regla especial. Sin atajos.",
	HORDE: "Una sola arena de tu capítulo. Oleadas cada vez más duras, élites y campeones, mejora cada 3 oleadas. Si caes, termina.",
	TIME_ATTACK: "5 salas de tu capítulo contra el reloj. Sin mejoras ni descansos: cada golpe recibido suma +3 s.",
	EXPEDITION: "Elige tu ruta en cada tramo: combate, élite, cofre o descanso. Los modificadores dan riesgo y recompensa.",
}

const WAVES_PER_PHASE := 5

## id -> {name, desc, mods}. Los `mods` los leen Game / Bullets / Pickups / RunDirector.
const CHALLENGES := {
	"one_weapon": {"name": "UNA SOLA ARMA", "desc": "Solo tu arma inicial. No se puede recoger ni cambiar.", "mods": {"one_weapon": true}, "bonus": 1.5},
	"glass": {"name": "CRISTAL", "desc": "Solo 3 de vida y sin escudo.", "mods": {"hp_cap": 3, "no_shield": true}, "bonus": 1.6},
	"fast_bullets": {"name": "BALAS RÁPIDAS", "desc": "Los proyectiles enemigos van un 40% más rápido.", "mods": {"enemy_bullet_speed": 1.4}, "bonus": 1.4},
	"elites": {"name": "TODOS ÉLITE", "desc": "Cada enemigo con vida es élite.", "mods": {"all_elite": true}, "bonus": 1.8},
}
const CHALLENGE_ORDER := ["one_weapon", "glass", "fast_bullets", "elites"]

## Arenas de supervivencia (una por familia) y capitulo cuya familia usan.
const ARENAS := ["arena_tech", "arena_aztec", "arena_castle", "arena_anomaly"]


static func phase_of_wave(n: int) -> int:
	return (n - 1) / WAVES_PER_PHASE


## Capitulo (familia) de una fase; tras la 4a vuelve a empezar con mas dificultad.
static func chapter_of_phase(phase: int) -> String:
	return Catalog.chapter_order[phase % Catalog.chapter_order.size()]


static func loop_of_phase(phase: int) -> int:
	return phase / Catalog.chapter_order.size()


static func difficulty_scale(n: int, phase: int) -> float:
	return 1.0 + 0.045 * float(n - 1) + 0.35 * float(loop_of_phase(phase))


## Oleada n de supervivencia: [{id, delay, elite}] con enemigos SOLO de la familia de su fase.
## Presupuesto de amenaza creciente; mas variedad tactica con las oleadas (no solo mas unidades).
static func survival_wave(n: int, rng: RandomNumberGenerator) -> Array:
	var phase := phase_of_wave(n)
	var ch: ChapterData = Catalog.chapter(chapter_of_phase(phase))
	var in_phase := (n - 1) % WAVES_PER_PHASE          # 0..4
	var budget := 3.0 + float(n) * 1.15 + float(loop_of_phase(phase)) * 4.0
	var pool: Array = []
	for id in ch.enemy_pool:
		var d: EnemyData = Catalog.enemies[id]
		# las oleadas iniciales de cada fase solo usan lo basico de la familia; lo pesado entra despues
		if in_phase == 0 and d.threat > 2.2:
			continue
		pool.append(d)
	if pool.is_empty():
		for id in ch.enemy_pool:
			pool.append(Catalog.enemies[id])
	var out: Array = []
	var t := 0.0
	var guard := 0
	while budget > 0.4 and out.size() < 16 and guard < 60:
		guard += 1
		var d: EnemyData = pool[rng.randi() % pool.size()]
		if d.threat > budget + 1.0:
			continue
		budget -= d.threat
		out.append({"id": d.id, "delay": t, "elite": false})
		t += rng.randf_range(0.35, 0.9)
	# elite al final de cada fase y, desde la oleada 3, de vez en cuando
	var want_elite := in_phase == WAVES_PER_PHASE - 1 or (n >= 3 and n % 3 == 0)
	if want_elite and not ch.elite_pool.is_empty():
		out.append({"id": ch.elite_pool[rng.randi() % ch.elite_pool.size()], "delay": t + 0.6, "elite": true})
	return out


static func survival_score(kills: int, wave: int, time: float) -> int:
	return kills * 10 + wave * 100 + int(time * 0.5)


## Estructura de plan de una etapa de supervivencia (no es de DungeonGenerator: no hay pasillos ni salida).
static func survival_stage(phase: int) -> Dictionary:
	var arena: String = ARENAS[phase % ARENAS.size()]
	return {"kind": "survival", "room": arena, "encounter": "", "elite": false, "entry": "", "exit": "", "perk_after": false,
		"name": (Catalog.rooms[arena] as RoomDef).display_name, "chapter": chapter_of_phase(phase)}


## Plan del Boss Rush: los jefes de los capitulos en orden, cada uno en su sala de jefe; entre jefes se camina por el pasillo de salida.
static func boss_rush_plan(rooms: Dictionary) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	var order: Array = Catalog.chapter_order
	for i in order.size():
		var ch: ChapterData = Catalog.chapter(order[i])
		var def: RoomDef = rooms[ch.boss_room]
		var entry: String = def.entry_sides[0] if not def.entry_sides.is_empty() else "W"
		var exit := ""
		if i < order.size() - 1 and not def.exit_sides.is_empty():
			var opts: Array = def.exit_sides.filter(func(s): return s != entry)
			exit = opts[0] if not opts.is_empty() else def.exit_sides[0]
		plan.append({"kind": "boss", "room": ch.boss_room, "encounter": "", "elite": false, "entry": entry, "exit": exit,
			"perk_after": i < order.size() - 1, "name": def.display_name, "chapter": ch.id})
	return plan


# ------------------------------------------------------------------ HORDA INFINITA
const HORDE_MAX_ALIVE := 12          # enemigos simultaneos maximos (rendimiento y justicia): el resto espera en cola
const HORDE_PERK_EVERY := 3          # mejora cada N oleadas
const HORDE_CHAMPION_EVERY := 5      # campeon (elite del mayor peligro) cada N oleadas
const HORDE_MAX_UNITS := 18          # unidades por oleada (la presion sigue creciendo por vida/dano/elites, no por cantidad ilimitada)


## Familia (capitulo) de la arena de la Horda: la del capitulo elegido.
static func horde_arena(chapter_id: String) -> String:
	var i := maxi(Catalog.chapter_order.find(chapter_id), 0)
	return ARENAS[i % ARENAS.size()]


static func horde_stage(chapter_id: String) -> Dictionary:
	var arena := horde_arena(chapter_id)
	return {"kind": "horde", "room": arena, "encounter": "", "elite": false, "entry": "", "exit": "", "perk_after": false,
		"name": (Catalog.rooms[arena] as RoomDef).display_name, "chapter": chapter_id}


## Oleada n de la Horda: [{id, delay, elite}]. Solo enemigos del capitulo elegido (sin mezclar familias).
## Presupuesto de amenaza creciente con tope de unidades; lo pesado entra tras las primeras oleadas; elites cada 3 y campeon cada 5.
static func horde_wave(n: int, chapter_id: String, rng: RandomNumberGenerator) -> Array:
	var ch: ChapterData = Catalog.chapter(chapter_id)
	var budget := 4.0 + float(n) * 1.5
	var pool: Array = []
	for id in ch.enemy_pool:
		var d: EnemyData = Catalog.enemies[id]
		if n < 4 and d.threat > 2.2:
			continue
		pool.append(d)
	if pool.is_empty():
		for id in ch.enemy_pool:
			pool.append(Catalog.enemies[id])
	var out: Array = []
	var t := 0.0
	var guard := 0
	while budget > 0.4 and out.size() < HORDE_MAX_UNITS and guard < 80:
		guard += 1
		var d: EnemyData = pool[rng.randi() % pool.size()]
		if d.threat > budget + 1.0:
			continue
		budget -= d.threat
		out.append({"id": d.id, "delay": t, "elite": false})
		t += rng.randf_range(0.25, 0.7)
	if n % 3 == 0 and not ch.elite_pool.is_empty():
		out.append({"id": ch.elite_pool[rng.randi() % ch.elite_pool.size()], "delay": t + 0.5, "elite": true})
	if n % HORDE_CHAMPION_EVERY == 0:
		# campeon: el enemigo de mayor peligro de la familia, elite, mas un acompanante
		var best: EnemyData = pool[0]
		for d in pool:
			if (d as EnemyData).threat > best.threat:
				best = d
		out.append({"id": best.id, "delay": t + 1.2, "elite": true, "champion": true})
	return out


static func horde_hp_scale(n: int) -> float:
	return minf(1.0 + 0.06 * float(maxi(n - 1, 0)), 2.6)


static func horde_score(kills: int, wave: int, time: float) -> int:
	return kills * 10 + wave * 150 + int(time * 0.5)


# ------------------------------------------------------------------ CONTRARRELOJ
const TA_ROOMS := 5
const TA_PENALTY := 3.0              # segundos que suma cada golpe recibido


## Los 5 primeros encuentros del capitulo elegido: sin mejoras entre salas, sin cofres, sin jefe.
static func time_attack_plan(chapter: ChapterData, seed_v: int) -> Array[Dictionary]:
	var full := DungeonGenerator.generate(chapter, seed_v, Catalog.rooms, Catalog.encounters)
	var out: Array[Dictionary] = []
	for st in full:
		if st["kind"] in ["cache", "boss"]:
			continue
		var c: Dictionary = (st as Dictionary).duplicate()
		c["perk_after"] = false
		out.append(c)
		if out.size() >= TA_ROOMS:
			break
	return out


static func time_attack_total(time: float, penalty: float) -> float:
	return time + penalty


# ------------------------------------------------------------------ EXPEDICION
const EXP_LEGS := 6                  # tramos antes del jefe (el jefe es el tramo final)

## Modificadores temporales de un tramo: riesgo -> recompensa. `mods` se funde en Game.mods mientras dura el tramo.
const EXP_MODIFIERS := {
	"armored": {"name": "BLINDADOS", "desc": "Enemigos con +35% de vida.", "mods": {"enemy_hp_mult": 1.35}, "risk": 1, "coins": 14},
	"frenzy": {"name": "FRENESÍ", "desc": "Proyectiles enemigos +35% más rápidos y +15% de daño.", "mods": {"enemy_bullet_speed": 1.35, "enemy_dmg_mult": 1.15}, "risk": 1, "coins": 14},
	"veterans": {"name": "VETERANOS", "desc": "Todos los enemigos son élite.", "mods": {"all_elite": true}, "risk": 2, "coins": 28},
	"siege": {"name": "ASEDIO", "desc": "+25% de vida, +25% de daño y proyectiles más rápidos.", "mods": {"enemy_hp_mult": 1.25, "enemy_dmg_mult": 1.25, "enemy_bullet_speed": 1.2}, "risk": 2, "coins": 30},
}
const EXP_MODIFIER_ORDER := ["armored", "frenzy", "veterans", "siege"]
const EXP_KIND_NAMES := {"combat": "COMBATE", "elite": "ÉLITE", "cache": "COFRES", "rest": "DESCANSO", "boss": "JEFE"}


## Opciones de ruta tras el tramo `leg` (0-based) de la expedicion: 2 o 3 {kind, room, encounter, entry, exit, modifier, ...}.
## Compatibilidad: solo salas del capitulo elegido; la entrada exigida por la salida anterior; nunca dos descansos seguidos.
static func expedition_options(chapter: ChapterData, leg: int, need_entry: String, prev_kind: String, rng: RandomNumberGenerator, used_rooms: Array) -> Array:
	var opts: Array = []
	var kinds: Array[String] = ["combat"]
	if leg >= 1:
		kinds.append("elite")
	if leg >= 2 and leg < EXP_LEGS - 1:
		kinds.append("cache" if prev_kind != "cache" and rng.randf() < 0.55 else "rest")
	if prev_kind == "rest":
		kinds.erase("rest")
	if kinds.size() < 2:
		kinds.append("combat")
	while kinds.size() > 3:
		kinds.remove_at(rng.randi() % kinds.size())
	for kind in kinds:
		var pool: Array[String] = chapter.cache_rooms if kind in ["cache", "rest"] else chapter.room_pool
		var room_id := DungeonGenerator._pick_room(rng, pool, Catalog.rooms, Array(used_rooms, TYPE_STRING, "", null), need_entry)
		var def: RoomDef = Catalog.rooms[room_id]
		var entry := need_entry
		if entry == "" or not (entry in def.entry_sides):
			entry = def.entry_sides[0] if not def.entry_sides.is_empty() else "W"
		var exit := ""
		if not def.exit_sides.is_empty():
			var ex: Array = def.exit_sides.filter(func(s): return s != entry)
			exit = ex[rng.randi_range(0, ex.size() - 1)] if not ex.is_empty() else def.exit_sides[0]
		var tier := 1 if leg < 2 else 2
		if kind == "elite":
			tier = 3
		var enc := ""
		if kind in ["combat", "elite"]:
			enc = DungeonGenerator._pick_encounter(rng, chapter.id, tier, Catalog.encounters)
		var mod := ""
		if kind in ["combat", "elite"] and leg >= 1 and rng.randf() < 0.55:
			mod = EXP_MODIFIER_ORDER[rng.randi() % EXP_MODIFIER_ORDER.size()]
		opts.append({"kind": kind, "room": room_id, "encounter": enc, "entry": entry, "exit": exit, "modifier": mod,
			"elite": kind == "elite", "perk_after": kind in ["combat", "elite"] and leg % 2 == 1, "name": def.display_name})
	return opts


static func expedition_boss_stage(chapter: ChapterData, need_entry: String) -> Dictionary:
	var def: RoomDef = Catalog.rooms[chapter.boss_room]
	var entry := need_entry if need_entry in def.entry_sides else (def.entry_sides[0] if not def.entry_sides.is_empty() else "W")
	return {"kind": "boss", "room": chapter.boss_room, "encounter": "", "elite": false, "entry": entry, "exit": "", "perk_after": false,
		"name": def.display_name, "modifier": ""}


static func option_reward_coins(opt: Dictionary, leg: int) -> int:
	var base := 10 + leg * 4
	match str(opt["kind"]):
		"elite":
			base += 20
		"cache", "rest":
			base = 0
	if str(opt.get("modifier", "")) != "":
		base += int(EXP_MODIFIERS[str(opt["modifier"])]["coins"])
	return base
