extends RefCounted
## Cadencia y energia de TODAS las armas: independiente de FPS, un cobro por descarga, sin disparos gratis ni dobles.

const SIM_T := 3.0


func _make_game(t) -> Game:
	Profile.path = "user://test_profile_run.json"
	Profile.reload()
	Boot.args = {"god": "1", "seed": "7", "idle": "1", "bot": "1"}
	Router.params = {}
	var g: Game = (load("res://scenes/run.tscn") as PackedScene).instantiate()
	t.root.add_child(g)
	return g


## Simula `secs` con el gatillo apretado a `fps`; devuelve {shots, spent}. Sin regeneracion (se llama a update directamente).
func _hold(g: Game, wd: WeaponData, fps: float, secs: float, energy: float) -> Dictionary:
	var p := g.player
	var rt := WeaponRuntime.new(p, wd)
	p.slots[0] = rt
	p.cur = 0
	p.fire_lock = 0.0
	p.max_energy = maxf(p.max_energy, energy)
	p.energy = energy
	p.aim = Vector2.RIGHT
	var dt := 1.0 / fps
	var n := int(round(secs * fps))
	for i in n:
		rt.update(dt, true)
		g.bullets.clear_all()
	return {"shots": rt.shots, "spent": energy - p.energy, "rt": rt}


