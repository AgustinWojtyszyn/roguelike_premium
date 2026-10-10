# Auditoría integral y preparación de reconstrucción — RPG PREMIUM
**Fecha:** 2026-10-10
**Repositorio correcto:** `AgustinWojtyszyn/roguelike_premium` (NO `Rpg_new`)
**Base auditada:** `main` en `cb2b3e64bddd7ebd6ba1babc5a3586cc8ed8ba5d`.
**Rama aislada:** `feat/rpg-premium-complete-asset-audit-20261010`.

## 1. Alcance y evidencia
Esta es una **auditoría documental, de estructura GitHub, de contratos gráficos y de las exportaciones Playground**. Se inspeccionó la jerarquía completa de Git: **1.831 entradas / 1.612 archivos / 42.209.301 bytes de blobs**. Hay ~237 fuentes de código/configuración, 143 archivos UID y 5 escenas `.tscn`. Los directorios principales contienen 1.136 entradas en `asset_bank/` y 319 en `assets/`. Se leyeron las reglas AGENTS/ASTRA/CLAUDE, los docs de assets/presentación, los manifiestos, pruebas y los workflows de Android.

**Limitación expresa:** no se clonó ni ejecutó Godot en este contenedor (sin acceso de red desde el entorno de archivos y sin binario Godot local). Por lo tanto **no se certifica** que todos los 1.612 archivos hayan sido ejecutados o revisados línea por línea, que el juego esté libre de bugs, ni que los recursos nuevos ya estén integrados. No confundir revisión estructural + CI histórico con una prueba local nueva.

## 2. Situación del juego actual
- Godot 4.7 (README y configuración), aplicación 2D top-down PC + Android horizontal, modo compatibilidad.
- Catálogo documentado: **4 capítulos × 5 etapas (20 niveles)**; 11 personajes (+8 skins), 18 armas, 18 enemigos en cuatro familias, 22 perks, 25 salas curadas, 28 encuentros. La existencia documentada no implica haber probado aquí todas las rutas.
- Bucle HOME → personaje/capítulo → cinco etapas → recompensas → HOME. Modos campaña, supervivencia, boss rush y desafío.
- La documentación registra **dos jefes completos de tres fases** (Custodio y Xocotl); los capítulos 3 y 4 cierran con encuentros finales, no con otros dos jefes equivalentes. No prometer cuatro bosses finales completos.
- Juego: `game/`, generador `dungeons/`, catálogo `data/`, perfiles `save/`, UI `ui/`, lógica de armas `weapons/`, roles de enemigos `enemies/`, audio `audio/`.
- Gráficos: `visual/asset_catalog.gd`, `visual/sprite_actor.gd`, `visual/visual_profiles.gd`, `data/visual/premium_manifest.gd` y `assets/premium/`. El dibujo estático pasa por RoomBake y las balas/partículas usan pooling; no invalidar esas optimizaciones.

## 3. Riesgos y hallazgos técnicos
**P0 — No romper gameplay/Android ni mezclar staging en runtime.** `asset_bank/.gdignore` separa los originales de los recursos importados. Mantenerlo. No alterar `main` sin validación.

**P0 — Animaciones/agarre de arma.** `VisualProfiles.CHARACTERS` tiene **dos perfiles aprobados de jugables (vesper, sable)**. Los otros personajes del catálogo no equivalen automáticamente a art compatible con armas. `AGENTS.md` impide reintroducir los sprites antiguos de `Rpg_new`, el jugador procedural/poligonal, o un héroe sin pose de mano, grip/muzzle derivado del rig y `weapon_compatible: true`. Los sprites de Playground no cumplen ese contrato automáticamente aunque se vean bien.

**P1 — Escenarios.** Panoramas 1376×768 son fondos, NO mapas caminables. Los cinco PNG llamados tileset pueden ser composiciones ilustradas y requieren validación de grilla, módulos, oclusión y colisiones. Respetar geometría y RoomBake.

**P1 — Escala y memoria.** Hay 91 hojas candidatas de animación (1.252 frames, típicamente 512×512, en 4/16 frames por hoja). Es un banco voluminoso; recortar margen vacío de manera reproducible, limitar precarga y validar ETC2/ASTC; no agregar 168 PNG sin presupuestar VRAM.

**P1 — Perspectiva y estilo.** Varias figuras están de perfil frente a entornos isométricos 3/4; la ilustración no garantiza consistencia con el estilo del juego. Revisar orientación, sombra, paleta, altura y legibilidad a tamaño Android.

**P1 — Procedencia comercial.** Los avisos THIRD_PARTY_NOTICES de Playground solo describen paquetes de software de terceros; no sustituyen el análisis de términos del servicio, derechos de gráficos/música generados y fuentes. Documentar la procedencia antes de publicar.

