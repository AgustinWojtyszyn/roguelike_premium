class_name ContentMeta
extends RefCounted
## Misiones, temporada (pase) y ofertas de tienda. Todo local; sin red ni pagos.

static func _m(id: String, scope: String, title: String, metric: String, target: int, coins: int, xp: int, gems: int = 0) -> MissionData:
	var m := MissionData.new()
	m.id = id
	m.scope = scope
	m.title = title
	m.metric = metric
	m.target = target
	m.reward_coins = coins
	m.reward_xp = xp
	m.reward_gems = gems
	return m


static func missions() -> Array[MissionData]:
	var L: Array[MissionData] = []
	# diarias
	L.append(_m("d_kills_40", "daily", "Elimina 40 enemigos", "kills", 40, 60, 25))
	L.append(_m("d_kills_80", "daily", "Elimina 80 enemigos", "kills", 80, 110, 40))
	L.append(_m("d_chest_2", "daily", "Abre 2 cofres", "chests", 2, 70, 25))
	L.append(_m("d_rooms_6", "daily", "Despeja 6 salas", "rooms", 6, 80, 30))
	L.append(_m("d_smg_25", "daily", "Elimina 25 enemigos con subfusiles", "kills_cat:smg", 25, 70, 25))
	L.append(_m("d_shotgun_20", "daily", "Elimina 20 enemigos con escopetas", "kills_cat:shotgun", 20, 70, 25))
	L.append(_m("d_energy_20", "daily", "Elimina 20 enemigos con armas de energía", "kills_cat:energy", 20, 70, 25))
	L.append(_m("d_perk_1", "daily", "Elige 1 perk", "perks", 1, 50, 20))
	L.append(_m("d_flawless_2", "daily", "Despeja 2 salas sin recibir daño", "nodamage_rooms", 2, 90, 35))
	# semanales
	L.append(_m("w_chapters_2", "weekly", "Completa 2 capítulos", "chapters", 2, 250, 90, 10))
	L.append(_m("w_kills_400", "weekly", "Elimina 400 enemigos", "kills", 400, 280, 100))
	L.append(_m("w_bosses_2", "weekly", "Derrota a 2 jefes", "bosses", 2, 300, 100, 10))
	L.append(_m("w_chest_10", "weekly", "Abre 10 cofres", "chests", 10, 220, 80))
	L.append(_m("w_rooms_40", "weekly", "Despeja 40 salas", "rooms", 40, 260, 90))
	L.append(_m("w_flawless_10", "weekly", "Despeja 10 salas sin recibir daño", "nodamage_rooms", 10, 300, 110))
	# temporada
	L.append(_m("s_kills_3000", "season", "Elimina 3000 enemigos", "kills", 3000, 600, 300, 20))
	L.append(_m("s_chapters_10", "season", "Completa 10 capítulos", "chapters", 10, 700, 350, 20))
	L.append(_m("s_bosses_10", "season", "Derrota a 10 jefes", "bosses", 10, 700, 350, 20))
	L.append(_m("s_chest_60", "season", "Abre 60 cofres", "chests", 60, 500, 250, 10))
	L.append(_m("s_vesper_5", "season", "Gana 5 capítulos con Vesper", "wins_char:vesper", 5, 400, 200))
	L.append(_m("s_perk_30", "season", "Elige 30 perks", "perks", 30, 500, 250))
	return L


static func _r(level: int, type: String, d: Dictionary = {}) -> Dictionary:
	var r := {"level": level, "type": type}
	r.merge(d)
	return r


static func season() -> SeasonData:
	var s := SeasonData.new()
	s.id = "s1"
	s.display_name = "ECLIPSE CORRUPTO"
	s.number = 1
	s.theme_color = Color("27e0cc")
	s.levels = 30
	s.xp_base = 100
	s.xp_step = 10
	var free: Array = []
	var prem: Array = []
	for lv in range(1, 31):
		# pista gratis: monedas casi siempre, algun hito
		if lv % 5 == 0:
			free.append(_r(lv, "gems", {"amount": 15}))
		else:
			free.append(_r(lv, "coins", {"amount": 80 + lv * 10}))
		# pista premium: cosmeticos, monedas dobles y extras
		if lv % 5 == 0 and lv < 30:
			prem.append(_r(lv, "coins", {"amount": 400 + lv * 20}))
		else:
			prem.append(_r(lv, "coins", {"amount": 160 + lv * 14}))
	free[2] = _r(3, "skin", {"id": "vesper_ember"})
	free[11] = _r(12, "character", {"id": "kiro9"})
	free[19] = _r(20, "skin", {"id": "basalto_arctic"})
	free[29] = _r(30, "character", {"id": "paradoja"})
	prem[3] = _r(4, "skin", {"id": "sera_noir"})
	prem[8] = _r(9, "trail", {"id": "trail_ember"})
	prem[13] = _r(14, "skin", {"id": "halo_dusk"})
	prem[17] = _r(18, "frame", {"id": "frame_gold"})
	prem[21] = _r(22, "skin", {"id": "kiro9_gold"})
	prem[25] = _r(26, "skin", {"id": "vesper_frost"})
	prem[29] = _r(30, "skin", {"id": "sable_ghost"})
	s.free_rewards = free
	s.premium_rewards = prem
	return s


static func _o(id: String, kind: String, item: String, title: String, sub: String, cost: Dictionary, grants: Dictionary, daily: bool = false, badge: String = "") -> ShopOffer:
	var o := ShopOffer.new()
	o.id = id
	o.kind = kind
	o.item = item
	o.title = title
	o.subtitle = sub
	o.cost = cost
	o.grants = grants
	o.daily = daily
	o.badge = badge
	return o


static func shop_offers() -> Array[ShopOffer]:
	var L: Array[ShopOffer] = []
	L.append(_o("gift_daily", "gift", "", "REGALO DIARIO", "Una vez por día", {}, {"coins": 120}, true, "GRATIS"))
	L.append(_o("gems_s", "gems", "", "PUÑADO DE GEMAS", "80 gemas", {"usd": 0.99}, {"gems": 80}))
	L.append(_o("gems_m", "gems", "", "BOLSA DE GEMAS", "450 gemas", {"usd": 4.99}, {"gems": 450}, false, "MEJOR VALOR"))
	L.append(_o("gems_l", "gems", "", "CAJA DE GEMAS", "1000 gemas", {"usd": 9.99}, {"gems": 1000}))
	L.append(_o("coins_s", "coins", "", "BOLSA DE MONEDAS", "500 monedas", {"gems": 30}, {"coins": 500}))
	L.append(_o("coins_m", "coins", "", "BAÚL DE MONEDAS", "2500 monedas", {"gems": 120}, {"coins": 2500}))
	L.append(_o("pack_starter", "pack", "", "PACK INICIAL", "Skin Brasa + 1500 monedas", {"usd": 1.99}, {"coins": 1500, "skin": "vesper_ember"}, false, "ÚNICA VEZ"))
	return L
