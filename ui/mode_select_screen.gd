class_name ModeSelectScreen
extends MenuScreen
## Selector visual de siete modos; selección local y confirmación explícita.
## Los modos bloqueados dicen por que. Emite `chosen(mode, challenge)`; el HOME arranca la run.

signal chosen(mode: String, challenge: String)

var chapter_id := "ch1"
var state := "modes"            # modes | rules

const ICONS := {ModeRules.CAMPAIGN: "door", ModeRules.SURVIVAL: "bolt", ModeRules.BOSS_RUSH: "skull", ModeRules.CHALLENGE: "star",
	ModeRules.HORDE: "boom", ModeRules.TIME_ATTACK: "clock", ModeRules.EXPEDITION: "target"}
const COLORS := {ModeRules.CAMPAIGN: Color("27e0cc"), ModeRules.SURVIVAL: Color("ffd24a"), ModeRules.BOSS_RUSH: Color("ff6a8a"), ModeRules.CHALLENGE: Color("c47bff"),
	ModeRules.HORDE: Color("ff7a3d"), ModeRules.TIME_ATTACK: Color("5fb8ff"), ModeRules.EXPEDITION: Color("5fffc8")}


const MENU_BUTTON = preload("res://ui/home_button.gd")
var canvas: Control
var cards: Dictionary = {}
var difficulties: Dictionary = {}
var launch: HomeButton
var selected_mode := ModeRules.CAMPAIGN
var selected_rule := "one_weapon"
const MODE_ART := {"campaign": "ch1", "survival": "ch2", "bossrush": "ch3", "challenge": "ch4", "horde": "ch3", "timeattack": "ch1", "expedition": "ch2"}
var content_origin := Vector2.ZERO
var content_scale := 1.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	selected_mode = str(Profile.p.data.get("selected_mode", ModeRules.CAMPAIGN))
	if not ModeRules.ORDER.has(selected_mode) or not _available(selected_mode):
		selected_mode = ModeRules.SURVIVAL if not _available(ModeRules.CAMPAIGN) else ModeRules.CAMPAIGN
	resized.connect(_layout)
	_rebuild()
	_layout()
	AudioMgr.ui("ui_open", -4.0)

func _control(rect: Rect2, text: String, action: Callable) -> HomeButton:
	var b := MENU_BUTTON.new()
	b.position = rect.position
	b.size = rect.size
	b.label = text
	b.font_size = 18
	b.pressed.connect(action)
	canvas.add_child(b)
	return b

func _rebuild() -> void:
	for child in canvas.get_children():
		canvas.remove_child(child)
		child.queue_free()
	cards.clear()
	difficulties.clear()
	back_btn = _control(Rect2(40, 28, 52, 48), "", close)
	back_btn.icon = "chev_l"
	back_btn.tooltip_text = "Volver"
	if state == "modes":
		for i in DamageScale.ORDER.size():
			var id: String = DamageScale.ORDER[i]
			var d: Dictionary = DamageScale.difficulty(id)
			var b := _control(Rect2(420 + i * 180, 111, 166, 44), str(d["name"]), func(): tap("diff:" + id); _refresh())
			b.tint = d["color"]
			difficulties[id] = b
		for i in ModeRules.ORDER.size():
			var id: String = ModeRules.ORDER[i]
			var b := _control(Rect2(420 + (i % 2) * 416, 180 + (i / 2) * 110, 400, 102), ModeRules.NAMES[id], func(): selected_mode = id; _refresh())
			b.card = true
			b.compact = true
			b.art = MenuStyle.art(MODE_ART[id])
			b.icon = ICONS[id]
			b.tint = COLORS[id]
			b.description = ModeRules.GOALS[id]
			b.enabled = _available(id)
			b.footnote = _record_line(id) if b.enabled else _lock_reason(id)
			b.tooltip_text = ModeRules.DESCS[id] if b.enabled else _lock_reason(id)
			cards[id] = b
	else:
		for i in ModeRules.CHALLENGE_ORDER.size():
			var id: String = ModeRules.CHALLENGE_ORDER[i]
			var d: Dictionary = ModeRules.CHALLENGES[id]
			var b := _control(Rect2(420 + (i % 2) * 416, 180 + (i / 2) * 220, 400, 208), d["name"], func(): selected_rule = id; _refresh())
			b.card = true
			b.art = MenuStyle.art("ch4")
			b.icon = "star"
			b.tint = COLORS[ModeRules.CHALLENGE]
			b.description = d["desc"]
			var rec: Dictionary = Profile.p.data["records"]["challenges"].get(id, {})
			var done := int(rec.get("cleared", 0))
			b.footnote = ("Superado ×%d" % done if done > 0 else "Sin superar") + "  ·  Bono ×%.1f" % float(d["bonus"])
			cards[id] = b
	launch = _control(Rect2(936, 632, 304, 56), "JUGAR", _confirm)
	launch.style = GButton.Style.PRIMARY
	_refresh()
	_wire_focus()
	var active: String = selected_mode if state == "modes" else selected_rule
	cards[active].grab_focus()

