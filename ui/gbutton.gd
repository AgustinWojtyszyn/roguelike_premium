class_name GButton
extends Control
## Boton de menu: respuesta tactil inmediata (escala/hundimiento), sonido, icono + texto, insignia de notificacion.
## Funciona con raton Y con toque (el proyecto desactiva la emulacion de raton desde toque).

signal pressed

enum Style { PRIMARY, SECONDARY, GOLD, DANGER, GHOST, TAB, ICON }

var label := ""
var sublabel := ""
var icon := ""
var style: int = Style.SECONDARY
var font_size := 24
var badge := 0              # >0 muestra una insignia roja
var badge_text := ""
var enabled := true
var selected := false
var press_k: float = 0.0
var hover_k: float = 0.0
var pulse := false
var _down := false
var _touch_idx := -1
var _t: float = 0.0
var click_sound := "ui_click"
var icon_col := Color.WHITE
var extra: Callable          # func(ci: CanvasItem, r: Rect2) dibuja encima del cuerpo


static func make(text: String, st: int = Style.SECONDARY, ic: String = "") -> GButton:
	var b := GButton.new()
	b.label = text
	b.style = st
	b.icon = ic
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	return b


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = size * 0.5
	resized.connect(func(): pivot_offset = size * 0.5)


func _process(delta: float) -> void:
	_t += delta
	var tgt_p := 1.0 if _down else 0.0
	press_k = move_toward(press_k, tgt_p, delta * 14.0)
	var tgt_h := 1.0 if (_hover and enabled) else 0.0
	hover_k = move_toward(hover_k, tgt_h, delta * 10.0)
	scale = Vector2.ONE * (1.0 - press_k * 0.05 + hover_k * 0.012)
	if press_k > 0.0 or hover_k > 0.0 or pulse or badge > 0 or selected:
		queue_redraw()


var _hover := false


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hover = true
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hover = false
		if _touch_idx == -1:
			_down = false
	elif what == NOTIFICATION_VISIBILITY_CHANGED:
		_down = false
		_touch_idx = -1


func _gui_input(e: InputEvent) -> void:
	if not enabled:
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			AudioMgr.ui("ui_error", -6.0)
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_down = true
		else:
			if _down and Rect2(Vector2.ZERO, size).has_point(e.position):
				_fire()
			_down = false
	elif e is InputEventScreenTouch:
		if e.pressed and _touch_idx == -1:
			_touch_idx = e.index
			_down = true
		elif not e.pressed and e.index == _touch_idx:
			if _down and Rect2(Vector2.ZERO, size).has_point(e.position):
				_fire()
			_down = false
			_touch_idx = -1
	elif e is InputEventScreenDrag and e.index == _touch_idx:
		if not Rect2(Vector2.ZERO, size).grow(30.0).has_point(e.position):
			_down = false


func _fire() -> void:
	AudioMgr.ui(click_sound, -2.0)
	pressed.emit()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var top: Color
	var bot: Color
	var txt := UiKit.TEXT
	match style:
		Style.PRIMARY:
			top = Color("ffb23d")
			bot = Color("ff6a2a")
		Style.GOLD:
			top = Color("ffe27a")
			bot = Color("f0a020")
			txt = Color("3a2200")
		Style.DANGER:
			top = Color("ff7a8a")
			bot = Color("d83a52")
		Style.GHOST:
			top = Color(0.2, 0.28, 0.44, 0.9)
			bot = Color(0.1, 0.15, 0.28, 0.9)
		Style.TAB:
			if selected:
				top = Color("35e8d4")
				bot = Color("12a39a")
				txt = Color("04201e")
			else:
				top = Color("2a3a5c")
				bot = Color("141e38")
		Style.ICON:
			top = Color("3a4c78")
			bot = Color("1a2442")
		_:
			top = Color("3fb8ff")
			bot = Color("1a68d8")
	if not enabled:
		top = top.lerp(Color("3a4056"), 0.75)
		bot = bot.lerp(Color("20243a"), 0.75)
		txt = Color(txt, 0.5)
	if pulse and enabled:
		var k := 0.5 + 0.5 * sin(_t * 4.0)
		Gfx.draw_glow(self, r.get_center(), maxf(size.x, size.y) * (0.7 + 0.1 * k), Color(top, 0.25 + 0.2 * k))
	var cut := minf(14.0, size.y * 0.3)
	var body := UiKit.chunky(self, r, top, bot, press_k, hover_k, cut, 3.0)
	var cy := body.position.y + body.size.y * 0.5
	var has_icon := icon != ""
	if style == Style.ICON or label == "":
		if has_icon:
			var s := minf(size.x, size.y) * 0.3
			UiIcons.draw(self, icon, Vector2(r.size.x * 0.5, cy), s, icon_col)
	else:
		var tw := UiKit.text_width(label, font_size)
		var isz := font_size * 0.8 if has_icon else 0.0
		var total := tw + (isz * 2.2 if has_icon else 0.0)
		var x0 := (size.x - total) * 0.5
		if has_icon:
			UiIcons.draw(self, icon, Vector2(x0 + isz, cy), isz, icon_col)
			x0 += isz * 2.2
		var ty := cy + font_size * 0.36
		if sublabel != "":
			ty = cy - 2.0
			UiKit.text(self, Vector2(x0, ty), label, font_size, txt, 0, -1.0, 4.0 if style != Style.GOLD else 0.0)
			UiKit.text(self, Vector2(0, cy + font_size * 0.8), sublabel, int(font_size * 0.5), Color(txt, 0.75), 1, size.x, 0.0, false)
		else:
			UiKit.text(self, Vector2(x0, ty), label, font_size, txt, 0, -1.0, 4.0 if style != Style.GOLD else 0.0)
	if extra.is_valid():
		extra.call(self, r)
	if badge > 0 or badge_text != "":
		var c := Vector2(size.x - 8.0, 8.0)
		var s := badge_text if badge_text != "" else (str(badge) if badge < 10 else "9+")
		var w := maxf(22.0, UiKit.text_width(s, 14) + 12.0)
		UiKit.pill(self, Rect2(c.x - w * 0.5 - 6.0, c.y - 11.0, w, 22.0), Color("ff4a5a"), UiKit.INK, 2.5)
		UiKit.text(self, Vector2(c.x - w * 0.5 - 6.0, c.y + 5.0), s, 14, Color.WHITE, 1, w)
