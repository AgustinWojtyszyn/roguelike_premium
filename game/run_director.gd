class_name RunDirector
extends Node
## Director de la run: genera el plan de etapas, carga cada sala, lanza los encuentros por oleadas, gestiona
## recompensas, perks, salida (sello que se disuelve) y la victoria / derrota.

var game: Game
var plan: Array[Dictionary] = []
var stage: int = -1
var in_combat := false
var cleared := false
var entered := false
var transition := false
var perk_busy := false
var waves: Array = []
var wave_i: int = -1
var pending: Array = []
var next_wave_t: float = -1.0
var wave_clock: float = 0.0
var spawn_busy: Dictionary = {}
var boss: Enemy = null
var elite_done := false
var token: int = 0
var enter_t: float = 0.0
var end_t: float = -1.0
var end_won := false
var chests: Array[Chest] = []
var rng := RandomNumberGenerator.new()
var fade: ColorRect
var fade_layer: CanvasLayer
# ---- modos alternativos (ver ModeRules)
var surv_wave := 0              # supervivencia: ultima oleada lanzada
var surv_phase := 0
var surv_pending_phase := -1    # fase a la que se pasa cuando se cierre el selector de perk
var rush_wait := -1.0           # boss rush: cuenta atras de la zona de preparacion
var _rush_last_sec := -1
var room_elites := 0            # elites extra por dificultad ya lanzados en esta sala (tope 3)
# ---- Expedicion
var exp_used_rooms: Array = []
var _base_mods: Dictionary = {}
var exp_picker: Node = null


func _ready() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 18
	fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(fade_layer)
	fade = ColorRect.new()
	fade.color = Color("04060c")
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.modulate.a = 1.0
	fade_layer.add_child(fade)


func begin(start_stage: int = 0) -> void:
	rng.seed = game.run.seed_v + 77
	match game.mode_id:
		ModeRules.SURVIVAL:
			plan = [ModeRules.survival_stage(0)]
			surv_phase = 0
			surv_wave = 0
		ModeRules.BOSS_RUSH:
			plan = ModeRules.boss_rush_plan(Catalog.rooms)
		ModeRules.HORDE:
			plan = [ModeRules.horde_stage(game.chapter.id)]
			surv_wave = 0
		ModeRules.TIME_ATTACK:
			plan = ModeRules.time_attack_plan(game.chapter, game.run.seed_v)
		ModeRules.EXPEDITION:
			_base_mods = game.mods.duplicate()
			var first: Array = ModeRules.expedition_options(game.chapter, 0, "", "", rng, [])
			var st0: Dictionary = (first[0] as Dictionary).duplicate()
			st0["kind"] = "combat"
			st0["modifier"] = ""
			st0["perk_after"] = false
			plan = [st0]
			exp_used_rooms = [st0["room"]]
			game.run.route_log.append("combat")
		_:
			plan = DungeonGenerator.generate(game.chapter, game.run.seed_v, Catalog.rooms, Catalog.encounters)
	_load_stage(clampi(start_stage, 0, plan.size() - 1), true)


func exit_open() -> bool:
	return cleared and game.room.seal_open > 0.5


func boss_alive() -> bool:
	return boss != null and is_instance_valid(boss) and boss.state != Enemy.S_DYING


func threats_left() -> int:
	return game.enemies.size() + pending.size()


func stages_cleared() -> int:
	return stage + (1 if cleared else 0)


func current() -> Dictionary:
	return plan[stage]


# ------------------------------------------------------------------ carga de etapas
func _teardown() -> void:
	token += 1
	for e in game.enemies.duplicate():
		e.queue_free()
	game.enemies.clear()
	game.melee_users.clear()
	for a in game.allies:
		a.queue_free()
	game.allies.clear()
	for c in chests:
		if is_instance_valid(c):
			c.queue_free()
	chests.clear()
	game.bullets.clear_all()
	game.pickups.clear_all()
	game.fx.ps.clear()
	game.fx.decals.clear()
	if game.room != null:
		for p in game.room.props:
			p.queue_free()
		for d in game.room.standing:
			if is_instance_valid(d):
				d.queue_free()
		game.room.queue_free()
	pending.clear()
	spawn_busy.clear()
	boss = null
	game.hud.boss = null


