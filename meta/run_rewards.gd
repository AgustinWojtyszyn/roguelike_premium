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
	if chapter != null:
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
