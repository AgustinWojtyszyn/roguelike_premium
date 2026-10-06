class_name ContentEnemies
extends RefCounted
## Catalogo de enemigos por familia (capitulo). `role` documenta su funcion para el generador de encuentros.

static func _e(id: String, nm: String, fam: String, role: String, path: String, hp: float, threat: float, coins: int, elite_ok: bool = true) -> EnemyData:
	var e := EnemyData.new()
	e.id = id
	e.display_name = nm
	e.family = fam
	e.role = role
	e.script_path = path
	e.hp = hp
	e.threat = threat
	e.coins = coins
	e.elite_ok = elite_ok
	return e


static func build() -> Array[EnemyData]:
	var L: Array[EnemyData] = []
	# ---- Familia 1: maquinas corruptas
	L.append(_e("skitter", "ARAÑA DE CABLES", "tech", "melee", "res://enemies/skitter.gd", 7.0, 1.0, 1, false))
	L.append(_e("lancer", "CENTINELA", "tech", "shooter", "res://enemies/lancer.gd", 12.0, 1.5, 1))
	L.append(_e("brute", "CARGADOR PESADO", "tech", "heavy", "res://enemies/brute.gd", 58.0, 4.0, 3))
	L.append(_e("sentry", "TORRETA", "tech", "turret", "res://enemies/sentry.gd", 24.0, 2.0, 2))
	L.append(_e("fuse", "DRON BOMBA", "tech", "kamikaze", "res://enemies/fuse.gd", 5.0, 1.0, 1, false))
	L.append(_e("aegis", "GUARDIA ÉGIDA", "tech", "shield", "res://enemies/aegis.gd", 34.0, 2.5, 2))
	L.append(_e("mender", "DRON REPARADOR", "tech", "support", "res://enemies/mender.gd", 12.0, 2.0, 2))
	return L
