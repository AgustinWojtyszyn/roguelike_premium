class_name ShopSystem
extends RefCounted
## Tienda local/simulada. Sin red ni pagos reales: las ofertas en USD solo funcionan si Pricing.MOCK_PURCHASES.

static func rotation_key(date: String) -> String:
	return date


## Ofertas diarias (skins y personajes a la venta) elegidas de forma determinista por fecha.
static func daily_offers(profile: PlayerProfile, catalog_skins: Dictionary, catalog_chars: Dictionary, date: String) -> Array[ShopOffer]:
	var out: Array[ShopOffer] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("shop" + date)
	var skin_ids: Array = catalog_skins.keys()
	skin_ids.sort()
	for i in range(skin_ids.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = skin_ids[i]
		skin_ids[i] = skin_ids[j]
		skin_ids[j] = t
	for sid in skin_ids:
		if out.size() >= 2:
			break
		var s: SkinData = catalog_skins[sid]
		var o := ShopOffer.new()
		o.id = "daily_" + sid
		o.kind = "skin"
		o.item = sid
		o.title = s.display_name
		o.subtitle = catalog_chars[s.character].display_name
		var price := int(s.unlock.get("price", 1000))
		o.cost = {"coins": int(price * 0.75)}
		o.badge = "-25%"
		o.daily = true
		out.append(o)
	# un personaje bloqueado de precio en monedas
	var cl: Array = catalog_chars.values()
	cl.sort_custom(func(a, b): return a.order < b.order)
	for c in cl:
		if not profile.is_unlocked(c.id) and c.unlock.get("type", "") == "coins":
			var o := ShopOffer.new()
			o.id = "char_" + c.id
			o.kind = "character"
			o.item = c.id
			o.title = c.display_name
			o.subtitle = c.title
			o.cost = {"coins": int(c.unlock["price"])}
			out.append(o)
			break
	return out


static func gift_available(profile: PlayerProfile, date: String) -> bool:
	return profile.data["shop"]["daily_gift"] != date


## Intenta comprar/reclamar. Devuelve {"ok": bool, "msg": String}.
static func purchase(profile: PlayerProfile, offer: ShopOffer, date: String) -> Dictionary:
	if offer.kind == "gift":
		if not gift_available(profile, date):
			return {"ok": false, "msg": "Ya reclamaste el regalo de hoy"}
		profile.data["shop"]["daily_gift"] = date
		_grant(profile, offer.grants)
		return {"ok": true, "msg": "¡Regalo reclamado!"}
	if offer.kind == "skin" and profile.owns_skin(offer.item):
		return {"ok": false, "msg": "Ya tienes esta skin"}
	if offer.kind == "character" and profile.is_unlocked(offer.item):
		return {"ok": false, "msg": "Ya tienes este personaje"}
	if offer.id == "pack_starter" and profile.data["shop"]["bought"].get(offer.id, false):
		return {"ok": false, "msg": "Pack ya adquirido"}
	if offer.cost.has("usd"):
		if not Pricing.MOCK_PURCHASES:
			return {"ok": false, "msg": "Compras no disponibles todavía"}
		_grant(profile, _grants_for(offer))
		profile.data["shop"]["bought"][offer.id] = true
		profile.touch()
		return {"ok": true, "msg": "Compra SIMULADA (sin cargo real)"}
	if not profile.spend(offer.cost):
		return {"ok": false, "msg": "Te faltan monedas o gemas"}
	_grant(profile, _grants_for(offer))
	profile.data["shop"]["bought"][offer.id] = true
	profile.touch()
	return {"ok": true, "msg": "¡Compra realizada!"}


static func _grants_for(offer: ShopOffer) -> Dictionary:
	if not offer.grants.is_empty():
		return offer.grants
	match offer.kind:
		"skin":
			return {"skin": offer.item}
		"character":
			return {"character": offer.item}
	return {}


static func _grant(profile: PlayerProfile, g: Dictionary) -> void:
	if g.has("coins"):
		profile.add_coins(int(g["coins"]))
	if g.has("gems"):
		profile.add_gems(int(g["gems"]))
	if g.has("skin"):
		profile.grant_skin(str(g["skin"]))
	if g.has("character"):
		profile.unlock_character(str(g["character"]))


## Desbloqueo de personaje con monedas desde la coleccion.
static func buy_character(profile: PlayerProfile, c: CharacterData) -> Dictionary:
	if profile.is_unlocked(c.id):
		return {"ok": false, "msg": "Ya desbloqueado"}
	var t: String = c.unlock.get("type", "")
	if t == "pass":
		return {"ok": false, "msg": "Recompensa del pase de temporada"}
	if t == "default":
		profile.unlock_character(c.id)
		return {"ok": true, "msg": ""}
	var cost := {"coins": int(c.unlock.get("price", 0))} if t == "coins" else {"gems": int(c.unlock.get("price", 0))}
	if not profile.spend(cost):
		return {"ok": false, "msg": "Te faltan monedas"}
	profile.unlock_character(c.id)
	return {"ok": true, "msg": "¡%s desbloqueado!" % c.display_name}


static func buy_skin(profile: PlayerProfile, s: SkinData) -> Dictionary:
	if profile.owns_skin(s.id):
		return {"ok": false, "msg": "Ya tienes esta skin"}
	if not profile.spend({"coins": int(s.unlock.get("price", 0))}):
		return {"ok": false, "msg": "Te faltan monedas"}
	profile.grant_skin(s.id)
	return {"ok": true, "msg": "Skin obtenida"}
