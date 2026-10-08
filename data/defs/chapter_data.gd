class_name ChapterData
extends Resource
## Capitulo / mazmorra: tema, 8 etapas, pools de salas y enemigos, jefe y tablas de loot.

@export var id: String = ""
@export var display_name: String = ""
@export var subtitle: String = ""
@export_multiline var description: String = ""
@export var theme: String = "tech"
@export var order: int = 0
@export var music: String = "ch1"
@export var accent: Color = Color("27e0cc")
@export var sky: Color = Color("04060c")
## Plan de etapas: tipos "combat" "elite" "cache" "boss". El generador rellena salas/encuentros.
@export var stage_plan: Array[String] = ["combat", "combat", "combat", "cache", "elite", "combat", "elite", "boss"]
@export var perk_after: Array[int] = [1, 4, 6]     # indices de etapa (0-based) tras los que se ofrece un perk
@export var room_pool: Array[String] = []
@export var cache_rooms: Array[String] = []
@export var boss_room: String = ""
@export var enemy_pool: Array[String] = []     # ids de EnemyData
@export var elite_pool: Array[String] = []
@export var boss: String = ""
@export var loot_table: String = "ch1"
@export var difficulty: float = 1.0
@export var unlock_requires: String = ""       # capitulo que debe estar completado
@export var coin_reward: int = 60
@export var xp_reward: int = 90
