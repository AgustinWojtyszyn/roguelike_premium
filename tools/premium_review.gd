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
