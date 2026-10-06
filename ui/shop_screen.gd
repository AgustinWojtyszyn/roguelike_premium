class_name ShopScreen
extends MenuScreen
## Tienda local / simulada: regalo diario, ofertas del dia (skins y personajes por monedas), gemas, packs y monedas.
## No hay pagos reales; las ofertas en USD se simulan con aviso claro (Pricing.MOCK_PURCHASES).

var pane: ScrollPane
var offers_daily: Array[ShopOffer] = []
var today := ""
const CARD_W := 230.0
const CARD_H := 250.0


func _build() -> void:
	title = "TIENDA"
	accent = Color("ffb23d")
	today = MissionSystem.today_key()
	_rebuild_offers()
	pane = ScrollPane.new()
	pane.draw_cb = _draw_list
	pane.tap_cb = _list_tap
	add_child(pane)


func _rebuild_offers() -> void:
	offers_daily = ShopSystem.daily_offers(Profile.p, Catalog.skins, Catalog.characters, today)


func _layout() -> void:
	pane.position = Vector2(20, HEADER_H + 10.0)
	pane.size = Vector2(size.x - 40.0, size.y - HEADER_H - 20.0)
	pane.content_len = 1200.0


func _draw_list(p: ScrollPane) -> void:
	var w := p.size.x
	var y := 8.0
	# --- regalo diario
	_section(p, "REGALO DIARIO", y)
	y += 36.0
	var gift: ShopOffer = Catalog.offers["gift_daily"]
	var avail := ShopSystem.gift_available(Profile.p, today)
	var gr := Rect2(0, y, w, 96.0)
	UiKit.panel(p, gr, Color("1c1630"), Color("ffd24a", 0.8 if avail else 0.25), 14.0)
	UiIcons.draw(p, "gift", Vector2(gr.position.x + 56.0, gr.get_center().y), 28.0, Color("ffd24a") if avail else UiKit.DIM)
	UiKit.text(p, Vector2(gr.position.x + 110.0, gr.position.y + 42.0), "¡Un regalo cada día!", 26, UiKit.TEXT, 0, -1.0, 5.0)
	UiKit.text(p, Vector2(gr.position.x + 110.0, gr.position.y + 70.0), "+%d monedas gratis" % int(gift.grants["coins"]), 16, UiKit.DIM, 0, -1.0, 3.0, false)
	var gb := Rect2(gr.end.x - 260.0, gr.position.y + 20.0, 236.0, 56.0)
	if avail:
		var press := p.is_pressed("gift")
		var body := UiKit.chunky(p, gb, Color("ffe27a"), Color("f0a020"), 1.0 if press else 0.0)
		UiKit.text(p, Vector2(gb.position.x, body.position.y + 38.0), "RECLAMAR", 24, Color("3a2200"), 1, gb.size.x)
		p.reg("gift", gb)
	else:
		UiKit.pill(p, gb, Color(0.1, 0.14, 0.24), Color(1, 1, 1, 0.1), 2.0)
		UiKit.text(p, Vector2(gb.position.x, gb.position.y + 37.0), "VUELVE MAÑANA", 18, UiKit.DIM, 1, gb.size.x, 2.0)
	y += 120.0
	# --- ofertas del dia
	_section(p, "OFERTAS DEL DÍA", y)
	y += 36.0
	var x := 0.0
	for o in offers_daily:
		_offer_card(p, Rect2(x, y, CARD_W, CARD_H), o)
		x += CARD_W + 16.0
	y += CARD_H + 30.0
	# --- gemas
	_section(p, "GEMAS", y)
	y += 36.0
	x = 0.0
	for id in ["gems_s", "gems_m", "gems_l"]:
		_offer_card(p, Rect2(x, y, CARD_W, 200.0), Catalog.offers[id])
		x += CARD_W + 16.0
	y += 230.0
	# --- packs y monedas
	_section(p, "PACKS Y MONEDAS", y)
	y += 36.0
	x = 0.0
	for id in ["pack_starter", "coins_s", "coins_m"]:
		_offer_card(p, Rect2(x, y, CARD_W, 200.0), Catalog.offers[id])
		x += CARD_W + 16.0
	y += 230.0
	UiKit.text(p, Vector2(0, y + 16.0), "Las compras con dinero real todavía no están activas: las ofertas en US$ se simulan sin ningún cargo.", 14, UiKit.DIM, 0, w, 2.0, false)
	p.content_len = y + 50.0


func _section(p: ScrollPane, s: String, y: float) -> void:
	UiKit.text(p, Vector2(0, y + 22.0), s, 22, UiKit.GOLD, 0, -1.0, 4.0)
	p.draw_rect(Rect2(0, y + 28.0, p.size.x, 2.0), Color(1, 0.8, 0.3, 0.25))


