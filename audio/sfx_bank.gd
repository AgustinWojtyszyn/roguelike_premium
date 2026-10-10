class_name SfxBank
extends RefCounted
## Banco de sonidos 100% sintetizado por codigo (sin archivos externos; procedencia: obra propia del proyecto).
## v2 (2026-10-10): sintesis por CAPAS (click + chasquido filtrado + golpe grave + cola con reverb + saturacion) en vez de un
## oscilador con ruido; 32 kHz; cada sonido clave tiene 2-3 variantes ("nombre~1", "nombre~2") y AudioMgr rota entre ellas.
## REGLA ANDROID: los loops usan loop_end = size - 1. Con loop_end == size el mezclador de Android hace SIGSEGV
## en el hilo de AudioTrack. No cambiar (cubierto por tests/test_audio_bank.gd). Version anterior: asset_bank/reserve/audio_legacy/.

const RATE := Synth.RATE

## Sonidos con variantes (cantidad total, incluida la base).
const VARIANTS := {
	"smg": 3, "pistol": 3, "rifle": 3, "maul": 2, "minigun": 3, "hit": 3, "tink": 2, "wall": 2, "slash": 3, "claws": 3,
	"step": 3, "break": 2, "coin": 2, "bolt": 2, "zap": 2, "plasma": 2, "swarm": 2, "rocket": 2, "bounce": 3,
}


## Nombre -> Callable que devuelve un AudioStreamWAV. Las variantes se registran como "nombre~N".
static func recipes() -> Dictionary:
	var base := {
		# armas
		"smg": _smg, "pistol": _pistol, "rifle": _rifle, "maul": _maul, "minigun": _minigun, "rail": _rail, "sniper": _sniper,
		"plasma": _plasma, "grenade": _grenade, "rocket": _rocket, "swarm": _swarm, "anomaly": _anomaly, "railbeam": _railbeam,
		"zap": _zap, "bounce": _bounce, "flame": _flame, "slash": _slash, "claws": _claws, "bolt": _bolt,
		# impactos y mundo
		"hit": _hit, "tink": _tink, "wall": _wall, "break": _break, "boom": _boom, "slam": _slam, "stomp": _stomp, "thump": _thump,
		"reflect": _reflect, "step": _step,
		# criaturas
		"die": func(v: int): return _die(v, false), "die_big": func(v: int): return _die(v, true), "roar": _roar, "spawn": _spawn,
		"wind": _windup, "charge": _charge, "drone": _drone,
		# jugador
		"hurt": _hurt, "player_die": _player_die, "shield_break": _shield_break, "shield_hit": _shield_hit, "ability": _ability,
		"heal": _heal, "swap": _swap, "empty": _empty, "pickup": _pickup,
		# progresion / interfaz
		"coin": _coin, "chest": _chest, "perk": _perk, "reward": _reward, "levelup": _levelup, "victory": _victory, "defeat": _defeat,
		"clear": _clear, "wave": _wave, "tick": _tick,
		"ui_click": _ui_click, "ui_back": _ui_back, "ui_open": _ui_open, "ui_confirm": _ui_confirm, "ui_error": _ui_error,
		"hum": _hum,
	}
	var out := {}
	for k in base:
		var fn: Callable = base[k]
		var nv: int = VARIANTS.get(k, 1)
		for v in nv:
			var key: String = k if v == 0 else "%s~%d" % [k, v]
			var vv := v
			out[key] = func(): return fn.call(vv)
	return out


static func _wav(s: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	return Synth.to_wav(s, loop)


## Utilidad: ruido filtrado con envolvente.
static func _nz(dur: float, kind: int, fc: float, q: float, attack: float, k: float, fc1: float = -1.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var x := Synth.noise(n)
	x = Synth.svf(x, fc, fc if fc1 < 0.0 else fc1, q, kind, RATE)
	return Synth.mul(x, Synth.env(n, attack, k))


static func _jit(v: int, amt: float = 0.08) -> float:
	return 1.0 + (Synth.rng.randf() - 0.5) * amt * 2.0 * (1.0 if v > 0 else 0.4)


## Disparo por capas. p: dur, click, crack{f,q,k,g}, thump{f0,f1,k,g}, tail{f,k,g}, zip{f0,f1,k,g,shape}, rev{size,decay,wet,tail}, drive, peak.
static func _gun(name: String, v: int, p: Dictionary) -> AudioStreamWAV:
	Synth.seed_with(name, v)
	var dur: float = p["dur"]
	var n := int(dur * RATE)
	var out := Synth.buf(dur)
	var j := _jit(v)
	var cl: float = p.get("click", 0.5)
	if cl > 0.0:
		var c := Synth.hp(_nz(0.006, 0, 1000.0, 0.7, 0.0002, 700.0), 1800.0)
		Synth.mix(out, c, 0.0, cl)
	var cr: Dictionary = p.get("crack", {})
	if not cr.is_empty():
		var c2 := _nz(dur, 2, float(cr["f"]) * j, float(cr.get("q", 1.2)), 0.0003, float(cr["k"]))
		Synth.mix(out, c2, 0.0, float(cr["g"]))
	var th: Dictionary = p.get("thump", {})
	if not th.is_empty():
		var t := Synth.sweep(n, float(th["f0"]) * j, float(th["f1"]), float(th["k"]) * 0.6, RATE)
		t = Synth.mul(t, Synth.env(n, 0.0008, float(th["k"])))
		Synth.mix(out, t, 0.0, float(th["g"]))
	var tl: Dictionary = p.get("tail", {})
	if not tl.is_empty():
		var t2 := _nz(dur, 0, float(tl["f"]) * j, 0.8, 0.004, float(tl["k"]), float(tl["f"]) * 0.35)
		Synth.mix(out, t2, 0.0, float(tl["g"]))
	var zp: Dictionary = p.get("zip", {})
	if not zp.is_empty():
		var z := Synth.sweep(n, float(zp["f0"]) * j, float(zp["f1"]), float(zp["k"]), RATE, int(zp.get("shape", 0)))
		z = Synth.mul(z, Synth.env(n, 0.0005, float(zp.get("ek", zp["k"]))))
		Synth.mix(out, z, 0.0, float(zp["g"]))
	var rv: Dictionary = p.get("rev", {})
	if not rv.is_empty():
		out = Synth.reverb(out, float(rv["size"]), float(rv["decay"]), float(rv["wet"]), float(rv.get("tail", 0.1)))
	return _wav(Synth.finalize(out, float(p.get("peak", 0.55)), float(p.get("drive", 1.8))))


static func _pistol(v: int) -> AudioStreamWAV:
	return _gun("pistol", v, {"dur": 0.24, "click": 0.6, "crack": {"f": 2600.0, "q": 1.1, "k": 38.0, "g": 1.0},
		"thump": {"f0": 230.0, "f1": 85.0, "k": 34.0, "g": 0.9}, "tail": {"f": 1400.0, "k": 16.0, "g": 0.35},
		"zip": {"f0": 3200.0, "f1": 900.0, "k": 55.0, "g": 0.25}, "rev": {"size": 0.7, "decay": 0.55, "wet": 0.22, "tail": 0.12}, "drive": 2.2})


static func _smg(v: int) -> AudioStreamWAV:   # PULSAR: pulso energetico corto
	return _gun("smg", v, {"dur": 0.15, "click": 0.5, "crack": {"f": 3400.0, "q": 1.4, "k": 55.0, "g": 0.9},
		"thump": {"f0": 190.0, "f1": 90.0, "k": 45.0, "g": 0.85}, "zip": {"f0": 2600.0, "f1": 700.0, "k": 38.0, "g": 0.45, "shape": 3, "ek": 30.0},
		"drive": 2.0})


static func _rifle(v: int) -> AudioStreamWAV:   # TRINCA: fusil de ritmo marcado
	return _gun("rifle", v, {"dur": 0.2, "click": 0.55, "crack": {"f": 2100.0, "q": 1.0, "k": 30.0, "g": 1.0},
		"thump": {"f0": 170.0, "f1": 60.0, "k": 26.0, "g": 1.0}, "tail": {"f": 1100.0, "k": 20.0, "g": 0.3},
		"rev": {"size": 0.6, "decay": 0.5, "wet": 0.18, "tail": 0.08}, "drive": 2.4})


static func _minigun(v: int) -> AudioStreamWAV:   # MASTIN: golpes graves repetibles
	return _gun("minigun", v, {"dur": 0.11, "click": 0.35, "crack": {"f": 1500.0, "q": 0.9, "k": 48.0, "g": 0.8},
		"thump": {"f0": 140.0, "f1": 55.0, "k": 40.0, "g": 1.2}, "drive": 2.6})


static func _maul(v: int) -> AudioStreamWAV:   # escopeta
	return _gun("maul", v, {"dur": 0.55, "click": 0.8, "crack": {"f": 1000.0, "q": 0.55, "k": 14.0, "g": 1.1},
		"thump": {"f0": 120.0, "f1": 38.0, "k": 11.0, "g": 1.5}, "tail": {"f": 900.0, "k": 7.5, "g": 0.55},
		"rev": {"size": 1.1, "decay": 0.62, "wet": 0.3, "tail": 0.25}, "peak": 0.7, "drive": 2.8})


static func _sniper(v: int) -> AudioStreamWAV:   # AGUJA: latigazo + resonancia metalica
	var s := _gun("sniper", v, {"dur": 0.75, "click": 0.9, "crack": {"f": 3600.0, "q": 1.3, "k": 26.0, "g": 1.2},
		"thump": {"f0": 150.0, "f1": 52.0, "k": 12.0, "g": 1.0}, "tail": {"f": 1800.0, "k": 5.0, "g": 0.5},
		"zip": {"f0": 2400.0, "f1": 1500.0, "k": 4.0, "ek": 6.5, "g": 0.1}, "rev": {"size": 1.3, "decay": 0.68, "wet": 0.34, "tail": 0.4}, "peak": 0.68, "drive": 2.4})
	return s


static func _rail(v: int) -> AudioStreamWAV:   # LANCE-X: aceleracion electromagnetica
	Synth.seed_with("rail", v)
	var n := int(0.5 * RATE)
	var out := Synth.buf(0.5)
	var sw := Synth.sweep(n, 3200.0, 240.0, 9.0, RATE, 1)
	sw = Synth.lp(sw, 3500.0, 0.9)
	Synth.mix(out, Synth.mul(sw, Synth.env(n, 0.0004, 8.0)), 0.0, 0.7)
	var ring := Synth.sweep(n, 900.0 * _jit(v), 880.0, 1.0)
	Synth.mix(out, Synth.mul(ring, Synth.env(n, 0.001, 6.0)), 0.0, 0.35)
	Synth.mix(out, Synth.hp(_nz(0.02, 0, 1000.0, 0.7, 0.0002, 160.0), 1500.0), 0.0, 1.0)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 110.0, 48.0, 14.0), Synth.env(n, 0.001, 14.0)), 0.0, 0.9)
	out = Synth.reverb(out, 0.9, 0.55, 0.22, 0.2)
	return _wav(Synth.finalize(out, 0.62, 2.2))


