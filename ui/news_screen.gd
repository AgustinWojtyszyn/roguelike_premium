class_name NewsScreen
extends MenuScreen
## Novedades: notas de version y consejos. Contenido estatico local.

var pane: ScrollPane
const ITEMS := [
	["¡Bienvenido a Eclipse Corrupto!", "Temporada 1: 30 niveles de pase, skins y estelas. Juega gratis y desbloquea todo lo importante sin pagar.", "star", Color("c47bff")],
	["11 personajes con siluetas propias", "Cada héroe tiene habilidad y pasiva únicas: reflejar disparos, fases etéreas, torretas, tormentas eléctricas y más.", "person", Color("27e0cc")],
	["18 armas con mecánicas reales", "Ráfagas, minigun con arranque, rayos en cadena, rebotes, misiles teledirigidos, hoja de energía y haz de riel cargado.", "sword", Color("ff6a8a")],
	["Capítulo 1: Circuitos Corruptos", "Cinco etapas, salas distintas, élites, cofres y un jefe de tres fases. Los demás capítulos se irán abriendo.", "door", Color("5fffc8")],
	["Consejo: lee al enemigo", "No hay telegrafos en el suelo. Observa la postura, el brillo y las partículas: avisan antes de atacar.", "eye", Color("ffd24a")],
	["Consejo: los perks se acumulan", "Algunos perks se pueden repetir. Con 5 slots, elige combinaciones: crítico + perforante o escudo + reactiva.", "bolt", Color("6cc4ff")],
]


func _build() -> void:
	title = "NOVEDADES"
	accent = Color("6cc4ff")
	pane = ScrollPane.new()
	pane.draw_cb = _draw_list
	add_child(pane)


func _layout() -> void:
	var w := minf(980.0, size.x - 60.0)
	pane.position = Vector2((size.x - w) * 0.5, HEADER_H + 14.0)
	pane.size = Vector2(w, size.y - HEADER_H - 24.0)
	pane.content_len = float(ITEMS.size()) * 128.0 + 10.0


func _draw_list(p: ScrollPane) -> void:
	for i in ITEMS.size():
		var it: Array = ITEMS[i]
		var col: Color = it[3]
		var r := Rect2(4.0, 4.0 + float(i) * 128.0, p.size.x - 8.0, 116.0)
		UiKit.panel(p, r, Color("101a30"), Color(col, 0.6), 14.0)
		var ic := Vector2(r.position.x + 62.0, r.get_center().y)
		p.draw_circle(ic, 38.0, Color(col.darkened(0.6), 1.0))
		p.draw_arc(ic, 38.0, 0, TAU, 28, col, 3.0, true)
		UiIcons.draw(p, it[2], ic, 20.0, col.lightened(0.3))
		UiKit.text(p, Vector2(r.position.x + 128.0, r.position.y + 42.0), it[0], 26, UiKit.TEXT, 0, r.size.x - 150.0, 5.0)
		p.draw_multiline_string(UiKit.font_reg(), Vector2(r.position.x + 128.0, r.position.y + 70.0), it[1], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 150.0, 16, 3, Color(0.8, 0.9, 1.0, 0.9))
