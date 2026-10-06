class_name SfxBank
extends RefCounted
## Banco de sonidos 100% sintetizado por codigo (sin archivos externos). Pensado para construirse en un hilo.
## REGLA ANDROID: los loops usan loop_end = size - 1. Con loop_end == size el mezclador de Android hace SIGSEGV
## en el hilo de AudioTrack. No cambiar (cubierto por tests/test_audio_bank.gd).

const RATE := 22050
static var _rng := RandomNumberGenerator.new()


## Nombre -> Callable que devuelve un AudioStreamWAV.
static func recipes() -> Dictionary:
	return {
		"smg": _smg, "maul": _maul, "rail": _rail, "hit": _hit, "tink": _tink, "wall": _wall,
		"die": func(): return _die(0.45, 380.0), "die_big": func(): return _die(0.9, 150.0),
		"charge": func(): return _charge(0.75, 260.0, 1000.0), "wind": func(): return _hiss(0.5),
		"slash": _slash, "bolt": _bolt, "slam": _slam, "stomp": _stomp, "hurt": _hurt, "player_die": _player_die,
		"spawn": _spawn, "clear": _clear, "swap": _swap, "step": _step, "break": _break, "wave": _wave,
		"zap": _zap, "flame": _flame, "boom": _boom, "coin": _coin, "chest": _chest, "perk": _perk,
		"shield_break": _shield_break, "shield_hit": _shield_hit, "ability": _ability, "heal": _heal,
		"pickup": _pickup, "roar": _roar, "thump": _thump, "empty": _empty, "reflect": _reflect, "drone": _drone,
		"ui_click": _ui_click, "ui_back": _ui_back, "ui_open": _ui_open, "ui_confirm": _ui_confirm, "ui_error": _ui_error,
		"hum": _hum, "reward": _reward, "levelup": _levelup, "victory": _victory, "defeat": _defeat, "tick": _tick,
	}


