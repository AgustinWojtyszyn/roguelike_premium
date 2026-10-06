class_name MissionData
extends Resource
## Mision. `metric` se compara con los eventos del run (ver `MissionSystem.METRICS`).

@export var id: String = ""
@export var scope: String = "daily"        # daily weekly season
@export var title: String = ""
@export var metric: String = "kills"       # kills | kills_cat:<cat> | chapters | chests | rooms | wins | play_char:<id> | nodamage_rooms | bosses | perks
@export var target: int = 10
@export var reward_coins: int = 50
@export var reward_xp: int = 20
@export var reward_gems: int = 0
