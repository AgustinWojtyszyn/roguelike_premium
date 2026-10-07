extends Node
## Autoload "Profile": dueño del PlayerProfile y de la persistencia (carga al inicio, guardado diferido).
## Acceso: Profile.p (PlayerProfile).

signal saved

var p: PlayerProfile
var path: String = SaveStore.PATH
var _save_timer := 0.0
var _loaded_ok := false


func _init() -> void:
	p = PlayerProfile.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Boot.has_flag("fresh"):
		path = "user://profile_test.json"
	reload()
	if Boot.has_flag("unlockall"):
		for id in Catalog.char_order:
			p.unlock_character(id)
		for id in Catalog.chapter_order:
			p.unlock_chapter(id)


func reload() -> void:
	var raw := SaveStore.read(path)
	if raw.is_empty():
		p = PlayerProfile.new()
		p.data["created"] = int(Time.get_unix_time_from_system())
		_loaded_ok = false
	else:
		raw = SaveStore.migrate(raw, SaveStore.default_migrations())
		p = PlayerProfile.new(raw)
		_loaded_ok = true
	p.changed.connect(_on_changed)


func _on_changed() -> void:
	_save_timer = 0.6


func _process(delta: float) -> void:
	if _save_timer > 0.0:
		_save_timer -= delta
		if _save_timer <= 0.0:
			save_now()


func save_now() -> void:
	_save_timer = 0.0
	if SaveStore.write(path, p.data):
		p.dirty = false
		saved.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if p != null and p.dirty:
			save_now()
