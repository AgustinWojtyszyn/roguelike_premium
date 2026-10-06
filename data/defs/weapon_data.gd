class_name WeaponData
extends Resource
## Definicion de un arma. `behavior` describe lo que la hace DISTINTA (rafaga, carga, rebote, cadena...),
## no solo numeros. Los comportamientos los ejecuta `WeaponRuntime`.

@export var id: String = ""
@export var display_name: String = ""
@export var sub: String = ""
@export var category: String = "smg"       # smg rifle shotgun pistol sniper energy plasma rail explosive melee drone exp
@export_multiline var description: String = ""
@export var rarity: int = 0
@export var damage: float = 2.0
@export var rate: float = 0.2              # segundos entre disparos
@export var spread: float = 0.05
@export var count: int = 1
@export var speed: float = 800.0
@export var life: float = 0.8
@export var pierce: int = 0
@export var knock: float = 40.0
@export var energy_cost: float = 0.0
@export var kick: float = 4.0              # retroceso visual del arma
@export var body_kick: float = 20.0        # impulso al cuerpo
@export var shake: float = 0.06
@export var muzzle: Vector2 = Vector2(35, 0)
@export var grip2: Vector2 = Vector2(15, 4)
@export var color: Color = Color("3df2dc")
@export var bullet: int = 0                # estilo visual/fisico de proyectil (ver Bullets.Style)
@export var casing: bool = true
@export var behavior: Dictionary = {}
@export var sfx: String = "smg"
@export var sfx_vol: float = -6.0
@export var art: String = "pulsar"         # pintor de `WeaponArt`
@export var palette: Dictionary = {}       # overrides de color del pintor
@export var muzzle_scale: float = 1.0
@export var max_range: float = 0.0         # solo informativo (auto)


func dps() -> float:
	var shots := float(count) * damage / maxf(rate, 0.05)
	if behavior.has("burst"):
		var b: int = behavior["burst"]
		shots = float(count * b) * damage / (rate + float(b) * float(behavior.get("burst_gap", 0.06)))
	return shots
