class_name VisualProfiles
extends RefCounted
## Perfiles visuales: que sprite usa cada personaje / enemigo / jefe / arma / cofre / prop, con su escala, offset, fps y anclas.
## `height` = alto en pixeles de juego de la silueta tipica (la escala sale de ahi, nunca se deforma el sprite).
## Todo lo que no tenga perfil (o cuyo arte falle al cargar) usa el render procedural original.

## Ajuste global del tamano del arte de armas importado (1.0 = la punta cae justo en `muzzle`).
const WEAPON_ART_SCALE := 1.0

## HomeLife (NPC y props de VIDA) queda DESACTIVADO en el HOME: el menu debe ser limpio y centrado en el heroe.
## El codigo y los assets se conservan; poner true para volver a mostrarlo.
const HOME_LIFE_ENABLED := false

const CHAR_WEAPON_SCALE := 0.66

const CHAR_FPS := {"default": 10.0, "walk": 15.0, "idle": 6.0, "attack": 16.0, "hurt": 16.0, "death": 12.0}

## id de `look["visual"]` -> perfil. weapon_anchor: punto del hombro (relativo a los pies) donde gira el arma.
const CHARACTERS := {
	"vesper": {"set": "rpg/characters/human_ranger", "height": 75.0, "anchor_ref": 75.0, "filter": "nearest", "menu_k": 0.8, "fps": CHAR_FPS, "shadow": 1.0, "hand": Color("d9a77a"), "sleeve": Color("5b5a3a"),
		"weapon_anchor": {"south": Vector2(13, -27), "south-east": Vector2(11, -28), "east": Vector2(-1, -26), "north-east": Vector2(13, -26), "north": Vector2(15, -26), "north-west": Vector2(-14, -26), "west": Vector2(-9, -23), "south-west": Vector2(-13, -28), "default": Vector2(0, -26)}},
	"kiro9": {"set": "rpg/characters/combat_android", "height": 75.0, "anchor_ref": 75.0, "filter": "nearest", "menu_k": 0.8, "fps": CHAR_FPS, "idle_from_walk": true, "shadow": 1.0, "hand": Color("9fb1c9"), "sleeve": Color("5d6b82"),
		"weapon_anchor": {"south": Vector2(14, -31), "south-east": Vector2(14, -31), "east": Vector2(1, -34), "north-east": Vector2(1, -34), "north": Vector2(15, -31), "north-west": Vector2(-1, -36), "west": Vector2(-1, -36), "south-west": Vector2(-14, -31), "default": Vector2(0, -32)}},
	"kraal": {"set": "rpg/characters/beetle_cyborg", "height": 81.0, "anchor_ref": 81.0, "menu_k": 0.76, "fps": CHAR_FPS, "idle_from_walk": true, "weapon_scale": 0.5, "shadow": 1.1, "hand": Color("d58a2c"), "sleeve": Color("3a3340"),
		"weapon_anchor": {"south": Vector2(15, -26), "south-east": Vector2(15, -26), "east": Vector2(0, -27), "north-east": Vector2(0, -27), "north": Vector2(15, -26), "north-west": Vector2(0, -27), "west": Vector2(0, -27), "south-west": Vector2(-15, -26), "default": Vector2(0, -27)}},
	"paradoja": {"set": "rpg/characters/mutant_striker", "height": 77.0, "anchor_ref": 77.0, "filter": "nearest", "menu_k": 0.78, "fps": CHAR_FPS, "idle_from_walk": true, "shadow": 1.1, "hand": Color("c99a76"), "sleeve": Color("c99a76"),
		"weapon_anchor": {"south": Vector2(17, -24), "south-east": Vector2(17, -24), "east": Vector2(-4, -22), "north-east": Vector2(-4, -22), "north": Vector2(19, -26), "north-west": Vector2(4, -22), "west": Vector2(4, -22), "south-west": Vector2(-17, -24), "default": Vector2(0, -24)}},
	"sera": {"set": "rpg/characters/sera", "height": 75.0, "anchor_ref": 75.0, "filter": "nearest", "menu_k": 0.8, "fps": CHAR_FPS, "shadow": 1.0, "hand": Color("d9a77a"), "sleeve": Color("e8eef2"),
		"weapon_anchor": {"south": Vector2(13, -27), "south-east": Vector2(11, -28), "east": Vector2(-1, -26), "north-east": Vector2(13, -26), "north": Vector2(15, -26), "north-west": Vector2(-14, -26), "west": Vector2(-9, -23), "south-west": Vector2(-13, -28), "default": Vector2(0, -26)}},
	"orla": {"set": "rpg/characters/orla", "height": 75.0, "anchor_ref": 75.0, "filter": "nearest", "menu_k": 0.8, "fps": CHAR_FPS, "shadow": 1.0, "hand": Color("d9a77a"), "sleeve": Color("a8741c"),
		"weapon_anchor": {"south": Vector2(13, -27), "south-east": Vector2(11, -28), "east": Vector2(-1, -26), "north-east": Vector2(13, -26), "north": Vector2(15, -26), "north-west": Vector2(-14, -26), "west": Vector2(-9, -23), "south-west": Vector2(-13, -28), "default": Vector2(0, -26)}},
	"halo": {"set": "rpg/characters/halo", "height": 75.0, "anchor_ref": 75.0, "filter": "nearest", "menu_k": 0.8, "fps": CHAR_FPS, "shadow": 1.0, "hand": Color("d9a77a"), "sleeve": Color("8a7a56"),
		"weapon_anchor": {"south": Vector2(13, -27), "south-east": Vector2(11, -28), "east": Vector2(-1, -26), "north-east": Vector2(13, -26), "north": Vector2(15, -26), "north-west": Vector2(-14, -26), "west": Vector2(-9, -23), "south-west": Vector2(-13, -28), "default": Vector2(0, -26)}},
	"sable": {"set": "rpg/characters/sable", "height": 75.0, "anchor_ref": 75.0, "filter": "nearest", "menu_k": 0.8, "fps": CHAR_FPS, "idle_from_walk": true, "shadow": 1.0, "hand": Color("9a8fa0"), "sleeve": Color("2a2230"),
		"weapon_anchor": {"south": Vector2(14, -31), "south-east": Vector2(14, -31), "east": Vector2(1, -34), "north-east": Vector2(1, -34), "north": Vector2(15, -31), "north-west": Vector2(-1, -36), "west": Vector2(-1, -36), "south-west": Vector2(-14, -31), "default": Vector2(0, -32)}},
	"nyx": {"set": "rpg/characters/nyx", "height": 75.0, "anchor_ref": 75.0, "filter": "nearest", "menu_k": 0.8, "fps": CHAR_FPS, "idle_from_walk": true, "shadow": 1.0, "hand": Color("9a8fa0"), "sleeve": Color("4a2a6a"),
		"weapon_anchor": {"south": Vector2(14, -31), "south-east": Vector2(14, -31), "east": Vector2(1, -34), "north-east": Vector2(1, -34), "north": Vector2(15, -31), "north-west": Vector2(-1, -36), "west": Vector2(-1, -36), "south-west": Vector2(-14, -31), "default": Vector2(0, -32)}},
	"ilex": {"set": "rpg/characters/ilex", "height": 75.0, "anchor_ref": 75.0, "filter": "nearest", "menu_k": 0.8, "fps": CHAR_FPS, "idle_from_walk": true, "shadow": 1.0, "hand": Color("b0a890"), "sleeve": Color("3a4a7a"),
		"weapon_anchor": {"south": Vector2(14, -31), "south-east": Vector2(14, -31), "east": Vector2(1, -34), "north-east": Vector2(1, -34), "north": Vector2(15, -31), "north-west": Vector2(-1, -36), "west": Vector2(-1, -36), "south-west": Vector2(-14, -31), "default": Vector2(0, -32)}},
	"basalto": {"set": "rpg/characters/basalto", "height": 88.0, "anchor_ref": 77.0, "weapon_scale": 0.7, "filter": "nearest", "menu_k": 0.78, "fps": CHAR_FPS, "idle_from_walk": true, "shadow": 1.1, "hand": Color("c99a76"), "sleeve": Color("c99a76"),
		"weapon_anchor": {"south": Vector2(17, -24), "south-east": Vector2(17, -24), "east": Vector2(-4, -22), "north-east": Vector2(-4, -22), "north": Vector2(19, -26), "north-west": Vector2(4, -22), "west": Vector2(4, -22), "south-west": Vector2(-17, -24), "default": Vector2(0, -24)}},
}


