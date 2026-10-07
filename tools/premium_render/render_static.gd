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
	var cell := int(job.get("cell", 384))
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
	sun.light_energy = float(job.get("sun", 1.15))
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(job.get("ambient", "#9aa6c8"))
	env.ambient_light_energy = float(job.get("ambient_e", 0.85))
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	await process_frame
	var ppu := float(job["ppu"])
	var meta := {}
	for it in job["items"]:
		var pitch: float = float(it.get("pitch", job.get("pitch", 35.0)))
		var feet: float = float(it.get("feet_frac", job.get("feet_frac", 0.80)))
		var ortho := float(cell) / ppu
		cam.size = ortho
		var basis := Basis(Vector3.RIGHT, -deg_to_rad(pitch))
		cam.transform = Transform3D(basis, basis * Vector3(0.0, (feet - 0.5) * ortho, 14.0))
		sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
		var st := GLTFState.new()
		var doc := GLTFDocument.new()
		if doc.append_from_file(it["file"], st) != OK:
			push_error("no carga " + String(it["file"]))
			continue
		var node: Node = doc.generate_scene(st)
		vp.add_child(node)
		if node is Node3D:
			(node as Node3D).rotation_degrees = Vector3(0, float(it.get("yaw", 0.0)), 0)
			(node as Node3D).position = Vector3(float(it.get("dx", 0.0)), 0, float(it.get("dz", 0.0)))
		await process_frame
		await process_frame
		vp.get_texture().get_image().save_png(out_dir.path_join(String(it["id"]) + ".png"))
		meta[it["id"]] = {"anchor": [cell / 2, int(round(float(cell) * feet))], "pitch": pitch}
		vp.remove_child(node)
		node.queue_free()
		await process_frame
	var f := FileAccess.open(out_dir.path_join("frames.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"cell": cell, "ppu": ppu, "items": meta}))
	f.close()
	quit()