func _offer_card(p: ScrollPane, r: Rect2, o: ShopOffer) -> void:
	var key := "o:" + o.id
	if p.is_pressed(key):
		r = r.grow(-3.0)
	var owned := false
	var rc := Color("ffb23d")
	match o.kind:
		"skin":
			owned = Profile.p.owns_skin(o.item)
			rc = Rarity.color((Catalog.skins[o.item] as SkinData).rarity)
		"character":
			owned = Profile.p.is_unlocked(o.item)
			rc = Rarity.color((Catalog.characters[o.item] as CharacterData).rarity)
		"gems":
			rc = UiKit.GEM
		"pack":
			owned = Profile.p.data["shop"]["bought"].get(o.id, false)
			rc = Color("ff6a8a")
	UiKit.panel(p, r, Color("101a30"), Color(rc, 0.7), 12.0)
	var top := Rect2(r.position.x + 10.0, r.position.y + 10.0, r.size.x - 20.0, r.size.y - 100.0)
	UiKit.gradient_rect(p, top, Color(rc.darkened(0.6), 0.9), Color(rc.darkened(0.8), 0.9))
	Gfx.draw_glow(p, top.get_center(), 70.0, Color(rc, 0.2))
	match o.kind:
		"skin":
			var sk: SkinData = Catalog.skins[o.item]
			PortraitCache.draw(p, sk.character, Rect2(top.position.x + 10.0, top.position.y - 6.0, top.size.x - 20.0, top.size.y + 10.0), sk.id)
		"character":
			PortraitCache.draw(p, o.item, Rect2(top.position.x + 10.0, top.position.y - 6.0, top.size.x - 20.0, top.size.y + 10.0))
		"gems":
			UiIcons.draw(p, "gem", top.get_center(), 34.0, UiKit.GEM)
		"coins":
			UiIcons.draw(p, "coin", top.get_center(), 34.0, Color("ffd24a"))
		_:
			UiIcons.draw(p, "chest", top.get_center(), 34.0, Color("ff6a8a"))
	UiKit.text(p, Vector2(r.position.x, r.end.y - 72.0), o.title, 17, UiKit.TEXT, 1, r.size.x, 3.0)
	UiKit.text(p, Vector2(r.position.x, r.end.y - 54.0), o.subtitle, 12, UiKit.DIM, 1, r.size.x, 2.0, false)
	if o.badge != "":
		var bw := UiKit.text_width(o.badge, 11) + 18.0
		UiKit.pill(p, Rect2(r.end.x - bw - 6.0, r.position.y + 6.0, bw, 22.0), Color("ff4a5a"), UiKit.INK, 2.0)
		UiKit.text(p, Vector2(r.end.x - bw - 6.0, r.position.y + 22.0), o.badge, 11, Color.WHITE, 1, bw)
	var br := Rect2(r.position.x + 14.0, r.end.y - 42.0, r.size.x - 28.0, 34.0)
	if owned:
		UiIcons.draw(p, "check", br.get_center(), 14.0, UiKit.OK)
	else:
		var label := ""
		var icon := ""
		var usd := false
		if o.cost.has("usd"):
			label = "US$ %.2f" % float(o.cost["usd"])
			usd = true
		elif o.cost.has("coins"):
			label = UiKit.format_int(int(o.cost["coins"]))
			icon = "coin"
		elif o.cost.has("gems"):
			label = UiKit.format_int(int(o.cost["gems"]))
			icon = "gem"
		var can := Profile.p.can_afford(o.cost) or usd
		var body := UiKit.chunky(p, br, Color("ffe27a") if can else Color("5a6070"), Color("f0a020") if can else Color("33384a"), 1.0 if p.is_pressed(key) else 0.0, 0.0, 10.0, 2.5)
		if icon != "":
			UiIcons.draw(p, icon, Vector2(br.position.x + br.size.x * 0.5 - UiKit.text_width(label, 18) * 0.5 - 14.0, body.get_center().y), 9.0, Color("3a2200"))
		UiKit.text(p, Vector2(br.position.x + (10.0 if icon != "" else 0.0), body.get_center().y + 7.0), label, 18, Color("3a2200") if can else UiKit.DIM, 1, br.size.x)
	p.reg(key, r)


func _list_tap(id: String) -> void:
	var pf := Profile.p
	if id == "gift":
		var r := ShopSystem.purchase(pf, Catalog.offers["gift_daily"], today)
		show_toast(r["msg"], UiKit.GOLD if r["ok"] else UiKit.DANGER)
		if r["ok"]:
			AudioMgr.ui("reward")
	elif id.begins_with("o:"):
		var oid := id.substr(2)
		var o: ShopOffer = Catalog.offers.get(oid)
		if o == null:
			for d in offers_daily:
				if d.id == oid:
					o = d
		if o == null:
			return
		var r := ShopSystem.purchase(pf, o, today)
		show_toast(r["msg"], UiKit.OK if r["ok"] else UiKit.DANGER)
		AudioMgr.ui("reward" if r["ok"] else "ui_error")
		if r["ok"]:
			_rebuild_offers()
