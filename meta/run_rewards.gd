class_name RunRewards
extends RefCounted
## Convierte el resumen de una run en progreso persistente: monedas, XP (cuenta + pase), estadisticas,
## misiones, desbloqueo de capitulos. Una sola funcion pura sobre PlayerProfile => facil de probar.

## summary: {character, chapter, won, stages, rooms, kills, kills_cat:{}, chests, perks, bosses, nodamage_rooms, coins, time, weapons_seen:[]}
static func apply(profile: PlayerProfile, summary: Dictionary, chapter: ChapterData, catalog_missions: Dictionary, next_chapter: String = "") -> Dictionary:
	var won: bool = summary.get("won", false)
	var kills := int(summary.get("kills", 0))
	var rooms := int(summary.get("rooms", 0))
	var coins := int(summary.get("coins", 0))
	var bonus_coins := 0
	var xp := int(kills * 0.6) + rooms * 7 + int(summary.get("bosses", 0)) * 40
	if won and chapter != null:
		bonus_coins = chapter.coin_reward
		xp += chapter.xp_reward
	var mode := str(summary.get("mode", "campaign"))
	if mode != "campaign":
		bonus_coins = mode_bonus(summary)
		xp = int(kills * 0.5) + int(summary.get("wave", 0)) * 6 + int(summary.get("bosses", 0)) * 60
		if mode == "timeattack" or mode == "expedition":
			xp = int(kills * 0.5) + rooms * 7 + int(summary.get("bosses", 0)) * 60 + (60 if won else 0)
	# dificultad: mas riesgo, mas recompensa (la fija DamageScale.DIFFICULTIES; Normal = x1)
	var rmult := float(DamageScale.difficulty(str(summary.get("difficulty", "normal")))["reward"])
	coins = int(round(float(coins) * rmult))
	bonus_coins = int(round(float(bonus_coins) * rmult))
	xp = int(round(float(xp) * (1.0 + (rmult - 1.0) * 0.5)))
	profile.add_coins(coins + bonus_coins)
	profile.data["xp_total"] = int(profile.data["xp_total"]) + xp
	profile.data["pass"]["xp"] = int(profile.data["pass"]["xp"]) + xp
	var st: Dictionary = profile.data["stats"]
	st["kills"] = int(st["kills"]) + kills
	st["rooms"] = int(st["rooms"]) + rooms
	st["chests"] = int(st["chests"]) + int(summary.get("chests", 0))
	st["perks"] = int(st["perks"]) + int(summary.get("perks", 0))
	st["bosses"] = int(st["bosses"]) + int(summary.get("bosses", 0))
	st["runs"] = int(st["runs"]) + 1
	st["playtime"] = float(st["playtime"]) + float(summary.get("time", 0.0))
	if won:
		st["wins"] = int(st["wins"]) + 1
	else:
		st["deaths"] = int(st["deaths"]) + 1
	var cid: String = summary.get("character", "vesper")
	var cs := profile.char_state(cid)
	cs["xp"] = int(cs.get("xp", 0)) + xp
	cs["runs"] = int(cs.get("runs", 0)) + 1
	if won:
		cs["wins"] = int(cs.get("wins", 0)) + 1
	profile.data["characters"][cid] = cs
	for w in summary.get("weapons_seen", []):
		profile.data["weapons_seen"][w] = true
	if mode != "campaign":
		record_mode(profile, summary)
	elif chapter != null:
		var chs := profile.chapter_state(chapter.id)
		chs["best_stage"] = maxi(int(chs.get("best_stage", 0)), int(summary.get("stages", 0)))
		if won:
			chs["cleared"] = int(chs.get("cleared", 0)) + 1
		profile.data["chapters"][chapter.id] = chs
		if won and next_chapter != "":
			profile.unlock_chapter(next_chapter)
	# misiones
	MissionSystem.record(profile, catalog_missions, "kills", kills)
	var kc: Dictionary = summary.get("kills_cat", {})
	for cat in kc:
		MissionSystem.record(profile, catalog_missions, "kills_cat:" + str(cat), int(kc[cat]))
	MissionSystem.record(profile, catalog_missions, "rooms", rooms)
	MissionSystem.record(profile, catalog_missions, "chests", int(summary.get("chests", 0)))
	MissionSystem.record(profile, catalog_missions, "perks", int(summary.get("perks", 0)))
	MissionSystem.record(profile, catalog_missions, "bosses", int(summary.get("bosses", 0)))
	MissionSystem.record(profile, catalog_missions, "nodamage_rooms", int(summary.get("nodamage_rooms", 0)))
	if won:
		MissionSystem.record(profile, catalog_missions, "chapters", 1)
		MissionSystem.record(profile, catalog_missions, "wins_char:" + cid, 1)
	profile.touch()
	return {"coins": coins, "bonus_coins": bonus_coins, "xp": xp}


