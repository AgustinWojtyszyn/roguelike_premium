class_name ModeSelectScreen
extends MenuScreen
## Selector de modo: se abre al pulsar JUGAR. Campana, Supervivencia, Boss Rush y Desafio (este ultimo pide elegir una regla).
## Los modos bloqueados dicen por que. Emite `chosen(mode, challenge)`; el HOME arranca la run.

signal chosen(mode: String, challenge: String)

var chapter_id := "ch1"
var state := "modes"            # modes | rules

const ICONS := {ModeRules.CAMPAIGN: "door", ModeRules.SURVIVAL: "bolt", ModeRules.BOSS_RUSH: "skull", ModeRules.CHALLENGE: "star"}
const COLORS := {ModeRules.CAMPAIGN: Color("27e0cc"), ModeRules.SURVIVAL: Color("ffd24a"), ModeRules.BOSS_RUSH: Color("ff6a8a"), ModeRules.CHALLENGE: Color("c47bff")}


func _build() -> void:
	title = "ELIGE UN MODO"
	accent = Color("ffb23d")


func close() -> void:
	if state == "rules":
		state = "modes"
		title = "ELIGE UN MODO"
		return
	super.close()


func _available(mode: String) -> bool:
	var p := Profile.p
	match mode:
		ModeRules.SURVIVAL:
			return true
		ModeRules.BOSS_RUSH:
			return bool(p.chapter_state(Catalog.chapter_order[Catalog.chapter_order.size() - 1]).get("unlocked", false))
	return bool(p.chapter_state(chapter_id).get("unlocked", false))


func _lock_reason(mode: String) -> String:
	if mode == ModeRules.BOSS_RUSH:
		return "Llega al último capítulo"
	var req := Catalog.chapter(Catalog.chapter(chapter_id).unlock_requires)
	return ("Completa: %s" % req.display_name) if req != null else "Bloqueado"


func _record_line(mode: String) -> String:
	var rec: Dictionary = Profile.p.data["records"]
	match mode:
		ModeRules.CAMPAIGN:
			var ch := Catalog.chapter(chapter_id)
			return "Capítulo %d · %s" % [Catalog.chapter_order.find(chapter_id) + 1, ch.display_name]
		ModeRules.SURVIVAL:
			var s: Dictionary = rec["survival"]
			return "Mejor: oleada %d · %s pts" % [int(s["best_wave"]), UiKit.format_int(int(s["best_score"]))]
		ModeRules.BOSS_RUSH:
			var b: Dictionary = rec["bossrush"]
			var t := float(b["best_time"])
			return "Mejor: %d/4 jefes%s" % [int(b["best_bosses"]), (" · %d:%02d" % [int(t) / 60, int(t) % 60]) if t > 0.0 else ""]
		ModeRules.CHALLENGE:
			var n := 0
			for cid in rec["challenges"]:
				if int(rec["challenges"][cid].get("cleared", 0)) > 0:
					n += 1
			return "Superados: %d / %d" % [n, ModeRules.CHALLENGE_ORDER.size()]
	return ""


func _draw_body(k: float) -> void:
	var gap := 18.0
	var m := 24.0
	var n := 4
	var top := HEADER_H + 26.0
	var h := size.y - top - 28.0
	var w := (size.x - m * 2.0 - gap * float(n - 1)) / float(n)
	for i in n:
		var r := Rect2(m + float(i) * (w + gap), top, w, h)
		if state == "modes":
			_card_mode(r, ModeRules.ORDER[i])
		else:
			_card_rule(r, ModeRules.CHALLENGE_ORDER[i])


func _wrap(r: Rect2, text: String, y: float, col: Color, fs: int = 17) -> void:
	draw_multiline_string(UiKit.font_reg(), Vector2(r.position.x + 18.0, y), text, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 36.0, fs, 6, col)


func _card_mode(r: Rect2, mode: String) -> void:
	var ok := _available(mode)
	var col: Color = COLORS[mode]
	var pressed := is_down("mode:" + mode) and ok
	var rr := r.grow(-3.0) if pressed else r
	UiKit.panel(self, rr, Color("101a30", 0.97), Color(col, 0.95 if ok else 0.3), 16.0)
	var c := Vector2(rr.get_center().x, rr.position.y + 92.0)
	draw_circle(c, 52.0, Color(col.darkened(0.65), 1.0 if ok else 0.5))
	draw_arc(c, 52.0, 0, TAU, 32, Color(col, 1.0 if ok else 0.4), 4.0, true)
	UiIcons.draw(self, ICONS[mode], c, 26.0, col.lightened(0.3) if ok else Color(col, 0.4))
	UiKit.text(self, Vector2(rr.position.x, rr.position.y + 190.0), ModeRules.NAMES[mode], 30, UiKit.TEXT if ok else UiKit.DIM, 1, rr.size.x, 6.0)
	_wrap(rr, ModeRules.DESCS[mode], rr.position.y + 228.0, Color(0.8, 0.9, 1.0, 0.9 if ok else 0.45))
	var line := _record_line(mode) if ok else _lock_reason(mode)
	UiKit.text(self, Vector2(rr.position.x, rr.end.y - 70.0), line, 15, Color(col.lightened(0.3), 0.95) if ok else UiKit.DIM, 1, rr.size.x, 3.0, false)
	var br := Rect2(rr.position.x + 24.0, rr.end.y - 56.0, rr.size.x - 48.0, 42.0)
	button("", br, "JUGAR" if mode != ModeRules.CHALLENGE else "ELEGIR REGLA", GButton.Style.PRIMARY if ok else GButton.Style.GHOST, "", 20, ok)
	if ok:
		reg("mode:" + mode, rr)


func _card_rule(r: Rect2, cid: String) -> void:
	var def: Dictionary = ModeRules.CHALLENGES[cid]
	var col: Color = COLORS[ModeRules.CHALLENGE]
	var pressed := is_down("rule:" + cid)
	var rr := r.grow(-3.0) if pressed else r
	UiKit.panel(self, rr, Color("101a30", 0.97), Color(col, 0.95), 16.0)
	UiKit.text(self, Vector2(rr.position.x, rr.position.y + 84.0), def["name"], 28, UiKit.TEXT, 1, rr.size.x, 6.0)
	_wrap(rr, def["desc"], rr.position.y + 130.0, Color(0.8, 0.9, 1.0, 0.92), 18)
	var rec: Dictionary = Profile.p.data["records"]["challenges"].get(cid, {})
	var done := int(rec.get("cleared", 0))
	UiKit.text(self, Vector2(rr.position.x, rr.end.y - 70.0), ("Superado ×%d" % done) if done > 0 else "Sin superar", 15, UiKit.OK if done > 0 else UiKit.DIM, 1, rr.size.x, 3.0, false)
	UiKit.text(self, Vector2(rr.position.x, rr.end.y - 98.0), "Bono ×%.1f" % float(def["bonus"]), 14, UiKit.GOLD, 1, rr.size.x, 3.0, false)
	button("", Rect2(rr.position.x + 24.0, rr.end.y - 56.0, rr.size.x - 48.0, 42.0), "JUGAR", GButton.Style.PRIMARY, "", 20, true)
	reg("rule:" + cid, rr)


func tap(id: String) -> void:
	if id.begins_with("mode:"):
		var mode := id.substr(5)
		if mode == ModeRules.CHALLENGE:
			state = "rules"
			title = "ELIGE UNA REGLA"
			AudioMgr.ui("tick", -4.0)
		else:
			chosen.emit(mode, "")
	elif id.begins_with("rule:"):
		chosen.emit(ModeRules.CHALLENGE, id.substr(5))
