class_name ArmoryScreen
extends MenuScreen
## Armeria: todas las armas del juego. Las que aun no encontraste aparecen como silueta. Detalle con estadisticas
## y descripcion de la mecanica que las hace distintas.

var grid: ScrollPane
var sel_id := "pulsar"
var ids: Array[String] = []
const CARD_W := 138.0
const CARD_H := 116.0
const GAP := 10.0
const COLS := 4


func _build() -> void:
	title = "ARMERÍA"
	accent = Color("ff6a8a")
	ids = []
	for id in Catalog.weapons:
		ids.append(id)
	ids.sort_custom(func(a, b):
		var wa: WeaponData = Catalog.weapons[a]
		var wb: WeaponData = Catalog.weapons[b]
		if wa.rarity != wb.rarity:
			return wa.rarity < wb.rarity
		return wa.display_name < wb.display_name)
	grid = ScrollPane.new()
	grid.draw_cb = _draw_grid
	grid.tap_cb = func(id: String): sel_id = id.substr(2); AudioMgr.ui("swap", -6.0)
	add_child(grid)


func _layout() -> void:
	grid.position = Vector2(20, HEADER_H + 14.0)
	grid.size = Vector2(float(COLS) * (CARD_W + GAP) + 6.0, size.y - HEADER_H - 30.0)
	var rows := ceili(float(ids.size()) / float(COLS))
	grid.content_len = float(rows) * (CARD_H + GAP) + 10.0


func _draw_grid(pane: ScrollPane) -> void:
	var seen: Dictionary = Profile.p.data["weapons_seen"]
	for i in ids.size():
		var wd: WeaponData = Catalog.weapons[ids[i]]
		var col := i % COLS
		var row := i / COLS
		var r := Rect2(3.0 + float(col) * (CARD_W + GAP), 4.0 + float(row) * (CARD_H + GAP), CARD_W, CARD_H)
		var known: bool = seen.get(wd.id, false)
		var rc := Rarity.color_anim(wd.rarity, pane.t)
		if pane.is_pressed("w:" + wd.id):
			r = r.grow(-3.0)
		UiKit.panel(pane, r, Color("101a30") if known else Color("0a1020"), Color(rc, 1.0 if sel_id == wd.id else 0.5), 10.0)
		Gfx.draw_glow(pane, r.get_center(), 54.0, Color(rc, 0.14 if known else 0.04))
		if known:
			pane.draw_set_transform(r.position + Vector2(r.size.x * 0.5 - 22.0, 50.0), 0.0, Vector2(0.9, 0.9))
			WeaponArt.paint(pane, wd, 0.0, pane.t)
			pane.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			UiKit.text(pane, Vector2(r.position.x, r.position.y + 92.0), wd.display_name, 15, UiKit.TEXT, 1, r.size.x, 3.0)
		else:
			UiKit.text(pane, Vector2(r.position.x, r.position.y + 62.0), "?", 40, Color(rc, 0.5), 1, r.size.x, 4.0)
			UiKit.text(pane, Vector2(r.position.x, r.position.y + 92.0), "SIN DESCUBRIR", 12, UiKit.DIM, 1, r.size.x, 2.0, false)
		draw_rect_rar(pane, r, rc)
		pane.reg("w:" + wd.id, r)


func draw_rect_rar(pane: CanvasItem, r: Rect2, rc: Color) -> void:
	pane.draw_rect(Rect2(r.position.x + 10.0, r.end.y - 8.0, r.size.x - 20.0, 3.0), Color(rc, 0.8))


