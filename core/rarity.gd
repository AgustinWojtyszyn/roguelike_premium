class_name Rarity
extends RefCounted
## Rarezas originales del universo. Una sola fuente de verdad para color, nombre y peso de aparicion.

enum Tier { COMMON, RARE, EPIC, LEGENDARY, ANOMALOUS }

const NAMES: Array[String] = ["COMÚN", "RARA", "ÉPICA", "LEGENDARIA", "ANÓMALA"]
const COLORS: Array[Color] = [
	Color("8fa3c7"), Color("3fb8ff"), Color("b47bff"), Color("ffb938"), Color("ff4fd8"),
]
## Peso base para tablas de loot (mas alto = mas frecuente).
const WEIGHTS: Array[float] = [60.0, 26.0, 10.0, 3.2, 0.8]


static func color(tier: int) -> Color:
	return COLORS[clampi(tier, 0, COLORS.size() - 1)]


static func label(tier: int) -> String:
	return NAMES[clampi(tier, 0, NAMES.size() - 1)]


## Color animado para la rareza ANOMALA (cambia de tono); el resto es estatico.
static func color_anim(tier: int, t: float) -> Color:
	if tier == Tier.ANOMALOUS:
		return Color.from_hsv(fposmod(0.82 + sin(t * 1.6) * 0.1, 1.0), 0.75, 1.0)
	return color(tier)


static func roll(rng: RandomNumberGenerator, luck: float = 0.0, min_tier: int = 0, max_tier: int = 4) -> int:
	var total := 0.0
	var ws: Array[float] = []
	for i in WEIGHTS.size():
		var w := 0.0
		if i >= min_tier and i <= max_tier:
			w = WEIGHTS[i] * (1.0 + luck * float(i))
		ws.append(w)
		total += w
	var r := rng.randf() * total
	for i in ws.size():
		r -= ws[i]
		if r <= 0.0:
			return i
	return min_tier
