extends Control
## Lamina de revision del plantel real: los 18 enemigos + 4 jefes en idle / anticipacion / golpe / dano / muerte, con el perfil de runtime.
## Uso: godot --path . --rendering-driver opengl3 tools/roster_review.tscn -- --out=/tmp/roster.png

const PHASES := ["idle", "windup", "strike", "hurt", "death"]
const FRAC := {"idle": 0.0, "windup": 0.85, "strike": 0.5, "hurt": 0.4, "death": 0.7}


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("1b2238")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var kinds: Array = Catalog.enemies.keys() + Catalog.bosses.keys()
	var cols := PHASES.size()
	for i in kinds.size():
		var kind: String = kinds[i]
		var prof := VisualProfiles.enemy(kind)
		var row := i % 11
		var xo := float(i / 11) * 840.0
		var lbl := Label.new()
		lbl.text = kind
		lbl.position = Vector2(8.0 + xo, 40.0 + float(row) * 90.0)
		lbl.add_theme_font_size_override("font_size", 12)
		add_child(lbl)
		for c in cols:
			var holder := Node2D.new()
			holder.position = Vector2(xo + 150.0 + float(c) * 150.0, 100.0 + float(row) * 90.0)
			holder.scale = Vector2.ONE * 0.55
			add_child(holder)
			var a := SpriteActor.create(holder, prof)
			if a == null:
				push_error("ART_MISSING " + kind)
				continue
			a.play(PHASES[c], true, false)
			a.set_progress(FRAC[PHASES[c]])
	var out := Boot.get_arg("out", "/tmp/roster.png")
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()