static func _plasma(v: int) -> AudioStreamWAV:   # GOTA: glóbulo burbujeante
	Synth.seed_with("plasma", v)
	var n := int(0.32 * RATE)
	var out := Synth.buf(0.32)
	var f0 := 520.0 * _jit(v)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 160.0 + (f0 - 160.0) * exp(-t * 9.0) + sin(t * 70.0) * 60.0 * exp(-t * 6.0)
		ph += f / RATE
		out[i] = sin(TAU * ph + sin(TAU * ph * 2.0) * 1.4 * exp(-t * 10.0)) * exp(-t * 11.0)
	Synth.mix(out, _nz(0.2, 2, 1100.0, 3.0, 0.002, 18.0, 300.0), 0.0, 0.7)
	Synth.mix(out, Synth.hp(_nz(0.01, 0, 1000.0, 0.7, 0.0003, 400.0), 2000.0), 0.0, 0.5)
	return _wav(Synth.finalize(Synth.reverb(out, 0.7, 0.45, 0.18, 0.1), 0.55, 1.8))


static func _grenade(v: int) -> AudioStreamWAV:   # POMELO: tubo + empuje
	Synth.seed_with("grenade", v)
	var n := int(0.42 * RATE)
	var out := Synth.buf(0.42)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 140.0, 55.0, 16.0), Synth.env(n, 0.001, 12.0)), 0.0, 1.3)
	Synth.mix(out, _nz(0.3, 2, 330.0, 4.0, 0.001, 14.0), 0.0, 0.9)      # resonancia del tubo
	Synth.mix(out, _nz(0.2, 2, 1200.0, 0.8, 0.0008, 22.0, 400.0), 0.0, 0.7)
	Synth.mix(out, Synth.hp(_nz(0.01, 0, 1000.0, 0.7, 0.0003, 400.0), 1200.0), 0.0, 0.6)
	return _wav(Synth.finalize(Synth.reverb(out, 0.9, 0.55, 0.22, 0.15), 0.62, 2.4))


static func _rocket(v: int) -> AudioStreamWAV:   # COLMENA: silbido de micro-misil
	Synth.seed_with("rocket", v)
	var n := int(0.4 * RATE)
	var out := Synth.buf(0.4)
	var w := Synth.svf(Synth.noise(n), 500.0, 2800.0 * _jit(v), 1.6, 2, RATE)
	Synth.mix(out, Synth.mul(w, Synth.env(n, 0.012, 6.0)), 0.0, 0.9)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 120.0, 60.0, 12.0), Synth.env(n, 0.001, 14.0)), 0.0, 0.8)
	Synth.mix(out, Synth.hp(_nz(0.01, 0, 1000.0, 0.7, 0.0003, 400.0), 1500.0), 0.0, 0.5)
	return _wav(Synth.finalize(out, 0.5, 1.6))


static func _swarm(v: int) -> AudioStreamWAV:   # ENJAMBRE: zumbido de drones al soltarse
	Synth.seed_with("swarm", v)
	var n := int(0.36 * RATE)
	var out := Synth.buf(0.36)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += (210.0 + 90.0 * t + sin(t * 55.0) * 14.0) * _jit(0, 0.02) / RATE
		var saw := fmod(ph, 1.0) * 2.0 - 1.0
		out[i] = saw * (0.6 + 0.4 * sin(TAU * 42.0 * t)) * exp(-t * 6.0)
	out = Synth.lp(out, 1800.0, 1.1)
	Synth.mix(out, _nz(0.12, 2, 2400.0, 2.0, 0.003, 20.0), 0.0, 0.5)
	return _wav(Synth.finalize(out, 0.5, 1.8))