func run(t) -> void:
	var g := _make_game(t)
	for i in 20:
		await t.process_frame
	g.input.auto_walk = null
	var p := g.player
	var rates := {}
	var firearms := 0
	for wid in Catalog.weapons:
		var wd: WeaponData = Catalog.weapons[wid]
		rates[snappedf(wd.rate, 0.001)] = true
		var melee := wd.category == "melee"
		# ---- contrato de coste
		if not melee:
			firearms += 1
			t.check(wd.energy_cost > 0.0, "%s: toda arma de fuego consume energia" % wid)
			var per_shot_t := wd.rate + (float(wd.behavior.get("burst", 1)) * float(wd.behavior.get("burst_gap", 0.0)) if wd.behavior.has("burst") else 0.0)
			if wd.behavior.has("charge"):
				per_shot_t = maxf(per_shot_t, float(wd.behavior["charge"]))
			var eps: float = wd.energy_cost / maxf(per_shot_t, 0.045)
			t.check(eps >= 1.5 and eps <= 16.0, "%s: gasto sostenido %.1f EN/s dentro de [1.5, 16]" % [wid, eps])
		# ---- independencia de FPS (cadencia) y cobro exacto
		var r60 := _hold(g, wd, 60.0, SIM_T, 250.0)
		var r30 := _hold(g, wd, 30.0, SIM_T, 250.0)
		var r144 := _hold(g, wd, 144.0, SIM_T, 250.0)
		t.check(r60["shots"] > 0, "%s dispara (%d)" % [wid, r60["shots"]])
		t.check(absi(int(r60["shots"]) - int(r30["shots"])) <= 2 and absi(int(r60["shots"]) - int(r144["shots"])) <= 2,
			"%s: disparos independientes del FPS (30/60/144 = %d/%d/%d)" % [wid, r30["shots"], r60["shots"], r144["shots"]])
		if not wd.behavior.has("spool") and not wd.behavior.has("charge") and wd.behavior.get("semi", false) == false:
			var expect := SIM_T / (wd.rate / maxf(0.25, p.rate_mult()))
			t.check(absf(float(r60["shots"]) - expect) <= 2.0, "%s: %d disparos ~ %.1f esperados por su cadencia" % [wid, r60["shots"], expect])
		var cost := wd.energy_cost * p.energy_cost_mult()
		t.check(absf(float(r60["spent"]) - float(r60["shots"]) * cost) < 0.01, "%s: energia gastada %.2f == disparos x coste %.2f" % [wid, r60["spent"], float(r60["shots"]) * cost])
		t.check(p.energy >= 0.0 and p.energy <= p.max_energy, "%s: energia valida" % wid)
		# ---- sin energia no dispara y no cobra
		var dry := _hold(g, wd, 60.0, 1.0, cost * 0.5 if cost > 0.0 else 0.0)
		if cost > 0.0:
			t.eq(dry["shots"], 0, "%s: sin energia suficiente no dispara" % wid)
			t.check(absf(float(dry["spent"])) < 0.0001, "%s: un intento rechazado no consume" % wid)
		# ---- un intento con cooldown activo no cobra: dt=0 repetido solo cuenta el primer disparo
		if not wd.behavior.has("charge"):
			var rt := WeaponRuntime.new(p, wd)
			p.slots[0] = rt
			p.energy = 250.0
			p.fire_lock = 0.0
			rt.update(0.0, true)
			rt.update(0.0, true)
			rt.update(0.0, true)
			t.check(rt.shots <= 1, "%s: con cooldown activo no hay disparos extra (%d)" % [wid, rt.shots])
			g.bullets.clear_all()
	t.check(rates.size() >= 12, "las armas tienen cadencias propias (%d valores distintos)" % rates.size())
	t.eq(firearms, 16, "16 armas de fuego + 2 cuerpo a cuerpo")

	# ---- semiautomatica: mantener no repite, soltar y apretar si
	var aguja: WeaponData = Catalog.weapon("aguja")
	var rt := WeaponRuntime.new(p, aguja)
	p.slots[0] = rt
	p.energy = 250.0
	p.fire_lock = 0.0
	for i in 180:
		rt.update(1.0 / 60.0, true)
	t.eq(rt.shots, 1, "semiautomatica: mantener el gatillo = 1 disparo")
	var presses := 0
	for i in 240:
		rt.update(1.0 / 60.0, i % 30 < 15)
	presses = rt.shots - 1
	t.check(presses >= 4, "semiautomatica: pulsaciones sucesivas disparan segun su cadencia (%d)" % presses)
	g.bullets.clear_all()

	# ---- cambio rapido de armas: no suma cadencias
	p.slots[0] = WeaponRuntime.new(p, Catalog.weapon("pulsar"))
	p.slots[1] = WeaponRuntime.new(p, Catalog.weapon("chispa"))
	p.cur = 0
	p.fire_lock = 0.0
	p.energy = 250.0
	var single := 0
	for i in 120:   # 2 s con una sola arma
		p.slots[p.cur].update(1.0 / 60.0, true)
		p.fire_lock = maxf(0.0, p.fire_lock - 1.0 / 60.0)
	single = p.slots[0].shots
	p.slots[0] = WeaponRuntime.new(p, Catalog.weapon("pulsar"))
	p.slots[1] = WeaponRuntime.new(p, Catalog.weapon("chispa"))
	p.cur = 0
	var total := 0
	for i in 120:
		if i % 4 == 0:
			p.swap_weapon(true)   # cambio de arma cada 4 frames
		p.fire_lock = maxf(0.0, p.fire_lock - 0.0)
		for k in p.slots.size():
			p.slots[k].update(1.0 / 60.0, k == p.cur and p.fire_lock <= 0.0)
		p.fire_lock = maxf(0.0, p.fire_lock - 1.0 / 60.0)
	total = p.slots[0].shots + p.slots[1].shots
	t.check(total < single, "alternar armas con cambios constantes (%d disparos) no supera disparar con una sola (%d)" % [total, single])
	g.bullets.clear_all()

	# ---- cobro central: valores invalidos nunca corrompen la energia
	p.energy = 50.0
	t.check(not p.spend_energy(INF), "spend_energy rechaza coste infinito")
	t.check(not p.spend_energy(NAN), "spend_energy rechaza NaN")
	t.check(p.spend_energy(20.0) and absf(p.energy - 30.0) < 0.001, "spend_energy cobra una vez")
	t.check(not p.spend_energy(31.0) and absf(p.energy - 30.0) < 0.001, "spend_energy no cobra si falta")
	p.energy = 5.0
	p.energy_idle = 5.0
	p._update_resources(1.0)
	t.check(p.energy > 5.0 + 6.0, "sin disparar la energia se recupera rapido (%.1f)" % p.energy)
	p.energy = 5.0
	p.energy_idle = 0.0
	p._update_resources(0.2)
	t.check(p.energy < 5.0 + 0.2 * 4.0, "disparando la recuperacion es lenta (%.2f)" % p.energy)
	g.queue_free()
