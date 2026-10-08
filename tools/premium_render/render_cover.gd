extends SceneTree
## Offline title artwork. Only the resulting PNG ships; no 3D nodes in Home.
const SOURCE := "res://asset_bank/vendor/kaykit_dungeon/addons/kaykit_dungeon_remastered/Assets/gltf/"
var world: Node3D
func _init() -> void:
	call_deferred("render")
func material(c: Color, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.82
	if glow > 0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return m
func box(p: Vector3, s: Vector3, c: Color, glow: float = 0.0) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = s
	n.mesh = mesh
	n.material_override = material(c, glow)
	world.add_child(n)
	n.position = p
	return n
func collect(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for child in n.get_children():
		collect(child, out)
func piece(id: String, p: Vector3, height: float, tint: Color) -> void:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	assert(doc.append_from_file(SOURCE + id + ".gltf.glb", state) == OK)
	var n := doc.generate_scene(state)
	world.add_child(n)
	var meshes: Array = []
	collect(n, meshes)
	var bounds := AABB()
	for m in meshes:
		bounds = bounds.merge(m.global_transform * m.get_aabb())
	var k := height / maxf(bounds.size.y, 0.01)
	n.scale = Vector3.ONE * k
	n.position = p - Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * k
	for m in meshes:
		for i in m.mesh.get_surface_count():
			var mat := m.get_active_material(i).duplicate() as StandardMaterial3D
			mat.albedo_color *= tint
			mat.roughness = 0.8
			m.set_surface_override_material(i, mat)
func arch_stone(a: float, b: float, z: float, col: Color) -> void:
	var points: Array[Vector3] = []
	for depth in [z - 0.55, z + 0.55]:
		for radius in [0.0, 0.65]:
			for angle in [a, b]:
				points.append(Vector3(cos(angle) * (4.3 + radius), 5.6 + sin(angle) * (3.0 + radius), depth))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for face in [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]:
		for corner in [0,1,2,0,2,3]:
			st.add_vertex(points[face[corner]])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := material(col)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	world.add_child(mi)
func lamp(p: Vector3, col: Color, energy: float, radius: float) -> void:
	var l := OmniLight3D.new()
	world.add_child(l)
	l.position = p
	l.light_color = col
	l.light_energy = energy
	l.omni_range = radius
	l.shadow_enabled = true
func render() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("070d18")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("758292")
	env.environment.ambient_light_energy = 0.32
	world.add_child(env)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 4.2, 16)
	cam.look_at(Vector3(0, 3.5, -10))
	cam.fov = 64
	# A stepped ceremonial passage with layered buttresses, a distant burning gate.
	box(Vector3(0,-0.3,-3), Vector3(30,0.5,38), Color("202b38"))
	for z in range(-16, 14, 2):
		for x in range(-12, 13, 2):
			box(Vector3(x, -0.015, z), Vector3(1.96,0.12,1.96), Color("34404b") if (x + z) % 4 == 0 else Color("293643"))
	box(Vector3(0,0.06,-2), Vector3(3.8,0.04,26), Color("381826"))
	for x in [-1.8, 1.8]:
		box(Vector3(x,0.09,-2), Vector3(0.045,0.01,26), Color("a3804b"))
	for z in [5, -1, -7, -13]:
		for side in [-1, 1]:
			var x: float = side * 5.0
			piece("pillar", Vector3(x,0,z), 7.2, Color("657386"))
			piece("banner_patternA_red", Vector3(x - side * 0.9,4.0,z+0.45), 3.2, Color("a27374"))
			piece("candle_triple", Vector3(x - side * 0.7,0,z+1), 1.0, Color("d6b38a"))
			lamp(Vector3(x - side * 1.0,1.7,z+1.0),Color("ffa65c"), 3.3, 5.5)
			box(Vector3(x,4,z-2.8), Vector3(1,8,5.2), Color("263140"))
		# Segmented arch, with a keystone and actual cast shadows.
		for i in 23:
			arch_stone(PI * float(i) / 23.0 + 0.004, PI * float(i + 1) / 23.0 - 0.004, z, Color("48576a") if i % 3 else Color("536175"))
	box(Vector3(0,3.4,-17),Vector3(9,6.8,1),Color("101c29"))
	box(Vector3(0,3,-16.4),Vector3(2.8,5.8,0.1),Color("bc7a3d"),1.0)
	for x in [-1.6,1.6]:
		piece("pillar",Vector3(x,0,-16),6.4,Color("8792a0"))
	lamp(Vector3(0,3,-14),Color("ffc278"),3.5,12)
	lamp(Vector3(1,7,4),Color("759bcc"),2.0,16)
	var sun := DirectionalLight3D.new()
	world.add_child(sun)
	sun.rotation_degrees = Vector3(-48,-28,0)
	sun.light_color = Color("90afcc")
	sun.light_energy = 0.38
	sun.shadow_enabled = true
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://assets/premium/presentation/fortress.png"
	assert(vp.get_texture().get_image().save_png(path) == OK)
	print("COVER rendered: ", path)
	quit()
