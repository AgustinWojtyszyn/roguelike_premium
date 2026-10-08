class_name HomeButton
extends GButton
## Restrained title-screen controls; inherits the existing touch/controller behavior.
var navigation := false
func _draw() -> void:
	var r := Rect2(Vector2(0, press_k * 2.0), size - Vector2(0, 2))
	var primary := style == Style.PRIMARY
	var gold := Color("c6a477")
	var fill := Color("a77b48") if primary else Color("101925", 0.88)
	fill = fill.lightened(hover_k * 0.12)
	draw_style_box(_panel(fill, gold if primary else Color("58616c", 0.65)), r)
	if primary:
		draw_line(Vector2(2, 2), Vector2(size.x-2, 2), Color("f1d5a3"), 1)
	var col := Color("fff0d3") if primary else Color("dadbd6")
	if navigation:
		UiIcons.draw(self, icon, Vector2(24, size.y * 0.5), 10, gold)
		UiKit.text(self, Vector2(44, size.y * 0.5 + 5), label, 13, col)
	elif icon != "":
		UiIcons.draw(self, icon, size * 0.5, 12, col)
	else:
		UiKit.text(self, Vector2(0, size.y * 0.5 + font_size * 0.34), label, font_size, col, 1, size.x)
	if badge > 0 or badge_text != "":
		draw_circle(Vector2(size.x-8, 8), 4, gold)
func _panel(fill: Color, edge: Color) -> StyleBoxFlat:
	var p := StyleBoxFlat.new()
	p.bg_color = fill
	p.border_color = edge
	p.set_border_width_all(1)
	return p
