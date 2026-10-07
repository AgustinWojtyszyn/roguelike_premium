class_name SpriteActor
extends Sprite2D
## Un unico Sprite2D que reproduce animaciones direccionales de un AnimSet segun un perfil visual.
## Solo cambia la textura cuando cambia (anim, direccion, frame). Los pies quedan en el origen del nodo.
## Perfil: {set, height, anim_map, fps, offset, loop_anims}. La escala sale de `height` / alto de la caja opaca (o de `scale` explicito en sets pre-renderizados Premium: px de juego por px de celda).

const FALLBACK := {"walk": "idle", "move": "walk", "idle": "walk", "attack": "idle", "hurt": "idle", "death": "idle", "cast": "attack"}

var aset: AnimSet
var prof: Dictionary = {}
var anim := ""
var dir := "south"
var idx := 0
var clock := 0.0
var looping := true
var finished := false
var reverse := false
var rate := 1.0
var _key := ""
var _fps_cache: Dictionary = {}


## Devuelve null si el set no existe o no carga: el llamador debe usar su render procedural.
static func create(parent: Node, profile: Dictionary) -> SpriteActor:
	var s := AssetCatalog.anim_set(profile.get("set", ""))
	if s == null:
		return null
	var a := SpriteActor.new()
	a.aset = s
	a.prof = profile
	a.centered = false
	a.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if profile.get("filter", "linear") == "nearest" else CanvasItem.TEXTURE_FILTER_LINEAR
	a.use_parent_material = true
	var h: float = float(profile.get("height", 56.0))
	var bh := maxf(1.0, float(s.bbox.size.y))
	var sc: float = float(profile["scale"]) if profile.has("scale") else h / bh
	a.scale = Vector2(sc, sc) * float(profile.get("xscale", 1.0))
	var feet_y: float = float(s.bbox.end.y) + float(profile.get("feet_pad", 0.0))
	a.offset = Vector2(-float(s.cell.x) * 0.5, -feet_y)
	a.position = profile.get("offset", Vector2.ZERO)
	parent.add_child(a)
	a.play("idle")
	if a.texture == null:
		a.queue_free()
		return null
	return a


func resolve(logical: String) -> String:
	var m: Dictionary = prof.get("anim_map", {})
	var a: String = m.get(logical, logical)
	var guard := 0
	while not aset.has_anim(a) and guard < 4:
		a = FALLBACK.get(a, "")
		guard += 1
		if a == "":
			break
	return a if aset.has_anim(a) else ""


func has_logical(logical: String) -> bool:
	var m: Dictionary = prof.get("anim_map", {})
	return aset.has_anim(m.get(logical, logical))


func fps_of(real: String) -> float:
	var f: Dictionary = prof.get("fps", {})
	return float(f.get(real, f.get("default", 10.0)))


func play(logical: String, restart: bool = false, loop: bool = true) -> void:
	var real := resolve(logical)
	if real == "":
		return
	if real == anim and not restart:
		looping = loop
		return
	anim = real
	idx = 0
	clock = 0.0
	looping = loop
	finished = false
	_apply()


func set_dir_vec(v: Vector2) -> void:
	var d := aset.best_dir(anim, v)
	if d != "" and d != dir:
		dir = d
		_apply()


func tick(dt: float) -> void:
	var n := aset.frame_count(anim, dir)
	if n <= 1:
		return
	if finished:
		return
	clock += dt * rate * fps_of(anim)
	var step := int(clock)
	if step <= 0:
		return
	clock -= float(step)
	var ni := idx + (-step if reverse else step)
	if looping:
		idx = posmod(ni, n)
	else:
		if ni >= n:
			idx = n - 1
			finished = true
		elif ni < 0:
			idx = 0
			finished = true
		else:
			idx = ni
	_apply()


## 0..1 dentro del ciclo actual.
func phase() -> float:
	var n := aset.frame_count(anim, dir)
	return float(idx) / float(maxi(1, n))


func set_progress(k: float) -> void:
	var n := aset.frame_count(anim, dir)
	idx = clampi(int(k * float(n)), 0, n - 1)
	_apply()


func _apply() -> void:
	var fr := aset.frames(anim, dir)
	if fr.is_empty():
		return
	var i := clampi(idx, 0, fr.size() - 1)
	var t: Texture2D = fr[i]
	if t != texture:
		texture = t
