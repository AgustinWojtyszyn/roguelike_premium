class_name PerkPicker
extends Control
## Eleccion de perk (3 opciones). Pausa la run. Si los 5 slots estan llenos, pide elegir cual reemplazar.

var game: Game
var source := "clear"
var offers: Array[PerkData] = []
var _anim: float = 0.0
var _picked := -1
var _picked_t: float = 0.0
var _stage := 0                     # 0 = elegir carta, 1 = elegir slot a reemplazar
var _pending: PerkData
var skip_btn: GButton
var cancel_btn: GButton
var _closing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(func(): size = get_viewport_rect().size)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var rng := RandomNumberGenerator.new()
	rng.seed = game.run.seed_v * 7 + game.run.stage_idx * 13 + game.run.perks_picked
	var luck := 0.15 if source == "chest" else 0.0
	offers = RunState.roll_perk_offer(rng, Catalog.perks, game.run.perks, 3, luck)
	skip_btn = GButton.make("SALTAR  +20", GButton.Style.GHOST, "coin")
	skip_btn.font_size = 20
	skip_btn.pressed.connect(_skip)
	add_child(skip_btn)
	cancel_btn = GButton.make("ATRÁS", GButton.Style.GHOST)
	cancel_btn.font_size = 20
	cancel_btn.visible = false
	cancel_btn.pressed.connect(func(): _stage = 0; cancel_btn.visible = false; skip_btn.visible = true)
	add_child(cancel_btn)
	game.get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.input_locked = true
	game.input.reset()
	AudioMgr.ui("perk")
	resized.connect(_layout)
	_layout()
	if game.bot:
		get_tree().create_timer(0.6, true, false, true).timeout.connect(func(): _choose(0))


func _layout() -> void:
	skip_btn.size = Vector2(190, 52)
	skip_btn.position = Vector2(size.x * 0.5 - 95.0, size.y - 78.0)
	cancel_btn.size = Vector2(150, 52)
	cancel_btn.position = Vector2(size.x * 0.5 - 75.0, size.y - 78.0)


func _card_rect(i: int) -> Rect2:
	var n := offers.size()
	var w := minf(300.0, (size.x - 80.0) / float(maxi(n, 1)) - 14.0)
	var h := minf(400.0, size.y - 250.0)
	var total := w * float(n) + 24.0 * float(n - 1)
	var x := (size.x - total) * 0.5 + float(i) * (w + 24.0)
	var y := 130.0
	return Rect2(x, y, w, h)


func _slot_rect(i: int) -> Rect2:
	var w := 64.0
	var total := w * 5.0 + 12.0 * 4.0
	return Rect2((size.x - total) * 0.5 + float(i) * (w + 12.0), size.y - 160.0, w, w)


func _process(delta: float) -> void:
	_anim += delta
	if _picked >= 0:
		_picked_t += delta
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if _closing:
		return
	var pos := Vector2.ZERO
	var tap := false
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		pos = e.position
		tap = true
	elif e is InputEventScreenTouch and e.pressed:
		pos = e.position
		tap = true
	if not tap or _anim < 0.35:
		return
	if _stage == 0 and _picked < 0:
		for i in offers.size():
			if _card_rect(i).has_point(pos):
				_choose(i)
				return
	elif _stage == 1:
		for i in game.run.perks.size():
			if _slot_rect(i).grow(6.0).has_point(pos):
				game.run.replace_perk(i, _pending, Catalog.perks)
				_finish(_pending)
				return


func _choose(i: int) -> void:
	var p := offers[i]
	if game.run.perks.has(p.id) and not p.stackable:
		return
	if game.run.perk_slots_free() <= 0 and not (game.run.perks.has(p.id) and p.stackable):
		_pending = p
		_stage = 1
		skip_btn.visible = false
		cancel_btn.visible = true
		AudioMgr.ui("ui_open")
		return
	_picked = i
	_picked_t = 0.0
	game.run.add_perk(p, Catalog.perks)
	_finish(p)


func _finish(p: PerkData) -> void:
	_closing = true
	AudioMgr.ui("ui_confirm")
	game.player.recompute_stats()
	var c := Rarity.color(p.rarity)
	game.fx.ring(game.player.hit_center(), 6.0, 60.0, c, 0.5, 4.0)
	game.fx.burst(game.player.hit_center(), 20, 260.0, c, 0.6)
	game.hud.toast(p.display_name, c)
	get_tree().create_timer(0.45, true, false, true).timeout.connect(_close)


func _skip() -> void:
	if _closing:
		return
	_closing = true
	game.run.coins += 20
	AudioMgr.ui("coin")
	_close()


func _close() -> void:
	game.get_tree().paused = false
	game.input_locked = false
	game.input.reset()
	if not game.touch_mode:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if source == "clear":
		game.director.perk_closed()
	queue_free()