static func _wav(s: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(s.size() * 2)
	for i in s.size():
		var v := int(clampf(s[i], -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		# loop_end == size crashes Godot's Android mixer (SIGSEGV in AudioTrack thread at the wrap)
		w.loop_end = s.size() - 1
	return w


static func _n() -> float:
	return _rng.randf() * 2.0 - 1.0


static func _buf(dur: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(dur * RATE))
	return b


static func _smg() -> AudioStreamWAV:
	var b := _buf(0.13)
	var lp := 0.0
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.5
		var f := 220.0 * exp(-t * 28.0) + 70.0
		ph += TAU * f / RATE
		var env := exp(-t * 32.0)
		b[i] = (lp * 0.7 + sin(ph) * 0.8 + (_n() * 0.4 if t < 0.006 else 0.0)) * env * 0.55
	return _wav(b)


static func _maul() -> AudioStreamWAV:
	var b := _buf(0.5)
	var lp := 0.0
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.18
		var f := 120.0 * exp(-t * 12.0) + 38.0
		ph += TAU * f / RATE
		var env := exp(-t * 9.0)
		b[i] = (lp * 1.2 + sin(ph) * 1.1 + (_n() * 0.6 if t < 0.012 else 0.0)) * env * 0.6
	return _wav(b)


static func _rail() -> AudioStreamWAV:
	var b := _buf(0.55)
	var ph := 0.0
	var ph2 := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 2600.0 * exp(-t * 9.0) + 260.0
		ph += TAU * f / RATE
		ph2 += TAU * f * 2.01 / RATE
		var env := exp(-t * 7.0)
		var crack := _n() * exp(-t * 90.0)
		b[i] = (sin(ph) * 0.6 + sin(ph2) * 0.25 + crack * 0.9) * env * 0.6
	return _wav(b)


static func _hit() -> AudioStreamWAV:
	var b := _buf(0.09)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (900.0 - t * 5000.0) / RATE
		b[i] = (_n() * 0.5 + signf(sin(ph)) * 0.3) * exp(-t * 55.0) * 0.5
	return _wav(b)


static func _tink() -> AudioStreamWAV:
	var b := _buf(0.2)
	for i in b.size():
		var t := float(i) / RATE
		var env := exp(-t * 26.0)
		b[i] = (sin(TAU * 1310.0 * t) * 0.5 + sin(TAU * 1780.0 * t) * 0.35 + sin(TAU * 2930.0 * t) * 0.2) * env * 0.5
	return _wav(b)


static func _wall() -> AudioStreamWAV:
	var b := _buf(0.07)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.35
		b[i] = lp * exp(-t * 70.0) * 0.5
	return _wav(b)


static func _die(dur: float, f0: float) -> AudioStreamWAV:
	var b := _buf(dur)
	var lp := 0.0
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.3
		ph += TAU * (f0 * exp(-t * 6.0) + 40.0) / RATE
		var env := exp(-t * (5.0 if dur > 0.6 else 8.0))
		b[i] = (lp * 0.9 + signf(sin(ph)) * 0.25 + sin(ph * 0.5) * 0.5) * env * 0.55
	return _wav(b)


static func _charge(dur: float, f0: float, f1: float) -> AudioStreamWAV:
	var b := _buf(dur)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var k := t / dur
		var f := f0 + (f1 - f0) * k * k
		ph += TAU * f / RATE
		var trem := 0.65 + 0.35 * sin(TAU * (10.0 + 20.0 * k) * t)
		var env := minf(1.0, k * 4.0) * (1.0 - pow(k, 8.0))
		b[i] = (sin(ph) * 0.5 + sin(ph * 1.5) * 0.2) * trem * env * 0.35
	return _wav(b)


static func _hiss(dur: float) -> AudioStreamWAV:
	var b := _buf(dur)
	var lp := 0.0
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var k := t / dur
		lp += (_n() - lp) * (0.25 + 0.5 * k)
		ph += TAU * (90.0 + 160.0 * k) / RATE
		var env := minf(1.0, k * 3.0) * (1.0 - pow(k, 6.0))
		b[i] = (lp * 0.5 + sin(ph) * signf(sin(ph * 3.0)) * 0.25) * env * 0.4
	return _wav(b)


static func _slash() -> AudioStreamWAV:
	var b := _buf(0.18)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * (0.15 + 3.0 * t)
		var env := sin(minf(t / 0.18, 1.0) * PI) * exp(-t * 6.0)
		b[i] = lp * env * 0.8
	return _wav(b)


static func _bolt() -> AudioStreamWAV:
	var b := _buf(0.28)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (900.0 * exp(-t * 11.0) + 160.0) / RATE
		var saw := fmod(ph / TAU, 1.0) * 2.0 - 1.0
		b[i] = (saw * 0.5 + sin(ph) * 0.4) * exp(-t * 13.0) * 0.5
	return _wav(b)


static func _slam() -> AudioStreamWAV:
	var b := _buf(0.8)
	var lp := 0.0
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.1
		ph += TAU * (85.0 * exp(-t * 5.0) + 28.0) / RATE
		b[i] = (sin(ph) * 1.0 + lp * 1.4 * exp(-t * 8.0)) * exp(-t * 4.5) * 0.75
	return _wav(b)


static func _stomp() -> AudioStreamWAV:
	var b := _buf(0.16)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.12
		b[i] = (sin(TAU * (70.0 - t * 150.0) * t) * 0.9 + lp * 0.5) * exp(-t * 26.0) * 0.6
	return _wav(b)


static func _hurt() -> AudioStreamWAV:
	var b := _buf(0.35)
	var ph := 0.0
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.25
		ph += TAU * (170.0 - t * 200.0) / RATE
		b[i] = (signf(sin(ph)) * 0.35 + lp * 0.5) * exp(-t * 9.0) * 0.6
	return _wav(b)


static func _player_die() -> AudioStreamWAV:
	var b := _buf(1.2)
	var ph := 0.0
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.2
		ph += TAU * (420.0 * exp(-t * 3.0) + 30.0) / RATE
		b[i] = (sin(ph) * 0.5 + signf(sin(ph * 0.5)) * 0.2 + lp * 0.5 * exp(-t * 10.0)) * exp(-t * 2.6) * 0.65
	return _wav(b)


static func _spawn() -> AudioStreamWAV:
	var b := _buf(0.7)
	var ph := 0.0
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var k := t / 0.7
		lp += (_n() - lp) * 0.4
		ph += TAU * (120.0 + 600.0 * k * k) / RATE
		var env := sin(minf(k, 1.0) * PI) * 0.9
		b[i] = (sin(ph) * 0.4 + lp * 0.25 * k + sin(ph * 3.0) * 0.1) * env * 0.5
	return _wav(b)


static func _clear() -> AudioStreamWAV:
	var b := _buf(1.6)
	var notes := [440.0, 659.3, 880.0, 1318.5]
	for n in notes.size():
		var t0 := 0.12 * float(n)
		for i in b.size():
			var t := float(i) / RATE - t0
			if t < 0.0:
				continue
			b[i] += (sin(TAU * notes[n] * t) + sin(TAU * notes[n] * 2.0 * t) * 0.25) * exp(-t * 3.2) * 0.2
	return _wav(b)


static func _wave() -> AudioStreamWAV:
	var b := _buf(0.6)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (110.0 + 40.0 * sin(t * 5.0)) / RATE
		b[i] = (sin(ph) * 0.6 + sin(ph * 2.0) * 0.2) * exp(-t * 5.0) * 0.5
	return _wav(b)


static func _swap() -> AudioStreamWAV:
	var b := _buf(0.14)
	for i in b.size():
		var t := float(i) / RATE
		var env := exp(-t * 60.0) + (exp(-(t - 0.07) * 70.0) if t > 0.07 else 0.0)
		b[i] = (_n() * 0.4 + sin(TAU * 600.0 * t) * 0.4) * env * 0.4
	return _wav(b)


static func _step() -> AudioStreamWAV:
	var b := _buf(0.07)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.1
		b[i] = (lp * 1.2 + sin(TAU * 90.0 * t) * 0.4) * exp(-t * 50.0) * 0.35
	return _wav(b)


static func _break() -> AudioStreamWAV:
	var b := _buf(0.3)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.5
		var tick := 1.0 if fmod(t, 0.045) < 0.004 else 0.3
		b[i] = lp * tick * exp(-t * 14.0) * 0.7
	return _wav(b)


static func _hum() -> AudioStreamWAV:
	var n := 4 * RATE
	var b := PackedFloat32Array()
	b.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := sin(TAU * 55.0 * t) * 0.5 + sin(TAU * 82.5 * t) * 0.3 + sin(TAU * 110.0 * t) * 0.15
		v *= 0.75 + 0.25 * sin(TAU * 0.5 * t)
		b[i] = v * 0.5
	return _wav(b, true)


# ------------------------------------------------------------------ nuevos sonidos
static func _zap() -> AudioStreamWAV:
	var b := _buf(0.22)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (1400.0 + 800.0 * sin(t * 90.0)) / RATE
		var crackle := _n() * (0.6 if fmod(t * 380.0, 1.0) < 0.35 else 0.1)
		b[i] = (signf(sin(ph)) * 0.25 + crackle * 0.5) * exp(-t * 14.0) * 0.6
	return _wav(b)


static func _flame() -> AudioStreamWAV:
	var b := _buf(0.12)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.12
		b[i] = lp * 1.6 * minf(1.0, t * 90.0) * exp(-t * 16.0) * 0.5
	return _wav(b)


static func _boom() -> AudioStreamWAV:
	var b := _buf(0.7)
	var lp := 0.0
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.09
		ph += TAU * (110.0 * exp(-t * 7.0) + 32.0) / RATE
		b[i] = (sin(ph) * 0.9 + lp * 1.3 * exp(-t * 7.0)) * exp(-t * 5.0) * 0.75
	return _wav(b)


static func _coin() -> AudioStreamWAV:
	var b := _buf(0.2)
	for i in b.size():
		var t := float(i) / RATE
		var f := 1318.5 if t < 0.05 else 1975.5
		b[i] = (sin(TAU * f * t) * 0.5 + sin(TAU * f * 2.0 * t) * 0.15) * exp(-t * 14.0) * 0.45
	return _wav(b)


static func _chest() -> AudioStreamWAV:
	var b := _buf(0.9)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.3
		var thud := sin(TAU * (90.0 - t * 80.0) * t) * exp(-t * 22.0) * 0.8
		var creak := sin(TAU * (240.0 + 220.0 * t) * t) * exp(-t * 6.0) * 0.12 * (1.0 if t > 0.04 else 0.0)
		var sparkle := 0.0
		if t > 0.18:
			var tt := t - 0.18
			sparkle = (sin(TAU * 1568.0 * tt) + sin(TAU * 2093.0 * (tt + 0.1))) * exp(-tt * 5.0) * 0.14
		b[i] = (thud + creak + lp * exp(-t * 60.0) * 0.4 + sparkle) * 0.9
	return _wav(b)


static func _perk() -> AudioStreamWAV:
	var b := _buf(0.7)
	var notes := [523.3, 659.3, 784.0, 1046.5]
	for n in notes.size():
		var t0 := 0.07 * float(n)
		for i in b.size():
			var t := float(i) / RATE - t0
			if t < 0.0:
				continue
			b[i] += (sin(TAU * notes[n] * t) + sin(TAU * notes[n] * 3.0 * t) * 0.12) * exp(-t * 5.0) * 0.2
	return _wav(b)


static func _shield_break() -> AudioStreamWAV:
	var b := _buf(0.5)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.5
		b[i] = (lp * exp(-t * 18.0) * 0.7 + sin(TAU * (1200.0 - t * 1800.0) * t) * exp(-t * 9.0) * 0.4) * 0.6
	return _wav(b)


static func _shield_hit() -> AudioStreamWAV:
	var b := _buf(0.18)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * 880.0 * t) * 0.4 + sin(TAU * 1320.0 * t) * 0.3 + _n() * 0.15) * exp(-t * 24.0) * 0.5
	return _wav(b)


static func _ability() -> AudioStreamWAV:
	var b := _buf(0.6)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var k := t / 0.6
		ph += TAU * (220.0 + 900.0 * k * k) / RATE
		b[i] = (sin(ph) * 0.5 + sin(ph * 2.0) * 0.2) * sin(minf(k, 1.0) * PI) * 0.5
	return _wav(b)


static func _heal() -> AudioStreamWAV:
	var b := _buf(0.6)
	for i in b.size():
		var t := float(i) / RATE
		var f := 660.0 + 440.0 * minf(t / 0.3, 1.0)
		b[i] = (sin(TAU * f * t) * 0.4 + sin(TAU * f * 1.5 * t) * 0.2) * exp(-t * 5.0) * 0.5
	return _wav(b)


static func _pickup() -> AudioStreamWAV:
	var b := _buf(0.14)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = sin(TAU * (700.0 + 1400.0 * t / 0.14) * t) * exp(-t * 20.0) * 0.4
	return _wav(b)


static func _roar() -> AudioStreamWAV:
	var b := _buf(1.0)
	var lp := 0.0
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * 0.25
		ph += TAU * (70.0 + 30.0 * sin(t * 14.0)) / RATE
		var env := sin(minf(t / 1.0, 1.0) * PI) * 0.9
		b[i] = (signf(sin(ph)) * 0.4 + lp * 0.7 + sin(ph * 0.5) * 0.4) * env * 0.6
	return _wav(b)


static func _thump() -> AudioStreamWAV:
	var b := _buf(0.5)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = sin(TAU * (60.0 - t * 40.0) * t) * exp(-t * 9.0) * 0.9
	return _wav(b)


static func _empty() -> AudioStreamWAV:
	var b := _buf(0.07)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (_n() * 0.4 + sin(TAU * 300.0 * t) * 0.3) * exp(-t * 70.0) * 0.4
	return _wav(b)


static func _reflect() -> AudioStreamWAV:
	var b := _buf(0.2)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * (1800.0 - t * 4000.0) * t) * 0.5 + sin(TAU * 2400.0 * t) * 0.2) * exp(-t * 18.0) * 0.45
	return _wav(b)


