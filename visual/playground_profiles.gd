class_name PlaygroundProfiles
extends RefCounted
## R8 visual-only prototype for RPG PREMIUM. No gameplay/damage/boss HP modifications.
## Exactly 8 unique non-boss enemy designs + 4 bosses exist; the missing designs cannot be inferred.
## A few existing AI roles intentionally reuse a visual with different size/tint.
## No legacy fallback exists: every enemy kind and boss resolves here. Commercial licence not yet established.

const LOOKS := {
    # Tech (7 pre-existing AI identities)
    "skitter": {"actor":"robotic_drone", "height":44.0},
    "lancer": {"actor":"robotic_trooper", "height":65.0},
    "brute": {"actor":"robotic_trooper", "height":83.0, "tint":Color("ffd2ac")},
    "sentry": {"actor":"robotic_trooper", "height":70.0, "tint":Color("a7eaff")},
    "fuse": {"actor":"robotic_drone", "height":49.0, "tint":Color("ffb09b")},
    "aegis": {"actor":"robotic_trooper", "height":79.0, "tint":Color("a2caff")},
    "mender": {"actor":"robotic_drone", "height":46.0, "tint":Color("99ffe3")},
    "custodio": {"actor":"robotic_overseer", "height":148.0},
    # Jade
    "jaguar": {"actor":"jade_stalker", "height":63.0},
    "cerbatana": {"actor":"jade_stalker", "height":63.0, "tint":Color("c8ffd0")},
    "idolo": {"actor":"jade_guardian", "height":90.0},
    "sacerdote": {"actor":"jade_guardian", "height":75.0, "tint":Color("b9faff")},
    "escarabajo": {"actor":"jade_stalker", "height":44.0, "tint":Color("a6ffd9")},
    "xocotl": {"actor":"jade_warden", "height":152.0},
    # Scarlet
    "caballero": {"actor":"scarlet_duelist", "height":73.0},
    "ballestero": {"actor":"scarlet_duelist", "height":66.0, "tint":Color("ffccaa")},
    "sabueso": {"actor":"scarlet_hound", "height":52.0},
    "mariscal": {"actor":"scarlet_castellan", "height":150.0},
    # Rift
    "fulgor": {"actor":"rift_lancer", "height":64.0, "tint":Color("b6deff")},
    "acechador": {"actor":"rift_skitter", "height":57.0},
    "ojo": {"actor":"rift_lancer", "height":76.0, "tint":Color("e2bbff")},
    "vigia": {"actor":"rift_monarch", "height":152.0},
}
const BOSSES := ["custodio", "xocotl", "mariscal", "vigia"]
const FPS := {"default":9.0, "idle":5.0, "walk":11.0, "attack":13.0, "special":12.0, "hurt":24.0, "death":11.0}

static func enabled() -> bool:
    return true

static func enemy(kind: String) -> Dictionary:
    if not enabled() or not LOOKS.has(kind):
        return {}
    var spec: Dictionary = LOOKS[kind]
    var set_id := "playground_r8/" + str(spec["actor"])
    if not PlaygroundManifest.SETS.has(set_id):
        return {}
    var metadata: Dictionary = PlaygroundManifest.SETS[set_id]
    var anims: Dictionary = metadata.get("anims", {})
    if not anims.has("idle"):
        return {}
    var boss := BOSSES.has(kind)
    var has_attack := anims.has("attack")
    var move := "walk" if anims.has("walk") else "idle"
    var dying := "death" if anims.has("death") else "idle"
    # Anticipacion y golpe salen del MISMO clip real: la primera parte es la carga, el resto la ejecucion.
    # Los jefes usan su clip "special" para la anticipacion (distinto del ataque normal) cuando existe.
    var windup := "idle"
    var strike := "idle"
    var ranges := {}
    if has_attack:
        windup = "attack"
        strike = "attack"
        ranges["windup"] = [0.0, 0.4]
        ranges["strike"] = [0.4, 1.0]
    if boss and anims.has("special"):
        windup = "special"
        ranges["windup"] = [0.0, 0.55]
        ranges["strike"] = [0.0, 1.0]
    var anim_map := {"idle":"idle", "move":move, "windup":windup, "strike":strike, "recover":"idle", "death":dying}
    if anims.has("hurt"):
        anim_map["hurt"] = "hurt"
        ranges["hurt"] = [0.0, 0.5]
    # SpriteActor derives px-to-world scale from actual alpha bbox, rather than whole cell height.
    var profile := {
        "set":set_id, "height":float(spec["height"]), "filter":"nearest", "fps":FPS,
        "shadow":1.0, "death_dur":0.9 if boss else 0.55,
        "anim_map": anim_map, "ranges": ranges,
        "static_art": not anims.has("walk"),
        "no_death_clip": not anims.has("death")
    }
    if spec.has("tint"):
        profile["tint"] = spec["tint"]
    if BOSSES.has(kind):
        profile["shadow"] = 1.4
        profile["bar_y"] = -float(spec["height"]) - 8.0
    return profile


## Presentation-only boss state map. Values mirror named ST_* constants in the existing boss scripts.
## AI, cooldowns, hitboxes, invulnerability, and HP remain owned by their original scripts.
const BOSS_STATE_ANIMS := {
    "custodio": {"windup":[2, 5, 7, 9, 11, 12], "strike":[3, 6, 8, 10], "recover":[4]},
    "xocotl": {"windup":[2, 4, 7, 8, 12], "strike":[3, 5, 6, 9], "recover":[10, 11]},
    "mariscal": {"windup":[2, 4, 6, 9, 11], "strike":[3, 5, 7], "recover":[8, 10]},
}

static func boss_phase(kind: String, state: int, velocity: Vector2) -> String:
    var config: Dictionary = BOSS_STATE_ANIMS.get(kind, {})
    for phase in ["windup", "strike", "recover"]:
        if (config.get(phase, []) as Array).has(state):
            return phase
    return "move" if velocity.length() > 14.0 else "idle"
