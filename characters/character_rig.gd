class_name CharacterRig
extends Node2D
## Presentacion del jugador. Desde la reconstruccion Premium el jugador es EXCLUSIVAMENTE sprite/pre-render.
## No existe fallback de cuerpo procedural: si un perfil Premium aun no esta listo se muestra un placeholder temporal.
## La logica de juego, arma, recoil y muzzle siguen siendo propiedad de Player/WeaponRuntime.

signal stepped(strength: float)

const SPEED_REF := 262.0
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
var swing: float = 0.0
var t: float = 0.0
var dead := false
var death_t: float = 0.0
var death_dirv := Vector2.RIGHT
var auto := false

# Compatibilidad de API con Home/Collection/Player. No vuelven a representar partes corporales.
var vis: Node2D
var body: Node2D
var pivot: Node2D
var wnode: Part
var spr: SpriteActor
var shadow: Node2D
var scarf_pts: Array[Vector2] = []

## Perfiles Premium pre-renderizados: el arma se ancla al agarre (hueso handslot del rig fuente) de CADA frame y la mano
## que la sostiene se redibuja encima del arma. No hay offsets visuales manuales.
var grip_rig := false
var hand_spr: Sprite2D
var _grip_rot := 0.0
var _atk_active := false
var _behind := false
var sprite_mode := false
var is_placeholder := false
var sprof: Dictionary = {}
var fmat: ShaderMaterial
var _placeholder: Sprite2D
var _hurt_t := 0.0
var _prev_flash := 0.0
var _last_step_idx := -1
var _anchor_cur := Vector2.ZERO
var _anchor_init := false
var _last_heat := -1.0
var _prev_spd := 0.0
var _auto_t := 0.0


static func resolve_look(look: Dictionary) -> Dictionary:
	return look.duplicate(true)


func build(look: Dictionary, w: WeaponData, _show_shadow: bool = true) -> void:
	lk = resolve_look(look)
	weapon = w
	sprite_mode = false
	is_placeholder = false
	spr = null
	sprof = {}
	_anchor_init = false

	vis = Node2D.new()
	fmat = Gfx.flash_material()
	vis.material = fmat
	add_child(vis)

	body = Node2D.new()
	body.use_parent_material = true
	vis.add_child(body)

	var vp := VisualProfiles.character(str(lk.get("visual", "")))
	var profile_ok := not vp.is_empty() and bool(vp.get("weapon_compatible", false)) and VisualProfiles.sprites_enabled()
	if profile_ok:
		sprof = vp
		spr = SpriteActor.create(body, vp)
		if spr != null:
			sprite_mode = true
			if vp.has("tint"):
				spr.self_modulate = vp["tint"]

	if not sprite_mode:
		_build_placeholder()

	pivot = Node2D.new()
	pivot.use_parent_material = true
	pivot.position = _anchor_for("south") if sprite_mode else Vector2(0, -32)
	vis.add_child(pivot)
	wnode = Part.make(pivot, _paint_weapon, Vector2.ZERO)
	var ws := float(sprof.get("weapon_scale", VisualProfiles.CHAR_WEAPON_SCALE)) if sprite_mode else VisualProfiles.CHAR_WEAPON_SCALE
	wnode.scale = Vector2.ONE * ws * _k()
	_last_heat = heat
	grip_rig = sprite_mode and spr != null and str(sprof.get("grip_mode", "")) == "rig" and spr.aset.has_grips()
	if grip_rig:
		hand_spr = Sprite2D.new()
		hand_spr.use_parent_material = true
		hand_spr.centered = true
		hand_spr.texture_filter = spr.texture_filter
		hand_spr.visible = false
		vis.add_child(hand_spr)
		_atk_active = false
		_behind = false


func _build_placeholder() -> void:
	is_placeholder = true
	_placeholder = Sprite2D.new()
	_placeholder.texture = load("res://assets/dev/player_placeholder.png") as Texture2D
	_placeholder.centered = true
	_placeholder.position = Vector2(0, -36)
	_placeholder.scale = Vector2.ONE * 0.72
	_placeholder.use_parent_material = true
	_placeholder.modulate = lk.get("glow", Color("6cc4ff"))
	body.add_child(_placeholder)


func _anchor_for(d: String) -> Vector2:
	if not sprite_mode:
		return Vector2(0, -32)
	var a: Variant = sprof.get("weapon_anchor", Vector2(0, -28))
	if a is Dictionary:
		return (a as Dictionary).get(d, (a as Dictionary).get("default", Vector2(0, -28))) * _k()
	return (a as Vector2) * _k()


