class_name CharacterRig
extends Node2D
## Aspecto y animacion procedural de un personaje (partes vectoriales + IK de brazos). No contiene logica de juego:
## Player y las pantallas de menu (home / coleccion) lo reutilizan. La silueta cambia por `look`
## (cabeza, torso, espalda, hombros, proporciones) y los colores se derivan de 4 colores base.

signal stepped(strength: float)

const SPEED_REF := 262.0
const HIP_Y := -17.0
const WEAPON_POS := Vector2(12, 2.5)

const DEFAULT_LOOK := {
	"suit": [Color("4a5a82"), Color("27304e")], "sleeve": [Color("3a4a74"), Color("27304f")],
	"leg": [Color("2b3755"), Color("1d2540")], "leg_b": [Color("1b2338"), Color("121829")],
	"knee": Color("56648e"), "boot": [Color("3a4668"), Color("232b44")],
	"plate": [Color("e6edf9"), Color("9aabcc")], "shoulder": [Color("8da0cf"), Color("46547d")],
	"helmet": [Color("f2f6fd"), Color("8b9cc0")], "crest": Color("ff8a3d"), "trim": Color("ff8a3d"),
	"visor": [Color("1d3f56"), Color("060b16")], "visor_line": Color("5ff7e4"),
	"glow": Color("27e0cc"), "ear": Color("1c2440"), "scarf": Color("ff7a2e"),
	"glove": [Color("e4ebf8"), Color("9aa8c6")], "pack": [Color("303b5c"), Color("1a2138")],
	"belt": Color("20283f"), "hair": Color("5a3a2a"), "skin": Color("f0c8a0"),
	"head": "visor_helmet", "torso": "armor", "back": "pack", "shoulder_style": "pads",
	"w": 1.0, "h": 1.0, "hs": 1.0, "bare_arms": false,
}


static func resolve_look(look: Dictionary) -> Dictionary:
	var out: Dictionary = DEFAULT_LOOK.duplicate(true)
	if look.has("base"):
		var B: Color = look["base"]
		var L: Color = look.get("light", B.lightened(0.6))
		var G: Color = look.get("glow", Color("27e0cc"))
		var A: Color = look.get("accent", G)
		out["suit"] = [B, B.darkened(0.45)]
		out["sleeve"] = [B.darkened(0.15), B.darkened(0.45)]
		out["leg"] = [B.darkened(0.3), B.darkened(0.55)]
		out["leg_b"] = [B.darkened(0.5), B.darkened(0.7)]
		out["knee"] = B.lightened(0.2)
		out["boot"] = [B.darkened(0.2), B.darkened(0.45)]
		out["plate"] = [L, L.darkened(0.35)]
		out["shoulder"] = [L.lerp(B, 0.35), B.darkened(0.15)]
		out["helmet"] = [L, L.darkened(0.35)]
		out["crest"] = A
		out["trim"] = A
		out["visor"] = [G.darkened(0.72), G.darkened(0.9)]
		out["visor_line"] = G.lightened(0.35)
		out["glow"] = G
		out["ear"] = B.darkened(0.55)
		out["glove"] = [L.lightened(0.1), L.darkened(0.3)]
		out["pack"] = [B.darkened(0.3), B.darkened(0.55)]
		out["belt"] = B.darkened(0.6)
		out["scarf"] = A
		out["hair"] = B.darkened(0.45)
	for k in look:
		if k in ["base", "light", "accent"]:
			continue
		if k == "glow":
			out["glow"] = look[k]
			out["visor_line"] = (look[k] as Color).lightened(0.35)
			continue
		out[k] = look[k]
	return out


# ----------------------------------------------------------------------------- estado (lo alimenta el dueño)
var lk: Dictionary = {}
var weapon: WeaponData
var vel := Vector2.ZERO
var aim := Vector2.RIGHT
var face: float = 1.0
var face_vis: float = 1.0
var kick: float = 0.0
var heat: float = 0.0
var swap_t: float = 0.0
var flash: float = 0.0
var alpha: float = 1.0
var swing: float = 0.0          # tajo melee (-1..1)
var t: float = 0.0
var walk_ph: float = 0.0
var look_q: int = 0
var was_step_sign: float = 1.0
var dead := false
var death_t: float = 0.0
var death_dirv := Vector2.RIGHT
var auto := false               # animacion autonoma (menus)
var cape_sway: float = 0.0

var vis: Node2D
var fmat: ShaderMaterial
var shadow: Part
var body: Node2D
var pack: Part
var antenna: Part
var leg_b: Part
var leg_f: Part
var torso: Part
var head: Part
var scarf: Part
var pivot: Node2D
var arm_b: Part
var wnode: Part
var arm_f: Part
var scarf_pts: Array[Vector2] = []
var _prev_aim_y: float = 99.0
var _auto_t: float = 0.0
var _redraw_t: float = 0.0


func build(look: Dictionary, w: WeaponData, show_shadow: bool = true) -> void:
	lk = resolve_look(look)
	weapon = w
	var sw: float = lk["w"]
	var sh: float = lk["h"]
	if show_shadow:
		shadow = Part.make(self, _paint_shadow)
	vis = Node2D.new()
	fmat = Gfx.flash_material()
	vis.material = fmat
	add_child(vis)
	scarf = Part.make(vis, _paint_scarf)
	body = Node2D.new()
	body.use_parent_material = true
	vis.add_child(body)
	pack = Part.make(body, _paint_back, Vector2(-9, -26))
	Part.make(pack, _paint_back_glow, Vector2.ZERO, true)
	antenna = Part.make(body, _paint_antenna, Vector2(-12, -34))
	antenna.visible = (lk["back"] == "pack")
	leg_b = Part.make(body, _paint_leg, Vector2(-5 * sw, HIP_Y))
	leg_b.set_meta("dark", true)
	leg_f = Part.make(body, _paint_leg, Vector2(5 * sw, HIP_Y))
	leg_f.set_meta("dark", false)
	leg_b.scale.x = sw
	leg_f.scale.x = sw
	torso = Part.make(body, _paint_torso, Vector2(0, HIP_Y))
	torso.scale = Vector2(sw, sh)
	Part.make(torso, _paint_torso_glow, Vector2.ZERO, true)
	for i in 6:
		scarf_pts.append(Vector2(-4, -33))
	head = Part.make(body, _paint_head, Vector2(1, -34 - (sh - 1.0) * 14.0))
	head.scale = Vector2.ONE * float(lk["hs"])
	Part.make(head, _paint_head_glow, Vector2.ZERO, true)
	pivot = Node2D.new()
	pivot.use_parent_material = true
	pivot.position = Vector2(0, -26)
	vis.add_child(pivot)
	arm_b = Part.make(pivot, _paint_arm_back)
	wnode = Part.make(pivot, _paint_weapon, WEAPON_POS)
	arm_f = Part.make(pivot, _paint_arm_front)
	scarf.visible = lk["scarf"] != null and lk["back"] != "cape"


func set_weapon(w: WeaponData) -> void:
	weapon = w
	swap_t = 1.0
	arm_b.queue_redraw()
	wnode.queue_redraw()


func muzzle_world() -> Vector2:
	return pivot.to_global(wnode.position + weapon.muzzle)


func hit_center_local() -> Vector2:
	return Vector2(0, -26)