static func character(visual_id: String) -> Dictionary:
	return CHARACTERS.get(visual_id, {})


## Enemigos por `kind_name`. Solo cambia la PRESENTACION: IA, vida, hitboxes y ataques siguen siendo del enemigo Premium.
## anim_map traduce fases logicas (idle, move, windup, strike, recover, death) a animaciones del set.
## tint: matiz del sprite (para que una misma criatura sirva a dos enemigos sin parecer la misma skin).
const ENEMY_FPS := {"default": 10.0, "walk": 11.0, "idle": 6.0, "attack": 14.0, "death": 16.0, "roll": 16.0}

const ENEMIES := {
	"caballero": {"set": "rpg/enemies/bone_guard", "height": 62.0, "fps": ENEMY_FPS, "shadow": 1.2,
		"anim_map": {"idle": "shield_idle", "move": "walk", "windup": "bash_windup_alt", "strike": "attack", "recover": "guard_fatigue"}},
	"sabueso": {"set": "rpg/enemies/raptor", "height": 46.0, "fps": ENEMY_FPS, "tint": Color("ffc89a"), "shadow": 1.0,
		"anim_map": {"idle": "idle", "move": "walk", "windup": "lunge_windup", "strike": "lunge_attack", "recover": "recovery"}},
	"acechador": {"set": "rpg/enemies/raptor", "height": 56.0, "fps": ENEMY_FPS, "tint": Color("c8a6ff"), "shadow": 1.1,
		"anim_map": {"idle": "idle", "move": "walk", "windup": "lunge_windup", "strike": "lunge_attack", "recover": "recovery"}},
	"ojo": {"set": "rpg/enemies/orb_stalker", "height": 70.0, "offset": Vector2(0, -16), "fps": ENEMY_FPS, "shadow": 1.2,
		"anim_map": {"idle": "idle", "move": "move", "windup": "ranged_windup", "strike": "projectile_attack", "recover": "idle"}},
	"escarabajo": {"set": "rpg/enemies/iron_beetle", "height": 30.0, "fps": ENEMY_FPS, "tint": Color("9affd0"), "shadow": 0.8,
		"anim_map": {"idle": "idle", "move": "walk", "windup": "roll_windup_alt", "strike": "roll", "recover": "idle"}},
}


