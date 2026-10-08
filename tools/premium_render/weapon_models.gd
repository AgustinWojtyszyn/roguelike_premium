class_name WeaponModels
extends RefCounted
## Armas modeladas por nosotros (geometria original de RPG Premium, no de ningun pack): volumenes robustos que comparten proporcion
## con las manos grandes de los heroes. Eje +X = hacia adelante, origen = centro de la empuñadura (donde cierra el puño),
## Y arriba, la cara que mira a camara es +Z. Los puntos `tip` (boca/punta) y `grip2` (mano libre) salen de la geometria,
## no de offsets: se proyectan con la camara del render y acaban en el manifest.

const INK := Color("202d36")       # metal oscuro
const PLATE := Color("465b64")     # placas
const EDGE := Color("a2aaab")      # cantos claros
const GRIP := Color("40332c")      # empuñadura


static func _mat(c: Color, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color, glow: float = 0.0, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	(mi.mesh as PrimitiveMesh).material = _mat(c, glow)
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


## Cilindro con el eje a lo largo de X.
static func _cyl(parent: Node3D, r: float, length: float, pos: Vector3, c: Color, glow: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = length
	cm.radial_segments = 10
	mi.mesh = cm
	(mi.mesh as PrimitiveMesh).material = _mat(c, glow)
	mi.position = pos
	mi.rotation_degrees = Vector3(0, 0, 90)
	parent.add_child(mi)
	return mi


static func _sphere(parent: Node3D, r: float, pos: Vector3, c: Color, glow: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 10
	sm.rings = 6
	mi.mesh = sm
	(mi.mesh as PrimitiveMesh).material = _mat(c, glow)
	mi.position = pos
	parent.add_child(mi)
	return mi


## Arma de fuego parametrica. Todas las medidas en unidades de mundo (el heroe mide ~1.6).
## spec: rear/front (cuerpo), h (alto), w (ancho), barrel (largo del caño), br (radio), stock (largo culata), mag_x/mag_h, grip_h,
## fore_x (posicion del agarre delantero, 0 = sin), glow (color del acento), sight, shroud (cubierta del caño)
static func gun(s: Dictionary) -> Node3D:
	var root := Node3D.new()
	var glow: Color = s.get("glow", Color("3df2dc"))
	var h: float = s["h"]
	var w: float = s.get("w", 0.15)
	var rear: float = s["rear"]
	var front: float = s["front"]
	var cy: float = s.get("body_y", 0.09)
	# cuerpo: carcasa + placa superior mas clara (da un canto que recoge la luz)
	_box(root, Vector3(front - rear, h, w), Vector3((front + rear) * 0.5, cy, 0), PLATE)
	_box(root, Vector3(front - rear - 0.04, h * 0.28, w * 0.78), Vector3((front + rear) * 0.5, cy + h * 0.5, 0), EDGE)
	_box(root, Vector3(front - rear - 0.06, h * 0.22, w + 0.012), Vector3((front + rear) * 0.5 - 0.01, cy - h * 0.12, 0), INK)
	# acento luminoso lateral
	_box(root, Vector3((front - rear) * 0.55, 0.02, w + 0.02), Vector3(rear + (front - rear) * 0.55, cy + h * 0.12, 0), glow, 1.0)
	# caño
	var bl: float = s["barrel"]
	var br: float = s.get("br", 0.04)
	_cyl(root, br, bl, Vector3(front + bl * 0.5 - 0.01, cy + h * 0.1, 0), INK)
	if s.get("shroud", 0.0) > 0.0:
		_cyl(root, br * 1.7, s["shroud"], Vector3(front + s["shroud"] * 0.5 - 0.02, cy + h * 0.1, 0), PLATE)
	_cyl(root, br * 1.25, 0.035, Vector3(front + bl - 0.01, cy + h * 0.1, 0), glow, 1.0)
	var tip_x: float = front + bl + 0.015
	# culata
	if s.get("stock", 0.0) > 0.0:
		_box(root, Vector3(s["stock"], h * 0.8, w * 0.8), Vector3(rear - s["stock"] * 0.5 + 0.02, cy - h * 0.1 - s.get("stock_drop", 0.0), 0), INK, 0.0, Vector3(0, 0, -s.get("stock_drop", 0.0) * 40.0))
		_box(root, Vector3(0.03, h * 1.1, w * 0.9), Vector3(rear - s["stock"] + 0.02, cy - h * 0.1 - s.get("stock_drop", 0.0), 0), EDGE)
	# empuñadura (el puño cierra aqui, en el origen)
	var gh: float = s.get("grip_h", 0.2)
	_box(root, Vector3(0.095, gh, w * 0.82), Vector3(0.0, cy - h * 0.5 - gh * 0.5 + 0.03, 0), GRIP, 0.0, Vector3(0, 0, 8))
	_box(root, Vector3(0.12, 0.04, w * 0.7), Vector3(-0.005, cy - h * 0.5 + 0.03, 0), INK)
	# guardamonte
	_box(root, Vector3(0.16, 0.025, w * 0.5), Vector3(0.1, cy - h * 0.5 - 0.02, 0), INK)
	# cargador
	if s.get("mag_h", 0.0) > 0.0:
		_box(root, Vector3(0.085, s["mag_h"], w * 0.7), Vector3(s["mag_x"], cy - h * 0.5 - s["mag_h"] * 0.5 + 0.01, 0), INK, 0.0, Vector3(0, 0, s.get("mag_tilt", 6.0)))
		_box(root, Vector3(0.09, 0.02, w * 0.72), Vector3(s["mag_x"], cy - h * 0.5 - s["mag_h"] + 0.02, 0), glow, 1.0)
	# visor
	if s.get("sight", true):
		_box(root, Vector3(0.1, 0.04, w * 0.3), Vector3(rear + (front - rear) * 0.35, cy + h * 0.5 + 0.045, 0), INK)
	var points := {"tip": Vector3(tip_x, cy + h * 0.1, 0), "grip": Vector3.ZERO}
	if s.get("fore_x", 0.0) > 0.0:
		var fx: float = s["fore_x"]
		_box(root, Vector3(0.08, 0.16, w * 0.75), Vector3(fx, cy - h * 0.5 - 0.06, 0), GRIP)
		points["grip2"] = Vector3(fx, cy - h * 0.5 - 0.05, 0)
	root.set_meta("points", points)
	return root


## Hoja de energia: empuñadura, guarda, hoja con nucleo emisivo y borde claro.
static func blade(s: Dictionary) -> Node3D:
	var root := Node3D.new()
	var glow: Color = s.get("glow", Color("ff6a8a"))
	_cyl(root, 0.045, 0.24, Vector3(0, 0, 0), GRIP)
	_cyl(root, 0.055, 0.03, Vector3(-0.06, 0, 0), EDGE)
	_cyl(root, 0.055, 0.03, Vector3(0.06, 0, 0), EDGE)
	_sphere(root, 0.06, Vector3(-0.15, 0, 0), PLATE)
	_box(root, Vector3(0.05, 0.3, 0.16), Vector3(0.16, 0, 0), PLATE)
	_box(root, Vector3(0.05, 0.1, 0.19), Vector3(0.16, 0, 0), EDGE)
	var bl: float = s.get("blade", 0.7)
	_box(root, Vector3(bl, 0.12, 0.05), Vector3(0.19 + bl * 0.5, 0, 0), glow.darkened(0.35), 0.35)
	_box(root, Vector3(bl, 0.06, 0.065), Vector3(0.19 + bl * 0.5, 0, 0), glow, 0.8)
	_box(root, Vector3(0.12, 0.12, 0.05), Vector3(0.19 + bl + 0.04, 0, 0), glow.darkened(0.35), 0.35, Vector3(0, 0, 45))
	root.set_meta("points", {"tip": Vector3(0.19 + bl + 0.09, 0, 0), "grip": Vector3.ZERO})
	return root


static func build(id: String) -> Node3D:
	match id:
		"pulsar":
			return gun({"rear": -0.13, "front": 0.28, "h": 0.115, "w": 0.12, "barrel": 0.26, "br": 0.026, "stock": 0.15, "stock_drop": 0.08,
				"mag_x": 0.16, "mag_h": 0.19, "grip_h": 0.16, "fore_x": 0.30, "glow": Color("3df2dc"), "shroud": 0.13})
		"chispa":
			return gun({"rear": -0.08, "front": 0.18, "h": 0.1, "w": 0.1, "barrel": 0.12, "br": 0.024, "grip_h": 0.17, "glow": Color("9fe9ff"), "sight": true, "body_y": 0.08})
		"trinca":
			return gun({"rear": -0.16, "front": 0.42, "h": 0.115, "w": 0.12, "barrel": 0.34, "br": 0.026, "stock": 0.22, "stock_drop": 0.07,
				"mag_x": 0.18, "mag_h": 0.19, "grip_h": 0.16, "fore_x": 0.30, "glow": Color("b8ff6a"), "shroud": 0.2})
		"maul12":
			return gun({"rear": -0.15, "front": 0.34, "h": 0.125, "w": 0.14, "barrel": 0.3, "br": 0.04, "stock": 0.2, "stock_drop": 0.06,
				"mag_h": 0.0, "grip_h": 0.16, "fore_x": 0.30, "glow": Color("ffc24a"), "shroud": 0.14, "sight": false})
		"filo_z":
			return blade({"glow": Color("ff6a8a"), "blade": 0.72})
	return Node3D.new()
