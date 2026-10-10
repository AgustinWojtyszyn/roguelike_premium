extends RefCounted
## Capitulo 1 premium: sala compuesta "Linea de Montaje", suelo de cubierta original y props Quaternius con procedencia.

const DECK := ["deck_a", "deck_b", "deck_big", "deck_grate", "deck_hazard", "deck_stencil", "deck_vent", "deck_strip", "deck_scorch"]


func run(t) -> void:
	var def: RoomDef = Catalog.rooms.get("assembly_line")
	t.check(def != null, "assembly_line existe")
	if def == null:
		return
	var ch1 := Catalog.chapter("ch1")
	t.check(ch1.room_pool.has("assembly_line"), "ch1 incluye assembly_line")
	t.check(not ch1.room_pool.has("assembly_line_m"), "sala compuesta sin gemelo reverso")
	t.check(def.decor.get("composed", false), "sala marcada composed")
	# densidad: entre 15 y 25 props con colision, con cobertura destructible y solida
	var n: int = def.props.size()
	t.check(n >= 15 and n <= 25, "assembly_line tiene %d props (15-25)" % n)
	var destructible := 0
	var solid := 0
	for p in def.props:
		if str(p[0]) in ["crate_s", "barrel"]:
			destructible += 1
		else:
			solid += 1
	t.check(destructible >= 6, "al menos 6 objetos destructibles (%d)" % destructible)
	t.check(solid >= 8, "al menos 8 coberturas solidas (%d)" % solid)
	# el carril central (y en [-40, 40]) queda libre de huellas: nunca se bloquea entre entrada y salida
	var lane_blocked := false
	for p in def.props:
		var r := Rect2(float(p[1]), float(p[2]), float(p[3]), float(p[4]))
		if r.intersects(Rect2(-700, -40, 1400, 80)):
			lane_blocked = true
	t.check(not lane_blocked, "carril central libre")
	# zonas de suelo en coordenadas reales (no compactadas): fila de carril centrada en y=0
	var zones: Array = def.decor.get("deck_zones", [])
	t.check(zones.size() >= 2, "deck_zones definidas")
	var strip_ok := false
	for z in zones:
		if str(z["v"]) == "deck_strip" and (z["rect"] as Rect2).has_point(Vector2(0, 0)):
			strip_ok = true
	t.check(strip_ok, "fila deck_strip contiene el eje y=0")
	# arte: suelo + props con textura cargable y licencia comercial-compatible
	for id in DECK:
		t.check(AssetCatalog.tex("premium/dungeon/tech_floor/" + id) != null, "carga " + id)
	for k in ["crate_l", "crate_s", "barrel", "tank", "terminal", "pillar", "barrier_h"]:
		var pr := VisualProfiles.prop(k, "tech")
		t.check(not pr.is_empty() and pr["art"][0].begins_with("premium/dungeon/tech"), "perfil tech premium para " + k)
		for a in pr.get("art", []):
			t.check(AssetCatalog.tex(a) != null, "textura " + a)
			var lic := str(PremiumManifest.STATIC.get(a, {}).get("source", {}).get("license", ""))
			t.check(lic in ["CC0 1.0", "Original work (RPG Premium)"], "licencia verificada de " + a + " (" + lic + ")")
	# fallback: sin sprites el tema debe seguir pudiendo pintar (suelo vectorial) -> el perfil no es obligatorio
	t.check(VisualProfiles.prop("crate_l", "castle").is_empty() or VisualProfiles.prop("crate_l", "castle")["art"][0].begins_with("premium/dungeon/castle"), "otros temas no usan arte tech")
