extends Control
## Revision visual del vertical slice Premium (no forma parte del juego): un heroe con su arma real en 8 direcciones de apuntado.
## Uso: godot --path . --rendering-driver opengl3 tools/premium_review.tscn -- --char=vesper --state=idle|walk|attack|hurt|death
##        --zoom=3.5 --snap=1.0 --snapdir=/tmp/rev --exit=1.6 [--weapon=pulsar] [--only=0..7 (una direccion, ampliada)]

const AIMS := [90.0, 45.0, 0.0, -45.0, -90.0, -135.0, 180.0, 135.0]   # south, south-east, east, ... (y hacia abajo)

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("1b2238")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	if Boot.get_arg("page", "") != "":
		_page(Boot.get_arg("page"))
		return
	if Boot.get_arg("enemy", "") != "":
		_enemy_grid(Boot.get_arg("enemy"), float(Boot.get_arg("zoom", "2.2")))
		return
	var cid := Boot.get_arg("char", "vesper")
	var state := Boot.get_arg("state", "idle")
	var zoom := float(Boot.get_arg("zoom", "3.2"))
	var c: CharacterData = Catalog.characters[cid]
	var wid := Boot.get_arg("weapon", c.start_weapon)
	var only := int(Boot.get_arg("only", "-1"))
	for i in 8:
		if only >= 0 and i != only:
			continue
		var rig := CharacterRig.new()
		add_child(rig)
		rig.build(c.look, Catalog.weapon(wid), true)
		var a: float = deg_to_rad(float(AIMS[i]))
		rig.aim = Vector2.from_angle(a)
		rig.face = 1.0 if cos(a) >= 0.0 else -1.0
		if state == "walk":
			rig.vel = rig.aim * 240.0
		rig.position = Vector2(110.0 + float(i % 4) * 300.0, 260.0 + float(i / 4) * 330.0)
		if only >= 0:
			rig.position = Vector2(640, 600)
		rig.scale = Vector2.ONE * zoom
		rig.animate(0.016)
		_drive(rig, state)
		var l := Label.new()
		l.text = "%s %d°" % [state, int(AIMS[i])]
		l.position = rig.position + Vector2(-40, 20)
		add_child(l)


func _drive(rig: CharacterRig, state: String) -> void:
	var t := float(Boot.get_arg("t", "0.25"))
	match state:
		"attack":
			rig.swing = 1.0
			rig.animate(0.016)
			rig.animate(t)
		"hurt":
			rig.flash = 1.0
			rig.animate(0.016)
			rig.animate(t * 0.4)
		"death":
			rig.start_death(rig.aim)
			rig.update_dead(t * 2.0)
		_:
			for k in 6:
				rig.animate(t / 6.0)


## Rejilla de un enemigo: filas = fases logicas (idle, move, windup, strike, recover, death), columnas = las 5 direcciones del set.
func _enemy_grid(kind: String, zoom: float) -> void:
	var prof := VisualProfiles.enemy(kind)
	var phases := ["idle", "move", "windup", "strike", "recover", "death"]
	var dirs := ["south", "south-east", "east", "north-east", "north"]
	for r in phases.size():
		for c in dirs.size():
			var holder := Node2D.new()
			holder.position = Vector2(110.0 + float(c) * 240.0, 120.0 + float(r) * 112.0)
			holder.scale = Vector2.ONE * zoom
			add_child(holder)
			var a := SpriteActor.create(holder, prof)
			if a == null:
				continue
			a.play(phases[r], true, false)
			a.dir = dirs[c]
			a.set_progress(0.55)


# ----------------------------------------------------------------------------------------------------------------- lamina de calidad
## `--page=heroes|weapons|enemies` (usar --resolution 1920x1080): la lamina que decide si el arte esta a la altura de una captura de tienda.
## heroes: Vesper (SMG a dos manos, pistola a una mano) y Sable en idle/walk/attack en 8 direcciones.
## weapons: cada arma del slice sostenida en 4 direcciones, ampliada (agarre, mano libre, muzzle).
## enemies: los 4 enemigos Premium en todas sus fases.
const DIR_LABELS := ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]


