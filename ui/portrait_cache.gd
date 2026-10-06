class_name PortraitCache
extends RefCounted
## Retratos de personaje renderizados UNA vez a una textura pequena (SubViewport que se congela despues).
## Asi la coleccion muestra N personajes sin N rigs animados vivos (barato en movil).

static var _tex: Dictionary = {}
static var _host: Node = null


static func _ensure_host() -> Node:
	if _host == null or not is_instance_valid(_host):
		_host = Router
	return _host


static func get_portrait(char_id: String, skin_id: String = "") -> Texture2D:
	var key := char_id + "|" + skin_id
	if _tex.has(key):
		return _tex[key]
	var c := Catalog.character(char_id)
	var look: Dictionary = c.look.duplicate()
	if skin_id != "" and Catalog.skins.has(skin_id):
		look.merge((Catalog.skins[skin_id] as SkinData).look, true)
	var vp := SubViewport.new()
	vp.size = Vector2i(160, 176)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	var rig := CharacterRig.new()
	vp.add_child(rig)
	rig.build(look, Catalog.weapon(c.start_weapon), false)
	rig.position = Vector2(80, 186)
	rig.scale = Vector2.ONE * 2.9
	rig.aim = Vector2.from_angle(-0.1)
	rig.animate(0.016)
	_ensure_host().add_child(vp)
	var tex := vp.get_texture()
	_tex[key] = tex
	return tex


static func draw(ci: CanvasItem, char_id: String, rect: Rect2, skin_id: String = "", tint: Color = Color.WHITE) -> void:
	var tex := get_portrait(char_id, skin_id)
	ci.draw_texture_rect(tex, rect, false, tint)