# =====================================================================  PARTES
func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(1, -1), 24.0 * float(lk["w"]), Color(0, 0, 0, 0.6))


func _paint_leg(c: Part) -> void:
	var dark: bool = c.get_meta("dark", false)
	var ink := Gfx.INK
	var pair: Array = lk["leg_b"] if dark else lk["leg"]
	var bt: Array = lk["boot"]
	var a: Color = pair[0]
	var b: Color = pair[1]
	var robe: bool = lk["torso"] == "robe"
	Gfx.gpoly(c, PackedVector2Array([Vector2(-4.5, 0), Vector2(4.5, 0), Vector2(5, 8), Vector2(4.5, 13), Vector2(-4.5, 13), Vector2(-5, 8)]), a, b, ink, 2.0)
	Gfx.ell(c, Vector2(0.5, 6.5), 4.0, 3.0, (lk["knee"] as Color).darkened(0.35 if dark else 0.0), ink, 1.5)
	var btop: Color = bt[0]
	var bbot: Color = bt[1]
	if dark:
		btop = btop.darkened(0.35)
		bbot = bbot.darkened(0.3)
	var boot := PackedVector2Array([Vector2(-5.5, 11), Vector2(5.5, 11), Vector2(10, 15), Vector2(10.5, 18.5), Vector2(-5.5, 18.5)])
	if lk["torso"] == "heavy":
		boot = PackedVector2Array([Vector2(-6.5, 10), Vector2(6.5, 10), Vector2(11.5, 15), Vector2(12, 18.5), Vector2(-6.5, 18.5)])
	Gfx.gpoly(c, boot, btop, bbot, ink, 2.0)
	c.draw_rect(Rect2(-5, 16, 15, 2.0), Color("0c1020"))
	c.draw_line(Vector2(5, 13), Vector2(9.5, 16.5), Color(1, 1, 1, 0.18 if not dark else 0.06), 1.5)
	var trim: Color = lk["trim"]
	c.draw_rect(Rect2(-5, 11.5, 5, 1.6), trim if not dark else trim.darkened(0.35))
	if robe:
		pass


func _paint_torso(c: Part) -> void:
	var ink := Gfx.INK
	var suit: Array = lk["suit"]
	var plate: Array = lk["plate"]
	var glow: Color = lk["glow"]
	var trim: Color = lk["trim"]
	var style: String = lk["torso"]
	match style:
		"suit":
			var tb := PackedVector2Array([Vector2(-8.5, 0), Vector2(8.5, 0), Vector2(10.5, -6), Vector2(9.5, -15), Vector2(6, -18), Vector2(-6, -18), Vector2(-9.5, -15), Vector2(-10.5, -6)])
			Gfx.gpoly(c, tb, suit[0], suit[1], ink, 2.2)
			Gfx.gpoly(c, PackedVector2Array([Vector2(-5.5, -3.5), Vector2(5.5, -3.5), Vector2(6.5, -12), Vector2(3.5, -16), Vector2(-3.5, -16), Vector2(-6.5, -12)]), plate[0], plate[1], Color("1a2238"), 1.4)
			_emblem(c, Vector2(0, -9.5), 3.0)
			c.draw_rect(Rect2(-9, -2.5, 18, 3), (lk["belt"] as Color))
			Gfx.rrect(c, Rect2(-2.5, -3.2, 5, 4.6), 1.2, trim, ink, 1.2)
		"hunter":
			var tb := PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(11, -6), Vector2(10, -15), Vector2(6, -18), Vector2(-6, -18), Vector2(-10, -15), Vector2(-11, -6)])
			var skin: Color = lk["skin"]
			if lk["bare_arms"]:
				Gfx.gpoly(c, tb, skin, skin.darkened(0.35), ink, 2.2)
			else:
				Gfx.gpoly(c, tb, suit[0], suit[1], ink, 2.2)
			# chaleco + correas cruzadas
			Gfx.gpoly(c, PackedVector2Array([Vector2(-9, -2), Vector2(9, -2), Vector2(10, -12), Vector2(5, -17), Vector2(-5, -17), Vector2(-10, -12)]), plate[1], (plate[1] as Color).darkened(0.4), ink, 1.8)
			c.draw_line(Vector2(-8, -16), Vector2(7, -2), ink, 4.0, true)
			c.draw_line(Vector2(-8, -16), Vector2(7, -2), trim, 2.0, true)
			c.draw_line(Vector2(8, -16), Vector2(-7, -2), ink, 4.0, true)
			c.draw_line(Vector2(8, -16), Vector2(-7, -2), (trim as Color).darkened(0.3), 2.0, true)
			Gfx.ell(c, Vector2(0, -9), 3.2, 3.2, glow, ink, 1.4)
			c.draw_rect(Rect2(-10, -3, 20, 4), ink)
			c.draw_rect(Rect2(-9, -2.4, 18, 3), lk["belt"])
			for sx in [-6.5, 6.5]:
				Gfx.rrect(c, Rect2(sx - 2.5, -3, 5, 6.5), 1.4, plate[1], ink, 1.3)
		"heavy":
			var tb := PackedVector2Array([Vector2(-11, 0), Vector2(11, 0), Vector2(14, -6), Vector2(13.5, -15), Vector2(8, -18.5), Vector2(-8, -18.5), Vector2(-13.5, -15), Vector2(-14, -6)])
			Gfx.gpoly(c, tb, suit[0], suit[1], ink, 2.6)
			Gfx.gpoly(c, PackedVector2Array([Vector2(-10, -3), Vector2(10, -3), Vector2(11.5, -13), Vector2(6, -17), Vector2(-6, -17), Vector2(-11.5, -13)]), plate[0], plate[1], ink, 1.8)
			Gfx.rrect(c, Rect2(-5.5, -14, 11, 10), 2.5, Color("0b0f1a"), ink, 1.6)
			c.draw_circle(Vector2(0, -9), 3.6, glow)
			c.draw_arc(Vector2(0, -9), 5.0, 0, TAU, 14, Color(1, 1, 1, 0.5), 1.0, true)
			for k in 2:
				c.draw_line(Vector2(-9 + k * 18.0, -15), Vector2(-9 + k * 18.0, -5), trim, 2.0)
			c.draw_rect(Rect2(-13, -2.5, 26, 5), ink)
			c.draw_rect(Rect2(-12, -2, 24, 4), (lk["belt"] as Color).lightened(0.1))
			for sx in [-9.0, 0.0, 9.0]:
				Gfx.rrect(c, Rect2(sx - 2.5, -2, 5, 5), 1.2, trim, ink, 1.2)
		"robe":
			# abrigo largo: cubre caderas y el hem cae casi hasta las botas
			var sway := cape_sway * 2.0
			var tb := PackedVector2Array([Vector2(-9, 11), Vector2(9, 11), Vector2(11 + sway, 3), Vector2(10, -6), Vector2(8, -15), Vector2(5, -18), Vector2(-5, -18), Vector2(-8, -15), Vector2(-10, -6), Vector2(-11 + sway, 3)])
			Gfx.gpoly(c, tb, suit[0], suit[1], ink, 2.3)
			c.draw_line(Vector2(0, -17), Vector2(0, 11), Color(0, 0, 0, 0.4), 2.0)
			c.draw_line(Vector2(-9, 9), Vector2(9, 9), trim, 2.0)
			c.draw_line(Vector2(-9.5, 6.5), Vector2(9.5, 6.5), (trim as Color).darkened(0.3), 1.2)
			Gfx.gpoly(c, PackedVector2Array([Vector2(-6, -17), Vector2(0, -12), Vector2(6, -17), Vector2(4, -3), Vector2(-4, -3)]), plate[0], plate[1], ink, 1.4)
			_emblem(c, Vector2(0, -9), 2.8)
			c.draw_rect(Rect2(-10, -2.5, 20, 3.4), lk["belt"])
			Gfx.rrect(c, Rect2(-2.5, -3.2, 5, 4.6), 1.2, trim, ink, 1.2)
			for k in 3:
				c.draw_line(Vector2(-6 + k * 6.0, 1), Vector2(-6 + k * 6.0, 7), Color(glow, 0.7), 1.4)
		"glitch":
			var off := sin(t * 21.0) * 1.8 if int(t * 5.0) % 3 == 0 else 0.0
			var tb := PackedVector2Array([Vector2(-10, 0), Vector2(10, 0), Vector2(12, -6), Vector2(11, -15), Vector2(7, -18), Vector2(-7, -18), Vector2(-11, -15), Vector2(-12, -6)])
			Gfx.gpoly(c, tb, suit[0], suit[1], ink, 2.2)
			var up := PackedVector2Array([Vector2(-11 + off, -18), Vector2(11 + off, -18), Vector2(12 + off, -9), Vector2(-12 + off, -9)])
			Gfx.poly(c, up, Color(glow, 0.55), ink, 1.4)
			Gfx.poly(c, PackedVector2Array([Vector2(-8 - off, -8), Vector2(8 - off, -8), Vector2(9 - off, -1), Vector2(-9 - off, -1)]), Color(trim, 0.5), ink, 1.2)
			for k in 4:
				var y := -16.0 + k * 4.5
				c.draw_line(Vector2(-10, y), Vector2(10, y + sin(t * 9.0 + k) * 2.0), Color(1, 1, 1, 0.5), 1.0)
			_emblem(c, Vector2(0, -10), 3.0)
			c.draw_rect(Rect2(-11, -2.5, 22, 3), ink)
		_:   # armor (Vesper)
			var tb := PackedVector2Array([Vector2(-10, 0), Vector2(10, 0), Vector2(12.5, -6), Vector2(11.5, -15), Vector2(7, -18), Vector2(-7, -18), Vector2(-11.5, -15), Vector2(-12.5, -6)])
			Gfx.gpoly(c, tb, suit[0], suit[1], ink, 2.2)
			var cp := PackedVector2Array([Vector2(-7.5, -3.5), Vector2(7.5, -3.5), Vector2(9, -13), Vector2(5, -16.5), Vector2(-5, -16.5), Vector2(-9, -13)])
			Gfx.gpoly(c, cp, plate[0], plate[1], Color("1a2238"), 1.5)
			c.draw_line(Vector2(-6, -15), Vector2(6, -15), Color(1, 1, 1, 0.8), 1.5)
			_emblem(c, Vector2(0, -9.5), 3.3)
			c.draw_rect(Rect2(-11, -2.5, 22, 4), ink)
			c.draw_rect(Rect2(-10, -2, 20, 3), lk["belt"])
			Gfx.rrect(c, Rect2(-3.5, -3.5, 7, 6), 1.5, trim, ink, 1.4)
			for sx in [-8.5, 8.5]:
				Gfx.rrect(c, Rect2(sx - 2.5, -2.5, 5, 6.5), 1.5, (suit[0] as Color).lightened(0.05), ink, 1.4)
	_shoulders(c)