func _load_stage(i: int, instant: bool) -> void:
	_teardown()
	stage = i
	game.run.stage_idx = i
	var st: Dictionary = plan[i]
	if st.has("chapter") and game.chapter.id != st["chapter"]:
		game.chapter = Catalog.chapter(st["chapter"])
		game.run.chapter = game.chapter
		AudioMgr.play_music(game.chapter.music)
	if game.mode_id == ModeRules.EXPEDITION:
		# modificadores del tramo: se funden sobre las reglas base y SE QUITAN al salir (nunca se acumulan entre tramos)
		game.mods = _base_mods.duplicate()
		var mid := str(st.get("modifier", ""))
		if mid != "":
			var mm: Dictionary = (ModeRules.EXP_MODIFIERS[mid] as Dictionary)["mods"]
			for k in mm:
				game.mods[k] = mm[k]
	game.recalc_hp_scale(_mode_hp_scale())
	room_elites = 0
	var def: RoomDef = Catalog.rooms[st["room"]]
	var forced := Boot.get_arg("room", "")   # solo revision visual: fuerza la sala (sin efecto en partidas normales)
	if forced != "" and Catalog.rooms.has(forced):
		def = Catalog.rooms[forced]
	var room := Room.new()
	game.room = room
	game.add_child(room)
	game.move_child(room, 0)
	room.build(game, def, st["entry"], st["exit"], game.run.seed_v + i * 31)
	cleared = false
	entered = false
	in_combat = false
	wave_i = -1
	waves = []
	next_wave_t = -1.0
	elite_done = false
	enter_t = 0.0
	game.run.damaged_in_room = false
	var pl := game.player
	pl.position = room.entry_spawn()
	pl.vel = Vector2.ZERO
	pl.room_buff = ""
	game.input.reset()
	game.input.auto_walk = room.entry_walk_target()
	game.input.auto_walk_t = 0.0
	var dir := room.entry_walk_target() - pl.position
	pl.face = 1.0 if dir.x >= 0.0 else -1.0
	pl.aim = dir.normalized()
	game.cam_extra = Vector2.ZERO
	game._snap_camera()
	if st["kind"] == "survival" or st["kind"] == "horde":
		ArenaHazard.spawn_all(game, room, room)
	if st["kind"] == "cache":
		if game.mode_id == ModeRules.EXPEDITION and st.get("route", "") == "rest":
			_rest_site()
		else:
			_spawn_chests(def)
		cleared = true
		room.seal_open = 1.0
		room.seal_target = 1.0
		room._rebuild_rects()
	elif def.kind == "boss":
		pass
	if pl.passive_is("unstable"):
		pl.room_buff = ["dmg", "rate", "speed"][rng.randi() % 3]
		game.hud.toast("INESTABLE: +" + {"dmg": "DAÑO", "rate": "CADENCIA", "speed": "VELOCIDAD"}[pl.room_buff], Color("ff4fd8"))
	var title := "ETAPA %d / %d" % [i + 1, plan.size()]
	var sub: String = st["name"]
	var col := game.chapter.accent.lightened(0.6)
	if i == 0:
		title = game.chapter.display_name
		sub = game.chapter.subtitle
	elif st["kind"] == "boss":
		var has_boss := Catalog.bosses.has(game.chapter.boss)
		title = "¡JEFE!" if has_boss else "ÚLTIMA ETAPA"
		sub = Catalog.bosses[game.chapter.boss].title if has_boss else st["name"]
		col = Color("ff7a9a")
	elif st["kind"] == "elite":
		title = "ETAPA %d · ÉLITE" % (i + 1)
		col = Color("ffd24a")
	if game.mode_id == ModeRules.EXPEDITION and st["kind"] != "boss":
		title = "TRAMO %d · %s" % [i + 1, ModeRules.EXP_KIND_NAMES.get(st.get("route", st["kind"]), "COMBATE")]
		if str(st.get("modifier", "")) != "":
			sub = "%s: %s" % [ModeRules.EXP_MODIFIERS[st["modifier"]]["name"], ModeRules.EXP_MODIFIERS[st["modifier"]]["desc"]]
	elif game.mode_id == ModeRules.HORDE:
		title = "HORDA INFINITA"
	elif game.mode_id == ModeRules.TIME_ATTACK and i > 0:
		title = "SALA %d / %d" % [i + 1, plan.size()]
	game.hud.banner(title, 2.4, sub, col)
	fade.modulate.a = 1.0 if instant else fade.modulate.a
	_fade_in_settled()


