class_name PassScreen
extends MenuScreen
## Pase de temporada (local / simulado): pista GRATIS y pista PREMIUM, XP, niveles y recompensas.
## El precio sale de Pricing (configuracion central); no hay compras reales.

var track: ScrollPane
const COL_W := 138.0
const CARD_H := 140.0


func _build() -> void:
	title = "PASE DE TEMPORADA"
	accent = Catalog.season.theme_color
	track = ScrollPane.new()
	track.horizontal = true
	track.draw_cb = _draw_track
	track.tap_cb = _track_tap
	add_child(track)
	# desplazar hasta el nivel actual
	var lv := int(PassSystem.level_info(Profile.p, Catalog.season)["level"])
	get_tree().process_frame.connect(func(): track.scroll_to(float(maxi(0, lv - 2)) * COL_W), CONNECT_ONE_SHOT)


func _layout() -> void:
	track.position = Vector2(150.0, HEADER_H + 190.0)
	track.size = Vector2(size.x - 160.0, size.y - HEADER_H - 200.0)
	track.content_len = float(Catalog.season.levels) * COL_W + 20.0


func _draw_body(_k: float) -> void:
	var vs := size
	var s := Catalog.season
	var p := Profile.p
	var info := PassSystem.level_info(p, s)
	# cabecera de temporada
	var hr := Rect2(20, HEADER_H + 14.0, vs.x - 40.0, 160.0)
	UiKit.panel(self, hr, Color("120c2a"), Color(s.theme_color, 0.8), 16.0)
	Gfx.draw_glow(self, Vector2(hr.position.x + 200.0, hr.get_center().y), 260.0, Color(s.theme_color, 0.12))
	UiKit.text(self, Vector2(hr.position.x + 30.0, hr.position.y + 44.0), "TEMPORADA %d" % s.number, 16, Color(s.theme_color.lightened(0.3), 0.9), 0, -1.0, 3.0)
	UiKit.text(self, Vector2(hr.position.x + 30.0, hr.position.y + 88.0), s.display_name, 44, UiKit.TEXT, 0, -1.0, 8.0)
	# nivel
	var lr := Rect2(hr.position.x + 30.0, hr.position.y + 108.0, 360.0, 22.0)
	var f: float = 1.0 if bool(info["max"]) else float(info["into"]) / float(info["need"])
	UiKit.bar(self, lr, f, s.theme_color)
	UiKit.text(self, Vector2(lr.position.x, lr.end.y + 18.0), "NIVEL %d / %d    ·    %s XP" % [int(info["level"]), s.levels, ("MAX" if bool(info["max"]) else "%d / %d" % [int(info["into"]), int(info["need"])])], 15, UiKit.TEXT, 0, -1.0, 3.0, false)
	# premium
	var pr := Rect2(hr.end.x - 400.0, hr.position.y + 14.0, 380.0, 132.0)
	var prem: bool = p.data["pass"]["premium"]
	UiKit.panel(self, pr, Color("1b1238"), Color("ffd24a", 0.9 if not prem else 0.4), 14.0)
	UiIcons.draw(self, "star", Vector2(pr.position.x + 38.0, pr.position.y + 40.0), 20.0, Color("ffd24a"))
	UiKit.text(self, Vector2(pr.position.x + 70.0, pr.position.y + 38.0), "PASE PREMIUM", 24, UiKit.GOLD, 0, -1.0, 5.0)
	UiKit.text(self, Vector2(pr.position.x + 70.0, pr.position.y + 60.0), "Skins, estelas y más monedas por nivel", 13, UiKit.DIM, 0, pr.size.x - 80.0, 2.0, false)
	if prem:
		UiKit.text(self, Vector2(pr.position.x, pr.position.y + 106.0), "¡PREMIUM ACTIVO! (simulado)", 20, UiKit.OK, 1, pr.size.x, 4.0)
	else:
		button("buy_premium", Rect2(pr.position.x + 18.0, pr.position.y + 74.0, pr.size.x - 36.0, 48.0), "DESBLOQUEAR  %s" % Pricing.PASS_PRICE_LABEL, GButton.Style.GOLD, "", 20, true)
	# etiquetas de las pistas
	UiKit.text(self, Vector2(20, track.position.y + 76.0), "PREMIUM", 17, UiKit.GOLD, 0, 120.0, 3.0)
	UiIcons.draw(self, "star", Vector2(34, track.position.y + 100.0), 12.0, Color("ffd24a"))
	UiKit.text(self, Vector2(20, track.position.y + track.size.y - 70.0), "GRATIS", 17, UiKit.OK, 0, 120.0, 3.0)
	var n := PassSystem.claimable_count(p, s)
	button("claim_all", Rect2(vs.x - 260.0, vs.y - 62.0, 240.0, 50.0), "RECLAMAR TODO" if n > 0 else "AL DÍA", GButton.Style.PRIMARY, "", 20, n > 0)


