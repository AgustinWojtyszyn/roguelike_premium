class_name MusicSynth
extends RefCounted
## Musica de bucle sintetizada por codigo (obra propia, sin muestras externas). Cada estilo orquesta bajo, ritmo, armonia y melodia
## con instrumentos sintetizados (sierras desafinadas filtradas, plucks, campanas FM, percusion de ruido) y reverb en las capas largas.
## Determinista por id. Estilos: menu, industrial (ch1), temple (ch2), castle (ch3), anomaly (ch4), boss.
## REGLA ANDROID: loop_end = size - 1 (jamas == size).

static var R := 22050


static func render(id: String, tr: Dictionary, rate: int, abort: Callable) -> AudioStreamWAV:
	R = rate
	Synth.seed_with("music_" + id)
	var bpm: float = tr["bpm"]
	var beat := 60.0 / bpm
	var bars: int = tr["bars"]
	var total := int(beat * 4.0 * float(bars) * float(R))
	var style: String = tr["style"]
	var ctx := {"beat": beat, "bar": beat * 4.0, "bars": bars, "root": float(tr["root"]), "scale": tr["scale"], "chords": tr["chords"], "total": total}
	var drums := PackedFloat32Array()
	drums.resize(total)
	var bass := PackedFloat32Array()
	bass.resize(total)
	var harm := PackedFloat32Array()     # capas largas (pads / campanas): reciben reverb
	harm.resize(total)
	var lead := PackedFloat32Array()
	lead.resize(total)
	for bar in bars:
		if abort.is_valid() and abort.call():
			return null
		match style:
			"industrial":
				_industrial(ctx, bar, drums, bass, harm, lead)
			"temple":
				_temple(ctx, bar, drums, bass, harm, lead)
			"castle":
				_castle(ctx, bar, drums, bass, harm, lead)
			"anomaly":
				_anomaly(ctx, bar, drums, bass, harm, lead)
			"boss":
				_boss(ctx, bar, drums, bass, harm, lead)
			_:
				_menu(ctx, bar, drums, bass, harm, lead)
	var mixv := _final_mix(style, drums, bass, harm, lead, total)
	return Synth.to_wav(mixv, true, R)


static func _final_mix(style: String, drums: PackedFloat32Array, bass: PackedFloat32Array, harm: PackedFloat32Array, lead: PackedFloat32Array, total: int) -> PackedFloat32Array:
	var wet := 0.35 if style in ["castle", "anomaly", "temple"] else 0.22
	var h := Synth.reverb(harm, 1.4, 0.7, wet, 0.0, R)
	var l := Synth.reverb(lead, 1.0, 0.55, 0.2, 0.0, R)
	var out := PackedFloat32Array()
	out.resize(total)
	for i in total:
		out[i] = drums[i] * 0.9 + bass[i] * 0.85 + h[i] + l[i] * 0.8
	out = Synth.hp(out, 28.0, 0.7, R)
	var drive := 1.6 if style in ["boss", "industrial"] else 1.25
	var pk := 0.001
	for v in out:
		pk = maxf(pk, absf(v))
	for i in total:
		out[i] = tanh(out[i] / pk * drive) / tanh(drive) * 0.78
	var fade := int(0.02 * float(R))
	for i in fade:                           # extremos suaves: el bucle no hace clic
		var a := float(i) / float(fade)
		out[i] *= a
		out[total - 1 - i] *= a
	return out


# ------------------------------------------------------------------ instrumentos (renderizan una nota y la mezclan en `dst`)
static func _put(dst: PackedFloat32Array, src: PackedFloat32Array, at: float, g: float) -> void:
	Synth.mix(dst, src, at, g, R)


