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
	pane.position = Vector2(24, HEADER_H + 18)
	pane.size = Vector2(size.x - 48, size.y - HEADER_H - 36)
	pane.content_len = 250 + ceilf(float(ITEMS.size() - 1) / 2.0) * 212

func _draw_list(p: ScrollPane) -> void:
	var hero := Rect2(2, 2, p.size.x - 4, 232)
	MenuStyle.cover(p, hero, MenuStyle.art("ch4"))
	MenuStyle.shade_left(p, hero)
	MenuStyle.text(p, Vector2(28, 38), "DESDE EL REFUGIO  /  TEMPORADA 01", 13, MenuStyle.GOLD)
	MenuStyle.text(p, Vector2(28, 101), ITEMS[0][0], 46, MenuStyle.TEXT)
	MenuStyle.paragraph(p, Rect2(28, 126, 610, 90), ITEMS[0][1], 21, MenuStyle.TEXT)
	var w := (p.size.x - 20) * 0.5
	for i in range(1, ITEMS.size()):
		var it: Array = ITEMS[i]
		var col: Color = it[3]
		var r := Rect2(2 + ((i - 1) % 2) * (w + 16), 250 + ((i - 1) / 2) * 212, w, 196)
		MenuStyle.panel(p, r, MenuStyle.PANEL, Color(col, 0.3))
		UiIcons.draw(p, it[2], r.position + Vector2(30, 34), 14, col)
		MenuStyle.text(p, r.position + Vector2(60, 42), it[0], 29, MenuStyle.TEXT, 0, w - 84)
		MenuStyle.paragraph(p, Rect2(r.position + Vector2(24, 70), Vector2(w - 48, 108)), it[1], 19)