static func _anomaly(v: int) -> AudioStreamWAV:   # ANOMALIA: glitch FM aplastado
	Synth.seed_with("anomaly", v)
	var n := int(0.3 * RATE)
	var out := Synth.buf(0.3)
	var ph := 0.0
	var mod := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 420.0 * (1.0 + 2.0 * floorf(t * 38.0 + 0.5) * 0.12) * exp(-t * 3.0)
		ph += f / RATE
		mod += (f * 3.01) / RATE
		out[i] = sin(TAU * ph + sin(TAU * mod) * 2.4 * exp(-t * 8.0)) * exp(-t * 9.0)
	out = Synth.crush(out, 6, 3)
	Synth.mix(out, Synth.hp(_nz(0.03, 0, 1000.0, 0.7, 0.0003, 120.0), 2500.0), 0.0, 0.6)
	return _wav(Synth.finalize(Synth.reverb(out, 0.8, 0.5, 0.2, 0.12), 0.52, 1.8))


static func _railbeam(v: int) -> AudioStreamWAV:   # RIEL-Q: haz que atraviesa todo
	Synth.seed_with("railbeam", v)
	var n := int(1.0 * RATE)
	var out := Synth.buf(1.0)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 90.0, 34.0, 4.0), Synth.env(n, 0.002, 4.5)), 0.0, 1.4)
	Synth.mix(out, Synth.mul(Synth.lp(Synth.sweep(n, 4200.0, 180.0, 5.5, RATE, 1), 4200.0), Synth.env(n, 0.001, 5.0)), 0.0, 0.8)
	Synth.mix(out, _nz(0.5, 0, 2500.0, 0.8, 0.001, 8.0, 500.0), 0.0, 0.9)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 1500.0, 1480.0, 1.0), Synth.env(n, 0.002, 3.0)), 0.0, 0.18)
	Synth.mix(out, Synth.hp(_nz(0.02, 0, 1000.0, 0.7, 0.0002, 100.0), 1200.0), 0.0, 1.0)
	return _wav(Synth.finalize(Synth.reverb(out, 1.3, 0.7, 0.35, 0.5), 0.75, 2.6, 0.02))


static func _zap(v: int) -> AudioStreamWAV:   # RELAMPAGO: arco crepitante
	Synth.seed_with("zap", v)
	var n := int(0.28 * RATE)
	var out := Synth.buf(0.28)
	var gate := 0.0
	for i in n:
		var t := float(i) / RATE
		if i % 220 == 0:
			gate = Synth.rng.randf()
		out[i] = (Synth.rng.randf() * 2.0 - 1.0) * (0.35 + gate) * exp(-t * 9.0)
	out = Synth.svf(out, 900.0, 7000.0, 1.0, 1, RATE)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += (95.0 + 40.0 * sin(t * 30.0)) / RATE
		out[i] += (fmod(ph, 1.0) * 2.0 - 1.0) * 0.35 * exp(-t * 11.0)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 2800.0 * _jit(v), 600.0, 30.0), Synth.env(n, 0.0005, 30.0)), 0.0, 0.4)
	return _wav(Synth.finalize(out, 0.5, 2.0))


static func _bounce(v: int) -> AudioStreamWAV:   # REBOTE: pew elastico
	Synth.seed_with("bounce", v)
	var n := int(0.2 * RATE)
	var out := Synth.buf(0.2)
	var ph := 0.0
	var f0 := 1500.0 * _jit(v)
	for i in n:
		var t := float(i) / RATE
		var f := 420.0 + (f0 - 420.0) * exp(-t * 20.0) * (1.0 + 0.2 * sin(t * 140.0))
		ph += f / RATE
		out[i] = (sin(TAU * ph) * 0.8 + sin(TAU * ph * 2.0) * 0.2) * exp(-t * 17.0)
	Synth.mix(out, Synth.hp(_nz(0.008, 0, 1000.0, 0.7, 0.0002, 300.0), 2500.0), 0.0, 0.4)
	return _wav(Synth.finalize(Synth.delay(out, 0.045, 0.35, 0.4), 0.5, 1.4))


static func _flame(v: int) -> AudioStreamWAV:   # BRASERO: soplido corto apto para repeticion rapida
	Synth.seed_with("flame", v)
	var n := int(0.2 * RATE)
	var x := Synth.noise(n)
	var o := Synth.svf(x, 380.0, 1500.0, 0.9, 2, RATE)
	var fl := PackedFloat32Array()
	fl.resize(n)
	for i in n:
		var t := float(i) / RATE
		fl[i] = o[i] * (0.65 + 0.35 * sin(t * 90.0 + float(i % 7))) * minf(1.0, t * 90.0) * exp(-t * 7.0)
	Synth.mix(fl, Synth.mul(Synth.sweep(n, 70.0, 55.0, 2.0), Synth.env(n, 0.003, 12.0)), 0.0, 0.5)
	return _wav(Synth.finalize(fl, 0.45, 1.5))


static func _slash(v: int) -> AudioStreamWAV:   # FILO-Z: tajo largo de hoja de energia
	Synth.seed_with("slash", v)
	var n := int(0.3 * RATE)
	var out := Synth.buf(0.3)
	var w := Synth.svf(Synth.noise(n), 700.0, 4200.0 * _jit(v), 1.7, 2, RATE)
	var sh := PackedFloat32Array()
	sh.resize(n)
	for i in n:
		var t := float(i) / RATE
		sh[i] = w[i] * sin(minf(t / 0.2, 1.0) * PI * 0.5) * exp(-t * 7.0)
	Synth.mix(out, sh, 0.0, 1.0)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 2300.0, 2250.0, 1.0), Synth.env(n, 0.02, 9.0)), 0.04, 0.12)   # filo vibrando
	Synth.mix(out, Synth.mul(Synth.sweep(n, 210.0, 90.0, 20.0), Synth.env(n, 0.002, 18.0)), 0.0, 0.4)
	return _wav(Synth.finalize(out, 0.5, 1.5))


static func _claws(v: int) -> AudioStreamWAV:   # GARRA: dos cortes rapidos
	Synth.seed_with("claws", v)
	var out := Synth.buf(0.2)
	for k in 2:
		var n := int(0.09 * RATE)
		var w := Synth.svf(Synth.noise(n), 1800.0, 6200.0, 1.6, 2, RATE)
		Synth.mix(out, Synth.mul(w, Synth.env(n, 0.003, 30.0)), 0.0 + k * 0.055 * _jit(v, 0.2), 0.8 - 0.2 * k)
	Synth.mix(out, Synth.hp(_nz(0.01, 0, 1000.0, 0.7, 0.0002, 300.0), 3000.0), 0.0, 0.3)
	return _wav(Synth.finalize(out, 0.42, 1.4))


static func _bolt(v: int) -> AudioStreamWAV:   # proyectil de energia generico (enemigos y armas de plasma)
	Synth.seed_with("bolt", v)
	var n := int(0.3 * RATE)
	var out := Synth.buf(0.3)
	var ph := 0.0
	var f0 := 1100.0 * _jit(v)
	for i in n:
		var t := float(i) / RATE
		ph += (180.0 + (f0 - 180.0) * exp(-t * 12.0)) / RATE
		out[i] = (fmod(ph, 1.0) * 2.0 - 1.0) * 0.5 + sin(TAU * ph * 0.5) * 0.4
		out[i] *= exp(-t * 12.0)
	out = Synth.lp(out, 3000.0, 1.0)
	Synth.mix(out, Synth.hp(_nz(0.01, 0, 1000.0, 0.7, 0.0003, 300.0), 2200.0), 0.0, 0.35)
	return _wav(Synth.finalize(Synth.delay(out, 0.05, 0.3, 0.3), 0.5, 1.6))


