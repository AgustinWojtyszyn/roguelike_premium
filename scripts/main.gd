class_name Game
extends Node2D
## Director: monta la sala, gestiona entrada (PC/Android), oleadas, camara y feedback global.

static var tscale: float = 1.0

const WAVES := [
	[["S", 0.0], ["S", 0.9], ["L", 2.3]],
	[["S", 0.0], ["L", 0.9], ["S", 1.8], ["L", 3.2]],
	[["B", 0.0], ["L", 2.4], ["S", 3.6]],
]
const MELEE_SLOTS := 2

var ysort: Node2D
var room: Room
var fx: Fx
var bullets: Bullets
var player: Player
var sfx: Sfx
var cam: Camera2D
var hud: Hud
var enemies: Array[Enemy] = []
var melee_users: Array = []
var pending: Array = []        # [kind, tiempo_restante]
var wave: int = -1
var wave_clock: float = 0.0
var next_wave_t: float = -1.0
var hatch_busy: Dictionary = {}
var over := false
var victory := false
var end_t: float = 0.0
var trauma: float = 0.0
var shake_t: float = 0.0
var cam_pos := Vector2.ZERO
var hs_timer: float = 0.0
var kills: int = 0
var clock: float = 0.0

# entrada
var touch_move_id := -1
var touch_move_o := Vector2.ZERO
var touch_move_p := Vector2.ZERO
var touch_aim_id := -1
var touch_aim_o := Vector2.ZERO
var touch_aim_p := Vector2.ZERO
var touch_mode := false
var mouse_down := false
var touch_swap_id := -1

# banco de pruebas automatico (--bot) y capturas (--shots=2,5,9)
var bot := false
var god := false
var focus := false
var idle := false
var zoom_arg: float = 1.32
var start_wave: int = 0
var bot_t := 0.0
var shots: Array[float] = []
var shot_dir := "/tmp/shots"
var shot_i := 0
var quit_at := -1.0


func _ready() -> void:
	randomize()
	tscale = 1.0
	Engine.time_scale = 1.0
	RenderingServer.set_default_clear_color(Color("04060c"))
	touch_mode = DisplayServer.is_touchscreen_available() or OS.has_feature("android") or OS.has_feature("web_android")
	if not touch_mode:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a == "--bot":
			bot = true
		elif a.begins_with("--shots="):
			for s in a.substr(8).split(","):
				shots.append(float(s))
		elif a.begins_with("--shotdir="):
			shot_dir = a.substr(10)
		elif a.begins_with("--quit="):
			quit_at = float(a.substr(7))
		elif a == "--idle":
			idle = true
		elif a == "--focus":
			focus = true
		elif a.begins_with("--zoom="):
			zoom_arg = float(a.substr(7))
		elif a == "--god":
			god = true
		elif a.begins_with("--wave="):
			start_wave = int(a.substr(7))
		elif a == "--touch":
			touch_mode = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	sfx = Sfx.new()
	add_child(sfx)
	ysort = Node2D.new()
	ysort.y_sort_enabled = true
	room = Room.new()
	add_child(room)
	add_child(ysort)
	room.build(self)
	fx = Fx.new()
	add_child(fx)
	bullets = Bullets.new()
	bullets.game = self
	add_child(bullets)
	player = Player.new()
	player.position = Vector2(0, 150)
	ysort.add_child(player)
	player.build(self)
	cam = Camera2D.new()
	cam.zoom = Vector2.ONE * zoom_arg
	add_child(cam)
	cam.make_current()
	cam_pos = player.position
	hud = Hud.new()
	hud.game = self
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	layer.add_child(hud)
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_snap_camera()
	get_tree().create_timer(0.8).timeout.connect(func(): _start_wave(start_wave))


# ---------------------------------------------------------------- entrada
func _view_size() -> Vector2:
	return get_viewport_rect().size


