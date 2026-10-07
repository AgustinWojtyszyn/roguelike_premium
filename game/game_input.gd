class_name GameInput
extends Node
## Entrada de la run (teclado+raton, mando, tactil) abstraida: Game y Player solo consultan move/aim/fire/ability.
## Tactil: stick izquierdo = mover; mitad derecha = apuntar/disparar; botones fijos de habilidad, cambio de arma y pausa.

var game: Game
var touch_move_id := -1
var touch_move_o := Vector2.ZERO
var touch_move_p := Vector2.ZERO
var touch_aim_id := -1
var touch_aim_o := Vector2.ZERO
var touch_aim_p := Vector2.ZERO
var mouse_down := false
var ability_queued := false
var ability_touch_id := -1
var swap_touch_id := -1
var auto_walk: Variant = null     # Vector2: el jugador camina solo (entrada a sala)
var auto_walk_t: float = 0.0


func reset() -> void:
	touch_move_id = -1
	touch_aim_id = -1
	mouse_down = false
	ability_queued = false


func move_input() -> Vector2:
	if game.bot:
		return _bot_move()
	if auto_walk != null:
		var to: Vector2 = (auto_walk as Vector2) - game.player.position
		auto_walk_t += get_process_delta_time()
		if to.length() < 20.0 or auto_walk_t > 2.2:
			auto_walk = null
			return Vector2.ZERO
		return to.normalized() * 0.8
	if game.input_locked:
		return Vector2.ZERO
	var v := Vector2.ZERO
	if touch_move_id != -1:
		var d := touch_move_p - touch_move_o
		v = (d / 70.0).limit_length(1.0)
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
	if game.bot:
		return _bot_aim(origin)
	if touch_aim_id != -1:
		var d := touch_aim_p - touch_aim_o
		if d.length() > 8.0:
			return _assist(origin, d.normalized())
		return game.player.aim
	var pad := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if pad.length() > 0.3:
		return pad.normalized()
	if game.touch_mode:
		return game.player.aim
	return game.get_global_mouse_position() - origin


func fire_input() -> bool:
	if game.bot:
		return true
	if game.input_locked or game.over:
		return false
	if touch_aim_id != -1:
		return (touch_aim_p - touch_aim_o).length() > 26.0
	var pad := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if pad.length() > 0.5 or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.4:
		return true
	return mouse_down


func ability_input() -> bool:
	if game.bot:
		return game.player.energy > game.player.data.ability_cost + 20.0 and not game.enemies.is_empty() and randf() < 0.01
	var q := ability_queued
	ability_queued = false
	return q


func _assist(origin: Vector2, a: Vector2) -> Vector2:
	if not bool(Profile.p.setting("aim_assist")):
		return a
	var best := a
	var best_d := 0.26
	for e in game.enemies:
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
	if game.over and not game.result_ready:
		return
	var vs := game.get_viewport_rect().size
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not game.touch_mode and HudRects.pause_rect(vs).has_point(event.position):
				game.request_pause()
				return
			mouse_down = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			game.player.swap_weapon()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			game.player.swap_weapon()
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			ability_queued = true
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:
				game.player.select_weapon(0)
			KEY_2:
				game.player.select_weapon(1)
			KEY_Q, KEY_E, KEY_TAB:
				game.player.swap_weapon()
			KEY_SPACE, KEY_F:
				ability_queued = true
			KEY_ESCAPE, KEY_P:
				game.request_pause()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER or event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			game.player.swap_weapon()
		elif event.button_index == JOY_BUTTON_A or event.button_index == JOY_BUTTON_X:
			ability_queued = true
		elif event.button_index == JOY_BUTTON_START:
			game.request_pause()
	elif event is InputEventScreenTouch:
		game.touch_mode = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var p: Vector2 = event.position
		if event.pressed:
			if HudRects.pause_rect(vs).grow(8.0).has_point(p):
				game.request_pause()
			elif p.distance_to(HudRects.ability_center(vs)) < 62.0:
				ability_queued = true
				ability_touch_id = event.index
			elif game.player.slots.size() > 1 and p.distance_to(HudRects.swap_center(vs)) < 56.0:
				swap_touch_id = event.index
				game.player.swap_weapon()
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
			if event.index == swap_touch_id:
				swap_touch_id = -1
			if event.index == ability_touch_id:
				ability_touch_id = -1
	elif event is InputEventScreenDrag:
		var p: Vector2 = event.position
		if event.index == touch_move_id:
			touch_move_p = p
			var d := touch_move_p - touch_move_o
			if d.length() > 90.0:
				touch_move_o = touch_move_p - d.normalized() * 90.0
		elif event.index == touch_aim_id:
			touch_aim_p = p
			var d := touch_aim_p - touch_aim_o
			if d.length() > 90.0:
				touch_aim_o = touch_aim_p - d.normalized() * 90.0


