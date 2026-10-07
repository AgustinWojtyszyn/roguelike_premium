extends Control
## Galeria de revision visual (no forma parte del juego): personajes, armas y enemigos.
## Uso: godot --path . tools/gallery.tscn -- --what=chars|weapons|enemies --snap=1.5 --snapdir=/tmp/g --exit=2

func _ready() -> void:
	var what := Boot.get_arg("what", "chars")
	var bg := ColorRect.new()
	bg.color = Color("141c30")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	match what:
		"weapons":
			_weapons()
		"enemies":
			_enemies()
		_:
			_chars()


func _chars() -> void:
	var ids: Array = Catalog.char_order
	var cols := 6
	for i in ids.size():
		var c: CharacterData = Catalog.characters[ids[i]]
		var rig := CharacterRig.new()
		add_child(rig)
		rig.build(c.look, Catalog.weapon(c.start_weapon), true)
		rig.auto = true
		rig.position = Vector2(110.0 + float(i % cols) * 205.0, 250.0 + float(i / cols) * 330.0)
		rig.scale = Vector2.ONE * 3.0
		var l := Label.new()
		l.text = c.display_name
		l.position = rig.position + Vector2(-60, 24)
		add_child(l)


func _weapons() -> void:
	var ids: Array = Catalog.weapons.keys()
	ids.sort()
	var cols := 6
	for i in ids.size():
		var w: WeaponData = Catalog.weapons[ids[i]]
		var n := Control.new()
		var holder := WeaponHolder.new()
		holder.w = w
		holder.position = Vector2(60.0 + float(i % cols) * 205.0, 100.0 + float(i / cols) * 190.0)
		holder.scale = Vector2.ONE * 2.2
		add_child(holder)
		var l := Label.new()
		l.text = w.display_name
		l.position = holder.position + Vector2(-20, 70)
		add_child(l)


class WeaponHolder extends Node2D:
	var w: WeaponData
	var t := 0.0
	func _process(d: float) -> void:
		t += d
		queue_redraw()
	func _draw() -> void:
		WeaponArt.paint(self, w, 0.3, t)


func _enemies() -> void:
	var ids: Array = Catalog.enemies.keys()
	ids.sort()
	var game_stub := Node2D.new()
	add_child(game_stub)
	var label := Label.new()
	label.text = "(los enemigos requieren Game; usa la escena de run con --chapter)"
	add_child(label)
