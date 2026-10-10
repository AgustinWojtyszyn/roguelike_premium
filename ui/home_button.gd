class_name HomeButton
extends GButton
## Shared presentation controls, limited to Home and mode selection.
const GOLD := Color("edca87")
const IVORY := Color("f4f0e6")
var art: Texture2D
var compact := false
var ui_scale := 1.0
var navigation := false
var card := false
var tint := GOLD
var description := ""
var footnote := ""
var kicker := ""

func _ready() -> void:
	super._ready()
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(queue_redraw)
	focus_exited.connect(func(): _down = false; queue_redraw())

func _gui_input(e: InputEvent) -> void:
	if e is InputEventJoypadButton and e.pressed:
		var sides := {JOY_BUTTON_DPAD_LEFT: SIDE_LEFT, JOY_BUTTON_DPAD_UP: SIDE_TOP, JOY_BUTTON_DPAD_RIGHT: SIDE_RIGHT, JOY_BUTTON_DPAD_DOWN: SIDE_BOTTOM}
		if sides.has(e.button_index):
			var neighbor := get_focus_neighbor(sides[e.button_index])
			if not neighbor.is_empty():
				get_node(neighbor).grab_focus()
			else:
				var next := find_prev_valid_focus() if e.button_index in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_UP] else find_next_valid_focus()
				if next != null:
					next.grab_focus()
			accept_event()
			return
	var confirm: bool = e.is_action("ui_accept") or (e is InputEventJoypadButton and e.button_index == JOY_BUTTON_A)
	if enabled and confirm:
		if e.is_echo():
			accept_event()
			return
		if e.is_pressed():
			_down = true
		elif _down:
			_down = false
			_fire()
		accept_event()
		return
	if enabled and ((e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed)):
		grab_focus()
	super._gui_input(e)

func _process(delta: float) -> void:
	var animating := press_k > 0.0 or hover_k > 0.0
	super._process(delta)
	# Redraw the final resting frame as well.
	if animating:
		queue_redraw()

static func menu(text: String, st: int = Style.SECONDARY, ic: String = "") -> HomeButton:
	var b := HomeButton.new()
	b.label = text
	b.style = st
	b.icon = ic
	return b

func _draw() -> void:
	var k := ui_scale
	var r := Rect2(Vector2(0, press_k * 2.0), size - Vector2(0, 2))
	var primary := style in [Style.PRIMARY, Style.GOLD]
	var fill := GOLD if primary else Color("132332", 0.97)
	if style == Style.DANGER:
		fill = Color("542e35")
	if selected:
		fill = Color("182c3a").lerp(tint, 0.18)
	fill = fill.lightened(hover_k * 0.08)
	if not enabled:
		fill = Color("101923")
	var edge := tint if selected or primary else Color("405461", 0.65)
	draw_style_box(MenuStyle.box(fill, edge, 10), r)
	var col := Color("17202a") if primary else IVORY
	if not enabled:
		col = Color("8796a3")
	if card:
		_draw_card(r, col)
	elif navigation:
		UiIcons.draw(self, icon, Vector2(24, size.y / k * 0.5) * k, 11 * k, GOLD)
		MenuStyle.text(self, Vector2(48 * k, size.y * 0.5 + 5 * k), label, int(16 * k), col)
	elif icon != "" and label == "":
		UiIcons.draw(self, icon, size * 0.5, 12 * k, col)
	else:
		var tx := 0.0
		if icon != "":
			UiIcons.draw(self, icon, Vector2(26 * k, size.y * 0.5), 11 * k, col)
			tx = 24 * k
		MenuStyle.text(self, Vector2(tx, size.y * 0.5 + font_size * k * 0.34), label, int(font_size * k), col, 1, size.x - tx)
	if has_focus():
		draw_style_box(MenuStyle.box(Color.TRANSPARENT, IVORY, 8, 2), r.grow(-4))
	if badge > 0 or badge_text != "":
		draw_circle(Vector2(size.x - 12 * k, 12 * k), 8 * k, GOLD)
		MenuStyle.text(self, Vector2(size.x - 20 * k, 16 * k), str(badge) if badge > 0 else badge_text, int(11 * k), Color("101925"), 1, 16 * k)

func _draw_card(r: Rect2, col: Color) -> void:
	var ink := tint if enabled else Color("81929e")
	if art != null:
		var picture := Rect2(r.position + Vector2(3, 3), r.size - Vector2(6, 6))
		MenuStyle.cover(self, picture, art, Color(0.8, 0.85, 0.9, 0.55 if enabled else 0.14))
		MenuStyle.shade_left(self, picture, 0.96)
	if compact:
		UiIcons.draw(self, icon, Vector2(28, 28), 10, ink)
		MenuStyle.text(self, Vector2(48, 32), kicker, 11, ink)
		MenuStyle.text(self, Vector2(18, 68), label, 28, col, 0, size.x - 34)
		MenuStyle.text(self, Vector2(18, 93), footnote, 13, MenuStyle.DIM if enabled else ink, 0, size.x - 34)
	else:
		UiIcons.draw(self, icon, Vector2(30, 34), 12, ink)
		MenuStyle.text(self, Vector2(54, 38), kicker, 12, ink)
		MenuStyle.text(self, Vector2(20, 85), label, 30, col, 0, size.x - 40)
		MenuStyle.paragraph(self, Rect2(20, 102, size.x - 40, size.y - 166), description, 18)
		MenuStyle.text(self, Vector2(20, r.end.y - 20), footnote, 14, ink, 0, size.x - 40)
	if selected:
		draw_rect(Rect2(1, 12, 3, size.y - 24), ink)
		draw_style_box(MenuStyle.box(Color.TRANSPARENT, ink, 10, 2), r)
