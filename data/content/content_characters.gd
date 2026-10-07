class_name ContentCharacters
extends RefCounted
## Primera coleccion de personajes. La paleta se declara con 4 colores base (base/light/glow/accent);
## `CharacterRig.resolve_look` deriva el resto. Las claves de estilo cambian la SILUETA.

static func _c(id: String, nm: String, title: String, rar: int, p: Dictionary) -> CharacterData:
	var c := CharacterData.new()
	c.id = id
	c.display_name = nm
	c.title = title
	c.rarity = rar
	for k in p:
		c.set(k, p[k])
	return c


static func build() -> Array[CharacterData]:
	var L: Array[CharacterData] = []
	L.append(_c("vesper", "VESPER", "Soldado táctico", Rarity.Tier.COMMON, {
		"description": "Veterana de la Estación Cinder. Equilibrada, rápida de manos y con una bufanda que nunca se quita.",
		"hp": 6, "shield": 4, "energy": 150, "speed_mult": 1.0,
		"ability_id": "overclock", "ability_name": "SOBRECARGA", "ability_desc": "Durante 4 s dispara un 55% más rápido y con más daño.",
		"ability_cost": 50, "ability_cd": 12.0,
		"passive_id": "warm_mag", "passive_name": "CARGADOR CÁLIDO", "passive_desc": "Cada baja recarga un poco de energía.",
		"start_weapon": "pulsar", "side_weapon": "chispa", "recommended_weapon": "maul12",
		"look": {"visual": "vesper"},
		"unlock": {"type": "default"}, "order": 0,
	}))
	L.append(_c("kiro9", "KIRO-9", "Androide de contención", Rarity.Tier.RARE, {
		"description": "Unidad de seguridad reprogramada. Frágil por dentro, blindada por fuera; su campo magnético hace rebotar la violencia.",
		"hp": 4, "shield": 7, "energy": 200, "speed_mult": 0.98,
		"ability_id": "mirror", "ability_name": "CAMPO ESPEJO", "ability_desc": "Durante 3 s los proyectiles enemigos que te rodean se vuelven contra ellos.",
		"ability_cost": 60, "ability_cd": 14.0,
		"passive_id": "self_repair", "passive_name": "AUTORREPARACIÓN", "passive_desc": "El escudo se regenera mucho más rápido.",
		"start_weapon": "trinca", "side_weapon": "chispa", "recommended_weapon": "relampago",
		"look": {"visual": "kiro9", "base": Color("5c6577"), "light": Color("c9d2e2"), "glow": Color("b8ff3d"), "accent": Color("b8ff3d"),
			"head": "dome", "torso": "suit", "back": "array", "shoulder_style": "plain", "scarf": null, "hs": 1.05, "w": 0.97},
		"unlock": {"type": "coins", "price": 900}, "order": 1,
	}))
	L.append(_c("sera", "DOC SERA", "Médica de combate", Rarity.Tier.RARE, {
		"description": "Dejó el hospital de campaña por la línea del frente. Dispara poco, cura mucho, y nunca olvida un rostro.",
		"hp": 5, "shield": 5, "energy": 140, "speed_mult": 1.04,
		"ability_id": "nanocloud", "ability_name": "NANONUBE", "ability_desc": "Cura 2 de vida y 2 de escudo al instante y deja una nube que sigue sanando.",
		"ability_cost": 80, "ability_cd": 20.0,
		"passive_id": "triage", "passive_name": "TRIAJE", "passive_desc": "Los botiquines curan 1 punto extra.",
		"start_weapon": "chispa", "side_weapon": "pulsar", "recommended_weapon": "colmena",
		"look": {"visual": "sera", "base": Color("dfe8f2"), "light": Color("ffffff"), "glow": Color("5fffc8"), "accent": Color("ff4f6a"),
			"head": "medic", "torso": "suit", "back": "medpack", "shoulder_style": "plain", "scarf": null, "hs": 1.08, "w": 0.9, "h": 0.97},
		"unlock": {"type": "coins", "price": 1100}, "order": 2,
	}))
	L.append(_c("orla", "ORLA", "Ingeniera de campo", Rarity.Tier.RARE, {
		"description": "Si se rompe, lo arregla. Si se arregla, lo mejora. Si lo mejora, explota. Adora los plasmas.",
		"hp": 5, "shield": 4, "energy": 170, "speed_mult": 1.0,
		"ability_id": "turret", "ability_name": "TORRETA PORTÁTIL", "ability_desc": "Despliega una torreta que dispara a los enemigos durante 14 s.",
		"ability_cost": 70, "ability_cd": 16.0,
		"passive_id": "scrapper", "passive_name": "CHATARRERA", "passive_desc": "Romper cajas y barriles suelta monedas y energía.",
		"start_weapon": "gota", "side_weapon": "chispa", "recommended_weapon": "pomelo",
		"look": {"visual": "orla", "base": Color("e8a824"), "light": Color("ffd96a"), "glow": Color("36e0d0"), "accent": Color("36e0d0"),
			"head": "goggles", "torso": "armor", "back": "toolbox", "shoulder_style": "pads", "scarf": null, "hs": 1.04, "w": 1.0},
		"unlock": {"type": "coins", "price": 1200}, "order": 3,
	}))
	L.append(_c("halo", "HALO", "Tiradora de precisión", Rarity.Tier.RARE, {
		"description": "Paciente como el desierto. Una mirada, un disparo y el eco llega después.",
		"hp": 3, "shield": 3, "energy": 100, "speed_mult": 1.05,
		"ability_id": "mark", "ability_name": "MARCA DE CAZA", "ability_desc": "Tus próximos 3 disparos hacen +150% de daño y perforan más.",
		"ability_cost": 40, "ability_cd": 10.0,
		"passive_id": "eagle_eye", "passive_name": "OJO DE ÁGUILA", "passive_desc": "+18% de probabilidad de golpe crítico.",
		"start_weapon": "aguja", "side_weapon": "chispa", "recommended_weapon": "riel_q",
		"look": {"visual": "halo", "base": Color("a48b5c"), "light": Color("e6d3a2"), "glow": Color("ff5a4a"), "accent": Color("ff5a4a"),
			"head": "sniper", "torso": "hunter", "back": "rifle_sling", "shoulder_style": "plain", "scarf": Color("c9b380"), "hs": 1.0, "h": 1.04, "w": 0.92},
		"unlock": {"type": "coins", "price": 1500}, "order": 4,
	}))
	L.append(_c("sable", "SABLE", "Filo errante", Rarity.Tier.EPIC, {
		"description": "Una hoja, una promesa y ninguna prisa. Desvía lo que le disparan y devuelve el favor.",
		"hp": 7, "shield": 2, "energy": 90, "speed_mult": 1.1,
		"ability_id": "whirl", "ability_name": "TORBELLINO", "ability_desc": "Gira la hoja golpeando a todo el que esté cerca, tres veces, sin moverte del sitio.",
		"ability_cost": 50, "ability_cd": 10.0,
		"passive_id": "deflect", "passive_name": "REFLEJO DE ACERO", "passive_desc": "Cada tajo desvía los proyectiles enemigos cercanos.",
		"start_weapon": "filo_z", "side_weapon": "chispa", "recommended_weapon": "garra",
		"look": {"visual": "sable", "base": Color("2a2a3c"), "light": Color("8a8aa8"), "glow": Color("ff3a5a"), "accent": Color("ff3a5a"),
			"head": "horned", "torso": "hunter", "back": "cape", "shoulder_style": "spikes", "scarf": Color("ff3a5a"), "hs": 1.0, "h": 1.02, "w": 0.92},
		"unlock": {"type": "coins", "price": 3200}, "order": 5,
	}))
	L.append(_c("nyx", "NYX", "Exploradora dimensional", Rarity.Tier.EPIC, {
		"description": "Volvió de un lugar que no está en ningún mapa. Parte de ella todavía no regresó y a veces lo demuestra.",
		"hp": 4, "shield": 3, "energy": 180, "speed_mult": 1.08,
		"ability_id": "phase", "ability_name": "DESFASE", "ability_desc": "Durante 1,6 s existes a medias: los proyectiles y golpes te atraviesan.",
		"ability_cost": 55, "ability_cd": 13.0,
		"passive_id": "ether_step", "passive_name": "PASO ETÉREO", "passive_desc": "12% de probabilidad de ignorar un impacto.",
		"start_weapon": "rebote", "side_weapon": "chispa", "recommended_weapon": "anomalia",
		"look": {"visual": "nyx", "base": Color("4a2f7a"), "light": Color("b9a0ff"), "glow": Color("ff4fd8"), "accent": Color("ff4fd8"),
			"head": "hood", "torso": "robe", "back": "ring", "shoulder_style": "none", "scarf": null, "hs": 1.02, "w": 0.94},
		"unlock": {"type": "coins", "price": 3400}, "order": 6,
	}))
	L.append(_c("kraal", "KRAAL", "Cazador alienígena", Rarity.Tier.EPIC, {
		"description": "Cazó cosas peores que esto en un mundo sin nombre. Pelea cerca, huele el miedo y sonríe con demasiados dientes.",
		"hp": 8, "shield": 2, "energy": 140, "speed_mult": 1.04,
		"ability_id": "roar", "ability_name": "RUGIDO", "ability_desc": "Onda de choque: aturde, empuja y daña a todos los enemigos cercanos.",
		"ability_cost": 45, "ability_cd": 11.0,
		"passive_id": "hunt", "passive_name": "INSTINTO DE CAZA", "passive_desc": "Cada 5 bajas recuperas 1 punto de escudo.",
		"start_weapon": "brasero", "side_weapon": "garra", "recommended_weapon": "maul12",
		"look": {"visual": "kraal", "base": Color("3f8a6e"), "light": Color("d8e8c8"), "glow": Color("ffb23d"), "accent": Color("ffb23d"),
			"head": "alien", "torso": "hunter", "back": "spine", "shoulder_style": "spikes", "scarf": null, "hs": 1.0, "h": 1.08, "w": 0.95, "skin": Color("5fb88a")},
		"unlock": {"type": "coins", "price": 3600}, "order": 7,
	}))
	L.append(_c("basalto", "BASALTO", "Pesado de asalto", Rarity.Tier.EPIC, {
		"description": "Treinta años de blindaje sobre un solo hombre. Lento, inamovible y con un cañón que no sabe callarse.",
		"hp": 10, "shield": 4, "energy": 120, "speed_mult": 0.84,
		"ability_id": "bulwark", "ability_name": "MURO DE ACERO", "ability_desc": "Durante 4 s recibes un 70% menos de daño y no puedes ser empujado.",
		"ability_cost": 60, "ability_cd": 15.0,
		"passive_id": "immovable", "passive_name": "INAMOVIBLE", "passive_desc": "Inmune al empuje. El escudo empieza a regenerarse antes.",
		"start_weapon": "mastin", "side_weapon": "chispa", "recommended_weapon": "pomelo",
		"look": {"visual": "basalto", "base": Color("8a3a32"), "light": Color("d9b8a0"), "glow": Color("ff8a3d"), "accent": Color("ff8a3d"),
			"head": "heavy", "torso": "heavy", "back": "tanks", "shoulder_style": "big", "scarf": null, "hs": 1.0, "h": 0.94, "w": 1.22},
		"unlock": {"type": "coins", "price": 4200}, "order": 8,
	}))
	L.append(_c("ilex", "ILEX", "Tecnomante", Rarity.Tier.LEGENDARY, {
		"description": "Escribe en el aire con corriente. Lo que no entiende, lo conecta a un cable y espera a que hable.",
		"hp": 3, "shield": 5, "energy": 250, "speed_mult": 1.0,
		"ability_id": "storm", "ability_name": "TORMENTA", "ability_desc": "Descarga 5 rayos encadenados sobre los enemigos más cercanos.",
		"ability_cost": 90, "ability_cd": 18.0,
		"passive_id": "arcane_flow", "passive_name": "FLUJO ARCANO", "passive_desc": "Las armas de energía cuestan un 30% menos.",
		"start_weapon": "relampago", "side_weapon": "chispa", "recommended_weapon": "riel_q",
		"look": {"visual": "ilex", "base": Color("2a3a8a"), "light": Color("e8d28a"), "glow": Color("4fd8ff"), "accent": Color("ffd24a"),
			"head": "crown", "torso": "robe", "back": "orbs", "shoulder_style": "none", "scarf": null, "hs": 1.02, "w": 0.96},
		"unlock": {"type": "coins", "price": 7500}, "order": 9,
	}))
	L.append(_c("paradoja", "PARADOJA", "Experimento inestable", Rarity.Tier.ANOMALOUS, {
		"description": "Nació de una anomalía que alguien dejó encendida. No termina de decidir en qué tiempo está.",
		"hp": 2, "shield": 8, "energy": 200, "speed_mult": 1.06,
		"ability_id": "echo", "ability_name": "ECO TEMPORAL", "ability_desc": "Durante 3,5 s los enemigos y sus proyectiles se mueven a la mitad de velocidad.",
		"ability_cost": 80, "ability_cd": 18.0,
		"passive_id": "unstable", "passive_name": "INESTABLE", "passive_desc": "Al empezar cada sala recibe un beneficio aleatorio temporal.",
		"start_weapon": "anomalia", "side_weapon": "chispa", "recommended_weapon": "enjambre",
		"look": {"visual": "paradoja", "base": Color("1c1c2e"), "light": Color("e8e8ff"), "glow": Color("ff4fd8"), "accent": Color("4fffe8"),
			"head": "glitch", "torso": "glitch", "back": "shards", "shoulder_style": "none", "scarf": null, "hs": 1.04, "w": 0.96},
		"unlock": {"type": "pass", "level": 30}, "order": 10,
	}))
	return L


