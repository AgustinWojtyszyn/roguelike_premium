class_name ContentWeapons
extends RefCounted
## Catalogo de armas. Cada una cambia la MECANICA, no solo el numero (ver `behavior`).

static func _w(id: String, nm: String, sub: String, cat: String, rar: int, p: Dictionary) -> WeaponData:
	var w := WeaponData.new()
	w.id = id
	w.display_name = nm
	w.sub = sub
	w.category = cat
	w.rarity = rar
	for k in p:
		w.set(k, p[k])
	return w


static func build() -> Array[WeaponData]:
	var L: Array[WeaponData] = []
	L.append(_w("pulsar", "PULSAR", "AUTOMÁTICA", "smg", Rarity.Tier.COMMON, {
		"description": "Subfusil de pulsos. Cadencia alta, sin coste de energía.",
		"rate": 0.088, "damage": 2.0, "speed": 840.0, "spread": 0.055, "life": 0.8, "kick": 3.2, "shake": 0.05, "knock": 38.0,
		"muzzle": Vector2(35, -0.5), "grip2": Vector2(15, 3.5), "color": Color("3df2dc"), "bullet": 0, "sfx": "smg", "art": "pulsar", "body_kick": 14.0,
	}))
	L.append(_w("maul12", "MAUL-12", "CORTO ALCANCE", "shotgun", Rarity.Tier.RARE, {
		"description": "Escopeta de bobinas. Devastadora a quemarropa.",
		"rate": 0.78, "damage": 2.5, "speed": 640.0, "spread": 0.30, "count": 7, "life": 0.3, "kick": 10.0, "shake": 0.28, "knock": 150.0,
		"muzzle": Vector2(36, 0), "grip2": Vector2(15, 6), "color": Color("ffc24a"), "bullet": 1, "sfx": "maul", "sfx_vol": -2.0, "art": "maul", "body_kick": 95.0, "muzzle_scale": 1.5,
	}))
	L.append(_w("lancex", "LANCE-X", "ENERGÉTICA PRECISA", "rail", Rarity.Tier.EPIC, {
		"description": "Rifle de riel compacto. Atraviesa a dos enemigos.",
		"rate": 0.4, "damage": 13.0, "speed": 1500.0, "spread": 0.0, "life": 0.75, "pierce": 2, "kick": 7.0, "shake": 0.16, "knock": 90.0, "energy_cost": 4.0,
		"muzzle": Vector2(47, 0), "grip2": Vector2(24, 3), "color": Color("6cc4ff"), "bullet": 2, "casing": false, "sfx": "rail", "sfx_vol": -2.0, "art": "lance", "body_kick": 55.0, "muzzle_scale": 1.25,
	}))
	L.append(_w("chispa", "CHISPA", "PISTOLA", "pistol", Rarity.Tier.COMMON, {
		"description": "Pistola precisa y fiable. Siempre a mano.",
		"rate": 0.24, "damage": 3.4, "speed": 920.0, "spread": 0.018, "life": 0.7, "kick": 4.5, "shake": 0.06, "knock": 55.0,
		"muzzle": Vector2(23, -0.5), "grip2": Vector2(9, 4), "color": Color("9fe9ff"), "bullet": 0, "sfx": "smg", "sfx_vol": -4.0, "art": "pistol", "body_kick": 22.0,
		"palette": {"body": Color("9aa7c8"), "dark": Color("38425f"), "glow": Color("9fe9ff")},
	}))
	L.append(_w("trinca", "TRINCA", "RÁFAGA DE 3", "rifle", Rarity.Tier.RARE, {
		"description": "Fusil de ráfagas. Tres balas agrupadas, ritmo marcado.",
		"rate": 0.46, "damage": 2.6, "speed": 900.0, "spread": 0.03, "life": 0.8, "kick": 5.0, "shake": 0.07, "knock": 50.0,
		"muzzle": Vector2(38, 0), "grip2": Vector2(17, 4), "color": Color("b8ff6a"), "bullet": 0, "sfx": "smg", "art": "burst_rifle", "body_kick": 18.0,
		"behavior": {"burst": 3, "burst_gap": 0.055},
		"palette": {"body": Color("7f8a6a"), "dark": Color("2f3626"), "glow": Color("b8ff6a")},
	}))
	L.append(_w("mastin", "MASTÍN", "MINIGUN DE ARRANQUE", "smg", Rarity.Tier.EPIC, {
		"description": "Gira hasta ganar cadencia brutal. Te ralentiza mientras dispara.",
		"rate": 0.2, "damage": 1.7, "speed": 800.0, "spread": 0.09, "life": 0.75, "kick": 2.2, "shake": 0.05, "knock": 26.0, "energy_cost": 0.0,
		"muzzle": Vector2(42, 0), "grip2": Vector2(18, 5), "color": Color("ffb23d"), "bullet": 0, "sfx": "smg", "sfx_vol": -9.0, "art": "minigun", "body_kick": 6.0,
		"behavior": {"spool": {"rate_min": 0.2, "rate_max": 0.045, "time": 1.5, "spread_add": 0.05}, "move_mult": 0.72},
		"palette": {"body": Color("8a6a5a"), "dark": Color("3a2a26"), "glow": Color("ffb23d")},
	}))
	L.append(_w("gota", "GOTA ÁCIDA", "PLASMA EXPLOSIVO", "plasma", Rarity.Tier.RARE, {
		"description": "Dispara glóbulos de plasma que estallan al impactar.",
		"rate": 0.52, "damage": 5.0, "speed": 520.0, "spread": 0.03, "life": 1.1, "kick": 6.0, "shake": 0.12, "knock": 90.0, "energy_cost": 3.0,
		"muzzle": Vector2(32, 0), "grip2": Vector2(14, 5), "color": Color("7dff6a"), "bullet": 4, "casing": false, "sfx": "bolt", "sfx_vol": -3.0, "art": "plasma", "body_kick": 30.0,
		"behavior": {"explode": 46.0, "explode_mult": 0.7},
		"palette": {"body": Color("6a8a6a"), "dark": Color("24362a"), "glow": Color("7dff6a")},
	}))
	L.append(_w("pomelo", "CAÑÓN POMELO", "GRANADAS", "explosive", Rarity.Tier.EPIC, {
		"description": "Granadas que rebotan y detonan tras un instante. Daño en área enorme.",
		"rate": 0.95, "damage": 4.0, "speed": 560.0, "spread": 0.04, "life": 1.0, "kick": 11.0, "shake": 0.22, "knock": 120.0, "energy_cost": 6.0,
		"muzzle": Vector2(34, 0), "grip2": Vector2(16, 6), "color": Color("ff9a3d"), "bullet": 5, "casing": false, "sfx": "maul", "sfx_vol": -4.0, "art": "grenade", "body_kick": 70.0,
		"behavior": {"bounce": 2, "fuse": 0.85, "explode": 92.0, "explode_mult": 4.0, "drag": 2.2},
		"palette": {"body": Color("8a7a5a"), "dark": Color("3a3024"), "glow": Color("ff9a3d")},
	}))
	L.append(_w("relampago", "RELÁMPAGO", "ARCO EN CADENA", "energy", Rarity.Tier.LEGENDARY, {
		"description": "Un arco eléctrico salta entre hasta 4 enemigos cercanos.",
		"rate": 0.24, "damage": 4.2, "speed": 0.0, "spread": 0.0, "life": 0.0, "kick": 3.0, "shake": 0.07, "knock": 30.0, "energy_cost": 2.6,
		"muzzle": Vector2(34, 0), "grip2": Vector2(14, 4), "color": Color("8fa8ff"), "bullet": 14, "casing": false, "sfx": "zap", "sfx_vol": -5.0, "art": "arc", "body_kick": 10.0,
		"max_range": 330.0,
		"behavior": {"chain": {"n": 4, "range": 170.0, "falloff": 0.82, "reach": 330.0}},
		"palette": {"body": Color("8a8fcf"), "dark": Color("2c2f5e"), "glow": Color("8fa8ff")},
	}))
	L.append(_w("rebote", "REBOTE", "RICOCHET", "energy", Rarity.Tier.RARE, {
		"description": "Orbes magentas que rebotan hasta 3 veces en las paredes.",
		"rate": 0.2, "damage": 3.0, "speed": 700.0, "spread": 0.05, "life": 1.7, "kick": 3.5, "shake": 0.06, "knock": 40.0, "energy_cost": 1.4,
		"muzzle": Vector2(30, 0), "grip2": Vector2(12, 4), "color": Color("ff5fd0"), "bullet": 4, "casing": false, "sfx": "bolt", "sfx_vol": -9.0, "art": "bouncer", "body_kick": 12.0, "muzzle_scale": 0.9,
		"behavior": {"bounce": 3},
		"palette": {"body": Color("9a6ab0"), "dark": Color("3a2450"), "glow": Color("ff5fd0")},
	}))
	L.append(_w("colmena", "COLMENA", "MICRO-MISILES", "explosive", Rarity.Tier.EPIC, {
		"description": "Tres micromisiles teledirigidos por salva. Persiguen al enemigo más cercano.",
		"rate": 0.7, "damage": 2.6, "speed": 380.0, "spread": 0.34, "count": 3, "life": 1.5, "kick": 7.0, "shake": 0.1, "knock": 60.0, "energy_cost": 3.2,
		"muzzle": Vector2(30, 0), "grip2": Vector2(14, 6), "color": Color("ffd23d"), "bullet": 8, "casing": false, "sfx": "bolt", "sfx_vol": -5.0, "art": "pod", "body_kick": 28.0,
		"behavior": {"homing": 5.5, "accel": 520.0, "explode": 30.0, "explode_mult": 0.8},
		"palette": {"body": Color("9a8a5a"), "dark": Color("3a3220"), "glow": Color("ffd23d")},
	}))
	L.append(_w("filo_z", "FILO-Z", "HOJA DE ENERGÍA", "melee", Rarity.Tier.RARE, {
		"description": "Tajo en arco que alcanza a varios enemigos y desvía proyectiles.",
		"rate": 0.34, "damage": 6.5, "speed": 0.0, "spread": 0.0, "life": 0.0, "kick": 0.0, "shake": 0.12, "knock": 190.0,
		"muzzle": Vector2(40, 0), "grip2": Vector2(4, 4), "color": Color("ff6a8a"), "bullet": 15, "casing": false, "sfx": "slash", "sfx_vol": -2.0, "art": "blade", "body_kick": 0.0,
		"max_range": 92.0,
		"behavior": {"arc": {"range": 96.0, "angle": 2.3, "reflect": true}},
		"palette": {"body": Color("d9dff2"), "dark": Color("39425f"), "glow": Color("ff6a8a")},
	}))
	L.append(_w("garra", "GARRA", "ZARPAZOS RÁPIDOS", "melee", Rarity.Tier.COMMON, {
		"description": "Puñal doble de golpes rápidos. Curta pero feroz.",
		"rate": 0.15, "damage": 2.5, "speed": 0.0, "spread": 0.0, "life": 0.0, "kick": 0.0, "shake": 0.04, "knock": 70.0,
		"muzzle": Vector2(30, 0), "grip2": Vector2(4, 4), "color": Color("ffe27a"), "bullet": 15, "casing": false, "sfx": "slash", "sfx_vol": -9.0, "art": "claws", "body_kick": 0.0,
		"max_range": 60.0,
		"behavior": {"arc": {"range": 62.0, "angle": 1.7, "reflect": false}},
		"palette": {"body": Color("d8e0ee"), "dark": Color("3a4258"), "glow": Color("ffe27a")},
	}))
	L.append(_w("enjambre", "ENJAMBRE", "NIDO DE DRONES", "drone", Rarity.Tier.EPIC, {
		"description": "Suelta drones que cazan y se estrellan contra los enemigos.",
		"rate": 0.95, "damage": 2.0, "speed": 300.0, "spread": 0.5, "count": 2, "life": 3.6, "kick": 5.0, "shake": 0.06, "knock": 60.0, "energy_cost": 5.0,
		"muzzle": Vector2(26, 0), "grip2": Vector2(12, 5), "color": Color("6affb0"), "bullet": 13, "casing": false, "sfx": "bolt", "sfx_vol": -7.0, "art": "nest", "body_kick": 12.0,
		"behavior": {"homing": 4.0, "accel": 160.0, "explode": 38.0, "explode_mult": 4.2, "wobble": 1.0},
		"palette": {"body": Color("6a9a8a"), "dark": Color("24403a"), "glow": Color("6affb0")},
	}))
	L.append(_w("anomalia", "ANOMALÍA", "EXPERIMENTAL", "exp", Rarity.Tier.ANOMALOUS, {
		"description": "Cada disparo muta: ráfaga dispersa, perforante, rebotante o explosiva. Nadie sabe qué hará.",
		"rate": 0.22, "damage": 3.0, "speed": 700.0, "spread": 0.06, "life": 1.0, "kick": 5.0, "shake": 0.1, "knock": 70.0, "energy_cost": 2.0,
		"muzzle": Vector2(30, 0), "grip2": Vector2(13, 4), "color": Color("ff4fd8"), "bullet": 4, "casing": false, "sfx": "zap", "sfx_vol": -6.0, "art": "anomaly", "body_kick": 24.0,
		"behavior": {"random": [
			{"count": 5, "spread": 0.35, "dmg": 1.6, "color": Color("ff6ad8")},
			{"pierce": 4, "dmg": 4.0, "speed": 1100.0, "color": Color("6cc4ff")},
			{"bounce": 3, "dmg": 2.8, "color": Color("7dff9a")},
			{"explode": 60.0, "explode_mult": 1.4, "dmg": 3.4, "color": Color("ffb23d")},
		]},
		"palette": {"body": Color("8a5aa8"), "dark": Color("2c1a46"), "glow": Color("ff4fd8")},
	}))
	L.append(_w("riel_q", "RIEL-Q", "CARGA DE RIEL", "rail", Rarity.Tier.LEGENDARY, {
		"description": "Mantén para cargar. Al completar la carga lanza un haz que atraviesa todo.",
		"rate": 0.3, "damage": 38.0, "speed": 0.0, "spread": 0.0, "life": 0.0, "kick": 11.0, "shake": 0.4, "knock": 300.0, "energy_cost": 16.0,
		"muzzle": Vector2(52, 0), "grip2": Vector2(26, 3), "color": Color("9a6cff"), "bullet": 16, "casing": false, "sfx": "rail", "sfx_vol": 0.0, "art": "charge_rail", "body_kick": 90.0, "muzzle_scale": 1.9,
		"max_range": 900.0,
		"behavior": {"charge": 0.8, "beam": 900.0},
		"palette": {"body": Color("b6a6e6"), "dark": Color("2e2650"), "glow": Color("9a6cff")},
	}))
	L.append(_w("brasero", "BRASERO", "LANZALLAMAS", "plasma", Rarity.Tier.RARE, {
		"description": "Cono de fuego continuo que perfora a todos. Consume energía rápido.",
		"rate": 0.05, "damage": 0.95, "speed": 400.0, "spread": 0.2, "life": 0.27, "pierce": 99, "kick": 1.2, "shake": 0.03, "knock": 12.0, "energy_cost": 0.8,
		"muzzle": Vector2(34, 1), "grip2": Vector2(15, 5), "color": Color("ff8a2a"), "bullet": 7, "casing": false, "sfx": "flame", "sfx_vol": -12.0, "art": "flamer", "body_kick": 3.0, "muzzle_scale": 0.0,
		"behavior": {"move_mult": 0.88},
		"palette": {"body": Color("8a6a5a"), "dark": Color("3a2820"), "glow": Color("ff8a2a")},
	}))
	L.append(_w("aguja", "AGUJA", "FRANCOTIRADOR", "sniper", Rarity.Tier.EPIC, {
		"description": "Un disparo, una baja. Proyectil rapidísimo que perfora.",
		"rate": 0.95, "damage": 22.0, "speed": 2300.0, "spread": 0.0, "life": 0.65, "pierce": 2, "kick": 9.0, "shake": 0.2, "knock": 180.0, "energy_cost": 0.0,
		"muzzle": Vector2(56, 0), "grip2": Vector2(28, 3), "color": Color("ff6a6a"), "bullet": 6, "casing": true, "sfx": "rail", "sfx_vol": -1.0, "art": "sniper", "body_kick": 70.0, "muzzle_scale": 1.4,
		"palette": {"body": Color("b0a07a"), "dark": Color("3a3424"), "glow": Color("ff6a6a")},
	}))
	return L
