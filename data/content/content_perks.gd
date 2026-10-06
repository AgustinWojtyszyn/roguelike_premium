class_name ContentPerks
extends RefCounted
## Perks de run. Mezcla de modificadores numericos (`mods`) y comportamientos (`hooks`, ver PerkEffects).

static func _p(id: String, nm: String, desc: String, rar: int, tag: String, icon: String, mods: Dictionary, hooks: Array[String] = [], stack: bool = false) -> PerkData:
	var p := PerkData.new()
	p.id = id
	p.display_name = nm
	p.description = desc
	p.rarity = rar
	p.tag = tag
	p.icon = icon
	p.mods = mods
	p.hooks = hooks
	p.stackable = stack
	return p


static func build() -> Array[PerkData]:
	var L: Array[PerkData] = []
	L.append(_p("quick_feet", "PIES LIGEROS", "+14% de velocidad de movimiento.", 0, "CUERPO", "boot", {"speed_mult": 0.14}, [], true))
	L.append(_p("hot_barrel", "CAÑÓN CALIENTE", "+12% de cadencia de disparo.", 0, "ARMA", "bolt", {"rate_mult": 0.12}, [], true))
	L.append(_p("sharp_rounds", "MUNICIÓN AFILADA", "+15% de daño.", 0, "ARMA", "bolt", {"dmg_mult": 0.15}, [], true))
	L.append(_p("steady_hand", "PULSO FIRME", "-40% de dispersión.", 0, "ARMA", "aim", {"spread_mult": -0.4}))
	L.append(_p("thick_plates", "PLACAS GRUESAS", "+2 de escudo máximo.", 0, "CUERPO", "shield", {"shield_max": 2}, [], true))
	L.append(_p("deep_cells", "CELDAS PROFUNDAS", "+40 de energía máxima y recarga más rápida.", 0, "NUCLEO", "cell", {"energy_max": 40, "energy_regen": 2.0}, [], true))
	L.append(_p("cold_core", "NÚCLEO FRÍO", "La habilidad se recarga un 25% más rápido.", 1, "NUCLEO", "cell", {"cd_mult": -0.25}))
	L.append(_p("crit_lens", "LENTE CRÍTICA", "+14% de probabilidad crítica. Los críticos hacen x2.", 1, "ARMA", "eye", {"crit": 0.14}, [], true))
	L.append(_p("piercing", "MUNICIÓN PERFORANTE", "Tus proyectiles atraviesan a un enemigo más.", 1, "ARMA", "bolt", {"pierce": 1}, [], true))
	L.append(_p("echo_shot", "DISPARO ECO", "15% de probabilidad de disparar un proyectil extra.", 1, "ARMA", "bolt", {}, ["echo_shot"]))
	L.append(_p("ricochet", "RICOCHET", "Tus proyectiles rebotan una vez en las paredes.", 1, "ARMA", "bounce", {"bounce": 1}))
	L.append(_p("scavenger", "CARROÑERO", "Los enemigos sueltan más monedas y energía.", 0, "UTIL", "coin", {"loot_mult": 0.5}, ["scavenger"]))
	L.append(_p("magnet", "IMÁN", "Los objetos son atraídos desde mucho más lejos.", 0, "UTIL", "magnet", {"magnet": 1.0}))
	L.append(_p("chain_kill", "CADENA DE RAYOS", "Al matar, un rayo salta a otro enemigo cercano.", 2, "ARMA", "zap", {}, ["chain_kill"]))
	L.append(_p("reactive", "BARRERA REACTIVA", "Al romperse el escudo, emite un pulso que empuja a los enemigos y borra proyectiles.", 2, "CUERPO", "shield", {}, ["reactive"]))
	L.append(_p("detonator", "DETONADOR", "Los enemigos explotan al morir causando daño alrededor.", 2, "ARMA", "boom", {}, ["detonator"]))
	L.append(_p("time_slip", "RESBALÓN TEMPORAL", "Al recibir daño, los enemigos se ralentizan 1,5 s.", 2, "CUERPO", "clock", {}, ["time_slip"]))
	L.append(_p("vital_pulse", "PULSO VITAL", "Despejar una sala recupera 1 escudo y energía.", 1, "CUERPO", "heart", {}, ["vital_pulse"]))
	L.append(_p("bloodlust", "SED DE BAJAS", "Cada 25 bajas recuperas 1 de vida.", 2, "CUERPO", "heart", {}, ["bloodlust"]))
	L.append(_p("overcharge", "SOBRECARGA", "Con la energía llena, tus disparos hacen +30% de daño.", 1, "NUCLEO", "cell", {}, ["overcharge"]))
	L.append(_p("glass_cannon", "CAÑÓN DE CRISTAL", "+60% de daño, pero -2 de escudo máximo.", 3, "ARMA", "boom", {"dmg_mult": 0.6, "shield_max": -2}))
	L.append(_p("anomaly_seed", "SEMILLA ANÓMALA", "Cada 6.º disparo es un proyectil anómalo: perfora, rebota y explota.", 4, "ARMA", "star", {}, ["anomaly_seed"]))
	return L
