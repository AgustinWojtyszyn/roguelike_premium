extends SceneTree
## Renderizador determinista de piezas estaticas (props, suelo, muros) desde glb CC0 -> PNG 2D con la misma camara/luz que los personajes.
## Uso: godot --path . --rendering-driver opengl3 --script tools/premium_render/render_static.gd -- --job=<job.json> --out=<dir>
## Cada pieza se renderiza a escala fija (`ppu` px por unidad de mundo) con el origen del modelo en (cell/2, cell*feet_frac);
## el empaquetador recorta por caja alfa y guarda el ancla (origen) para colocarla sin offsets manuales.

var job: Dictionary
var vp: SubViewport
var cam: Camera3D
var sun: DirectionalLight3D


func _init() -> void:
	call_deferred("_run")


func _arg(key: String, d: String = "") -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return d


func _run() -> void:
	var jf := FileAccess.open(_arg("job"), FileAccess.READ)
	job = JSON.parse_string(jf.get_as_text())
	var out_dir := _arg("out", "/tmp/premium_static")
	DirAccess.make_dir_recursive_absolute(out_dir)
	RenderingServer.set_default_clear_color(Color.BLACK)
	var ss := int(job.get("ss", 1))
	var cell := int(job.get("cell", 384)) * ss
	vp = SubViewport.new()
	vp.size = Vector2i(cell, cell)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(vp)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	vp.add_child(cam)
	sun = DirectionalLight3D.new()
	vp.add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(job.get("ambient", "#9aa6c8"))
	env.ambient_light_energy = float(job.get("ambient_e", 0.85))
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	await process_frame
	var ppu := float(job["ppu"]) * float(ss)
	var meta := {}
	for it in job["items"]:
		var pitch: float = float(it.get("pitch", job.get("pitch", 35.0)))
		var feet: float = float(it.get("feet_frac", job.get("feet_frac", 0.80)))
		var ortho := float(cell) / ppu
		cam.size = ortho
		var basis := Basis(Vector3.RIGHT, -deg_to_rad(pitch))
		cam.transform = Transform3D(basis, basis * Vector3(0.0, (feet - 0.5) * ortho, 14.0))
		PremiumStyle.setup_light(sun, job.get("look", {}))
		var node: Node
		if it.has("build"):
			node = WeaponModels.build(String(it["build"]))
		else:
			var st := GLTFState.new()
			var doc := GLTFDocument.new()
			if doc.append_from_file(it["file"], st) != OK:
				push_error("no carga " + String(it["file"]))
				continue
			node = doc.generate_scene(st)
		vp.add_child(node)
		if job.get("style", true) and not it.get("raw", false):
			var ms: Array = []
			_collect(node, ms)
			PremiumStyle.apply(ms, job.get("look", {}).merged(it.get("look", {})))
		if node is Node3D:
			(node as Node3D).rotation_degrees = Vector3(0, float(it.get("yaw", 0.0)), 0)
			(node as Node3D).position = Vector3(float(it.get("dx", 0.0)), 0, float(it.get("dz", 0.0)))
		await process_frame
		await process_frame
		vp.get_texture().get_image().save_png(out_dir.path_join(String(it["id"]) + ".png"))
		var rec := {"anchor": [cell / 2, int(round(float(cell) * feet))], "pitch": pitch}
		if node.has_meta("points"):
			# puntos de la geometria (boca, mano libre...) proyectados con la camara, en px de render relativos al ancla
			var pts := {}
			for k in node.get_meta("points"):
				var pc := cam.global_transform.affine_inverse() * (node as Node3D).to_global(node.get_meta("points")[k])
				pts[k] = [snappedf(pc.x * ppu, 0.01), snappedf(-pc.y * ppu, 0.01)]
			rec["points"] = pts
		meta[it["id"]] = rec
		vp.remove_child(node)
		node.queue_free()
		await process_frame
	var f := FileAccess.open(out_dir.path_join("frames.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"cell": cell, "ppu": ppu, "ss": ss, "items": meta}))
	f.close()
	quit()


func _collect(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)
