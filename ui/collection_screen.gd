class_name CollectionScreen
extends MenuScreen
## Coleccion de personajes: cuadricula de retratos (rareza, bloqueo, nivel) y vista de detalle con el personaje animado,
## estadisticas, habilidad, pasiva, arma recomendada, skins y accion (seleccionar / desbloquear).

var grid: ScrollPane
var sel_id := ""
var rig: CharacterRig
var rig_char := ""
var rig_skin := "?"
var skin_pane_open := false
var rig_scale := 3.6
const CARD_W := 150.0
const CARD_H := 188.0
const GAP := 12.0
const COLS := 3


func _build() -> void:
	title = "PERSONAJES"
	accent = Color("27e0cc")
	sel_id = Profile.p.selected_character()
	grid = ScrollPane.new()
	grid.draw_cb = _draw_grid
	grid.tap_cb = _grid_tap
	add_child(grid)
	rig = CharacterRig.new()
	add_child(rig)
	move_child(rig, 0)
	_rebuild_rig()


func _layout() -> void:
	var vs := size
	grid.position = Vector2(20, HEADER_H + 14.0)
	grid.size = Vector2(float(COLS) * (CARD_W + GAP) + 6.0, vs.y - HEADER_H - 30.0)
	var rows := ceili(float(Catalog.char_order.size()) / float(COLS))
	grid.content_len = float(rows) * (CARD_H + GAP) + 10.0
	var dx := grid.position.x + grid.size.x + 24.0
	rig.position = Vector2(dx + 170.0, vs.y * 0.66)
	rig_scale = clampf(vs.y / 720.0, 0.8, 1.3) * 4.3
	rig.scale = Vector2.ONE * rig_scale * rig.menu_k()