static func _drone() -> AudioStreamWAV:
	var b := _buf(0.3)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += TAU * (300.0 + 200.0 * sin(t * 40.0)) / RATE
		b[i] = (sin(ph) * 0.4 + signf(sin(ph * 0.5)) * 0.15) * exp(-t * 10.0) * 0.4
	return _wav(b)


# ---- UI
static func _ui_click() -> AudioStreamWAV:
	var b := _buf(0.09)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * 740.0 * t) * 0.5 + sin(TAU * 1480.0 * t) * 0.18) * exp(-t * 48.0) * 0.5
	return _wav(b)


static func _tick() -> AudioStreamWAV:
	var b := _buf(0.04)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = sin(TAU * 1100.0 * t) * exp(-t * 110.0) * 0.4
	return _wav(b)


static func _ui_back() -> AudioStreamWAV:
	var b := _buf(0.12)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * (520.0 - t * 1200.0) * t) * 0.5) * exp(-t * 30.0) * 0.5
	return _wav(b)


static func _ui_open() -> AudioStreamWAV:
	var b := _buf(0.2)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_n() - lp) * (0.1 + 2.0 * t)
		b[i] = (sin(TAU * (300.0 + 1400.0 * t) * t) * 0.3 + lp * 0.3) * sin(minf(t / 0.2, 1.0) * PI) * 0.5
	return _wav(b)


