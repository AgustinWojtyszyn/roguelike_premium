class_name ScrollPane
extends Control
## Zona desplazable (vertical u horizontal) con inercia, rueda y arrastre tactil. El contenido se dibuja por callback
## en coordenadas de contenido; las zonas tocables se registran con reg() y se resuelven al soltar (tap vs arrastre).

var horizontal := false
var content_len: float = 1000.0
var scroll: float = 0.0
var vel: float = 0.0
var draw_cb: Callable
var tap_cb: Callable
var regions: Array[Dictionary] = []
var pressed_id := ""
var pressed_t := 0.0
var _drag_active := false
var _press_pos := Vector2.ZERO
var _moved := false
var _touch_idx := -1
var _last_pos := Vector2.ZERO
var _last_t := 0.0
var t: float = 0.0
var snap_to: float = 0.0


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func max_scroll() -> float:
	var vis := size.x if horizontal else size.y
	return maxf(0.0, content_len - vis)


func scroll_to(v: float, instant: bool = false) -> void:
	scroll = clampf(v, 0.0, max_scroll())
	vel = 0.0


func reg(id: String, r: Rect2) -> void:
	var off := Vector2(-scroll, 0.0) if horizontal else Vector2(0.0, -scroll)
	regions.append({"id": id, "rect": Rect2(r.position + off, r.size)})


func is_pressed(id: String) -> bool:
	return pressed_id == id and _drag_active and not _moved


func _process(delta: float) -> void:
	t += delta
	if not _drag_active and absf(vel) > 5.0:
		scroll = clampf(scroll + vel * delta, 0.0, max_scroll())
		vel = move_toward(vel, 0.0, absf(vel) * 4.0 * delta + 60.0 * delta)
		if scroll <= 0.0 or scroll >= max_scroll():
			vel = 0.0
	queue_redraw()


func _draw() -> void:
	regions.clear()
	if not draw_cb.is_valid():
		return
	var off := Vector2(-scroll, 0.0) if horizontal else Vector2(0.0, -scroll)
	draw_set_transform(off, 0.0, Vector2.ONE)
	draw_cb.call(self)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _region_at(p: Vector2) -> String:
	for i in range(regions.size() - 1, -1, -1):
		if (regions[i]["rect"] as Rect2).has_point(p):
			return regions[i]["id"]
	return ""


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			scroll = clampf(scroll - 80.0, 0.0, max_scroll())
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			scroll = clampf(scroll + 80.0, 0.0, max_scroll())
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_begin(e.position, -2)
			else:
				_end(e.position)
	elif e is InputEventMouseMotion and _drag_active and _touch_idx == -2:
		_move(e.position)
	elif e is InputEventScreenTouch:
		if e.pressed and _touch_idx == -1:
			_begin(e.position, e.index)
		elif not e.pressed and e.index == _touch_idx:
			_end(e.position)
	elif e is InputEventScreenDrag and e.index == _touch_idx:
		_move(e.position)


func _begin(p: Vector2, idx: int) -> void:
	_drag_active = true
	_touch_idx = idx
	_press_pos = p
	_last_pos = p
	_moved = false
	vel = 0.0
	pressed_id = _region_at(p)
	_last_t = Time.get_ticks_msec() / 1000.0


func _move(p: Vector2) -> void:
	var d := (p - _press_pos)
	if not _moved and d.length() > 14.0:
		_moved = true
	if _moved:
		var delta_v := (_last_pos.x - p.x) if horizontal else (_last_pos.y - p.y)
		scroll = clampf(scroll + delta_v, 0.0, max_scroll())
		var now := Time.get_ticks_msec() / 1000.0
		var dtv := maxf(now - _last_t, 0.001)
		vel = lerpf(vel, delta_v / dtv, 0.5)
		_last_t = now
	_last_pos = p


func _end(p: Vector2) -> void:
	var was_tap := _drag_active and not _moved
	_drag_active = false
	_touch_idx = -1
	var id := pressed_id
	pressed_id = ""
	if was_tap and id != "" and _region_at(p) == id:
		AudioMgr.ui("ui_click", -2.0)
		if tap_cb.is_valid():
			tap_cb.call(id)
