class_name PlayerProfile
extends RefCounted
## Estado persistente del jugador. Es un contenedor de datos puro (sin nodos) para poder probarlo sin escena.
## `data` es un diccionario JSON-serializable; los sistemas (Economy, MissionSystem, PassSystem, ShopSystem)
## operan sobre este objeto.

signal changed

var data: Dictionary = {}
var dirty := false


func _init(d: Dictionary = {}) -> void:
	data = SaveStore.merge_defaults(d, default_data())


static func default_data() -> Dictionary:
	return {
		"version": SaveStore.VERSION,
		"created": 0,
		"coins": 300,
		"gems": 20,
		"xp_total": 0,
		"selected_character": "vesper",
		"characters": {"vesper": {"unlocked": true, "xp": 0, "runs": 0, "wins": 0, "skin": ""}},
		"skins_owned": [],
		"cosmetics_owned": [],
		"equipped": {"trail": "", "frame": ""},
		"weapons_seen": {"pulsar": true, "chispa": true},
		"chapters": {"ch1": {"unlocked": true, "cleared": 0, "best_stage": 0}},
		"selected_chapter": "ch1",
		"stats": {"kills": 0, "runs": 0, "wins": 0, "deaths": 0, "chests": 0, "rooms": 0, "bosses": 0, "perks": 0, "playtime": 0.0, "coins_earned": 0},
		"missions": {
			"daily": {"key": "", "items": []},
			"weekly": {"key": "", "items": []},
			"season": {"key": "", "items": []},
		},
		"pass": {"season_id": "s1", "xp": 0, "premium": false, "claimed_free": [], "claimed_premium": []},
		"shop": {"daily_gift": "", "bought": {}, "rotation_key": ""},
		"perm_perks": {},
		"settings": {"music": true, "sfx": true, "music_vol": 0.8, "sfx_vol": 1.0, "vibration": true, "show_fps": false, "quality": "auto", "aim_assist": true},
		"flags": {"seen_news": 0},
	}


func touch() -> void:
	dirty = true
	changed.emit()


# ---- monedas -----------------------------------------------------------------
func coins() -> int:
	return int(data["coins"])


func gems() -> int:
	return int(data["gems"])


func add_coins(n: int) -> void:
	data["coins"] = maxi(0, coins() + n)
	if n > 0:
		data["stats"]["coins_earned"] = int(data["stats"].get("coins_earned", 0)) + n
	touch()


func add_gems(n: int) -> void:
	data["gems"] = maxi(0, gems() + n)
	touch()


func can_afford(cost: Dictionary) -> bool:
	return coins() >= int(cost.get("coins", 0)) and gems() >= int(cost.get("gems", 0))


func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	add_coins(-int(cost.get("coins", 0)))
	add_gems(-int(cost.get("gems", 0)))
	return true


# ---- personajes ---------------------------------------------------------------
func is_unlocked(cid: String) -> bool:
	return bool(data["characters"].get(cid, {}).get("unlocked", false))


func unlock_character(cid: String) -> bool:
	if is_unlocked(cid):
		return false
	var st: Dictionary = data["characters"].get(cid, {"xp": 0, "runs": 0, "wins": 0, "skin": ""})
	st["unlocked"] = true
	data["characters"][cid] = st
	touch()
	return true


func char_state(cid: String) -> Dictionary:
	return data["characters"].get(cid, {"unlocked": false, "xp": 0, "runs": 0, "wins": 0, "skin": ""})


func select_character(cid: String) -> bool:
	if not is_unlocked(cid):
		return false
	data["selected_character"] = cid
	touch()
	return true


func selected_character() -> String:
	var c: String = data["selected_character"]
	return c if is_unlocked(c) else "vesper"


func owns_skin(sid: String) -> bool:
	return sid in data["skins_owned"]


func grant_skin(sid: String) -> void:
	if not owns_skin(sid):
		data["skins_owned"].append(sid)
		touch()


func equip_skin(cid: String, sid: String) -> bool:
	if sid != "" and not owns_skin(sid):
		return false
	var st := char_state(cid)
	st["skin"] = sid
	data["characters"][cid] = st
	touch()
	return true


func skin_of(cid: String) -> String:
	return str(char_state(cid).get("skin", ""))


func grant_cosmetic(cid: String) -> void:
	if not (cid in data["cosmetics_owned"]):
		data["cosmetics_owned"].append(cid)
		touch()


# ---- nivel de cuenta -----------------------------------------------------------
static func xp_for_account_level(lv: int) -> int:
	return 120 + 40 * (lv - 1)


## Devuelve {"level": n, "into": xp_en_el_nivel, "need": xp_para_siguiente}
func account_level() -> Dictionary:
	var xp := int(data["xp_total"])
	var lv := 1
	while xp >= xp_for_account_level(lv):
		xp -= xp_for_account_level(lv)
		lv += 1
	return {"level": lv, "into": xp, "need": xp_for_account_level(lv)}


# ---- capitulos -----------------------------------------------------------------
func chapter_state(chid: String) -> Dictionary:
	return data["chapters"].get(chid, {"unlocked": false, "cleared": 0, "best_stage": 0})


func unlock_chapter(chid: String) -> void:
	var st := chapter_state(chid)
	if not st.get("unlocked", false):
		st["unlocked"] = true
		data["chapters"][chid] = st
		touch()


# ---- ajustes ---------------------------------------------------------------------
func setting(key: String) -> Variant:
	return data["settings"].get(key)


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	touch()