static func _osc(n: int, f: float, shape: int, detune: float = 0.0) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(n)
	var ph := 0.0
	var ph2 := 0.0
	for i in n:
		ph += f / float(R)
		var v := 0.0
		match shape:
			1:
				v = fmod(ph, 1.0) * 2.0 - 1.0
			2:
				v = 1.0 if fmod(ph, 1.0) < 0.5 else -1.0
			3:
				v = 1.0 - 4.0 * absf(fmod(ph, 1.0) - 0.5)
			_:
				v = sin(TAU * ph)
		if detune != 0.0:
			ph2 += f * (1.0 + detune) / float(R)
			v = (v + (fmod(ph2, 1.0) * 2.0 - 1.0)) * 0.5
		b[i] = v
	return b


static func _env(n: int, att: float, k: float) -> PackedFloat32Array:
	return Synth.env(n, att, k, R)


static func _kick(dst: PackedFloat32Array, at: float, g: float, deep: float = 1.0) -> void:
	var n := int(0.28 * float(R))
	var b := Synth.mul(Synth.sweep(n, 150.0, 44.0 * deep, 26.0, R), _env(n, 0.0005, 11.0))
	var c := Synth.hp(Synth.mul(Synth.noise(int(0.01 * float(R))), _env(int(0.01 * float(R)), 0.0002, 500.0)), 1500.0, 0.7, R)
	_put(dst, b, at, g)
	_put(dst, c, at, g * 0.5)


static func _snare(dst: PackedFloat32Array, at: float, g: float) -> void:
	var n := int(0.2 * float(R))
	var nz := Synth.svf(Synth.noise(n), 1800.0, 1800.0, 0.9, 2, R)
	_put(dst, Synth.mul(nz, _env(n, 0.0004, 20.0)), at, g)
	_put(dst, Synth.mul(Synth.sweep(n, 220.0, 150.0, 30.0, R), _env(n, 0.0004, 28.0)), at, g * 0.6)


static func _hat(dst: PackedFloat32Array, at: float, g: float, open: bool = false) -> void:
	var n := int((0.12 if open else 0.04) * float(R))
	var nz := Synth.hp(Synth.noise(n), 7000.0, 0.7, R)
	_put(dst, Synth.mul(nz, _env(n, 0.0003, 60.0 if not open else 24.0)), at, g)


static func _clang(dst: PackedFloat32Array, at: float, g: float, base: float = 760.0) -> void:
	var n := int(0.4 * float(R))
	var b := PackedFloat32Array()
	b.resize(n)
	for pr in [[1.0, 1.0, 9.0], [1.49, 0.8, 11.0], [2.37, 0.6, 14.0], [3.11, 0.4, 18.0]]:
		var s := Synth.mul(Synth.sweep(n, base * float(pr[0]), base * float(pr[0]), 1.0, R), _env(n, 0.0004, float(pr[2])))
		for i in n:
			b[i] += s[i] * float(pr[1]) * 0.3
	_put(dst, b, at, g)
	var nz := Synth.mul(Synth.bp(Synth.noise(int(0.05 * float(R))), 2800.0, 1.4, R), _env(int(0.05 * float(R)), 0.0003, 50.0))
	_put(dst, nz, at, g * 0.8)


static func _tom(dst: PackedFloat32Array, at: float, g: float, f: float = 110.0) -> void:
	var n := int(0.4 * float(R))
	_put(dst, Synth.mul(Synth.sweep(n, f * 1.6, f, 18.0, R), _env(n, 0.0006, 8.0)), at, g)
	_put(dst, Synth.mul(Synth.lp(Synth.noise(int(0.03 * float(R))), 1200.0, 0.8, R), _env(int(0.03 * float(R)), 0.0003, 120.0)), at, g * 0.5)


static func _shaker(dst: PackedFloat32Array, at: float, g: float) -> void:
	var n := int(0.07 * float(R))
	_put(dst, Synth.mul(Synth.bp(Synth.noise(n), 6500.0, 1.0, R), _env(n, 0.012, 40.0)), at, g)


static func _bass_note(dst: PackedFloat32Array, at: float, f: float, dur: float, g: float, shape: int = 1, cutoff: float = 420.0) -> void:
	var n := int(dur * float(R))
	var o := _osc(n, f, shape, 0.004)
	o = Synth.lp(o, cutoff, 1.1, R)
	var sub := _osc(n, f, 0, 0.0)
	var e := _env(n, 0.003, 8.0 / maxf(dur, 0.05))
	for i in n:
		o[i] = (o[i] * 0.8 + sub[i] * 0.6) * e[i]
	_put(dst, o, at, g)


