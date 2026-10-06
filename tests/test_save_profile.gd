extends RefCounted
## Guardado versionado, migraciones, economia, progresion.

func run(t) -> void:
	var path := "user://test_profile.json"
	# --- ida y vuelta
	var p := PlayerProfile.new()
	p.add_coins(500)
	p.unlock_character("kiro9")
	p.select_character("kiro9")
	p.data["xp_total"] = 777
	t.check(SaveStore.write(path, p.data), "write ok")
	var raw := SaveStore.read(path)
	t.check(not raw.is_empty(), "read ok")
	var q := PlayerProfile.new(raw)
	t.eq(q.coins(), 800, "monedas persisten (300 iniciales + 500)")
	t.check(q.is_unlocked("kiro9"), "personaje desbloqueado persiste")
	t.eq(q.selected_character(), "kiro9", "personaje elegido persiste")
	t.eq(int(q.data["xp_total"]), 777, "xp persiste")

	# --- campos nuevos: un guardado viejo sin claves nuevas no se corrompe
	var old := {"version": 1, "coins": 42, "characters": {"vesper": {"unlocked": true}}, "campo_desconocido": {"x": 1}}
	var r := PlayerProfile.new(old)
	t.eq(r.coins(), 42, "conserva valor existente")
	t.check(r.data.has("pass") and r.data.has("missions") and r.data.has("settings"), "rellena claves nuevas con defaults")
	t.check(r.data.has("campo_desconocido"), "conserva claves desconocidas")
	t.check(r.char_state("vesper").has("unlocked"), "estructura anidada conservada")

	# --- migraciones encadenadas
	var mig := {
		0: func(d: Dictionary) -> Dictionary:
			d["coins"] = int(d.get("gold", 0))
			d.erase("gold")
			return d,
		1: func(d: Dictionary) -> Dictionary:
			d["renamed"] = true
			return d,
	}
	var m := SaveStore.migrate({"version": 0, "gold": 99}, mig, 2)
	t.eq(int(m["version"]), 2, "migra hasta version objetivo")
	t.eq(int(m["coins"]), 99, "migracion 0->1 aplicada")
	t.check(m.get("renamed", false), "migracion 1->2 aplicada")
	var same := SaveStore.migrate({"version": 2, "coins": 5}, mig, 2)
	t.eq(int(same["coins"]), 5, "no migra si ya esta en version")

	# --- corrupcion: cae al respaldo
	SaveStore.write(path, p.data)
	SaveStore.write(path, p.data)   # el segundo write genera .bak
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{esto no es json")
	f.close()
	var rec := SaveStore.read(path)
	t.check(not rec.is_empty(), "recupera desde .bak si el principal esta corrupto")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path + ".bak")
	t.check(SaveStore.read(path).is_empty(), "sin archivos devuelve vacio")

	# --- economia
	var e := PlayerProfile.new()
	t.check(not e.spend({"coins": 99999}), "no se puede gastar de mas")
	t.eq(e.coins(), 300, "monedas intactas tras gasto fallido")
	t.check(e.spend({"coins": 100, "gems": 5}), "gasto mixto ok")
	t.eq(e.coins(), 200, "monedas descontadas")
	t.eq(e.gems(), 15, "gemas descontadas")
	e.add_coins(-99999)
	t.eq(e.coins(), 0, "monedas no bajan de 0")

	# --- nivel de cuenta
	var lv := PlayerProfile.new()
	t.eq(int(lv.account_level()["level"]), 1, "nivel 1 inicial")
	lv.data["xp_total"] = PlayerProfile.xp_for_account_level(1)
	t.eq(int(lv.account_level()["level"]), 2, "sube a nivel 2")
	lv.data["xp_total"] += PlayerProfile.xp_for_account_level(2) - 1
	t.eq(int(lv.account_level()["level"]), 2, "un xp menos no sube")
