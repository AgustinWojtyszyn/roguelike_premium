# Roguelike Premium

Roguelite de acción top-down para **PC + Android** (Godot 4.7, horizontal). El audio y el arte base (personajes, enemigos, armas,
salas) se generan por código (vectores / síntesis). Encima hay una **capa de arte importado** (pixel art de los proyectos propios
Rpg_new y VIDA, ver `docs/ASSET_AUDIT.md`) que mejora la presentación sin tocar la lógica; cada pieza cae al dibujo procedural si falla
(`--no-sprites` lo fuerza para comparar).

- **PC:** WASD + ratón (clic dispara), `Espacio`/clic derecho = habilidad, `Q`/`E`/rueda/`Tab` = cambiar arma, `1`/`2` = elegir arma, `Esc`/`P` = pausa.
- **Android:** stick izquierdo mueve, mitad derecha apunta y dispara, botón grande de habilidad, botón de cambio de arma, pausa.
- **Mando:** stick izq. mueve, stick der. apunta/dispara, A/X habilidad, RB/LB cambia arma, Start pausa.

## Bucle de juego

`HOME` → elegir personaje y capítulo → **JUGAR** → 5 etapas (combate, combate, cofres, élite, jefe/final) → perks (tras etapas 2 y 4)
→ resultado con recompensas → `HOME`. Sin dash: la defensa son habilidades, escudo y lectura del enemigo (postura, brillo, partículas).

## Modos de juego

`CAMPAÑA` (20 niveles, 4 capítulos = 4 familias de enemigos que nunca se mezclan) · `SUPERVIVENCIA` (4 arenas propias, oleadas infinitas,
una fase por familia: eléctrica → azteca → medieval → interdimensional, mejora entre fases) · `BOSS RUSH` (los 4 jefes seguidos con
zona de preparación: recuperación parcial, 2 armas a elegir y una mejora) · `DESAFÍO` (campaña + una regla: una sola arma, cristal, balas
rápidas, todos élite). Reglas en `game/mode_rules.gd`; marcas en `profile.data["records"]`. Se eligen en el HOME (botón MODO) o con
`--mode=survival|bossrush|challenge [--challenge=glass]` para pruebas.

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
visual/      AssetCatalog (caché de texturas/AnimSets) · VisualProfiles (qué sprite usa cada personaje/enemigo/jefe/prop, escala, anclas, fps)
             SpriteActor (un Sprite2D animado por dirección) · RoomDecor (decoración contextual por tema)
assets/migrated/  arte importado y usado (hojas de animación + estáticos) · data/visual/asset_manifest.gd (generado)
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
| Packs externos | `data/packs/*.tres` (ejemplos en `data/packs_examples/`) | Cualquier `WeaponData`, `PerkData`, `CharacterData`... se registra solo. |

## Pruebas

```bash
godot --headless --path . --import                     # una vez (registra clases)
godot --headless --path . --script tests/run_tests.gd  # unitarias + integración (≈ 1700 comprobaciones)
python3 -m unittest tests.test_android_cold_start      # regresión Android (sin dispositivo)
```

Todo junto (importa, pruebas GDScript + Python y una partida de humo por capítulo; sin ADB ni dispositivo): `tools/check_all.sh`.

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

## Contenido actual

| | |
|---|---|
| Personajes | 11 (Vesper, Kiro-9, Doc Sera, Orla, Halo, Sable, Nyx, Kraal, Basalto, Ilex, Paradoja) + 8 skins |
| Armas | 18 con mecánicas distintas (ráfaga, minigun con arranque, plasma/granada explosivos, rayo en cadena, rebote, misiles/drones teledirigidos, hoja y garras, haz de riel cargado, lanzallamas, francotirador, experimental aleatoria) |
| Enemigos | 18 en 4 familias (máquinas corruptas, civilización de jade, fortaleza escarlata, anomalías) con roles: melee, tirador, francotirador, pesado, torreta, soporte, invocador, embestidor, kamikaze, escudo |
| Jefes | 2 con 3 fases (Custodio – cap. 1, Xocotl – cap. 2); los capítulos 3 y 4 cierran con un encuentro final |
| Capítulos | 4 (tecnología corrupta, azteca-tecnológica, fortaleza oscura, interdimensional), 5 etapas c/u, 25 salas curadas, 28 encuentros |
| Perks | 22 con slots (5), apilables y con comportamientos especiales |
| Meta | HOME, colección, armería, pase (30 niveles, gratis/premium simulado), misiones diarias/semanales/temporada, tienda local, ajustes |