static func _pad(dst: PackedFloat32Array, at: float, dur: float, freqs: Array, g: float, cutoff: float = 1200.0, shape: int = 1) -> void:
	var n := int(dur * float(R))
	var acc := PackedFloat32Array()
	acc.resize(n)
	for f in freqs:
		var o := _osc(n, float(f), shape, 0.005)
		for i in n:
			acc[i] += o[i]
	acc = Synth.svf(acc, cutoff * 0.5, cutoff, 0.8, 0, R)
	var att := dur * 0.25
	for i in n:
		var t := float(i) / float(R)
		acc[i] *= minf(1.0, t / att) * minf(1.0, (dur - t) / (dur * 0.3))
	_put(dst, acc, at, g / float(maxi(freqs.size(), 1)))


static func _pluck(dst: PackedFloat32Array, at: float, f: float, g: float, dur: float = 0.5, bright: float = 1.0) -> void:
	var n := int(dur * float(R))
	var b := PackedFloat32Array()
	b.resize(n)
	for pr in [[1.0, 1.0, 7.0], [2.0, 0.45 * bright, 12.0], [3.0, 0.2 * bright, 18.0], [4.0, 0.12 * bright, 26.0]]:
		var s := Synth.mul(Synth.sweep(n, f * float(pr[0]), f * float(pr[0]), 1.0, R), _env(n, 0.0008, float(pr[2])))
		for i in n:
			b[i] += s[i] * float(pr[1])
	_put(dst, b, at, g)


static func _fm_bell(dst: PackedFloat32Array, at: float, f: float, g: float, dur: float = 1.2, k: float = 3.0) -> void:
	var n := int(dur * float(R))
	var b := PackedFloat32Array()
	b.resize(n)
	var ph := 0.0
	var pm := 0.0
	for i in n:
		var t := float(i) / float(R)
		ph += f / float(R)
		pm += f * 3.5 / float(R)
		b[i] = sin(TAU * ph + sin(TAU * pm) * 1.4 * exp(-t * 9.0)) * exp(-t * k) * minf(1.0, t / 0.002)
	_put(dst, b, at, g)


static func _flute(dst: PackedFloat32Array, at: float, f: float, dur: float, g: float) -> void:
	var n := int(dur * float(R))
	var b := PackedFloat32Array()
	b.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(R)
		ph += f * (1.0 + 0.006 * sin(TAU * 5.2 * t) * minf(1.0, t / 0.2)) / float(R)
		b[i] = sin(TAU * ph) + sin(TAU * ph * 2.0) * 0.18
	var breath := Synth.bp(Synth.noise(n), f * 2.0, 1.5, R)
	for i in n:
		var t := float(i) / float(R)
		var e := minf(1.0, t / 0.07) * minf(1.0, (dur - t) / 0.12)
		b[i] = (b[i] + breath[i] * 0.12) * e
	_put(dst, b, at, g)


static func _note_hz(root: float, semis: float, octave: float = 1.0) -> float:
	return root * octave * pow(2.0, semis / 12.0)


static func _chord_semi(ctx: Dictionary, bar: int) -> int:
	var ch: Array = ctx["chords"]
	return int(ch[bar % ch.size()])


