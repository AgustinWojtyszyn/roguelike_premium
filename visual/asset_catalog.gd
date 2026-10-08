class_name AssetCatalog
extends RefCounted
## Punto unico de acceso al arte importado (assets/migrated). Cachea texturas y AnimSets; nunca carga por frame.
## Todo devuelve null / vacio si falta algo: el que llama cae al dibujo procedural (nada importado puede romper una run).

static var _tex: Dictionary = {}        # path -> Texture2D (o null si fallo)
static var _sets: Dictionary = {}       # set_id -> AnimSet (o null)
static var _warned: Dictionary = {}
static var _log_loads := false   # se activa tras el prewarm con --frametimes: cualquier carga a mitad de run queda a la vista


static func load_tex(path: String) -> Texture2D:
	if _tex.has(path):
		return _tex[path]
	var t: Texture2D = null
	var t0 := Time.get_ticks_usec()
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	if _log_loads:
		print("  [carga] %.1f ms  %s" % [float(Time.get_ticks_usec() - t0) / 1000.0, path])
	if t == null and not _warned.has(path):
		_warned[path] = true
		push_warning("AssetCatalog: no carga %s" % path)
	_tex[path] = t
	return t


## Textura estatica por id del manifest (p. ej. "rpg/props/dungeon2/brazier"). Respeta alias de duplicados.
static func tex(id: String) -> Texture2D:
	var sid: String = AssetManifest.ALIASES.get(id, id)
	if not AssetManifest.STATIC.has(sid):
		if PremiumManifest.STATIC.has(id):
			return load_tex(PremiumManifest.STATIC[id]["path"])
		return null
	return load_tex(AssetManifest.STATIC[sid]["path"])


## Ficha de un estatico (migrado o Premium): {path, size, bbox, ...; Premium ademas anchor/scale}. Vacia si no existe.
static func info(id: String) -> Dictionary:
	var sid: String = AssetManifest.ALIASES.get(id, id)
	if AssetManifest.STATIC.has(sid):
		return AssetManifest.STATIC[sid]
	return PremiumManifest.STATIC.get(id, {})


static func has_tex(id: String) -> bool:
	return tex(id) != null


## Tamano en pixeles de una textura estatica (sin cargarla).
static func tex_size(id: String) -> Vector2:
	var sid: String = AssetManifest.ALIASES.get(id, id)
	if not AssetManifest.STATIC.has(sid):
		return Vector2.ZERO
	var s: Array = AssetManifest.STATIC[sid]["size"]
	return Vector2(float(s[0]), float(s[1]))


static func anim_set(id: String) -> AnimSet:
	if _sets.has(id):
		return _sets[id]
	var s: AnimSet = null
	if AssetManifest.ANIMS.has(id):
		s = AnimSet.create(id, AssetManifest.ANIMS[id])
	elif PremiumManifest.SETS.has(id):
		s = AnimSet.create(id, PremiumManifest.SETS[id])
	if s != null:
		if s.first_texture("idle") == null and s.first_texture("walk") == null:
			s = null
	_sets[id] = s
	return s


static func clear_cache() -> void:
	_tex.clear()
	_sets.clear()


## Precarga (al empezar la run): sube a GPU y construye los AtlasTexture ANTES del primer frame jugable, para que ningun
## enemigo, efecto o arma cause un ttiron de carga a mitad de partida. Solo toca lo que esta run puede usar.
## Carga (y compila) los scripts de enemigos y jefe del capitulo ahora, no en el primer spawn en pleno combate.
static func _preload_scripts(chapter: ChapterData) -> void:
	var ids: Array = []
	ids.append_array(chapter.enemy_pool)
	ids.append_array(chapter.elite_pool)
	for id in ids:
		if Catalog.enemies.has(id):
			load((Catalog.enemies[id] as EnemyData).script_path)
	if Catalog.bosses.has(chapter.boss):
		load((Catalog.bosses[chapter.boss] as BossData).script_path)


static func prewarm(chapter: ChapterData, char_look: Dictionary, weapon_ids: Array) -> void:
	if not VisualProfiles.sprites_enabled():
		return
	var t0 := Time.get_ticks_usec()
	_preload_scripts(chapter)
	var set_ids: Array = []
	var vid := VisualProfiles.character(str(char_look.get("visual", "")))
	if not vid.is_empty():
		set_ids.append(vid["set"])
	var kinds: Array = []
	kinds.append_array(chapter.enemy_pool)
	kinds.append_array(chapter.elite_pool)
	kinds.append(chapter.boss)
	# invocaciones y refuerzos que pueden aparecer en cualquier capitulo
	for k in kinds:
		var pr := VisualProfiles.enemy(str(k))
		if not pr.is_empty():
			set_ids.append(pr["set"])
	var done := {}
	for sid in set_ids:
		if done.has(sid):
			continue
		done[sid] = true
		var s := anim_set(sid)
		if s != null:
			for a in s.anim_names():
				s.frames(a, "south")   # construye y carga la hoja de esa animacion
	for v in Fx.USED_VFX:
		tex("rpg/vfx/" + v)
	for wid in weapon_ids:
		if AssetManifest.ORIENTED.has(wid):
			load_tex(AssetManifest.ORIENTED[wid]["path"])
	for k in Chest.ART.values():
		tex("rpg/chests/" + k)
		tex("rpg/chests/" + k + "_open")
	if chapter.theme == "anomaly":
		for k in Chest.ART_ANOMALY.values():
			tex("rpg/chests/" + k)
			tex("rpg/chests/" + k + "_open")
	for kind in VisualProfiles.PROPS_THEMED.get(chapter.theme, {}):
		for art in VisualProfiles.PROPS_THEMED[chapter.theme][kind]["art"]:
			tex(art)
	if chapter.theme == "castle":
		for art in ThemeCastle.PREMIUM_ART:
			tex(art)
	var dec := VisualProfiles.decor(chapter.theme)
	for grp in ["floor", "stand"]:
		for spec in dec.get(grp, []):
			tex(spec["art"])
	for kind in VisualProfiles.PROPS:
		for art in VisualProfiles.PROPS[kind]["art"]:
			tex(art)
	_log_loads = Boot.has_flag("frametimes")
	if Boot.has_flag("perf") or Boot.has_flag("frametimes"):
		print("PREWARM %.1f ms (%d texturas, %d sets)" % [float(Time.get_ticks_usec() - t0) / 1000.0, _tex.size(), done.size()])
