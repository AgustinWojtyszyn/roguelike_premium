# Roguelike Premium

Roguelite de acción top-down para **PC + Android** (Godot 4.7, horizontal). Todo el arte, audio, personajes, enemigos, armas y
mapas son originales y se generan por código (vectores / síntesis): no hay assets de terceros.

- **PC:** WASD + ratón (clic dispara), `Espacio`/clic derecho = habilidad, `Q`/`E`/rueda/`Tab` = cambiar arma, `1`/`2` = elegir arma, `Esc`/`P` = pausa.
- **Android:** stick izquierdo mueve, mitad derecha apunta y dispara, botón grande de habilidad, botón de cambio de arma, pausa.
- **Mando:** stick izq. mueve, stick der. apunta/dispara, A/X habilidad, RB/LB cambia arma, Start pausa.

## Bucle de juego

`HOME` → elegir personaje y capítulo → **JUGAR** → 5 etapas (combate, combate, cofres, élite, jefe/final) → perks (tras etapas 2 y 4)
→ resultado con recompensas → `HOME`. Sin dash: la defensa son habilidades, escudo y lectura del enemigo (postura, brillo, partículas).

## Estructura del proyecto

```
core/        Boot (marcadores Android + argumentos), Router (cambio de escena), Gfx/Part (dibujo vectorial), Rarity, Prof
data/        defs/ (CharacterData, WeaponData, EnemyData, PerkData, MissionData, SeasonData, ChapterData, RoomDef, ...)
             content/ (catálogos en código) · packs/ (.tres opcionales que se auto-registran) · catalog.gd (autoload Catalog)
save/        SaveStore (JSON versionado, atómico, migraciones) · PlayerProfile (datos puros) · Profile (autoload)
meta/        MissionSystem, PassSystem, ShopSystem, RunRewards (lógica pura sobre PlayerProfile)
characters/  CharacterRig (aspecto + animación por código, parametrizado por `look`) · Abilities
weapons/     WeaponArt (dibujo) · WeaponRuntime (cadencia, ráfaga, carga, rebote, cadena, tajo, haz)
enemies/     Enemy base + roles/ (RoleShooter, RoleMelee, RoleCharger, RoleTotem) + una clase por enemigo
bosses/      Boss (fases) + BossCustodio
dungeons/    DungeonGenerator (sala curada + encuentro + semilla)
game/        Game (raíz de la run), RunDirector (etapas/oleadas), Player, Room (+ temas/), Bullets (pool), Fx, Hud, Pickups, Chest...
ui/          Home, Colección, Armería, Pase, Misiones, Tienda, Novedades, Pausa, Perk, Resultado, UiKit/GButton/ScrollPane
audio/       SfxBank (síntesis) + AudioMgr (buses Music/SFX/UI, pools, hilo de síntesis)
tests/       run_tests.gd + test_*.gd (headless)  ·  test_android_cold_start.py (regresión Android, se conserva)
tools/       android_cold_start.py (se conserva) · gallery.tscn (revisión visual de personajes y armas)
```

## Añadir contenido (sin tocar el core)

| Qué | Dónde | Notas |
|---|---|---|
| Personaje | `data/content/content_characters.gd` | `look` = 4 colores base + estilos de silueta (`head`, `torso`, `back`, `shoulder_style`, escalas). Habilidad por `ability_id` en `characters/abilities.gd`. |
| Arma | `data/content/content_weapons.gd` | Stats + `behavior` (`burst`, `spool`, `charge`, `bounce`, `explode`, `homing`, `chain`, `arc`, `beam`, `random`...). Dibujo en `weapons/weapon_art.gd`. |
| Enemigo | `data/content/content_enemies.gd` + clase en `enemies/` | Hereda de un rol (`RoleShooter`...) y solo pinta; la IA viene del rol. |
| Sala | `data/content/content_dungeons.gd` (`rooms()`) | Geometría + bloques + props + spawns. Los tests verifican conectividad y que nada tape los pasillos. |
| Encuentro / capítulo / jefe | mismo archivo | El generador combina piezas con una semilla. |
| Perk | `data/content/content_perks.gd` | `mods` numéricos y/o `hooks` en `game/perk_effects.gd`. |
| Misión / pase / tienda | `data/content/content_meta.gd` | Todo local; el precio del pase vive en `data/defs/pricing.gd`. |
| Tema visual | `game/themes/` | Subclase de `RoomTheme` (suelo, muros, luces, apariciones, bloques). |
| Packs externos | `data/packs/*.tres` | Cualquier `WeaponData`, `PerkData`, `CharacterData`... se registra solo. |

## Pruebas

```bash
godot --headless --path . --import                     # una vez (registra clases)
godot --headless --path . --script tests/run_tests.gd  # unitarias + integración (≈ 1700 comprobaciones)
python3 -m unittest tests.test_android_cold_start      # regresión Android (sin dispositivo)
```

Banco de pruebas de partida (bot) y capturas:

```bash
godot --headless --path . scenes/run.tscn -- --bot --god --speed=6 --quit=300 --seed=5 --chapter=ch2 --fresh
godot --path . scenes/run.tscn -- --idle --god --zoom=0.6 --shots=3 --shotdir=/tmp/s --quit=4 --chapter=ch3
godot --path . -- --snap=2 --snapdir=/tmp/h --exit=3 --fresh --shots=1 --screen=chars     # pantallas del menú
godot --path . scenes/run.tscn -- --perf --bot --god --quit=30 --fresh                      # draw calls / perfil
```

Opciones útiles: `--char=ID --chapter=chN --stage=N --seed=N --weapon=ID --perks=a,b --skin=ID --touch --focus --hide=floor,hud --show=pause|perk|win|lose --autoplay`.

## Android

- La causa del cierre inesperado fue `AudioStreamWAV.loop_end == size`. **Debe ser `size - 1`** (`SfxBank._wav` y `SfxBank.music`); `tests/test_audio_bank.gd` lo vigila.
- Los marcadores `[BOOT 01/09/10]` los emite el autoload `Boot` y los sigue consumiendo `tools/android_cold_start.py`.
- Orientación horizontal bloqueada, renderer `mobile` con respaldo OpenGL (sin cambios).
- La validación en dispositivo físico queda pendiente (no se tocó hardware en esta etapa).

## Rendimiento (resumen)

Capas estáticas de sala (suelo, muros, luces) **horneadas a una textura** (`RoomBake`): de ~2900 a ~900 draw calls y de ~111k a ~26k primitivas;
proyectiles y partículas con **pool**; HUD con redibujo por cambios; props estáticos sin redibujo periódico; síntesis de audio en un hilo.