## Jefes (mismas claves que los enemigos). Sus scripts y mecanicas no cambian; solo la representacion.
const BOSS_FPS := {"default": 10.0, "idle_float": 8.0, "dimensional_cast": 10.0, "projectile_cast": 12.0, "death": 8.0, "hurt": 10.0}

const BOSSES := {
	"vigia": {"set": "rpg/bosses/rift_warden", "height": 142.0, "offset": Vector2(0, -6), "fps": BOSS_FPS, "shadow": 1.5,
		"bar_y": -158.0, "death_dur": 1.8,
		"anim_map": {"idle": "idle_float", "move": "idle_float", "windup": "dimensional_cast", "strike": "projectile_cast", "recover": "hurt"}},
}


static func enemy(kind: String) -> Dictionary:
	if BOSSES.has(kind):
		return BOSSES[kind]
	return ENEMIES.get(kind, {})


static var _enabled := -1


## `--no-sprites` fuerza el render procedural (comparacion A/B y red de seguridad).
static func sprites_enabled() -> bool:
	if _enabled < 0:
		_enabled = 0 if "--no-sprites" in OS.get_cmdline_user_args() else 1
	return _enabled == 1


## Props de escenografia con arte importado: kind Premium -> arte(s) (se elige uno por semilla del prop) y modo de ajuste.
## fit "h": la altura del sprite sigue a la altura de juego del prop; "w": sigue al ancho de su huella (colision).
## La huella, la altura, los golpes y la rotura siguen siendo del Prop: solo cambia como se dibuja.
const PROPS := {
	"weapon_rack": {"art": ["rpg/props/dungeon2/weapon_rack"], "fit": "w"},
	"brazier": {"art": ["rpg/props/dungeon2/brazier"], "fit": "h", "hmul": 1.25},
	"statue": {"art": ["rpg/props/dungeon2/guardian_statue"], "fit": "h", "hmul": 1.05},
	"column": {"art": ["rpg/props/structures/stone_column", "rpg/props/structures/broken_column"], "fit": "h"},
	"crystal": {"art": ["rpg/props/crystals/violet_rift_crystal_cluster", "rpg/props/crystals/cyan_crystal_cluster"], "fit": "h", "hmul": 0.95},
	"wood_crate": {"art": ["rpg/props/containers/crate"], "fit": "h", "hmul": 1.1},
	"wood_barrel": {"art": ["rpg/props/containers/barrel"], "fit": "h", "hmul": 1.1},
	"rack": {"art": ["rpg/props/lab/server_rack"], "fit": "h"},
	"terminal": {"art": ["rpg/props/story/sci_fi_terminal"], "fit": "h", "hmul": 1.15},
	"tank": {"art": ["rpg/props/lab/gas_tanks"], "fit": "h", "hmul": 1.05},
	"rift_stone": {"art": ["rpg/props/rift/dimensional_fragment"], "fit": "h", "hmul": 1.15},
	"orb_pillar": {"art": ["rpg/props/dungeon2/rift_crystal_pillar"], "fit": "h"},
}


