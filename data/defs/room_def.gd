class_name RoomDef
extends Resource
## Sala curada. La geometria es el rectangulo de suelo `floor` (centrado en el origen) mas bloques solidos
## internos (`blocks`), props y puntos de aparicion. El generador combina estas piezas con encuentros.

@export var id: String = ""
@export var display_name: String = ""
@export var theme: String = "tech"
@export var size: Vector2 = Vector2(1200, 640)
@export var kind: String = "combat"            # combat cache boss
## Bloques solidos internos: [x, y, w, h, style]  (relativos al centro de la sala)
@export var blocks: Array = []
## Props: [kind, x, y, w, h]  (rect de huella)
@export var props: Array = []
## Puntos de aparicion de enemigos (compuertas, portales, grietas...)
@export var spawns: Array[Vector2] = []
@export var entry_sides: Array[String] = ["W"]
@export var exit_sides: Array[String] = ["E"]
@export var decor: Dictionary = {}              # hints para el tema (densidad de luces, etc.)
@export var threat_min: float = 3.0
@export var threat_max: float = 12.0
@export var original: bool = false              # la sala de la vertical slice
