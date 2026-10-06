extends Node
## Autoload "Catalog": registro central de contenido data-driven. Cada tipo se construye desde un `Content*`
## en codigo y ademas se escanean packs `res://data/packs/*.tres` para sumar contenido sin tocar codigo.

var characters: Dictionary = {}     # id -> CharacterData
var weapons: Dictionary = {}
var enemies: Dictionary = {}
var perks: Dictionary = {}
var missions: Dictionary = {}
var skins: Dictionary = {}
var chapters: Dictionary = {}
var rooms: Dictionary = {}
var encounters: Dictionary = {}
var bosses: Dictionary = {}
var loot: Dictionary = {}
var offers: Dictionary = {}
var season: SeasonData
var char_order: Array[String] = []
var chapter_order: Array[String] = []


func _init() -> void:
	_build()


func _build() -> void:
	for c in ContentCharacters.build():
		characters[c.id] = c
	var cl: Array = characters.values()
	cl.sort_custom(func(a, b): return a.order < b.order)
	for c in cl:
		char_order.append(c.id)
	for s in ContentCharacters.build_skins():
		skins[s.id] = s
	for w in ContentWeapons.build():
		weapons[w.id] = w
	for p in ContentPerks.build():
		perks[p.id] = p
	for m in ContentMeta.missions():
		missions[m.id] = m
	for o in ContentMeta.shop_offers():
		offers[o.id] = o
	season = ContentMeta.season()
	for e in ContentEnemies.build():
		enemies[e.id] = e
	for ch in ContentDungeons.chapters():
		chapters[ch.id] = ch
	var chl: Array = chapters.values()
	chl.sort_custom(func(a, b): return a.order < b.order)
	for ch in chl:
		chapter_order.append(ch.id)
	for r in ContentDungeons.rooms():
		rooms[r.id] = r
	for en in ContentDungeons.encounters():
		encounters[en.id] = en
	for b in ContentDungeons.bosses():
		bosses[b.id] = b
	for lt in ContentDungeons.loot_tables():
		loot[lt.id] = lt
	_scan_packs("res://data/packs")


## Packs de contenido extra: cualquier .tres de un tipo conocido se registra automaticamente.
func _scan_packs(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for f in dir.get_files():
		var fn := f.trim_suffix(".remap")
		if not fn.ends_with(".tres"):
			continue
		var res := load(dir_path + "/" + fn)
		if res is WeaponData:
			weapons[res.id] = res
		elif res is PerkData:
			perks[res.id] = res
		elif res is CharacterData:
			characters[res.id] = res
			if not (res.id in char_order):
				char_order.append(res.id)
		elif res is MissionData:
			missions[res.id] = res
		elif res is SkinData:
			skins[res.id] = res
		elif res is EnemyData:
			enemies[res.id] = res
		elif res is RoomDef:
			rooms[res.id] = res
		elif res is EncounterDef:
			encounters[res.id] = res


func character(id: String) -> CharacterData:
	return characters.get(id, characters["vesper"])


func weapon(id: String) -> WeaponData:
	return weapons.get(id, weapons["pulsar"])


func chapter(id: String) -> ChapterData:
	return chapters.get(id, null)


func perk(id: String) -> PerkData:
	return perks.get(id, null)


func weapons_by_rarity(tier: int) -> Array:
	var out: Array = []
	for w in weapons.values():
		if w.rarity == tier:
			out.append(w)
	return out


## Validacion de integridad referencial: devuelve lista de problemas (vacia = todo bien).
func validate() -> Array[String]:
	var errs: Array[String] = []
	for c in characters.values():
		if not weapons.has(c.start_weapon):
			errs.append("personaje %s: arma inicial inexistente %s" % [c.id, c.start_weapon])
		if c.side_weapon != "" and not weapons.has(c.side_weapon):
			errs.append("personaje %s: arma secundaria inexistente %s" % [c.id, c.side_weapon])
		if c.recommended_weapon != "" and not weapons.has(c.recommended_weapon):
			errs.append("personaje %s: arma recomendada inexistente %s" % [c.id, c.recommended_weapon])
	for s in skins.values():
		if not characters.has(s.character):
			errs.append("skin %s: personaje inexistente %s" % [s.id, s.character])
	for ch in chapters.values():
		for r in ch.room_pool + ch.cache_rooms + [ch.boss_room]:
			if r != "" and not rooms.has(r):
				errs.append("capitulo %s: sala inexistente %s" % [ch.id, r])
		for e in ch.enemy_pool + ch.elite_pool:
			if not enemies.has(e):
				errs.append("capitulo %s: enemigo inexistente %s" % [ch.id, e])
		if ch.boss != "" and not bosses.has(ch.boss):
			errs.append("capitulo %s: jefe inexistente %s" % [ch.id, ch.boss])
		if not loot.has(ch.loot_table):
			errs.append("capitulo %s: tabla de loot inexistente %s" % [ch.id, ch.loot_table])
	for en in encounters.values():
		for w in en.waves:
			for e in w:
				if not enemies.has(e[0]):
					errs.append("encuentro %s: enemigo inexistente %s" % [en.id, e[0]])
	for r in rooms.values():
		if r.spawns.is_empty() and r.kind != "cache":
			errs.append("sala %s: sin puntos de aparicion" % r.id)
	for rw in season.free_rewards + season.premium_rewards:
		if rw["type"] == "skin" and not skins.has(rw["id"]):
			errs.append("pase: skin inexistente %s" % rw["id"])
		if rw["type"] == "character" and not characters.has(rw["id"]):
			errs.append("pase: personaje inexistente %s" % rw["id"])
	return errs