# Keep keyboard/controller navigation inside this modal, including at its edges.
func _wire_focus() -> void:
	var controls := canvas.get_children()
	var directions := [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN]
	for i in controls.size():
		var b: Control = controls[i]
		b.focus_next = b.get_path_to(controls[(i + 1) % controls.size()])
		b.focus_previous = b.get_path_to(controls[posmod(i - 1, controls.size())])
		for side in 4:
			var nearest: Control = b
			var best := INF
			for other: Control in controls:
				var offset := other.get_rect().get_center() - b.get_rect().get_center()
				var forward := offset.dot(directions[side])
				var across := absf(offset.cross(directions[side]))
				var score := forward + across * 3.0
				if forward > 1.0 and score < best:
					best = score
					nearest = other
			b.set_focus_neighbor(side, b.get_path_to(nearest))

	var order: Array = ModeRules.ORDER if state == "modes" else ModeRules.CHALLENGE_ORDER
	for i in order.size():
		var b: Control = cards[order[i]]
		var left: Control = cards[order[i - 1]] if i % 2 == 1 else b
		var right: Control = cards[order[i + 1]] if i % 2 == 0 and i + 1 < order.size() else b
		var up: Control = cards[order[i - 2]] if i >= 2 else (difficulties[DamageScale.ORDER[mini(i, 2)]] if state == "modes" else back_btn)
		var down: Control = cards[order[i + 2]] if i + 2 < order.size() else launch
		b.focus_neighbor_left = b.get_path_to(left)
		b.focus_neighbor_right = b.get_path_to(right)
		b.focus_neighbor_top = b.get_path_to(up)
		b.focus_neighbor_bottom = b.get_path_to(down)

func _refresh() -> void:
	var active: String = selected_mode if state == "modes" else selected_rule
	for id in cards:
		var b: HomeButton = cards[id]
		b.selected = id == active
		b.kicker = "SELECCIONADO" if b.selected else ("DISPONIBLE" if b.enabled else "BLOQUEADO")
		b.queue_redraw()
	for id in difficulties:
		var b: HomeButton = difficulties[id]
		b.selected = id == str(Profile.p.data.get("selected_difficulty", DamageScale.NORMAL))
		b.queue_redraw()
	launch.label = "ELEGIR REGLA  →" if state == "modes" and selected_mode == ModeRules.CHALLENGE else "JUGAR  →"
	launch.queue_redraw()
	queue_redraw()

func _confirm() -> void:
	if closing:
		return
	if state == "rules":
		tap("rule:" + selected_rule)
	elif _available(selected_mode):
		tap("mode:" + selected_mode)

func _layout() -> void:
	if canvas == null:
		return
	var sm := SafeArea.margins(self)
	var usable := size - Vector2(sm.x + sm.z, sm.y + sm.w)
	content_scale = minf(usable.x / 1280.0, usable.y / 720.0)
	content_origin = Vector2(sm.x, sm.y) + (usable - Vector2(1280, 720) * content_scale) * 0.5
	canvas.position = content_origin
	canvas.scale = Vector2.ONE * content_scale
	canvas.size = Vector2(1280, 720)

