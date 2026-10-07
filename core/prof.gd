class_name Prof
extends RefCounted
## Perfilador minimo opcional (--perf): acumula microsegundos por etiqueta. Coste despreciable cuando esta apagado.

static var on := false
static var acc: Dictionary = {}
static var cnt: Dictionary = {}
static var _t0: Dictionary = {}


static func begin(tag: String) -> void:
	if on:
		_t0[tag] = Time.get_ticks_usec()


static func end(tag: String) -> void:
	if on:
		var d := Time.get_ticks_usec() - int(_t0.get(tag, 0))
		acc[tag] = int(acc.get(tag, 0)) + d
		cnt[tag] = int(cnt.get(tag, 0)) + 1


static func report(frames: int) -> String:
	var keys := acc.keys()
	keys.sort_custom(func(a, b): return acc[a] > acc[b])
	var out := ""
	for k in keys:
		out += "   %-14s %7.2f ms/frame  (%d llamadas)\n" % [k, float(acc[k]) / 1000.0 / float(maxi(frames, 1)), cnt[k]]
	return out
