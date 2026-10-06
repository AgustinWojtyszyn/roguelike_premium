class_name SeasonData
extends Resource
## Temporada / pase de batalla. Las recompensas son listas de {"level": n, "type": ..., ...}.

@export var id: String = "s1"
@export var display_name: String = ""
@export var number: int = 1
@export var theme_color: Color = Color("27e0cc")
@export var levels: int = 30
@export var xp_base: int = 100
@export var xp_step: int = 12
@export var free_rewards: Array = []
@export var premium_rewards: Array = []


func xp_for_level(lv: int) -> int:
	return xp_base + xp_step * maxi(0, lv - 1)


func total_xp_for(level: int) -> int:
	var t := 0
	for i in range(1, level + 1):
		t += xp_for_level(i)
	return t