# ------------------------------------------------------------------ estilos
static func _industrial(ctx: Dictionary, bar: int, drums: PackedFloat32Array, bass: PackedFloat32Array, harm: PackedFloat32Array, lead: PackedFloat32Array) -> void:
	var beat: float = ctx["beat"]
	var t0: float = float(bar) * float(ctx["bar"])
	var root: float = ctx["root"]
	var cs := _chord_semi(ctx, bar)
	var sc: Array = ctx["scale"]
	var step := beat * 0.25
	var pattern := [1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0]
	for s in 16:
		if pattern[s] == 1:
			var semi := cs + (0 if s % 8 != 6 else 7) + (12 if s == 15 else 0)
			_bass_note(bass, t0 + float(s) * step, _note_hz(root, float(semi)), step * 1.6, 0.55, 1, 320.0 + 60.0 * float(bar % 4))
		var hit_t := t0 + float(s) * step
		if s % 2 == 1 or s % 4 == 0:
			_hat(drums, hit_t, 0.18 if s % 4 == 2 else 0.1, s == 14)
	for q in [0, 8]:
		_kick(drums, t0 + float(q) * step, 0.85)
	if bar % 4 == 3:
		_kick(drums, t0 + 14.0 * step, 0.7)
	for q in [4, 12]:
		_clang(drums, t0 + float(q) * step, 0.22, 640.0 + 40.0 * float(bar % 3))
		_snare(drums, t0 + float(q) * step, 0.3)
	# pad oscuro: acorde menor desafinado, filtro abriendose cada 4 compases
	var pf := [_note_hz(root, float(cs), 4.0), _note_hz(root, float(cs + 3), 4.0), _note_hz(root, float(cs + 7), 4.0)]
	_pad(harm, t0, float(ctx["bar"]), pf, 0.5, 700.0 + 500.0 * float(bar % 4))
	# destellos de datos: blips cuadrados sincopados (mas densos en la 2a mitad)
	if bar >= 4:
		for s in 16:
			if Synth.rng.randf() < (0.22 if bar < 8 else 0.34):
				var deg: int = sc[Synth.rng.randi_range(0, sc.size() - 1)]
				var f := _note_hz(root, float(cs + deg), 16.0 if Synth.rng.randf() < 0.7 else 8.0)
				var n := int(0.09 * float(R))
				var b := Synth.mul(Synth.lp(_osc(n, f, 2), 3200.0, 1.0, R), _env(n, 0.0005, 30.0))
				_put(lead, b, t0 + float(s) * step, 0.18)
	if bar % 4 == 3:   # subida de maquinaria antes del cambio de ciclo
		var n := int(beat * 2.0 * float(R))
		var w := Synth.svf(Synth.noise(n), 400.0, 5000.0, 1.8, 2, R)
		var e := PackedFloat32Array()
		e.resize(n)
		for i in n:
			e[i] = pow(float(i) / float(n), 2.0)
		_put(harm, Synth.mul(w, e), t0 + beat * 2.0, 0.25)


static func _temple(ctx: Dictionary, bar: int, drums: PackedFloat32Array, bass: PackedFloat32Array, harm: PackedFloat32Array, lead: PackedFloat32Array) -> void:
	var beat: float = ctx["beat"]
	var t0: float = float(bar) * float(ctx["bar"])
	var root: float = ctx["root"]
	var cs := _chord_semi(ctx, bar)
	var sc: Array = ctx["scale"]
	var step := beat * 0.5
	# tambores de mano: patron sincopado
	for s in [0, 3, 5]:
		_tom(drums, t0 + float(s) * step, 0.6 if s == 0 else 0.4, 92.0 if s != 3 else 118.0)
	_tom(drums, t0 + 6.0 * step, 0.3, 140.0)
	for s in 8:
		_shaker(drums, t0 + float(s) * step, 0.18 if s % 2 == 0 else 0.1)
	# bajo: bordon en quintas
	_bass_note(bass, t0, _note_hz(root, float(cs)), float(ctx["bar"]) * 0.5, 0.5, 3, 500.0)
	_bass_note(bass, t0 + beat * 2.0, _note_hz(root, float(cs + 7)), float(ctx["bar"]) * 0.5, 0.45, 3, 500.0)
	# pad calido
	_pad(harm, t0, float(ctx["bar"]), [_note_hz(root, float(cs), 4.0), _note_hz(root, float(cs + 7), 4.0), _note_hz(root, float(cs + 12), 4.0)], 0.4, 900.0, 3)
	# marimba: frase de 8 corcheas con huecos (la frase se repite en compases pares)
	var prng := RandomNumberGenerator.new()
	prng.seed = hash("temple_phrase") + (bar % 2) * 31
	var deg_prev := 0
	for s in 8:
		if prng.randf() < 0.3:
			continue
		var deg: int = sc[prng.randi_range(0, sc.size() - 1)]
		deg_prev = deg
		_pluck(lead, t0 + float(s) * step, _note_hz(root, float(cs + deg), 8.0), 0.35, 0.55, 1.0)
	# flauta en la segunda mitad
	if bar >= 8 and bar % 2 == 0:
		var d1: int = sc[(bar / 2) % sc.size()]
		var d2: int = sc[(bar / 2 + 2) % sc.size()]
		_flute(lead, t0 + beat, _note_hz(root, float(cs + d1), 16.0), beat * 2.4, 0.3)
		_flute(lead, t0 + beat * 3.4, _note_hz(root, float(cs + d2), 16.0), beat * 2.4, 0.26)


