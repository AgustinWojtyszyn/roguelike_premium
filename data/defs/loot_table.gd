class_name LootTable
extends Resource
## Tabla de loot ponderada. Entradas: {"type": coins|energy|heal|weapon|perk|rare, "w": peso, "min":, "max":, "tier_min":, "tier_max":}

@export var id: String = ""
@export var entries: Array = []


func roll(rng: RandomNumberGenerator) -> Dictionary:
	var total := 0.0
	for e in entries:
		total += float(e.get("w", 1.0))
	var r := rng.randf() * total
	for e in entries:
		r -= float(e.get("w", 1.0))
		if r <= 0.0:
			return _resolve(e, rng)
	return _resolve(entries[0], rng)


func _resolve(e: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var out: Dictionary = {"type": e.get("type", "coins")}
	if e.has("min"):
		out["amount"] = rng.randi_range(int(e["min"]), int(e.get("max", e["min"])))
	if e.has("tier_min"):
		out["tier"] = Rarity.roll(rng, 0.0, int(e["tier_min"]), int(e.get("tier_max", 4)))
	return out
