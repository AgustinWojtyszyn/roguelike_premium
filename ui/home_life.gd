class_name HomeLife
extends Node2D
## Vida de fondo del HOME (estacion): personal de VIDA que camina y descansa, y props de interior/ciudad.
## Todo queda detras del heroe y de la UI, entintado con el color del capitulo. Barato: 2-4 sprites animados,
## y se detiene por completo (sin proceso) cuando una pantalla del menu lo tapa.

const NPC_IDS := ["tecnica", "armero", "mercader", "auxiliar"]

class Walker:
	var actor: SpriteActor
	var x0 := 0.0
	var x1 := 0.0
	var speed := 22.0
	var dir := 1.0
	var pause := 0.0
	var pose := ""
	var holder: Node2D


var walkers: Array[Walker] = []
var prop_nodes: Array[Sprite2D] = []
var accent := Color.WHITE
var vs := Vector2(1280, 720)
var floor_y := 450.0


func _ready() -> void:
	z_index = 0
	set_process(false)


func build(size: Vector2, hero_feet: Vector2, tint: Color) -> void:
	if not VisualProfiles.sprites_enabled() or not VisualProfiles.HOME_LIFE_ENABLED:
		return
	vs = size
	accent = tint
	floor_y = hero_feet.y + 6.0
	_clear()
	_build_props()
	_build_walkers()
	set_process(true)


func _clear() -> void:
	for c in get_children():
		c.queue_free()
	walkers.clear()
	prop_nodes.clear()


func set_active(on: bool) -> void:
	visible = on
	set_process(on and not walkers.is_empty())


func retint(tint: Color) -> void:
	accent = tint
	var base := Color(0.62, 0.66, 0.78).lerp(tint, 0.28)
	for sp in prop_nodes:
		sp.modulate = base
	for w in walkers:
		w.holder.modulate = Color(0.86, 0.9, 0.98).lerp(tint, 0.18)


func _build_props() -> void:
	for side in VisualProfiles.HOME_PROPS:
		for spec in VisualProfiles.HOME_PROPS[side]:
			var tex := AssetCatalog.tex(spec["art"])
			if tex == null:
				continue
			var sid: String = AssetManifest.ALIASES.get(spec["art"], spec["art"])
			var bb: Array = AssetManifest.STATIC.get(sid, {}).get("bbox", [0, 0, tex.get_width(), tex.get_height()])
			var bw := float(bb[2]) - float(bb[0])
			var bh := float(bb[3]) - float(bb[1])
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.region_enabled = true
			sp.region_rect = Rect2(float(bb[0]), float(bb[1]), bw, bh)
			sp.centered = false
			sp.offset = Vector2(-bw * 0.5, -bh)
			var sc := float(spec["h"]) * vs.y / bh
			sp.scale = Vector2(sc, sc)
			sp.position = Vector2(float(spec["x"]) * vs.x, floor_y - 6.0 + (4.0 if int(spec["x"] * 100.0) % 2 == 0 else 0.0))
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			add_child(sp)
			prop_nodes.append(sp)


func _build_walkers() -> void:
	var zones := [Vector2(0.04, 0.27), Vector2(0.74, 0.97)]
	var ids := NPC_IDS.duplicate()
	for zi in zones.size():
		for k in 1 + (1 if zi == 0 else 0):
			var nid: String = ids[(zi * 2 + k) % ids.size()]
			var prof: Dictionary = VisualProfiles.NPCS[nid].duplicate()
			var holder := Node2D.new()
			holder.position = Vector2(0, 0)
			add_child(holder)
			prof["height"] = float(prof["height"]) * vs.y / 720.0
			var a := SpriteActor.create(holder, prof)
			if a == null:
				holder.queue_free()
				continue
			a.self_modulate = prof.get("tint", Color.WHITE)
			var w := Walker.new()
			w.actor = a
			w.holder = holder
			w.x0 = zones[zi].x * vs.x
			w.x1 = zones[zi].y * vs.x
			w.speed = randf_range(18.0, 28.0) * vs.y / 720.0
			w.dir = 1.0 if randf() < 0.5 else -1.0
			holder.position = Vector2(randf_range(w.x0, w.x1), floor_y + 22.0 + float(k) * 14.0 - float(zi) * 4.0)
			w.pause = randf_range(0.0, 3.0)
			walkers.append(w)
			a.play("idle")
	retint(accent)


func _process(dt: float) -> void:
	for w in walkers:
		var a := w.actor
		if w.pause > 0.0:
			w.pause -= dt
			if w.pose == "":
				a.play("idle")
				a.set_dir_vec(Vector2(0, 1))
			a.tick(dt)
			if w.pause <= 0.0:
				w.pose = ""
				w.dir = -w.dir if randf() < 0.5 else w.dir
			continue
		var h := w.holder
		h.position.x += w.dir * w.speed * dt
		if h.position.x > w.x1:
			h.position.x = w.x1
			w.dir = -1.0
			_rest(w)
		elif h.position.x < w.x0:
			h.position.x = w.x0
			w.dir = 1.0
			_rest(w)
		elif randf() < dt * 0.05:
			_rest(w)
		a.play("walk")
		a.set_dir_vec(Vector2(w.dir, 0.0))
		a.tick(dt)


func _rest(w: Walker) -> void:
	w.pause = randf_range(2.5, 6.0)
	var poses := ["idle"]
	for p in ["phone", "drink"]:
		if w.actor.aset.has_anim(p):
			poses.append(p)
	w.pose = poses[randi() % poses.size()]
	w.actor.play(w.pose, true, true)
	w.actor.set_dir_vec(Vector2(0, 1))