# ---------------------------------------------------------------- bot de pruebas (--bot)
var _bot_last := Vector2.ZERO
var _bot_stuck := 0.0
var _bot_detour := 0.0
var _bot_detour_dir := Vector2.ZERO
var _bot_beeline := 0.0


func _bot_move() -> Vector2:
	if game.idle:
		return Vector2.ZERO
	# desatasco: sin pathfinding, si el bot lleva 1.5 s sin avanzar toma un rodeo aleatorio
	var dtb := get_process_delta_time()
	if game.player.position.distance_to(_bot_last) < 10.0 * dtb * 6.0:
		_bot_stuck += dtb
	else:
		_bot_stuck = 0.0
		_bot_last = game.player.position
	if _bot_detour > 0.0:
		_bot_detour -= dtb
		return _bot_detour_dir
	if _bot_beeline > 0.0:
		_bot_beeline -= dtb
	if _bot_stuck > 1.5:
		_bot_stuck = 0.0
		_bot_last = game.player.position
		var far := game.nearest_enemy()
		if far != null and far.position.distance_to(game.player.position) > 380.0:
			_bot_beeline = 3.5         # enemigo lejano (torreta en una esquina): ir en linea recta hacia el
		else:
			_bot_detour = 1.4
			_bot_detour_dir = Vector2.from_angle(randf() * TAU)
			return _bot_detour_dir
	var nearest := game.nearest_enemy()
	var v := Vector2.ZERO
	var p := game.player.position
	if auto_walk != null:
		var to: Vector2 = (auto_walk as Vector2) - p
		if to.length() < 20.0 or auto_walk_t > 2.2:
			auto_walk = null
		else:
			auto_walk_t += get_process_delta_time()
			return to.normalized() * 0.8
	if nearest != null:
		var to: Vector2 = nearest.position - p
		var d := to.length()
		var dir := to / maxf(d, 0.01)
		var tang := Vector2(-dir.y, dir.x)
		v = tang * 0.9
		if _bot_beeline > 0.0 and d > 300.0:
			v = dir * 1.3
		elif d < 230.0:
			v -= dir * 1.0
		elif d > 340.0:
			v += dir * 0.6
	else:
		var target := game.bot_goal()
		v = (target - p).limit_length(1.0) * 0.8
	var fr := game.room.floor_rect
	if (absf(p.x - fr.get_center().x) > fr.size.x * 0.5 - 130.0 or absf(p.y - fr.get_center().y) > fr.size.y * 0.5 - 90.0) and not game.director.exit_open():
		if fr.has_point(p):
			v += (fr.get_center() - p).normalized() * 1.2
	for r in game.room.rects:
		var rc: Rect2 = r
		var cp := Vector2(clampf(p.x, rc.position.x, rc.end.x), clampf(p.y, rc.position.y, rc.end.y))
		var dd := p - cp
		if dd.length() < 55.0 and dd.length() > 0.01:
			v += dd.normalized() * 1.5
	return v.limit_length(1.0)


func _bot_aim(origin: Vector2) -> Vector2:
	var n := game.nearest_enemy()
	if n != null:
		return n.hit_center() - origin
	return game.player.aim
