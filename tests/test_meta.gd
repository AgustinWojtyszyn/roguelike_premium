extends RefCounted
## Misiones, pase de batalla, tienda, recompensas de run y desbloqueos. Todo sobre PlayerProfile sin disco.

func run(t) -> void:
	var date := "2026-10-06"
	# ---------------------------------------------------------------- misiones
	var p := PlayerProfile.new()
	t.check(MissionSystem.refresh(p, Catalog.missions, date, "s1"), "primer refresh asigna misiones")
	t.eq(MissionSystem.items(p, "daily").size(), 3, "3 diarias")
	t.eq(MissionSystem.items(p, "weekly").size(), 3, "3 semanales")
	t.eq(MissionSystem.items(p, "season").size(), 6, "6 de temporada")
	var ids_a: Array = MissionSystem.items(p, "daily").map(func(i): return i["id"])
	var q := PlayerProfile.new()
	MissionSystem.refresh(q, Catalog.missions, date, "s1")
	var ids_b: Array = MissionSystem.items(q, "daily").map(func(i): return i["id"])
	t.eq(ids_a, ids_b, "mismas misiones para la misma fecha (determinista)")
	t.check(not MissionSystem.refresh(p, Catalog.missions, date, "s1"), "mismo dia: sin cambios")
	var q2 := PlayerProfile.new()
	MissionSystem.refresh(q2, Catalog.missions, "2026-10-07", "s1")
	t.check(MissionSystem.refresh(p, Catalog.missions, "2026-10-07", "s1"), "dia nuevo: reasigna")
	# progreso y reclamo
	var first: Dictionary = MissionSystem.items(p, "daily")[0]
	var def: MissionData = Catalog.missions[first["id"]]
	MissionSystem.record(p, Catalog.missions, def.metric, def.target - 1)
	t.check(not MissionSystem.is_complete(first, def), "casi completa no cuenta")
	t.eq(MissionSystem.claim(p, Catalog.missions, "daily", 0), {}, "no se reclama incompleta")
	MissionSystem.record(p, Catalog.missions, def.metric, 5)
	t.eq(int(first["progress"]), def.target, "progreso topeado al objetivo")
	var coins_before := p.coins()
	var r := MissionSystem.claim(p, Catalog.missions, "daily", 0)
	t.check(not r.is_empty(), "reclamo de mision completa")
	t.eq(p.coins(), coins_before + def.reward_coins, "monedas de mision acreditadas")
	t.eq(MissionSystem.claim(p, Catalog.missions, "daily", 0), {}, "no se reclama dos veces")
	# ---------------------------------------------------------------- pase
	var pp := PlayerProfile.new()
	var s: SeasonData = Catalog.season
	t.eq(int(PassSystem.level_info(pp, s)["level"]), 0, "pase en nivel 0")
	pp.data["pass"]["xp"] = s.xp_for_level(1)
	t.eq(int(PassSystem.level_info(pp, s)["level"]), 1, "1 nivel con XP exacta")
	pp.data["pass"]["xp"] = s.total_xp_for(5) + 3
	t.eq(int(PassSystem.level_info(pp, s)["level"]), 5, "nivel 5")
	t.check(PassSystem.can_claim(pp, s, "free", 3), "puede reclamar gratis nivel 3 (alcanzado)")
	t.check(not PassSystem.can_claim(pp, s, "free", 6), "no reclama nivel no alcanzado")
	t.check(not PassSystem.can_claim(pp, s, "premium", 3), "premium bloqueado sin pase")
	var cb := pp.coins()
	t.check(not PassSystem.claim(pp, s, "free", 1).is_empty(), "reclamo gratis")
	t.check(pp.coins() > cb, "monedas del pase acreditadas")
	t.check(PassSystem.claim(pp, s, "free", 1).is_empty(), "no reclama dos veces")
	t.check(PassSystem.claim(pp, s, "free", 3).get("type") == "skin" and pp.owns_skin("vesper_ember"), "recompensa de skin entrega la skin")
	t.check(PassSystem.unlock_premium_mock(pp), "premium simulado se activa")
	t.check(PassSystem.can_claim(pp, s, "premium", 4), "premium reclamable tras activar")
	var n := PassSystem.claim_all(pp, s)
	t.check(n > 0, "reclamar todo entrega recompensas (%d)" % n)
	t.eq(PassSystem.claimable_count(pp, s), 0, "nada pendiente tras reclamar todo")
	t.check(Pricing.PASS_PRICE_USD >= 2.0 and Pricing.PASS_PRICE_USD <= 4.0, "precio del pase en el rango objetivo USD 2-4")
	# maximo
	pp.data["pass"]["xp"] = s.total_xp_for(s.levels) + 9999
	t.check(bool(PassSystem.level_info(pp, s)["max"]), "pase maximo")
	t.eq(int(PassSystem.level_info(pp, s)["level"]), s.levels, "nivel tope = niveles de la temporada")
	# personaje de recompensa final
	PassSystem.claim_all(pp, s)
	t.check(pp.is_unlocked("paradoja"), "el nivel 30 gratis desbloquea a Paradoja")
	# ---------------------------------------------------------------- tienda
	var sp := PlayerProfile.new()
	var day := "2026-10-06"
	t.check(ShopSystem.gift_available(sp, day), "regalo disponible")
	var gift: ShopOffer = Catalog.offers["gift_daily"]
	t.check(ShopSystem.purchase(sp, gift, day)["ok"], "reclamar regalo")
	t.check(not ShopSystem.purchase(sp, gift, day)["ok"], "no reclama dos veces el mismo dia")
	t.check(ShopSystem.gift_available(sp, "2026-10-07"), "al dia siguiente vuelve")
	var daily := ShopSystem.daily_offers(sp, Catalog.skins, Catalog.characters, day)
	t.check(daily.size() >= 2, "ofertas diarias")
	var daily2 := ShopSystem.daily_offers(sp, Catalog.skins, Catalog.characters, day)
	t.eq(daily.map(func(o): return o.id), daily2.map(func(o): return o.id), "ofertas diarias deterministas")
	var poor := PlayerProfile.new()
	poor.data["coins"] = 10
	var skin_offer: ShopOffer = daily[0]
	t.check(not ShopSystem.purchase(poor, skin_offer, day)["ok"], "sin fondos no compra")
	t.eq(poor.coins(), 10, "sin fondos: monedas intactas")
	var rich := PlayerProfile.new()
	rich.data["coins"] = 99999
	var cbefore := rich.coins()
	t.check(ShopSystem.purchase(rich, skin_offer, day)["ok"], "con fondos compra")
	t.check(rich.coins() < cbefore, "monedas descontadas")
	t.check(not ShopSystem.purchase(rich, skin_offer, day)["ok"], "no compra dos veces la misma skin")
	var gems := rich.gems()
	t.check(ShopSystem.purchase(rich, Catalog.offers["gems_s"], day)["ok"], "compra SIMULADA de gemas")
	t.eq(rich.gems(), gems + 80, "gemas acreditadas por la compra simulada")
	t.check(ShopSystem.buy_character(rich, Catalog.character("kiro9"))["ok"], "desbloquear personaje con monedas")
	t.check(rich.is_unlocked("kiro9"), "personaje desbloqueado")
	t.check(not ShopSystem.buy_character(rich, Catalog.character("paradoja"))["ok"], "Paradoja solo por el pase")
	# ---------------------------------------------------------------- recompensas de run
	var rp := PlayerProfile.new()
	MissionSystem.refresh(rp, Catalog.missions, date, "s1")
	var ch := Catalog.chapter("ch1")
	var coins0 := rp.coins()
	var summary := {"character": "vesper", "chapter": "ch1", "won": true, "stages": 5, "rooms": 5, "kills": 40, "kills_cat": {"smg": 30, "pistol": 10}, "chests": 2, "perks": 2, "bosses": 1, "nodamage_rooms": 1, "coins": 90, "time": 300.0, "weapons_seen": ["pulsar", "lancex"]}
	var res := RunRewards.apply(rp, summary, ch, Catalog.missions, "ch2")
	t.eq(rp.coins(), coins0 + 90 + ch.coin_reward, "monedas de run + bono de capitulo")
	t.check(int(res["xp"]) > 0 and int(rp.data["xp_total"]) == int(res["xp"]), "XP acreditada")
	t.eq(int(rp.data["pass"]["xp"]), int(res["xp"]), "la XP alimenta el pase")
	t.check(rp.chapter_state("ch2")["unlocked"], "ganar desbloquea el siguiente capitulo")
	t.eq(int(rp.data["stats"]["kills"]), 40, "estadisticas de bajas")
	t.eq(int(rp.data["stats"]["wins"]), 1, "victorias")
	t.check(rp.data["weapons_seen"].get("lancex", false), "arma descubierta registrada")
	# derrota: sin bono y sin desbloqueo
	var rl := PlayerProfile.new()
	var lose := summary.duplicate()
	lose["won"] = false
	var c1 := rl.coins()
	RunRewards.apply(rl, lose, ch, Catalog.missions, "ch2")
	t.eq(rl.coins(), c1 + 90, "derrota: solo monedas recolectadas")
	t.check(not rl.chapter_state("ch2")["unlocked"], "derrota no desbloquea capitulo")
	t.eq(int(rl.data["stats"]["deaths"]), 1, "muertes registradas")
	# skins / cosmeticos no tocan estadisticas del personaje
	for sid in Catalog.skins:
		var sk: SkinData = Catalog.skins[sid]
		t.check(not ("hp" in sk.look or "shield" in sk.look or "energy" in sk.look), "skin %s solo cosmetica" % sid)