static func prop(kind: String) -> Dictionary:
	return PROPS.get(kind, {})


## Decoracion contextual por tema (tema = RoomDef.theme). `floor`: se HORNEA en el suelo de la sala (coste cero en juego).
## `decal` se dibuja centrado y translucido; `obj` apoya la base en el punto. `stand`: piezas altas SIN colision pegadas al muro
## norte (Sprite2D ordenados en Y). n = [min, max] a escala de sala media. Nada se coloca sobre solidos, spawns ni pasillos.
const DECOR := {
	"castle": {
		"floor": [
			{"art": "rpg/decals/floor_crack", "n": [2, 4], "kind": "decal", "a": 0.4, "s": 1.2},
			{"art": "rpg/decals/bone_dust", "n": [2, 3], "kind": "decal", "a": 0.7, "s": 1.3},
			{"art": "rpg/decals/gravel_scatter", "n": [2, 4], "kind": "decal", "a": 0.65, "s": 1.4},
			{"art": "rpg/props/rubble/stone_rubble", "n": [2, 4], "kind": "obj", "a": 1.0, "s": 0.9},
			{"art": "rpg/props/rubble/skull_pile", "n": [1, 2], "kind": "obj", "a": 1.0, "s": 0.8},
			{"art": "rpg/props/rubble/bone_debris", "n": [1, 3], "kind": "obj", "a": 1.0, "s": 0.9},
			{"art": "rpg/props/dungeon2/bone_heap", "n": [0, 1], "kind": "obj", "a": 1.0, "s": 0.75},
		],
		"stand": [
			{"art": "rpg/props/dungeon/candles", "n": [1, 2], "s": 0.9},
			{"art": "rpg/props/dungeon2/lantern_post", "n": [1, 2], "s": 0.9},
			{"art": "rpg/props/dungeon/books_scroll", "n": [0, 1], "s": 0.9},
			{"art": "rpg/props/dungeon2/sarcophagus", "n": [0, 1], "s": 0.85},
			{"art": "rpg/props/dungeon/chains_shackles", "n": [0, 1], "s": 0.9},
		],
	},
	"aztec": {
		"floor": [
			{"art": "rpg/decals/moss_patch_a", "n": [2, 3], "kind": "decal", "a": 0.6, "s": 1.2},
			{"art": "rpg/decals/moss_patch_b", "n": [2, 3], "kind": "decal", "a": 0.6, "s": 1.2},
			{"art": "rpg/decals/floor_roots", "n": [1, 2], "kind": "decal", "a": 0.55, "s": 1.0},
			{"art": "rpg/decals/gravel_scatter", "n": [2, 3], "kind": "decal", "a": 0.6, "s": 1.4},
			{"art": "rpg/props/rubble/stone_rubble", "n": [2, 3], "kind": "obj", "a": 1.0, "s": 0.9},
			{"art": "rpg/props/organic/glowing_mushroom_cluster", "n": [1, 2], "kind": "obj", "a": 1.0, "s": 0.85},
		],
		"stand": [
			{"art": "rpg/props/organic/giant_root", "n": [1, 2], "s": 0.9},
			{"art": "rpg/props/dungeon2/root_stump", "n": [0, 1], "s": 0.85},
			{"art": "rpg/props/organic/plant_nest", "n": [0, 1], "s": 0.85},
			{"art": "rpg/props/organic/thorny_vegetation", "n": [0, 1], "s": 0.85},
		],
	},
	"tech": {
		"floor": [
			{"art": "rpg/decals/floor_crack", "n": [2, 4], "kind": "decal", "a": 0.4, "s": 1.5},
			{"art": "rpg/props/rooms/combat_scorch_decal", "n": [1, 2], "kind": "decal", "a": 0.7, "s": 0.8},
			{"art": "rpg/props/lab/cable_bundle", "n": [1, 3], "kind": "obj", "a": 1.0, "s": 0.8},
			{"art": "rpg/props/lab/pipes", "n": [0, 1], "kind": "obj", "a": 1.0, "s": 0.8},
		],
		"stand": [
			{"art": "rpg/props/lab/electrical_box", "n": [1, 2], "s": 0.95},
			{"art": "rpg/props/lab/warning_light", "n": [1, 2], "s": 0.9},
			{"art": "rpg/props/lab/med_equipment", "n": [0, 1], "s": 0.9},
			{"art": "rpg/props/lab/destroyed_terminal", "n": [0, 1], "s": 0.9},
		],
	},
	"anomaly": {
		"floor": [
			{"art": "rpg/decals/floor_crack", "n": [2, 3], "kind": "decal", "a": 0.3, "s": 1.1},
			{"art": "rpg/props/rift/void_debris", "n": [1, 3], "kind": "obj", "a": 0.95, "s": 0.8},
			{"art": "rpg/props/rift/dimensional_fragment", "n": [1, 2], "kind": "obj", "a": 1.0, "s": 0.85},
			{"art": "rpg/props/crystals/violet_rift_crystal_cluster", "n": [1, 2], "kind": "obj", "a": 1.0, "s": 0.75},
		],
		"stand": [
			{"art": "rpg/props/lighting/violet_rift_lamp", "n": [1, 2], "s": 0.95},
			{"art": "rpg/props/lighting/magic_lamp_cyan", "n": [1, 1], "s": 0.9},
			{"art": "rpg/props/rift/floating_crystals", "n": [0, 1], "s": 0.85},
			{"art": "rpg/props/rift/rift_anchor", "n": [0, 1], "s": 0.85},
		],
	},
}


