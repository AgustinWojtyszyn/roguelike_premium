class_name SkinData
extends Resource
## Skin cosmetica: solo cambia aspecto (paleta, piezas, proyectil, estela). Nunca estadisticas.

@export var id: String = ""
@export var character: String = ""
@export var display_name: String = ""
@export var rarity: int = 1
@export var look: Dictionary = {}              # se mezcla sobre CharacterData.look
@export var bullet_color: Color = Color(0, 0, 0, 0)   # alpha 0 = sin override
@export var trail_color: Color = Color(0, 0, 0, 0)
@export var unlock: Dictionary = {"type": "coins", "price": 600}
