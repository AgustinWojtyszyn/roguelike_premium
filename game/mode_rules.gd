class_name ModeRules
extends RefCounted
## Modos de juego: CAMPANA (principal, 4 capitulos x 5 etapas = 20 niveles, una familia por capitulo), SUPERVIVENCIA (arenas
## propias, oleadas infinitas, familias por FASES), BOSS RUSH (los 4 jefes seguidos) y DESAFIO (campana con reglas especiales).
## Solo datos y funciones puras: el RunDirector las consulta; la campana no cambia.

const CAMPAIGN := "campaign"
const SURVIVAL := "survival"
const BOSS_RUSH := "bossrush"
const CHALLENGE := "challenge"
const ORDER := [CAMPAIGN, SURVIVAL, BOSS_RUSH, CHALLENGE]

const NAMES := {CAMPAIGN: "CAMPAÑA", SURVIVAL: "SUPERVIVENCIA", BOSS_RUSH: "BOSS RUSH", CHALLENGE: "DESAFÍO"}
const DESCS := {
	CAMPAIGN: "20 niveles en 4 capítulos. Cada capítulo es una familia de enemigos distinta.",
	SURVIVAL: "Arenas compactas y oleadas sin fin. Una fase por familia: eléctrica, azteca, medieval, interdimensional.",
	BOSS_RUSH: "Los 4 jefes seguidos. Entre jefes: recupera algo, elige arma y mejora.",
	CHALLENGE: "La campaña con una regla especial. Sin atajos.",
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