static func decor(theme_id: String) -> Dictionary:
	return DECOR.get(theme_id, {})


## Personal de la estacion (HOME): sprites civiles de VIDA usados como ambientacion, nunca como combatientes.
const NPC_FPS := {"default": 8.0, "walk": 9.0, "idle": 4.0, "phone": 5.0, "drink": 5.0}

const NPCS := {
	"tecnica": {"set": "vida/npc/female", "height": 84.0, "fps": NPC_FPS, "tint": Color("b8f5e8")},
	"armero": {"set": "vida/npc/male", "height": 82.0, "fps": NPC_FPS, "tint": Color("ffd3a0")},
	"mercader": {"set": "vida/npc/male", "height": 80.0, "fps": NPC_FPS, "tint": Color("d9b8ff")},
	"auxiliar": {"set": "vida/npc/female", "height": 84.0, "fps": NPC_FPS, "tint": Color("ffb8c8")},
}

## Props de la estacion (VIDA + Rpg_new): id de arte, altura en pantalla relativa a la escena (1.0 = 720 px de alto).
const HOME_PROPS := {
	"left": [
		{"art": "vida/props/city/vending_machine", "h": 0.17, "x": 0.045},
		{"art": "vida/interior/market_shelf_front", "h": 0.18, "x": 0.15},
		{"art": "vida/props/city/bench", "h": 0.075, "x": 0.235},
	],
	"right": [
		{"art": "vida/props/city/lamp", "h": 0.25, "x": 0.745},
		{"art": "vida/interior/bookcase_front", "h": 0.18, "x": 0.865},
		{"art": "vida/props/city/planter", "h": 0.075, "x": 0.935},
	],
}