## El horneado del suelo de la sala nueva se renderiza en los primeros frames: se mantiene la pantalla negra unos frames
## y el fundido de entrada empieza DESPUES, asi el tiron del horneado no se ve ni come el fundido ni el input.
const SETTLE_FRAMES := 3

func _fade_in_settled() -> void:
	var my_token := token
	for i in SETTLE_FRAMES:
		await get_tree().process_frame
	if my_token != token:
		return
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 0.0, 0.45)


func _spawn_chests(def: RoomDef) -> void:
	var spots: Array = def.decor.get("chests", [])
	var kinds := ["coin", "weapon", "perk"]
	if rng.randf() < 0.3:
		kinds[rng.randi() % 3] = "rare"
	for k in spots.size():
		var c := Chest.make(game, kinds[k % kinds.size()], spots[k])
		game.ysort.add_child(c)
		chests.append(c)


# ------------------------------------------------------------------ bucle
func _process(delta: float) -> void:
	Prof.begin("dir_proc")
	__process_impl(delta)
	Prof.end("dir_proc")


func __process_impl(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0) * Game.tscale
	if end_t >= 0.0:
		end_t -= minf(delta, 1.0 / 30.0)
		if end_t < 0.0:
			end_t = -1.0
			game.show_result(end_won)
		return
	if transition or game.over:
		return
	if rush_wait > 0.0:
		rush_wait -= dt
		var sec := int(ceil(rush_wait))
		if sec != _rush_last_sec and sec in [8, 5, 3, 2, 1]:
			_rush_last_sec = sec
			game.hud.toast("SIGUIENTE JEFE EN %d" % sec, Color("ff7a9a"))
		if rush_wait <= 0.0:
			rush_wait = -1.0
			_leave()
		return
	var room := game.room
	if not entered:
		enter_t += dt
		if room.floor_rect.grow(-34.0).has_point(game.player.position) or enter_t > 2.6:
			entered = true
			game.input.auto_walk = null
			if not cleared:
				_begin_encounter_delayed()
		return
	if in_combat:
		_update_waves(dt)
	if cleared and room.seal_open > 0.9 and room.has_exit and room.exit_trigger.has_point(game.player.position) and not perk_busy and not game.over:
		_leave()


func _begin_encounter_delayed() -> void:
	var t := token
	get_tree().create_timer(0.7).timeout.connect(func():
		if t == token and not game.over:
			_begin_encounter())


func _begin_encounter() -> void:
	var st: Dictionary = plan[stage]
	in_combat = true
	if st["kind"] == "survival":
		_start_survival_wave()
		return
	if st["kind"] == "horde":
		_start_horde_wave()
		return
	if st["kind"] == "boss" and Catalog.bosses.has(game.chapter.boss):
		_spawn_boss()
		return
	var enc: EncounterDef = Catalog.encounters.get(Boot.get_arg("enc", st["encounter"]))
	if enc == null:
		_clear_stage()
		return
	waves = enc.waves
	_start_wave(0)


func _start_wave(i: int) -> void:
	wave_i = i
	wave_clock = 0.0
	next_wave_t = -1.0
	for e in waves[i]:
		pending.append([e[0], e[1]])
	if waves.size() > 1:
		game.hud.banner("OLEADA %d / %d" % [i + 1, waves.size()], 1.4, "", game.chapter.accent.lightened(0.6))
	game.sfx.play("wave", -2.0)
	if i > 0 and game.player.hp < game.player.max_hp and rng.randf() < 0.4:
		game.pickups.drop_heart(game.room.floor_rect.get_center())


func _update_waves(dt: float) -> void:
	if plan[stage]["kind"] == "survival":
		_update_survival(dt)
		return
	if plan[stage]["kind"] == "horde":
		_update_horde(dt)
		return
	if plan[stage]["kind"] == "boss" and Catalog.bosses.has(game.chapter.boss):
		return
	wave_clock += dt
	var i := pending.size() - 1
	while i >= 0:
		pending[i][1] -= dt
		if pending[i][1] <= 0.0:
			if _try_spawn(pending[i][0]):
				pending.remove_at(i)
			else:
				pending[i][1] = 0.3
		i -= 1
	var alive := game.enemies.size() + pending.size()
	if alive <= 1 and next_wave_t < 0.0 and pending.is_empty() and wave_i < waves.size() - 1 and not game.over:
		next_wave_t = 1.4
	if next_wave_t >= 0.0:
		next_wave_t -= dt
		if next_wave_t <= 0.0:
			_start_wave(wave_i + 1)
	alive = game.enemies.size() + pending.size()   # recalcular: _start_wave pudo anadir enemigos pendientes
	if alive == 0 and wave_i == waves.size() - 1 and next_wave_t < 0.0 and not cleared and not game.over:
		_clear_stage()