func _label(txt: String, pos: Vector2, size: int = 14) -> void:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.modulate = Color(1, 1, 1, 0.75)
	add_child(l)


func _hero(cid: String, wid: String, state: String, aim_deg: float, pos: Vector2, zoom: float, t: float = 0.25, marks: bool = false) -> CharacterRig:
	var c: CharacterData = Catalog.characters[cid]
	var rig := CharacterRig.new()
	add_child(rig)
	rig.build(c.look, Catalog.weapon(wid), true)
	var a := deg_to_rad(aim_deg)
	rig.aim = Vector2.from_angle(a)
	rig.face = 1.0 if cos(a) >= 0.0 else -1.0
	if state == "walk":
		rig.vel = rig.aim * 240.0
	rig.position = pos
	rig.scale = Vector2.ONE * zoom
	rig.animate(0.016)
	_drive(rig, state)
	if marks:
		var m := ColorRect.new()
		m.color = Color(1, 0.2, 0.2)
		m.size = Vector2(3, 3)
		m.position = rig.muzzle_world() - Vector2(1.5, 1.5)
		add_child(m)
	return rig


func _page(page: String) -> void:
	var W := get_viewport_rect().size.x
	match page:
		"heroes":
			var rows := [["vesper", "pulsar", "idle", "Vesper · PULSAR (2 manos) · idle"], ["vesper", "chispa", "walk", "Vesper · CHISPA (1 mano) · walk"],
				["sable", "filo_z", "idle", "Sable · FILO-Z · idle"], ["sable", "filo_z", "attack", "Sable · FILO-Z · attack"]]
			var cw := W / 8.0
			for r in rows.size():
				_label(rows[r][3], Vector2(10, 2 + r * 172))
				for i in 8:
					var deg: float = [90.0, 45.0, 0.0, -45.0, -90.0, -135.0, 180.0, 135.0][i]
					_hero(rows[r][0], rows[r][1], rows[r][2], deg, Vector2(cw * (float(i) + 0.5), 152.0 + r * 172.0), 1.75, 0.12 if rows[r][2] == "attack" else 0.25)
					if r == 0:
						_label(DIR_LABELS[i] + " (%d°)" % int(deg), Vector2(cw * (float(i) + 0.5) - 30, 4 + 172 * 4))
		"weapons":
			var ws := ["pulsar", "chispa", "trinca", "maul12", "filo_z"]
			for r in ws.size():
				var cid := "sable" if ws[r] == "filo_z" else "vesper"
				_label(ws[r].to_upper(), Vector2(10, 2 + r * 142))
				for i in 4:
					var deg: float = [0.0, 45.0, -45.0, 180.0][i]
					_hero(cid, ws[r], "idle", deg, Vector2(W / 4.0 * (float(i) + 0.5), 122.0 + r * 142.0), 2.3, 0.25, true)
		"enemies":
			var kinds := ["caballero", "ballestero", "sabueso", "escarabajo"]
			var phases := ["idle", "move", "windup", "strike", "recover", "death"]
			for k in kinds.size():
				var prof := VisualProfiles.enemy(kinds[k])
				_label(kinds[k].to_upper(), Vector2(10, 2 + k * 178))
				for p in phases.size():
					for d in 3:
						var holder := Node2D.new()
						holder.position = Vector2(36.0 + (float(p) * 3.0 + float(d)) * 70.0, 110.0 + k * 178.0)
						holder.scale = Vector2.ONE * 1.05
						add_child(holder)
						var a := SpriteActor.create(holder, prof)
						if a == null:
							continue
						a.play(phases[p], true, false)
						a.dir = ["south", "east", "north"][d]
						a.set_progress(0.5)
					if k == 0:
						_label(phases[p], Vector2(40.0 + float(p) * 205.0, 0))
