class_name AssetManifest
extends RefCounted
## GENERADO por tools/migrate_assets.py (no editar a mano). Hojas de animacion y estaticos migrados.
## anims[id].anims[anim] = {sheet, dirs (filas), counts (frames por fila), cell}; bbox = caja opaca union (pies = y max).

const ANIMS := {
	"rpg/characters/human_ranger": {
		"state": "migrate",
		"bbox": [35, 13, 72, 88],
		"anims": {
			"attack": {
				"sheet": "res://assets/migrated/rpg/characters/human_ranger/attack.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [9, 9, 9, 9],
				"cell": [108, 108]
			},
			"dash": {
				"sheet": "res://assets/migrated/rpg/characters/human_ranger/dash.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 7, 7, 7],
				"cell": [108, 108]
			},
			"death": {
				"sheet": "res://assets/migrated/rpg/characters/human_ranger/death.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [9, 9, 9, 9],
				"cell": [108, 108]
			},
			"hurt": {
				"sheet": "res://assets/migrated/rpg/characters/human_ranger/hurt.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 7, 7, 7],
				"cell": [108, 108]
			},
			"idle": {
				"sheet": "res://assets/migrated/rpg/characters/human_ranger/idle.png",
				"dirs": ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"],
				"counts": [9, 9, 9, 9, 9, 9, 9, 9],
				"cell": [108, 108]
			},
			"walk": {
				"sheet": "res://assets/migrated/rpg/characters/human_ranger/walk.png",
				"dirs": ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"],
				"counts": [9, 9, 9, 9, 9, 9, 9, 9],
				"cell": [108, 108]
			}
		}
	},
	"rpg/characters/combat_android": {
		"state": "migrate",
		"bbox": [31, 15, 65, 90],
		"anims": {
			"attack": {
				"sheet": "res://assets/migrated/rpg/characters/combat_android/attack.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"dash": {
				"sheet": "res://assets/migrated/rpg/characters/combat_android/dash.png",
				"dirs": ["south"],
				"counts": [6],
				"cell": [96, 96]
			},
			"death": {
				"sheet": "res://assets/migrated/rpg/characters/combat_android/death.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [96, 96]
			},
			"hurt": {
				"sheet": "res://assets/migrated/rpg/characters/combat_android/hurt.png",
				"dirs": ["south"],
				"counts": [6],
				"cell": [96, 96]
			},
			"idle": {
				"sheet": "res://assets/migrated/rpg/characters/combat_android/idle.png",
				"dirs": ["south"],
				"counts": [8],
				"cell": [96, 96]
			},
			"walk": {
				"sheet": "res://assets/migrated/rpg/characters/combat_android/walk.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [8, 8, 8, 8],
				"cell": [96, 96]
			},
			"hurt_alt": {
				"sheet": "res://assets/migrated/rpg/characters/combat_android/hurt_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [560, 112]
			},
			"attack_alt": {
				"sheet": "res://assets/migrated/rpg/characters/combat_android/attack_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [784, 112]
			},
			"dash_alt": {
				"sheet": "res://assets/migrated/rpg/characters/combat_android/dash_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [576, 96]
			},
			"idle_alt": {
				"sheet": "res://assets/migrated/rpg/characters/combat_android/idle_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [560, 112]
			}
		}
	},
	"rpg/characters/beetle_cyborg": {
		"state": "migrate",
		"bbox": [44, 19, 83, 109],
		"anims": {
			"attack": {
				"sheet": "res://assets/migrated/rpg/characters/beetle_cyborg/attack.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			},
			"dash": {
				"sheet": "res://assets/migrated/rpg/characters/beetle_cyborg/dash.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			},
			"death": {
				"sheet": "res://assets/migrated/rpg/characters/beetle_cyborg/death.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			},
			"hurt": {
				"sheet": "res://assets/migrated/rpg/characters/beetle_cyborg/hurt.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			},
			"idle": {
				"sheet": "res://assets/migrated/rpg/characters/beetle_cyborg/idle.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			},
			"walk": {
				"sheet": "res://assets/migrated/rpg/characters/beetle_cyborg/walk.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 9, 9, 9],
				"cell": [132, 132]
			},
			"hurt_alt": {
				"sheet": "res://assets/migrated/rpg/characters/beetle_cyborg/hurt_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [660, 132]
			},
			"attack_alt": {
				"sheet": "res://assets/migrated/rpg/characters/beetle_cyborg/attack_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [924, 132]
			},
			"dash_alt": {
				"sheet": "res://assets/migrated/rpg/characters/beetle_cyborg/dash_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [924, 132]
			},
			"idle_alt": {
				"sheet": "res://assets/migrated/rpg/characters/beetle_cyborg/idle_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [660, 132]
			}
		}
	},
	"rpg/characters/mutant_striker": {
		"state": "migrate",
		"bbox": [34, 18, 74, 95],
		"anims": {
			"attack": {
				"sheet": "res://assets/migrated/rpg/characters/mutant_striker/attack.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [112, 112]
			},
			"dash": {
				"sheet": "res://assets/migrated/rpg/characters/mutant_striker/dash.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [112, 112]
			},
			"death": {
				"sheet": "res://assets/migrated/rpg/characters/mutant_striker/death.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [112, 112]
			},
			"hurt": {
				"sheet": "res://assets/migrated/rpg/characters/mutant_striker/hurt.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [112, 112]
			},
			"idle": {
				"sheet": "res://assets/migrated/rpg/characters/mutant_striker/idle.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [112, 112]
			},
			"walk": {
				"sheet": "res://assets/migrated/rpg/characters/mutant_striker/walk.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 9, 9, 9],
				"cell": [116, 116]
			},
			"hurt_alt": {
				"sheet": "res://assets/migrated/rpg/characters/mutant_striker/hurt_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [580, 116]
			},
			"attack_alt": {
				"sheet": "res://assets/migrated/rpg/characters/mutant_striker/attack_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [812, 116]
			},
			"dash_alt": {
				"sheet": "res://assets/migrated/rpg/characters/mutant_striker/dash_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [812, 116]
			},
			"idle_alt": {
				"sheet": "res://assets/migrated/rpg/characters/mutant_striker/idle_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [580, 116]
			}
		}
	},
	"rpg/enemies/bone_guard": {
		"state": "migrate",
		"bbox": [26, 17, 66, 78],
		"anims": {
			"attack": {
				"sheet": "res://assets/migrated/rpg/enemies/bone_guard/attack.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [96, 96]
			},
			"death": {
				"sheet": "res://assets/migrated/rpg/enemies/bone_guard/death.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 9, 9, 9],
				"cell": [96, 96]
			},
			"guard_fatigue": {
				"sheet": "res://assets/migrated/rpg/enemies/bone_guard/guard_fatigue.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [4, 7, 7, 7],
				"cell": [96, 96]
			},
			"hurt": {
				"sheet": "res://assets/migrated/rpg/enemies/bone_guard/hurt.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 7, 7, 7],
				"cell": [96, 96]
			},
			"idle": {
				"sheet": "res://assets/migrated/rpg/enemies/bone_guard/idle.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [96, 96]
			},
			"move": {
				"sheet": "res://assets/migrated/rpg/enemies/bone_guard/move.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [96, 96]
			},
			"shield_block": {
				"sheet": "res://assets/migrated/rpg/enemies/bone_guard/shield_block.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 7, 7, 7],
				"cell": [96, 96]
			},
			"shield_idle": {
				"sheet": "res://assets/migrated/rpg/enemies/bone_guard/shield_idle.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 9, 9, 9],
				"cell": [96, 96]
			},
			"walk": {
				"sheet": "res://assets/migrated/rpg/enemies/bone_guard/walk.png",
				"dirs": ["east", "north", "west"],
				"counts": [7, 7, 7],
				"cell": [96, 96]
			},
			"attack_alt": {
				"sheet": "res://assets/migrated/rpg/enemies/bone_guard/attack_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [672, 96]
			},
			"bash_windup_alt": {
				"sheet": "res://assets/migrated/rpg/enemies/bone_guard/bash_windup_alt.png",
				"dirs": ["south"],
				"counts": [4],
				"cell": [480, 96]
			}
		}
	},
	"rpg/enemies/iron_beetle": {
		"state": "migrate",
		"bbox": [19, 27, 90, 88],
		"anims": {
			"attack": {
				"sheet": "res://assets/migrated/rpg/enemies/iron_beetle/attack.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"death": {
				"sheet": "res://assets/migrated/rpg/enemies/iron_beetle/death.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 9, 9, 9],
				"cell": [108, 108]
			},
			"hurt": {
				"sheet": "res://assets/migrated/rpg/enemies/iron_beetle/hurt.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 7, 7, 7],
				"cell": [108, 108]
			},
			"idle": {
				"sheet": "res://assets/migrated/rpg/enemies/iron_beetle/idle.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 9, 9, 9],
				"cell": [108, 108]
			},
			"move": {
				"sheet": "res://assets/migrated/rpg/enemies/iron_beetle/move.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"roll": {
				"sheet": "res://assets/migrated/rpg/enemies/iron_beetle/roll.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"roll_impact": {
				"sheet": "res://assets/migrated/rpg/enemies/iron_beetle/roll_impact.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"roll_recovery": {
				"sheet": "res://assets/migrated/rpg/enemies/iron_beetle/roll_recovery.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 9, 9, 9],
				"cell": [108, 108]
			},
			"roll_windup": {
				"sheet": "res://assets/migrated/rpg/enemies/iron_beetle/roll_windup.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"walk": {
				"sheet": "res://assets/migrated/rpg/enemies/iron_beetle/walk.png",
				"dirs": ["east", "north", "west"],
				"counts": [7, 7, 7],
				"cell": [104, 104]
			},
			"roll_alt": {
				"sheet": "res://assets/migrated/rpg/enemies/iron_beetle/roll_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [728, 104]
			},
			"roll_windup_alt": {
				"sheet": "res://assets/migrated/rpg/enemies/iron_beetle/roll_windup_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [520, 104]
			}
		}
	},
	"rpg/enemies/orb_stalker": {
		"state": "migrate",
		"bbox": [22, 19, 81, 83],
		"anims": {
			"attack": {
				"sheet": "res://assets/migrated/rpg/enemies/orb_stalker/attack.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"casting": {
				"sheet": "res://assets/migrated/rpg/enemies/orb_stalker/casting.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"death": {
				"sheet": "res://assets/migrated/rpg/enemies/orb_stalker/death.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"hurt": {
				"sheet": "res://assets/migrated/rpg/enemies/orb_stalker/hurt.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"idle": {
				"sheet": "res://assets/migrated/rpg/enemies/orb_stalker/idle.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"move": {
				"sheet": "res://assets/migrated/rpg/enemies/orb_stalker/move.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"projectile_attack": {
				"sheet": "res://assets/migrated/rpg/enemies/orb_stalker/projectile_attack.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 7, 7, 7],
				"cell": [108, 108]
			},
			"ranged_windup": {
				"sheet": "res://assets/migrated/rpg/enemies/orb_stalker/ranged_windup.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [9, 9, 9, 9],
				"cell": [108, 108]
			},
			"teleport": {
				"sheet": "res://assets/migrated/rpg/enemies/orb_stalker/teleport.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [108, 108]
			},
			"walk": {
				"sheet": "res://assets/migrated/rpg/enemies/orb_stalker/walk.png",
				"dirs": ["east", "north", "west"],
				"counts": [7, 7, 7],
				"cell": [100, 100]
			}
		}
	},
	"rpg/enemies/raptor": {
		"state": "migrate",
		"bbox": [33, 18, 78, 94],
		"anims": {
			"attack": {
				"sheet": "res://assets/migrated/rpg/enemies/raptor/attack.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [112, 112]
			},
			"death": {
				"sheet": "res://assets/migrated/rpg/enemies/raptor/death.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 9, 9, 9],
				"cell": [112, 112]
			},
			"hurt": {
				"sheet": "res://assets/migrated/rpg/enemies/raptor/hurt.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 7, 7, 7],
				"cell": [112, 112]
			},
			"idle": {
				"sheet": "res://assets/migrated/rpg/enemies/raptor/idle.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 9, 9, 9],
				"cell": [112, 112]
			},
			"lunge_attack": {
				"sheet": "res://assets/migrated/rpg/enemies/raptor/lunge_attack.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [112, 112]
			},
			"lunge_windup": {
				"sheet": "res://assets/migrated/rpg/enemies/raptor/lunge_windup.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 7, 7, 7],
				"cell": [112, 112]
			},
			"move": {
				"sheet": "res://assets/migrated/rpg/enemies/raptor/move.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [112, 112]
			},
			"recovery": {
				"sheet": "res://assets/migrated/rpg/enemies/raptor/recovery.png",
				"dirs": ["east", "north", "west"],
				"counts": [9, 9, 9],
				"cell": [112, 112]
			},
			"walk": {
				"sheet": "res://assets/migrated/rpg/enemies/raptor/walk.png",
				"dirs": ["east", "north", "west"],
				"counts": [7, 14, 7],
				"cell": [112, 112]
			},
			"lunge_attack_alt": {
				"sheet": "res://assets/migrated/rpg/enemies/raptor/lunge_attack_alt.png",
				"dirs": ["south"],
				"counts": [3],
				"cell": [784, 112]
			}
		}
	},
	"rpg/enemies/root_vine": {
		"state": "migrate",
		"bbox": [20, 18, 106, 109],
		"anims": {
			"attack": {
				"sheet": "res://assets/migrated/rpg/enemies/root_vine/attack.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			},
			"death": {
				"sheet": "res://assets/migrated/rpg/enemies/root_vine/death.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			},
			"grab_pull": {
				"sheet": "res://assets/migrated/rpg/enemies/root_vine/grab_pull.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			},
			"grab_windup": {
				"sheet": "res://assets/migrated/rpg/enemies/root_vine/grab_windup.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			},
			"hurt": {
				"sheet": "res://assets/migrated/rpg/enemies/root_vine/hurt.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			},
			"idle": {
				"sheet": "res://assets/migrated/rpg/enemies/root_vine/idle.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			},
			"move": {
				"sheet": "res://assets/migrated/rpg/enemies/root_vine/move.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			},
			"vine_grab": {
				"sheet": "res://assets/migrated/rpg/enemies/root_vine/vine_grab.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [128, 128]
			}
		}
	},
	"rpg/bosses/rift_warden": {
		"state": "migrate",
		"bbox": [76, 35, 143, 195],
		"anims": {
			"attack": {
				"sheet": "res://assets/migrated/rpg/bosses/rift_warden/attack.png",
				"dirs": ["east", "north", "west"],
				"counts": [9, 9, 9],
				"cell": [228, 228]
			},
			"death": {
				"sheet": "res://assets/migrated/rpg/bosses/rift_warden/death.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 9, 9, 9],
				"cell": [228, 228]
			},
			"dimensional_cast": {
				"sheet": "res://assets/migrated/rpg/bosses/rift_warden/dimensional_cast.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [228, 228]
			},
			"hurt": {
				"sheet": "res://assets/migrated/rpg/bosses/rift_warden/hurt.png",
				"dirs": ["south", "east", "north", "west"],
				"counts": [7, 7, 7, 7],
				"cell": [228, 228]
			},
			"idle": {
				"sheet": "res://assets/migrated/rpg/bosses/rift_warden/idle.png",
				"dirs": ["east", "north", "west"],
				"counts": [9, 9, 9],
				"cell": [228, 228]
			},
			"idle_float": {
				"sheet": "res://assets/migrated/rpg/bosses/rift_warden/idle_float.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [228, 228]
			},
			"projectile_cast": {
				"sheet": "res://assets/migrated/rpg/bosses/rift_warden/projectile_cast.png",
				"dirs": ["south"],
				"counts": [7],
				"cell": [228, 228]
			},
			"walk": {
				"sheet": "res://assets/migrated/rpg/bosses/rift_warden/walk.png",
				"dirs": ["east", "north", "west"],
				"counts": [9, 9, 9],
				"cell": [228, 228]
			}
		}
	},
	"vida/npc/male": {
		"state": "migrate",
		"bbox": [9, 1, 24, 28],
		"anims": {
			"walk": {
				"sheet": "res://assets/migrated/vida/npc/male/walk.png",
				"dirs": ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"],
				"counts": [8, 8, 8, 8, 8, 8, 8, 8],
				"cell": [32, 32]
			},
			"idle": {
				"sheet": "res://assets/migrated/vida/npc/male/idle.png",
				"dirs": ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"],
				"counts": [1, 1, 1, 1, 1, 1, 1, 1],
				"cell": [32, 32]
			},
			"phone": {
				"sheet": "res://assets/migrated/vida/npc/male/phone.png",
				"dirs": ["south"],
				"counts": [9],
				"cell": [40, 40]
			}
		}
	},
	"vida/npc/female": {
		"state": "migrate",
		"bbox": [18, 7, 30, 41],
		"anims": {
			"walk": {
				"sheet": "res://assets/migrated/vida/npc/female/walk.png",
				"dirs": ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"],
				"counts": [8, 8, 8, 8, 8, 8, 8, 8],
				"cell": [48, 48]
			},
			"idle": {
				"sheet": "res://assets/migrated/vida/npc/female/idle.png",
				"dirs": ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"],
				"counts": [1, 1, 1, 1, 1, 1, 1, 1],
				"cell": [48, 48]
			},
			"phone": {
				"sheet": "res://assets/migrated/vida/npc/female/phone.png",
				"dirs": ["south"],
				"counts": [9],
				"cell": [48, 48]
			},
			"drink": {
				"sheet": "res://assets/migrated/vida/npc/female/drink.png",
				"dirs": ["south"],
				"counts": [9],
				"cell": [48, 48]
			}
		}
	}
}

const STATIC := {
	"rpg/ui/portraits/beetle_cyborg_portrait": {
		"path": "res://assets/migrated/rpg/ui/portraits/beetle_cyborg_portrait.png",
		"size": [64, 64],
		"bbox": [1, 1, 63, 63]
	},
	"rpg/ui/portraits/combat_android_portrait": {
		"path": "res://assets/migrated/rpg/ui/portraits/combat_android_portrait.png",
		"size": [64, 64],
		"bbox": [1, 2, 63, 61]
	},
	"rpg/ui/portraits/human_ranger_portrait": {
		"path": "res://assets/migrated/rpg/ui/portraits/human_ranger_portrait.png",
		"size": [64, 64],
		"bbox": [3, 0, 61, 63]
	},
	"rpg/ui/portraits/mutant_striker_portrait": {
		"path": "res://assets/migrated/rpg/ui/portraits/mutant_striker_portrait.png",
		"size": [64, 64],
		"bbox": [0, 1, 64, 63]
	},
	"rpg/props/rooms/boss_arena_pillar": {
		"path": "res://assets/migrated/rpg/props/rooms/boss_arena_pillar.png",
		"size": [128, 192],
		"bbox": [9, 5, 118, 187]
	},
	"rpg/props/rooms/boss_arena_seal": {
		"path": "res://assets/migrated/rpg/props/rooms/boss_arena_seal.png",
		"size": [96, 96],
		"bbox": [7, 11, 88, 85]
	},
	"rpg/props/rooms/challenge_obelisk": {
		"path": "res://assets/migrated/rpg/props/rooms/challenge_obelisk.png",
		"size": [48, 80],
		"bbox": [6, 1, 43, 79]
	},
	"rpg/props/rooms/challenge_rune_plate": {
		"path": "res://assets/migrated/rpg/props/rooms/challenge_rune_plate.png",
		"size": [128, 128],
		"bbox": [9, 10, 119, 118]
	},
	"rpg/props/rooms/combat_blood_decal": {
		"path": "res://assets/migrated/rpg/props/rooms/combat_blood_decal.png",
		"size": [96, 96],
		"bbox": [8, 4, 85, 71]
	},
	"rpg/props/rooms/combat_scorch_decal": {
		"path": "res://assets/migrated/rpg/props/rooms/combat_scorch_decal.png",
		"size": [96, 96],
		"bbox": [24, 21, 78, 73]
	},
	"rpg/props/rooms/dimensional_pocket_anomaly": {
		"path": "res://assets/migrated/rpg/props/rooms/dimensional_pocket_anomaly.png",
		"size": [96, 96],
		"bbox": [8, 25, 89, 88]
	},
	"rpg/props/rooms/elite_dais": {
		"path": "res://assets/migrated/rpg/props/rooms/elite_dais.png",
		"size": [96, 64],
		"bbox": [6, 8, 89, 61]
	},
	"rpg/props/rooms/elite_floor_marker": {
		"path": "res://assets/migrated/rpg/props/rooms/elite_floor_marker.png",
		"size": [96, 96],
		"bbox": [12, 11, 84, 85]
	},
	"rpg/props/rooms/entrance_archway": {
		"path": "res://assets/migrated/rpg/props/rooms/entrance_archway.png",
		"size": [64, 64],
		"bbox": [0, 4, 64, 56]
	},
	"rpg/props/rooms/event_artifact_stone": {
		"path": "res://assets/migrated/rpg/props/rooms/event_artifact_stone.png",
		"size": [128, 128],
		"bbox": [23, 19, 107, 106]
	},
	"rpg/props/rooms/event_rune_circle": {
		"path": "res://assets/migrated/rpg/props/rooms/event_rune_circle.png",
		"size": [96, 96],
		"bbox": [16, 25, 81, 79]
	},
	"rpg/props/rooms/exit_portal": {
		"path": "res://assets/migrated/rpg/props/rooms/exit_portal.png",
		"size": [64, 80],
		"bbox": [4, 5, 57, 78]
	},
	"rpg/props/rooms/exit_stairs": {
		"path": "res://assets/migrated/rpg/props/rooms/exit_stairs.png",
		"size": [128, 128],
		"bbox": [17, 2, 98, 128]
	},
	"rpg/props/rooms/miniboss_arena_seal": {
		"path": "res://assets/migrated/rpg/props/rooms/miniboss_arena_seal.png",
		"size": [192, 192],
		"bbox": [15, 15, 177, 177]
	},
	"rpg/props/rooms/pocket_float_platform": {
		"path": "res://assets/migrated/rpg/props/rooms/pocket_float_platform.png",
		"size": [128, 128],
		"bbox": [18, 27, 110, 106]
	},
	"rpg/props/rooms/secret_false_wall": {
		"path": "res://assets/migrated/rpg/props/rooms/secret_false_wall.png",
		"size": [128, 128],
		"bbox": [25, 5, 103, 123]
	},
	"rpg/props/rooms/secret_wall_switch": {
		"path": "res://assets/migrated/rpg/props/rooms/secret_wall_switch.png",
		"size": [48, 64],
		"bbox": [15, 16, 35, 48]
	},
	"rpg/props/rooms/starting_waystone": {
		"path": "res://assets/migrated/rpg/props/rooms/starting_waystone.png",
		"size": [128, 128],
		"bbox": [38, 8, 90, 120]
	},
	"rpg/props/rooms/trap_pressure_plate": {
		"path": "res://assets/migrated/rpg/props/rooms/trap_pressure_plate.png",
		"size": [96, 96],
		"bbox": [15, 14, 81, 82]
	},
	"rpg/props/rooms/treasure_floor_accent": {
		"path": "res://assets/migrated/rpg/props/rooms/treasure_floor_accent.png",
		"size": [128, 128],
		"bbox": [20, 19, 108, 108]
	},
	"rpg/props/rooms/treasure_gold_pile": {
		"path": "res://assets/migrated/rpg/props/rooms/treasure_gold_pile.png",
		"size": [64, 64],
		"bbox": [4, 6, 60, 58]
	},
	"rpg/vfx/bosses/arena_warning": {
		"path": "res://assets/migrated/rpg/vfx/bosses/arena_warning.png",
		"size": [64, 64],
		"bbox": [4, 3, 61, 61]
	},
	"rpg/vfx/bosses/boss_attack_warning": {
		"path": "res://assets/migrated/rpg/vfx/bosses/boss_attack_warning.png",
		"size": [64, 64],
		"bbox": [11, 7, 53, 56]
	},
	"rpg/vfx/bosses/boss_death": {
		"path": "res://assets/migrated/rpg/vfx/bosses/boss_death.png",
		"size": [96, 96],
		"bbox": [6, 5, 89, 88]
	},
	"rpg/vfx/bosses/boss_phase_change": {
		"path": "res://assets/migrated/rpg/vfx/bosses/boss_phase_change.png",
		"size": [96, 96],
		"bbox": [7, 6, 88, 90]
	},
	"rpg/vfx/bosses/boss_spawn": {
		"path": "res://assets/migrated/rpg/vfx/bosses/boss_spawn.png",
		"size": [96, 96],
		"bbox": [10, 0, 87, 92]
	},
	"rpg/vfx/bosses/rift_opening": {
		"path": "res://assets/migrated/rpg/vfx/bosses/rift_opening.png",
		"size": [64, 96],
		"bbox": [2, 1, 62, 95]
	},
	"rpg/vfx/bosses/summon_effect": {
		"path": "res://assets/migrated/rpg/vfx/bosses/summon_effect.png",
		"size": [64, 64],
		"bbox": [13, 3, 52, 61]
	},
	"rpg/vfx/magic/cyan_magic_burst": {
		"path": "res://assets/migrated/rpg/vfx/magic/cyan_magic_burst.png",
		"size": [48, 48],
		"bbox": [7, 4, 43, 43]
	},
	"rpg/vfx/magic/fire": {
		"path": "res://assets/migrated/rpg/vfx/magic/fire.png",
		"size": [64, 64],
		"bbox": [6, 2, 58, 61]
	},
	"rpg/vfx/magic/rift_energy_burst": {
		"path": "res://assets/migrated/rpg/vfx/magic/rift_energy_burst.png",
		"size": [64, 64],
		"bbox": [11, 7, 49, 57]
	},
	"rpg/vfx/magic/violet_magic_burst": {
		"path": "res://assets/migrated/rpg/vfx/magic/violet_magic_burst.png",
		"size": [48, 48],
		"bbox": [3, 5, 44, 43]
	},
	"rpg/vfx/rewards/chest_sparkle": {
		"path": "res://assets/migrated/rpg/vfx/rewards/chest_sparkle.png",
		"size": [64, 64],
		"bbox": [6, 3, 61, 61]
	},
	"rpg/vfx/rewards/essence_collect": {
		"path": "res://assets/migrated/rpg/vfx/rewards/essence_collect.png",
		"size": [48, 48],
		"bbox": [5, 5, 42, 43]
	},
	"rpg/vfx/rewards/heal": {
		"path": "res://assets/migrated/rpg/vfx/rewards/heal.png",
		"size": [48, 64],
		"bbox": [3, 3, 45, 62]
	},
	"rpg/vfx/rewards/loot_glow_epic": {
		"path": "res://assets/migrated/rpg/vfx/rewards/loot_glow_epic.png",
		"size": [64, 64],
		"bbox": [16, 8, 50, 55]
	},
	"rpg/vfx/rewards/loot_glow_legendary": {
		"path": "res://assets/migrated/rpg/vfx/rewards/loot_glow_legendary.png",
		"size": [64, 64],
		"bbox": [8, 3, 57, 59]
	},
	"rpg/vfx/rewards/loot_glow_rare": {
		"path": "res://assets/migrated/rpg/vfx/rewards/loot_glow_rare.png",
		"size": [64, 64],
		"bbox": [11, 6, 52, 59]
	},
	"rpg/vfx/rewards/loot_sparkle": {
		"path": "res://assets/migrated/rpg/vfx/rewards/loot_sparkle.png",
		"size": [32, 32],
		"bbox": [4, 2, 29, 30]
	},
	"rpg/vfx/rewards/relic_pickup": {
		"path": "res://assets/migrated/rpg/vfx/rewards/relic_pickup.png",
		"size": [64, 64],
		"bbox": [9, 6, 57, 57]
	},
	"rpg/vfx/combat/armor_hit": {
		"path": "res://assets/migrated/rpg/vfx/combat/armor_hit.png",
		"size": [48, 48],
		"bbox": [5, 0, 41, 39]
	},
	"rpg/vfx/combat/blood_hit": {
		"path": "res://assets/migrated/rpg/vfx/combat/blood_hit.png",
		"size": [48, 48],
		"bbox": [9, 12, 38, 44]
	},
	"rpg/vfx/combat/bullet_impact": {
		"path": "res://assets/migrated/rpg/vfx/combat/bullet_impact.png",
		"size": [64, 64],
		"bbox": [6, 7, 58, 55]
	},
	"rpg/vfx/combat/critical_hit": {
		"path": "res://assets/migrated/rpg/vfx/combat/critical_hit.png",
		"size": [64, 64],
		"bbox": [5, 6, 57, 58]
	},
	"rpg/vfx/combat/electric_arc": {
		"path": "res://assets/migrated/rpg/vfx/combat/electric_arc.png",
		"size": [64, 48],
		"bbox": [3, 3, 61, 45]
	},
	"rpg/vfx/combat/energy_impact": {
		"path": "res://assets/migrated/rpg/vfx/combat/energy_impact.png",
		"size": [64, 64],
		"bbox": [4, 4, 59, 60]
	},
	"rpg/vfx/combat/explosion_fire": {
		"path": "res://assets/migrated/rpg/vfx/combat/explosion_fire.png",
		"size": [64, 64],
		"bbox": [4, 6, 59, 59]
	},
	"rpg/vfx/combat/heavy_explosion": {
		"path": "res://assets/migrated/rpg/vfx/combat/heavy_explosion.png",
		"size": [64, 64],
		"bbox": [4, 4, 60, 60]
	},
	"rpg/vfx/combat/hit_spark": {
		"path": "res://assets/migrated/rpg/vfx/combat/hit_spark.png",
		"size": [48, 48],
		"bbox": [10, 7, 37, 42]
	},
	"rpg/vfx/combat/poison_cloud": {
		"path": "res://assets/migrated/rpg/vfx/combat/poison_cloud.png",
		"size": [64, 48],
		"bbox": [5, 2, 59, 45]
	},
	"rpg/vfx/combat/shield_hit": {
		"path": "res://assets/migrated/rpg/vfx/combat/shield_hit.png",
		"size": [64, 64],
		"bbox": [8, 5, 57, 58]
	},
	"rpg/vfx/combat/spore_burst": {
		"path": "res://assets/migrated/rpg/vfx/combat/spore_burst.png",
		"size": [64, 48],
		"bbox": [8, 5, 56, 43]
	},
	"rpg/vfx/weapons/muzzle_flash": {
		"path": "res://assets/migrated/rpg/vfx/weapons/muzzle_flash.png",
		"size": [48, 48],
		"bbox": [2, 1, 45, 47]
	},
	"rpg/vfx/weapons/muzzle_flash_rifle": {
		"path": "res://assets/migrated/rpg/vfx/weapons/muzzle_flash_rifle.png",
		"size": [64, 64],
		"bbox": [6, 6, 58, 56]
	},
	"rpg/vfx/weapons/muzzle_flash_shotgun": {
		"path": "res://assets/migrated/rpg/vfx/weapons/muzzle_flash_shotgun.png",
		"size": [64, 64],
		"bbox": [8, 16, 56, 48]
	},
	"rpg/vfx/weapons/projectile_trail": {
		"path": "res://assets/migrated/rpg/vfx/weapons/projectile_trail.png",
		"size": [64, 32],
		"bbox": [0, 9, 62, 23]
	},
	"rpg/vfx/movement/dash_streak": {
		"path": "res://assets/migrated/rpg/vfx/movement/dash_streak.png",
		"size": [64, 32],
		"bbox": [0, 8, 61, 22]
	},
	"rpg/vfx/movement/player_spawn": {
		"path": "res://assets/migrated/rpg/vfx/movement/player_spawn.png",
		"size": [64, 64],
		"bbox": [14, 4, 50, 60]
	},
	"rpg/vfx/movement/speed_streak": {
		"path": "res://assets/migrated/rpg/vfx/movement/speed_streak.png",
		"size": [64, 64],
		"bbox": [0, 21, 64, 40]
	},
	"rpg/vfx/movement/teleport": {
		"path": "res://assets/migrated/rpg/vfx/movement/teleport.png",
		"size": [48, 64],
		"bbox": [9, 0, 39, 62]
	},
	"rpg/props/rift/arcane_device": {
		"path": "res://assets/migrated/rpg/props/rift/arcane_device.png",
		"size": [96, 128],
		"bbox": [16, 10, 80, 119]
	},
	"rpg/props/rift/dimensional_fragment": {
		"path": "res://assets/migrated/rpg/props/rift/dimensional_fragment.png",
		"size": [64, 64],
		"bbox": [5, 4, 59, 61]
	},
	"rpg/props/rift/dimensional_gate": {
		"path": "res://assets/migrated/rpg/props/rift/dimensional_gate.png",
		"size": [128, 128],
		"bbox": [32, 13, 97, 110]
	},
	"rpg/props/rift/floating_crystals": {
		"path": "res://assets/migrated/rpg/props/rift/floating_crystals.png",
		"size": [96, 96],
		"bbox": [28, 8, 68, 88]
	},
	"rpg/props/rift/floating_pillar": {
		"path": "res://assets/migrated/rpg/props/rift/floating_pillar.png",
		"size": [96, 160],
		"bbox": [13, 11, 80, 142]
	},
	"rpg/props/rift/rift_anchor": {
		"path": "res://assets/migrated/rpg/props/rift/rift_anchor.png",
		"size": [96, 96],
		"bbox": [23, 17, 73, 79]
	},
	"rpg/props/rift/void_debris": {
		"path": "res://assets/migrated/rpg/props/rift/void_debris.png",
		"size": [96, 96],
		"bbox": [8, 8, 86, 88]
	},
	"rpg/props/organic/alien_growth": {
		"path": "res://assets/migrated/rpg/props/organic/alien_growth.png",
		"size": [96, 96],
		"bbox": [7, 0, 90, 91]
	},
	"rpg/props/organic/cocoon": {
		"path": "res://assets/migrated/rpg/props/organic/cocoon.png",
		"size": [96, 128],
		"bbox": [29, 0, 67, 118]
	},
	"rpg/props/organic/egg_sac": {
		"path": "res://assets/migrated/rpg/props/organic/egg_sac.png",
		"size": [96, 96],
		"bbox": [5, 11, 91, 89]
	},
	"rpg/props/organic/giant_root": {
		"path": "res://assets/migrated/rpg/props/organic/giant_root.png",
		"size": [96, 128],
		"bbox": [7, 9, 89, 115]
	},
	"rpg/props/organic/glowing_mushroom_cluster": {
		"path": "res://assets/migrated/rpg/props/organic/glowing_mushroom_cluster.png",
		"size": [48, 64],
		"bbox": [5, 7, 43, 59]
	},
	"rpg/props/organic/organic_doorway": {
		"path": "res://assets/migrated/rpg/props/organic/organic_doorway.png",
		"size": [96, 128],
		"bbox": [4, 4, 92, 124]
	},
	"rpg/props/organic/plant_nest": {
		"path": "res://assets/migrated/rpg/props/organic/plant_nest.png",
		"size": [128, 128],
		"bbox": [15, 16, 113, 115]
	},
	"rpg/props/organic/poison_pool": {
		"path": "res://assets/migrated/rpg/props/organic/poison_pool.png",
		"size": [96, 96],
		"bbox": [6, 6, 90, 90]
	},
	"rpg/props/organic/spore_pods": {
		"path": "res://assets/migrated/rpg/props/organic/spore_pods.png",
		"size": [64, 64],
		"bbox": [11, 12, 53, 52]
	},
	"rpg/props/organic/thorny_vegetation": {
		"path": "res://assets/migrated/rpg/props/organic/thorny_vegetation.png",
		"size": [64, 48],
		"bbox": [8, 3, 57, 42]
	},
	"rpg/props/organic/toxic_vines": {
		"path": "res://assets/migrated/rpg/props/organic/toxic_vines.png",
		"size": [96, 96],
		"bbox": [6, 0, 90, 90]
	},
	"rpg/props/crystals/cyan_crystal_cluster": {
		"path": "res://assets/migrated/rpg/props/crystals/cyan_crystal_cluster.png",
		"size": [48, 64],
		"bbox": [6, 5, 42, 59]
	},
	"rpg/props/crystals/violet_rift_crystal_cluster": {
		"path": "res://assets/migrated/rpg/props/crystals/violet_rift_crystal_cluster.png",
		"size": [48, 64],
		"bbox": [2, 2, 46, 61]
	},
	"rpg/props/lab/blast_door": {
		"path": "res://assets/migrated/rpg/props/lab/blast_door.png",
		"size": [96, 128],
		"bbox": [21, 37, 76, 90]
	},
	"rpg/props/lab/broken_generator": {
		"path": "res://assets/migrated/rpg/props/lab/broken_generator.png",
		"size": [96, 128],
		"bbox": [5, 3, 92, 125]
	},
	"rpg/props/lab/cable_bundle": {
		"path": "res://assets/migrated/rpg/props/lab/cable_bundle.png",
		"size": [96, 96],
		"bbox": [33, 0, 62, 89]
	},
	"rpg/props/lab/containment_unit": {
		"path": "res://assets/migrated/rpg/props/lab/containment_unit.png",
		"size": [96, 128],
		"bbox": [10, 6, 86, 120]
	},
	"rpg/props/lab/destroyed_terminal": {
		"path": "res://assets/migrated/rpg/props/lab/destroyed_terminal.png",
		"size": [96, 96],
		"bbox": [23, 21, 73, 76]
	},
	"rpg/props/lab/electrical_box": {
		"path": "res://assets/migrated/rpg/props/lab/electrical_box.png",
		"size": [96, 96],
		"bbox": [29, 7, 67, 88]
	},
	"rpg/props/lab/gas_tanks": {
		"path": "res://assets/migrated/rpg/props/lab/gas_tanks.png",
		"size": [96, 96],
		"bbox": [12, 13, 82, 83]
	},
	"rpg/props/lab/lab_sliding_door": {
		"path": "res://assets/migrated/rpg/props/lab/lab_sliding_door.png",
		"size": [96, 128],
		"bbox": [20, 16, 76, 118]
	},
	"rpg/props/lab/med_equipment": {
		"path": "res://assets/migrated/rpg/props/lab/med_equipment.png",
		"size": [128, 96],
		"bbox": [17, 11, 112, 85]
	},
	"rpg/props/lab/pipes": {
		"path": "res://assets/migrated/rpg/props/lab/pipes.png",
		"size": [96, 96],
		"bbox": [6, 6, 91, 91]
	},
	"rpg/props/lab/security_gate": {
		"path": "res://assets/migrated/rpg/props/lab/security_gate.png",
		"size": [96, 128],
		"bbox": [24, 15, 72, 110]
	},
	"rpg/props/lab/server_rack": {
		"path": "res://assets/migrated/rpg/props/lab/server_rack.png",
		"size": [96, 128],
		"bbox": [16, 8, 80, 120]
	},
	"rpg/props/lab/warning_light": {
		"path": "res://assets/migrated/rpg/props/lab/warning_light.png",
		"size": [64, 96],
		"bbox": [20, 13, 44, 87]
	},
	"rpg/chests/common_chest": {
		"path": "res://assets/migrated/rpg/chests/common_chest.png",
		"size": [48, 48],
		"bbox": [4, 8, 44, 40]
	},
	"rpg/chests/common_chest_open": {
		"path": "res://assets/migrated/rpg/chests/common_chest_open.png",
		"size": [48, 48],
		"bbox": [3, 1, 45, 47]
	},
	"rpg/chests/corrupted_chest": {
		"path": "res://assets/migrated/rpg/chests/corrupted_chest.png",
		"size": [48, 48],
		"bbox": [6, 7, 42, 42]
	},
	"rpg/chests/corrupted_chest_open": {
		"path": "res://assets/migrated/rpg/chests/corrupted_chest_open.png",
		"size": [48, 48],
		"bbox": [5, 3, 44, 44]
	},
	"rpg/chests/dimensional_chest": {
		"path": "res://assets/migrated/rpg/chests/dimensional_chest.png",
		"size": [48, 48],
		"bbox": [4, 3, 43, 45]
	},
	"rpg/chests/dimensional_chest_open": {
		"path": "res://assets/migrated/rpg/chests/dimensional_chest_open.png",
		"size": [48, 48],
		"bbox": [7, 1, 39, 42]
	},
	"rpg/chests/epic_chest": {
		"path": "res://assets/migrated/rpg/chests/epic_chest.png",
		"size": [48, 48],
		"bbox": [2, 3, 46, 45]
	},
	"rpg/chests/epic_chest_open": {
		"path": "res://assets/migrated/rpg/chests/epic_chest_open.png",
		"size": [48, 48],
		"bbox": [2, 2, 46, 46]
	},
	"rpg/chests/legendary_chest": {
		"path": "res://assets/migrated/rpg/chests/legendary_chest.png",
		"size": [48, 48],
		"bbox": [4, 5, 44, 41]
	},
	"rpg/chests/legendary_chest_open": {
		"path": "res://assets/migrated/rpg/chests/legendary_chest_open.png",
		"size": [48, 48],
		"bbox": [4, 4, 44, 44]
	},
	"rpg/chests/rare_chest": {
		"path": "res://assets/migrated/rpg/chests/rare_chest.png",
		"size": [48, 48],
		"bbox": [1, 3, 46, 45]
	},
	"rpg/chests/rare_chest_open": {
		"path": "res://assets/migrated/rpg/chests/rare_chest_open.png",
		"size": [48, 48],
		"bbox": [3, 3, 45, 45]
	},
	"rpg/chests/uncommon_chest": {
		"path": "res://assets/migrated/rpg/chests/uncommon_chest.png",
		"size": [48, 48],
		"bbox": [2, 4, 46, 44]
	},
	"rpg/chests/uncommon_chest_open": {
		"path": "res://assets/migrated/rpg/chests/uncommon_chest_open.png",
		"size": [48, 48],
		"bbox": [4, 2, 43, 45]
	},
	"rpg/props/story/guardian_statue": {
		"path": "res://assets/migrated/rpg/props/story/guardian_statue.png",
		"size": [64, 96],
		"bbox": [11, 2, 55, 94]
	},
	"rpg/props/story/power_generator": {
		"path": "res://assets/migrated/rpg/props/story/power_generator.png",
		"size": [64, 64],
		"bbox": [3, 1, 60, 62]
	},
	"rpg/props/story/sci_fi_terminal": {
		"path": "res://assets/migrated/rpg/props/story/sci_fi_terminal.png",
		"size": [48, 48],
		"bbox": [9, 4, 40, 42]
	},
	"rpg/props/story/stone_altar_relic": {
		"path": "res://assets/migrated/rpg/props/story/stone_altar_relic.png",
		"size": [48, 64],
		"bbox": [2, 9, 46, 60]
	},
	"rpg/props/dungeon/banner": {
		"path": "res://assets/migrated/rpg/props/dungeon/banner.png",
		"size": [96, 128],
		"bbox": [3, 6, 93, 122]
	},
	"rpg/props/dungeon/bench": {
		"path": "res://assets/migrated/rpg/props/dungeon/bench.png",
		"size": [96, 96],
		"bbox": [6, 16, 90, 80]
	},
	"rpg/props/dungeon/books_scroll": {
		"path": "res://assets/migrated/rpg/props/dungeon/books_scroll.png",
		"size": [64, 64],
		"bbox": [6, 4, 58, 60]
	},
	"rpg/props/dungeon/broken_statue": {
		"path": "res://assets/migrated/rpg/props/dungeon/broken_statue.png",
		"size": [128, 128],
		"bbox": [7, 8, 121, 120]
	},
	"rpg/props/dungeon/broken_table": {
		"path": "res://assets/migrated/rpg/props/dungeon/broken_table.png",
		"size": [96, 96],
		"bbox": [7, 7, 89, 90]
	},
	"rpg/props/dungeon/candles": {
		"path": "res://assets/migrated/rpg/props/dungeon/candles.png",
		"size": [64, 64],
		"bbox": [12, 5, 52, 59]
	},
	"rpg/props/dungeon/chains_shackles": {
		"path": "res://assets/migrated/rpg/props/dungeon/chains_shackles.png",
		"size": [96, 96],
		"bbox": [12, 18, 84, 80]
	},
	"rpg/props/dungeon/corpse": {
		"path": "res://assets/migrated/rpg/props/dungeon/corpse.png",
		"size": [96, 96],
		"bbox": [11, 11, 80, 87]
	},
	"rpg/props/dungeon/torn_banner": {
		"path": "res://assets/migrated/rpg/props/dungeon/torn_banner.png",
		"size": [96, 128],
		"bbox": [4, 5, 92, 122]
	},
	"rpg/props/dungeon2/bone_heap": {
		"path": "res://assets/migrated/rpg/props/dungeon2/bone_heap.png",
		"size": [96, 64],
		"bbox": [7, 1, 88, 62]
	},
	"rpg/props/dungeon2/bookshelf": {
		"path": "res://assets/migrated/rpg/props/dungeon2/bookshelf.png",
		"size": [80, 80],
		"bbox": [16, 2, 64, 77]
	},
	"rpg/props/dungeon2/brazier": {
		"path": "res://assets/migrated/rpg/props/dungeon2/brazier.png",
		"size": [48, 64],
		"bbox": [9, 3, 38, 58]
	},
	"rpg/props/dungeon2/dry_fountain": {
		"path": "res://assets/migrated/rpg/props/dungeon2/dry_fountain.png",
		"size": [96, 80],
		"bbox": [11, 6, 83, 72]
	},
	"rpg/props/dungeon2/guardian_statue": {
		"path": "res://assets/migrated/rpg/props/dungeon2/guardian_statue.png",
		"size": [48, 96],
		"bbox": [7, 3, 41, 92]
	},
	"rpg/props/dungeon2/iron_cage": {
		"path": "res://assets/migrated/rpg/props/dungeon2/iron_cage.png",
		"size": [64, 80],
		"bbox": [2, 3, 61, 76]
	},
	"rpg/props/dungeon2/lantern_post": {
		"path": "res://assets/migrated/rpg/props/dungeon2/lantern_post.png",
		"size": [32, 80],
		"bbox": [3, 4, 30, 75]
	},
	"rpg/props/dungeon2/low_wall_cover": {
		"path": "res://assets/migrated/rpg/props/dungeon2/low_wall_cover.png",
		"size": [96, 48],
		"bbox": [9, 3, 86, 45]
	},
	"rpg/props/dungeon2/rift_crystal_pillar": {
		"path": "res://assets/migrated/rpg/props/dungeon2/rift_crystal_pillar.png",
		"size": [48, 96],
		"bbox": [5, 5, 42, 92]
	},
	"rpg/props/dungeon2/root_stump": {
		"path": "res://assets/migrated/rpg/props/dungeon2/root_stump.png",
		"size": [80, 80],
		"bbox": [3, 2, 77, 79]
	},
	"rpg/props/dungeon2/rubble_large": {
		"path": "res://assets/migrated/rpg/props/dungeon2/rubble_large.png",
		"size": [96, 64],
		"bbox": [5, 3, 91, 61]
	},
	"rpg/props/dungeon2/rune_altar": {
		"path": "res://assets/migrated/rpg/props/dungeon2/rune_altar.png",
		"size": [64, 64],
		"bbox": [6, 2, 58, 63]
	},
	"rpg/props/dungeon2/sarcophagus": {
		"path": "res://assets/migrated/rpg/props/dungeon2/sarcophagus.png",
		"size": [96, 64],
		"bbox": [19, 3, 75, 62]
	},
	"rpg/props/dungeon2/spike_barricade": {
		"path": "res://assets/migrated/rpg/props/dungeon2/spike_barricade.png",
		"size": [96, 48],
		"bbox": [15, 0, 81, 47]
	},
	"rpg/props/dungeon2/stalagmites": {
		"path": "res://assets/migrated/rpg/props/dungeon2/stalagmites.png",
		"size": [80, 64],
		"bbox": [8, 2, 70, 61]
	},
	"rpg/props/dungeon2/weapon_rack": {
		"path": "res://assets/migrated/rpg/props/dungeon2/weapon_rack.png",
		"size": [64, 64],
		"bbox": [4, 1, 60, 62]
	},
	"rpg/props/containers/barrel": {
		"path": "res://assets/migrated/rpg/props/containers/barrel.png",
		"size": [48, 56],
		"bbox": [9, 7, 41, 49]
	},
	"rpg/props/containers/broken_barrel": {
		"path": "res://assets/migrated/rpg/props/containers/broken_barrel.png",
		"size": [48, 56],
		"bbox": [2, 8, 46, 49]
	},
	"rpg/props/containers/broken_crate": {
		"path": "res://assets/migrated/rpg/props/containers/broken_crate.png",
		"size": [48, 56],
		"bbox": [3, 9, 44, 45]
	},
	"rpg/props/containers/crate": {
		"path": "res://assets/migrated/rpg/props/containers/crate.png",
		"size": [48, 56],
		"bbox": [5, 9, 43, 47]
	},
	"rpg/props/pickups/coin_stack": {
		"path": "res://assets/migrated/rpg/props/pickups/coin_stack.png",
		"size": [48, 48],
		"bbox": [7, 9, 42, 39]
	},
	"rpg/props/pickups/essence_shard": {
		"path": "res://assets/migrated/rpg/props/pickups/essence_shard.png",
		"size": [32, 32],
		"bbox": [8, 6, 24, 26]
	},
	"rpg/props/pickups/health_orb": {
		"path": "res://assets/migrated/rpg/props/pickups/health_orb.png",
		"size": [32, 32],
		"bbox": [7, 5, 25, 28]
	},
	"rpg/props/traps/spike_trap": {
		"path": "res://assets/migrated/rpg/props/traps/spike_trap.png",
		"size": [64, 48],
		"bbox": [4, 3, 60, 44]
	},
	"rpg/props/traps/swinging_blade_trap": {
		"path": "res://assets/migrated/rpg/props/traps/swinging_blade_trap.png",
		"size": [64, 48],
		"bbox": [22, 5, 47, 37]
	},
	"rpg/props/rubble/bone_debris": {
		"path": "res://assets/migrated/rpg/props/rubble/bone_debris.png",
		"size": [48, 48],
		"bbox": [3, 14, 47, 39]
	},
	"rpg/props/rubble/skull_pile": {
		"path": "res://assets/migrated/rpg/props/rubble/skull_pile.png",
		"size": [48, 48],
		"bbox": [2, 2, 46, 45]
	},
	"rpg/props/rubble/stone_rubble": {
		"path": "res://assets/migrated/rpg/props/rubble/stone_rubble.png",
		"size": [48, 48],
		"bbox": [3, 11, 44, 36]
	},
	"rpg/props/lighting/brazier": {
		"path": "res://assets/migrated/rpg/props/lighting/brazier.png",
		"size": [96, 96],
		"bbox": [19, 9, 77, 91]
	},
	"rpg/props/lighting/broken_street_lamp": {
		"path": "res://assets/migrated/rpg/props/lighting/broken_street_lamp.png",
		"size": [128, 128],
		"bbox": [45, 9, 81, 121]
	},
	"rpg/props/lighting/dark_street_lamp": {
		"path": "res://assets/migrated/rpg/props/lighting/dark_street_lamp.png",
		"size": [48, 96],
		"bbox": [16, 2, 32, 91]
	},
	"rpg/props/lighting/emergency_sci_light": {
		"path": "res://assets/migrated/rpg/props/lighting/emergency_sci_light.png",
		"size": [96, 96],
		"bbox": [27, 10, 65, 86]
	},
	"rpg/props/lighting/iron_lamp": {
		"path": "res://assets/migrated/rpg/props/lighting/iron_lamp.png",
		"size": [64, 96],
		"bbox": [11, 0, 51, 93]
	},
	"rpg/props/lighting/large_brazier": {
		"path": "res://assets/migrated/rpg/props/lighting/large_brazier.png",
		"size": [128, 128],
		"bbox": [27, 14, 102, 102]
	},
	"rpg/props/lighting/magic_lamp_cyan": {
		"path": "res://assets/migrated/rpg/props/lighting/magic_lamp_cyan.png",
		"size": [48, 80],
		"bbox": [10, 4, 40, 74]
	},
	"rpg/props/lighting/standing_torch": {
		"path": "res://assets/migrated/rpg/props/lighting/standing_torch.png",
		"size": [48, 80],
		"bbox": [15, 2, 33, 77]
	},
	"rpg/props/lighting/torch_bracket_pair": {
		"path": "res://assets/migrated/rpg/props/lighting/torch_bracket_pair.png",
		"size": [64, 64],
		"bbox": [8, 6, 56, 59]
	},
	"rpg/props/lighting/torch_wall": {
		"path": "res://assets/migrated/rpg/props/lighting/torch_wall.png",
		"size": [48, 64],
		"bbox": [12, 4, 34, 60]
	},
	"rpg/props/lighting/violet_rift_lamp": {
		"path": "res://assets/migrated/rpg/props/lighting/violet_rift_lamp.png",
		"size": [96, 96],
		"bbox": [31, 8, 66, 90]
	},
	"rpg/props/structures/boss_gate": {
		"path": "res://assets/migrated/rpg/props/structures/boss_gate.png",
		"size": [96, 96],
		"bbox": [21, 15, 77, 81]
	},
	"rpg/props/structures/broken_column": {
		"path": "res://assets/migrated/rpg/props/structures/broken_column.png",
		"size": [48, 64],
		"bbox": [7, 5, 41, 59]
	},
	"rpg/props/structures/event_pedestal": {
		"path": "res://assets/migrated/rpg/props/structures/event_pedestal.png",
		"size": [48, 48],
		"bbox": [2, 2, 46, 45]
	},
	"rpg/props/structures/lever": {
		"path": "res://assets/migrated/rpg/props/structures/lever.png",
		"size": [40, 48],
		"bbox": [12, 15, 28, 32]
	},
	"rpg/props/structures/ruined_arch": {
		"path": "res://assets/migrated/rpg/props/structures/ruined_arch.png",
		"size": [96, 128],
		"bbox": [15, 15, 81, 108]
	},
	"rpg/props/structures/stone_arch": {
		"path": "res://assets/migrated/rpg/props/structures/stone_arch.png",
		"size": [96, 128],
		"bbox": [3, 6, 93, 124]
	},
	"rpg/props/structures/stone_column": {
		"path": "res://assets/migrated/rpg/props/structures/stone_column.png",
		"size": [48, 80],
		"bbox": [10, 5, 36, 75]
	},
	"rpg/props/structures/stone_dungeon_door": {
		"path": "res://assets/migrated/rpg/props/structures/stone_dungeon_door.png",
		"size": [64, 80],
		"bbox": [4, 4, 57, 77]
	},
	"rpg/props/structures/treasure_pedestal": {
		"path": "res://assets/migrated/rpg/props/structures/treasure_pedestal.png",
		"size": [48, 48],
		"bbox": [5, 2, 43, 47]
	},
	"rpg/decals/bone_dust": {
		"path": "res://assets/migrated/rpg/decals/bone_dust.png",
		"size": [96, 64],
		"bbox": [14, 7, 80, 58]
	},
	"rpg/decals/floor_crack": {
		"path": "res://assets/migrated/rpg/decals/floor_crack.png",
		"size": [96, 64],
		"bbox": [10, 7, 86, 57]
	},
	"rpg/decals/floor_roots": {
		"path": "res://assets/migrated/rpg/decals/floor_roots.png",
		"size": [128, 64],
		"bbox": [15, 4, 110, 60]
	},
	"rpg/decals/gravel_scatter": {
		"path": "res://assets/migrated/rpg/decals/gravel_scatter.png",
		"size": [96, 64],
		"bbox": [22, 11, 72, 53]
	},
	"rpg/decals/moss_patch_a": {
		"path": "res://assets/migrated/rpg/decals/moss_patch_a.png",
		"size": [96, 64],
		"bbox": [13, 4, 81, 62]
	},
	"rpg/decals/moss_patch_b": {
		"path": "res://assets/migrated/rpg/decals/moss_patch_b.png",
		"size": [64, 48],
		"bbox": [11, 6, 51, 43]
	},
	"vida/props/city/bench": {
		"path": "res://assets/migrated/vida/props/city/bench.png",
		"size": [64, 48],
		"bbox": [4, 1, 57, 46]
	},
	"vida/props/city/lamp": {
		"path": "res://assets/migrated/vida/props/city/lamp.png",
		"size": [48, 96],
		"bbox": [10, 4, 38, 90]
	},
	"vida/props/city/planter": {
		"path": "res://assets/migrated/vida/props/city/planter.png",
		"size": [64, 48],
		"bbox": [2, 1, 62, 47]
	},
	"vida/props/city/vending_machine": {
		"path": "res://assets/migrated/vida/props/city/vending_machine.png",
		"size": [32, 64],
		"bbox": [3, 5, 29, 55]
	},
	"vida/interior/bakery_display": {
		"path": "res://assets/migrated/vida/interior/bakery_display.png",
		"size": [128, 96],
		"bbox": [19, 6, 109, 91]
	},
	"vida/interior/bathroom": {
		"path": "res://assets/migrated/vida/interior/bathroom.png",
		"size": [128, 96],
		"bbox": [3, 3, 114, 87]
	},
	"vida/interior/bed": {
		"path": "res://assets/migrated/vida/interior/bed.png",
		"size": [64, 64],
		"bbox": [6, 3, 58, 59]
	},
	"vida/interior/bed_front": {
		"path": "res://assets/migrated/vida/interior/bed_front.png",
		"size": [128, 96],
		"bbox": [11, 12, 117, 87]
	},
	"vida/interior/bookcase": {
		"path": "res://assets/migrated/vida/interior/bookcase.png",
		"size": [128, 96],
		"bbox": [30, 10, 99, 88]
	},
	"vida/interior/bookcase_front": {
		"path": "res://assets/migrated/vida/interior/bookcase_front.png",
		"size": [128, 96],
		"bbox": [19, 12, 109, 88]
	},
	"vida/interior/cafe_bar": {
		"path": "res://assets/migrated/vida/interior/cafe_bar.png",
		"size": [160, 96],
		"bbox": [9, 1, 145, 93]
	},
	"vida/interior/cafe_table": {
		"path": "res://assets/migrated/vida/interior/cafe_table.png",
		"size": [96, 96],
		"bbox": [3, 15, 90, 80]
	},
	"vida/interior/checkout": {
		"path": "res://assets/migrated/vida/interior/checkout.png",
		"size": [128, 96],
		"bbox": [16, 10, 107, 85]
	},
	"vida/interior/desk": {
		"path": "res://assets/migrated/vida/interior/desk.png",
		"size": [96, 96],
		"bbox": [7, 8, 84, 84]
	},
	"vida/interior/dining": {
		"path": "res://assets/migrated/vida/interior/dining.png",
		"size": [96, 96],
		"bbox": [9, 12, 85, 80]
	},
	"vida/interior/grill": {
		"path": "res://assets/migrated/vida/interior/grill.png",
		"size": [128, 96],
		"bbox": [11, 6, 116, 93]
	},
	"vida/interior/hospital_bed": {
		"path": "res://assets/migrated/vida/interior/hospital_bed.png",
		"size": [128, 96],
		"bbox": [15, 17, 108, 83]
	},
	"vida/interior/ice_cream_counter": {
		"path": "res://assets/migrated/vida/interior/ice_cream_counter.png",
		"size": [128, 96],
		"bbox": [17, 24, 112, 83]
	},
	"vida/interior/kitchen": {
		"path": "res://assets/migrated/vida/interior/kitchen.png",
		"size": [96, 64],
		"bbox": [17, 5, 74, 60]
	},
	"vida/interior/market_fridge": {
		"path": "res://assets/migrated/vida/interior/market_fridge.png",
		"size": [96, 96],
		"bbox": [17, 4, 74, 90]
	},
	"vida/interior/market_shelf": {
		"path": "res://assets/migrated/vida/interior/market_shelf.png",
		"size": [96, 96],
		"bbox": [10, 4, 83, 93]
	},
	"vida/interior/market_shelf_front": {
		"path": "res://assets/migrated/vida/interior/market_shelf_front.png",
		"size": [128, 96],
		"bbox": [18, 15, 108, 83]
	},
	"vida/interior/reception": {
		"path": "res://assets/migrated/vida/interior/reception.png",
		"size": [128, 96],
		"bbox": [16, 47, 108, 84]
	},
	"vida/interior/shelf": {
		"path": "res://assets/migrated/vida/interior/shelf.png",
		"size": [96, 96],
		"bbox": [21, 3, 69, 92]
	},
	"vida/interior/sofa": {
		"path": "res://assets/migrated/vida/interior/sofa.png",
		"size": [96, 64],
		"bbox": [13, 5, 82, 61]
	},
	"vida/interior/sofa_front": {
		"path": "res://assets/migrated/vida/interior/sofa_front.png",
		"size": [128, 96],
		"bbox": [2, 21, 125, 79]
	},
	"vida/interior/tv": {
		"path": "res://assets/migrated/vida/interior/tv.png",
		"size": [96, 64],
		"bbox": [9, 2, 88, 63]
	},
	"vida/interior/tv_back": {
		"path": "res://assets/migrated/vida/interior/tv_back.png",
		"size": [128, 96],
		"bbox": [9, 20, 119, 88]
	},
	"vida/interior/wardrobe": {
		"path": "res://assets/migrated/vida/interior/wardrobe.png",
		"size": [96, 96],
		"bbox": [14, 4, 74, 89]
	}
}

const ALIASES := {}

## Armas normalizadas: eje a +x, `grip` = punto de agarre (origen del arma), `tip` = x de la punta.
const ORIENTED := {
	"pulsar": {
		"path": "res://assets/migrated/rpg/weapons/oriented/pulsar.png",
		"size": [146, 68],
		"grip": [65.7, 34.0],
		"tip": 146.0,
		"src": "pulse_smg"
	},
	"maul12": {
		"path": "res://assets/migrated/rpg/weapons/oriented/maul12.png",
		"size": [167, 45],
		"grip": [70.1, 22.5],
		"tip": 167.0,
		"src": "breach_shotgun"
	},
	"lancex": {
		"path": "res://assets/migrated/rpg/weapons/oriented/lancex.png",
		"size": [169, 48],
		"grip": [71.0, 24.0],
		"tip": 169.0,
		"src": "alien_beam_rifle"
	},
	"chispa": {
		"path": "res://assets/migrated/rpg/weapons/oriented/chispa.png",
		"size": [137, 89],
		"grip": [38.4, 44.5],
		"tip": 137.0,
		"src": "tactical_sidearm"
	},
	"trinca": {
		"path": "res://assets/migrated/rpg/weapons/oriented/trinca.png",
		"size": [145, 74],
		"grip": [60.9, 37.0],
		"tip": 145.0,
		"src": "swat_compact"
	},
	"mastin": {
		"path": "res://assets/migrated/rpg/weapons/oriented/mastin.png",
		"size": [143, 72],
		"grip": [60.1, 36.0],
		"tip": 143.0,
		"src": "beetle_core"
	},
	"gota": {
		"path": "res://assets/migrated/rpg/weapons/oriented/gota.png",
		"size": [155, 66],
		"grip": [55.8, 33.0],
		"tip": 155.0,
		"src": "living_spore_gun"
	},
	"pomelo": {
		"path": "res://assets/migrated/rpg/weapons/oriented/pomelo.png",
		"size": [155, 61],
		"grip": [65.1, 30.5],
		"tip": 155.0,
		"src": "toxic_mortar"
	},
	"relampago": {
		"path": "res://assets/migrated/rpg/weapons/oriented/relampago.png",
		"size": [158, 41],
		"grip": [66.4, 20.5],
		"tip": 158.0,
		"src": "arc_rifle"
	},
	"rebote": {
		"path": "res://assets/migrated/rpg/weapons/oriented/rebote.png",
		"size": [149, 63],
		"grip": [44.7, 31.5],
		"tip": 149.0,
		"src": "void_pistol"
	},
	"colmena": {
		"path": "res://assets/migrated/rpg/weapons/oriented/colmena.png",
		"size": [172, 85],
		"grip": [72.2, 42.5],
		"tip": 172.0,
		"src": "hive_launcher"
	},
	"filo_z": {
		"path": "res://assets/migrated/rpg/weapons/oriented/filo_z.png",
		"size": [200, 36],
		"grip": [60.0, 18.0],
		"tip": 200.0,
		"src": "rift_spear"
	},
	"garra": {
		"path": "res://assets/migrated/rpg/weapons/oriented/garra.png",
		"size": [90, 108],
		"grip": [10.8, 54.0],
		"tip": 90.0,
		"src": "mutant_claws"
	},
	"enjambre": {
		"path": "res://assets/migrated/rpg/weapons/oriented/enjambre.png",
		"size": [136, 93],
		"grip": [68.0, 46.5],
		"tip": 136.0,
		"src": "beetle_cannon"
	},
	"anomalia": {
		"path": "res://assets/migrated/rpg/weapons/oriented/anomalia.png",
		"size": [147, 74],
		"grip": [32.3, 37.0],
		"tip": 147.0,
		"src": "orb_projector"
	},
	"riel_q": {
		"path": "res://assets/migrated/rpg/weapons/oriented/riel_q.png",
		"size": [166, 51],
		"grip": [66.4, 25.5],
		"tip": 166.0,
		"src": "bone_rail"
	},
	"brasero": {
		"path": "res://assets/migrated/rpg/weapons/oriented/brasero.png",
		"size": [172, 71],
		"grip": [77.4, 35.5],
		"tip": 172.0,
		"src": "void_launcher"
	},
	"aguja": {
		"path": "res://assets/migrated/rpg/weapons/oriented/aguja.png",
		"size": [137, 52],
		"grip": [57.5, 26.0],
		"tip": 137.0,
		"src": "swat_carbine"
	}
}