func _pick_spawn() -> int:
	var room := game.room
	var best := -1
	var best_s := -1e9
	for i in room.spawns.size():
		if spawn_busy.has(i):
			continue
		var h: Vector2 = room.spawns[i]
		var d := h.distance_to(game.player.position)
		var s := minf(d, 520.0) + rng.randf() * 140.0
		if d < 280.0:
			s -= 500.0
		for e in game.enemies:
			if e.position.distance_to(h) < 80.0:
				s -= 200.0
		if s > best_s:
			best_s = s
			best = i
	return best


func _try_spawn(id: String, elite: bool = false) -> bool:
	var room := game.room
	var h := _pick_spawn()
	if h < 0:
		return false
	spawn_busy[h] = true
	room.open_spawn(h, true)
	var pos: Vector2 = room.spawns[h]
	var col := room.theme.spawn_color()
	game.sfx.play("spawn", -6.0)
	game.fx.ring(pos, 10.0, 70.0, col, 0.6, 3.0)
	game.fx.flash(pos, 90.0, Color(col, 0.6), 0.5)
	var t := token
	var lead := 0.65
	get_tree().create_timer(lead).timeout.connect(func():
		if t != token or game.over:
			return
		var e := spawn_enemy_at(id, pos, elite)
		game.fx.burst(pos, 14, 240.0, col.lightened(0.3), 0.5)
		game.fx.puff(pos, Vector2(0, -20), 24.0, Color(col, 0.4), 0.7, 2.4)
		game.fx.ring(pos, 6.0, 52.0, col.lightened(0.5), 0.35, 4.0)
		get_tree().create_timer(1.3).timeout.connect(func():
			if t != token:
				return
			room.open_spawn(h, false)
			spawn_busy.erase(h)
		)
	)
	return true


## Crea un enemigo por id en `pos` (tambien lo usan jefes y habilidades que invocan).
func spawn_enemy_at(id: String, pos: Vector2, force_elite: bool) -> Enemy:
	_require_art(id)
	var data: EnemyData = Catalog.enemies[id]
	var e: Enemy = (load(data.script_path) as GDScript).new()
	e.data = data
	var st: Dictionary = plan[stage]
	var all_elite: bool = game.mods.get("all_elite", false)
	if all_elite and data.elite_ok and st["kind"] != "boss":
		e.elite = true
	elif (st["elite"] or force_elite or (st["kind"] == "boss" and not Catalog.bosses.has(game.chapter.boss))) and not elite_done and data.elite_ok and data.threat >= 1.4:
		e.elite = true
		elite_done = true
	if not e.elite and data.elite_ok and data.threat >= 1.4 and st["kind"] != "boss" and room_elites < 3:
		var extra := float(DamageScale.difficulty(game.difficulty_id)["elite"])
		if extra > 0.0 and rng.randf() < extra:
			e.elite = true
			room_elites += 1
	game.ysort.add_child(e)
	e.setup(game, pos)
	if e.spr == null:
		_art_error(id, "el enemigo no pudo crear su SpriteActor")
	game.enemies.append(e)
	return e


func _mode_hp_scale() -> float:
	match game.mode_id:
		ModeRules.SURVIVAL:
			return ModeRules.difficulty_scale(surv_wave + 1, surv_phase)
		ModeRules.HORDE:
			return ModeRules.horde_hp_scale(surv_wave + 1)
	return 1.0


func _has_enemy_sprite(id: String) -> bool:
	return not VisualProfiles.enemy(id).is_empty()


## Falta de arte = error explicito de recursos. Nunca se omite al enemigo ni se avanza la sala por ello.
var art_errors: Array[String] = []


func _art_error(id: String, why: String) -> void:
	var msg := "ART_MISSING %s: %s" % [id, why]
	art_errors.append(msg)
	push_error(msg)


