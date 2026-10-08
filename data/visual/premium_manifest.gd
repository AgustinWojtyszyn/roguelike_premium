class_name PremiumManifest
extends RefCounted
## GENERADO por tools/premium_pipeline.py (no editar a mano). Hojas pre-renderizadas desde rigs 3D CC0 + agarre derivado del hueso fuente.
## SETS[id] = {bbox, feet, anims{anim:{sheet,dirs,counts,cell,weapon_mode,hand}}, grips{anim:{dir:[[gx,gy,ang,lgx,lgy,behind]...]}}}
## grip: px de celda relativos a los pies; ang: eje del arma en pantalla (grados, y hacia abajo); lg*: mano libre; behind=1 si la mano queda detras del torso (arma bajo el cuerpo).

## STATIC[id] = {path, size, bbox, anchor (origen del modelo en el recorte), scale (px de juego por px de textura), source}

const SETS := {
	"premium/characters/sable": {
		"kind": "hero_melee",
		"role": "player",
		"weapon_compatible": true,
		"bbox": [
			0,
			0,
			144,
			115
		],
		"feet": [
			72,
			115.2
		],
		"ppu": 45.0,
		"source": {
			"pack": "KayKit Adventurers 1.0",
			"revision": "672074b73ba276876a19e8816ecdc5241817ab47",
			"license": "CC0 1.0"
		},
		"anims": {
			"idle": {
				"sheet": "res://assets/premium/characters/sable/idle.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					144,
					144
				],
				"weapon_mode": "aim",
				"hand": {
					"sheet": "res://assets/premium/characters/sable/idle_hand.png",
					"cell": [
						40,
						40
					]
				}
			},
			"walk": {
				"sheet": "res://assets/premium/characters/sable/walk.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					144,
					144
				],
				"weapon_mode": "aim",
				"hand": {
					"sheet": "res://assets/premium/characters/sable/walk_hand.png",
					"cell": [
						40,
						40
					]
				}
			},
			"attack": {
				"sheet": "res://assets/premium/characters/sable/attack.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					7,
					7,
					7,
					7,
					7
				],
				"cell": [
					144,
					144
				],
				"weapon_mode": "rig",
				"hand": {
					"sheet": "res://assets/premium/characters/sable/attack_hand.png",
					"cell": [
						40,
						40
					]
				}
			},
			"hurt": {
				"sheet": "res://assets/premium/characters/sable/hurt.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					3,
					3,
					3,
					3,
					3
				],
				"cell": [
					144,
					144
				],
				"weapon_mode": "aim",
				"hand": {
					"sheet": "res://assets/premium/characters/sable/hurt_hand.png",
					"cell": [
						40,
						40
					]
				}
			},
			"death": {
				"sheet": "res://assets/premium/characters/sable/death.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					144,
					144
				],
				"weapon_mode": "rig",
				"hand": {
					"sheet": "res://assets/premium/characters/sable/death_hand.png",
					"cell": [
						40,
						40
					]
				}
			}
		},
		"grips": {
			"idle": {
				"south": [
					[
						-21.3,
						-19.8,
						104.8,
						22.1,
						-22.8,
						0
					],
					[
						-21.3,
						-19.3,
						104.8,
						22.1,
						-22.3,
						0
					],
					[
						-21.3,
						-18.9,
						104.8,
						22.1,
						-21.9,
						0
					],
					[
						-21.3,
						-19.3,
						104.8,
						22.1,
						-22.3,
						0
					]
				],
				"south-east": [
					[
						-11.6,
						-11.9,
						37.9,
						15.2,
						-31.6,
						0
					],
					[
						-11.6,
						-11.5,
						37.9,
						15.2,
						-31.2,
						0
					],
					[
						-11.6,
						-11.0,
						37.9,
						15.2,
						-30.7,
						0
					],
					[
						-11.6,
						-11.5,
						37.9,
						15.2,
						-31.2,
						0
					]
				],
				"east": [
					[
						4.9,
						-10.3,
						5.0,
						-0.6,
						-35.1,
						0
					],
					[
						4.9,
						-9.9,
						5.0,
						-0.6,
						-34.6,
						0
					],
					[
						4.9,
						-9.4,
						5.0,
						-0.6,
						-34.2,
						0
					],
					[
						4.9,
						-9.9,
						5.0,
						-0.6,
						-34.6,
						0
					]
				],
				"north-east": [
					[
						18.6,
						-15.9,
						-22.9,
						-16.1,
						-31.1,
						0
					],
					[
						18.6,
						-15.5,
						-22.9,
						-16.1,
						-30.7,
						0
					],
					[
						18.6,
						-15.0,
						-22.9,
						-16.1,
						-30.2,
						0
					],
					[
						18.6,
						-15.5,
						-22.9,
						-16.1,
						-30.7,
						0
					]
				],
				"north": [
					[
						21.3,
						-25.4,
						-75.2,
						-22.1,
						-22.1,
						0
					],
					[
						21.3,
						-24.9,
						-75.2,
						-22.1,
						-21.6,
						0
					],
					[
						21.3,
						-24.5,
						-75.2,
						-22.1,
						-21.2,
						0
					],
					[
						21.3,
						-24.9,
						-75.2,
						-22.1,
						-21.6,
						0
					]
				]
			},
			"walk": {
				"south": [
					[
						-21.7,
						-22.6,
						108.6,
						22.1,
						-23.8,
						0
					],
					[
						-21.7,
						-19.7,
						108.6,
						22.1,
						-20.8,
						0
					],
					[
						-21.7,
						-21.0,
						108.3,
						22.1,
						-22.2,
						0
					],
					[
						-21.7,
						-22.6,
						108.6,
						22.1,
						-23.8,
						0
					],
					[
						-21.7,
						-19.7,
						108.6,
						22.1,
						-20.8,
						0
					],
					[
						-21.7,
						-21.0,
						108.3,
						22.1,
						-22.2,
						0
					]
				],
				"south-east": [
					[
						-11.9,
						-14.7,
						51.3,
						17.8,
						-33.3,
						0
					],
					[
						-11.9,
						-11.7,
						51.3,
						17.8,
						-30.3,
						0
					],
					[
						-11.8,
						-13.1,
						51.7,
						17.9,
						-31.7,
						0
					],
					[
						-11.9,
						-14.7,
						51.3,
						17.8,
						-33.3,
						0
					],
					[
						-11.9,
						-11.7,
						51.3,
						17.8,
						-30.3,
						0
					],
					[
						-11.8,
						-13.1,
						51.7,
						17.9,
						-31.7,
						0
					]
				],
				"east": [
					[
						4.9,
						-13.0,
						16.7,
						3.1,
						-38.2,
						0
					],
					[
						4.9,
						-10.1,
						16.7,
						3.1,
						-35.3,
						0
					],
					[
						5.0,
						-11.5,
						17.3,
						3.2,
						-36.7,
						0
					],
					[
						4.9,
						-13.0,
						16.7,
						3.1,
						-38.2,
						0
					],
					[
						4.9,
						-10.1,
						16.7,
						3.1,
						-35.3,
						0
					],
					[
						5.0,
						-11.5,
						17.3,
						3.2,
						-36.7,
						0
					]
				],
				"north-east": [
					[
						18.8,
						-18.6,
						-9.5,
						-13.4,
						-35.8,
						0
					],
					[
						18.8,
						-15.7,
						-9.5,
						-13.4,
						-32.8,
						0
					],
					[
						18.9,
						-17.1,
						-8.7,
						-13.3,
						-34.3,
						0
					],
					[
						18.8,
						-18.6,
						-9.5,
						-13.4,
						-35.8,
						0
					],
					[
						18.8,
						-15.7,
						-9.5,
						-13.4,
						-32.8,
						0
					],
					[
						18.9,
						-17.1,
						-8.7,
						-13.3,
						-34.3,
						0
					]
				],
				"north": [
					[
						21.7,
						-28.2,
						-59.3,
						-22.1,
						-27.4,
						0
					],
					[
						21.7,
						-25.3,
						-59.3,
						-22.1,
						-24.4,
						0
					],
					[
						21.7,
						-26.8,
						-58.6,
						-22.1,
						-25.9,
						0
					],
					[
						21.7,
						-28.2,
						-59.3,
						-22.1,
						-27.4,
						0
					],
					[
						21.7,
						-25.3,
						-59.3,
						-22.1,
						-24.4,
						0
					],
					[
						21.7,
						-26.8,
						-58.6,
						-22.1,
						-25.9,
						0
					]
				]
			},
			"attack": {
				"south": [
					[
						-21.3,
						-19.8,
						104.8,
						22.1,
						-22.8,
						0
					],
					[
						-13.1,
						-10.1,
						-0.8,
						21.1,
						-26.7,
						0
					],
					[
						-38.0,
						-23.6,
						128.4,
						16.0,
						-33.6,
						0
					],
					[
						-36.7,
						-28.4,
						172.1,
						15.6,
						-33.9,
						0
					],
					[
						-35.9,
						-29.8,
						165.9,
						16.8,
						-34.6,
						0
					],
					[
						-34.5,
						-31.2,
						159.0,
						18.6,
						-33.7,
						0
					],
					[
						-28.8,
						-31.1,
						145.3,
						21.5,
						-26.6,
						0
					]
				],
				"south-east": [
					[
						-11.6,
						-11.9,
						37.9,
						15.2,
						-31.6,
						0
					],
					[
						8.1,
						-8.9,
						-27.9,
						10.2,
						-34.1,
						0
					],
					[
						-21.3,
						-9.5,
						56.8,
						4.0,
						-38.3,
						0
					],
					[
						-26.3,
						-13.4,
						136.8,
						3.3,
						-38.4,
						0
					],
					[
						-28.0,
						-14.7,
						127.3,
						2.2,
						-39.1,
						0
					],
					[
						-30.4,
						-15.8,
						113.3,
						2.9,
						-38.8,
						0
					],
					[
						-27.7,
						-17.7,
						84.7,
						10.2,
						-34.2,
						0
					]
				],
				"east": [
					[
						4.9,
						-10.3,
						5.0,
						-0.6,
						-35.1,
						0
					],
					[
						24.5,
						-16.6,
						-72.6,
						-6.6,
						-35.0,
						0
					],
					[
						7.9,
						-6.3,
						14.6,
						-10.4,
						-36.8,
						0
					],
					[
						-0.4,
						-7.1,
						67.1,
						-10.9,
						-36.6,
						0
					],
					[
						-3.7,
						-7.1,
						60.0,
						-13.7,
						-36.4,
						0
					],
					[
						-8.4,
						-6.6,
						47.2,
						-14.5,
						-36.1,
						0
					],
					[
						-10.3,
						-8.7,
						29.1,
						-7.0,
						-34.9,
						0
					]
				],
				"north-east": [
					[
						18.6,
						-15.9,
						-22.9,
						-16.1,
						-31.1,
						0
					],
					[
						26.6,
						-28.8,
						-130.6,
						-19.6,
						-28.8,
						1
					],
					[
						32.5,
						-15.9,
						-12.1,
						-18.7,
						-29.9,
						0
					],
					[
						25.7,
						-13.1,
						19.3,
						-18.8,
						-29.6,
						0
					],
					[
						22.8,
						-11.7,
						17.8,
						-21.6,
						-28.0,
						0
					],
					[
						18.5,
						-9.0,
						11.3,
						-23.4,
						-27.1,
						0
					],
					[
						13.1,
						-9.3,
						0.1,
						-20.2,
						-28.4,
						0
					]
				],
				"north": [
					[
						21.3,
						-25.4,
						-75.2,
						-22.1,
						-22.1,
						0
					],
					[
						13.1,
						-38.2,
						-164.8,
						-21.1,
						-19.1,
						1
					],
					[
						38.0,
						-32.6,
						-51.6,
						-16.0,
						-21.6,
						0
					],
					[
						36.7,
						-27.9,
						-7.9,
						-15.6,
						-21.4,
						0
					],
					[
						35.9,
						-25.6,
						-9.0,
						-16.8,
						-18.9,
						0
					],
					[
						34.5,
						-21.6,
						-15.7,
						-18.6,
						-17.1,
						0
					],
					[
						28.8,
						-19.3,
						-30.7,
						-21.5,
						-18.5,
						0
					]
				]
			},
			"hurt": {
				"south": [
					[
						-21.3,
						-19.8,
						104.8,
						22.1,
						-22.8,
						0
					],
					[
						-23.8,
						-22.4,
						118.7,
						25.4,
						-23.8,
						0
					],
					[
						-21.3,
						-19.8,
						104.8,
						22.1,
						-22.8,
						0
					]
				],
				"south-east": [
					[
						-11.6,
						-11.9,
						37.9,
						15.2,
						-31.6,
						0
					],
					[
						-16.5,
						-12.8,
						47.7,
						16.7,
						-33.8,
						0
					],
					[
						-11.6,
						-11.9,
						37.9,
						15.2,
						-31.6,
						0
					]
				],
				"east": [
					[
						4.9,
						-10.3,
						5.0,
						-0.6,
						-35.1,
						0
					],
					[
						0.4,
						-9.0,
						10.2,
						-1.8,
						-37.3,
						0
					],
					[
						4.9,
						-10.3,
						5.0,
						-0.6,
						-35.1,
						0
					]
				],
				"north-east": [
					[
						18.6,
						-15.9,
						-22.9,
						-16.1,
						-31.1,
						0
					],
					[
						17.1,
						-13.1,
						-16.7,
						-19.2,
						-32.3,
						0
					],
					[
						18.6,
						-15.9,
						-22.9,
						-16.1,
						-31.1,
						0
					]
				],
				"north": [
					[
						21.3,
						-25.4,
						-75.2,
						-22.1,
						-22.1,
						0
					],
					[
						23.8,
						-22.8,
						-61.3,
						-25.4,
						-21.7,
						0
					],
					[
						21.3,
						-25.4,
						-75.2,
						-22.1,
						-22.1,
						0
					]
				]
			},
			"death": {
				"south": [
					[
						-21.3,
						-19.8,
						104.8,
						22.1,
						-22.8,
						0
					],
					[
						-18.8,
						-22.6,
						-139.7,
						19.8,
						-23.5,
						0
					],
					[
						-24.6,
						-26.7,
						-128.9,
						25.8,
						-29.7,
						0
					],
					[
						-43.9,
						-23.9,
						-99.3,
						42.6,
						-31.4,
						1
					],
					[
						-56.8,
						-29.6,
						-66.9,
						46.9,
						-36.1,
						1
					],
					[
						-63.6,
						-32.4,
						-54.0,
						47.1,
						-36.3,
						1
					]
				],
				"south-east": [
					[
						-11.6,
						-11.9,
						37.9,
						15.2,
						-31.6,
						0
					],
					[
						-2.6,
						-17.5,
						-74.8,
						23.3,
						-33.8,
						0
					],
					[
						-19.1,
						-16.3,
						-152.0,
						15.7,
						-39.6,
						0
					],
					[
						-46.8,
						-2.3,
						-150.8,
						8.4,
						-43.6,
						0
					],
					[
						-64.4,
						-0.8,
						-133.4,
						4.3,
						-48.3,
						0
					],
					[
						-72.7,
						-0.0,
						-121.7,
						4.2,
						-48.5,
						0
					]
				],
				"east": [
					[
						4.9,
						-10.3,
						5.0,
						-0.6,
						-35.1,
						0
					],
					[
						15.1,
						-20.5,
						-38.5,
						13.2,
						-42.4,
						0
					],
					[
						-2.5,
						-11.2,
						-167.5,
						-3.6,
						-42.4,
						0
					],
					[
						-5.0,
						14.1,
						-179.3,
						-13.4,
						-38.3,
						0
					],
					[
						-16.9,
						22.7,
						-169.2,
						-23.6,
						-39.6,
						0
					],
					[
						-21.9,
						26.5,
						-163.3,
						-23.9,
						-39.7,
						0
					]
				],
				"north-east": [
					[
						18.6,
						-15.9,
						-22.9,
						-16.1,
						-31.1,
						0
					],
					[
						23.9,
						-29.8,
						-46.4,
						-4.7,
						-44.4,
						0
					],
					[
						15.7,
						-14.3,
						-6.6,
						-20.8,
						-36.6,
						0
					],
					[
						15.3,
						7.1,
						149.4,
						-51.8,
						-27.3,
						0
					],
					[
						16.0,
						18.4,
						163.8,
						-62.1,
						-23.8,
						0
					],
					[
						17.2,
						23.1,
						170.0,
						-62.4,
						-23.7,
						0
					]
				],
				"north": [
					[
						21.3,
						-25.4,
						-75.2,
						-22.1,
						-22.1,
						0
					],
					[
						18.8,
						-39.9,
						-66.4,
						-19.8,
						-38.6,
						0
					],
					[
						24.6,
						-23.9,
						-15.6,
						-25.8,
						-25.6,
						0
					],
					[
						43.9,
						-15.6,
						78.1,
						-42.6,
						-13.6,
						0
					],
					[
						56.8,
						-7.6,
						116.1,
						-46.9,
						-6.5,
						0
					],
					[
						63.6,
						-4.7,
						130.2,
						-47.1,
						-6.3,
						0
					]
				]
			}
		},
		"weapon_axis": "ay"
	},
	"premium/characters/vesper": {
		"kind": "hero_ranged",
		"role": "player",
		"weapon_compatible": true,
		"bbox": [
			0,
			0,
			144,
			115
		],
		"feet": [
			72,
			115.2
		],
		"ppu": 45.7142857142857,
		"source": {
			"pack": "KayKit Adventurers 1.0",
			"revision": "672074b73ba276876a19e8816ecdc5241817ab47",
			"license": "CC0 1.0"
		},
		"anims": {
			"idle": {
				"sheet": "res://assets/premium/characters/vesper/idle.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					144,
					144
				],
				"weapon_mode": "aim",
				"hand": {
					"sheet": "res://assets/premium/characters/vesper/idle_hand.png",
					"cell": [
						40,
						40
					]
				}
			},
			"walk": {
				"sheet": "res://assets/premium/characters/vesper/walk.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					144,
					144
				],
				"weapon_mode": "aim",
				"hand": {
					"sheet": "res://assets/premium/characters/vesper/walk_hand.png",
					"cell": [
						40,
						40
					]
				}
			},
			"hurt": {
				"sheet": "res://assets/premium/characters/vesper/hurt.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					3,
					3,
					3,
					3,
					3
				],
				"cell": [
					144,
					144
				],
				"weapon_mode": "aim",
				"hand": {
					"sheet": "res://assets/premium/characters/vesper/hurt_hand.png",
					"cell": [
						40,
						40
					]
				}
			},
			"death": {
				"sheet": "res://assets/premium/characters/vesper/death.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					144,
					144
				],
				"weapon_mode": "rig",
				"hand": {
					"sheet": "res://assets/premium/characters/vesper/death_hand.png",
					"cell": [
						40,
						40
					]
				}
			},
			"idle_2h": {
				"sheet": "res://assets/premium/characters/vesper/idle_2h.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					144,
					144
				],
				"weapon_mode": "aim",
				"hand": {
					"sheet": "res://assets/premium/characters/vesper/idle_2h_hand.png",
					"cell": [
						40,
						40
					]
				}
			},
			"walk_2h": {
				"sheet": "res://assets/premium/characters/vesper/walk_2h.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					144,
					144
				],
				"weapon_mode": "aim",
				"hand": {
					"sheet": "res://assets/premium/characters/vesper/walk_2h_hand.png",
					"cell": [
						40,
						40
					]
				}
			}
		},
		"grips": {
			"idle": {
				"south": [
					[
						-22.9,
						-36.7,
						104.0,
						27.8,
						-34.6,
						0
					],
					[
						-22.9,
						-36.1,
						104.0,
						27.8,
						-34.0,
						0
					],
					[
						-22.9,
						-35.5,
						104.0,
						27.8,
						-33.4,
						0
					],
					[
						-22.9,
						-36.1,
						104.0,
						27.8,
						-34.0,
						0
					]
				],
				"south-east": [
					[
						-3.7,
						-30.4,
						43.4,
						19.9,
						-45.9,
						0
					],
					[
						-3.7,
						-29.8,
						43.4,
						19.9,
						-45.3,
						0
					],
					[
						-3.7,
						-29.2,
						43.4,
						19.9,
						-44.8,
						0
					],
					[
						-3.7,
						-29.8,
						43.4,
						19.9,
						-45.3,
						0
					]
				],
				"east": [
					[
						17.6,
						-33.7,
						10.2,
						0.4,
						-50.7,
						0
					],
					[
						17.6,
						-33.1,
						10.2,
						0.4,
						-50.1,
						0
					],
					[
						17.6,
						-32.5,
						10.2,
						0.4,
						-49.6,
						0
					],
					[
						17.6,
						-33.1,
						10.2,
						0.4,
						-50.1,
						0
					]
				],
				"north-east": [
					[
						28.6,
						-44.7,
						-17.1,
						-19.4,
						-46.2,
						0
					],
					[
						28.6,
						-44.1,
						-17.1,
						-19.4,
						-45.6,
						0
					],
					[
						28.6,
						-43.5,
						-17.1,
						-19.4,
						-45.1,
						0
					],
					[
						28.6,
						-44.1,
						-17.1,
						-19.4,
						-45.6,
						0
					]
				],
				"north": [
					[
						22.9,
						-56.9,
						-71.4,
						-27.8,
						-35.0,
						0
					],
					[
						22.9,
						-56.3,
						-71.4,
						-27.8,
						-34.4,
						0
					],
					[
						22.9,
						-55.8,
						-71.4,
						-27.8,
						-33.9,
						0
					],
					[
						22.9,
						-56.3,
						-71.4,
						-27.8,
						-34.4,
						0
					]
				]
			},
			"walk": {
				"south": [
					[
						-24.3,
						-35.9,
						106.6,
						27.6,
						-35.2,
						0
					],
					[
						-24.3,
						-32.1,
						106.6,
						27.6,
						-31.5,
						0
					],
					[
						-24.3,
						-33.5,
						106.4,
						27.6,
						-33.1,
						0
					],
					[
						-24.3,
						-35.9,
						106.6,
						27.6,
						-35.2,
						0
					],
					[
						-24.3,
						-32.1,
						106.6,
						27.6,
						-31.5,
						0
					],
					[
						-24.3,
						-33.5,
						106.4,
						27.6,
						-33.1,
						0
					]
				],
				"south-east": [
					[
						-3.0,
						-29.4,
						57.7,
						23.4,
						-47.4,
						0
					],
					[
						-3.0,
						-25.6,
						57.7,
						23.4,
						-43.6,
						0
					],
					[
						-2.8,
						-27.1,
						58.2,
						23.5,
						-45.3,
						0
					],
					[
						-3.0,
						-29.4,
						57.7,
						23.4,
						-47.4,
						0
					],
					[
						-3.0,
						-25.6,
						57.7,
						23.4,
						-43.6,
						0
					],
					[
						-2.8,
						-27.1,
						58.2,
						23.5,
						-45.3,
						0
					]
				],
				"east": [
					[
						20.1,
						-33.5,
						24.8,
						5.5,
						-54.2,
						0
					],
					[
						20.1,
						-29.7,
						24.8,
						5.5,
						-50.5,
						0
					],
					[
						20.4,
						-31.3,
						25.5,
						5.7,
						-52.2,
						0
					],
					[
						20.1,
						-33.5,
						24.8,
						5.5,
						-54.2,
						0
					],
					[
						20.1,
						-29.7,
						24.8,
						5.5,
						-50.5,
						0
					],
					[
						20.4,
						-31.3,
						25.5,
						5.7,
						-52.2,
						0
					]
				],
				"north-east": [
					[
						31.4,
						-45.7,
						0.7,
						-15.7,
						-51.8,
						0
					],
					[
						31.4,
						-42.0,
						0.7,
						-15.7,
						-48.0,
						0
					],
					[
						31.6,
						-43.6,
						1.8,
						-15.5,
						-49.9,
						0
					],
					[
						31.4,
						-45.7,
						0.7,
						-15.7,
						-51.8,
						0
					],
					[
						31.4,
						-42.0,
						0.7,
						-15.7,
						-48.0,
						0
					],
					[
						31.6,
						-43.6,
						1.8,
						-15.5,
						-49.9,
						0
					]
				],
				"north": [
					[
						24.3,
						-59.0,
						-45.0,
						-27.6,
						-41.5,
						0
					],
					[
						24.3,
						-55.2,
						-45.0,
						-27.6,
						-37.8,
						0
					],
					[
						24.3,
						-56.9,
						-43.2,
						-27.6,
						-39.6,
						0
					],
					[
						24.3,
						-59.0,
						-45.0,
						-27.6,
						-41.5,
						0
					],
					[
						24.3,
						-55.2,
						-45.0,
						-27.6,
						-37.8,
						0
					],
					[
						24.3,
						-56.9,
						-43.2,
						-27.6,
						-39.6,
						0
					]
				]
			},
			"hurt": {
				"south": [
					[
						-20.5,
						-27.3,
						101.5,
						21.2,
						-30.1,
						0
					],
					[
						-22.7,
						-29.8,
						106.2,
						24.0,
						-31.3,
						0
					],
					[
						-20.5,
						-27.3,
						101.5,
						21.2,
						-30.1,
						0
					]
				],
				"south-east": [
					[
						-11.3,
						-19.8,
						82.2,
						14.4,
						-38.6,
						0
					],
					[
						-15.9,
						-20.6,
						87.2,
						15.6,
						-40.7,
						0
					],
					[
						-11.3,
						-19.8,
						82.2,
						14.4,
						-38.6,
						0
					]
				],
				"east": [
					[
						4.5,
						-18.1,
						65.7,
						-0.7,
						-41.8,
						0
					],
					[
						0.2,
						-16.9,
						69.1,
						-1.9,
						-44.0,
						0
					],
					[
						4.5,
						-18.1,
						65.7,
						-0.7,
						-41.8,
						0
					]
				],
				"north-east": [
					[
						17.7,
						-23.4,
						58.3,
						-15.5,
						-38.0,
						0
					],
					[
						16.2,
						-20.8,
						58.6,
						-18.3,
						-39.1,
						0
					],
					[
						17.7,
						-23.4,
						58.3,
						-15.5,
						-38.0,
						0
					]
				],
				"north": [
					[
						20.5,
						-32.5,
						69.4,
						-21.2,
						-29.3,
						0
					],
					[
						22.7,
						-30.1,
						63.4,
						-24.0,
						-29.1,
						0
					],
					[
						20.5,
						-32.5,
						69.4,
						-21.2,
						-29.3,
						0
					]
				]
			},
			"death": {
				"south": [
					[
						-20.5,
						-27.3,
						101.5,
						21.2,
						-30.1,
						0
					],
					[
						-18.0,
						-32.9,
						105.6,
						19.0,
						-33.6,
						0
					],
					[
						-22.6,
						-33.8,
						120.8,
						23.6,
						-36.9,
						0
					],
					[
						-38.9,
						-25.1,
						179.0,
						37.9,
						-32.0,
						1
					],
					[
						-48.9,
						-29.2,
						-169.3,
						41.3,
						-35.3,
						1
					],
					[
						-54.1,
						-31.4,
						-167.4,
						41.4,
						-35.4,
						1
					]
				],
				"south-east": [
					[
						-11.3,
						-19.8,
						82.2,
						14.4,
						-38.6,
						0
					],
					[
						-3.4,
						-27.8,
						61.2,
						21.5,
						-43.2,
						0
					],
					[
						-18.2,
						-24.1,
						76.8,
						13.6,
						-45.7,
						0
					],
					[
						-41.8,
						-6.0,
						143.3,
						7.5,
						-42.8,
						0
					],
					[
						-55.6,
						-4.4,
						163.2,
						4.1,
						-46.1,
						0
					],
					[
						-62.1,
						-3.8,
						165.7,
						4.0,
						-46.2,
						0
					]
				],
				"east": [
					[
						4.5,
						-18.1,
						65.7,
						-0.7,
						-41.8,
						0
					],
					[
						13.2,
						-30.2,
						29.8,
						11.3,
						-51.0,
						0
					],
					[
						-3.2,
						-19.0,
						39.8,
						-4.4,
						-47.9,
						0
					],
					[
						-20.2,
						8.8,
						55.7,
						-27.3,
						-38.1,
						0
					],
					[
						-29.8,
						15.9,
						97.0,
						-35.5,
						-38.6,
						0
					],
					[
						-33.6,
						19.0,
						108.9,
						-35.8,
						-38.7,
						0
					]
				],
				"north-east": [
					[
						17.7,
						-23.4,
						58.3,
						-15.5,
						-38.0,
						0
					],
					[
						22.0,
						-38.5,
						7.6,
						-5.5,
						-52.4,
						0
					],
					[
						13.7,
						-21.5,
						15.8,
						-19.9,
						-42.1,
						0
					],
					[
						13.2,
						10.4,
						8.7,
						-46.1,
						-20.6,
						0
					],
					[
						13.5,
						19.8,
						21.6,
						-54.3,
						-17.2,
						0
					],
					[
						14.5,
						23.5,
						28.6,
						-54.6,
						-17.2,
						0
					]
				],
				"north": [
					[
						20.5,
						-32.5,
						69.4,
						-21.2,
						-29.3,
						0
					],
					[
						18.0,
						-48.0,
						-30.2,
						-19.0,
						-46.6,
						0
					],
					[
						22.6,
						-30.1,
						-8.9,
						-23.6,
						-31.8,
						0
					],
					[
						38.9,
						-1.9,
						-17.5,
						-37.9,
						-0.7,
						0
					],
					[
						48.9,
						-3.6,
						-7.5,
						-41.3,
						-3.2,
						0
					],
					[
						54.1,
						-1.4,
						-3.0,
						-41.4,
						-3.0,
						0
					]
				]
			},
			"idle_2h": {
				"south": [
					[
						-22.9,
						-36.7,
						104.0,
						-9.8,
						-34.0,
						0
					],
					[
						-22.9,
						-36.1,
						104.0,
						-9.8,
						-33.4,
						0
					],
					[
						-22.9,
						-35.5,
						104.0,
						-9.8,
						-32.8,
						0
					],
					[
						-22.9,
						-36.1,
						104.0,
						-9.8,
						-33.4,
						0
					]
				],
				"south-east": [
					[
						-3.7,
						-30.4,
						43.4,
						6.3,
						-33.1,
						0
					],
					[
						-3.7,
						-29.8,
						43.4,
						6.3,
						-32.6,
						0
					],
					[
						-3.7,
						-29.2,
						43.4,
						6.3,
						-32.0,
						0
					],
					[
						-3.7,
						-29.8,
						43.4,
						6.3,
						-32.6,
						0
					]
				],
				"east": [
					[
						17.6,
						-33.7,
						10.2,
						18.8,
						-39.1,
						0
					],
					[
						17.6,
						-33.1,
						10.2,
						18.8,
						-38.6,
						0
					],
					[
						17.6,
						-32.5,
						10.2,
						18.8,
						-38.0,
						0
					],
					[
						17.6,
						-33.1,
						10.2,
						18.8,
						-38.6,
						0
					]
				],
				"north-east": [
					[
						28.6,
						-44.7,
						-17.1,
						20.3,
						-48.4,
						0
					],
					[
						28.6,
						-44.1,
						-17.1,
						20.3,
						-47.9,
						0
					],
					[
						28.6,
						-43.5,
						-17.1,
						20.3,
						-47.3,
						0
					],
					[
						28.6,
						-44.1,
						-17.1,
						20.3,
						-47.9,
						0
					]
				],
				"north": [
					[
						22.9,
						-56.9,
						-71.4,
						9.8,
						-55.6,
						0
					],
					[
						22.9,
						-56.3,
						-71.4,
						9.8,
						-55.0,
						0
					],
					[
						22.9,
						-55.8,
						-71.4,
						9.8,
						-54.5,
						0
					],
					[
						22.9,
						-56.3,
						-71.4,
						9.8,
						-55.0,
						0
					]
				]
			},
			"walk_2h": {
				"south": [
					[
						-24.3,
						-35.9,
						106.6,
						-10.7,
						-32.4,
						0
					],
					[
						-24.3,
						-32.1,
						106.6,
						-10.7,
						-28.6,
						0
					],
					[
						-24.3,
						-33.5,
						106.4,
						-10.7,
						-29.9,
						0
					],
					[
						-24.3,
						-35.9,
						106.6,
						-10.7,
						-32.4,
						0
					],
					[
						-24.3,
						-32.1,
						106.6,
						-10.7,
						-28.6,
						0
					],
					[
						-24.3,
						-33.5,
						106.4,
						-10.7,
						-29.9,
						0
					]
				],
				"south-east": [
					[
						-3.0,
						-29.4,
						57.7,
						9.0,
						-31.9,
						0
					],
					[
						-3.0,
						-25.6,
						57.7,
						9.0,
						-28.2,
						0
					],
					[
						-2.8,
						-27.1,
						58.2,
						9.2,
						-29.6,
						0
					],
					[
						-3.0,
						-29.4,
						57.7,
						9.0,
						-31.9,
						0
					],
					[
						-3.0,
						-25.6,
						57.7,
						9.0,
						-28.2,
						0
					],
					[
						-2.8,
						-27.1,
						58.2,
						9.2,
						-29.6,
						0
					]
				],
				"east": [
					[
						20.1,
						-33.5,
						24.8,
						23.4,
						-39.6,
						0
					],
					[
						20.1,
						-29.7,
						24.8,
						23.4,
						-35.9,
						0
					],
					[
						20.4,
						-31.3,
						25.5,
						23.7,
						-37.4,
						0
					],
					[
						20.1,
						-33.5,
						24.8,
						23.4,
						-39.6,
						0
					],
					[
						20.1,
						-29.7,
						24.8,
						23.4,
						-35.9,
						0
					],
					[
						20.4,
						-31.3,
						25.5,
						23.7,
						-37.4,
						0
					]
				],
				"north-east": [
					[
						31.4,
						-45.7,
						0.7,
						24.1,
						-50.9,
						0
					],
					[
						31.4,
						-42.0,
						0.7,
						24.1,
						-47.1,
						0
					],
					[
						31.6,
						-43.6,
						1.8,
						24.3,
						-48.9,
						0
					],
					[
						31.4,
						-45.7,
						0.7,
						24.1,
						-50.9,
						0
					],
					[
						31.4,
						-42.0,
						0.7,
						24.1,
						-47.1,
						0
					],
					[
						31.6,
						-43.6,
						1.8,
						24.3,
						-48.9,
						0
					]
				],
				"north": [
					[
						24.3,
						-59.0,
						-45.0,
						10.7,
						-59.2,
						0
					],
					[
						24.3,
						-55.2,
						-45.0,
						10.7,
						-55.4,
						0
					],
					[
						24.3,
						-56.9,
						-43.2,
						10.7,
						-57.2,
						0
					],
					[
						24.3,
						-59.0,
						-45.0,
						10.7,
						-59.2,
						0
					],
					[
						24.3,
						-55.2,
						-45.0,
						10.7,
						-55.4,
						0
					],
					[
						24.3,
						-56.9,
						-43.2,
						10.7,
						-57.2,
						0
					]
				]
			}
		},
		"weapon_axis": "fore"
	},
	"premium/enemies/crab": {
		"kind": "enemy_creature",
		"role": "enemy",
		"weapon_compatible": false,
		"bbox": [
			0,
			0,
			96,
			69
		],
		"feet": [
			48,
			69.12
		],
		"ppu": 30.0,
		"source": {
			"pack": "Quaternius FreeModels mirror",
			"revision": "db3df04d1e4714298a09510b26fb6de6645138a2",
			"license": "CC0 1.0"
		},
		"anims": {
			"idle": {
				"sheet": "res://assets/premium/enemies/crab/idle.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					96,
					96
				]
			},
			"walk": {
				"sheet": "res://assets/premium/enemies/crab/walk.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					96,
					96
				]
			},
			"windup": {
				"sheet": "res://assets/premium/enemies/crab/windup.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					96,
					96
				]
			},
			"attack": {
				"sheet": "res://assets/premium/enemies/crab/attack.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					96,
					96
				]
			},
			"recover": {
				"sheet": "res://assets/premium/enemies/crab/recover.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					2,
					2,
					2,
					2,
					2
				],
				"cell": [
					96,
					96
				]
			},
			"death": {
				"sheet": "res://assets/premium/enemies/crab/death.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					96,
					96
				]
			}
		}
	},
	"premium/enemies/imp": {
		"kind": "enemy_creature",
		"role": "enemy",
		"weapon_compatible": false,
		"bbox": [
			0,
			0,
			112,
			83
		],
		"feet": [
			56,
			82.88
		],
		"ppu": 32.9411764705882,
		"source": {
			"pack": "Quaternius FreeModels mirror",
			"revision": "db3df04d1e4714298a09510b26fb6de6645138a2",
			"license": "CC0 1.0"
		},
		"anims": {
			"idle": {
				"sheet": "res://assets/premium/enemies/imp/idle.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					112,
					112
				]
			},
			"walk": {
				"sheet": "res://assets/premium/enemies/imp/walk.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					112,
					112
				]
			},
			"windup": {
				"sheet": "res://assets/premium/enemies/imp/windup.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					112,
					112
				]
			},
			"attack": {
				"sheet": "res://assets/premium/enemies/imp/attack.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					112,
					112
				]
			},
			"recover": {
				"sheet": "res://assets/premium/enemies/imp/recover.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					2,
					2,
					2,
					2,
					2
				],
				"cell": [
					112,
					112
				]
			},
			"death": {
				"sheet": "res://assets/premium/enemies/imp/death.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					112,
					112
				]
			}
		}
	},
	"premium/enemies/skeleton_crossbow": {
		"kind": "enemy_humanoid",
		"role": "enemy",
		"weapon_compatible": false,
		"bbox": [
			0,
			0,
			144,
			118
		],
		"feet": [
			72,
			118.08
		],
		"ppu": 34.2857142857143,
		"source": {
			"pack": "KayKit Skeletons 1.0",
			"revision": "15b62b9bad122f72926c10fb14d622c73819fa54",
			"license": "CC0 1.0"
		},
		"anims": {
			"idle": {
				"sheet": "res://assets/premium/enemies/skeleton_crossbow/idle.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					144,
					144
				]
			},
			"walk": {
				"sheet": "res://assets/premium/enemies/skeleton_crossbow/walk.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					144,
					144
				]
			},
			"windup": {
				"sheet": "res://assets/premium/enemies/skeleton_crossbow/windup.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					144,
					144
				]
			},
			"attack": {
				"sheet": "res://assets/premium/enemies/skeleton_crossbow/attack.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					144,
					144
				]
			},
			"recover": {
				"sheet": "res://assets/premium/enemies/skeleton_crossbow/recover.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					3,
					3,
					3,
					3,
					3
				],
				"cell": [
					144,
					144
				]
			},
			"death": {
				"sheet": "res://assets/premium/enemies/skeleton_crossbow/death.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					144,
					144
				]
			}
		}
	},
	"premium/enemies/skeleton_warrior": {
		"kind": "enemy_humanoid",
		"role": "enemy",
		"weapon_compatible": false,
		"bbox": [
			0,
			0,
			144,
			118
		],
		"feet": [
			72,
			118.08
		],
		"ppu": 34.2857142857143,
		"source": {
			"pack": "KayKit Skeletons 1.0",
			"revision": "15b62b9bad122f72926c10fb14d622c73819fa54",
			"license": "CC0 1.0"
		},
		"anims": {
			"idle": {
				"sheet": "res://assets/premium/enemies/skeleton_warrior/idle.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					144,
					144
				]
			},
			"walk": {
				"sheet": "res://assets/premium/enemies/skeleton_warrior/walk.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					144,
					144
				]
			},
			"windup": {
				"sheet": "res://assets/premium/enemies/skeleton_warrior/windup.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					144,
					144
				]
			},
			"attack": {
				"sheet": "res://assets/premium/enemies/skeleton_warrior/attack.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					4,
					4,
					4,
					4,
					4
				],
				"cell": [
					144,
					144
				]
			},
			"recover": {
				"sheet": "res://assets/premium/enemies/skeleton_warrior/recover.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					3,
					3,
					3,
					3,
					3
				],
				"cell": [
					144,
					144
				]
			},
			"death": {
				"sheet": "res://assets/premium/enemies/skeleton_warrior/death.png",
				"dirs": [
					"south",
					"south-east",
					"east",
					"north-east",
					"north"
				],
				"counts": [
					6,
					6,
					6,
					6,
					6
				],
				"cell": [
					144,
					144
				]
			}
		}
	}
}

