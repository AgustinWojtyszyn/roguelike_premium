class_name ShopOffer
extends Resource
## Oferta de tienda (local / simulada). `cost`: {"coins": n} o {"gems": n} o {"usd": x} (simulado).

@export var id: String = ""
@export var kind: String = "skin"              # skin character coins gems pack gift
@export var item: String = ""
@export var title: String = ""
@export var subtitle: String = ""
@export var cost: Dictionary = {}
@export var grants: Dictionary = {}            # {"coins": 500, "gems": 10, "character": "x", "skin": "y"}
@export var daily: bool = false
@export var badge: String = ""