static func _ui_confirm() -> AudioStreamWAV:
	var b := _buf(0.3)
	for i in b.size():
		var t := float(i) / RATE
		var f := 784.0 if t < 0.08 else 1175.0
		b[i] = (sin(TAU * f * t) * 0.45 + sin(TAU * f * 2.0 * t) * 0.15) * exp(-t * 11.0) * 0.5
	return _wav(b)


static func _ui_error() -> AudioStreamWAV:
	var b := _buf(0.2)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = signf(sin(TAU * (190.0 - t * 50.0) * t)) * exp(-t * 16.0) * 0.28
	return _wav(b)


static func _reward() -> AudioStreamWAV:
	var b := _buf(1.0)
	var notes := [523.3, 659.3, 784.0, 1046.5, 1318.5]
	for n in notes.size():
		var t0 := 0.08 * float(n)
		for i in b.size():
			var t := float(i) / RATE - t0
			if t < 0.0:
				continue
			b[i] += (sin(TAU * notes[n] * t) + sin(TAU * notes[n] * 2.0 * t) * 0.2) * exp(-t * 4.0) * 0.17
	return _wav(b)


static func _levelup() -> AudioStreamWAV:
	var b := _buf(1.2)
	var notes := [392.0, 523.3, 659.3, 784.0, 1046.5]
	for n in notes.size():
		var t0 := 0.1 * float(n)
		for i in b.size():
			var t := float(i) / RATE - t0
			if t < 0.0:
				continue
			b[i] += (sin(TAU * notes[n] * t) + sin(TAU * notes[n] * 3.0 * t) * 0.1) * exp(-t * 3.0) * 0.18
	return _wav(b)