func _require_art(id: String) -> void:
	if not _has_enemy_sprite(id):
		_art_error(id, "sin perfil visual premium")


func _spawn_boss() -> void:
	_require_art(game.chapter.boss)
	var bd: BossData = Catalog.bosses[game.chapter.boss]
	var b: Enemy = (load(bd.script_path) as GDScript).new()
	b.boss_data = bd
	b.data = null
	game.ysort.add_child(b)
	var pos := Vector2(0, game.room.floor_rect.position.y + 200.0)
	b.setup(game, pos)
	if b.spr == null:
		_art_error(game.chapter.boss, "el jefe no pudo crear su SpriteActor")
	game.enemies.append(b)
	boss = b
	game.hud.boss = b
	game.hud.boss_frac_lag = 1.0
	AudioMgr.play_music("boss")
	game.fx.sprite("bosses/boss_spawn", pos + Vector2(0, -6), 150.0, 190.0, 1.6, Color(1, 1, 1, 0.9), 0.0, true)
	game.hud.banner(bd.display_name, 2.6, bd.title, Color("ff7a9a"))
	game.sfx.play("roar", -2.0)
	game.shake(0.4)


func roll_weapon(min_tier: int, max_tier: int) -> String:
	var tier := Rarity.roll(rng, 0.0, min_tier, max_tier)
	var cands: Array = []
	for w in Catalog.weapons.values():
		if w.rarity == tier and not game.player.slots.any(func(s): return s.data.id == w.id):
			cands.append(w.id)
	if cands.is_empty():
		for w in Catalog.weapons.values():
			if w.rarity >= min_tier and w.rarity <= max_tier:
				cands.append(w.id)
	cands.sort()
	if cands.is_empty():
		return "pulsar"
	return cands[rng.randi() % cands.size()]


# ------------------------------------------------------------------ eventos
func on_enemy_dead(e: Enemy) -> void:
	var pos := e.hit_center()
	var coins := 1
	if e.data != null:
		coins = e.data.coins
	if e.elite:
		coins *= 3
		game.pickups.drop_heart(pos)
	var lt: LootTable = Catalog.loot.get(game.chapter.loot_table)
	if lt != null:
		var r := lt.roll(rng)
		match r["type"]:
			"coins":
				game.pickups.drop_coins(pos, int(r["amount"]) * coins)
			"energy":
				game.pickups.drop_energy(pos, float(r["amount"]))
			"heart":
				game.pickups.drop_heart(pos)
			"shield":
				game.pickups.drop_shield(pos)
	if e == boss:
		_boss_defeated(e)


func _clear_stage() -> void:
	if cleared:
		return
	cleared = true
	in_combat = false
	var room := game.room
	var run := game.run
	run.rooms += 1
	if not run.damaged_in_room:
		run.nodamage_rooms += 1
	game.hud.banner("SALA DESPEJADA", 1.8, "", Color("9fffe8"))
	game.sfx.play("clear", 0.0)
	var c := room.floor_rect.get_center()
	game.pickups.drop_coins(game.player.position + Vector2(0, -20), 6 + stage * 2)
	if rng.randf() < 0.45:
		game.pickups.drop_heart(game.player.position + Vector2(20, -10))
	game.pickups.drop_energy(game.player.position + Vector2(-20, -10), 12.0)
	if game.mode_id == ModeRules.EXPEDITION:
		var mid := str(plan[stage].get("modifier", ""))
		if mid != "":   # riesgo asumido, recompensa cobrada
			game.pickups.drop_coins(game.player.position + Vector2(10, 14), int(ModeRules.EXP_MODIFIERS[mid]["coins"]))
			if int(ModeRules.EXP_MODIFIERS[mid]["risk"]) >= 2:
				game.pickups.drop_heart(game.player.position + Vector2(-26, 12))
	PerkEffects.on_room_clear(game)
	if stage == plan.size() - 1 and (game.mode_id != ModeRules.EXPEDITION or str(plan[stage]["kind"]) == "boss"):
		_finish_chapter(null)
		return
	var t := token
	if plan[stage]["perk_after"]:
		perk_busy = true
		get_tree().create_timer(1.1).timeout.connect(func():
			if t == token and not game.over:
				game.offer_perk("clear"))
	else:
		_open_exit()


