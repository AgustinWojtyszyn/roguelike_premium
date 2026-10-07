class_name Boss
extends Enemy
## Base de jefes: varias fases por umbral de vida, barra con marcas de fase y hooks de transicion.

var boss_data: BossData
var phase: int = 0
var phase_marks_arr: Array = []


func hp_frac() -> float:
	return clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)


func title_text() -> String:
	return boss_data.display_name


func accent_color() -> Color:
	return boss_data.accent


func phase_marks() -> Array:
	return phase_marks_arr


func _on_phase_change(_new_phase: int) -> void:
	pass


func _check_phase() -> void:
	var f := hp_frac()
	var ph := 0
	for i in range(1, boss_data.phases.size()):
		if f <= boss_data.phases[i]:
			ph = i
	if ph != phase:
		phase = ph
		game.fx.sprite("bosses/boss_phase_change", hit_center(), 120.0, 260.0, 0.8, Color(1, 1, 1, 0.9), 0.0, true)
		_on_phase_change(ph)