func _draw() -> void:
	var a := clampf(_anim * 5.0, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.06, 0.78 * a))
	var title := "ELIGE UN PERK" if _stage == 0 else "¿QUÉ PERK REEMPLAZAS?"
	UiKit.text(self, Vector2(0, 74.0), title, 44, UiKit.TEXT, 1, size.x, 8.0)
	var sub := "Mejora permanente durante esta run" if _stage == 0 else "Tus 5 slots están llenos"
	UiKit.text(self, Vector2(0, 104.0), sub, 18, UiKit.DIM, 1, size.x, 3.0, false)
	if _stage == 0:
		for i in offers.size():
			_draw_card(i)
	_draw_slots()


func _draw_card(i: int) -> void:
	var p := offers[i]
	var delay := 0.08 * float(i)
	var k := Gfx.ease_out(clampf((_anim - delay) * 3.2, 0.0, 1.0))
	var r := _card_rect(i)
	var yoff := (1.0 - k) * 70.0
	var sel := _picked == i
	var sc := 1.0 + (0.06 if sel else 0.0)
	var cc := r.get_center() + Vector2(0, yoff)
	draw_set_transform(cc * (1.0 - sc), 0.0, Vector2.ONE * sc)
	var rr := Rect2(r.position + Vector2(0, yoff), r.size)
	var col := Rarity.color_anim(p.rarity, _anim)
	var owned := game.run.perks.has(p.id) and not p.stackable
	Gfx.draw_glow(self, rr.get_center(), rr.size.y * 0.7, Color(col, 0.14 * k))
	UiKit.panel(self, rr, UiKit.PANEL_HI, Color(col, 0.95), 18.0, k)
	draw_rect(Rect2(rr.position.x + 10, rr.position.y + 10, rr.size.x - 20, 6), Color(col, 0.9 * k))
	# icono en hexagono
	var ic := Vector2(rr.get_center().x, rr.position.y + 92.0)
	var hex := Gfx.ell_pts(ic, 52.0, 52.0, 6, PI / 6.0)
	draw_colored_polygon(hex, Color(col.darkened(0.7), k))
	Gfx.outline(self, hex, Color(col, k), 3.0)
	Gfx.draw_glow(self, ic, 60.0, Color(col, 0.3 * k))
	UiIcons.draw(self, p.icon, ic, 26.0, Color(col.lightened(0.45), k))
	# nombre y etiquetas
	UiKit.text(self, Vector2(rr.position.x, rr.position.y + 176.0), p.display_name, 24, Color(UiKit.TEXT, k), 1, rr.size.x, 5.0)
	UiKit.text(self, Vector2(rr.position.x, rr.position.y + 202.0), "%s · %s" % [p.tag, Rarity.label(p.rarity)], 14, Color(col, k), 1, rr.size.x, 3.0)
	var f := UiKit.font_reg()
	draw_multiline_string(f, rr.position + Vector2(18, 238.0), p.description, HORIZONTAL_ALIGNMENT_CENTER, rr.size.x - 36.0, 18, 6, Color(0.85, 0.93, 1.0, k))
	if owned:
		UiKit.text(self, Vector2(rr.position.x, rr.end.y - 18.0), "YA LO TIENES", 14, Color(UiKit.DANGER, k), 1, rr.size.x, 3.0)
	elif p.stackable and game.run.perks.has(p.id):
		UiKit.text(self, Vector2(rr.position.x, rr.end.y - 18.0), "SE ACUMULA  x%d" % (game.run.perk_count(p.id) + 1), 14, Color(UiKit.OK, k), 1, rr.size.x, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_slots() -> void:
	UiKit.text(self, Vector2(0, size.y - 172.0), "SLOTS  %d / %d" % [game.run.perks.size(), RunState.PERK_SLOTS], 14, UiKit.DIM, 1, size.x, 3.0)
	for i in RunState.PERK_SLOTS:
		var r := _slot_rect(i)
		var filled := i < game.run.perks.size()
		var col := UiKit.DIM
		if filled:
			var pd: PerkData = Catalog.perks[game.run.perks[i]]
			col = Rarity.color(pd.rarity)
		UiKit.panel(self, r, UiKit.PANEL, Color(col, 0.9 if filled else 0.3), 8.0, 1.0, false)
		if filled:
			var pd2: PerkData = Catalog.perks[game.run.perks[i]]
			UiIcons.draw(self, pd2.icon, r.get_center(), 18.0, Color(col.lightened(0.4)))
			if _stage == 1:
				var pulse := 0.5 + 0.5 * sin(_anim * 8.0)
				draw_rect(r.grow(3.0), Color(1, 1, 1, 0.5 * pulse), false, 3.0)