func _emblem(c: Part, p: Vector2, r: float) -> void:
	var glow: Color = lk["glow"]
	Gfx.poly(c, PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)]), glow, glow.darkened(0.7), 1.3)


func _shoulders(c: Part) -> void:
	var ink := Gfx.INK
	var sh: Array = lk["shoulder"]
	var glow: Color = lk["glow"]
	var style: String = lk["shoulder_style"]
	for sx in [-1, 1]:
		var hp := Vector2(11.5 * sx, -14.5)
		match style:
			"pads":
				Gfx.gell(c, hp, 6.0, 5.2, sh[0], sh[1], ink, 2.0)
				c.draw_line(hp + Vector2(-3.5, 0.5), hp + Vector2(3.5, 0.5), glow, 1.6)
			"plain":
				Gfx.gell(c, hp, 4.4, 4.0, sh[0], sh[1], ink, 1.8)
			"spikes":
				Gfx.gell(c, hp, 5.2, 4.6, sh[0], sh[1], ink, 2.0)
				Gfx.poly(c, PackedVector2Array([hp + Vector2(-2.5 * sx, -3), hp + Vector2(1 * sx, -11), hp + Vector2(3.5 * sx, -3)]), (lk["trim"] as Color), ink, 1.5)
			"big":
				Gfx.gell(c, hp + Vector2(2.0 * sx, 0), 9.0, 7.6, sh[0], sh[1], ink, 2.4)
				c.draw_arc(hp + Vector2(2.0 * sx, 0), 6.0, PI * 1.1, PI * 1.9, 10, Color(1, 1, 1, 0.3), 1.6, true)
				c.draw_line(hp + Vector2(-4.5 + 2.0 * sx, 1.5), hp + Vector2(4.5 + 2.0 * sx, 1.5), lk["trim"], 2.2)
			_:
				pass


func _paint_torso_glow(c: Part) -> void:
	var p := 0.6 + 0.4 * sin(t * 3.0)
	var g: Color = lk["glow"]
	Gfx.draw_glow(c, Vector2(0, -9.5), 11.0, Color(g.r, g.g, g.b, 0.5 * p))


