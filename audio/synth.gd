class_name Synth
extends RefCounted
## Herramientas DSP para el banco de sonido (100% codigo, sin archivos externos, determinista por semilla).
## Todo trabaja sobre PackedFloat32Array mono. Filtros de variable de estado (Chamberlin), saturacion suave,
## retardos/reverb cortos y un `finalize` que quita DC, satura, normaliza y recorta bordes (sin clicks).

const RATE := 32000
static var rng := RandomNumberGenerator.new()


static func seed_with(name: String, variant: int = 0) -> void:
	rng.seed = hash(name) + variant * 7919


static func buf(dur: float, rate: int = RATE) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(maxi(8, int(dur * float(rate))))
	return b


static func noise(n: int) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(n)
	for i in n:
		b[i] = rng.randf() * 2.0 - 1.0
	return b


## Mezcla `src` en `dst` desde el instante `at` (s) con ganancia `gain`.
static func mix(dst: PackedFloat32Array, src: PackedFloat32Array, at: float, gain: float = 1.0, rate: int = RATE) -> void:
	var o := int(at * float(rate))
	var n := mini(src.size(), dst.size() - o)
	for i in n:
		dst[o + i] += src[i] * gain


## Envolvente exponencial con ataque lineal: attack (s), k = constante de caida (1/s).
static func env(n: int, attack: float, k: float, rate: int = RATE) -> PackedFloat32Array:
	var e := PackedFloat32Array()
	e.resize(n)
	var a := maxf(attack * float(rate), 1.0)
	for i in n:
		var t := float(i) / float(rate)
		e[i] = minf(1.0, float(i) / a) * exp(-t * k)
	return e


