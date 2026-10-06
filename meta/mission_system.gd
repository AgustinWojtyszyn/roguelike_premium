class_name MissionSystem
extends RefCounted
## Misiones diarias / semanales / de temporada. Estado en profile.data["missions"]; definiciones en Catalog.
## Las misiones se eligen de forma determinista a partir de la fecha (misma fecha = mismas misiones).

const COUNTS := {"daily": 3, "weekly": 3, "season": 6}


static func today_key() -> String:
	return Time.get_date_string_from_system()


static func week_key(date: String) -> String:
	var unix := Time.get_unix_time_from_datetime_string(date + "T00:00:00")
	return "w%d" % int(floor(float(unix) / 86400.0 / 7.0))


static func key_for(scope: String, date: String, season_id: String) -> String:
	match scope:
		"daily":
			return date
		"weekly":
			return week_key(date)
	return season_id


## Reasigna misiones cuyo periodo cambio. Devuelve true si algo cambio.
static func refresh(profile: PlayerProfile, catalog_missions: Dictionary, date: String, season_id: String) -> bool:
	var changed := false
	for scope in COUNTS:
		var slot: Dictionary = profile.data["missions"][scope]
		var key := key_for(scope, date, season_id)
		if slot.get("key", "") == key and not (slot.get("items", []) as Array).is_empty():
			continue
		slot["key"] = key
		slot["items"] = _roll(scope, key, catalog_missions)
		changed = true
	if changed:
		profile.touch()
	return changed


static func _roll(scope: String, key: String, catalog_missions: Dictionary) -> Array:
	var pool: Array = []
	for m in catalog_missions.values():
		if m.scope == scope:
			pool.append(m.id)
	pool.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(scope + key)
	# mezcla determinista
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var items: Array = []
	for i in mini(int(COUNTS[scope]), pool.size()):
		items.append({"id": pool[i], "progress": 0, "claimed": false})
	return items


static func items(profile: PlayerProfile, scope: String) -> Array:
	return profile.data["missions"][scope]["items"]


## Registra progreso de una metrica. `metric` ej. "kills", "kills_cat:smg", "wins_char:vesper".
static func record(profile: PlayerProfile, catalog_missions: Dictionary, metric: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	var touched := false
	for scope in COUNTS:
		for it in items(profile, scope):
			var def: MissionData = catalog_missions.get(it["id"])
			if def == null or def.metric != metric or it["claimed"]:
				continue
			it["progress"] = mini(def.target, int(it["progress"]) + amount)
			touched = true
	if touched:
		profile.touch()


static func is_complete(it: Dictionary, def: MissionData) -> bool:
	return int(it["progress"]) >= def.target


## Reclama la recompensa. Devuelve {} si no se pudo, o el dict de recompensas.
static func claim(profile: PlayerProfile, catalog_missions: Dictionary, scope: String, index: int) -> Dictionary:
	var lst := items(profile, scope)
	if index < 0 or index >= lst.size():
		return {}
	var it: Dictionary = lst[index]
	var def: MissionData = catalog_missions.get(it["id"])
	if def == null or it["claimed"] or not is_complete(it, def):
		return {}
	it["claimed"] = true
	profile.add_coins(def.reward_coins)
	profile.add_gems(def.reward_gems)
	profile.data["xp_total"] = int(profile.data["xp_total"]) + def.reward_xp
	profile.data["pass"]["xp"] = int(profile.data["pass"]["xp"]) + def.reward_xp
	profile.touch()
	return {"coins": def.reward_coins, "gems": def.reward_gems, "xp": def.reward_xp}


static func claimable_count(profile: PlayerProfile, catalog_missions: Dictionary) -> int:
	var n := 0
	for scope in COUNTS:
		for it in items(profile, scope):
			var def: MissionData = catalog_missions.get(it["id"])
			if def != null and not it["claimed"] and is_complete(it, def):
				n += 1
	return n