func _k() -> float:
	if not sprite_mode:
		return 1.0
	return float(sprof.get("height", 64.0)) / maxf(1.0, float(sprof.get("anchor_ref", sprof.get("height", 64.0))))


func menu_k() -> float:
	return float(sprof.get("menu_k", 1.0)) if sprite_mode else 0.85


func set_weapon(w: WeaponData) -> void:
	weapon = w
	swap_t = 1.0
	heat = 0.0
	if wnode != null:
		wnode.queue_redraw()


func muzzle_world() -> Vector2:
	if pivot == null or wnode == null:
		return global_position + Vector2(18, -28)
	return pivot.to_global(wnode.position + weapon.muzzle * wnode.scale.x)


func hit_center_local() -> Vector2:
	return Vector2(0, -26)


func _paint_weapon(c: Part) -> void:
	WeaponArt.paint(c, weapon, heat, t)


func _process(delta: float) -> void:
	if not auto:
		return
	_auto_t += delta
	aim = Vector2.from_angle(sin(_auto_t * 0.7) * 0.28 - 0.05)
	face = 1.0
	if kick <= 0.0 and fmod(_auto_t, 3.4) < delta:
		kick = 1.0
		heat = 1.0
	kick = maxf(0.0, kick - delta * 5.0)
	heat = maxf(0.0, heat - delta * 1.6)
	animate(delta)


func animate(dt: float) -> void:
	if dead:
		return
	t += dt
	var spd := vel.length()
	var amp := clampf(spd / SPEED_REF, 0.0, 1.0)
	var moving := spd > 25.0
	face_vis = move_toward(face_vis, face, dt * 16.0)

	if sprite_mode and spr != null:
		_animate_sprite(dt, spd, amp, moving)
	else:
		_animate_placeholder(dt, spd, amp, moving)

	var kk := kick * kick
	swap_t = maxf(0.0, swap_t - dt * 5.0)
	swing = maxf(0.0, swing - dt * 7.0)
	pivot.rotation = _grip_rot if grip_rig else aim.angle()
	pivot.scale.y = (1.0 if cos(_grip_rot) >= 0.0 else -1.0) if grip_rig else face
	var melee := weapon != null and weapon.category == "melee"
	wnode.position = Vector2(-kk * weapon.kick * wnode.scale.x, 0.0)
	if grip_rig:
		wnode.rotation = (0.0 if melee else -kk * 0.16) + swap_t * swap_t * 1.1
	elif melee:
		wnode.position += Vector2(swing * 8.0, 0)
		wnode.rotation = lerpf(-0.9, 0.8, 1.0 - swing) * (1.0 if swing > 0.0 else 0.0) + (-0.2 if swing <= 0.0 else 0.0) + swap_t * swap_t * 1.1
	else:
		wnode.rotation = -kk * 0.16 + swap_t * swap_t * 1.1

	if heat != _last_heat or heat > 0.01:
		_last_heat = heat
		wnode.queue_redraw()
	vis.position = -aim * kk * 1.8
	flash = maxf(0.0, flash - dt * 7.0)
	fmat.set_shader_parameter("flash", flash)
	vis.modulate.a = alpha


func _animate_sprite(dt: float, spd: float, amp: float, moving: bool) -> void:
	var aset := spr.aset
	var base_anim := "walk" if moving else ("aim" if spr.has_logical("aim") else "idle")
	_hurt_t = maxf(0.0, _hurt_t - dt)
	if flash > _prev_flash + 0.5 and spr.has_logical("hurt"):
		_hurt_t = 0.24
		_atk_active = false
		spr.play("hurt", true, false)
	_prev_flash = flash
	if grip_rig and swing > 0.99 and _hurt_t <= 0.0 and spr.has_logical("attack"):
		_atk_active = true
		spr.set_dir_vec(aim)
		spr.play("attack", true, false)
	if _atk_active and spr.finished:
		_atk_active = false
	if _hurt_t <= 0.0 and not _atk_active:
		spr.play(base_anim)

	var cand := aset.best_dir(spr.anim, aim)
	if _atk_active:
		cand = spr.dir
	if cand != spr.dir:
		var cur: Vector2 = AnimSet.DIR_VEC.get(spr.dir, Vector2.DOWN)
		var nw: Vector2 = AnimSet.DIR_VEC.get(cand, Vector2.DOWN)
		if not aset.dirs_of(spr.anim).has(spr.dir) or aim.dot(nw) > aim.dot(cur) + 0.12:
			spr.set_dir_vec(nw)

	if _atk_active:
		spr.rate = 1.0
	elif moving:
		var nfr := float(maxi(1, aset.frame_count(spr.anim, spr.dir)))
		var afps := maxf(1.0, spr.fps_of(spr.anim))
		spr.rate = clampf(spd / (0.85 * float(sprof.get("height", 64.0))) * nfr / afps, 0.45, 30.0 / afps)
	else:
		spr.rate = 1.0
	spr.reverse = false
	spr.tick(dt)

	if moving:
		var n := maxi(1, aset.frame_count(spr.anim, spr.dir))
		var half := n / 2
		if (spr.idx == 0 or spr.idx == half) and spr.idx != _last_step_idx:
			_last_step_idx = spr.idx
			stepped.emit(amp)
		elif spr.idx != 0 and spr.idx != half:
			_last_step_idx = -1
	else:
		_last_step_idx = -1

	if grip_rig:
		_grip_update()
		return
	var tgt := _anchor_for(spr.dir)
	if not _anchor_init:
		_anchor_cur = tgt
		_anchor_init = true
	_anchor_cur = _anchor_cur.lerp(tgt, clampf(dt * 18.0, 0.0, 1.0))
	var bob := -absf(sin(spr.phase() * TAU)) * 1.6 * amp
	pivot.position = _anchor_cur + Vector2(0, bob)