func move_input() -> Vector2:
	if bot:
		return _bot_move()
	var v := Vector2.ZERO
	if touch_move_id != -1:
		var d := touch_move_p - touch_move_o
		var r := 70.0
		v = (d / r).limit_length(1.0)
		if v.length() < 0.12:
			v = Vector2.ZERO
		return v
	v.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	v.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	var pad := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if pad.length() > 0.2:
		v += pad
	return v.limit_length(1.0)


func aim_input(origin: Vector2) -> Vector2:
	if bot:
		return _bot_aim(origin)
	if touch_aim_id != -1:
		var d := touch_aim_p - touch_aim_o
		if d.length() > 8.0:
			var a := d.normalized()
			return _assist(origin, a)
		return player.aim
	var pad := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if pad.length() > 0.3:
		return pad.normalized()
	if touch_mode:
		return player.aim
	return get_global_mouse_position() - origin


func fire_input() -> bool:
	if bot:
		return true
	if touch_aim_id != -1:
		return (touch_aim_p - touch_aim_o).length() > 26.0
	var pad := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if pad.length() > 0.5 or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.4:
		return true
	return mouse_down


func _assist(origin: Vector2, a: Vector2) -> Vector2:
	var best := a
	var best_d := 0.26
	for e in enemies:
		if not e.targetable():
			continue
		var to: Vector2 = e.hit_center() - origin
		if to.length() > 640.0:
			continue
		var da := absf(a.angle_to(to))
		if da < best_d:
			best_d = da
			best = a.slerp(to.normalized(), 0.75)
	return best


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_down = event.pressed
			if event.pressed:
				_restart_check()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			player.setup_weapon((player.weapon + 2) % 3)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			player.setup_weapon((player.weapon + 1) % 3)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:
				player.setup_weapon(0)
			KEY_2:
				player.setup_weapon(1)
			KEY_3:
				player.setup_weapon(2)
			KEY_Q:
				player.setup_weapon((player.weapon + 2) % 3)
			KEY_E:
				player.setup_weapon((player.weapon + 1) % 3)
			KEY_R:
				_restart_check()
			KEY_ESCAPE:
				get_tree().quit()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			player.setup_weapon((player.weapon + 1) % 3)
		elif event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			player.setup_weapon((player.weapon + 2) % 3)
		elif event.button_index == JOY_BUTTON_A:
			_restart_check()
	elif event is InputEventScreenTouch:
		touch_mode = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var vs := _view_size()
		var p: Vector2 = event.position
		if event.pressed:
			_restart_check()
			if hud.swap_rect(vs).has_point(p):
				touch_swap_id = event.index
				player.setup_weapon((player.weapon + 1) % 3)
			elif p.x < vs.x * 0.5:
				if touch_move_id == -1:
					touch_move_id = event.index
					touch_move_o = p
					touch_move_p = p
			else:
				if touch_aim_id == -1:
					touch_aim_id = event.index
					touch_aim_o = p
					touch_aim_p = p
		else:
			if event.index == touch_move_id:
				touch_move_id = -1
			if event.index == touch_aim_id:
				touch_aim_id = -1
			if event.index == touch_swap_id:
				touch_swap_id = -1
	elif event is InputEventScreenDrag:
		var p: Vector2 = event.position
		if event.index == touch_move_id:
			touch_move_p = p
			# el origen sigue al dedo si se aleja demasiado (control flotante)
			var d := touch_move_p - touch_move_o
			if d.length() > 90.0:
				touch_move_o = touch_move_p - d.normalized() * 90.0
		elif event.index == touch_aim_id:
			touch_aim_p = p
			var d := touch_aim_p - touch_aim_o
			if d.length() > 90.0:
				touch_aim_o = touch_aim_p - d.normalized() * 90.0


func _restart_check() -> void:
	if (over or victory) and end_t > 1.4:
		Game.tscale = 1.0
		get_tree().reload_current_scene()