func _rebuild_rig() -> void:
	var p := Profile.p
	var c := Catalog.character(sel_id)
	var skin := p.skin_of(c.id)
	if rig_char == sel_id and rig_skin == skin:
		return
	rig_char = sel_id
	rig_skin = skin
	for ch in rig.get_children():
		rig.remove_child(ch)
		ch.queue_free()
	rig.scarf_pts.clear()
	var look: Dictionary = c.look.duplicate()
	if skin != "" and Catalog.skins.has(skin):
		look.merge((Catalog.skins[skin] as SkinData).look, true)
	rig.build(look, Catalog.weapon(c.start_weapon), false)
	rig.auto = true
	rig.kick = 1.0
	rig.scale = Vector2.ONE * rig_scale * rig.menu_k() * 0.88
	var tw := create_tween()
	tw.tween_property(rig, "scale", Vector2.ONE * rig_scale * rig.menu_k(), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw_grid(pane: ScrollPane) -> void:
	var p := Profile.p
	for i in Catalog.char_order.size():
		var id: String = Catalog.char_order[i]
		var c := Catalog.character(id)
		var col := i % COLS
		var row := i / COLS
		var r := Rect2(3.0 + float(col) * (CARD_W + GAP), 4.0 + float(row) * (CARD_H + GAP), CARD_W, CARD_H)
		var owned := p.is_unlocked(id)
		var sel := sel_id == id
		var rc := Rarity.color_anim(c.rarity, pane.t)
		var press := pane.is_pressed("c:" + id)
		if press:
			r = r.grow(-3.0)
		UiKit.panel(pane, r, Color("101a30") if owned else Color("0a1020"), Color(rc, 1.0 if sel else 0.55), 12.0)
		# fondo del retrato
		var pr := Rect2(r.position.x + 8, r.position.y + 8, r.size.x - 16, 112)
		UiKit.gradient_rect(pane, pr, Color(rc.darkened(0.55), 0.9), Color(rc.darkened(0.8), 0.9))
		Gfx.draw_glow(pane, pr.get_center() + Vector2(0, 10), 60.0, Color(rc, 0.25 if owned else 0.08))
		var skin := p.skin_of(id)
		PortraitCache.draw(pane, id, Rect2(pr.position.x + 4, pr.position.y - 8, pr.size.x - 8, pr.size.y + 14), skin, Color.WHITE if owned else Color(0.08, 0.1, 0.16, 0.95))
		if not owned:
			UiIcons.draw(pane, "lock", pr.get_center() + Vector2(0, 4), 18.0, Color(1, 1, 1, 0.85))
		UiKit.text(pane, Vector2(r.position.x, r.position.y + 142.0), c.display_name, 19, UiKit.TEXT if owned else UiKit.DIM, 1, r.size.x, 4.0)
		UiKit.text(pane, Vector2(r.position.x, r.position.y + 162.0), Rarity.label(c.rarity), 12, rc, 1, r.size.x, 2.0)
		if owned:
			var xp := int(p.char_state(id).get("xp", 0))
			var lvl := 1 + xp / 150
			UiKit.pill(pane, Rect2(r.end.x - 44.0, r.position.y + 12.0, 34.0, 22.0), Color("0b1224", 0.9), Color(rc, 0.8), 2.0)
			UiKit.text(pane, Vector2(r.end.x - 44.0, r.position.y + 28.0), str(lvl), 14, UiKit.TEXT, 1, 34.0)
			if p.selected_character() == id:
				UiIcons.draw(pane, "check", Vector2(r.position.x + 24.0, r.position.y + 24.0), 10.0, UiKit.OK)
		pane.reg("c:" + id, r)


func _grid_tap(id: String) -> void:
	if id.begins_with("c:"):
		sel_id = id.substr(2)
		_rebuild_rig()
		AudioMgr.ui("swap", -6.0)


func _draw_body(_k: float) -> void:
	var vs := size
	var p := Profile.p
	var c := Catalog.character(sel_id)
	var owned := p.is_unlocked(sel_id)
	var rc := Rarity.color_anim(c.rarity, t)
	var dx := grid.position.x + grid.size.x + 24.0
	var dw := vs.x - dx - 20.0
	# ---- escenario del personaje
	var stage := Rect2(dx, HEADER_H + 14.0, 340.0, vs.y - HEADER_H - 30.0)
	UiKit.panel(self, stage, Color("0c1428", 0.92), Color(rc, 0.7), 16.0)
	Gfx.draw_glow(self, Vector2(stage.get_center().x, rig.position.y - 80.0), 200.0, Color(rc, 0.2))
	var pc := rig.position + Vector2(0, 4)
	draw_set_transform(pc, 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 130.0, Color(0.02, 0.04, 0.08, 0.7))
	draw_arc(Vector2.ZERO, 130.0, 0, TAU, 40, Color(rc, 0.9), 5.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	UiKit.text(self, Vector2(stage.position.x, stage.position.y + 50.0), c.display_name, 40, UiKit.TEXT, 1, stage.size.x, 7.0)
	UiKit.text(self, Vector2(stage.position.x, stage.position.y + 74.0), "%s · %s" % [c.title, Rarity.label(c.rarity)], 15, rc.lightened(0.2), 1, stage.size.x, 3.0, false)
	# ---- panel de datos
	var info := Rect2(stage.end.x + 14.0, stage.position.y, vs.x - stage.end.x - 34.0, stage.size.y)
	UiKit.panel(self, info, Color("0c1428", 0.92), Color(UiKit.EDGE, 0.4), 16.0)
	var x := info.position.x + 22.0
	var y := info.position.y + 34.0
	var f := UiKit.font_reg()
	draw_multiline_string(f, Vector2(x, y), c.description, HORIZONTAL_ALIGNMENT_LEFT, info.size.x - 44.0, 15, 4, UiKit.DIM)
	y += 62.0
	_stat(Vector2(x, y), "VIDA", float(c.hp) / 10.0, str(c.hp), Color("ff4f6a"), info.size.x - 44.0)
	_stat(Vector2(x, y + 28.0), "ESCUDO", float(c.shield) / 10.0, str(c.shield), Color("4fd0ff"), info.size.x - 44.0)
	_stat(Vector2(x, y + 56.0), "ENERGÍA", float(c.energy) / 250.0, str(c.energy), Color("6a9cff"), info.size.x - 44.0)
	_stat(Vector2(x, y + 84.0), "VELOCIDAD", clampf((c.speed_mult - 0.6) / 0.6, 0.0, 1.0), "%d%%" % int(c.speed_mult * 100.0), Color("5fffc8"), info.size.x - 44.0)
	y += 120.0
	# habilidad y pasiva
	var bw := (info.size.x - 56.0) * 0.5
	_ability_box(Rect2(x, y, bw, 118.0), "HABILIDAD", c.ability_name, c.ability_desc, c.ability_id, "%d EN · %ds" % [c.ability_cost, int(c.ability_cd)], Color("ffd24a"))
	_ability_box(Rect2(x + bw + 12.0, y, bw, 118.0), "PASIVA", c.passive_name, c.passive_desc, "star", "", Color("5fffc8"))
	y += 130.0
	# arma recomendada
	if c.recommended_weapon != "":
		var wd := Catalog.weapon(c.recommended_weapon)
		var wr := Rect2(x, y, info.size.x - 44.0, 52.0)
		UiKit.panel(self, wr, Color("141f3a"), Color(Rarity.color(wd.rarity), 0.6), 10.0, 1.0, false)
		draw_set_transform(wr.position + Vector2(60, 28), 0.0, Vector2(0.8, 0.8))
		WeaponArt.paint(self, wd, 0.0, t)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		UiKit.text(self, Vector2(wr.position.x + 116.0, wr.position.y + 22.0), "ARMA RECOMENDADA", 12, UiKit.DIM, 0, -1.0, 2.0, false)
		UiKit.text(self, Vector2(wr.position.x + 116.0, wr.position.y + 42.0), "%s · %s" % [wd.display_name, wd.sub], 17, UiKit.TEXT, 0, -1.0, 3.0)
		y += 62.0
	# skins
	var skins := _skins_for(sel_id)
	if not skins.is_empty():
		UiKit.text(self, Vector2(x, y + 14.0), "SKINS", 13, UiKit.DIM, 0, -1.0, 2.0, false)
		var cur := p.skin_of(sel_id)
		var chips: Array = [""] + skins
		var sx := x + 56.0
		for sid in chips:
			var r := Rect2(sx, y - 2.0, 44.0, 44.0)
			var is_cur: bool = cur == sid
			var own: bool = sid == "" or p.owns_skin(sid)
			var colr := Color("8fa3c7")
			if sid != "":
				var sk: SkinData = Catalog.skins[sid]
				colr = (sk.look.get("glow", sk.look.get("base", colr)) as Color)
			UiKit.pill(self, r, Color(colr.darkened(0.5), 1.0), Color.WHITE if is_cur else Color(colr, 0.6), 3.0 if is_cur else 2.0)
			draw_circle(r.get_center(), 11.0, colr)
			if not own:
				UiIcons.draw(self, "lock", r.get_center(), 9.0, Color(0, 0, 0, 0.8))
			reg("skin:" + str(sid), r)
			sx += 52.0
		y += 50.0
	# accion principal
	var br := Rect2(info.position.x + 22.0, info.end.y - 82.0, info.size.x - 44.0, 62.0)
	if owned:
		if p.selected_character() == sel_id:
			button("none", br, "SELECCIONADO", GButton.Style.GHOST, "check", 24, false)
		else:
			button("select", br, "SELECCIONAR", GButton.Style.PRIMARY, "check", 28)
	else:
		var ut: String = c.unlock.get("type", "")
		if ut == "pass":
			button("none", br, "RECOMPENSA DEL PASE", GButton.Style.GHOST, "lock", 22, false, "Nivel %d de la temporada" % int(c.unlock.get("level", 30)))
		else:
			var price := int(c.unlock.get("price", 0))
			button("buy", br, "DESBLOQUEAR  %s" % UiKit.format_int(price), GButton.Style.GOLD, "coin", 26, p.coins() >= price)


func _stat(pos: Vector2, label: String, frac: float, val: String, col: Color, w: float) -> void:
	UiKit.text(self, pos + Vector2(0, 14.0), label, 14, UiKit.DIM, 0, -1.0, 2.0)
	UiKit.bar(self, Rect2(pos.x + 110.0, pos.y + 3.0, w - 170.0, 14.0), frac, col)
	UiKit.text(self, pos + Vector2(w - 50.0, 15.0), val, 16, UiKit.TEXT, 2, 50.0, 3.0)


func _ability_box(r: Rect2, head: String, nm: String, desc: String, icon: String, sub: String, col: Color) -> void:
	UiKit.panel(self, r, Color("141f3a"), Color(col, 0.55), 10.0, 1.0, false)
	UiIcons.draw(self, icon, Vector2(r.position.x + 24.0, r.position.y + 28.0), 14.0, col)
	UiKit.text(self, Vector2(r.position.x + 46.0, r.position.y + 20.0), head, 11, UiKit.DIM, 0, -1.0, 2.0, false)
	UiKit.text(self, Vector2(r.position.x + 46.0, r.position.y + 38.0), nm, 14, UiKit.TEXT, 0, r.size.x - 50.0, 3.0)
	draw_multiline_string(UiKit.font_reg(), r.position + Vector2(12.0, 62.0), desc, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 24.0, 13, 3, Color(0.8, 0.9, 1.0, 0.9))
	if sub != "":
		UiKit.text(self, Vector2(r.position.x + 12.0, r.end.y - 6.0), sub, 12, col, 0, -1.0, 2.0, false)


func _skins_for(cid: String) -> Array:
	var out: Array = []
	for sid in Catalog.skins:
		if (Catalog.skins[sid] as SkinData).character == cid:
			out.append(sid)
	out.sort()
	return out


func tap(id: String) -> void:
	var p := Profile.p
	if id == "select":
		if p.select_character(sel_id):
			AudioMgr.ui("ui_confirm")
			show_toast("¡%s listo para la acción!" % Catalog.character(sel_id).display_name, UiKit.OK)
	elif id == "buy":
		var r := ShopSystem.buy_character(p, Catalog.character(sel_id))
		show_toast(r["msg"], UiKit.OK if r["ok"] else UiKit.DANGER)
		if r["ok"]:
			p.select_character(sel_id)
			AudioMgr.ui("reward")
			_rebuild_rig()
	elif id.begins_with("skin:"):
		var sid := id.substr(5)
		if sid == "" or p.owns_skin(sid):
			p.equip_skin(sel_id, sid)
			AudioMgr.ui("swap", -4.0)
			_rebuild_rig()
		else:
			var sk: SkinData = Catalog.skins[sid]
			var r := ShopSystem.buy_skin(p, sk)
			show_toast(r["msg"] + ("  -%d" % int(sk.unlock.get("price", 0)) if r["ok"] else ""), UiKit.OK if r["ok"] else UiKit.DANGER)
			if r["ok"]:
				AudioMgr.ui("reward")
				p.equip_skin(sel_id, sid)
				_rebuild_rig()