func perk_closed() -> void:
	perk_busy = false
	if game.mode_id == ModeRules.HORDE:
		_start_horde_wave()
		return
	if surv_pending_phase >= 0:
		var ph := surv_pending_phase
		surv_pending_phase = -1
		_survival_phase_change(ph)
		return
	if game.mode_id == ModeRules.BOSS_RUSH:
		_rush_start_wait()
		return
	_open_exit()


func _open_exit() -> void:
	var room := game.room
	if not room.has_exit:
		return
	room.set_exit_open(true)
	game.sfx.play("swap", -2.0, 0.6)
	game.fx.ring(room.seal_rect.get_center(), 10.0, 100.0, game.chapter.accent, 0.5, 4.0)
	game.hud.toast("EL CAMINO ESTÁ ABIERTO", game.chapter.accent.lightened(0.5))


func _leave() -> void:
	if game.mode_id == ModeRules.EXPEDITION and stage + 1 >= plan.size():
		_exp_offer_routes()      # el siguiente tramo aun no existe: se elige la ruta (modal) y se vuelve a llamar
		return
	transition = true
	game.input_locked = true
	game.sfx.play("ui_open", -4.0)
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.28)
	await tw.finished
	if stage + 1 >= plan.size():
		return
	_load_stage(stage + 1, false)
	for i in SETTLE_FRAMES + 1:
		await get_tree().process_frame
	game.input_locked = false
	transition = false


func _boss_defeated(e: Enemy) -> void:
	for o in game.enemies.duplicate():
		if o != e:
			o.hp = 0.0
			o._start_dying(Vector2.RIGHT)
	game.run.bosses += 1
	game.run.rooms += 1
	if game.mode_id == ModeRules.BOSS_RUSH and stage < plan.size() - 1:
		_rush_intermission(e)
		return
	_finish_chapter(e)


func _finish_chapter(e: Enemy) -> void:
	game.run.won = true
	game.victory = true
	cleared = true
	in_combat = false
	game.hud.boss = null
	game.slow_enemies(0.2, 1.4)
	game.sfx.play("victory", -2.0)
	var at := e.hit_center() if e != null else game.player.position + Vector2(0, -30)
	var bonus := (Catalog.bosses[game.chapter.boss] as BossData).coins if e != null else 30
	if game.mode_id == ModeRules.TIME_ATTACK:
		var tot := ModeRules.time_attack_total(game.run.time, game.run.penalty_time)
		game.hud.banner("¡%d:%05.2f!" % [int(tot) / 60, fmod(tot, 60.0)], 3.2, "Contrarreloj completada", Color("ffe27a"))
		game.pickups.drop_coins(at, bonus)
	else:
		game.hud.banner("¡EXPEDICIÓN COMPLETADA!" if game.mode_id == ModeRules.EXPEDITION else "¡CAPÍTULO COMPLETADO!", 3.2, game.chapter.display_name, Color("ffe27a"))
		game.pickups.drop_coins(at, bonus)
		game.pickups.drop_weapon(at + Vector2(0, 40), roll_weapon(2, 4))
		game.pickups.drop_heart(at + Vector2(30, 10))
	AudioMgr.play_music(game.chapter.music)
	end_won = true
	end_t = 3.6


func on_player_died() -> void:
	end_won = false
	end_t = 1.9
	AudioMgr.stop_hum()
	game.hud.banner("", 0.1)


# ------------------------------------------------------------------ SUPERVIVENCIA
func _start_survival_wave() -> void:
	surv_wave += 1
	game.run.wave = surv_wave
	surv_phase = ModeRules.phase_of_wave(surv_wave)
	game.recalc_hp_scale(ModeRules.difficulty_scale(surv_wave, surv_phase))
	elite_done = false
	next_wave_t = -1.0
	wave_i = surv_wave - 1
	wave_clock = 0.0
	for u in ModeRules.survival_wave(surv_wave, rng):
		pending.append([u["id"], u["delay"], u["elite"]])
	game.hud.banner("OLEADA %d" % surv_wave, 1.4, game.chapter.display_name, game.chapter.accent.lightened(0.6))
	game.sfx.play("wave", -2.0)
	if surv_wave > 1:
		game.pickups.drop_energy(game.room.floor_rect.get_center(), 14.0)
		if game.player.hp < game.player.max_hp and rng.randf() < 0.5:
			game.pickups.drop_heart(game.room.floor_rect.get_center() + Vector2(rng.randf_range(-80, 80), rng.randf_range(-40, 40)))


