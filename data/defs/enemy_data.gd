class_name EnemyData
extends Resource
## Definicion de un enemigo. `script_path` apunta a la clase que lo implementa; `role` describe su funcion
## en el encuentro (para el generador de encuentros y para la UI).

@export var id: String = ""
@export var display_name: String = ""
@export var family: String = ""            # familia visual/tematica (capitulo)
@export var role: String = "melee"         # melee shooter sniper heavy turret support summoner charger kamikaze shield controller
@export var script_path: String = ""
@export var hp: float = 10.0
@export var threat: float = 1.0            # coste en el presupuesto del encuentro
@export var coins: int = 1
@export var elite_ok: bool = true
@export var params: Dictionary = {}        # overrides para la clase (velocidad, cadencia...)