static func _victory() -> AudioStreamWAV:
	var b := _buf(2.2)
	var notes := [392.0, 523.3, 659.3, 784.0, 659.3, 784.0, 1046.5]
	var times := [0.0, 0.14, 0.28, 0.42, 0.7, 0.84, 1.0]
	for n in notes.size():
		for i in b.size():
			var t: float = float(i) / RATE - float(times[n])
			if t < 0.0:
				continue
			b[i] += (sin(TAU * notes[n] * t) + sin(TAU * notes[n] * 2.0 * t) * 0.25 + sin(TAU * notes[n] * 0.5 * t) * 0.3) * exp(-t * 2.6) * 0.17
	return _wav(b)


static func _defeat() -> AudioStreamWAV:
	var b := _buf(1.8)
	var notes := [392.0, 349.2, 311.1, 261.6]
	for n in notes.size():
		var t0 := 0.28 * float(n)
		for i in b.size():
			var t := float(i) / RATE - t0
			if t < 0.0:
				continue
			b[i] += (sin(TAU * notes[n] * t) * 0.5 + signf(sin(TAU * notes[n] * 0.5 * t)) * 0.12) * exp(-t * 2.4) * 0.28
	return _wav(b)


# ------------------------------------------------------------------ musica procedural (loops)
const MUSIC_RATE := 16000

## Pistas disponibles: id -> parametros (tonica en Hz, tempo bpm, escala, timbre, densidad)
const TRACKS := {
	"menu": {"root": 110.0, "bpm": 92.0, "scale": [0, 3, 5, 7, 10], "chords": [0, 5, 3, 7], "wave": 0, "drums": 0.55, "bars": 8},
	"ch1": {"root": 98.0, "bpm": 116.0, "scale": [0, 3, 5, 7, 10], "chords": [0, 0, 5, 3], "wave": 1, "drums": 1.0, "bars": 8},
	"ch2": {"root": 82.4, "bpm": 104.0, "scale": [0, 1, 5, 7, 8], "chords": [0, 8, 5, 7], "wave": 2, "drums": 0.9, "bars": 8},
	"ch3": {"root": 73.4, "bpm": 84.0, "scale": [0, 2, 3, 7, 8], "chords": [0, 3, 5, 7], "wave": 0, "drums": 0.7, "bars": 8},
	"ch4": {"root": 87.3, "bpm": 100.0, "scale": [0, 2, 6, 7, 11], "chords": [0, 6, 2, 7], "wave": 3, "drums": 0.6, "bars": 8},
	"boss": {"root": 65.4, "bpm": 138.0, "scale": [0, 1, 3, 6, 7], "chords": [0, 1, 0, 6], "wave": 1, "drums": 1.3, "bars": 8},
}