# ------------------------------------------------------------------ impactos y mundo
static func _hit(v: int) -> AudioStreamWAV:   # impacto en enemigo: golpe seco con chasquido
	Synth.seed_with("hit", v)
	var n := int(0.13 * RATE)
	var out := Synth.buf(0.13)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 260.0 * _jit(v), 90.0, 40.0), Synth.env(n, 0.0005, 38.0)), 0.0, 1.0)
	Synth.mix(out, _nz(0.1, 2, 1700.0, 1.2, 0.0004, 60.0), 0.0, 0.7)
	Synth.mix(out, Synth.hp(_nz(0.005, 0, 1000.0, 0.7, 0.0002, 800.0), 2500.0), 0.0, 0.4)
	return _wav(Synth.finalize(out, 0.5, 2.0))


static func _tink(v: int) -> AudioStreamWAV:   # golpe contra armadura/metal
	Synth.seed_with("tink", v)
	var n := int(0.32 * RATE)
	var out := Synth.buf(0.32)
	var base := 1180.0 * _jit(v, 0.1)
	for pr in [[1.0, 1.0, 20.0], [1.58, 0.7, 26.0], [2.41, 0.5, 34.0], [3.9, 0.3, 48.0]]:
		Synth.mix(out, Synth.mul(Synth.sweep(n, base * float(pr[0]), base * float(pr[0]), 1.0), Synth.env(n, 0.0004, float(pr[2]))), 0.0, float(pr[1]))
	Synth.mix(out, Synth.hp(_nz(0.01, 0, 1000.0, 0.7, 0.0002, 400.0), 3000.0), 0.0, 0.5)
	return _wav(Synth.finalize(Synth.reverb(out, 0.5, 0.4, 0.15, 0.08), 0.42, 1.3))


static func _wall(v: int) -> AudioStreamWAV:   # bala contra muro: chasquido sordo
	Synth.seed_with("wall", v)
	var out := _nz(0.09, 0, 2400.0 * _jit(v), 0.8, 0.0003, 70.0, 700.0)
	Synth.mix(out, Synth.mul(Synth.sweep(out.size(), 180.0, 90.0, 40.0), Synth.env(out.size(), 0.0005, 50.0)), 0.0, 0.5)
	return _wav(Synth.finalize(out, 0.4, 1.6))


static func _break(v: int) -> AudioStreamWAV:   # caja/barril se rompe
	Synth.seed_with("break", v)
	var out := Synth.buf(0.45)
	Synth.mix(out, _nz(0.4, 2, 1300.0, 0.7, 0.0005, 9.0, 450.0), 0.0, 0.9)
	Synth.mix(out, Synth.mul(Synth.sweep(out.size(), 170.0, 60.0, 14.0), Synth.env(out.size(), 0.001, 12.0)), 0.0, 1.0)
	for k in 5:                                # astillas
		var f := Synth.rng.randf_range(1800.0, 4800.0)
		Synth.mix(out, Synth.hp(_nz(0.02, 0, f, 0.9, 0.0003, 120.0), f), Synth.rng.randf_range(0.02, 0.2), 0.4)
	return _wav(Synth.finalize(Synth.reverb(out, 0.7, 0.45, 0.16, 0.1), 0.6, 1.9))


static func _boom(v: int) -> AudioStreamWAV:   # explosion grande
	Synth.seed_with("boom", v)
	var n := int(1.3 * RATE)
	var out := Synth.buf(1.3)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 100.0, 30.0, 3.0), Synth.env(n, 0.003, 3.2)), 0.0, 1.5)
	Synth.mix(out, Synth.mul(Synth.svf(Synth.noise(n), 3500.0, 160.0, 0.9, 0, RATE), Synth.env(n, 0.002, 3.6)), 0.0, 1.0)
	Synth.mix(out, Synth.hp(_nz(0.03, 0, 1000.0, 0.7, 0.0002, 90.0), 900.0), 0.0, 0.8)
	Synth.mix(out, Synth.mul(Synth.lp(Synth.noise(n), 220.0, 1.0), Synth.env(n, 0.05, 2.2)), 0.0, 0.8)   # retumbo
	return _wav(Synth.finalize(Synth.reverb(out, 1.4, 0.72, 0.3, 0.45), 0.8, 2.6, 0.03))


static func _slam(v: int) -> AudioStreamWAV:   # golpe de jefe contra el suelo
	Synth.seed_with("slam", v)
	var n := int(0.85 * RATE)
	var out := Synth.buf(0.85)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 88.0, 28.0, 6.0), Synth.env(n, 0.002, 5.0)), 0.0, 1.5)
	Synth.mix(out, Synth.mul(Synth.lp(Synth.noise(n), 700.0, 0.9), Synth.env(n, 0.001, 8.0)), 0.0, 1.2)
	Synth.mix(out, Synth.hp(_nz(0.02, 0, 1000.0, 0.7, 0.0002, 90.0), 1800.0), 0.0, 0.5)
	return _wav(Synth.finalize(Synth.reverb(out, 1.0, 0.6, 0.25, 0.3), 0.75, 2.4))


static func _stomp(v: int) -> AudioStreamWAV:   # pisada pesada
	Synth.seed_with("stomp", v)
	var n := int(0.4 * RATE)
	var out := Synth.buf(0.4)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 78.0, 38.0, 12.0), Synth.env(n, 0.002, 9.0)), 0.0, 1.3)
	Synth.mix(out, Synth.mul(Synth.lp(Synth.noise(n), 500.0, 0.8), Synth.env(n, 0.001, 18.0)), 0.0, 0.9)
	return _wav(Synth.finalize(out, 0.65, 2.0))


static func _thump(v: int) -> AudioStreamWAV:
	Synth.seed_with("thump", v)
	var n := int(0.3 * RATE)
	var out := Synth.mul(Synth.sweep(n, 110.0, 42.0, 16.0), Synth.env(n, 0.002, 12.0))
	Synth.mix(out, Synth.mul(Synth.lp(Synth.noise(n), 400.0, 0.9), Synth.env(n, 0.001, 30.0)), 0.0, 0.6)
	return _wav(Synth.finalize(out, 0.6, 1.8))


static func _reflect(v: int) -> AudioStreamWAV:   # proyectil desviado por la hoja
	Synth.seed_with("reflect", v)
	var n := int(0.28 * RATE)
	var out := Synth.buf(0.28)
	for pr in [[1.0, 1.0, 14.0], [1.5, 0.6, 18.0], [2.76, 0.4, 26.0]]:
		Synth.mix(out, Synth.mul(Synth.sweep(n, 1500.0 * float(pr[0]), 1900.0 * float(pr[0]), 14.0), Synth.env(n, 0.0004, float(pr[2]))), 0.0, float(pr[1]))
	Synth.mix(out, Synth.hp(_nz(0.01, 0, 1000.0, 0.7, 0.0002, 300.0), 2800.0), 0.0, 0.5)
	return _wav(Synth.finalize(Synth.delay(out, 0.04, 0.4, 0.35), 0.5, 1.4))