func _paint_back(c: Part) -> void:
	var ink := Gfx.INK
	var pk: Array = lk["pack"]
	var glow: Color = lk["glow"]
	var trim: Color = lk["trim"]
	match lk["back"]:
		"array":
			Gfx.grrect(c, Rect2(-7, -10, 14, 20), 3.0, pk[0], pk[1], ink, 2.0)
			for k in 3:
				var y := -8.0 + k * 6.0
				c.draw_line(Vector2(-4, y), Vector2(-13, y - 6 - k * 2.0), ink, 3.0, true)
				c.draw_line(Vector2(-4, y), Vector2(-13, y - 6 - k * 2.0), (lk["plate"][1] as Color), 1.4, true)
				c.draw_circle(Vector2(-13, y - 6 - k * 2.0), 1.8, glow if (int(t * 3.0) + k) % 2 == 0 else glow.darkened(0.6))
			c.draw_rect(Rect2(-5, -6, 3, 12), glow)
		"medpack":
			Gfx.grrect(c, Rect2(-9, -10, 18, 22), 4.0, Color("f4f7fb"), Color("b8c4d6"), ink, 2.0)
			c.draw_rect(Rect2(-2, -6, 4, 12), trim)
			c.draw_rect(Rect2(-6, -2, 12, 4), trim)
			c.draw_line(Vector2(9, -4), Vector2(14, 4), ink, 3.0, true)
			c.draw_circle(Vector2(14, 5), 2.4, glow)
		"toolbox":
			Gfx.grrect(c, Rect2(-10, -9, 20, 20), 3.0, pk[0], pk[1], ink, 2.0)
			c.draw_rect(Rect2(-10, -2, 20, 3), trim)
			for k in 3:
				c.draw_line(Vector2(-6 + k * 6.0, -9), Vector2(-6 + k * 6.0, -14 - k * 1.5), ink, 3.0, true)
			c.draw_circle(Vector2(-12, -2), 3.4, ink)
			c.draw_circle(Vector2(-12, -2), 2.2, glow)
			c.draw_line(Vector2(-10, -3), Vector2(-16, -12), ink, 3.2, true)
			c.draw_line(Vector2(-10, -3), Vector2(-16, -12), (lk["plate"][1] as Color), 1.4, true)
			c.draw_circle(Vector2(-16, -12), 2.0, trim)
		"rifle_sling":
			Gfx.grrect(c, Rect2(-8, -10, 16, 22), 4.0, pk[0], pk[1], ink, 2.0)
			var a := PackedVector2Array([Vector2(-10, 14), Vector2(8, -18)])
			c.draw_polyline(a, ink, 6.0, true)
			c.draw_polyline(a, (lk["plate"][1] as Color).darkened(0.2), 3.2, true)
			c.draw_circle(Vector2(8, -18), 2.4, glow)
			c.draw_line(Vector2(-6, -8), Vector2(6, 9), trim, 2.0)
		"cape":
			var sw := cape_sway * 10.0
			var cp := PackedVector2Array([Vector2(0, -8), Vector2(-4, -9), Vector2(-18 + sw, 6), Vector2(-24 + sw * 1.6, 26), Vector2(-14 + sw, 30), Vector2(-6 + sw * 0.7, 24), Vector2(2, 28), Vector2(8, 10), Vector2(4, -4)])
			Gfx.gpoly(c, cp, pk[0], pk[1], ink, 2.0)
			c.draw_line(Vector2(-3, -6), Vector2(-14 + sw * 1.4, 26), Color(trim, 0.7), 1.8, true)
			var sc: Variant = lk["scarf"]
			if sc != null:
				c.draw_line(Vector2(-4, -8), Vector2(-18 + sw, 6), sc, 2.4, true)
		"spine":
			for k in 4:
				var y := -12.0 + k * 7.0
				Gfx.poly(c, PackedVector2Array([Vector2(-2, y + 3), Vector2(-14 + k * 1.5, y + 7 - k), Vector2(-2, y - 3)]), lk["plate"][1], ink, 1.6)
			Gfx.grrect(c, Rect2(-6, -10, 10, 22), 3.0, pk[0], pk[1], ink, 1.8)
		"ring":
			var ph := t * 1.6
			c.draw_arc(Vector2(-6, -12), 18.0, ph, ph + TAU * 0.78, 24, Color(ink, 0.9), 5.0, true)
			c.draw_arc(Vector2(-6, -12), 18.0, ph, ph + TAU * 0.78, 24, glow, 2.4, true)
			for k in 3:
				var a := ph + float(k) * 1.7
				c.draw_circle(Vector2(-6, -12) + Vector2.from_angle(a) * 18.0, 2.4, Color.WHITE)
		"tanks":
			for sy in [-1, 1]:
				var cy: float = -2.0 + sy * 7.0
				Gfx.grrect(c, Rect2(-13, cy - 6.5, 16, 13), 6.0, pk[0].lightened(0.15), pk[1], ink, 2.0)
				c.draw_rect(Rect2(-10, cy - 4.5, 10, 2.0), Color(1, 1, 1, 0.3))
				c.draw_rect(Rect2(-12.5, cy - 1.0, 15, 2.6), trim)
			c.draw_rect(Rect2(-4, -6, 4, 12), ink)
			c.draw_circle(Vector2(-2, 0), 1.8, glow)
		"orbs":
			for k in 3:
				var a := t * 1.9 + TAU * float(k) / 3.0
				var p := Vector2(-8, -12) + Vector2(cos(a) * 12.0, sin(a) * 7.0)
				Gfx.ell(c, p, 3.6, 3.6, glow.lightened(0.2), ink, 1.4)
				c.draw_circle(p + Vector2(-1, -1), 1.1, Color(1, 1, 1, 0.8))
			Gfx.grrect(c, Rect2(-7, -8, 12, 18), 3.0, pk[0], pk[1], ink, 1.8)
		"shards":
			for k in 4:
				var a := t * 0.9 + TAU * float(k) / 4.0
				var p := Vector2(-9, -10) + Vector2(cos(a) * 14.0, sin(a * 1.3) * 12.0)
				var col := glow if k % 2 == 0 else (trim as Color)
				Gfx.poly(c, PackedVector2Array([p + Vector2(0, -5), p + Vector2(3, 0), p + Vector2(0, 5), p + Vector2(-3, 0)]), Color(col, 0.85), ink, 1.3)
		"none":
			pass
		_:  # pack (Vesper)
			Gfx.grrect(c, Rect2(-8, -12, 16, 24), 4.0, pk[0], pk[1], ink, 2.0)
			Gfx.rrect(c, Rect2(-5, -8, 4, 16), 1.5, Color("0b2a30"), ink, 1.2)
			Gfx.rrect(c, Rect2(1, -8, 4, 16), 1.5, Color("0b2a30"), ink, 1.2)
			c.draw_rect(Rect2(-4, -7, 2, 14), glow)
			c.draw_rect(Rect2(2, -7, 2, 14), glow)
			c.draw_rect(Rect2(-8, 8, 16, 3), trim)
			c.draw_rect(Rect2(-8, 8, 16, 1), Color(1, 1, 1, 0.2))


func _paint_back_glow(c: Part) -> void:
	var p := 0.6 + 0.4 * sin(t * 2.4 + 1.0)
	var g: Color = lk["glow"]
	match lk["back"]:
		"pack", "tanks", "array", "orbs", "ring", "shards":
			Gfx.draw_glow(c, Vector2(0, 0), 16.0, Color(g.r, g.g, g.b, 0.35 * p))


func _paint_antenna(c: Part) -> void:
	var tip := Vector2(-1.5, -14)
	c.draw_line(Vector2.ZERO, tip, Gfx.INK, 3.0, true)
	c.draw_line(Vector2.ZERO, tip, (lk["shoulder"][0] as Color), 1.3, true)
	c.draw_circle(tip, 2.6, Gfx.INK)
	var on := int(t * 2.5) % 2 == 0
	var tr: Color = lk["trim"]
	c.draw_circle(tip, 1.8, tr if on else tr.darkened(0.55))


