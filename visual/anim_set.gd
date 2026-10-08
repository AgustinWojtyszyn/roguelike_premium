class_name AnimSet
extends RefCounted
## Conjunto de animaciones direccionales de un personaje importado (hojas: filas = direcciones, columnas = frames).
## Las texturas se construyen (AtlasTexture) una sola vez por animacion y se reutilizan: nada se carga por frame.

const DIR_VEC := {
	"south": Vector2(0, 1), "south-east": Vector2(0.7071, 0.7071), "east": Vector2(1, 0), "north-east": Vector2(0.7071, -0.7071),
	"north": Vector2(0, -1), "north-west": Vector2(-0.7071, -0.7071), "west": Vector2(-1, 0), "south-west": Vector2(-0.7071, 0.7071),
}

var id := ""
var cell := Vector2i(96, 96)
var bbox := Rect2i()
var _meta: Dictionary = {}
var _built: Dictionary = {}     # anim -> {dirs: Array, rows: {dir: Array[Texture2D]}}
var _grips: Dictionary = {}     # anim -> dir -> [[gx, gy, ang, lgx, lgy, behind], ...] (generado desde el hueso handslot del rig fuente)
var _hand_built: Dictionary = {}
var weapon_axis := ""


static func create(set_id: String, meta: Dictionary) -> AnimSet:
	var s := AnimSet.new()
	s.id = set_id
	s._meta = meta["anims"]
	var b: Array = meta["bbox"]
	s.bbox = Rect2i(int(b[0]), int(b[1]), int(b[2]) - int(b[0]), int(b[3]) - int(b[1]))
	s._grips = meta.get("grips", {})
	s.weapon_axis = str(meta.get("weapon_axis", ""))
	for a in s._meta:
		var c: Array = s._meta[a]["cell"]
		s.cell = Vector2i(int(c[0]), int(c[1]))
		break
	return s


func has_anim(anim: String) -> bool:
	return _meta.has(anim)


func anim_names() -> Array:
	return _meta.keys()


func dirs_of(anim: String) -> Array:
	if not _meta.has(anim):
		return []
	return _meta[anim]["dirs"]


func _build(anim: String) -> Dictionary:
	if _built.has(anim):
		return _built[anim]
	var out := {"dirs": [], "rows": {}}
	if not _meta.has(anim):
		_built[anim] = out
		return out
	var m: Dictionary = _meta[anim]
	var tex: Texture2D = AssetCatalog.load_tex(m["sheet"])
	if tex == null:
		_built[anim] = out
		return out
	var c: Array = m["cell"]
	var cw := int(c[0])
	var ch := int(c[1])
	var dirs: Array = m["dirs"]
	var counts: Array = m["counts"]
	for r in dirs.size():
		var frames: Array[Texture2D] = []
		for i in int(counts[r]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * cw, r * ch, cw, ch)
			frames.append(at)
		out["rows"][dirs[r]] = frames
	out["dirs"] = dirs
	_built[anim] = out
	return out


func has_grips() -> bool:
	return not _grips.is_empty()


## Agarre del frame (px de celda relativos a los pies): [gx, gy, ang_deg, lgx, lgy, behind]. Vacio si el set no lo define.
func grip(anim: String, dir: String, idx: int) -> Array:
	var per: Dictionary = _grips.get(anim, {})
	var row: Array = per.get(dir, [])
	if row.is_empty():
		return []
	return row[clampi(idx, 0, row.size() - 1)]


func weapon_mode(anim: String) -> String:
	return str(_meta.get(anim, {}).get("weapon_mode", "aim"))


## Parches de la mano que sostiene el arma (se dibujan ENCIMA del arma para que los dedos la envuelvan).
func hand_frames(anim: String, dir: String) -> Array:
	if not _meta.has(anim) or not _meta[anim].has("hand"):
		return []
	if not _hand_built.has(anim):
		var m: Dictionary = _meta[anim]["hand"]
		var tex: Texture2D = AssetCatalog.load_tex(m["sheet"])
		var rows := {}
		if tex != null:
			var c: Array = m["cell"]
			var cw := int(c[0])
			var ch := int(c[1])
			var dirs: Array = _meta[anim]["dirs"]
			var counts: Array = _meta[anim]["counts"]
			for r in dirs.size():
				var fr: Array[Texture2D] = []
				for i in int(counts[r]):
					var at := AtlasTexture.new()
					at.atlas = tex
					at.region = Rect2(i * cw, r * ch, cw, ch)
					fr.append(at)
				rows[dirs[r]] = fr
		_hand_built[anim] = rows
	var rows2: Dictionary = _hand_built[anim]
	return rows2.get(dir, [])


## Direccion disponible mas cercana al vector (con ligero sesgo horizontal para resolver diagonales).
func best_dir(anim: String, v: Vector2) -> String:
	var dirs: Array = dirs_of(anim)
	if dirs.is_empty():
		return ""
	if dirs.size() == 1:
		return dirs[0]
	if v.length_squared() < 0.0001:
		v = Vector2(0, 1)
	var vn := Vector2(v.x * 1.12, v.y).normalized()
	var best: String = dirs[0]
	var bd := -2.0
	for d in dirs:
		var dv: Vector2 = DIR_VEC[d]
		var dot := vn.dot(dv)
		if dot > bd + 0.0001:
			bd = dot
			best = d
	return best


func frames(anim: String, dir: String) -> Array:
	var b := _build(anim)
	var rows: Dictionary = b["rows"]
	if rows.has(dir):
		return rows[dir]
	if not (b["dirs"] as Array).is_empty():
		return rows[(b["dirs"] as Array)[0]]
	return []


func frame_count(anim: String, dir: String = "") -> int:
	return frames(anim, dir if dir != "" else "south").size()


func first_texture(anim: String = "idle") -> Texture2D:
	var a: String = anim if has_anim(anim) else (str(anim_names()[0]) if not anim_names().is_empty() else "")
	if a == "":
		return null
	var d := best_dir(a, Vector2(0, 1))
	var f := frames(a, d)
	return f[0] if not f.is_empty() else null


## Comprobacion estructural (tests): todas las hojas existen y las regiones caben.
func validate() -> Array:
	var errs: Array = []
	for a in _meta:
		var m: Dictionary = _meta[a]
		var tex: Texture2D = AssetCatalog.load_tex(m["sheet"])
		if tex == null:
			errs.append("%s/%s: hoja no carga (%s)" % [id, a, m["sheet"]])
			continue
		var c: Array = m["cell"]
		var counts: Array = m["counts"]
		var need_w := 0
		for n in counts:
			need_w = maxi(need_w, int(n) * int(c[0]))
		if need_w > tex.get_width() or (m["dirs"] as Array).size() * int(c[1]) > tex.get_height():
			errs.append("%s/%s: la hoja es mas chica que su rejilla" % [id, a])
		if (m["dirs"] as Array).size() != counts.size():
			errs.append("%s/%s: dirs y counts no coinciden" % [id, a])
	return errs
