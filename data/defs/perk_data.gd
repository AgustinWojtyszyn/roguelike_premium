class_name PerkData
extends Resource
## Perk de run. `mods` son modificadores de estadisticas; `hooks` activan comportamientos
## implementados en `PerkEffects` (por id de hook). Ocupa un slot.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rarity: int = 0
@export var tag: String = "ARMA"           # categoria visible: ARMA CUERPO NUCLEO UTIL
@export var icon: String = "bolt"
@export var mods: Dictionary = {}          # {"dmg_mult": 0.1, "speed_mult": 0.1, ...} (aditivos)
@export var hooks: Array[String] = []
@export var stackable: bool = false
@export var weight: float = 1.0