# ----------------------------------------------------------------------------- cabeza
func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	var ly := float(look_q) / 10.0
	var hm: Array = lk["helmet"]
	var vz: Array = lk["visor"]
	var vline: Color = lk["visor_line"]
	var glow: Color = lk["glow"]
	var trim: Color = lk["trim"]
	var style: String = lk["head"]
	# cuello base
	c.draw_rect(Rect2(-3.5, -4, 7, 5), (lk["suit"][1] as Color).darkened(0.3))
	match style:
		"dome":
			Gfx.rrect(c, Rect2(-7, -5.5, 14, 6), 2.5, (lk["shoulder"][1] as Color), ink, 1.6)
			Gfx.gpoly(c, Gfx.ell_pts(Vector2(1, -13), 12.4, 12.0, 26), hm[0], hm[1], ink, 2.4)
			Gfx.rrect(c, Rect2(-14.0, -15, 3.2, 9), 1.4, hm[1], ink, 1.4)
			Gfx.rrect(c, Rect2(13.0, -15, 3.2, 9), 1.4, hm[1], ink, 1.4)
			if ly < -0.55:
				for k in 3:
					c.draw_line(Vector2(-6, -19 + k * 3.0), Vector2(8, -19 + k * 3.0), (hm[1] as Color).darkened(0.3), 1.4)
			else:
				var vy := -12.0 + ly * 2.0
				Gfx.rrect(c, Rect2(1.5, vy - 4.0, 13.5, 8.0), 4.0, vz[0], ink, 1.8)
				c.draw_rect(Rect2(3.5, vy - 1.2, 10.0, 2.4), vline)
				c.draw_line(Vector2(4, vy - 3.0), Vector2(11, vy - 3.0), Color(1, 1, 1, 0.5), 1.2)
		"hood":
			var hood := PackedVector2Array([Vector2(-14, 2), Vector2(-15, -14), Vector2(-9, -25), Vector2(2, -28), Vector2(11, -22), Vector2(14, -12), Vector2(11, -4), Vector2(5, 1)])
			Gfx.gpoly(c, hood, lk["suit"][0], lk["suit"][1], ink, 2.4)
			Gfx.poly(c, PackedVector2Array([Vector2(-14, 2), Vector2(-20, 10), Vector2(-9, 6)]), lk["suit"][1], ink, 1.8)
			c.draw_line(Vector2(-11, -22), Vector2(-14, -8), Color(trim, 0.6), 1.6, true)
			if ly >= -0.55:
				var vy := -12.0 + ly * 2.0
				Gfx.poly(c, Gfx.ell_pts(Vector2(6, vy), 7.4, 8.2, 16), Color("07040f"), ink, 1.6)
			# ojos
			var ey := -12.0 + ly * 2.0
			c.draw_colored_polygon(PackedVector2Array([Vector2(3.6, ey - 1.6), Vector2(8.6, ey - 0.4), Vector2(8.4, ey + 1.4), Vector2(3.8, ey + 0.8)]), glow)
		"goggles":
			var skin: Color = lk["skin"]
			Gfx.ell(c, Vector2(1, -12), 11.4, 11.0, skin, ink, 2.2)
			Gfx.poly(c, PackedVector2Array([Vector2(-12, -14), Vector2(-9, -20), Vector2(-2, -22), Vector2(0, -16)]), lk["hair"], ink, 1.6)
			Gfx.poly(c, PackedVector2Array([Vector2(-12, -9), Vector2(-16, -4), Vector2(-9, -6)]), lk["hair"], ink, 1.4)
			# casco de obra + lampara
			var cap := PackedVector2Array([Vector2(-13, -15), Vector2(-11, -22), Vector2(-2, -27), Vector2(9, -25), Vector2(14, -17), Vector2(16, -15), Vector2(-13, -15)])
			Gfx.gpoly(c, cap, hm[0], hm[1], ink, 2.2)
			c.draw_line(Vector2(-3, -26), Vector2(1, -16), Color(0, 0, 0, 0.25), 1.6)
			Gfx.rrect(c, Rect2(5, -26, 6, 4.6), 1.6, Color("ffffff"), ink, 1.3)
			if ly >= -0.55:
				var gy := -11.5 + ly * 2.0
				Gfx.rrect(c, Rect2(1, gy - 4, 14, 8.5), 4.0, Color("22303a"), ink, 1.6)
				Gfx.ell(c, Vector2(6, gy), 3.4, 3.4, glow, ink, 1.2)
				Gfx.ell(c, Vector2(12, gy), 2.6, 2.6, glow.darkened(0.2), ink, 1.0)
				c.draw_line(Vector2(5, gy - 1.6), Vector2(8, gy - 1.6), Color(1, 1, 1, 0.7), 1.0)
				c.draw_line(Vector2(-10, gy - 1), Vector2(1, gy - 0.5), ink, 2.2)
		"alien":
			var skin: Color = lk["skin"]
			var cranium := PackedVector2Array([Vector2(-15, -4), Vector2(-17, -16), Vector2(-9, -26), Vector2(3, -27), Vector2(12, -19), Vector2(15, -9), Vector2(11, -1), Vector2(2, 1), Vector2(-8, 0)])
			Gfx.gpoly(c, cranium, skin.lightened(0.1), skin.darkened(0.4), ink, 2.4)
			for k in 3:
				var y := -22.0 + k * 3.5
				c.draw_line(Vector2(-12, y), Vector2(-2, y - 1), Color(0, 0, 0, 0.28), 1.4)
			for k in 3:
				Gfx.poly(c, PackedVector2Array([Vector2(-14 - k * 1.5, -8 - k * 5.0), Vector2(-24 - k * 2.0, -4 - k * 7.0), Vector2(-12, -14 - k * 5.0)]), lk["plate"][1], ink, 1.5)
			if ly >= -0.55:
				var ey := -12.0 + ly * 2.0
				c.draw_colored_polygon(PackedVector2Array([Vector2(3, ey - 2.5), Vector2(11.5, ey - 0.5), Vector2(11, ey + 2), Vector2(3.5, ey + 1)]), Color("06120e"))
				c.draw_colored_polygon(PackedVector2Array([Vector2(5, ey - 1.5), Vector2(10.5, ey - 0.2), Vector2(10.2, ey + 0.8), Vector2(5.2, ey + 0.3)]), glow)
				# mandibulas
				c.draw_polyline(PackedVector2Array([Vector2(12, -2), Vector2(17, 1), Vector2(14, 5)]), ink, 4.0, true)
				c.draw_polyline(PackedVector2Array([Vector2(12, -2), Vector2(17, 1), Vector2(14, 5)]), lk["plate"][0], 2.0, true)
				c.draw_polyline(PackedVector2Array([Vector2(7, 0), Vector2(11, 4), Vector2(7, 6)]), ink, 3.4, true)
				c.draw_polyline(PackedVector2Array([Vector2(7, 0), Vector2(11, 4), Vector2(7, 6)]), lk["plate"][0], 1.6, true)
		"medic":
			var skin: Color = lk["skin"]
			Gfx.ell(c, Vector2(1, -12), 11.4, 11.0, skin, ink, 2.2)
			Gfx.poly(c, PackedVector2Array([Vector2(-11, -12), Vector2(-17, -8), Vector2(-20, 2), Vector2(-12, -2), Vector2(-9, -8)]), lk["hair"], ink, 1.6)   # coleta
			var cap := PackedVector2Array([Vector2(-12, -14), Vector2(-9, -23), Vector2(0, -26), Vector2(9, -23), Vector2(13, -14), Vector2(5, -17), Vector2(-5, -17)])
			Gfx.gpoly(c, cap, hm[0], hm[1], ink, 2.0)
			c.draw_rect(Rect2(-1.6, -24, 3.2, 7), trim)
			c.draw_rect(Rect2(-4.2, -22.2, 8.4, 3.2), trim)
			if ly >= -0.55:
				var vy := -11.0 + ly * 2.0
				Gfx.rrect(c, Rect2(1.5, vy + 0.5, 13.0, 8.5), 3.0, Color("e8f2f6"), ink, 1.6)                  # mascarilla
				Gfx.rrect(c, Rect2(2.0, vy - 4.4, 12.5, 5.2), 2.4, Color(glow.darkened(0.55), 0.95), ink, 1.5)    # gafas
				c.draw_line(Vector2(4, vy - 3), Vector2(10, vy - 3), Color(1, 1, 1, 0.65), 1.2)
		"heavy":
			Gfx.rrect(c, Rect2(-8.5, -6, 17, 7), 3.0, (lk["shoulder"][1] as Color), ink, 1.8)
			Gfx.grrect(c, Rect2(-13, -27, 28, 25), 7.0, hm[0], hm[1], ink, 2.6)
			Gfx.rrect(c, Rect2(-14, -19, 5, 14), 2.0, hm[1], ink, 1.6)
			Gfx.rrect(c, Rect2(10, -17, 5.4, 12), 2.0, hm[1], ink, 1.6)
			Gfx.rrect(c, Rect2(-3, -30.5, 8, 5), 2.0, lk["plate"][1], ink, 1.6)
			c.draw_rect(Rect2(-1, -29.5, 4, 2.0), trim)
			if ly < -0.55:
				for k in 3:
					c.draw_line(Vector2(-8, -22 + k * 4.0), Vector2(8, -22 + k * 4.0), (hm[1] as Color).darkened(0.3), 1.6)
			else:
				var vy := -15.0 + ly * 1.8
				Gfx.rrect(c, Rect2(-1, vy - 3.0, 16, 6.0), 2.4, Color("0a0605"), ink, 1.8)
				c.draw_rect(Rect2(1.5, vy - 1.2, 11.5, 2.4), glow)
				for k in 3:
					c.draw_line(Vector2(3 + k * 3.6, -9.5), Vector2(3 + k * 3.6, -5), ink, 1.6)
		"crown":
			var skin: Color = lk["skin"]
			Gfx.ell(c, Vector2(1, -12), 10.6, 10.8, skin, ink, 2.2)
			Gfx.poly(c, PackedVector2Array([Vector2(-11, -12), Vector2(-9, -23), Vector2(1, -25), Vector2(11, -21), Vector2(12, -15), Vector2(4, -18), Vector2(-4, -17), Vector2(-8, -9), Vector2(-12, -4)]), lk["hair"], ink, 1.8)
			if ly >= -0.55:
				var ey := -12.0 + ly * 2.0
				c.draw_rect(Rect2(3.0, ey - 1.8, 4.2, 2.6), glow)
				c.draw_rect(Rect2(9.0, ey - 1.4, 3.4, 2.4), glow)
				c.draw_line(Vector2(5, ey + 3), Vector2(11, ey + 6), Color(glow, 0.9), 1.2)
			# aro flotante
			var by := -30.0 + sin(t * 2.2) * 1.4
			c.draw_arc(Vector2(1, by), 11.0, PI * 1.05, PI * 1.95, 14, ink, 4.6, true)
			c.draw_arc(Vector2(1, by), 11.0, PI * 1.05, PI * 1.95, 14, trim, 2.4, true)
			for k in 3:
				c.draw_circle(Vector2(1 + (k - 1) * 8.0, by - 7.0 * (1 - absf(k - 1.0) * 0.5) * 0.0 - (4.0 if k == 1 else 0.0)), 1.9, trim.lightened(0.3))
		"sniper":
			var skin: Color = lk["skin"]
			Gfx.ell(c, Vector2(1, -12), 11.4, 11.0, skin.darkened(0.1), ink, 2.2)
			var cowl := PackedVector2Array([Vector2(-13, -2), Vector2(-14, -14), Vector2(-8, -24), Vector2(2, -26), Vector2(11, -20), Vector2(13, -13), Vector2(5, -15), Vector2(-3, -10), Vector2(-3, 2)])
			Gfx.gpoly(c, cowl, (lk["scarf"] as Color) if lk["scarf"] != null else hm[0], hm[1], ink, 2.2)
			c.draw_line(Vector2(-9, -20), Vector2(-5, -8), Color(0, 0, 0, 0.3), 1.6)
			Gfx.rrect(c, Rect2(-6, -3, 22, 6), 3.0, lk["scarf"] if lk["scarf"] != null else hm[1], ink, 1.6)
			if ly >= -0.55:
				var vy := -11.0 + ly * 2.0
				Gfx.ell(c, Vector2(8, vy), 5.2, 5.2, Color("160807"), ink, 2.0)
				Gfx.ell(c, Vector2(8.6, vy), 3.4, 3.4, glow.darkened(0.2), Color(0, 0, 0, 0), 0.0)
				c.draw_circle(Vector2(7.4, vy - 1.2), 1.0, Color(1, 1, 1, 0.85))
				c.draw_line(Vector2(-10, vy - 1), Vector2(3, vy - 0.5), ink, 2.0)
		"horned":
			Gfx.grrect(c, Rect2(-11.5, -26, 24, 24), 9.0, hm[0], hm[1], ink, 2.4)
			for sx in [-1, 1]:
				var bx: float = 1.0 + 10.5 * sx
				Gfx.poly(c, PackedVector2Array([Vector2(bx - 2.5 * sx, -22), Vector2(bx + 6 * sx, -31), Vector2(bx + 12 * sx, -33), Vector2(bx + 5 * sx, -26), Vector2(bx + 2.5 * sx, -17)]), lk["trim"], ink, 1.6)
			c.draw_line(Vector2(-6, -25), Vector2(-2, -4), Color(1, 1, 1, 0.14), 2.0)
			Gfx.poly(c, PackedVector2Array([Vector2(-8, -12), Vector2(-4, -17), Vector2(14, -17), Vector2(14, -2), Vector2(2, 1), Vector2(-8, -3)]), Color("10101c"), ink, 1.6)
			if ly >= -0.55:
				var ey := -11.5 + ly * 2.0
				c.draw_colored_polygon(PackedVector2Array([Vector2(4, ey - 2.6), Vector2(11, ey - 0.8), Vector2(10.6, ey + 0.6), Vector2(4.4, ey - 0.4)]), glow)
				c.draw_line(Vector2(-1, -4), Vector2(12, -2), Color(trim, 0.9), 1.4)
		"glitch":
			var ox := 0.0
			if int(t * 4.0) % 5 == 0:
				ox = sin(t * 40.0) * 2.4
			Gfx.gpoly(c, PackedVector2Array([Vector2(-11, -13), Vector2(-9, -22), Vector2(1, -26), Vector2(12, -22), Vector2(14, -13)]), hm[0], hm[1], ink, 2.2)
			Gfx.gpoly(c, PackedVector2Array([Vector2(-11 + ox, -13), Vector2(14 + ox, -13), Vector2(12 + ox, -4), Vector2(1 + ox, -1), Vector2(-9 + ox, -4)]), hm[1], (hm[1] as Color).darkened(0.4), ink, 2.2)
			if ly >= -0.55:
				var vy := -13.0 + ly * 2.0
				c.draw_rect(Rect2(2 + ox * 0.4, vy - 3.2, 11, 2.2), glow)
				c.draw_rect(Rect2(4 - ox * 0.6, vy + 0.6, 9, 2.2), trim)
				c.draw_rect(Rect2(8, vy - 1.0, 5, 1.4), Color.WHITE)
			Gfx.poly(c, PackedVector2Array([Vector2(-14, -24), Vector2(-9, -28), Vector2(-8, -22)]), Color(glow, 0.8), ink, 1.0)
		_:   # visor_helmet (Vesper)
			Gfx.rrect(c, Rect2(-8, -5.5, 16, 6.5), 3.0, lk["scarf"] if lk["scarf"] != null else lk["suit"][1], ink, 1.8)
			if lk["scarf"] != null:
				c.draw_line(Vector2(-5, -3.5), Vector2(5, -3.5), (lk["scarf"] as Color).lightened(0.45), 1.2, true)
			var shell := Gfx.ell_pts(Vector2(1, -13), 13.0, 12.2, 26)
			Gfx.gpoly(c, shell, hm[0], hm[1], ink, 2.4)
			Gfx.poly(c, PackedVector2Array([Vector2(-8, -22), Vector2(0, -26.5), Vector2(8, -22.5), Vector2(3, -21), Vector2(-4, -20.5)]), lk["crest"], ink, 1.8)
			c.draw_line(Vector2(-5, -23), Vector2(4, -24.5), Color(1, 0.85, 0.6, 0.8), 1.2)
			Gfx.ell(c, Vector2(-5, -10), 4.6, 5.0, lk["ear"], ink, 1.8)
			Gfx.ell(c, Vector2(-5, -10), 2.2, 2.4, glow, Color(0, 0, 0, 0), 0.0)
			if ly < -0.55:
				Gfx.rrect(c, Rect2(-6, -19, 14, 10), 3.0, (hm[1] as Color).lightened(0.2), ink, 1.6)
				for k in 3:
					c.draw_line(Vector2(-3, -17 + k * 3.0), Vector2(5, -17 + k * 3.0), (hm[1] as Color).darkened(0.35), 1.4)
			else:
				var squash := clampf(1.0 - maxf(0.0, -ly) * 1.2, 0.35, 1.0)
				var vy := -12.0 + ly * 2.2
				var vh := 8.2 * squash
				var vp := PackedVector2Array([Vector2(2.5, vy - vh), Vector2(12.5, vy - vh + 1.5), Vector2(14, vy), Vector2(11.5, vy + vh * 0.8), Vector2(3.5, vy + vh)])
				Gfx.gpoly(c, vp, vz[0], vz[1], ink, 1.8)
				c.draw_line(Vector2(5, vy - vh * 0.6), Vector2(11, vy - vh * 0.6 + 0.5), Color(1, 1, 1, 0.55), 1.6, true)
				c.draw_line(Vector2(4.5, vy - vh * 0.2), Vector2(8, vy - vh * 0.2), Color(1, 1, 1, 0.25), 1.2, true)
				c.draw_line(Vector2(4.5, vy + vh * 0.35), Vector2(12, vy + vh * 0.25), vline, 2.0, true)