static func _step(v: int) -> AudioStreamWAV:
	Synth.seed_with("step", v)
	var out := _nz(0.08, 0, 900.0 * _jit(v, 0.25), 0.8, 0.001, 45.0, 300.0)
	Synth.mix(out, Synth.hp(_nz(0.01, 0, 1000.0, 0.7, 0.0002, 200.0), 2500.0), 0.0, 0.12)
	return _wav(Synth.finalize(out, 0.22, 1.2))


# ------------------------------------------------------------------ criaturas
static func _die(v: int, big: bool) -> AudioStreamWAV:   # muerte de enemigo: chasquido + caida de tono + polvo
	var nm := "die_big" if big else "die"
	Synth.seed_with(nm, v)
	var dur := 1.0 if big else 0.5
	var n := int(dur * RATE)
	var out := Synth.buf(dur)
	var f0 := 240.0 if big else 520.0
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += (f0 * exp(-t * (4.5 if big else 8.0)) + 38.0) / RATE
		out[i] = (fmod(ph, 1.0) * 2.0 - 1.0) * exp(-t * (4.0 if big else 9.0))
	out = Synth.lp(out, 1800.0, 1.0)
	Synth.mix(out, _nz(dur * 0.8, 2, 1400.0, 0.9, 0.001, 6.0 if big else 11.0, 300.0), 0.0, 0.8)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 120.0, 40.0, 7.0), Synth.env(n, 0.002, 6.0)), 0.0, 1.1 if big else 0.6)
	Synth.mix(out, Synth.hp(_nz(0.02, 0, 1000.0, 0.7, 0.0002, 160.0), 1500.0), 0.0, 0.6)
	return _wav(Synth.finalize(Synth.reverb(out, 0.9, 0.55, 0.2, 0.2), 0.62 if big else 0.52, 2.0, 0.02))


static func _roar(v: int) -> AudioStreamWAV:   # rugido de jefe: sierra grave + formantes + vibrato
	Synth.seed_with("roar", v)
	var n := int(1.1 * RATE)
	var src := PackedFloat32Array()
	src.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := (62.0 + 34.0 * sin(minf(t / 0.5, 1.0) * PI * 0.5) - 14.0 * maxf(0.0, t - 0.6)) * (1.0 + 0.02 * sin(t * 38.0))
		ph += f / RATE
		src[i] = (fmod(ph, 1.0) * 2.0 - 1.0) + (Synth.rng.randf() * 2.0 - 1.0) * 0.28
	var f1 := Synth.bp(src, 520.0, 2.4)
	var f2 := Synth.bp(src, 1250.0, 2.0)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		out[i] = (f1[i] * 1.0 + f2[i] * 0.6 + src[i] * 0.15) * sin(minf(t / 0.12, 1.0) * PI * 0.5) * exp(-maxf(0.0, t - 0.4) * 2.6)
	return _wav(Synth.finalize(Synth.reverb(out, 1.1, 0.6, 0.22, 0.3), 0.7, 2.8, 0.05))


static func _spawn(v: int) -> AudioStreamWAV:   # aparicion/teletransporte de un enemigo
	Synth.seed_with("spawn", v)
	var n := int(0.55 * RATE)
	var out := Synth.buf(0.55)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += (180.0 + 1300.0 * t * t * 3.0) / RATE
		out[i] = sin(TAU * ph + sin(TAU * 11.0 * t) * 2.0) * sin(minf(t / 0.5, 1.0) * PI) * 0.8
	Synth.mix(out, _nz(0.4, 2, 2400.0, 2.5, 0.12, 5.0, 5200.0), 0.05, 0.5)
	Synth.mix(out, Synth.hp(_nz(0.02, 0, 1000.0, 0.7, 0.0002, 120.0), 1500.0), 0.5, 0.3)
	return _wav(Synth.finalize(Synth.reverb(out, 0.9, 0.55, 0.22, 0.2), 0.45, 1.5, 0.03))


static func _windup(v: int) -> AudioStreamWAV:   # aviso de ataque (carga): subida corta y tensa
	Synth.seed_with("wind", v)
	var n := int(0.5 * RATE)
	var out := Synth.buf(0.5)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / 0.5
		ph += (140.0 + 900.0 * k * k) / RATE
		out[i] = (fmod(ph, 1.0) * 2.0 - 1.0) * 0.5 * minf(1.0, k * 6.0) * (1.0 - pow(k, 10.0)) * (0.7 + 0.3 * sin(TAU * (12.0 + 30.0 * k) * t))
	out = Synth.svf(out, 500.0, 3200.0, 1.2, 0, RATE)
	Synth.mix(out, _nz(0.45, 2, 1200.0, 2.0, 0.1, 3.0, 4000.0), 0.0, 0.25)
	return _wav(Synth.finalize(out, 0.42, 1.4, 0.03))


static func _charge(v: int) -> AudioStreamWAV:   # carga de un ataque pesado (jefe)
	Synth.seed_with("charge", v)
	var n := int(0.8 * RATE)
	var out := Synth.buf(0.8)
	var ph := 0.0
	var ph2 := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / 0.8
		var f := 90.0 + 640.0 * pow(k, 1.7)
		ph += f / RATE
		ph2 += f * 1.505 / RATE
		out[i] = (sin(TAU * ph) * 0.6 + (fmod(ph2, 1.0) * 2.0 - 1.0) * 0.3) * minf(1.0, k * 5.0) * (1.0 - pow(k, 12.0)) * (0.75 + 0.25 * sin(TAU * (8.0 + 22.0 * k) * t))
	Synth.mix(out, _nz(0.7, 2, 900.0, 1.8, 0.2, 2.0, 5000.0), 0.0, 0.3)
	return _wav(Synth.finalize(Synth.reverb(out, 0.9, 0.5, 0.18, 0.15), 0.5, 1.5, 0.03))


static func _drone(v: int) -> AudioStreamWAV:   # zumbido de dron enemigo
	Synth.seed_with("drone", v)
	var n := int(0.4 * RATE)
	var out := Synth.buf(0.4)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += (260.0 + 20.0 * sin(t * 30.0)) / RATE
		out[i] = (fmod(ph, 1.0) * 2.0 - 1.0) * (0.55 + 0.45 * sin(TAU * 55.0 * t)) * sin(minf(t / 0.4, 1.0) * PI)
	return _wav(Synth.finalize(Synth.lp(out, 2200.0, 1.0), 0.4, 1.4, 0.03))


# ------------------------------------------------------------------ jugador
static func _hurt(v: int) -> AudioStreamWAV:   # recibir daño: impacto grave + quejido corto
	Synth.seed_with("hurt", v)
	var n := int(0.32 * RATE)
	var out := Synth.buf(0.32)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 180.0, 70.0, 18.0), Synth.env(n, 0.001, 14.0)), 0.0, 1.2)
	Synth.mix(out, _nz(0.2, 2, 1100.0, 0.9, 0.001, 22.0, 400.0), 0.0, 0.8)
	var ph := 0.0
	var vow := PackedFloat32Array()
	vow.resize(n)
	for i in n:
		var t := float(i) / RATE
		ph += (210.0 - 90.0 * t) / RATE
		vow[i] = (fmod(ph, 1.0) * 2.0 - 1.0) * exp(-t * 9.0)
	Synth.mix(out, Synth.bp(vow, 700.0, 2.2), 0.01, 0.9)
	return _wav(Synth.finalize(out, 0.6, 2.0))