func _draw_track(pane: ScrollPane) -> void:
	var s := Catalog.season
	var p := Profile.p
	var lv := int(PassSystem.level_info(p, s)["level"])
	var prem: bool = p.data["pass"]["premium"]
	var ph := pane.size.y
	var y_prem := 6.0
	var y_node := y_prem + CARD_H + 10.0
	var y_free := y_node + 56.0
	# linea de progreso
	var lx := 0.0
	var line_y := y_node + 22.0
	pane.draw_rect(Rect2(0, line_y - 4.0, float(s.levels) * COL_W, 8.0), Color(0.1, 0.14, 0.26))
	pane.draw_rect(Rect2(0, line_y - 4.0, minf(float(lv) * COL_W + 20.0, float(s.levels) * COL_W), 8.0), Color(s.theme_color, 0.9))
	for L in range(1, s.levels + 1):
		var x := float(L - 1) * COL_W + 6.0
		var reached := L <= lv
		var cx := x + (COL_W - 12.0) * 0.5
		# nodo de nivel
		var nc := Vector2(cx, line_y)
		pane.draw_circle(nc, 22.0, Color(s.theme_color if reached else Color(0.1, 0.14, 0.26)))
		pane.draw_arc(nc, 22.0, 0, TAU, 24, UiKit.INK, 3.0, true)
		UiKit.text(pane, Vector2(nc.x - 22.0, nc.y + 8.0), str(L), 22, Color("04201e") if reached else UiKit.DIM, 1, 44.0)
		_reward_card(pane, Rect2(x, y_prem, COL_W - 12.0, CARD_H), PassSystem.reward_at(s, "premium", L), "premium", L, reached, not prem)
		_reward_card(pane, Rect2(x, y_free, COL_W - 12.0, CARD_H), PassSystem.reward_at(s, "free", L), "free", L, reached, false)


