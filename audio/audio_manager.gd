extends Node
## Autoload "AudioMgr": buses Music / SFX / UI, pools de voces acotados y sintesis en un hilo de fondo.
## - Solo 12 voces SFX + 4 UI + 2 de musica: nunca se crean AudioStreamPlayer por disparo.
## - Los streams se sintetizan en un hilo (no bloquea el arranque) y quedan cacheados.

const SFX_VOICES := 12
const UI_VOICES := 4

var streams: Dictionary = {}
var music_streams: Dictionary = {}
var _variants: Dictionary = {}       # nombre base -> Array[AudioStreamWAV] (base + variantes "~N")
var _last_variant: Dictionary = {}
var _voice_name: Dictionary = {}     # AudioStreamPlayer -> nombre que suena (limite de polifonia por sonido)
const MUSIC_CACHE := 3                # pistas de musica en memoria a la vez (menu + actual + siguiente)
## Voces simultaneas maximas por sonido: evita la "masa de ruido" de armas automaticas y cascadas de impactos.
const MAX_POLY := {"smg": 3, "pistol": 3, "rifle": 3, "minigun": 3, "flame": 2, "hit": 3, "tink": 3, "wall": 2, "step": 2, "coin": 3,
	"claws": 3, "slash": 3, "bolt": 3, "bounce": 3, "zap": 3, "swarm": 2, "rocket": 3, "plasma": 3, "tick": 2, "die": 3, "break": 3}
const PRIORITY := ["boom", "roar", "slam", "player_die", "victory", "defeat", "levelup", "reward", "hurt", "shield_break", "railbeam", "maul", "sniper", "die_big"]
var _sfx_pool: Array[AudioStreamPlayer] = []
var _ui_pool: Array[AudioStreamPlayer] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_active: AudioStreamPlayer
var _hum: AudioStreamPlayer
var _last_play: Dictionary = {}
var _thread: Thread
var _jobs: Array = []
var _jobs_mutex := Mutex.new()
var _music_want := ""
var _music_cur := ""
var _music_on := true
var _sfx_on := true
var _hum_want := false
var _built := {}
var _rr := 0
var _fade_t := 1.0

var bus_music := -1
var bus_sfx := -1
var bus_ui := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_sfx_pool.append(p)
	for i in UI_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = &"UI"
		add_child(p)
		_ui_pool.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	for m in [_music_a, _music_b]:
		m.bus = &"Music"
		m.volume_db = -80.0
		add_child(m)
	_music_active = _music_a
	_hum = AudioStreamPlayer.new()
	_hum.bus = &"SFX"
	_hum.volume_db = -20.0
	add_child(_hum)
	apply_settings()
	_start_thread()


func _setup_buses() -> void:
	for n in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(n) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, n)
			AudioServer.set_bus_send(idx, &"Master")
	bus_music = AudioServer.get_bus_index("Music")
	bus_sfx = AudioServer.get_bus_index("SFX")
	bus_ui = AudioServer.get_bus_index("UI")
	# limitador en Master: la suma de armas + impactos + musica nunca recorta
	var has_lim := false
	for i in AudioServer.get_bus_effect_count(0):
		if AudioServer.get_bus_effect(0, i) is AudioEffectLimiter:
			has_lim = true
	if not has_lim:
		var lim := AudioEffectLimiter.new()
		lim.ceiling_db = -1.0
		lim.threshold_db = -4.0
		AudioServer.add_bus_effect(0, lim)


## Lee preferencias del perfil y las aplica a los buses.
func apply_settings() -> void:
	var s: Dictionary = Profile.p.data["settings"]
	_music_on = bool(s.get("music", true))
	_sfx_on = bool(s.get("sfx", true))
	AudioServer.set_bus_mute(bus_music, not _music_on)
	AudioServer.set_bus_mute(bus_sfx, not _sfx_on)
	AudioServer.set_bus_mute(bus_ui, not _sfx_on)
	AudioServer.set_bus_volume_db(bus_music, linear_to_db(clampf(float(s.get("music_vol", 0.8)), 0.0001, 1.0)) - 4.0)
	AudioServer.set_bus_volume_db(bus_sfx, linear_to_db(clampf(float(s.get("sfx_vol", 1.0)), 0.0001, 1.0)))
	AudioServer.set_bus_volume_db(bus_ui, linear_to_db(clampf(float(s.get("sfx_vol", 1.0)), 0.0001, 1.0)) - 2.0)


func set_music_enabled(on: bool) -> void:
	Profile.p.set_setting("music", on)
	apply_settings()


func set_sfx_enabled(on: bool) -> void:
	Profile.p.set_setting("sfx", on)
	apply_settings()


func music_enabled() -> bool:
	return _music_on


func sfx_enabled() -> bool:
	return _sfx_on


# ------------------------------------------------------------------ sintesis en hilo
func _start_thread() -> void:
	var order: Array = SfxBank.recipes().keys()
	# lo critico del menu y del combate primero
	var first := ["ui_click", "ui_confirm", "ui_back", "ui_open", "ui_error", "coin", "pistol", "smg", "hit", "swap", "hurt", "die", "step", "rifle", "maul"]
	for f in first:
		order.erase(f)
	order = first + order
	_jobs_mutex.lock()
	for n in order:
		_jobs.append(["sfx", n])
	_jobs.insert(2, ["music", "menu"])
	_jobs.insert(order.size() - 8, ["music", "ch1"])
	_jobs_mutex.unlock()
	_thread = Thread.new()
	_thread.start(_worker)