static func _player_die(v: int) -> AudioStreamWAV:
	Synth.seed_with("player_die", v)
	var n := int(1.4 * RATE)
	var out := Synth.buf(1.4)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 220.0, 38.0, 2.6, RATE, 1), Synth.env(n, 0.01, 2.0)), 0.0, 0.5)
	out = Synth.svf(out, 2400.0, 160.0, 0.9, 0, RATE)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 90.0, 30.0, 4.0), Synth.env(n, 0.002, 3.0)), 0.0, 1.2)
	Synth.mix(out, _nz(0.6, 2, 1300.0, 1.0, 0.002, 6.0, 300.0), 0.0, 0.6)
	return _wav(Synth.finalize(Synth.reverb(out, 1.2, 0.65, 0.3, 0.4), 0.65, 2.0, 0.05))


static func _shield_hit(v: int) -> AudioStreamWAV:   # escudo absorbe: zumbido electrico
	Synth.seed_with("shield_hit", v)
	var n := int(0.22 * RATE)
	var out := Synth.buf(0.22)
	for pr in [[1.0, 1.0, 18.0], [1.5, 0.5, 22.0], [2.0, 0.4, 28.0]]:
		Synth.mix(out, Synth.mul(Synth.sweep(n, 760.0 * float(pr[0]), 520.0 * float(pr[0]), 16.0), Synth.env(n, 0.0005, float(pr[2]))), 0.0, float(pr[1]))
	Synth.mix(out, Synth.hp(_nz(0.1, 0, 1000.0, 0.7, 0.0003, 40.0), 3200.0), 0.0, 0.5)
	return _wav(Synth.finalize(out, 0.5, 1.6))


static func _shield_break(v: int) -> AudioStreamWAV:   # cristal que estalla
	Synth.seed_with("shield_break", v)
	var n := int(0.7 * RATE)
	var out := Synth.buf(0.7)
	Synth.mix(out, Synth.hp(_nz(0.35, 0, 1000.0, 0.7, 0.0003, 10.0), 2800.0), 0.0, 1.0)
	for k in 9:
		var f := Synth.rng.randf_range(2400.0, 7000.0)
		Synth.mix(out, Synth.mul(Synth.sweep(int(0.15 * RATE), f, f, 1.0), Synth.env(int(0.15 * RATE), 0.0003, 28.0)), Synth.rng.randf_range(0.0, 0.25), 0.28)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 520.0, 130.0, 6.0), Synth.env(n, 0.001, 8.0)), 0.0, 0.7)
	return _wav(Synth.finalize(Synth.reverb(out, 0.8, 0.55, 0.28, 0.25), 0.55, 1.6, 0.03))


static func _ability(v: int) -> AudioStreamWAV:   # habilidad: barrido ascendente + estallido
	Synth.seed_with("ability", v)
	var n := int(0.6 * RATE)
	var out := Synth.buf(0.6)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += (220.0 + 1400.0 * pow(t / 0.6, 2.0)) / RATE
		out[i] = (sin(TAU * ph) * 0.6 + (fmod(ph * 2.0, 1.0) * 2.0 - 1.0) * 0.2) * sin(minf(t / 0.6, 1.0) * PI * 0.5) * exp(-maxf(0.0, t - 0.35) * 7.0)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 120.0, 50.0, 10.0), Synth.env(n, 0.001, 9.0)), 0.3, 0.9)
	Synth.mix(out, _nz(0.25, 2, 3000.0, 1.2, 0.001, 12.0), 0.3, 0.6)
	return _wav(Synth.finalize(Synth.reverb(out, 0.9, 0.55, 0.25, 0.2), 0.58, 1.7, 0.03))


static func _heal(v: int) -> AudioStreamWAV:   # curacion: arpegio brillante suave
	Synth.seed_with("heal", v)
	var out := Synth.buf(0.7)
	var notes := [523.25, 659.25, 783.99, 1046.5]
	for i in notes.size():
		var n := int(0.4 * RATE)
		var tone := Synth.mul(Synth.sweep(n, float(notes[i]), float(notes[i]), 1.0), Synth.env(n, 0.005, 7.0))
		var h2 := Synth.mul(Synth.sweep(n, float(notes[i]) * 2.0, float(notes[i]) * 2.0, 1.0), Synth.env(n, 0.005, 12.0))
		Synth.mix(out, tone, float(i) * 0.075, 0.55)
		Synth.mix(out, h2, float(i) * 0.075, 0.18)
	return _wav(Synth.finalize(Synth.reverb(out, 0.9, 0.55, 0.28, 0.25), 0.45, 1.2, 0.04))


static func _swap(v: int) -> AudioStreamWAV:   # cambio de arma: cerrojo mecanico
	Synth.seed_with("swap", v)
	var out := Synth.buf(0.2)
	Synth.mix(out, _nz(0.05, 2, 2200.0, 2.0, 0.0003, 70.0), 0.0, 0.9)
	Synth.mix(out, Synth.mul(Synth.sweep(1200, 700.0, 300.0, 30.0), Synth.env(1200, 0.0005, 60.0)), 0.0, 0.5)
	Synth.mix(out, _nz(0.06, 2, 3300.0, 2.5, 0.0003, 80.0), 0.075, 0.8)
	Synth.mix(out, Synth.mul(Synth.sweep(1200, 430.0, 200.0, 30.0), Synth.env(1200, 0.0005, 60.0)), 0.075, 0.6)
	return _wav(Synth.finalize(out, 0.42, 1.5))


static func _empty(v: int) -> AudioStreamWAV:   # sin energia: clic seco, nunca molesto
	Synth.seed_with("empty", v)
	var out := _nz(0.05, 2, 1800.0, 3.0, 0.0003, 90.0)
	Synth.mix(out, Synth.mul(Synth.sweep(900, 520.0, 380.0, 40.0), Synth.env(900, 0.0004, 70.0)), 0.0, 0.5)
	return _wav(Synth.finalize(out, 0.3, 1.3))


static func _pickup(v: int) -> AudioStreamWAV:
	Synth.seed_with("pickup", v)
	var out := Synth.buf(0.3)
	for i in 2:
		var f := 880.0 * (1.0 if i == 0 else 1.498)
		var n := int(0.2 * RATE)
		Synth.mix(out, Synth.mul(Synth.sweep(n, f, f, 1.0), Synth.env(n, 0.002, 14.0)), float(i) * 0.06, 0.6)
		Synth.mix(out, Synth.mul(Synth.sweep(n, f * 2.0, f * 2.0, 1.0), Synth.env(n, 0.002, 22.0)), float(i) * 0.06, 0.2)
	return _wav(Synth.finalize(out, 0.42, 1.2))


# ------------------------------------------------------------------ progresion
static func _coin(v: int) -> AudioStreamWAV:   # moneda: dos parciales inarmonicos brillantes
	Synth.seed_with("coin", v)
	var n := int(0.4 * RATE)
	var out := Synth.buf(0.4)
	var b := 1568.0 * _jit(v, 0.03)
	Synth.mix(out, Synth.mul(Synth.sweep(n, b, b, 1.0), Synth.env(n, 0.0008, 11.0)), 0.0, 0.55)
	Synth.mix(out, Synth.mul(Synth.sweep(n, b * 1.5, b * 1.5, 1.0), Synth.env(n, 0.0008, 9.0)), 0.055, 0.5)
	Synth.mix(out, Synth.mul(Synth.sweep(n, b * 2.76, b * 2.76, 1.0), Synth.env(n, 0.0004, 30.0)), 0.0, 0.25)
	Synth.mix(out, Synth.hp(_nz(0.006, 0, 1000.0, 0.7, 0.0002, 300.0), 4000.0), 0.0, 0.25)
	return _wav(Synth.finalize(Synth.reverb(out, 0.5, 0.4, 0.15, 0.08), 0.4, 1.1))


