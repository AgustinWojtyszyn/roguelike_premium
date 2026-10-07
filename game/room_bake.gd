class_name RoomBake
extends Node2D
## Hornea las capas ESTATICAS de la sala (suelo, muros, luces fijas) a una textura una sola vez.
## Antes se redibujaban ~2000 draw calls por frame; ahora son 1-2 sprites. Se re-hornea al reanudar la app (Android).

var room: Room
var vp: SubViewport
var sprite: Sprite2D
var rect := Rect2()
var bake_scale := 1.5
var _layers: Array[Node2D] = []


static func choose_scale(size: Vector2) -> float:
	var s := 2.0 if not OS.has_feature("mobile") else 1.5
	var max_dim := maxf(size.x, size.y)
	while max_dim * s > 4000.0 and s > 0.6:
		s -= 0.1
	while size.x * size.y * s * s > 7.0e6 and s > 0.6:
		s -= 0.1
	return s


func setup(r: Room, region: Rect2) -> void:
	room = r
	rect = region
	bake_scale = choose_scale(region.size)
	vp = SubViewport.new()
	vp.size = Vector2i(int(ceil(region.size.x * bake_scale)), int(ceil(region.size.y * bake_scale)))
	vp.transparent_bg = false
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	add_child(vp)
	var root := Node2D.new()
	root.scale = Vector2.ONE * bake_scale
	root.position = -region.position * bake_scale
	vp.add_child(root)
	# fondo = color del vacio del tema
	var bg := Layer.new()
	bg.mode = 9
	bg.room = room
	bg.z_index = -40
	bg.region = region
	root.add_child(bg)
	for spec in [[0, -30, false], [4, -29, false], [1, -28, true]]:
		var l := Room.Layer.new()
		l.room = room
		l.mode = spec[0]
		l.z_index = spec[1]
		if spec[2]:
			l.material = Gfx.add_material()
		root.add_child(l)
		_layers.append(l)
	sprite = Sprite2D.new()
	sprite.texture = vp.get_texture()
	sprite.centered = false
	sprite.position = region.position
	sprite.scale = Vector2.ONE / bake_scale
	sprite.z_index = -30
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)


func rebake() -> void:
	if vp != null:
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		rebake()


class Layer extends Node2D:
	var room: Room
	var mode := 9
	var region := Rect2()
	func _draw() -> void:
		draw_rect(region, room.theme.void_col)