static func build_skins() -> Array[SkinData]:
	var S: Array[SkinData] = []
	S.append(_s("vesper_ember", "vesper", "BRASA", 1, {"base": Color("7a3a3a"), "glow": Color("ff8a3d"), "accent": Color("ffd24a"), "scarf": Color("ffd24a")}, Color("ff9a4a"), 700))
	S.append(_s("vesper_frost", "vesper", "ESCARCHA", 2, {"base": Color("4a6a9a"), "light": Color("ffffff"), "glow": Color("8fe8ff"), "accent": Color("ffffff"), "scarf": Color("bfefff")}, Color("9fefff"), 1600))
	S.append(_s("kiro9_gold", "kiro9", "ORO VIEJO", 2, {"base": Color("9a7a2a"), "light": Color("ffe9a0"), "glow": Color("ffd24a"), "accent": Color("ffd24a")}, Color("ffd24a"), 1600))
	S.append(_s("sera_noir", "sera", "NOCTURNA", 2, {"base": Color("30364a"), "light": Color("c8d0e8"), "glow": Color("b78bff"), "accent": Color("b78bff")}, Color("c0a0ff"), 1600))
	S.append(_s("halo_dusk", "halo", "CREPÚSCULO", 2, {"base": Color("5a3a6a"), "light": Color("e8c8ff"), "glow": Color("ff9a5a"), "accent": Color("ff9a5a"), "scarf": Color("ff9a5a")}, Color("ffb07a"), 1800))
	S.append(_s("sable_ghost", "sable", "FANTASMA", 3, {"base": Color("c8d0e0"), "light": Color("ffffff"), "glow": Color("5fe8ff"), "accent": Color("5fe8ff"), "scarf": Color("5fe8ff")}, Color("7ff0ff"), 3200))
	S.append(_s("kraal_ember", "kraal", "ESCAMA ROJA", 2, {"base": Color("8a3a3a"), "light": Color("ffe0c8"), "glow": Color("ff5a3a"), "accent": Color("ff5a3a"), "skin": Color("c46a5a")}, Color("ff7a4a"), 2000))
	S.append(_s("basalto_arctic", "basalto", "ÁRTICO", 2, {"base": Color("5a6a8a"), "light": Color("e8f0ff"), "glow": Color("8fe8ff"), "accent": Color("8fe8ff")}, Color("a0efff"), 2000))
	return S


static func _s(id: String, ch: String, nm: String, rar: int, look: Dictionary, bullet: Color, price: int) -> SkinData:
	var s := SkinData.new()
	s.id = id
	s.character = ch
	s.display_name = nm
	s.rarity = rar
	s.look = look
	s.bullet_color = bullet
	s.trail_color = bullet
	s.unlock = {"type": "coins", "price": price}
	return s