static func mul(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var o := PackedFloat32Array()
	o.resize(a.size())
	for i in a.size():
		o[i] = a[i] * (b[i] if i < b.size() else 0.0)
	return o


static func scale(a: PackedFloat32Array, g: float) -> PackedFloat32Array:
	var o := a.duplicate()
	for i in o.size():
		o[i] *= g
	return o


## Seno con barrido exponencial de frecuencia f0->f1 (la fase se integra: sin saltos). `fm` = indice de modulacion de frecuencia opcional.
static func sweep(n: int, f0: float, f1: float, k: float, rate: int = RATE, shape: int = 0) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(rate)
		var f := f1 + (f0 - f1) * exp(-t * k)
		ph += f / float(rate)
		var p := fmod(ph, 1.0)
		match shape:
			1:
				b[i] = p * 2.0 - 1.0                          # sierra
			2:
				b[i] = 1.0 if p < 0.5 else -1.0               # cuadrada
			3:
				b[i] = 1.0 - 4.0 * absf(p - 0.5)              # triangulo
			_:
				b[i] = sin(TAU * p)
	return b


## Filtro de variable de estado con corte que va de fc0 a fc1 (lineal en log). mode: 0 pasa-bajos, 1 pasa-altos, 2 pasa-banda.
static func svf(x: PackedFloat32Array, fc0: float, fc1: float, q: float = 0.7, mode: int = 0, rate: int = RATE) -> PackedFloat32Array:
	var o := PackedFloat32Array()
	o.resize(x.size())
	var low := 0.0
	var band := 0.0
	var damp := 1.0 / maxf(q, 0.05)
	var n := x.size()
	var fmax := float(rate) * 0.16   # por encima de ~0.16*fs el SVF de Chamberlin se vuelve inestable (NaN)
	var fc := minf(maxf(fc0, 20.0), fmax)
	var ratio := 1.0
	if absf(fc1 - fc0) > 0.01 and n > 1:
		ratio = pow(minf(maxf(fc1, 20.0), fmax) / fc, 1.0 / float(n - 1))   # barrido exponencial: fc *= ratio por muestra
	var f := 2.0 * sin(PI * fc / float(rate))
	var moving := ratio != 1.0
	for i in n:
		if moving:
			fc *= ratio
			f = 2.0 * sin(PI * fc / float(rate))
		low += f * band
		var high := x[i] - low - damp * band
		band += f * high
		match mode:
			1:
				o[i] = high
			2:
				o[i] = band
			_:
				o[i] = low
	return o


static func lp(x: PackedFloat32Array, fc: float, q: float = 0.7, rate: int = RATE) -> PackedFloat32Array:
	return svf(x, fc, fc, q, 0, rate)


static func hp(x: PackedFloat32Array, fc: float, q: float = 0.7, rate: int = RATE) -> PackedFloat32Array:
	return svf(x, fc, fc, q, 1, rate)


static func bp(x: PackedFloat32Array, fc: float, q: float = 1.5, rate: int = RATE) -> PackedFloat32Array:
	return svf(x, fc, fc, q, 2, rate)


static func softclip(x: PackedFloat32Array, drive: float) -> PackedFloat32Array:
	var o := PackedFloat32Array()
	o.resize(x.size())
	var norm := 1.0 / tanh(drive)
	for i in x.size():
		o[i] = tanh(x[i] * drive) * norm
	return o


## Retardo con realimentacion (eco corto / cuerpo de sala).
static func delay(x: PackedFloat32Array, time: float, fb: float, wet: float, rate: int = RATE) -> PackedFloat32Array:
	var d := maxi(1, int(time * float(rate)))
	var line := x.duplicate()
	for i in range(d, x.size()):
		line[i] = x[i] + line[i - d] * fb
	var o := PackedFloat32Array()
	o.resize(x.size())
	for i in x.size():
		o[i] = x[i] + (line[i] - x[i]) * wet
	return o


## Reverb tipo Schroeder pequena (4 combs + 2 allpass). `size` ~ 0.5..1.5 escala los tiempos. Alarga el buffer con la cola.
static func reverb(x: PackedFloat32Array, size: float, decay: float, wet: float, tail: float = 0.0, rate: int = RATE) -> PackedFloat32Array:
	var n := x.size() + int(tail * float(rate))
	var src := PackedFloat32Array()
	src.resize(n)
	for i in x.size():
		src[i] = x[i]
	var out := PackedFloat32Array()
	out.resize(n)
	var combs := [0.0297, 0.0371, 0.0411, 0.0437]
	for c in combs:
		var d := maxi(1, int(float(c) * size * float(rate)))
		var line := PackedFloat32Array()
		line.resize(n)
		var lp_s := 0.0
		for i in n:
			var fbv := line[i - d] if i >= d else 0.0
			lp_s += (fbv - lp_s) * 0.45                 # amortigua agudos en la cola
			line[i] = src[i] + lp_s * decay
			out[i] += line[i] * 0.25
	for ap in [0.0050, 0.0017]:
		var d := maxi(1, int(float(ap) * size * float(rate)))
		var res := PackedFloat32Array()
		res.resize(n)
		for i in n:
			var yd := res[i - d] if i >= d else 0.0
			var xd := out[i - d] if i >= d else 0.0
			res[i] = -0.5 * out[i] + xd + 0.5 * yd
		out = res
	var o := PackedFloat32Array()
	o.resize(n)
	for i in n:
		o[i] = (src[i] * (1.0 - wet) + out[i] * wet * 2.0)
	return o


static func crush(x: PackedFloat32Array, bits: int, hold: int) -> PackedFloat32Array:
	var o := x.duplicate()
	var steps := pow(2.0, float(bits))
	var h := 0.0
	for i in o.size():
		if i % maxi(hold, 1) == 0:
			h = roundf(x[i] * steps) / steps
		o[i] = h
	return o


## Quita DC, satura suavemente, normaliza al pico `peak` y recorta bordes (fade-in 0.4 ms / fade-out `fade` s).
static func finalize(x: PackedFloat32Array, peak: float = 0.55, drive: float = 1.0, fade: float = 0.03, rate: int = RATE) -> PackedFloat32Array:
	var o := hp(x, 25.0, 0.7, rate) if x.size() > 64 else x.duplicate()
	if drive > 1.001:
		var m := 0.0001
		for v in o:
			m = maxf(m, absf(v))
		o = scale(o, 1.0 / m)
		o = softclip(o, drive)
	var pk := 0.0001
	for v in o:
		pk = maxf(pk, absf(v))
	var g := peak / pk
	var n := o.size()
	var fi := maxi(1, int(0.0004 * float(rate)))
	var fo := maxi(2, int(fade * float(rate)))
	for i in n:
		var a := 1.0
		if i < fi:
			a = float(i) / float(fi)
		if i > n - fo:
			var u := float(n - i) / float(fo)
			a = minf(a, u * u * (3.0 - 2.0 * u))
		o[i] = o[i] * g * a
	return o


## Convierte a AudioStreamWAV 16 bit mono.
static func to_wav(s: PackedFloat32Array, loop: bool = false, rate: int = RATE) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(s.size() * 2)
	for i in s.size():
		data.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		# REGLA ANDROID: loop_end == size provoca SIGSEGV en el hilo AudioTrack. Nunca igualar a size.
		w.loop_end = s.size() - 1
	return w


static func stats(x: PackedFloat32Array) -> Dictionary:
	var pk := 0.0
	var sum := 0.0
	var sq := 0.0
	for v in x:
		pk = maxf(pk, absf(v))
		sum += v
		sq += v * v
	var n := maxf(float(x.size()), 1.0)
	return {"peak": pk, "rms": sqrt(sq / n), "dc": sum / n}
