class_name BossData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var title: String = ""
@export var chapter: String = ""
@export var script_path: String = ""
@export var hp: float = 400.0
@export var phases: Array[float] = [1.0, 0.6, 0.3]     # umbrales de vida (fraccion) de cada fase
@export var accent: Color = Color("ff4fa8")
@export var coins: int = 40
@export var guaranteed_loot: String = "boss_ch1"