static func _castle(ctx: Dictionary, bar: int, drums: PackedFloat32Array, bass: PackedFloat32Array, harm: PackedFloat32Array, lead: PackedFloat32Array) -> void:
	var beat: float = ctx["beat"]
	var t0: float = float(bar) * float(ctx["bar"])
	var root: float = ctx["root"]
	var cs := _chord_semi(ctx, bar)
	var sc: Array = ctx["scale"]
	_tom(drums, t0, 0.9, 64.0)
	if bar % 2 == 1:
		_tom(drums, t0 + beat * 2.5, 0.5, 72.0)
		_tom(drums, t0 + beat * 3.0, 0.6, 58.0)
	_bass_note(bass, t0, _note_hz(root, float(cs)), float(ctx["bar"]) * 0.95, 0.55, 1, 260.0)
	var strings := [_note_hz(root, float(cs), 4.0), _note_hz(root, float(cs + 3), 4.0), _note_hz(root, float(cs + 7), 4.0), _note_hz(root, float(cs), 8.0)]
	_pad(harm, t0, float(ctx["bar"]) * 1.02, strings, 0.6, 1100.0)
	if bar % 2 == 0:
		_fm_bell(harm, t0, _note_hz(root, float(cs + 12), 8.0), 0.22, 2.0, 2.0)
	for s in 4:
		if Synth.rng.randf() < 0.4:
			var deg: int = sc[Synth.rng.randi_range(0, sc.size() - 1)]
			_fm_bell(lead, t0 + beat * float(s), _note_hz(root, float(cs + deg), 16.0), 0.18, 1.0, 4.0)


static func _anomaly(ctx: Dictionary, bar: int, drums: PackedFloat32Array, bass: PackedFloat32Array, harm: PackedFloat32Array, lead: PackedFloat32Array) -> void:
	var beat: float = ctx["beat"]
	var t0: float = float(bar) * float(ctx["bar"])
	var root: float = ctx["root"]
	var cs := _chord_semi(ctx, bar)
	var sc: Array = ctx["scale"]
	var step := beat * 0.5
	_bass_note(bass, t0, _note_hz(root, float(cs), 0.5), beat * 1.8, 0.6, 0, 200.0)
	_bass_note(bass, t0 + beat * 2.0, _note_hz(root, float(cs + 6), 0.5), beat * 1.8, 0.5, 0, 200.0)
	var pf := [_note_hz(root, float(cs), 4.0), _note_hz(root, float(cs + 6), 4.0), _note_hz(root, float(cs + 11), 4.0), _note_hz(root, float(cs + 2), 8.0)]
	_pad(harm, t0, float(ctx["bar"]), pf, 0.5, 1500.0, 3)
	for s in 8:
		var deg: int = sc[(s + bar) % sc.size()]
		if Synth.rng.randf() < 0.65:
			_fm_bell(harm, t0 + float(s) * step, _note_hz(root, float(cs + deg), 16.0), 0.14, 1.4, 2.6)
	# percusion glitch irregular
	for s in 8:
		if Synth.rng.randf() < 0.5:
			var n := int(0.03 * float(R))
			var nz := Synth.crush(Synth.hp(Synth.noise(n), 5000.0, 0.7, R), 4, 2)
			_put(drums, Synth.mul(nz, _env(n, 0.0002, 90.0)), t0 + float(s) * step, 0.14)
	if bar % 2 == 0:
		_kick(drums, t0, 0.6, 0.9)
		_kick(drums, t0 + beat * 2.5, 0.4, 0.9)


