class_name CharacterData
extends Resource
## Definicion de un personaje jugable. Todo lo visual vive en `look` (paleta + variantes de piezas),
## de modo que agregar un personaje es agregar datos, no codigo.

@export var id: String = ""
@export var display_name: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var rarity: int = 0
@export var hp: int = 6
@export var shield: int = 3
@export var energy: int = 120
@export var speed_mult: float = 1.0
@export var ability_id: String = ""
@export var ability_name: String = ""
@export_multiline var ability_desc: String = ""
@export var ability_cost: int = 40
@export var ability_cd: float = 9.0
@export var passive_id: String = ""
@export var passive_name: String = ""
@export_multiline var passive_desc: String = ""
@export var start_weapon: String = "pulsar"
@export var side_weapon: String = "chispa"
@export var recommended_weapon: String = ""
## Paleta + variantes de piezas. Ver `CharacterRig.DEFAULT_LOOK` para las claves.
@export var look: Dictionary = {}
## {"type": "default"|"coins"|"pass"|"gems", "price": int}
@export var unlock: Dictionary = {"type": "coins", "price": 500}
@export var order: int = 0


func is_default_unlock() -> bool:
	return unlock.get("type", "") == "default"