## 4. Auditoría de ZIPs Playground
Se conservaron los ZIP originales sin modificación.
- `project-files (1).zip`: 83 imágenes reales + 1 MP3.
- `project-files (3).zip`: snapshot incompleto de 85 imágenes + 2 MP3; 83 entradas son `__MEDIA__`, cuatro entradas multimedia reales coinciden byte a byte con `project-files (4).zip`; aporta **cero multimedia exclusivos**.
- `project-files (4).zip`: 85 imágenes reales + 2 MP3.
- Suma de las tandas completas: **168 imágenes + 3 MP3**. Además se conservaron **22 JPG seleccionados manualmente**. Sin duplicados de contenido exacto entre los 171 archivos multimedia válidos de ambas tandas.
- Las 168 imágenes tienen **codificación interna WebP** pese a la extensión `.png`. Se exportaron a PNG auténtico RGBA sin destruir el alfa. El archivo temporal truncado `boss_reality_architect_hurt.png` se rehízo y se verificó. Todas las 168 imágenes PNG del paquete completo pasan `Pillow.verify` y SHA256.
- Distribución: 30 imágenes de personajes, 41 de enemigos, 22 de jefes, 28 props, 15 fondos, 5 tilesets, 14 VFX, 13 armas, 3 MP3.
- Se inspeccionaron 91 hojas con 1.252 frames potenciales; no hay frames con máscara alfa completamente vacía. **No equivale** a certificar locomoción/poses reales, existencia de 8 orientaciones ni sockets.
- Los JPG elegidos individualmente son **referencias**: se mantienen originales sin eliminación destructiva del negro o del contorno magenta.

## 5. Estado Android/CI documentado
En el workflow `Build Android APK` del commit `cb2b3e64...`, ejecución de 2026-10-08:
- `Validate project`, `Export debug APK`, `Align and re-sign distributable APK`, `Verify Android package and signing` y `Upload APK` terminaron **success**.
- La ejecución global concluyó **cancelled** durante la prueba de emulador. El log incluye `adb: device 'emulator-5554' not found`, `Timeout waiting for emulator to boot`, seguida de cancelación. **No se certificó arranque en dispositivo en esa ejecución**.
- Una ejecución anterior falló al alinear/firmar APK; la posterior avanzó más allá de la firma.
- Este informe no ejecutó nuevos tests Godot/Android: la cobertura reciente es evidencia histórica y debe repetirse tras integrar nuevos assets.

## 6. Reconstrucción sin destruir la base
1. **Staging completo, sin exclusiones**: `asset_bank/playground/`, separado por rounds, calidad/categoría, JPG seleccionados, reportes/manifiestos y ZIPs originales.
2. **Curaduría**: galería y lupa de spritesheets; detectar espacios sobrantes, mezcla de ángulos, animaciones inconsistentes y candidatos de tileset.
3. **Slice vertical**: héroe a distancia + héroe melee con sockets/grips reales; esqueleto + criatura; sala compacta con 15–25 props y combate real, antes de mover otras decenas de assets.
4. **Sólo promovidos**: `assets/premium/` + manifiestos `data/visual/`, conservando original en banco. Nunca ejecutar importación masiva directamente al runtime.
5. **Validación**: `python3 tools/check_premium_art.py`, `python3 -m unittest tests.test_premium_pipeline`, `godot --headless --path . --import`, `godot --headless --path . --script tests/run_tests.gd`, `tools/check_all.sh`; QA de cámara y grip, FPS en Android real, build APK y apertura sin fallos.
6. **Fases por capítulo**: tech → jade → fortaleza → anomalía. Respetar catalogación y progresión preexistentes. Si una imagen no encaja todavía, mantenerla en banco con estado `candidate`, no eliminarla.

## 7. Entrega y límites de subida al repositorio
- Los **textos técnicos y el instalador** están versionados en esta rama.
- Los **archivos binarios de los ZIP** se empaquetaron en dos entregas de importación independientes (compacta y PNG completos). La conexión GitHub disponible aquí solo permitió crear/editar contenido UTF-8, **no transferir directamente cientos de MB de archivos binarios desde el contenedor al repositorio**. No afirmar que esos binarios ya están en GitHub.
- La instalación local segura es `python3 tools/install_playground_bank.py RUTA_AL_ZIP`; después se confirma el inventario con SHA256 y se hace commit de `asset_bank/playground/` desde un checkout local. Mantener `main` inalterada y trabajar en esta rama.
- Los paquetes conservan toda la selección; no borrar archivos por considerarlos poco aprovechables.

## 8. Responsabilidades de Claude / Astra
**Claude**: importar el banco binario, ejecutar inventarios, revisar animaciones/sockets, instrumentar galería, integrar primer slice, poner pruebas/optimización reproducible. **Astra**: dirección de arte, consistencia visual a escala 3/4, densidad y legibilidad móvil, iluminación/sombras y aceptación de cambios. No hacer merge automático.

Referencias obligatorias: `AGENTS.md`, `docs/PREMIUM_ASSET_REBUILD.md`, `docs/CLAUDE_ASTRA_ASSET_BRIEF.md`, `docs/PREMIUM_ART_DIRECTION.md`, `THIRD_PARTY_ASSETS.md` y `docs/PLAYGROUND_REBUILD_HANDOFF.md`.
