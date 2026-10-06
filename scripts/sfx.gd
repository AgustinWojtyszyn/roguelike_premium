class_name Sfx
extends Node
## Audio 100% sintetizado por codigo (sin archivos externos).

const RATE := 22050
var sounds: Dictionary = {}
var pool: Array[AudioStreamPlayer] = []
var last_play: Dictionary = {}
var hum: AudioStreamPlayer


func _ready() -> void:
	seed(7)
	sounds["smg"] = _smg()
	sounds["maul"] = _maul()
	sounds["rail"] = _rail()
	sounds["hit"] = _hit()
	sounds["tink"] = _tink()
	sounds["wall"] = _wall()
	sounds["die"] = _die(0.45, 380.0)
	sounds["die_big"] = _die(0.9, 150.0)
	sounds["charge"] = _charge(0.75, 260.0, 1000.0)
	sounds["wind"] = _hiss(0.5)
	sounds["slash"] = _slash()
	sounds["bolt"] = _bolt()
	sounds["slam"] = _slam()
	sounds["stomp"] = _stomp()
	sounds["hurt"] = _hurt()
	sounds["player_die"] = _player_die()
	sounds["spawn"] = _spawn()
	sounds["clear"] = _clear()
	sounds["swap"] = _swap()
	sounds["step"] = _step()
	sounds["break"] = _break()
	sounds["wave"] = _wave()
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		pool.append(p)
	hum = AudioStreamPlayer.new()
	hum.stream = _hum()
	hum.volume_db = -20.0
	add_child(hum)
	hum.play()


func play(name: String, vol: float = 0.0, pitch: float = 1.0, jitter: float = 0.07, min_gap: float = 0.0) -> void:
	if not sounds.has(name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if min_gap > 0.0 and now - float(last_play.get(name, -10.0)) < min_gap:
		return
	last_play[name] = now
	for p in pool:
		if not p.playing:
			p.stream = sounds[name]
			p.volume_db = vol
			p.pitch_scale = pitch * randf_range(1.0 - jitter, 1.0 + jitter)
			p.play()
			return
	# todos ocupados: robar el primero
	var q := pool[0]
	q.stream = sounds[name]
	q.volume_db = vol
	q.pitch_scale = pitch
	q.play()


# ---------- sintesis ----------

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
		w.loop_end = s.size()
	return w


static func _n() -> float:
	return randf() * 2.0 - 1.0


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
