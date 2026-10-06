class_name EncounterDef
extends Resource
## Encuentro: oleadas [[enemy_id, delay], ...]. La amenaza total sirve para elegir segun la etapa.

@export var id: String = ""
@export var chapters: Array[String] = []
@export var tier: int = 1                       # 1 (suave) .. 4 (duro)
@export var waves: Array = []
@export var tags: Array[String] = []

func threat(lookup: Callable) -> float:
	var t := 0.0
	for w in waves:
		for e in w:
			t += float(lookup.call(e[0]))
	return t