static func _chest(v: int) -> AudioStreamWAV:   # cofre: cerrojo + tapa + destello
	Synth.seed_with("chest", v)
	var out := Synth.buf(1.0)
	Synth.mix(out, _nz(0.06, 2, 1700.0, 2.0, 0.0003, 60.0), 0.0, 0.8)
	Synth.mix(out, Synth.mul(Synth.sweep(3000, 160.0, 70.0, 22.0), Synth.env(3000, 0.001, 14.0)), 0.05, 1.0)
	Synth.mix(out, _nz(0.22, 2, 900.0, 1.0, 0.04, 9.0, 1900.0), 0.08, 0.5)          # tapa que se abre
	var notes := [783.99, 987.77, 1174.66, 1567.98]
	for i in notes.size():
		var n := int(0.5 * RATE)
		Synth.mix(out, Synth.mul(Synth.sweep(n, float(notes[i]), float(notes[i]), 1.0), Synth.env(n, 0.003, 6.0)), 0.22 + float(i) * 0.07, 0.4)
		Synth.mix(out, Synth.mul(Synth.sweep(n, float(notes[i]) * 2.0, float(notes[i]) * 2.0, 1.0), Synth.env(n, 0.003, 10.0)), 0.22 + float(i) * 0.07, 0.15)
	return _wav(Synth.finalize(Synth.reverb(out, 1.0, 0.6, 0.28, 0.3), 0.55, 1.4, 0.05))


static func _bell(out: PackedFloat32Array, at: float, f: float, g: float, k: float = 5.0) -> void:
	var n := int(1.0 * RATE)
	var ph := 0.0
	var ph2 := 0.0
	var b := PackedFloat32Array()
	b.resize(n)
	for i in n:
		var t := float(i) / RATE
		ph += f / RATE
		ph2 += f * 3.5 / RATE
		b[i] = (sin(TAU * ph + sin(TAU * ph2) * 1.2 * exp(-t * 14.0)) * exp(-t * k))
	Synth.mix(out, b, at, g)


static func _perk(v: int) -> AudioStreamWAV:   # elegir mejora: campanas ascendentes
	Synth.seed_with("perk", v)
	var out := Synth.buf(1.2)
	var notes := [587.33, 880.0, 1174.66]
	for i in notes.size():
		_bell(out, float(i) * 0.09, float(notes[i]), 0.5, 4.0)
	Synth.mix(out, Synth.mul(Synth.sweep(4000, 110.0, 70.0, 12.0), Synth.env(4000, 0.001, 10.0)), 0.0, 0.6)
	return _wav(Synth.finalize(Synth.reverb(out, 1.0, 0.62, 0.3, 0.4), 0.5, 1.3, 0.06))


static func _reward(v: int) -> AudioStreamWAV:
	Synth.seed_with("reward", v)
	var out := Synth.buf(1.4)
	var notes := [523.25, 659.25, 783.99, 1046.5, 1318.5]
	for i in notes.size():
		_bell(out, float(i) * 0.1, float(notes[i]), 0.45, 3.4)
	Synth.mix(out, Synth.mul(Synth.sweep(6000, 120.0, 60.0, 10.0), Synth.env(6000, 0.001, 8.0)), 0.0, 0.7)
	return _wav(Synth.finalize(Synth.reverb(out, 1.1, 0.65, 0.32, 0.5), 0.52, 1.3, 0.08))


static func _levelup(v: int) -> AudioStreamWAV:
	Synth.seed_with("levelup", v)
	var out := Synth.buf(1.8)
	var notes := [392.0, 523.25, 659.25, 783.99, 1046.5, 1318.5]
	for i in notes.size():
		_bell(out, float(i) * 0.1, float(notes[i]), 0.42, 3.0)
	for f in [523.25, 659.25, 783.99, 1046.5]:
		_bell(out, 0.62, float(f), 0.3, 2.2)
	Synth.mix(out, Synth.mul(Synth.sweep(8000, 100.0, 55.0, 8.0), Synth.env(8000, 0.001, 6.0)), 0.62, 0.8)
	return _wav(Synth.finalize(Synth.reverb(out, 1.2, 0.68, 0.34, 0.5), 0.58, 1.3, 0.1))