## Coloca arma y mano desde los metadatos de agarre del frame actual (derivados del rig fuente).
func _grip_update() -> void:
	var g: Array = spr.aset.grip(spr.anim, spr.dir, spr.idx)
	if g.size() < 6:
		return
	var sc := spr.scale.x
	var gp: Vector2 = spr.position + Vector2(float(g[0]), float(g[1])) * sc
	pivot.position = gp
	var rot := aim.angle()
	if spr.aset.weapon_mode(spr.anim) == "rig":
		var nominal: float = (AnimSet.DIR_VEC.get(spr.dir, Vector2.RIGHT) as Vector2).angle()
		rot = deg_to_rad(float(g[2])) + angle_difference(nominal, aim.angle())
	_grip_rot = rot
	var behind := int(g[5]) == 1 and bool(sprof.get("weapon_behind", false))
	if behind != _behind:
		_behind = behind
		vis.move_child(pivot, 0 if behind else body.get_index() + 1)
	var hf: Array = spr.aset.hand_frames(spr.anim, spr.dir)
	if hf.is_empty():
		hand_spr.visible = false
		return
	hand_spr.visible = true
	hand_spr.texture = hf[clampi(spr.idx, 0, hf.size() - 1)]
	hand_spr.position = gp
	hand_spr.scale = Vector2(sc, sc)


func _animate_placeholder(dt: float, spd: float, amp: float, moving: bool) -> void:
	if _placeholder == null:
		return
	var bob := (absf(sin(t * 8.0)) * 2.0 * amp) if moving else sin(t * 2.3) * 0.6
	_placeholder.position.y = -36.0 - bob
	_placeholder.rotation = clampf(vel.x / SPEED_REF, -1.0, 1.0) * 0.06
	pivot.position = Vector2(0, -32.0 - bob * 0.6)
	if moving and fmod(t, 0.34) < dt:
		stepped.emit(amp)


func start_death(dir: Vector2) -> void:
	dead = true
	death_t = 0.0
	death_dirv = dir
	if sprite_mode and spr != null and spr.has_logical("death"):
		spr.set_dir_vec(dir)
		spr.play("death", true, false)
	_atk_active = false
	if pivot != null and not grip_rig:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(pivot, "position", pivot.position + Vector2(dir.x * 18.0, 12.0), 0.35)
		tw.tween_property(pivot, "rotation", pivot.rotation + 1.8, 0.35)


func update_dead(dt: float) -> void:
	t += dt
	death_t += dt
	if sprite_mode and spr != null and spr.has_logical("death"):
		spr.tick(dt)
		if grip_rig:
			_grip_update()
			pivot.rotation = _grip_rot
			pivot.scale.y = 1.0 if cos(_grip_rot) >= 0.0 else -1.0
			# el arma se suelta con la mano de la caida y se desvanece (no queda flotando junto al cuerpo)
			var wa := clampf(1.0 - (death_t - 0.1) / 0.3, 0.0, 1.0)
			pivot.modulate.a = wa
			hand_spr.modulate.a = wa
	else:
		body.rotation = -death_dirv.x * minf(1.2, death_t * 2.4)
		body.position.y = minf(12.0, death_t * 16.0)
	flash = maxf(0.0, flash - dt * 5.0)
	fmat.set_shader_parameter("flash", flash)
	vis.modulate.a = clampf(1.0 - (death_t - 1.4) / 0.8, 0.25, 1.0)
