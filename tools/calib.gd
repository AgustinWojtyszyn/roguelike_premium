extends Control
## Calibracion visual de personajes importados: 8 direcciones con rejilla en pixeles de juego (1 marca = 10 px, origen = pies).
## Uso: godot --path . tools/calib.tscn -- --char=vesper --weapon=pulsar --pose=idle|walk --snap=1 --snapdir=/tmp/c --exit=1.5
const DIRS := ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("20283c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var cid := Boot.get_arg("char", "vesper")
	var c: CharacterData = Catalog.characters[cid]
	var wid := Boot.get_arg("weapon", c.start_weapon)
	var sc := float(Boot.get_arg("scale", "3.0"))
	var walk := Boot.get_arg("pose", "idle") == "walk"
	for i in 8:
		var d: String = DIRS[i]
		var aim: Vector2 = AnimSet.DIR_VEC[d]
		var host := Node2D.new()
		host.position = Vector2(170.0 + float(i % 4) * 310.0, 330.0 + float(i / 4) * 340.0)
		host.scale = Vector2.ONE * sc
		add_child(host)
		host.add_child(Grid.new())
		var rig := CharacterRig.new()
		host.add_child(rig)
		rig.build(c.look, Catalog.weapon(wid), true)
		rig.aim = aim
		rig.face = 1.0 if aim.x >= 0.0 else -1.0
		rig.vel = aim * 200.0 if walk else Vector2.ZERO
		for k in 12 + i:
			rig.animate(1.0 / 60.0)
		var l := Label.new()
		l.text = d
		l.position = host.position + Vector2(-40, 20)
		add_child(l)


class Grid extends Node2D:
	func _draw() -> void:
		for k in range(-6, 8):
			var x := float(k) * 10.0
			draw_line(Vector2(x, -75), Vector2(x, 5), Color(1, 1, 1, 0.12 if k % 5 else 0.3), 0.3)
		for k in range(0, 9):
			var y := -float(k) * 10.0
			draw_line(Vector2(-60, y), Vector2(70, y), Color(1, 1, 1, 0.12 if k % 5 else 0.3), 0.3)
			if k % 2 == 0:
				draw_string(ThemeDB.fallback_font, Vector2(-72, y + 2), str(-k * 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(1, 1, 0.6))
