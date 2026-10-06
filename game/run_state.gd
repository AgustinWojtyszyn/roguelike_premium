class_name RunState
extends RefCounted
## Estado de UNA run: personaje, capitulo, perks activos (con slots), armas equipadas y contadores
## que luego se convierten en recompensas persistentes (RunRewards). Sin nodos => testeable.

const PERK_SLOTS := 5
const WEAPON_SLOTS := 2

var character: CharacterData
var chapter: ChapterData
var seed_v: int = 0
var perks: Array[String] = []
var weapons: Array[String] = []
var stage_idx: int = 0
var time: float = 0.0
# contadores
var coins: int = 0
var kills: int = 0
var kills_cat: Dictionary = {}
var chests: int = 0
var rooms: int = 0
var perks_picked: int = 0
var bosses: int = 0
var nodamage_rooms: int = 0
var weapons_seen: Array[String] = []
var damaged_in_room := false
var shots_fired: int = 0
var won := false
# estadisticas agregadas de perks
var mods: Dictionary = {}
var hooks: Dictionary = {}


static func create(c: CharacterData, ch: ChapterData, sd: int) -> RunState:
	var r := RunState.new()
	r.character = c
	r.chapter = ch
	r.seed_v = sd
	r.weapons = [c.start_weapon]
	if c.side_weapon != "" and c.side_weapon != c.start_weapon:
		r.weapons.append(c.side_weapon)
	for w in r.weapons:
		r.weapons_seen.append(w)
	return r


func recompute(catalog_perks: Dictionary) -> void:
	mods.clear()
	hooks.clear()
	for id in perks:
		var p: PerkData = catalog_perks.get(id)
		if p == null:
			continue
		for k in p.mods:
			mods[k] = float(mods.get(k, 0.0)) + float(p.mods[k])
		for h in p.hooks:
			hooks[h] = int(hooks.get(h, 0)) + 1


func mod(key: String, default: float = 0.0) -> float:
	return float(mods.get(key, default))


func has_hook(h: String) -> bool:
	return hooks.has(h)


func perk_count(id: String) -> int:
	return perks.count(id)


func perk_slots_free() -> int:
	return PERK_SLOTS - perks.size()


## Añade un perk. Devuelve false si no hay slot (el llamador debe pedir reemplazo) o ya lo tiene y no es apilable.
func add_perk(p: PerkData, catalog_perks: Dictionary) -> bool:
	if perks.has(p.id) and not p.stackable:
		return false
	if perks.size() >= PERK_SLOTS and not (perks.has(p.id) and p.stackable):
		return false
	perks.append(p.id)
	perks_picked += 1
	recompute(catalog_perks)
	return true


func replace_perk(index: int, p: PerkData, catalog_perks: Dictionary) -> void:
	if index >= 0 and index < perks.size():
		perks[index] = p.id
		perks_picked += 1
		recompute(catalog_perks)


func note_weapon(id: String) -> void:
	if not (id in weapons_seen):
		weapons_seen.append(id)


func note_kill(cat: String) -> void:
	kills += 1
	if cat != "":
		kills_cat[cat] = int(kills_cat.get(cat, 0)) + 1


func summary(stages_cleared: int) -> Dictionary:
	return {
		"character": character.id, "chapter": chapter.id if chapter != null else "", "won": won,
		"stages": stages_cleared, "rooms": rooms, "kills": kills, "kills_cat": kills_cat,
		"chests": chests, "perks": perks_picked, "bosses": bosses, "nodamage_rooms": nodamage_rooms,
		"coins": coins, "time": time, "weapons_seen": weapons_seen,
	}


## Elige `n` perks distintos para ofrecer, ponderados por rareza y evitando los no apilables ya tomados.
static func roll_perk_offer(rng: RandomNumberGenerator, catalog_perks: Dictionary, owned: Array[String], n: int = 3, luck: float = 0.0) -> Array[PerkData]:
	var pool: Array[PerkData] = []
	for p in catalog_perks.values():
		if owned.has(p.id) and not p.stackable:
			continue
		pool.append(p)
	pool.sort_custom(func(a, b): return a.id < b.id)
	var out: Array[PerkData] = []
	while out.size() < n and not pool.is_empty():
		var total := 0.0
		var ws: Array[float] = []
		for p in pool:
			var w: float = Rarity.WEIGHTS[p.rarity] * p.weight * (1.0 + luck * float(p.rarity))
			ws.append(w)
			total += w
		var r := rng.randf() * total
		var pick := 0
		for i in pool.size():
			r -= ws[i]
			if r <= 0.0:
				pick = i
				break
		out.append(pool[pick])
		pool.remove_at(pick)
	return out