static func _boss(ctx: Dictionary, bar: int, drums: PackedFloat32Array, bass: PackedFloat32Array, harm: PackedFloat32Array, lead: PackedFloat32Array) -> void:
	var beat: float = ctx["beat"]
	var t0: float = float(bar) * float(ctx["bar"])
	var root: float = ctx["root"]
	var cs := _chord_semi(ctx, bar)
	var sc: Array = ctx["scale"]
	var step := beat * 0.5
	for s in 8:
		var semi := cs + (0 if s % 4 != 3 else (1 if bar % 2 == 0 else 6))
		_bass_note(bass, t0 + float(s) * step, _note_hz(root, float(semi)), step * 0.9, 0.55, 1, 520.0)
		_hat(drums, t0 + float(s) * step + step * 0.5, 0.12)
	for q in 4:
		_kick(drums, t0 + float(q) * beat, 0.9)
	for q in [1, 3]:
		_snare(drums, t0 + float(q) * beat, 0.42)
		_clang(drums, t0 + float(q) * beat, 0.12, 520.0)
	if bar % 4 == 3:
		for q in 4:
			_tom(drums, t0 + beat * 3.0 + float(q) * beat * 0.25, 0.5, 150.0 - 14.0 * float(q))
	var pf := [_note_hz(root, float(cs), 4.0), _note_hz(root, float(cs + 3), 4.0), _note_hz(root, float(cs + 6), 4.0)]
	_pad(harm, t0, float(ctx["bar"]), pf, 0.45, 1800.0)
	# estocadas de metales en contratiempo
	for s in [3, 7]:
		for f in [_note_hz(root, float(cs), 8.0), _note_hz(root, float(cs + 6), 8.0)]:
			var n := int(step * 0.9 * float(R))
			var b := Synth.mul(Synth.lp(_osc(n, f, 1, 0.006), 2200.0, 1.0, R), _env(n, 0.004, 9.0))
			_put(lead, b, t0 + float(s) * step, 0.22)
	if bar >= 8:
		var d: int = sc[(bar * 3) % sc.size()]
		_flute(lead, t0, _note_hz(root, float(cs + d), 16.0), beat * 1.8, 0.14)


static func _menu(ctx: Dictionary, bar: int, drums: PackedFloat32Array, bass: PackedFloat32Array, harm: PackedFloat32Array, lead: PackedFloat32Array) -> void:
	var beat: float = ctx["beat"]
	var t0: float = float(bar) * float(ctx["bar"])
	var root: float = ctx["root"]
	var cs := _chord_semi(ctx, bar)
	var sc: Array = ctx["scale"]
	var step := beat * 0.5
	_kick(drums, t0, 0.45, 0.9)
	_kick(drums, t0 + beat * 2.0, 0.3, 0.9)
	for s in 8:
		_shaker(drums, t0 + float(s) * step, 0.1)
	_bass_note(bass, t0, _note_hz(root, float(cs)), float(ctx["bar"]) * 0.95, 0.5, 3, 400.0)
	_pad(harm, t0, float(ctx["bar"]), [_note_hz(root, float(cs), 4.0), _note_hz(root, float(cs + 3), 4.0), _note_hz(root, float(cs + 7), 4.0), _note_hz(root, float(cs + 10), 4.0)], 0.5, 1000.0, 3)
	for s in 8:
		var deg: int = sc[(s * 2 + bar) % sc.size()]
		if s % 2 == 0 or Synth.rng.randf() < 0.3:
			_pluck(lead, t0 + float(s) * step, _note_hz(root, float(cs + deg), 8.0), 0.3, 0.7, 0.8)