func _worker() -> void:
	var recipes := SfxBank.recipes()
	while true:
		_jobs_mutex.lock()
		var job: Variant = null
		if not _jobs.is_empty():
			job = _jobs.pop_front()
		_jobs_mutex.unlock()
		if job == null:
			OS.delay_msec(40)
			if _stop:
				return
			continue
		if job[0] == "sfx":
			var s: AudioStreamWAV = (recipes[job[1]] as Callable).call()
			_on_sfx.call_deferred(job[1], s)
		else:
			var m: AudioStreamWAV = SfxBank.music(job[1], func(): return _stop)
			if m != null:
				_on_music.call_deferred(job[1], m)


var _stop := false


func _on_sfx(name: String, s: AudioStreamWAV) -> void:
	streams[name] = s
	var base := name.get_slice("~", 0)
	if not _variants.has(base):
		_variants[base] = []
	(_variants[base] as Array).append(s)
	if name == "hum" and _hum_want:
		_start_hum()


func _on_music(id: String, s: AudioStreamWAV) -> void:
	music_streams[id] = s
	# memoria acotada: conserva el menu, la pista pedida y como mucho MUSIC_CACHE en total
	while music_streams.size() > MUSIC_CACHE:
		var drop := ""
		for k in music_streams:
			if k != id and k != _music_cur and k != _music_want and k != "menu":
				drop = k
				break
		if drop == "":
			break
		music_streams.erase(drop)
		_built.erase(drop)
	if _music_want == id and _music_cur != id:
		_crossfade_to(id)


func _exit_tree() -> void:
	_stop = true
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()


func request_music_build(id: String) -> void:
	if music_streams.has(id) or _built.has(id):
		return
	_built[id] = true
	_jobs_mutex.lock()
	_jobs.append(["music", id])
	_jobs_mutex.unlock()


# ------------------------------------------------------------------ reproduccion
func play(name: String, vol: float = 0.0, pitch: float = 1.0, jitter: float = 0.07, min_gap: float = 0.0) -> void:
	if not _sfx_on or not streams.has(name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if min_gap > 0.0 and now - float(_last_play.get(name, -10.0)) < min_gap:
		return
	var cap: int = MAX_POLY.get(name, 5)
	if cap < 99 and not PRIORITY.has(name):
		var live := 0
		for pl in _sfx_pool:
			if pl.playing and _voice_name.get(pl, "") == name:
				live += 1
		if live >= cap:
			return
	_last_play[name] = now
	var p := _free_voice(_sfx_pool)
	p.stream = _pick(name)
	p.volume_db = vol
	p.pitch_scale = pitch * (1.0 + randf_range(-jitter, jitter))
	_voice_name[p] = name
	p.play()


## Elige una variante distinta de la ultima reproducida.
func _pick(name: String) -> AudioStream:
	var arr: Array = _variants.get(name, [])
	if arr.size() <= 1:
		return streams[name]
	var i := randi() % arr.size()
	if i == int(_last_variant.get(name, -1)):
		i = (i + 1) % arr.size()
	_last_variant[name] = i
	return arr[i]


## Sonido de interfaz (bus UI, funciona en pausa).
func ui(name: String, vol: float = 0.0, pitch: float = 1.0) -> void:
	if not _sfx_on or not streams.has(name):
		return
	var p := _free_voice(_ui_pool)
	p.stream = streams[name]
	p.volume_db = vol
	p.pitch_scale = pitch
	p.play()


func _free_voice(pool: Array[AudioStreamPlayer]) -> AudioStreamPlayer:
	for p in pool:
		if not p.playing:
			return p
	_rr = (_rr + 1) % pool.size()
	return pool[_rr]


func play_music(id: String) -> void:
	_music_want = id
	if _music_cur == id:
		return
	if music_streams.has(id):
		_crossfade_to(id)
	else:
		request_music_build(id)


func stop_music() -> void:
	_music_want = ""
	_music_cur = ""
	_fade_t = 0.0
	_music_other().stop()


func _music_other() -> AudioStreamPlayer:
	return _music_b if _music_active == _music_a else _music_a


func _crossfade_to(id: String) -> void:
	var nxt := _music_other()
	nxt.stream = music_streams[id]
	nxt.volume_db = -60.0
	nxt.play()
	_music_cur = id
	var prev := _music_active
	_music_active = nxt
	_fade_t = 0.0
	_fade_from = prev


var _fade_from: AudioStreamPlayer


func _process(delta: float) -> void:
	if _fade_t < 1.0 and _music_active != null:
		_fade_t = minf(1.0, _fade_t + delta / 1.2)
		_music_active.volume_db = lerpf(-50.0, -6.0, _fade_t) if _music_cur != "" else -80.0
		if _fade_from != null:
			_fade_from.volume_db = lerpf(-6.0, -60.0, _fade_t)
			if _fade_t >= 1.0:
				_fade_from.stop()
				_fade_from = null


func start_hum() -> void:
	_hum_want = true
	_start_hum()


func _start_hum() -> void:
	if streams.has("hum") and not _hum.playing:
		_hum.stream = streams["hum"]
		_hum.play()


func stop_hum() -> void:
	_hum_want = false
	_hum.stop()