const STATIC := {
	"premium/dungeon/castle/wall": {
		"path": "res://assets/premium/dungeon/castle/wall.png",
		"size": [
			276,
			266
		],
		"bbox": [
			0,
			0,
			276,
			266
		],
		"anchor": [
			138.0,
			244.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "wall.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/wall_cracked": {
		"path": "res://assets/premium/dungeon/castle/wall_cracked.png",
		"size": [
			276,
			266
		],
		"bbox": [
			0,
			0,
			276,
			266
		],
		"anchor": [
			138.0,
			244.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "wall_cracked.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/wall_arched": {
		"path": "res://assets/premium/dungeon/castle/wall_arched.png",
		"size": [
			276,
			266
		],
		"bbox": [
			0,
			0,
			276,
			266
		],
		"anchor": [
			138.0,
			244.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "wall_arched.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/wall_window_closed": {
		"path": "res://assets/premium/dungeon/castle/wall_window_closed.png",
		"size": [
			276,
			266
		],
		"bbox": [
			0,
			0,
			276,
			266
		],
		"anchor": [
			138.0,
			244.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "wall_window_closed.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/wall_half": {
		"path": "res://assets/premium/dungeon/castle/wall_half.png",
		"size": [
			140,
			266
		],
		"bbox": [
			0,
			0,
			140,
			266
		],
		"anchor": [
			2.0,
			244.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "wall_half.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/wall_corner": {
		"path": "res://assets/premium/dungeon/castle/wall_corner.png",
		"size": [
			174,
			324
		],
		"bbox": [
			0,
			0,
			174,
			324
		],
		"anchor": [
			138.0,
			244.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "wall_corner.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/floor_tile_small": {
		"path": "res://assets/premium/dungeon/castle/floor_tile_small.png",
		"size": [
			136,
			136
		],
		"bbox": [
			0,
			0,
			136,
			136
		],
		"anchor": [
			68.0,
			68.0
		],
		"scale": 0.38235294117647056,
		"pitch": 90.0,
		"source_file": "floor_tile_small.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/floor_tile_small_broken_A": {
		"path": "res://assets/premium/dungeon/castle/floor_tile_small_broken_A.png",
		"size": [
			136,
			136
		],
		"bbox": [
			0,
			0,
			136,
			136
		],
		"anchor": [
			68.0,
			68.0
		],
		"scale": 0.38235294117647056,
		"pitch": 90.0,
		"source_file": "floor_tile_small_broken_A.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/floor_tile_small_broken_B": {
		"path": "res://assets/premium/dungeon/castle/floor_tile_small_broken_B.png",
		"size": [
			136,
			136
		],
		"bbox": [
			0,
			0,
			136,
			136
		],
		"anchor": [
			68.0,
			68.0
		],
		"scale": 0.38235294117647056,
		"pitch": 90.0,
		"source_file": "floor_tile_small_broken_B.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/floor_tile_small_weeds_A": {
		"path": "res://assets/premium/dungeon/castle/floor_tile_small_weeds_A.png",
		"size": [
			136,
			136
		],
		"bbox": [
			0,
			0,
			136,
			136
		],
		"anchor": [
			68.0,
			68.0
		],
		"scale": 0.38235294117647056,
		"pitch": 90.0,
		"source_file": "floor_tile_small_weeds_A.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/floor_tile_small_decorated": {
		"path": "res://assets/premium/dungeon/castle/floor_tile_small_decorated.png",
		"size": [
			136,
			136
		],
		"bbox": [
			0,
			0,
			136,
			136
		],
		"anchor": [
			68.0,
			68.0
		],
		"scale": 0.38235294117647056,
		"pitch": 90.0,
		"source_file": "floor_tile_small_decorated.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/floor_tile_large": {
		"path": "res://assets/premium/dungeon/castle/floor_tile_large.png",
		"size": [
			272,
			272
		],
		"bbox": [
			0,
			0,
			272,
			272
		],
		"anchor": [
			136.0,
			136.0
		],
		"scale": 0.38235294117647056,
		"pitch": 90.0,
		"source_file": "floor_tile_large.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/floor_tile_grate": {
		"path": "res://assets/premium/dungeon/castle/floor_tile_grate.png",
		"size": [
			272,
			136
		],
		"bbox": [
			0,
			0,
			272,
			136
		],
		"anchor": [
			136.0,
			68.0
		],
		"scale": 0.38235294117647056,
		"pitch": 90.0,
		"source_file": "floor_tile_grate.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/barrel_large": {
		"path": "res://assets/premium/dungeon/castle/barrel_large.png",
		"size": [
			130,
			166
		],
		"bbox": [
			0,
			0,
			130,
			166
		],
		"anchor": [
			65.0,
			138.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "barrel_large.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/barrel_large_decorated": {
		"path": "res://assets/premium/dungeon/castle/barrel_large_decorated.png",
		"size": [
			139,
			182
		],
		"bbox": [
			0,
			0,
			139,
			182
		],
		"anchor": [
			66.0,
			148.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "barrel_large_decorated.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/barrel_small_stack": {
		"path": "res://assets/premium/dungeon/castle/barrel_small_stack.png",
		"size": [
			133,
			130
		],
		"bbox": [
			0,
			0,
			133,
			130
		],
		"anchor": [
			66.5,
			114.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "barrel_small_stack.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/keg_decorated": {
		"path": "res://assets/premium/dungeon/castle/keg_decorated.png",
		"size": [
			247,
			171
		],
		"bbox": [
			0,
			0,
			247,
			171
		],
		"anchor": [
			127.5,
			140.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "keg_decorated.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/box_large": {
		"path": "res://assets/premium/dungeon/castle/box_large.png",
		"size": [
			109,
			144
		],
		"bbox": [
			0,
			0,
			109,
			144
		],
		"anchor": [
			54.5,
			113.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "box_large.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/box_stacked": {
		"path": "res://assets/premium/dungeon/castle/box_stacked.png",
		"size": [
			244,
			283
		],
		"bbox": [
			0,
			0,
			244,
			283
		],
		"anchor": [
			122.5,
			208.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "box_stacked.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/crates_stacked": {
		"path": "res://assets/premium/dungeon/castle/crates_stacked.png",
		"size": [
			150,
			190
		],
		"bbox": [
			0,
			0,
			150,
			190
		],
		"anchor": [
			78.0,
			145.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "crates_stacked.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/box_small_decorated": {
		"path": "res://assets/premium/dungeon/castle/box_small_decorated.png",
		"size": [
			109,
			142
		],
		"bbox": [
			0,
			0,
			109,
			142
		],
		"anchor": [
			45.5,
			105.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "box_small_decorated.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/column": {
		"path": "res://assets/premium/dungeon/castle/column.png",
		"size": [
			55,
			102
		],
		"bbox": [
			0,
			0,
			55,
			102
		],
		"anchor": [
			27.5,
			84.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "column.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/pillar_decorated": {
		"path": "res://assets/premium/dungeon/castle/pillar_decorated.png",
		"size": [
			159,
			289
		],
		"bbox": [
			0,
			0,
			159,
			289
		],
		"anchor": [
			79.5,
			256.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "pillar_decorated.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/table_long": {
		"path": "res://assets/premium/dungeon/castle/table_long.png",
		"size": [
			279,
			136
		],
		"bbox": [
			0,
			0,
			279,
			136
		],
		"anchor": [
			139.5,
			97.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "table_long.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/table_long_decorated_A": {
		"path": "res://assets/premium/dungeon/castle/table_long_decorated_A.png",
		"size": [
			279,
			154
		],
		"bbox": [
			0,
			0,
			279,
			154
		],
		"anchor": [
			139.5,
			116.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "table_long_decorated_A.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/table_medium_tablecloth_decorated_B": {
		"path": "res://assets/premium/dungeon/castle/table_medium_tablecloth_decorated_B.png",
		"size": [
			143,
			160
		],
		"bbox": [
			0,
			0,
			143,
			160
		],
		"anchor": [
			71.5,
			122.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "table_medium_tablecloth_decorated_B.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/chair": {
		"path": "res://assets/premium/dungeon/castle/chair.png",
		"size": [
			72,
			102
		],
		"bbox": [
			0,
			0,
			72,
			102
		],
		"anchor": [
			36.0,
			82.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "chair.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/stool": {
		"path": "res://assets/premium/dungeon/castle/stool.png",
		"size": [
			58,
			62
		],
		"bbox": [
			0,
			0,
			58,
			62
		],
		"anchor": [
			29.0,
			45.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "stool.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/shelf_large": {
		"path": "res://assets/premium/dungeon/castle/shelf_large.png",
		"size": [
			143,
			38
		],
		"bbox": [
			0,
			0,
			143,
			38
		],
		"anchor": [
			71.5,
			9.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "shelf_large.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/shelf_small_candles": {
		"path": "res://assets/premium/dungeon/castle/shelf_small_candles.png",
		"size": [
			75,
			64
		],
		"bbox": [
			0,
			0,
			75,
			64
		],
		"anchor": [
			37.5,
			36.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "shelf_small_candles.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/torch_mounted": {
		"path": "res://assets/premium/dungeon/castle/torch_mounted.png",
		"size": [
			45,
			68
		],
		"bbox": [
			0,
			0,
			45,
			68
		],
		"anchor": [
			22.5,
			38.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "torch_mounted.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/torch_lit": {
		"path": "res://assets/premium/dungeon/castle/torch_lit.png",
		"size": [
			45,
			76
		],
		"bbox": [
			0,
			0,
			45,
			76
		],
		"anchor": [
			22.5,
			49.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "torch_lit.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/banner_red": {
		"path": "res://assets/premium/dungeon/castle/banner_red.png",
		"size": [
			109,
			180
		],
		"bbox": [
			0,
			0,
			109,
			180
		],
		"anchor": [
			54.5,
			191.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "banner_red.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/banner_patternA_red": {
		"path": "res://assets/premium/dungeon/castle/banner_patternA_red.png",
		"size": [
			109,
			180
		],
		"bbox": [
			0,
			0,
			109,
			180
		],
		"anchor": [
			54.5,
			191.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "banner_patternA_red.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/banner_shield_red": {
		"path": "res://assets/premium/dungeon/castle/banner_shield_red.png",
		"size": [
			159,
			180
		],
		"bbox": [
			0,
			0,
			159,
			180
		],
		"anchor": [
			79.5,
			191.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "banner_shield_red.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/banner_thin_red": {
		"path": "res://assets/premium/dungeon/castle/banner_thin_red.png",
		"size": [
			82,
			179
		],
		"bbox": [
			0,
			0,
			82,
			179
		],
		"anchor": [
			41.0,
			191.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "banner_thin_red.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/sword_shield": {
		"path": "res://assets/premium/dungeon/castle/sword_shield.png",
		"size": [
			159,
			107
		],
		"bbox": [
			0,
			0,
			159,
			107
		],
		"anchor": [
			79.5,
			52.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "sword_shield.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/sword_shield_gold": {
		"path": "res://assets/premium/dungeon/castle/sword_shield_gold.png",
		"size": [
			159,
			107
		],
		"bbox": [
			0,
			0,
			159,
			107
		],
		"anchor": [
			79.5,
			52.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "sword_shield_gold.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/chest": {
		"path": "res://assets/premium/dungeon/castle/chest.png",
		"size": [
			123,
			114
		],
		"bbox": [
			0,
			0,
			123,
			114
		],
		"anchor": [
			61.5,
			88.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "chest.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/chest_gold": {
		"path": "res://assets/premium/dungeon/castle/chest_gold.png",
		"size": [
			123,
			114
		],
		"bbox": [
			0,
			0,
			123,
			114
		],
		"anchor": [
			61.5,
			88.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "chest_gold.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/candle_triple": {
		"path": "res://assets/premium/dungeon/castle/candle_triple.png",
		"size": [
			42,
			68
		],
		"bbox": [
			0,
			0,
			42,
			68
		],
		"anchor": [
			15.0,
			55.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "candle_triple.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/trunk_large_A": {
		"path": "res://assets/premium/dungeon/castle/trunk_large_A.png",
		"size": [
			109,
			96
		],
		"bbox": [
			0,
			0,
			109,
			96
		],
		"anchor": [
			54.5,
			73.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "trunk_large_A.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/coin_stack_large": {
		"path": "res://assets/premium/dungeon/castle/coin_stack_large.png",
		"size": [
			105,
			109
		],
		"bbox": [
			0,
			0,
			105,
			109
		],
		"anchor": [
			52.5,
			74.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "coin_stack_large.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/bed_frame": {
		"path": "res://assets/premium/dungeon/castle/bed_frame.png",
		"size": [
			109,
			170
		],
		"bbox": [
			0,
			0,
			109,
			170
		],
		"anchor": [
			54.5,
			111.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "bed_frame.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/barrier_column": {
		"path": "res://assets/premium/dungeon/castle/barrier_column.png",
		"size": [
			279,
			102
		],
		"bbox": [
			0,
			0,
			279,
			102
		],
		"anchor": [
			139.5,
			84.0
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "barrier_column.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/dungeon/castle/wall_pillar": {
		"path": "res://assets/premium/dungeon/castle/wall_pillar.png",
		"size": [
			276,
			286
		],
		"bbox": [
			0,
			0,
			276,
			286
		],
		"anchor": [
			138.0,
			254.5
		],
		"scale": 0.38235294117647056,
		"pitch": 35.0,
		"source_file": "wall_pillar.gltf.glb",
		"source": {
			"pack": "KayKit Dungeon Remastered 1.0",
			"revision": "b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07",
			"license": "CC0 1.0"
		}
	},
	"premium/weapons/pulsar": {
		"path": "res://assets/premium/weapons/pulsar.png",
		"size": [
			84,
			39
		],
		"bbox": [
			0,
			0,
			84,
			39
		],
		"anchor": [
			29.67,
			21.33
		],
		"scale": 0.3760869565217391,
		"pitch": 35.0,
		"source_file": "original:pulsar",
		"points": {
			"grip": [
				0.0,
				0.0
			],
			"grip2": [
				27.6,
				1.32
			],
			"tip": [
				51.06,
				-7.65
			]
		},
		"source": {
			"pack": "RPG Premium original models",
			"revision": "original",
			"license": "Original work (RPG Premium)"
		}
	},
	"premium/weapons/chispa": {
		"path": "res://assets/premium/weapons/chispa.png",
		"size": [
			44,
			35
		],
		"bbox": [
			0,
			0,
			44,
			35
		],
		"anchor": [
			11.67,
			20.0
		],
		"scale": 0.3760869565217391,
		"pitch": 35.0,
		"source_file": "original:chispa",
		"points": {
			"grip": [
				0.0,
				0.0
			],
			"tip": [
				28.98,
				-6.78
			]
		},
		"source": {
			"pack": "RPG Premium original models",
			"revision": "original",
			"license": "Original work (RPG Premium)"
		}
	},
	"premium/weapons/trinca": {
		"path": "res://assets/premium/weapons/trinca.png",
		"size": [
			114,
			39
		],
		"bbox": [
			0,
			0,
			114,
			39
		],
		"anchor": [
			39.0,
			21.33
		],
		"scale": 0.3760869565217391,
		"pitch": 35.0,
		"source_file": "original:trinca",
		"points": {
			"grip": [
				0.0,
				0.0
			],
			"grip2": [
				27.6,
				1.32
			],
			"tip": [
				71.3,
				-7.65
			]
		},
		"source": {
			"pack": "RPG Premium original models",
			"revision": "original",
			"license": "Original work (RPG Premium)"
		}
	},
	"premium/weapons/maul12": {
		"path": "res://assets/premium/weapons/maul12.png",
		"size": [
			100,
			36
		],
		"bbox": [
			0,
			0,
			100,
			36
		],
		"anchor": [
			36.33,
			20.0
		],
		"scale": 0.3760869565217391,
		"pitch": 35.0,
		"source_file": "original:maul12",
		"points": {
			"grip": [
				0.0,
				0.0
			],
			"grip2": [
				27.6,
				1.7
			],
			"tip": [
				60.26,
				-7.72
			]
		},
		"source": {
			"pack": "RPG Premium original models",
			"revision": "original",
			"license": "Original work (RPG Premium)"
		}
	},
	"premium/weapons/filo_z": {
		"path": "res://assets/premium/weapons/filo_z.png",
		"size": [
			123,
			40
		],
		"bbox": [
			0,
			0,
			123,
			40
		],
		"anchor": [
			23.33,
			20.0
		],
		"scale": 0.3760869565217391,
		"pitch": 35.0,
		"source_file": "original:filo_z",
		"points": {
			"grip": [
				0.0,
				0.0
			],
			"tip": [
				92.0,
				0.0
			]
		},
		"source": {
			"pack": "RPG Premium original models",
			"revision": "original",
			"license": "Original work (RPG Premium)"
		}
	}
}
