extends RefCounted
## Regla critica Android: los loops de AudioStreamWAV jamas usan loop_end == numero de muestras.

func run(t) -> void:
	var rec := SfxBank.recipes()
	t.check(rec.size() > 30, "banco de sonidos con receta suficiente")
	# hum es el unico efecto en bucle
	var hum: AudioStreamWAV = (rec["hum"] as Callable).call()
	var n := hum.data.size() / 2
	t.eq(hum.loop_mode, AudioStreamWAV.LOOP_FORWARD, "hum en bucle")
	t.eq(hum.loop_end, n - 1, "hum: loop_end == size-1 (regla Android)")
	t.check(hum.loop_end < n, "hum: loop_end < size")
	# musica
	for id in SfxBank.TRACKS:
		var m: AudioStreamWAV = SfxBank.music(id)
		var ns := m.data.size() / 2
		t.eq(m.loop_end, ns - 1, "musica %s: loop_end == size-1" % id)
		t.check(m.loop_begin == 0 and m.loop_end > m.loop_begin, "musica %s: bucle valido" % id)
		t.check(ns > 16000 * 8, "musica %s: duracion > 8 s" % id)
	# los sonidos de un solo disparo no hacen bucle
	var shot: AudioStreamWAV = (rec["smg"] as Callable).call()
	t.eq(shot.loop_mode, AudioStreamWAV.LOOP_DISABLED, "disparo sin bucle")
	# todos los sonidos se construyen y no estan vacios
	var empties := 0
	for k in rec:
		if k == "hum":
			continue
		var s: AudioStreamWAV = (rec[k] as Callable).call()
		if s == null or s.data.size() < 8:
			empties += 1
	t.eq(empties, 0, "ningun sonido vacio")
	run_quality(t)


## Calidad numerica de TODOS los sonidos nuevos (no sustituye escucharlos): sin recorte, sin DC, sin NaN, bordes suaves, nivel util.
func run_quality(t) -> void:
	var rec := SfxBank.recipes()
	var bad: Array[String] = []
	for k in rec:
		if k == "hum":
			continue
		var s: AudioStreamWAV = (rec[k] as Callable).call()
		var n := s.data.size() / 2
		var pk := 0.0
		var sum := 0.0
		for i in n:
			var v := float(s.data.decode_s16(i * 2)) / 32768.0
			pk = maxf(pk, absf(v))
			sum += v
		var last := absf(float(s.data.decode_s16((n - 1) * 2)) / 32768.0)
		var first := absf(float(s.data.decode_s16(0)) / 32768.0)
		if pk < 0.1 or pk > 0.9:
			bad.append("%s nivel %.2f" % [k, pk])
		if absf(sum / float(n)) > 0.01:
			bad.append("%s DC" % k)
		if last > 0.01 or first > 0.02:
			bad.append("%s borde duro" % k)
		if s.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			bad.append("%s con bucle" % k)
	t.eq(bad, [], "sonidos con nivel util, sin DC ni clics en los bordes: %s" % str(bad))
	# variantes: cada sonido clave tiene su set y las variantes no son identicas
	for base in SfxBank.VARIANTS:
		var n: int = SfxBank.VARIANTS[base]
		for v in range(1, n):
			t.check(rec.has("%s~%d" % [base, v]), "variante %s~%d registrada" % [base, v])
		if n > 1:
			var a: AudioStreamWAV = (rec[base] as Callable).call()
			var b: AudioStreamWAV = (rec["%s~1" % base] as Callable).call()
			t.check(a.data != b.data, "%s: la variante 1 difiere de la base" % base)
	# todas las armas apuntan a un sonido existente y propio por arma de fuego
	var seen := {}
	for wid in Catalog.weapons:
		var wd: WeaponData = Catalog.weapons[wid]
		t.check(rec.has(wd.sfx), "%s: sfx '%s' existe" % [wid, wd.sfx])
		seen[wd.sfx] = true
	t.check(seen.size() >= 16, "las 18 armas usan al menos 16 sonidos distintos (%d)" % seen.size())
	# el audio antiguo ya no esta en el runtime
	t.check(not FileAccess.file_exists("res://audio/legacy_sfx.gd"), "sin banco legacy en el runtime")
