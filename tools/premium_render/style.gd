class_name PremiumStyle
extends RefCounted
## Identidad visual de RPG Premium aplicada en el render 3D->2D: materiales toon con sombra teñida, luz calida de llave,
## luz de borde fria, gradiente de suelo y emision conservada. Una sola paleta para heroes, enemigos, armas, props y dungeon.
## KayKit/Quaternius solo aportan geometria y texturas base: el sombreado y el color final son nuestros.

const SHADER := """
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_back;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_col : source_color = vec4(1.0);
uniform bool has_tex = false;
uniform bool use_vcol = false;
uniform vec3 emission_col : source_color = vec3(0.0);
uniform float emission_e = 0.0;
uniform vec3 shade_col : source_color = vec3(0.20, 0.19, 0.40);
uniform vec3 sun_col : source_color = vec3(1.0, 0.90, 0.76);
uniform vec3 rim_col : source_color = vec3(0.35, 0.78, 1.0);
uniform vec3 rim_dir = vec3(0.55, 0.30, -0.78);
uniform float rim_i = 0.55;
uniform float amb_i = 0.26;
uniform vec3 sky_col : source_color = vec3(0.62, 0.66, 0.95);
uniform vec3 gnd_col : source_color = vec3(0.34, 0.26, 0.40);
uniform float ground_dark = 0.45;
uniform vec3 hsv = vec3(0.0, 1.0, 1.0);
uniform vec2 vsel = vec2(0.0, 1.0);   // idem por valor (separa pelo oscuro de piel clara dentro de una misma malla)
uniform vec2 sel = vec2(0.0, 1.0);   // solo se tiñe el rango de matiz [x, y] (p. ej. el verde de la tunica, no la piel)
uniform float sat = 0.80;
uniform float val = 0.86;
varying vec3 wpos;
varying vec3 wnrm;
vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec4 t = albedo_col;
	if (has_tex) { t *= texture(albedo_tex, UV); }
	if (use_vcol) { t *= COLOR; }
	vec3 hh = rgb2hsv(t.rgb);
	float w = step(sel.x, hh.x) * step(hh.x, sel.y) * step(vsel.x, hh.z) * step(hh.z, vsel.y);
	hh.x = fract(hh.x + hsv.x * w);
	hh.y = clamp(hh.y * mix(1.0, hsv.y, w), 0.0, 1.0);
	hh.z = clamp(hh.z * mix(1.0, hsv.z, w), 0.0, 1.0);
	t.rgb = hsv2rgb(hh);
	float l = dot(t.rgb, vec3(0.299, 0.587, 0.114));
	vec3 c = mix(vec3(l), t.rgb, sat) * val;
	float g = mix(1.0 - ground_dark, 1.0, smoothstep(0.0, 0.85, wpos.y));
	ALBEDO = c * g;
	float rim = pow(clamp(dot(wnrm, normalize(rim_dir)), 0.0, 1.0), 1.6);
	EMISSION = rim_col * rim * rim_i * g + c * g * mix(gnd_col, sky_col, wnrm.y * 0.5 + 0.5) * amb_i + emission_col * emission_e;
}
void light() {
	float ndl = dot(NORMAL, LIGHT);
	float b = smoothstep(-0.10, 0.18, ndl) * 0.55 + smoothstep(0.32, 0.62, ndl) * 0.45;
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * mix(shade_col, sun_col, b) * 0.55;
}
"""

static var _shader: Shader


static func shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	return _shader


## Convierte el material fuente (StandardMaterial3D) en nuestro material toon conservando textura, color y emision.
static func toon(src: Material, p: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader()
	if src is BaseMaterial3D:
		var b := src as BaseMaterial3D
		if b.albedo_texture != null:
			m.set_shader_parameter("albedo_tex", b.albedo_texture)
			m.set_shader_parameter("has_tex", true)
		var ac: Color = b.albedo_color
		var mul := float(p.get("albedo_mul", 1.0))
		m.set_shader_parameter("albedo_col", Color(ac.r * mul, ac.g * mul, ac.b * mul, 1.0))
		m.set_shader_parameter("use_vcol", b.vertex_color_use_as_albedo)
		if b.emission_enabled:
			m.set_shader_parameter("emission_col", b.emission)
			m.set_shader_parameter("emission_e", clampf(b.emission_energy_multiplier, 0.6, 1.2))
	if p.has("hsv"):
		var h: Array = p["hsv"]
		m.set_shader_parameter("hsv", Vector3(float(h[0]), float(h[1]), float(h[2])))
	if p.has("vsel"):
		var vl: Array = p["vsel"]
		m.set_shader_parameter("vsel", Vector2(float(vl[0]), float(vl[1])))
	if p.has("sel"):
		var sl: Array = p["sel"]
		m.set_shader_parameter("sel", Vector2(float(sl[0]), float(sl[1])))
	for k in ["shade_col", "sun_col", "rim_col", "sky_col", "gnd_col"]:
		if p.has(k):
			m.set_shader_parameter(k, Color(str(p[k])))
	for k in ["rim_i", "amb_i", "ground_dark", "sat", "val"]:
		if p.has(k):
			m.set_shader_parameter(k, float(p[k]))
	return m


## Sustituye todos los materiales de las mallas. `overrides` permite materiales propios por nombre de malla (armas modeladas).
static func apply(meshes: Array, p: Dictionary) -> void:
	for mi in meshes:
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		for si in m.mesh.get_surface_count():
			var q := p.duplicate()
			var ml: Dictionary = p.get("mesh_look", {})
			if ml.has(String(m.name)):
				q.merge(ml[String(m.name)], true)
			m.set_surface_override_material(si, toon(m.get_active_material(si), q))


static func setup_light(sun: DirectionalLight3D, p: Dictionary) -> void:
	sun.rotation_degrees = Vector3(float(p.get("sun_pitch", -52.0)), float(p.get("sun_yaw", -38.0)), 0.0)
	sun.light_energy = float(p.get("sun", 1.0))
	sun.light_color = Color(str(p.get("sun_light", "#ffffff")))
	sun.shadow_enabled = false