func close() -> void:
	if state == "rules":
		state = "modes"
		_rebuild()
		return
	super.close()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_B):
		close()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	MenuStyle.background(self, Rect2(Vector2.ZERO, size))
	draw_set_transform(content_origin, 0, Vector2.ONE * content_scale)
	MenuStyle.text(self, Vector2(112, 39), "RPG PREMIUM  /  PREPARAR DESCENSO", 12, MenuStyle.GOLD)
	MenuStyle.text(self, Vector2(112, 79), "ELEGÍ TU EXPERIENCIA" if state == "modes" else "CAMBIÁ LAS REGLAS", 38, MenuStyle.TEXT)
	MenuStyle.text(self, Vector2(810, 57), "CAPÍTULO %02d  /  %s" % [Catalog.chapter_order.find(chapter_id) + 1, Catalog.chapter(chapter_id).display_name], 15, MenuStyle.DIM, 2, 430)
	draw_line(Vector2(40, 96), Vector2(1240, 96), Color(MenuStyle.GOLD, 0.25), 1)
	var col: Color = COLORS[selected_mode]
	var feature := Rect2(40, 111, 352, 492)
	MenuStyle.cover(self, feature, MenuStyle.art(MODE_ART[selected_mode]))
	MenuStyle.gradient_rect(self, feature, Color(MenuStyle.INK, 0.1), Color(MenuStyle.INK, 1))
	draw_style_box(MenuStyle.box(Color.TRANSPARENT, Color(col, 0.7), 0), feature)
	UiIcons.draw(self, ICONS[selected_mode], Vector2(78, 155), 17, col)
	MenuStyle.text(self, Vector2(108, 160), "TU DESCENSO", 13, MenuStyle.TEXT)
	MenuStyle.text(self, Vector2(62, 340), ModeRules.NAMES[selected_mode], 40, MenuStyle.TEXT, 0, 310)
	MenuStyle.paragraph(self, Rect2(62, 363, 300, 132), ModeRules.DESCS[selected_mode], 20, MenuStyle.TEXT)
	MenuStyle.paragraph(self, Rect2(62, 525, 306, 55), _record_line(selected_mode), 16, col.lightened(0.3))
	if state == "modes":
		MenuStyle.text(self, Vector2(976, 133), "DIFICULTAD", 12, MenuStyle.GOLD)
		var d: Dictionary = DamageScale.difficulty(str(Profile.p.data.get("selected_difficulty", DamageScale.NORMAL)))
		MenuStyle.paragraph(self, Rect2(976, 141, 264, 32), str(d["desc"]), 12)
		MenuStyle.text(self, Vector2(860, 552), "SIETE FORMAS DE DESCENDER", 16, MenuStyle.GOLD)
		MenuStyle.text(self, Vector2(860, 580), "Elegí un modo. Confirmá para entrar.", 16, MenuStyle.DIM)
	else:
		MenuStyle.text(self, Vector2(420, 142), "UNA CONDICIÓN. UN NUEVO DESAFÍO.", 25, MenuStyle.GOLD)
	draw_line(Vector2(40, 620), Vector2(1240, 620), Color(MenuStyle.GOLD, 0.25), 1)
	var name_text: String = ModeRules.NAMES[selected_mode] if state == "modes" else ModeRules.CHALLENGES[selected_rule]["name"]
	MenuStyle.text(self, Vector2(40, 659), name_text, 30, MenuStyle.TEXT)
	var difficulty: Dictionary = DamageScale.difficulty(str(Profile.p.data.get("selected_difficulty", DamageScale.NORMAL)))
	MenuStyle.text(self, Vector2(40, 688), "Dificultad: %s  ·  %s" % [difficulty["name"], Catalog.character(Profile.p.selected_character()).display_name], 16, MenuStyle.DIM)
	draw_set_transform(Vector2.ZERO)


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
			return "Mejor: oleada %d · %s pts" % [int(s["best_wave"]), MenuStyle.format_int(int(s["best_score"]))] if int(s["best_wave"]) > 0 else "Sin récord · Tu primera resistencia"
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
		ModeRules.HORDE:
			var h: Dictionary = rec["horde"]
			return "Récord: oleada %d" % int(h["best_wave"]) if int(h["best_wave"]) > 0 else "Sin récord · ¿hasta dónde llegas?"
		ModeRules.TIME_ATTACK:
			var ta: Dictionary = (rec["timeattack"] as Dictionary).get(chapter_id, {})
			var bt := float(ta.get("best_time", 0.0))
			return ("Mejor: %d:%05.2f" % [int(bt) / 60, fmod(bt, 60.0)]) if bt > 0.0 else "Sin marca en este capítulo"
		ModeRules.EXPEDITION:
			var ex: Dictionary = (rec["expedition"] as Dictionary).get(chapter_id, {})
			return "Mejor: %d tramos · %d victorias" % [int(ex.get("best_legs", 0)), int(ex.get("clears", 0))] if ex.size() > 0 else "Sin expediciones aún"
	return ""


func tap(id: String) -> void:
	if id.begins_with("diff:"):
		Profile.p.data["selected_difficulty"] = id.substr(5)
		Profile.p.touch()
		AudioMgr.ui("tick", -4.0)
		return
	if id.begins_with("mode:"):
		var mode := id.substr(5)
		if mode == ModeRules.CHALLENGE:
			state = "rules"
			_rebuild()
			AudioMgr.ui("tick", -4.0)
		else:
			chosen.emit(mode, "")
	elif id.begins_with("rule:"):
		chosen.emit(ModeRules.CHALLENGE, id.substr(5))