# ---------------------------------------------------------------- bot de pruebas
func _bot_move() -> Vector2:
	if idle:
		return Vector2.ZERO
	var nearest := _nearest_enemy()
	var v := Vector2.ZERO
	var p := player.position
	if nearest != null:
		var to: Vector2 = nearest.position - p
		var d := to.length()
		var dir := to / maxf(d, 0.01)
		var tang := Vector2(-dir.y, dir.x)
		v = tang * 0.9
		if d < 230.0:
			v -= dir * 1.0
		elif d > 340.0:
			v += dir * 0.6
	else:
		v = (Vector2(0, 40) - p).limit_length(1.0) * 0.5
	# lejos de los muros
	var c := Vector2.ZERO
	if absf(p.x) > 480.0 or absf(p.y) > 230.0:
		v += (c - p).normalized() * 1.2
	# evita props
	for r in room.rects:
		var rc: Rect2 = r
		var cp := Vector2(clampf(p.x, rc.position.x, rc.end.x), clampf(p.y, rc.position.y, rc.end.y))
		var dd := p - cp
		if dd.length() < 55.0 and dd.length() > 0.01:
			v += dd.normalized() * 1.5
	return v.limit_length(1.0)


func _bot_aim(origin: Vector2) -> Vector2:
	var n := _nearest_enemy()
	if n != null:
		return n.hit_center() - origin
	return player.aim


func _nearest_enemy() -> Enemy:
	var best: Enemy = null
	var bd := 1e9
	for e in enemies:
		if not e.targetable():
			continue
		var d := e.position.distance_to(player.position)
		if d < bd:
			bd = d
			best = e
	return best


# ---------------------------------------------------------------- bucle
func _process(delta: float) -> void:
	var rdt := minf(delta, 1.0 / 30.0)
	clock += rdt
	if hs_timer > 0.0:
		hs_timer -= rdt
		if hs_timer <= 0.0:
			Game.tscale = 1.0
	var dt := rdt * Game.tscale
	if bot:
		bot_t += rdt
		if int(bot_t / 7.0) % 3 != player.weapon and fmod(bot_t, 7.0) < 0.05:
			player.setup_weapon(int(bot_t / 7.0) % 3, true)
	_update_waves(dt)
	_update_camera(rdt)
	if over or victory:
		end_t += rdt
	while shots.size() > shot_i and clock >= shots[shot_i]:
		_save_shot(shot_i)
		shot_i += 1
	if quit_at > 0.0 and clock >= quit_at:
		print("FPS medio: ", Engine.get_frames_per_second(), " kills: ", kills, " hp: ", player.hp, " victoria: ", victory)
		get_tree().quit()


func _save_shot(i: int) -> void:
	DirAccess.make_dir_recursive_absolute(shot_dir)
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/shot_%02d.png" % [shot_dir, i])


func hitstop(sec: float) -> void:
	Game.tscale = 0.04
	hs_timer = maxf(hs_timer, sec)


func shake(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)


func hud_flash() -> void:
	hud.damage_flash = 1.0


func _snap_camera() -> void:
	cam_pos = _cam_target()
	cam.position = cam_pos


func _cam_target() -> Vector2:
	var tgt := player.position + Vector2(0, -26)
	if focus:
		var n := _nearest_enemy()
		if n != null:
			tgt = n.position + Vector2(0, -20)
	elif not touch_mode or touch_aim_id != -1:
		tgt += player.aim * 46.0
	var vs := _view_size() / cam.zoom
	var half := vs * 0.5
	var minx := -650.0 + half.x
	var maxx := 650.0 - half.x
	var miny := -462.0 + half.y
	var maxy := 440.0 - half.y
	tgt.x = clampf(tgt.x, minx, maxx) if minx < maxx else 0.0
	tgt.y = clampf(tgt.y, miny, maxy) if miny < maxy else (miny + maxy) * 0.5
	return tgt


