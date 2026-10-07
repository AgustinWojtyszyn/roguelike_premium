# Auditoría y migración de assets (Rpg_new + VIDA → roguelike_premium)

Reproducible: `python3 tools/migrate_assets.py --rpg <clon Rpg_new @ soulknight-polish-pass> --vida <clon VIDA>`.
Inventario completo por blob (hash git, destino y decisión): `docs/asset_inventory.json`. Resumen: `docs/asset_migration_summary.json`.

## Fuentes fijadas
- **Rpg_new**: auditadas las 4 ramas (`main`, `soulknight-polish-pass` = banco grande, `discard/enemy-families-v2`, `discard/pre-astra-single-room-v2`);
  checkout de trabajo `cb0abd70e7ef7aefced6542c0ac1bda83f92e4c8` (soulknight-polish-pass).
- **VIDA** (`Life--simulador-de-vida`): `5d5192da4b258d36a330ef84f5617269ab9d0530`.
- Los frames originales siguen en esos commits (no se duplican aquí); VIDA completo sigue además en `asset_bank/bundles/`.

## Cifras
| | Rpg_new | VIDA | Total |
|---|---:|---:|---:|
| Archivos de arte/audio auditados (todas las rutas) | 2 612 | 440 | 3 052 |
| Blobs únicos (dedup por contenido) | 2 441 | 435 | 2 876 |
| Descartados (duplicados, fuentes de generación, capturas QA) | 72 | 0 | 72 |
| Útiles | 2 391 | 435 | 2 826 |
| Migrados a `assets/migrated/` (fuentes) | 1 380 | 178 | 1 558 |
| PNG resultantes en el repo (hojas + estáticos + armas normalizadas) | 193 | | 193 |
| Integrados al runtime | 193 (todo lo migrado está referenciado) | | |
| En reserva documentada (`asset_bank/reserve/` + bundles) | 1 011 | 257 | 1 268 |

Las animaciones se empaquetan en **hojas por personaje/animación** (filas = direcciones): 1 287 frames de Rpg_new y 172 de VIDA → 94 PNG.

## Qué se integró y cómo (la lógica Premium no cambia)
| Sistema | Cambio | Fallback |
|---|---|---|
| Personajes | `CharacterRig` híbrido: sprite 8/4 direcciones que sigue al apuntado (histeresis, retroceso en reversa), arma/recoil/muzzle/pivot/flash/alpha/pasos/muerte intactos | procedural si no hay perfil o el arte falla |
| Enemigos | `Enemy._try_sprite` + fases lógicas por rol (idle/move/windup/strike/recover/death); IA, vida, hitboxes y ataques siguen siendo Premium | procedural |
| Jefe | Rift Warden → **Vigía de la Grieta** (idle_float / dimensional_cast / projectile_cast / hurt / death) | procedural |
| Armas | 18/18 con arte importado normalizado (eje, recorte, agarre, punta = `muzzle`) vía `WeaponArt.paint`: mano, pickup, armería, colección, HUD | vectorial |
| Cofres | 4 tipos × (cerrado/abierto), variantes dimensional/corrupto en el capítulo de anomalías | vectorial |
| Props | 12 kinds con arte (huella/altura/rotura siguen del `Prop`) + decoración contextual por tema (suelo horneado + piezas altas sin colisión) | vectorial |
| VFX | `Fx` gana una partícula `SPRITE` (mismo pool): impactos, críticos, explosiones, escudo, sangre, curación, loot, fase/aparición de jefe, destello de boca | efecto vectorial previo |
| HOME | `HomeLife`: 4 NPC de VIDA caminando/descansando (walk 8 dir, phone, drink) y props de estación (máquina expendedora, estantes, banco, farola, librería, maceta) | sin cambios si falta |

### Mapeos
- Personajes: Vesper ← Human Ranger (sin arma, arma Premium encima) · Kiro-9 ← Combat Android · Kraal ← Beetle Cyborg · Paradoja ← Mutant Striker.
  Sera, Orla, Halo, Sable, Nyx, Basalto, Ilex **siguen procedurales** (no hay sprite que suba su calidad).
- Enemigos: Caballero ← Bone Guard · Ojo del Vacío ← Orb Stalker · Acechador y Sabueso ← Raptor (matiz violeta / cálido) · Escarabajo de Jade ← Iron Beetle (matiz jade).
- Armas: pulsar←pulse_smg, maul12←breach_shotgun, lancex←alien_beam_rifle, chispa←tactical_sidearm, trinca←swat_compact, mastin←beetle_core,
  gota←living_spore_gun, pomelo←toxic_mortar, relampago←arc_rifle, rebote←void_pistol, colmena←hive_launcher, filo_z←rift_spear,
  garra←mutant_claws, enjambre←beetle_cannon, anomalia←orb_projector, riel_q←bone_rail, brasero←void_launcher, aguja←swat_carbine. (18/18 con arte importado.)

## Reserva (útil, sin uso todavía)
T-Rex (266 frames, candidato a miniboss), Root Vine (sin equivalente orgánico en Premium), Human Ranger armado, poses `holding/*`, tiles/tilesets,
UI (marcos, joystick móvil, minimapa), iconos/held de armas, props sin hueco aún (lab, organic, story), audio Kenney, y de VIDA edificios, casas,
vehículos, catálogo y regiones (urbano: no encaja en mazmorra).

## Descartado
Duplicados por contenido, `.import` viejos, `holding/source/*/accepted` (fuente de generación), capturas de QA, JSON de PixelLab.
