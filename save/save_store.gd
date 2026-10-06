class_name SaveStore
extends RefCounted
## Guardado versionado a JSON. Escritura atomica (tmp + rename), copia de respaldo y migraciones encadenadas.
## Los campos desconocidos se conservan (compatibilidad hacia adelante) y los que falten se rellenan con valores por defecto.

const VERSION := 1
const PATH := "user://profile.json"


## Migraciones: {version_origen: Callable(data) -> data} que llevan de N a N+1.
static func default_migrations() -> Dictionary:
	return {}


static func migrate(data: Dictionary, migrations: Dictionary = {}, target: int = VERSION) -> Dictionary:
	var v := int(data.get("version", 0))
	var guard := 0
	while v < target and guard < 64:
		guard += 1
		if migrations.has(v):
			data = (migrations[v] as Callable).call(data)
		v += 1
		data["version"] = v
	return data


## Rellena en `data` las claves que falten segun `defaults` (recursivo para diccionarios). No pisa nada existente.
static func merge_defaults(data: Dictionary, defaults: Dictionary) -> Dictionary:
	for k in defaults:
		if not data.has(k):
			data[k] = _deep_copy(defaults[k])
		elif defaults[k] is Dictionary and data[k] is Dictionary:
			merge_defaults(data[k], defaults[k])
	return data


static func _deep_copy(v: Variant) -> Variant:
	if v is Dictionary:
		return (v as Dictionary).duplicate(true)
	if v is Array:
		return (v as Array).duplicate(true)
	return v


static func write(path: String, data: Dictionary) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	# respaldo del guardado bueno anterior
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
	return DirAccess.rename_absolute(tmp, path) == OK


## Lee y valida. Devuelve {} si no existe o esta corrupto (intenta el .bak antes).
static func read(path: String) -> Dictionary:
	for p in [path, path + ".bak"]:
		if not FileAccess.file_exists(p):
			continue
		var txt := FileAccess.get_file_as_string(p)
		var j := JSON.new()
		if j.parse(txt) != OK:
			continue
		var parsed: Variant = j.data
		if parsed is Dictionary and (parsed as Dictionary).has("version"):
			return parsed
	return {}