func _update_camera(dt: float) -> void:
	cam_pos = cam_pos.lerp(_cam_target(), 1.0 - exp(-dt * 7.0))
	trauma = maxf(0.0, trauma - dt * 2.2)
	shake_t += dt * 60.0
	var s := trauma * trauma
	var off := Vector2(sin(shake_t * 1.7) + sin(shake_t * 2.9) * 0.5, cos(shake_t * 2.3) + sin(shake_t * 3.7) * 0.5) * 7.0 * s
	cam.position = (cam_pos + off).round()


# ---------------------------------------------------------------- oleadas
func _start_wave(i: int) -> void:
	wave = i
	wave_clock = 0.0
	next_wave_t = -1.0
	for e in WAVES[i]:
		pending.append([e[0], e[1]])
	hud.banner("OLEADA %d / %d" % [i + 1, WAVES.size()], 1.8)
	sfx.play("wave", -2.0)
	if i > 0 and player.hp < Player.MAX_HP:
		player.heal(2)


func _update_waves(dt: float) -> void:
	if wave < 0 or victory:
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
	var alive := enemies.size() + pending.size()
	if alive <= 1 and next_wave_t < 0.0 and pending.size() == 0 and wave < WAVES.size() - 1 and not over:
		next_wave_t = 1.4
	if next_wave_t >= 0.0:
		next_wave_t -= dt
		if next_wave_t <= 0.0:
			_start_wave(wave + 1)
	if alive == 0 and wave == WAVES.size() - 1 and not over and not victory:
		victory = true
		end_t = 0.0
		sfx.play("clear", 0.0)
		hud.banner("SALA DESPEJADA", 3.0)


func _pick_hatch() -> int:
	var best := -1
	var best_s := -1e9
	for i in room.hatches.size():
		if hatch_busy.has(i):
			continue
		var h: Vector2 = room.hatches[i]
		var d := h.distance_to(player.position)
		var s := minf(d, 520.0) + randf() * 140.0
		if d < 280.0:
			s -= 500.0
		for e in enemies:
			if e.position.distance_to(h) < 80.0:
				s -= 200.0
		if s > best_s:
			best_s = s
			best = i
	return best


func _try_spawn(kind: String) -> bool:
	var h := _pick_hatch()
	if h < 0:
		return false
	hatch_busy[h] = true
	room.open_hatch(h, true)
	var pos: Vector2 = room.hatches[h]
	sfx.play("spawn", -6.0)
	fx.ring(pos, 10.0, 70.0, Color("c07aff"), 0.6, 3.0)
	fx.flash(pos, 90.0, Color(0.7, 0.35, 1.0, 0.6), 0.5)
	var lead := 0.65
	get_tree().create_timer(lead).timeout.connect(func():
		var e: Enemy
		match kind:
			"S":
				e = Skitter.new()
			"L":
				e = Lancer.new()
			_:
				e = Brute.new()
		ysort.add_child(e)
		e.setup(self, pos)
		enemies.append(e)
		fx.burst(pos, 14, 240.0, Color("d9a8ff"), 0.5)
		fx.puff(pos, Vector2(0, -20), 24.0, Color(0.8, 0.7, 1.0, 0.4), 0.7, 2.4)
		fx.ring(pos, 6.0, 52.0, Color("e2c2ff"), 0.35, 4.0)
		get_tree().create_timer(1.3).timeout.connect(func():
			room.open_hatch(h, false)
			hatch_busy.erase(h)
		)
	)
	return true


func claim_melee(e: Enemy) -> bool:
	if melee_users.size() >= MELEE_SLOTS:
		return false
	melee_users.append(e)
	return true


func release_melee(e: Enemy) -> void:
	melee_users.erase(e)


func on_enemy_dying(e: Enemy) -> void:
	enemies.erase(e)
	melee_users.erase(e)


func on_enemy_dead(_e: Enemy) -> void:
	kills += 1


func game_over() -> void:
	over = true
	end_t = 0.0
	hud.banner("SISTEMA CAÍDO", 99.0)
	for e in enemies:
		e.vel = Vector2.ZERO