func _paint_head_glow(c: Part) -> void:
	var ly := float(look_q) / 10.0
	if ly < -0.55:
		return
	var g: Color = lk["glow"]
	var vy := -12.0 + ly * 2.2
	var gx := 9.0
	match lk["head"]:
		"hood":
			gx = 6.0
		"goggles":
			gx = 8.0
		"heavy":
			gx = 7.0
			vy = -15.0 + ly * 1.8
	Gfx.draw_glow(c, Vector2(gx, vy), 14.0, Color(g.r, g.g, g.b, 0.5))


func _paint_scarf(c: Part) -> void:
	var sc: Variant = lk["scarf"]
	if sc == null:
		return
	var col: Color = sc
	var n := scarf_pts.size()
	for i in range(n - 1):
		var p0 := scarf_pts[i]
		var p1 := scarf_pts[i + 1]
		var d := p1 - p0
		if d.length() < 0.01:
			continue
		var nr := Vector2(-d.y, d.x).normalized()
		var w0 := lerpf(4.2, 1.2, float(i) / float(n - 1))
		var w1 := lerpf(4.2, 1.2, float(i + 1) / float(n - 1))
		var quad := PackedVector2Array([p0 + nr * w0, p1 + nr * w1, p1 - nr * w1, p0 - nr * w0])
		c.draw_colored_polygon(quad, col if i % 2 == 0 else col.lightened(0.1))
		c.draw_line(quad[0], quad[1], Gfx.INK, 2.0, true)
		c.draw_line(quad[3], quad[2], Gfx.INK, 2.0, true)
	var tip := scarf_pts[n - 1]
	c.draw_circle(tip, 1.6, Gfx.INK)