func _update_survival(dt: float) -> void:
	wave_clock += dt
	var i := pending.size() - 1
	while i >= 0:
		pending[i][1] -= dt
		if pending[i][1] <= 0.0:
			if _try_spawn(pending[i][0], pending[i][2]):
				pending.remove_at(i)
			else:
				pending[i][1] = 0.3
		i -= 1
	var alive := game.enemies.size() + pending.size()
	# la siguiente oleada empieza cuando queda poca gente: presion continua, sin esperas largas
	if pending.is_empty() and alive <= 1 and next_wave_t < 0.0 and not game.over:
		next_wave_t = 1.0
	if next_wave_t >= 0.0:
		next_wave_t -= dt
		if next_wave_t <= 0.0:
			next_wave_t = -1.0
			_survival_next()


func _survival_next() -> void:
	var n := surv_wave + 1
	var phase := ModeRules.phase_of_wave(n)
	if phase != surv_phase:
		# fin de fase: se cura algo, se elige una mejora y se pasa a la arena de la siguiente familia
		game.player.heal(2)
		game.hud.banner("FASE SUPERADA", 1.6, "", Color("ffe27a"))
		surv_pending_phase = phase
		perk_busy = true
		var t := token
		get_tree().create_timer(1.2).timeout.connect(func():
			if t == token and not game.over:
				game.offer_perk("clear"))
		return
	_start_survival_wave()


func _survival_phase_change(phase: int) -> void:
	transition = true
	game.input_locked = true
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.28)
	await tw.finished
	surv_phase = phase
	plan.append(ModeRules.survival_stage(phase))
	_load_stage(plan.size() - 1, false)
	for i in SETTLE_FRAMES + 1:
		await get_tree().process_frame
	game.input_locked = false
	transition = false


# ------------------------------------------------------------------ BOSS RUSH
## Tras cada jefe (menos el ultimo): recuperacion parcial, dos armas para elegir, mejora y una cuenta atras de preparacion.
func _rush_intermission(e: Enemy) -> void:
	cleared = true
	in_combat = false
	game.hud.boss = null
	game.slow_enemies(0.25, 1.2)
	game.sfx.play("victory", -4.0)
	game.hud.banner("JEFE DERROTADO", 2.4, "Prepárate para el siguiente", Color("ffe27a"))
	var at := e.hit_center()
	game.pickups.drop_coins(at, (Catalog.bosses[game.chapter.boss] as BossData).coins)
	var pl := game.player
	pl.heal(2)
	pl.add_shield(1)
	pl.add_energy(60.0)
	var c := game.room.floor_rect.get_center()
	game.pickups.drop_weapon(c + Vector2(-90, 70), roll_weapon(1, 4))
	game.pickups.drop_weapon(c + Vector2(90, 70), roll_weapon(1, 4))
	game.pickups.drop_heart(c + Vector2(0, 90))
	AudioMgr.play_music(game.chapter.music)
	perk_busy = true
	var t := token
	get_tree().create_timer(1.6).timeout.connect(func():
		if t == token and not game.over:
			game.offer_perk("clear"))


func _rush_start_wait() -> void:
	rush_wait = 12.0
	_rush_last_sec = -1
	game.hud.banner("PREPARACIÓN", 1.6, "Elige un arma · recoge tus recompensas", Color("9fffe8"))


# ------------------------------------------------------------------ HORDA INFINITA
func _start_horde_wave() -> void:
	surv_wave += 1
	game.run.wave = surv_wave
	game.recalc_hp_scale(ModeRules.horde_hp_scale(surv_wave))
	elite_done = false
	next_wave_t = -1.0
	wave_i = surv_wave - 1
	wave_clock = 0.0
	var champion := false
	for u in ModeRules.horde_wave(surv_wave, game.chapter.id, rng):
		pending.append([u["id"], u["delay"], u["elite"]])
		champion = champion or bool(u.get("champion", false))
	var sub := game.chapter.display_name
	if champion:
		sub = "¡CAMPEÓN!"
	game.hud.banner("OLEADA %d" % surv_wave, 1.4, sub, Color("ff7a9a") if champion else game.chapter.accent.lightened(0.6))
	game.sfx.play("wave", -2.0)
	if champion:
		game.sfx.play("roar", -6.0)
	if surv_wave > 1:
		game.pickups.drop_energy(game.room.floor_rect.get_center(), 16.0)
		if game.player.hp < game.player.max_hp and rng.randf() < 0.5:
			game.pickups.drop_heart(game.room.floor_rect.get_center() + Vector2(rng.randf_range(-80, 80), rng.randf_range(-40, 40)))


