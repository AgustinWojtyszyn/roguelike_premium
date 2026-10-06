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