func _reward_card(pane: ScrollPane, r: Rect2, rw: Dictionary, lane: String, level: int, reached: bool, locked_lane: bool) -> void:
	if rw.is_empty():
		return
	var p := Profile.p
	var claimed := PassSystem.is_claimed(p, lane, level)
	var can := PassSystem.can_claim(p, Catalog.season, lane, level)
	var col := Color("ffd24a") if lane == "premium" else Color("5fffc8")
	var key := "r:%s:%d" % [lane, level]
	if pane.is_pressed(key):
		r = r.grow(-3.0)
	var edge := Color(col, 0.35)
	if can:
		edge = Color(col, 0.7 + 0.3 * sin(pane.t * 6.0))
		Gfx.draw_glow(pane, r.get_center(), 90.0, Color(col, 0.18))
	UiKit.panel(pane, r, Color("12192e") if reached else Color("0b1020"), edge, 10.0)
	var cc := r.get_center() + Vector2(0, -12.0)
	var dim := 1.0 if (reached and not locked_lane) else 0.45
	var typ: String = rw["type"]
	match typ:
		"coins":
			UiIcons.draw(pane, "coin", cc, 26.0, Color(Color("ffd24a"), dim))
			UiKit.text(pane, Vector2(r.position.x, r.end.y - 18.0), "%d" % int(rw["amount"]), 20, Color(UiKit.TEXT, dim), 1, r.size.x, 3.0)
		"gems":
			UiIcons.draw(pane, "gem", cc, 26.0, Color(UiKit.GEM, dim))
			UiKit.text(pane, Vector2(r.position.x, r.end.y - 18.0), "%d" % int(rw["amount"]), 20, Color(UiKit.TEXT, dim), 1, r.size.x, 3.0)
		"skin":
			var sk: SkinData = Catalog.skins.get(rw["id"])
			if sk != null:
				PortraitCache.draw(pane, sk.character, Rect2(r.position.x + 10.0, r.position.y + 6.0, r.size.x - 20.0, 86.0), sk.id, Color(1, 1, 1, dim))
				UiKit.text(pane, Vector2(r.position.x, r.end.y - 28.0), "SKIN", 12, Color(Rarity.color(sk.rarity), dim), 1, r.size.x, 2.0)
				UiKit.text(pane, Vector2(r.position.x, r.end.y - 12.0), sk.display_name, 14, Color(UiKit.TEXT, dim), 1, r.size.x, 3.0)
		"character":
			var cd: CharacterData = Catalog.characters.get(rw["id"])
			if cd != null:
				PortraitCache.draw(pane, cd.id, Rect2(r.position.x + 10.0, r.position.y + 6.0, r.size.x - 20.0, 86.0), "", Color(1, 1, 1, dim))
				UiKit.text(pane, Vector2(r.position.x, r.end.y - 28.0), "PERSONAJE", 12, Color(Rarity.color(cd.rarity), dim), 1, r.size.x, 2.0)
				UiKit.text(pane, Vector2(r.position.x, r.end.y - 12.0), cd.display_name, 14, Color(UiKit.TEXT, dim), 1, r.size.x, 3.0)
		_:
			UiIcons.draw(pane, "star", cc, 24.0, Color(col, dim))
			UiKit.text(pane, Vector2(r.position.x, r.end.y - 18.0), PassSystem.reward_label(rw), 15, Color(UiKit.TEXT, dim), 1, r.size.x, 3.0)
	if claimed:
		pane.draw_rect(r, Color(0, 0, 0, 0.5))
		UiIcons.draw(pane, "check", r.get_center(), 22.0, UiKit.OK)
	elif locked_lane and reached:
		UiIcons.draw(pane, "lock", Vector2(r.end.x - 18.0, r.position.y + 18.0), 10.0, Color(1, 1, 1, 0.8))
	elif not reached:
		UiIcons.draw(pane, "lock", Vector2(r.end.x - 18.0, r.position.y + 18.0), 9.0, Color(1, 1, 1, 0.4))
	pane.reg(key, r)


func _track_tap(id: String) -> void:
	var parts := id.split(":")
	var lane := parts[1]
	var level := int(parts[2])
	var p := Profile.p
	var s := Catalog.season
	var r := PassSystem.claim(p, s, lane, level)
	if not r.is_empty():
		AudioMgr.ui("reward")
		show_toast("¡Recompensa reclamada!  " + PassSystem.reward_label(r), UiKit.GOLD)
	elif lane == "premium" and not bool(p.data["pass"]["premium"]):
		show_toast("Requiere el Pase Premium", UiKit.GOLD)
	elif level > int(PassSystem.level_info(p, s)["level"]):
		show_toast("Alcanza el nivel %d para reclamarla" % level, UiKit.DIM)


func tap(id: String) -> void:
	var p := Profile.p
	if id == "claim_all":
		var n := PassSystem.claim_all(p, Catalog.season)
		if n > 0:
			AudioMgr.ui("reward")
			show_toast("¡%d recompensas reclamadas!" % n, UiKit.GOLD)
	elif id == "buy_premium":
		if PassSystem.unlock_premium_mock(p):
			AudioMgr.ui("levelup")
			show_toast("Pase Premium activado (compra SIMULADA)", UiKit.GOLD)