func _update_horde(dt: float) -> void:
	wave_clock += dt
	var i := pending.size() - 1
	while i >= 0:
		pending[i][1] -= dt
		if pending[i][1] <= 0.0:
			# tope de enemigos simultaneos: el resto espera en cola (rendimiento y justicia)
			if game.enemies.size() + spawn_busy.size() >= ModeRules.HORDE_MAX_ALIVE:
				pending[i][1] = 0.25
			elif _try_spawn(pending[i][0], pending[i][2]):
				pending.remove_at(i)
			else:
				pending[i][1] = 0.3
		i -= 1
	var alive := game.enemies.size() + pending.size()
	if pending.is_empty() and alive <= 1 and next_wave_t < 0.0 and not game.over:
		next_wave_t = 1.2
	if next_wave_t >= 0.0:
		next_wave_t -= dt
		if next_wave_t <= 0.0:
			next_wave_t = -1.0
			_horde_next()


## Fin de oleada: recompensa; cada HORDE_PERK_EVERY oleadas, una mejora (la oleada siguiente empieza al cerrarla).
func _horde_next() -> void:
	var pl := game.player
	game.pickups.drop_coins(pl.position + Vector2(0, -20), 3 + surv_wave)
	pl.add_energy(25.0)
	if surv_wave % 2 == 0:
		pl.heal(1)
		pl.add_shield(1)
	game.hud.banner("OLEADA %d SUPERADA" % surv_wave, 1.4, "", Color("ffe27a"))
	game.sfx.play("clear", -2.0)
	if surv_wave % ModeRules.HORDE_PERK_EVERY == 0:
		perk_busy = true
		var t := token
		get_tree().create_timer(1.1).timeout.connect(func():
			if t == token and not game.over:
				game.offer_perk("clear"))
		return
	_start_horde_wave()


# ------------------------------------------------------------------ EXPEDICION
func _rest_site() -> void:
	var pl := game.player
	pl.heal(3)
	pl.add_shield(pl.max_shield)
	pl.add_energy(pl.max_energy)
	game.hud.toast("DESCANSO: vida, escudo y energía recuperados", Color("9fffe8"))


## Muestra la eleccion de ruta (2-3 tramos compatibles con el capitulo). Al elegir se agrega el tramo al plan y se continua.
func _exp_offer_routes() -> void:
	if exp_picker != null and is_instance_valid(exp_picker):
		return
	var cur: Dictionary = plan[stage]
	var need := ""
	var exit: String = str(cur.get("exit", ""))
	if exit != "":
		need = DungeonGenerator.OPP.get(exit, "")
	var next_idx := plan.size()
	if next_idx >= ModeRules.EXP_LEGS:
		_exp_choose({"boss": true})
		return
	var opts := ModeRules.expedition_options(game.chapter, next_idx, need, str(cur.get("route", cur["kind"])), rng, exp_used_rooms)
	var picker := RoutePicker.new()
	picker.game = game
	picker.options = opts
	picker.leg = next_idx
	exp_picker = picker
	perk_busy = true
	game.overlay_layer.add_child(picker)


func _exp_choose(opt: Dictionary) -> void:
	perk_busy = false
	exp_picker = null
	var cur: Dictionary = plan[stage]
	var need: String = DungeonGenerator.OPP.get(str(cur.get("exit", "")), "")
	if opt.get("boss", false):
		plan.append(ModeRules.expedition_boss_stage(game.chapter, need))
		game.hud.toast("EL JEFE TE ESPERA", Color("ff7a9a"))
	else:
		var st: Dictionary = opt.duplicate()
		st["route"] = st["kind"]
		if st["kind"] in ["cache", "rest"]:
			st["kind"] = "cache"
		plan.append(st)
		exp_used_rooms.append(st["room"])
		game.run.route_log.append(str(st["route"]))
	game.run.legs += 1
	_leave()
