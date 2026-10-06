class_name NavButton
extends GButton
## Boton de la barra de navegacion inferior del menu: icono arriba, etiqueta debajo, insignia de notificacion.

var accent := Color("27e0cc")


static func create(text: String, ic: String, acc: Color) -> NavButton:
	var b := NavButton.new()
	b.label = text
	b.icon = ic
	b.accent = acc
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	return b


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var top := Color("2a3f6a").lerp(accent, 0.25 if selected else 0.0)
	var bot := Color("111c38").lerp(accent.darkened(0.5), 0.35 if selected else 0.0)
	var body := UiKit.chunky(self, r, top, bot, press_k, hover_k, 12.0, 3.0)
	var cx := size.x * 0.5
	var iy := body.position.y + body.size.y * 0.38
	Gfx.draw_glow(self, Vector2(cx, iy), 30.0, Color(accent, 0.18 + 0.1 * hover_k))
	UiIcons.draw(self, icon, Vector2(cx, iy), 17.0, Color.WHITE, Color(0.03, 0.05, 0.1, 0.9))
	UiKit.text(self, Vector2(0, body.position.y + body.size.y - 11.0), label, 15, UiKit.TEXT, 1, size.x, 3.0)
	if badge > 0 or badge_text != "":
		var c := Vector2(size.x - 10.0, 10.0)
		var s := badge_text if badge_text != "" else (str(badge) if badge < 10 else "9+")
		var w := maxf(22.0, UiKit.text_width(s, 14) + 12.0)
		UiKit.pill(self, Rect2(c.x - w * 0.5 - 4.0, c.y - 11.0, w, 22.0), Color("ff4a5a"), UiKit.INK, 2.5)
		UiKit.text(self, Vector2(c.x - w * 0.5 - 4.0, c.y + 5.0), s, 14, Color.WHITE, 1, w)
