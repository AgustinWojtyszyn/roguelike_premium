class_name AssetCatalog
extends RefCounted
## Punto unico de acceso al arte importado (assets/migrated). Cachea texturas y AnimSets; nunca carga por frame.
## Todo devuelve null / vacio si falta algo: el que llama cae al dibujo procedural (nada importado puede romper una run).

static var _tex: Dictionary = {}        # path -> Texture2D (o null si fallo)
static var _sets: Dictionary = {}       # set_id -> AnimSet (o null)
static var _warned: Dictionary = {}


static func load_tex(path: String) -> Texture2D:
	if _tex.has(path):
		return _tex[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	if t == null and not _warned.has(path):
		_warned[path] = true
		push_warning("AssetCatalog: no carga %s" % path)
	_tex[path] = t
	return t


## Textura estatica por id del manifest (p. ej. "rpg/props/dungeon2/brazier"). Respeta alias de duplicados.
static func tex(id: String) -> Texture2D:
	var sid: String = AssetManifest.ALIASES.get(id, id)
	if not AssetManifest.STATIC.has(sid):
		return null
	return load_tex(AssetManifest.STATIC[sid]["path"])


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
		if s.first_texture("idle") == null and s.first_texture("walk") == null:
			s = null
	_sets[id] = s
	return s


static func clear_cache() -> void:
	_tex.clear()
	_sets.clear()
