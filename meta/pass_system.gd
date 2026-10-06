class_name PassSystem
extends RefCounted
## Pase de temporada local. Dos carriles (gratis / premium simulado). XP compartida con la cuenta.

static func level_info(profile: PlayerProfile, season: SeasonData) -> Dictionary:
	var xp := int(profile.data["pass"]["xp"])
	var lv := 0
	var left := xp
	while lv < season.levels and left >= season.xp_for_level(lv + 1):
		left -= season.xp_for_level(lv + 1)
		lv += 1
	var need := season.xp_for_level(lv + 1) if lv < season.levels else 1
	return {"level": lv, "into": left if lv < season.levels else need, "need": need, "max": lv >= season.levels}


static func reward_at(season: SeasonData, lane: String, level: int) -> Dictionary:
	var arr: Array = season.free_rewards if lane == "free" else season.premium_rewards
	for r in arr:
		if int(r["level"]) == level:
			return r
	return {}


static func is_claimed(profile: PlayerProfile, lane: String, level: int) -> bool:
	return level in profile.data["pass"]["claimed_" + lane]


static func can_claim(profile: PlayerProfile, season: SeasonData, lane: String, level: int) -> bool:
	if is_claimed(profile, lane, level):
		return false
	if level < 1 or level > int(level_info(profile, season)["level"]):
		return false
	if lane == "premium" and not bool(profile.data["pass"]["premium"]):
		return false
	return not reward_at(season, lane, level).is_empty()


## Aplica la recompensa al perfil. Devuelve la recompensa o {}.
static func claim(profile: PlayerProfile, season: SeasonData, lane: String, level: int) -> Dictionary:
	if not can_claim(profile, season, lane, level):
		return {}
	var r := reward_at(season, lane, level)
	apply_reward(profile, r)
	profile.data["pass"]["claimed_" + lane].append(level)
	profile.touch()
	return r


static func apply_reward(profile: PlayerProfile, r: Dictionary) -> void:
	match r["type"]:
		"coins":
			profile.add_coins(int(r["amount"]))
		"gems":
			profile.add_gems(int(r["amount"]))
		"skin":
			profile.grant_skin(str(r["id"]))
		"character":
			profile.unlock_character(str(r["id"]))
		"trail", "frame":
			profile.grant_cosmetic(str(r["id"]))


static func claim_all(profile: PlayerProfile, season: SeasonData) -> int:
	var n := 0
	var lv := int(level_info(profile, season)["level"])
	for l in range(1, lv + 1):
		for lane in ["free", "premium"]:
			if not claim(profile, season, lane, l).is_empty():
				n += 1
	return n


static func claimable_count(profile: PlayerProfile, season: SeasonData) -> int:
	var n := 0
	var lv := int(level_info(profile, season)["level"])
	for l in range(1, lv + 1):
		for lane in ["free", "premium"]:
			if can_claim(profile, season, lane, l):
				n += 1
	return n


## Compra SIMULADA del carril premium (no hay billing). Los niveles ya alcanzados quedan reclamables.
static func unlock_premium_mock(profile: PlayerProfile) -> bool:
	if not Pricing.MOCK_PURCHASES or bool(profile.data["pass"]["premium"]):
		return false
	profile.data["pass"]["premium"] = true
	profile.touch()
	return true


static func reward_label(r: Dictionary) -> String:
	match r.get("type", ""):
		"coins":
			return "%d MONEDAS" % int(r["amount"])
		"gems":
			return "%d GEMAS" % int(r["amount"])
		"skin":
			return "SKIN"
		"character":
			return "PERSONAJE"
		"trail":
			return "ESTELA"
		"frame":
			return "MARCO"
	return ""