static func music(id: String) -> AudioStreamWAV:
	var tr: Dictionary = TRACKS.get(id, TRACKS["menu"])
	var rate := MUSIC_RATE
	var bpm: float = tr["bpm"]
	var beat := 60.0 / bpm
	var bars: int = tr["bars"]
	var total := int(beat * 4.0 * float(bars) * rate)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var scale: Array = tr["scale"]
	var chords: Array = tr["chords"]
	var root: float = tr["root"]
	var wave_kind: int = tr["wave"]
	var drum_amt: float = tr["drums"]
	# bajo + acordes: un acorde por compas
	for bar in bars:
		var croot: int = chords[bar % chords.size()]
		var t0 := float(bar) * beat * 4.0
		var f_bass := root * pow(2.0, float(croot) / 12.0)
		for q in 8:
			var ts := t0 + float(q) * beat * 0.5
			var n0 := int(ts * rate)
			var n1 := mini(total, n0 + int(beat * 0.5 * rate))
			var oct := 1.0 if (q % 4) != 3 else 2.0
			var f := f_bass * oct
			for n in range(n0, n1):
				var t := float(n - n0) / rate
				var env := exp(-t * 7.0) * minf(1.0, t * 300.0)
				var ph := TAU * f * t
				var v := sin(ph) + 0.35 * sin(ph * 2.0)
				if wave_kind == 1:
					v = signf(sin(ph)) * 0.45 + sin(ph * 0.5) * 0.4
				elif wave_kind == 2:
					v = sin(ph) + 0.5 * sin(ph * 3.0)
				buf[n] += v * env * 0.22
		# pad
		var n0p := int(t0 * rate)
		var n1p := mini(total, int((t0 + beat * 4.0) * rate))
		for k in [0, 3 if wave_kind != 2 else 1, 7]:
			var fp := root * 2.0 * pow(2.0, float(croot + k) / 12.0)
			for n in range(n0p, n1p):
				var t := float(n - n0p) / rate
				var env := minf(1.0, t * 3.0) * minf(1.0, (beat * 4.0 - t) * 3.0)
				buf[n] += sin(TAU * fp * t + sin(TAU * 0.3 * t)) * env * 0.045
		# arpegio
		var steps := 8
		for s in steps:
			if rng.randf() < 0.28:
				continue
			var deg: int = scale[rng.randi_range(0, scale.size() - 1)]
			var fa := root * 4.0 * pow(2.0, float(croot + deg) / 12.0)
			var ts := t0 + float(s) * beat * 0.5
			var n0 := int(ts * rate)
			var n1 := mini(total, n0 + int(beat * 0.6 * rate))
			for n in range(n0, n1):
				var t := float(n - n0) / rate
				var env := exp(-t * 11.0) * minf(1.0, t * 400.0)
				var v := sin(TAU * fa * t)
				if wave_kind == 3:
					v += sin(TAU * fa * 1.5 * t) * 0.4
				buf[n] += v * env * 0.07
	# percusion
	if drum_amt > 0.0:
		var lp := 0.0
		for bar in bars:
			for q in 8:
				var ts := (float(bar) * 4.0 + float(q) * 0.5) * beat
				var n0 := int(ts * rate)
				var kick := (q == 0 or q == 4 or (q == 6 and drum_amt > 0.9))
				var hat := (q % 2 == 1)
				var snare := (q == 2 or q == 6)
				var len := int(0.22 * rate)
				for n in range(n0, mini(total, n0 + len)):
					var t := float(n - n0) / rate
					if kick:
						buf[n] += sin(TAU * (120.0 * exp(-t * 22.0) + 42.0) * t) * exp(-t * 11.0) * 0.5 * drum_amt
					if snare and drum_amt > 0.8:
						lp += (rng.randf() * 2.0 - 1.0 - lp) * 0.4
						buf[n] += lp * exp(-t * 16.0) * 0.16
					if hat:
						buf[n] += (rng.randf() * 2.0 - 1.0) * exp(-t * 70.0) * 0.05 * drum_amt
	# normalizar suave
	var peak := 0.001
	for n in total:
		peak = maxf(peak, absf(buf[n]))
	var g := 0.8 / peak
	for n in total:
		buf[n] = buf[n] * g
	var data := PackedByteArray()
	data.resize(total * 2)
	for n in total:
		data.encode_s16(n * 2, int(clampf(buf[n], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = total - 1   # nunca == total (ver regla Android arriba)
	return w