func _draw_body(_k: float) -> void:
	var vs := size
	var wd: WeaponData = Catalog.weapons[sel_id]
	var known: bool = Profile.p.data["weapons_seen"].get(sel_id, false)
	var rc := Rarity.color_anim(wd.rarity, t)
	var dx := grid.position.x + grid.size.x + 24.0
	var pr := Rect2(dx, HEADER_H + 14.0, vs.x - dx - 20.0, vs.y - HEADER_H - 30.0)
	UiKit.panel(self, pr, Color("0c1428", 0.94), Color(rc, 0.7), 16.0)
	Gfx.draw_glow(self, Vector2(pr.get_center().x, pr.position.y + 140.0), 220.0, Color(rc, 0.16))
	if not known:
		UiKit.text(self, Vector2(pr.position.x, pr.position.y + 150.0), "?", 120, Color(rc, 0.4), 1, pr.size.x, 6.0)
		UiKit.text(self, Vector2(pr.position.x, pr.position.y + 230.0), "ARMA SIN DESCUBRIR", 26, UiKit.DIM, 1, pr.size.x, 5.0)
		UiKit.text(self, Vector2(pr.position.x, pr.position.y + 266.0), "Encuéntrala en cofres, jefes o recompensas.", 16, UiKit.DIM, 1, pr.size.x, 3.0, false)
		UiKit.text(self, Vector2(pr.position.x, pr.position.y + 300.0), Rarity.label(wd.rarity), 18, rc, 1, pr.size.x, 3.0)
		return
	UiKit.text(self, Vector2(pr.position.x, pr.position.y + 54.0), wd.display_name, 44, UiKit.TEXT, 1, pr.size.x, 8.0)
	UiKit.text(self, Vector2(pr.position.x, pr.position.y + 82.0), "%s · %s · %s" % [wd.sub, wd.category.to_upper(), Rarity.label(wd.rarity)], 16, rc.lightened(0.25), 1, pr.size.x, 3.0, false)
	draw_set_transform(Vector2(pr.get_center().x - 60.0, pr.position.y + 170.0), 0.0, Vector2(2.6, 2.6))
	WeaponArt.paint(self, wd, 0.2 + 0.2 * sin(t * 3.0), t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var x := pr.position.x + 40.0
	var y := pr.position.y + 250.0
	var w := pr.size.x - 80.0
	draw_multiline_string(UiKit.font_reg(), Vector2(x, y), wd.description, HORIZONTAL_ALIGNMENT_LEFT, w, 18, 3, Color(0.85, 0.93, 1.0))
	y += 56.0
	_stat(Vector2(x, y), "DAÑO / DISPARO", clampf(wd.damage * float(wd.count) / 40.0, 0.0, 1.0), "%.1f%s" % [wd.damage, (" ×%d" % wd.count) if wd.count > 1 else ""], Color("ff4f6a"), w)
	_stat(Vector2(x, y + 30.0), "DPS ESTIMADO", clampf(wd.dps() / 60.0, 0.0, 1.0), "%d" % int(wd.dps()), Color("ffb23d"), w)
	_stat(Vector2(x, y + 60.0), "CADENCIA", clampf(1.0 / maxf(wd.rate, 0.05) / 12.0, 0.0, 1.0), "%.1f/s" % (1.0 / maxf(wd.rate, 0.05)), Color("5fffc8"), w)
	_stat(Vector2(x, y + 90.0), "COSTE ENERGÍA", clampf(wd.energy_cost / 8.0, 0.0, 1.0), "—" if wd.energy_cost <= 0.0 else "%.1f" % wd.energy_cost, Color("6a9cff"), w)
	_stat(Vector2(x, y + 120.0), "PRECISIÓN", clampf(1.0 - wd.spread * 2.0, 0.05, 1.0), "%d%%" % int(clampf(1.0 - wd.spread * 2.0, 0.0, 1.0) * 100.0), Color("c47bff"), w)
	# quien la recomienda
	var rec: Array[String] = []
	for cid in Catalog.char_order:
		var c := Catalog.character(cid)
		if c.start_weapon == sel_id or c.recommended_weapon == sel_id:
			rec.append(c.display_name)
	if not rec.is_empty():
		UiKit.text(self, Vector2(x, pr.end.y - 28.0), "IDEAL PARA:  " + ", ".join(rec), 15, UiKit.DIM, 0, w, 3.0, false)


func _stat(pos: Vector2, label: String, frac: float, val: String, col: Color, w: float) -> void:
	UiKit.text(self, pos + Vector2(0, 14.0), label, 14, UiKit.DIM, 0, -1.0, 2.0)
	UiKit.bar(self, Rect2(pos.x + 190.0, pos.y + 3.0, w - 290.0, 14.0), frac, col)
	UiKit.text(self, pos + Vector2(w - 80.0, 15.0), val, 16, UiKit.TEXT, 2, 80.0, 3.0)
