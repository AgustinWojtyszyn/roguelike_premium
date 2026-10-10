class_name DamageScale
extends RefCounted
## Escalado CENTRALIZADO de dificultad. Un unico punto de aplicacion del dano enemigo (Player.take_damage) y un unico calculo
## de vida enemiga (Game.recalc_hp_scale). Ningun script de enemigo o jefe multiplica por su cuenta.
##
## dano_final = dano_base x multiplicador(capitulo, etapa, modo/oleada, dificultad, expedicion, jefe) con tope por golpe:
##   - nunca por encima de MAX_MULT,
##   - un golpe escalado no supera max(dano_base, min(3, 0.45 x vida_max + 0.5)): el escalado nunca elimina de un golpe a quien
##     no moriria con el dano base (el dano base de un jefe sigue siendo el que diseno el jefe).
## Los multiplicadores se COMPONEN una sola vez en `multiplier()`; no hay estado acumulativo.

const NORMAL := "normal"
const HARD := "hard"
const NIGHTMARE := "nightmare"
const ORDER := [NORMAL, HARD, NIGHTMARE]

## dmg: dano enemigo | hp: vida enemiga | elite: probabilidad extra de elites | reward: monedas/XP de la run.
const DIFFICULTIES := {
	NORMAL: {"name": "NORMAL", "desc": "La experiencia pensada. Daño y vida estándar.", "dmg": 1.0, "hp": 1.0, "elite": 0.0, "reward": 1.0, "color": Color("27e0cc")},
	HARD: {"name": "DIFÍCIL", "desc": "Enemigos +25% de daño y +20% de vida, más élites. Recompensas ×1.35.", "dmg": 1.25, "hp": 1.2, "elite": 0.12, "reward": 1.35, "color": Color("ffb23d")},
	NIGHTMARE: {"name": "PESADILLA", "desc": "+50% de daño, +45% de vida y élites frecuentes. Recompensas ×1.8.", "dmg": 1.5, "hp": 1.45, "elite": 0.28, "reward": 1.8, "color": Color("ff4f6a")},
}

const CHAPTER_STEP := 0.12     # +12% por capitulo (ch1 = 1.00)
const STAGE_STEP := 0.04       # +4% por etapa dentro de la run (8 etapas = +28%)
const SURVIVAL_WAVE_STEP := 0.03
const SURVIVAL_WAVE_CAP := 0.8
const HORDE_WAVE_STEP := 0.035
const HORDE_WAVE_CAP := 1.0
const BOSS_SHARE := 0.6        # los jefes ya golpean fuerte: reciben el 60% del escalado
const MAX_MULT := 3.0
const HIT_CAP_ABS := 3.0


static func difficulty(id: String) -> Dictionary:
	return DIFFICULTIES.get(id, DIFFICULTIES[NORMAL])


static func valid(id: String) -> bool:
	return DIFFICULTIES.has(id)


## Componentes puros -> multiplicador. `ctx`: {chapter_order, stage, mode, wave, difficulty, mod_dmg, boss}
static func multiplier(ctx: Dictionary) -> float:
	var m := 1.0 + CHAPTER_STEP * float(int(ctx.get("chapter_order", 0)))
	var mode: String = ctx.get("mode", ModeRules.CAMPAIGN)
	match mode:
		ModeRules.SURVIVAL:
			m *= 1.0 + minf(SURVIVAL_WAVE_STEP * float(maxi(int(ctx.get("wave", 1)) - 1, 0)), SURVIVAL_WAVE_CAP)
		ModeRules.HORDE:
			m *= 1.0 + minf(HORDE_WAVE_STEP * float(maxi(int(ctx.get("wave", 1)) - 1, 0)), HORDE_WAVE_CAP)
		ModeRules.BOSS_RUSH:
			pass                                   # el capitulo de cada jefe ya aporta su escalon
		_:
			m *= 1.0 + STAGE_STEP * float(maxi(int(ctx.get("stage", 0)), 0))
	m *= float(difficulty(str(ctx.get("difficulty", NORMAL)))["dmg"])
	m *= maxf(float(ctx.get("mod_dmg", 1.0)), 0.1)
	if bool(ctx.get("boss", false)):
		m = 1.0 + (m - 1.0) * BOSS_SHARE
	return clampf(m, 1.0, MAX_MULT)


## Dano que llega al jugador por un golpe de `base` puntos con vida maxima `max_hp`.
static func final_hit(base: float, mult: float, max_hp: int) -> float:
	if base <= 0.0:
		return 0.0
	var limit := maxf(base, minf(HIT_CAP_ABS, 0.45 * float(max_hp) + 0.5))
	return minf(base * mult, limit)


## Vida enemiga: lo que ya definia el capitulo x modo x dificultad (se asigna, no se acumula).
static func hp_multiplier(chapter_difficulty: float, mode_scale: float, difficulty_id: String, mod_hp: float = 1.0) -> float:
	return chapter_difficulty * mode_scale * float(difficulty(difficulty_id)["hp"]) * maxf(mod_hp, 0.1)


## Contexto vivo del juego en este instante (lo usa Player.take_damage).
static func context(game: Game, boss: bool) -> Dictionary:
	var d := game.director
	return {
		"chapter_order": game.chapter.order if game.chapter != null else 0,
		"stage": d.stage if d != null else 0,
		"mode": game.mode_id,
		"wave": (d.surv_wave if d != null else 1),
		"difficulty": game.difficulty_id,
		"mod_dmg": float(game.mods.get("enemy_dmg_mult", 1.0)),
		"boss": boss,
	}
