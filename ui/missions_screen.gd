class_name MissionsScreen
extends MenuScreen
## Misiones diarias / semanales / de temporada con progreso y reclamo de recompensas.

var tab := "daily"
var pane: ScrollPane
const TABS := [["daily", "DIARIAS"], ["weekly", "SEMANALES"], ["season", "TEMPORADA"]]


func _build() -> void:
	title = "MISIONES"
	accent = Color("5fffc8")
	MissionSystem.refresh(Profile.p, Catalog.missions, MissionSystem.today_key(), Catalog.season.id)
	pane = ScrollPane.new()
	pane.draw_cb = _draw_list
	pane.tap_cb = _list_tap
	add_child(pane)


func _layout() -> void:
	var w := minf(900.0, size.x - 60.0)
	pane.position = Vector2((size.x - w) * 0.5, HEADER_H + 90.0)
	pane.size = Vector2(w, size.y - HEADER_H - 104.0)
	pane.content_len = float(MissionSystem.items(Profile.p, tab).size()) * 118.0 + 10.0


func _draw_body(_k: float) -> void:
	var w := minf(900.0, size.x - 60.0)
	var x0 := (size.x - w) * 0.5
	var tw := w / 3.0
	for i in TABS.size():
		var r := Rect2(x0 + float(i) * tw + 4.0, HEADER_H + 18.0, tw - 8.0, 56.0)
		var sel: bool = tab == TABS[i][0]
		var claim := _claimable(TABS[i][0])
		button("tab:" + TABS[i][0], r, TABS[i][1], GButton.Style.PRIMARY if sel else GButton.Style.TAB, "", 22)
		if claim > 0:
			UiKit.pill(self, Rect2(r.end.x - 34.0, r.position.y - 6.0, 30.0, 24.0), Color("ff4a5a"), UiKit.INK, 2.5)
			UiKit.text(self, Vector2(r.end.x - 34.0, r.position.y + 12.0), str(claim), 15, Color.WHITE, 1, 30.0)
	# reinicio
	var left := ""
	match tab:
		"daily":
			var now := Time.get_time_dict_from_system()
			var secs := 86400 - (int(now["hour"]) * 3600 + int(now["minute"]) * 60 + int(now["second"]))
			left = "Se reinician en %dh %02dm" % [secs / 3600, (secs % 3600) / 60]
		"weekly":
			left = "Se reinician cada semana"
		_:
			left = "Duran toda la temporada"
	UiKit.text(self, Vector2(x0, size.y - 8.0), left, 13, UiKit.DIM, 0, -1.0, 2.0, false)


func _claimable(scope: String) -> int:
	var n := 0
	for it in MissionSystem.items(Profile.p, scope):
		var def: MissionData = Catalog.missions.get(it["id"])
		if def != null and not it["claimed"] and MissionSystem.is_complete(it, def):
			n += 1
	return n


func _draw_list(p: ScrollPane) -> void:
	var items := MissionSystem.items(Profile.p, tab)
	for i in items.size():
		var it: Dictionary = items[i]
		var def: MissionData = Catalog.missions.get(it["id"])
		if def == null:
			continue
		var r := Rect2(4.0, 4.0 + float(i) * 118.0, p.size.x - 8.0, 106.0)
		var done := MissionSystem.is_complete(it, def)
		var claimed: bool = it["claimed"]
		var col := UiKit.OK if done else Color("6a9cff")
		UiKit.panel(p, r, Color("101a30") if not claimed else Color("0a1020"), Color(col, 0.7 if not claimed else 0.25), 12.0)
		UiKit.text(p, Vector2(r.position.x + 22.0, r.position.y + 40.0), def.title, 24, UiKit.TEXT if not claimed else UiKit.DIM, 0, r.size.x - 260.0, 4.0)
		var br := Rect2(r.position.x + 22.0, r.position.y + 58.0, r.size.x - 290.0, 20.0)
		UiKit.bar(p, br, float(it["progress"]) / float(def.target), col)
		UiKit.text(p, Vector2(br.position.x, br.position.y + 15.0), "%d / %d" % [int(it["progress"]), def.target], 14, UiKit.TEXT, 1, br.size.x, 3.0)
		# recompensas
		var rx := br.position.x
		var ry := r.position.y + 90.0
		UiIcons.draw(p, "coin", Vector2(rx + 8.0, ry), 9.0, Color("ffd24a"))
		UiKit.text(p, Vector2(rx + 24.0, ry + 5.0), str(def.reward_coins), 15, UiKit.TEXT, 0, -1.0, 3.0)
		UiIcons.draw(p, "star", Vector2(rx + 90.0, ry), 9.0, Color("8fe8ff"))
		UiKit.text(p, Vector2(rx + 106.0, ry + 5.0), "%d XP" % def.reward_xp, 15, UiKit.TEXT, 0, -1.0, 3.0)
		if def.reward_gems > 0:
			UiIcons.draw(p, "gem", Vector2(rx + 196.0, ry), 9.0, UiKit.GEM)
			UiKit.text(p, Vector2(rx + 212.0, ry + 5.0), str(def.reward_gems), 15, UiKit.TEXT, 0, -1.0, 3.0)
		# boton
		var bt := Rect2(r.end.x - 200.0, r.position.y + 24.0, 180.0, 58.0)
		if claimed:
			UiIcons.draw(p, "check", bt.get_center(), 18.0, UiKit.OK)
		elif done:
			var press := p.is_pressed("claim:%d" % i)
			var body := UiKit.chunky(p, bt, Color("ffe27a"), Color("f0a020"), 1.0 if press else 0.0)
			UiKit.text(p, Vector2(bt.position.x, body.position.y + 38.0), "RECLAMAR", 22, Color("3a2200"), 1, bt.size.x)
			p.reg("claim:%d" % i, bt)
		else:
			UiKit.pill(p, bt, Color(0.1, 0.14, 0.24), Color(1, 1, 1, 0.1), 2.0)
			UiKit.text(p, Vector2(bt.position.x, bt.position.y + 36.0), "EN CURSO", 16, UiKit.DIM, 1, bt.size.x, 2.0)


func _list_tap(id: String) -> void:
	if id.begins_with("claim:"):
		var idx := int(id.substr(6))
		var r := MissionSystem.claim(Profile.p, Catalog.missions, tab, idx)
		if not r.is_empty():
			AudioMgr.ui("reward")
			show_toast("+%d monedas  +%d XP%s" % [r["coins"], r["xp"], ("  +%d gemas" % r["gems"]) if r["gems"] > 0 else ""], UiKit.GOLD)


func tap(id: String) -> void:
	if id.begins_with("tab:"):
		tab = id.substr(4)
		pane.scroll = 0.0
		_layout()