## Monedas extra de los modos alternativos (la campana usa chapter.coin_reward).
static func mode_bonus(summary: Dictionary) -> int:
	var won: bool = summary.get("won", false)
	match str(summary.get("mode", "campaign")):
		"survival":
			return int(summary.get("wave", 0)) * 6 + int(summary.get("kills", 0)) / 3
		"bossrush":
			return int(summary.get("bosses", 0)) * 60 + (200 if won else 0)
		"challenge":
			if won:
				var ch: Dictionary = ModeRules.CHALLENGES.get(str(summary.get("challenge", "")), {})
				return int(120.0 * float(ch.get("bonus", 1.0)))
		"horde":
			return int(summary.get("wave", 0)) * 8 + int(summary.get("kills", 0)) / 3
		"timeattack":
			if won:
				var tot := ModeRules.time_attack_total(float(summary.get("time", 0.0)), float(summary.get("penalty", 0.0)))
				return 80 + maxi(0, int(210.0 - tot))     # cuanto mas rapido, mas bono
		"expedition":
			return int(summary.get("legs", 0)) * 18 + (220 if won else 0)
	return 0


## Mejores marcas por modo (se guardan en profile.data["records"]).
static func record_mode(profile: PlayerProfile, summary: Dictionary) -> void:
	var rec: Dictionary = profile.data["records"]
	var time := float(summary.get("time", 0.0))
	match str(summary.get("mode", "campaign")):
		"survival":
			var r: Dictionary = rec["survival"]
			var wave := int(summary.get("wave", 0))
			var score := ModeRules.survival_score(int(summary.get("kills", 0)), wave, time)
			r["runs"] = int(r["runs"]) + 1
			r["best_wave"] = maxi(int(r["best_wave"]), wave)
			r["best_score"] = maxi(int(r["best_score"]), score)
			r["best_kills"] = maxi(int(r["best_kills"]), int(summary.get("kills", 0)))
			r["best_time"] = maxf(float(r["best_time"]), time)
		"bossrush":
			var r2: Dictionary = rec["bossrush"]
			r2["runs"] = int(r2["runs"]) + 1
			r2["best_bosses"] = maxi(int(r2["best_bosses"]), int(summary.get("bosses", 0)))
			if summary.get("won", false):
				r2["clears"] = int(r2["clears"]) + 1
				var bt := float(r2["best_time"])
				r2["best_time"] = time if bt <= 0.0 else minf(bt, time)
				var dmg := int(summary.get("damage_taken", 0))
				var ld := int(r2["least_damage"])
				r2["least_damage"] = dmg if ld < 0 else mini(ld, dmg)
		"horde":
			var rh: Dictionary = rec["horde"]
			var wv := int(summary.get("wave", 0))
			rh["runs"] = int(rh["runs"]) + 1
			rh["best_wave"] = maxi(int(rh["best_wave"]), wv)
			rh["best_score"] = maxi(int(rh["best_score"]), ModeRules.horde_score(int(summary.get("kills", 0)), wv, time))
			rh["best_kills"] = maxi(int(rh["best_kills"]), int(summary.get("kills", 0)))
			rh["best_time"] = maxf(float(rh["best_time"]), time)
		"timeattack":
			var chid := str(summary.get("chapter_id", ""))
			var rt: Dictionary = rec["timeattack"].get(chid, {"best_time": 0.0, "clears": 0, "runs": 0})
			rt["runs"] = int(rt["runs"]) + 1
			if summary.get("won", false):
				rt["clears"] = int(rt["clears"]) + 1
				var tot2 := ModeRules.time_attack_total(time, float(summary.get("penalty", 0.0)))
				var bt2 := float(rt["best_time"])
				rt["best_time"] = tot2 if bt2 <= 0.0 else minf(bt2, tot2)
			rec["timeattack"][chid] = rt
		"expedition":
			var ce := str(summary.get("chapter_id", ""))
			var re: Dictionary = rec["expedition"].get(ce, {"best_legs": 0, "clears": 0, "best_time": 0.0, "runs": 0})
			re["runs"] = int(re["runs"]) + 1
			re["best_legs"] = maxi(int(re["best_legs"]), int(summary.get("legs", 0)))
			if summary.get("won", false):
				re["clears"] = int(re["clears"]) + 1
				var bt3 := float(re["best_time"])
				re["best_time"] = time if bt3 <= 0.0 else minf(bt3, time)
			rec["expedition"][ce] = re
		"challenge":
			var cid := str(summary.get("challenge", ""))
			var cs: Dictionary = rec["challenges"].get(cid, {"cleared": 0, "runs": 0, "best_stage": 0})
			cs["runs"] = int(cs["runs"]) + 1
			cs["best_stage"] = maxi(int(cs["best_stage"]), int(summary.get("stages", 0)))
			if summary.get("won", false):
				cs["cleared"] = int(cs["cleared"]) + 1
			rec["challenges"][cid] = cs