# ----------------------------------------------------------------------------- brazos y arma
func _paint_arm_back(c: Part) -> void:
	_arm(c, Vector2(-2, -2.5), wnode.position + weapon.grip2, true)


func _paint_arm_front(c: Part) -> void:
	_arm(c, Vector2(1, 2.5), wnode.position + Vector2(0.5, 1.0), false)


func _arm(c: Part, shoulder: Vector2, hand: Vector2, back: bool) -> void:
	var ink := Gfx.INK
	var elbow := Gfx.elbow(shoulder, hand, 10.5, 9.5, 1.0)
	var sl: Array = lk["sleeve"]
	var sleeve: Color = sl[0] if not back else sl[1]
	if lk["bare_arms"]:
		sleeve = (lk["skin"] as Color) if not back else (lk["skin"] as Color).darkened(0.3)
	var width := 6.0 * (1.0 + (float(lk["w"]) - 1.0) * 0.8)
	Gfx.limb(c, PackedVector2Array([shoulder, elbow, hand]), sleeve, width, ink)
	var glow: Color = lk["glow"]
	var bp := elbow.lerp(hand, 0.55)
	c.draw_circle(bp, 3.4, glow if not back else glow.darkened(0.4))
	c.draw_circle(bp, 2.0, glow.darkened(0.8))
	var gl: Array = lk["glove"]
	c.draw_circle(hand, 4.6, ink)
	c.draw_circle(hand, 3.5, gl[0] if not back else gl[1])


func _paint_weapon(c: Part) -> void:
	WeaponArt.paint(c, weapon, heat, t)


# =====================================================================  ANIMACION
func _process(delta: float) -> void:
	if not auto:
		return
	_auto_t += delta
	# idle de menu: respira, apunta con balanceo, de vez en cuando dispara en seco
	var a := sin(_auto_t * 0.7) * 0.35
	aim = Vector2.from_angle(a - 0.05)
	face = 1.0
	if kick <= 0.0 and fmod(_auto_t, 3.4) < delta:
		kick = 1.0
		heat = 1.0
		swing = 1.0
	kick = maxf(0.0, kick - delta * 5.0)
	heat = maxf(0.0, heat - delta * 1.6)
	animate(delta)


func animate(dt: float) -> void:
	Prof.begin("rig_anim")
	_animate_impl(dt)
	Prof.end("rig_anim")