## Acorde de metales sintetizado (sierras desafinadas + filtro con apertura).
static func _brass(out: PackedFloat32Array, at: float, f: float, dur: float, g: float) -> void:
	var n := int(dur * RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var p1 := 0.0
	var p2 := 0.0
	for i in n:
		p1 += f / RATE
		p2 += f * 1.006 / RATE
		b[i] = (fmod(p1, 1.0) * 2.0 - 1.0) + (fmod(p2, 1.0) * 2.0 - 1.0)
	b = Synth.svf(b, 500.0, 2600.0, 0.9, 0, RATE)
	var e := PackedFloat32Array()
	e.resize(n)
	for i in n:
		var t := float(i) / RATE
		e[i] = minf(1.0, t / 0.04) * (1.0 - smoothstep(dur * 0.55, dur, t))
	Synth.mix(out, Synth.mul(b, e), at, g)


static func _victory(v: int) -> AudioStreamWAV:
	Synth.seed_with("victory", v)
	var out := Synth.buf(2.8)
	var seq := [[392.0, 0.0, 0.3], [523.25, 0.22, 0.3], [659.25, 0.44, 0.3], [783.99, 0.66, 1.4]]
	for s in seq:
		_brass(out, float(s[1]), float(s[0]), float(s[2]), 0.5)
	for f in [523.25, 659.25, 783.99, 1046.5]:
		_brass(out, 0.66, float(f), 1.6, 0.28)
	_bell(out, 0.66, 1568.0, 0.3, 2.0)
	Synth.mix(out, Synth.mul(Synth.sweep(8000, 90.0, 50.0, 8.0), Synth.env(8000, 0.001, 6.0)), 0.66, 0.9)
	return _wav(Synth.finalize(Synth.reverb(out, 1.3, 0.7, 0.34, 0.6), 0.58, 1.4, 0.12))


static func _defeat(v: int) -> AudioStreamWAV:
	Synth.seed_with("defeat", v)
	var out := Synth.buf(2.6)
	var notes := [329.63, 311.13, 261.63, 196.0]
	for i in notes.size():
		_brass(out, float(i) * 0.34, float(notes[i]) * 0.5, 1.0 if i < 3 else 1.5, 0.45)
	Synth.mix(out, Synth.mul(Synth.sweep(10000, 70.0, 36.0, 3.0), Synth.env(10000, 0.01, 2.2)), 1.0, 0.8)
	return _wav(Synth.finalize(Synth.reverb(out, 1.3, 0.7, 0.34, 0.6), 0.52, 1.3, 0.12))


static func _clear(v: int) -> AudioStreamWAV:   # sala despejada
	Synth.seed_with("clear", v)
	var out := Synth.buf(1.0)
	var notes := [523.25, 783.99, 1046.5]
	for i in notes.size():
		_bell(out, float(i) * 0.09, float(notes[i]), 0.42, 4.2)
	Synth.mix(out, Synth.mul(Synth.sweep(4000, 100.0, 60.0, 14.0), Synth.env(4000, 0.001, 12.0)), 0.0, 0.5)
	return _wav(Synth.finalize(Synth.reverb(out, 0.9, 0.58, 0.26, 0.3), 0.45, 1.2, 0.06))


static func _wave(v: int) -> AudioStreamWAV:   # nueva oleada: alarma grave
	Synth.seed_with("wave", v)
	var out := Synth.buf(0.9)
	for i in 3:
		var n := int(0.22 * RATE)
		var t1 := Synth.mul(Synth.sweep(n, 220.0, 220.0, 1.0, RATE, 1), Synth.env(n, 0.003, 9.0))
		Synth.mix(out, Synth.lp(t1, 1400.0, 1.0), float(i) * 0.22, 0.6)
	Synth.mix(out, Synth.mul(Synth.sweep(6000, 80.0, 45.0, 6.0), Synth.env(6000, 0.002, 5.0)), 0.0, 0.8)
	return _wav(Synth.finalize(Synth.reverb(out, 0.9, 0.55, 0.22, 0.2), 0.52, 1.6, 0.04))


static func _tick(v: int) -> AudioStreamWAV:   # cronometro
	Synth.seed_with("tick", v)
	var out := _nz(0.03, 2, 3200.0, 3.0, 0.0002, 140.0)
	Synth.mix(out, Synth.mul(Synth.sweep(500, 1900.0, 1900.0, 1.0), Synth.env(500, 0.0003, 120.0)), 0.0, 0.35)
	return _wav(Synth.finalize(out, 0.3, 1.2))


# ------------------------------------------------------------------ interfaz
static func _ui_click(v: int) -> AudioStreamWAV:
	Synth.seed_with("ui_click", v)
	var n := int(0.07 * RATE)
	var out := Synth.mul(Synth.sweep(n, 1900.0, 1500.0, 40.0), Synth.env(n, 0.0004, 70.0))
	Synth.mix(out, _nz(0.012, 2, 3500.0, 2.0, 0.0002, 200.0), 0.0, 0.4)
	return _wav(Synth.finalize(out, 0.32, 1.2, 0.01))


static func _ui_confirm(v: int) -> AudioStreamWAV:
	Synth.seed_with("ui_confirm", v)
	var out := Synth.buf(0.3)
	for i in 2:
		var f := 740.0 if i == 0 else 1108.7
		var n := int(0.22 * RATE)
		Synth.mix(out, Synth.mul(Synth.sweep(n, f, f, 1.0), Synth.env(n, 0.003, 14.0)), float(i) * 0.07, 0.6)
		Synth.mix(out, Synth.mul(Synth.sweep(n, f * 2.0, f * 2.0, 1.0), Synth.env(n, 0.003, 22.0)), float(i) * 0.07, 0.18)
	return _wav(Synth.finalize(Synth.reverb(out, 0.5, 0.4, 0.12, 0.06), 0.36, 1.1, 0.02))


static func _ui_back(v: int) -> AudioStreamWAV:
	Synth.seed_with("ui_back", v)
	var out := Synth.buf(0.22)
	for i in 2:
		var f := 740.0 if i == 0 else 494.0
		var n := int(0.16 * RATE)
		Synth.mix(out, Synth.mul(Synth.sweep(n, f, f, 1.0), Synth.env(n, 0.003, 18.0)), float(i) * 0.05, 0.6)
	return _wav(Synth.finalize(out, 0.32, 1.1, 0.02))


static func _ui_open(v: int) -> AudioStreamWAV:
	Synth.seed_with("ui_open", v)
	var n := int(0.25 * RATE)
	var out := Synth.buf(0.25)
	Synth.mix(out, Synth.svf(Synth.noise(n), 600.0, 3000.0, 1.4, 2, RATE), 0.0, 0.0)
	Synth.mix(out, Synth.mul(Synth.svf(Synth.noise(n), 600.0, 3000.0, 1.4, 2, RATE), Synth.env(n, 0.03, 12.0)), 0.0, 0.5)
	Synth.mix(out, Synth.mul(Synth.sweep(n, 620.0, 980.0, 6.0), Synth.env(n, 0.004, 14.0)), 0.04, 0.45)
	return _wav(Synth.finalize(out, 0.34, 1.1, 0.03))


static func _ui_error(v: int) -> AudioStreamWAV:
	Synth.seed_with("ui_error", v)
	var out := Synth.buf(0.28)
	for i in 2:
		var n := int(0.1 * RATE)
		var t1 := Synth.mul(Synth.sweep(n, 190.0, 190.0, 1.0, RATE, 2), Synth.env(n, 0.002, 18.0))
		Synth.mix(out, Synth.lp(t1, 900.0, 1.0), float(i) * 0.12, 0.7)
	return _wav(Synth.finalize(out, 0.36, 1.4, 0.02))


static func _hum(v: int) -> AudioStreamWAV:   # zumbido ambiental de la estacion (unico bucle: ver regla Android)
	Synth.seed_with("hum", v)
	var dur := 3.0
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	# frecuencias que completan ciclos enteros en `dur` => el bucle no hace clic
	for pr in [[50.0, 0.5], [100.0, 0.22], [150.0, 0.12], [203.0, 0.04]]:
		var f := roundf(float(pr[0]) * dur) / dur
		for i in n:
			out[i] += sin(TAU * f * float(i) / RATE) * float(pr[1])
	var nz := Synth.lp(Synth.noise(n), 260.0, 0.8)
	for i in n:
		out[i] += nz[i] * 0.12
	var s := Synth.finalize(out, 0.2, 1.0, 0.0)
	return _wav(s, true)


# ------------------------------------------------------------------ musica
const MUSIC_RATE := 22050

## Pistas: tonica (Hz), tempo, escala y progresion (semitonos), estilo de orquestacion (ver MusicSynth).
const TRACKS := {
	"menu": {"root": 110.0, "bpm": 84.0, "scale": [0, 3, 5, 7, 10], "chords": [0, 8, 5, 7], "style": "menu", "bars": 8},
	"ch1": {"root": 55.0, "bpm": 112.0, "scale": [0, 3, 5, 6, 7, 10], "chords": [0, 0, 8, 7], "style": "industrial", "bars": 16},
	"ch2": {"root": 82.4, "bpm": 96.0, "scale": [0, 2, 4, 7, 9], "chords": [0, 0, 5, 7], "style": "temple", "bars": 16},
	"ch3": {"root": 73.4, "bpm": 80.0, "scale": [0, 2, 3, 7, 8], "chords": [0, 3, 8, 7], "style": "castle", "bars": 16},
	"ch4": {"root": 87.3, "bpm": 100.0, "scale": [0, 2, 6, 7, 11], "chords": [0, 6, 2, 7], "style": "anomaly", "bars": 16},
	"boss": {"root": 55.0, "bpm": 138.0, "scale": [0, 1, 3, 6, 7], "chords": [0, 1, 0, 6], "style": "boss", "bars": 16},
}


## `abort`: Callable opcional que devuelve true para cancelar (cierre de la app durante la sintesis en el hilo).
static func music(id: String, abort: Callable = Callable()) -> AudioStreamWAV:
	return MusicSynth.render(id, TRACKS.get(id, TRACKS["menu"]), MUSIC_RATE, abort)
