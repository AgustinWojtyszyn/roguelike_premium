extends SceneTree
## Sonda: carga un glb en runtime, lista huesos/animaciones y renderiza un frame. godot --path . --script tools/premium_render/probe.gd -- <glb> <out.png>
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var st := GLTFState.new()
	var doc := GLTFDocument.new()
	var err := doc.append_from_file(a[0], st)
	print("load err ", err)
	var root: Node = doc.generate_scene(st)
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 256)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(vp)
	vp.add_child(root)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 3.0
	vp.add_child(cam)
	cam.position = Vector3(0, 2.2, 3.2)
	cam.look_at(Vector3(0, 0.9, 0))
	var l := DirectionalLight3D.new()
	vp.add_child(l)
	l.rotation_degrees = Vector3(-50, -30, 0)
	var ap := _find(root, "AnimationPlayer") as AnimationPlayer
	print(ap.get_animation_list().size(), " anims")
	ap.play("Idle")
	await process_frame
	await process_frame
	await process_frame
	var img := vp.get_texture().get_image()
	print("img ", img.get_size(), " px(128,128)=", img.get_pixel(128, 128))
	img.save_png(a[1])
	quit()

func _find(n: Node, cls: String) -> Node:
	if n.get_class() == cls:
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r:
			return r
	return null