func _animate_impl(dt: float) -> void:
	t += dt
	var spd := vel.length()
	var amp := clampf(spd / SPEED_REF, 0.0, 1.0)
	var sw_w: float = lk["w"]
	var dirsign := 1.0
	if absf(vel.x) > 20.0 and signf(vel.x) != face:
		dirsign = -1.0
	walk_ph += dt * (spd * 0.082) * dirsign
	var sw := sin(walk_ph)
	var sw2 := sin(walk_ph + PI)
	var vertical := clampf(absf(vel.y) / maxf(spd, 1.0), 0.0, 1.0)
	var horiz := 1.0 - vertical * 0.6
	face_vis = move_toward(face_vis, face, dt * 16.0)
	body.scale.x = face_vis if absf(face_vis) > 0.08 else 0.08 * face
	leg_f.position = Vector2(5 * sw_w, HIP_Y - maxf(0.0, sw) * 3.2 * amp)
	leg_b.position = Vector2(-5 * sw_w, HIP_Y - maxf(0.0, sw2) * 3.2 * amp)
	leg_f.rotation = sw * 0.55 * amp * horiz
	leg_b.rotation = sw2 * 0.55 * amp * horiz
	leg_f.scale.y = 1.0 - absf(sw) * 0.12 * amp * vertical
	leg_b.scale.y = 1.0 - absf(sw2) * 0.12 * amp * vertical
	var bob := absf(sw) * 2.4 * amp
	var breath := sin(t * 2.3) * 0.9 * (1.0 - amp)
	body.position.y = -bob + breath * 0.4
	body.rotation = clampf(vel.x / SPEED_REF, -1.0, 1.0) * 0.09 * face_vis
	torso.scale = Vector2(sw_w * (1.0 + breath * 0.012), float(lk["h"]) * (1.0 + (breath * 0.035) + (kick * -0.03)))
	torso.position.y = HIP_Y
	var ly := clampf(aim.y, -1.0, 1.0)
	var q := int(round(ly * 10.0 / 2.0)) * 2
	if q != look_q:
		look_q = q
		head.queue_redraw()
		head.get_child(0).queue_redraw()
	var hbase := -34.0 - (float(lk["h"]) - 1.0) * 14.0
	head.position = Vector2(1.0 + kick * -1.0, hbase + sin(t * 2.3 + 0.6) * 0.5 * (1.0 - amp) + ly * 0.8)
	head.rotation = lerpf(head.rotation, aim.y * 0.12 * face_vis, clampf(dt * 14.0, 0.0, 1.0))
	antenna.rotation = sin(t * 3.0) * 0.08 - vel.x * 0.0012 * face_vis + sin(walk_ph * 2.0) * 0.1 * amp
	pack.position.y = -26.0 + sin(walk_ph * 2.0) * 0.8 * amp
	cape_sway = lerpf(cape_sway, clampf(-vel.x / SPEED_REF, -1.0, 1.0) * face_vis * -1.0 + sin(t * 3.0) * 0.12, clampf(dt * 6.0, 0.0, 1.0))
	if scarf.visible:
		_update_scarf(dt, amp)
	pivot.position = Vector2(0, -26.0 - bob * 0.9 + breath * 0.3)
	pivot.rotation = aim.angle()
	pivot.scale.y = face
	var kk := kick * kick
	swap_t = maxf(0.0, swap_t - dt * 5.0)
	swing = maxf(0.0, swing - dt * 7.0)
	var melee: bool = weapon.category == "melee"
	wnode.position = WEAPON_POS + Vector2(-kk * weapon.kick, 0.0) + Vector2(0, sin(walk_ph * 2.0) * 0.8 * amp + sin(t * 2.3) * 0.4 * (1.0 - amp))
	if melee:
		wnode.position += Vector2(swing * 8.0, 0)
		wnode.rotation = lerpf(-0.9, 0.8, 1.0 - swing) * (1.0 if swing > 0.0 else 0.0) + (-0.2 if swing <= 0.0 else 0.0) + swap_t * swap_t * 1.1
	else:
		wnode.rotation = -kk * 0.16 + swap_t * swap_t * 1.1
	# redibujado selectivo: lo que cambia cada frame
	_redraw_t -= dt
	arm_b.queue_redraw()
	arm_f.queue_redraw()
	wnode.queue_redraw()
	(head.get_child(0) as Part).soft_redraw()
	(torso.get_child(0) as Part).soft_redraw()
	(pack.get_child(0) as Part).soft_redraw()
	var anim_back: bool = lk["back"] in ["array", "cape", "ring", "orbs", "shards"]
	if anim_back or lk["head"] in ["crown", "hood", "glitch"] or lk["torso"] in ["robe", "glitch"]:
		pack.queue_redraw()
		if _redraw_t <= 0.0:
			_redraw_t = 0.05
			head.queue_redraw()
			torso.queue_redraw()
	if antenna.visible:
		antenna.queue_redraw()
	vis.position = -aim * kk * 1.8
	flash = maxf(0.0, flash - dt * 7.0)
	fmat.set_shader_parameter("flash", flash)
	vis.modulate.a = alpha
	var s := signf(sw)
	if s != was_step_sign and spd > 60.0:
		was_step_sign = s
		stepped.emit(amp)
	elif spd <= 60.0:
		was_step_sign = s
	if shadow != null:
		shadow.scale = Vector2(1.0 - bob * 0.01, 1.0)


func _update_scarf(dt: float, amp: float) -> void:
	var anchor := Vector2(-4.0 * face_vis, -33.0 + body.position.y * 0.5)
	scarf_pts[0] = anchor
	var rest := Vector2(-face_vis * 5.2, 1.4)
	for i in range(1, scarf_pts.size()):
		var want := scarf_pts[i - 1] + rest + Vector2(0, sin(t * 7.0 + i * 0.9) * (0.6 + amp * 1.0))
		want -= vel * 0.012 * float(i)
		scarf_pts[i] = scarf_pts[i].lerp(want, clampf(dt * (22.0 - float(i) * 2.0), 0.0, 1.0))
		var d := scarf_pts[i] - scarf_pts[i - 1]
		if d.length() > 6.5:
			scarf_pts[i] = scarf_pts[i - 1] + d.normalized() * 6.5
	scarf.queue_redraw()


# ----------------------------------------------------------------------------- muerte
func start_death(dir: Vector2) -> void:
	dead = true
	death_t = 0.0
	death_dirv = dir
	var tw := create_tween().set_parallel(true)
	tw.tween_property(head, "position", head.position + Vector2(-dir.x * 34.0, 12.0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(head, "rotation", -dir.x * 2.8, 0.5)
	tw.tween_property(pivot, "position", pivot.position + Vector2(dir.x * 22.0, 14.0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(pivot, "rotation", pivot.rotation + 2.0, 0.4)


func update_dead(dt: float) -> void:
	t += dt
	death_t += dt
	flash = maxf(0.0, flash - dt * 5.0)
	fmat.set_shader_parameter("flash", flash)
	var k := Gfx.ease_out(death_t / 0.45)
	body.rotation = -death_dirv.x * 1.45 * k
	body.position.y = 8.0 * k
	body.position.x = -death_dirv.x * 6.0 * k
	leg_f.rotation = 0.5 * k
	leg_b.rotation = -0.4 * k
	scarf.visible = death_t < 0.1 and lk["scarf"] != null
	vis.modulate.a = clampf(1.0 - (death_t - 1.6) / 0.8, 0.35, 1.0)
	arm_b.visible = false
	arm_f.visible = false
