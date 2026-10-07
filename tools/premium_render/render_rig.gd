extends SceneTree
## Renderizador determinista rig 3D -> frames 2D (fuente: glb de KayKit/Quaternius; runtime sigue siendo 2D).
## No hay Blender en el entorno: Godot (modo compatibilidad/GL) es el motor de render y el rig fuente es la unica
## fuente de verdad para agarre (hueso handslot), ejes del arma y mano libre.
##
## Uso:  godot --path . --rendering-driver opengl3 --script tools/premium_render/render_rig.gd -- --job=<job.json> --out=<dir>
## Salida: <out>/<anim>/<dir>_<i>.png (frames a `ss`x), <anim>/<dir>_<i>_hand.png (capa de manos, opcional) y <out>/frames.json
## con el agarre por frame ya en pixeles de celda (origen = punto de los pies en el centro de la celda).

const DIRS := {
	"south": 0.0, "south-east": 45.0, "east": 90.0, "north-east": 135.0,
	"north": 180.0, "north-west": -135.0, "west": -90.0, "south-west": -45.0,
}

const ID_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 hand_a = vec3(0.0, -50.0, 0.0);
uniform vec3 hand_b = vec3(0.0, -50.0, 0.0);
uniform float radius = 0.17;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float d = min(distance(wpos, hand_a), distance(wpos, hand_b));
	ALBEDO = vec3(step(d, radius));
}
"""

var job: Dictionary
var out_dir := ""
var vp: SubViewport
var cam: Camera3D
var root3d: Node3D
var skel: Skeleton3D
var bone_names: Array = []
var upper_idx := {}
var hand_idx := -1
var hand2_idx := -1
var elbow_idx := -1
var hips_idx := -1
var id_mat: ShaderMaterial
var meshes: Array[MeshInstance3D] = []
var cell := 160
var ss := 2
var ppu := 50.0   # px por unidad de mundo, a resolucion final de celda


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
	out_dir = _arg("out", "/tmp/premium_render")
	DirAccess.make_dir_recursive_absolute(out_dir)
	RenderingServer.set_default_clear_color(Color.BLACK)
	cell = int(job.get("cell", 160))
	ss = int(job.get("ss", 2))
	await _setup()
	if _arg("list") != "":
		_print_info()
		quit()
		return
	var frames_meta := {}
	var anims: Dictionary = job["anims"]
	var dirs: Array = job.get("dirs", DIRS.keys())
	for an in anims:
		var spec: Dictionary = anims[an]
		var adirs: Array = spec.get("dirs", dirs)
		frames_meta[an] = {}
		for d in adirs:
			frames_meta[an][d] = await _render_anim(an, spec, d)
		print("rendered ", an)
	var meta := {"cell": cell, "ppu": ppu, "pitch": job.get("pitch", 35.0), "feet": [cell / 2, _feet_y()], "anims": frames_meta}
	var f := FileAccess.open(out_dir.path_join("frames.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(meta))
	f.close()
	quit()


func _feet_y() -> float:
	return float(cell) * float(job.get("feet_frac", 0.80))


func _setup() -> void:
	var st := GLTFState.new()
	var doc := GLTFDocument.new()
	var err := doc.append_from_file(job["source"], st)
	assert(err == OK)
	root3d = doc.generate_scene(st)
	vp = SubViewport.new()
	vp.size = Vector2i(cell * ss, cell * ss)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(vp)
	vp.add_child(root3d)
	skel = _find_skel(root3d)
	for i in skel.get_bone_count():
		bone_names.append(skel.get_bone_name(i))
	hand_idx = maxi(0, _bone(str(job.get("hand", "handslot.r"))))
	hand2_idx = maxi(0, _bone(str(job.get("hand2", "handslot.l"))))
	hips_idx = maxi(0, _bone("hips"))
	elbow_idx = hand_idx
	for _k in 3:
		if skel.get_bone_parent(elbow_idx) >= 0:
			elbow_idx = skel.get_bone_parent(elbow_idx)
	var up_root := _bone(str(job.get("upper_root", "spine")))
	for i in skel.get_bone_count():
		var p := i
		while p >= 0:
			if p == up_root:
				upper_idx[i] = true
				break
			p = skel.get_bone_parent(p)
	# accesorios de la fuente (armas/escudos de enemigos) montados en el socket del rig: misma convencion de handslot que KayKit
	var ai := 0
	for a in job.get("attach", []):
		var ba := BoneAttachment3D.new()
		ba.name = "attach_%d" % ai
		ai += 1
		skel.add_child(ba)
		ba.bone_name = String(a["bone"])
		var st2 := GLTFState.new()
		var d2 := GLTFDocument.new()
		assert(d2.append_from_file(a["file"], st2) == OK)
		ba.add_child(d2.generate_scene(st2))
	_collect_meshes(root3d)
	# accesorios del glb (armas/escudos/etc. colgados de handslot_*): fuera, el arma la dibuja Premium
	var show: Array = job.get("show", [])
	for m in meshes:
		var hidden := false
		var p: Node = m.get_parent()
		while p != null and p != root3d:
			if p is BoneAttachment3D and String(p.name).begins_with("handslot"):
				hidden = true
			p = p.get_parent()
		for h in job.get("hide", []):
			if String(m.name) == String(h):
				hidden = true
		if show.has(String(m.name)):
			hidden = false
		m.visible = not hidden
	if job.get("fix_materials", false):
		# Quaternius exporta materiales metalicos: con luz de relleno plana salen casi negros. Se normalizan (no es un retoque artistico).
		for m in meshes:
			for si in m.mesh.get_surface_count():
				var mat := m.get_active_material(si)
				if mat is StandardMaterial3D:
					var mm := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
					mm.metallic = 0.0
					mm.roughness = float(job.get("roughness", 0.85))
					mm.albedo_color = mm.albedo_color * float(job.get("albedo_mul", 1.0))
					m.set_surface_override_material(si, mm)
	id_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = ID_SHADER
	id_mat.shader = sh
	# camara ortografica 3/4 fija
	var ortho := float(job.get("ortho", 3.0))
	ppu = float(cell) / ortho
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ortho
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	vp.add_child(cam)
	var pitch := deg_to_rad(float(job.get("pitch", 35.0)))
	var basis := Basis(Vector3.RIGHT, -pitch)
	# el origen del mundo (pies) cae en (cell/2, feet_y): desplazo la camara en su plano
	var fy := _feet_y() / float(cell)
	var up_shift := (fy - 0.5) * ortho
	cam.transform = Transform3D(basis, basis * Vector3(0.0, up_shift, 12.0))
	var sun := DirectionalLight3D.new()
	vp.add_child(sun)
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.light_energy = float(job.get("sun", 1.15))
	sun.shadow_enabled = false
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(job.get("ambient", "#9aa6c8"))
	env.ambient_light_energy = float(job.get("ambient_e", 0.85))
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	await process_frame
	await process_frame


func _bone(n: String) -> int:
	var i := skel.find_bone(n)
	if i < 0:
		i = skel.find_bone(n.replace(".", "_"))
	return i


func _find_skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _find_skel(c)
		if r != null:
			return r
	return null


func _collect_meshes(n: Node) -> void:
	if n is MeshInstance3D:
		meshes.append(n)
	for c in n.get_children():
		_collect_meshes(c)


func _print_info() -> void:
	print("BONES: ", bone_names)
	var ap := _find_ap(root3d)
	print("ANIMS: ", ap.get_animation_list())
	for a in ap.get_animation_list():
		print("  ", a, " len=", ap.get_animation(a).length)
	for m in meshes:
		print("MESH ", m.name, " vis=", m.visible)


func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_ap(c)
		if r != null:
			return r
	return null


# ---------------------------------------------------------------- pose por muestreo directo de pistas (determinista, sin AnimationPlayer)
func _sample(anim_name: String, t: float) -> Dictionary:
	var anim := _find_ap(root3d).get_animation(anim_name)
	var out := {}
	for ti in anim.get_track_count():
		var path := anim.track_get_path(ti)
		var bn := String(path.get_subname(0)) if path.get_subname_count() > 0 else ""
		var bi := _bone(bn)
		if bi < 0:
			continue
		var d: Dictionary = out.get(bi, {})
		match anim.track_get_type(ti):
			Animation.TYPE_POSITION_3D:
				d["p"] = anim.position_track_interpolate(ti, t)
			Animation.TYPE_ROTATION_3D:
				d["r"] = anim.rotation_track_interpolate(ti, t)
			Animation.TYPE_SCALE_3D:
				d["s"] = anim.scale_track_interpolate(ti, t)
		out[bi] = d
	return out


func _apply_pose(lower_pose: Dictionary, upper_pose: Dictionary) -> void:
	skel.reset_bone_poses()
	for bi in lower_pose:
		if upper_idx.has(bi):
			continue
		_set_bone(bi, lower_pose[bi])
	for bi in upper_pose:
		if upper_idx.has(bi):
			_set_bone(bi, upper_pose[bi])
	skel.force_update_all_bone_transforms()


func _set_bone(bi: int, d: Dictionary) -> void:
	if d.has("p"):
		skel.set_bone_pose_position(bi, d["p"])
	if d.has("r"):
		skel.set_bone_pose_rotation(bi, d["r"])
	if d.has("s"):
		skel.set_bone_pose_scale(bi, d["s"])


## Desplaza el modelo en el plano de la camara hasta que su silueta renderizada (caja alfa) quede dentro de la celda.
## Solo se usa en animaciones donde el cuerpo se desplaza mucho (muerte): el resto conserva el origen de los pies fijo.
func _fit_in_cell() -> void:
	var W := float(cell * ss)
	var pad := 3.0 * float(ss)
	var step := W * 0.06
	var k := 1.0 / (ppu * float(ss))
	for _it in 12:
		await process_frame
		await process_frame
		var r := vp.get_texture().get_image().get_used_rect()
		if r.size.x <= 0:
			return
		var dx := 0.0
		var dy := 0.0
		var tl := float(r.position.x) < pad
		var tr := float(r.end.x) > W - pad
		var tt := float(r.position.y) < pad
		var tb := float(r.end.y) > W - pad
		if tl and not tr:
			dx = step
		elif tr and not tl:
			dx = -step
		if tt and not tb:
			dy = step
		elif tb and not tt:
			dy = -step
		if dx == 0.0 and dy == 0.0:
			return
		root3d.position += cam.global_transform.basis.x * (dx * k) + cam.global_transform.basis.y * (-dy * k)
		skel.force_update_all_bone_transforms()


func _project(p: Vector3) -> Vector2:
	var pc := cam.global_transform.affine_inverse() * p
	var cx := float(cell) * 0.5 + pc.x * ppu
	var cy := float(cell) * 0.5 - pc.y * ppu
	return Vector2(cx - float(cell) * 0.5, cy - _feet_y())   # relativo a los pies (px de celda)


func _render_anim(an: String, spec: Dictionary, dir_name: String) -> Array:
	var n := int(spec["frames"])
	var lower_name: String = spec.get("lower", spec.get("upper"))
	var upper_name: String = spec.get("upper", lower_name)
	var ap := _find_ap(root3d)
	var llen := ap.get_animation(lower_name).length
	var ulen := ap.get_animation(upper_name).length
	var loop: bool = spec.get("loop", true)
	var t0: float = float(spec.get("t0", 0.0))
	var t1: float = float(spec.get("t1", 1.0))
	var hand_layer: bool = spec.get("hand_layer", job.get("hand_layer", false))
	var meta: Array = []
	root3d.rotation_degrees = Vector3(0, float(DIRS[dir_name]) + float(job.get("yaw_offset", 0.0)), 0)
	DirAccess.make_dir_recursive_absolute(out_dir.path_join(an))
	var ref_h := Vector3.ZERO
	var recenter := float(spec.get("recenter", 0.0))
	for i in n:
		var k: float
		if loop:
			k = lerpf(t0, t1, float(i) / float(n))
		else:
			k = lerpf(t0, t1, float(i) / float(maxi(1, n - 1)))
		var lt := clampf(k * llen, 0.0, llen)
		var ut := clampf(k * ulen, 0.0, ulen)
		if spec.has("upper_hold"):
			ut = float(spec["upper_hold"]) * ulen
		root3d.position = Vector3.ZERO
		_apply_pose(_sample(lower_name, lt), _sample(upper_name, ut))
		if recenter > 0.0:
			# anula parte del desplazamiento de raiz (p. ej. la caida hacia atras de la muerte) para que el cuerpo quede en la celda
			var h := (skel.global_transform * skel.get_bone_global_pose(hips_idx)).origin
			if i == 0:
				ref_h = h
			root3d.position = Vector3(-(h.x - ref_h.x), 0.0, -(h.z - ref_h.z)) * recenter
			skel.force_update_all_bone_transforms()
		if spec.get("fit_cell", false):
			await _fit_in_cell()
		await process_frame
		await process_frame
		for m in meshes:
			m.material_override = null
		var img := vp.get_texture().get_image()
		img.save_png(out_dir.path_join("%s/%s_%d.png" % [an, dir_name, i]))
		# metadatos de agarre desde el hueso fuente
		var hb := skel.global_transform * skel.get_bone_global_pose(hand_idx)
		var hb2 := skel.global_transform * skel.get_bone_global_pose(hand2_idx)
		var rec := {
			"grip": _v(_project(hb.origin)),
			"grip_l": _v(_project(hb2.origin)),
			"ax": _v(_project(hb.origin + hb.basis.x.normalized() * 0.5) - _project(hb.origin)),
			"ay": _v(_project(hb.origin + hb.basis.y.normalized() * 0.5) - _project(hb.origin)),
			"az": _v(_project(hb.origin + hb.basis.z.normalized() * 0.5) - _project(hb.origin)),
			"fore": _v(_project(hb.origin) - _project((skel.global_transform * skel.get_bone_global_pose(elbow_idx)).origin)),
			"depth_z": snappedf((cam.global_transform.affine_inverse() * hb.origin).z, 0.001),
			"behind": (cam.global_transform.affine_inverse() * hb.origin).z < (cam.global_transform.affine_inverse() * (skel.global_transform * skel.get_bone_global_pose(hips_idx)).origin).z - 0.04,
		}
		meta.append(rec)
		if hand_layer:
			for m in meshes:
				m.material_override = id_mat
			id_mat.set_shader_parameter("hand_a", hb.origin)
			id_mat.set_shader_parameter("hand_b", hb2.origin if spec.get("both_hands", false) else Vector3(0, -50, 0))
			id_mat.set_shader_parameter("radius", float(job.get("hand_radius", 0.17)))
			vp.transparent_bg = false
			await process_frame
			await process_frame
			vp.get_texture().get_image().save_png(out_dir.path_join("%s/%s_%d_mask.png" % [an, dir_name, i]))
			vp.transparent_bg = true
			for m in meshes:
				m.material_override = null
	return meta


func _v(v: Vector2) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01)]
