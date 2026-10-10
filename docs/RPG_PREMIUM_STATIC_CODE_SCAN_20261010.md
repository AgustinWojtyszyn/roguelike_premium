# RPG Premium — verificación estática exhaustiva de scripts y escenas

**Base:** `main` (`cb2b3e64bddd7ebd6ba1babc5a3586cc8ed8ba5d`). **Fecha:** 2026-10-10.

## Alcance realizado
Usando el conector de GitHub se inspeccionaron **los 143 scripts `.gd` presentes**, incluidos los 5 `tools/premium_render/*.gd`, además de **las 5 escenas `.tscn`** en el árbol completo. No se limitaron las consultas a README ni a módulos seleccionados.

También se consultaron `.github/workflows/android-build.yml`, `tools/check_all.sh`, `tools/check_premium_art.py`, `tools/premium_pipeline.py`, los 11 tests GDScript, documentos y manifiestos visuales, y el log CI del workflow vigente.

Se revisó:
- Existencia de archivos de las referencias estáticas literales `res://...` con extensiones de recursos conocidas.
- Identificadores `class_name` presentes y patrones de colisión visibles.
- Señales textuales de deuda `TODO/FIXME/HACK`.
- Componentes de juego/cámara/escenas, render/catálogo de assets, interfaz, audio y pruebas.
- Separación del banco `asset_bank/` y del runtime `assets/`.

**Resultado del barrido literal:** ~297 referencias estáticas encontradas en scripts/escenas; ninguna referencia faltante de ejecución inequívoca. Se encontraron **dos referencias intencionalmente inexistentes dentro de tests negativos**:
1. `tests/test_premium_slice.gd` utiliza `res://nope.png` en un `AnimSet` sintético para probar el rechazo de perfiles incompletos.
2. `tests/test_visual.gd` comprueba que `res://assets/migrated/rpg/characters/human_ranger/idle.png` NO exista, como protección contra el retorno de arte legacy.

**No arreglar esos dos tests creando los archivos ausentes.** Eso invertiría la intención del control de calidad.

Los nombres `class_name` encontrados en este recorrido no presentaron duplicaciones evidentes. Falsos positivos en cadenas como `TODOS ÉLITE` o `AL DÍA` no indican tareas TODO.

## Advertencias de interpretación
Este barrido detecta **referencias literales**, NO rutas construidas dinámicamente, contenido condicional, recursos externos no indexados ni efectos runtime. Un proyecto con todos los scripts legibles puede tener bugs de jugabilidad/Android/VRAM. La ejecución real de Godot sigue pendiente del entorno con motor y pruebas.

No se descargó ni clonó el repositorio completo en el sistema local del análisis (red no disponible desde el contenedor de archivos); las lecturas se hicieron con el conector GitHub autorizado.

## Hallazgos prioritarios
- `VisualProfiles.CHARACTERS` solo aprueba Vesper y Sable con grips; los otros 9 protagonistas del catálogo requieren nuevos visuales validados.
- `visual/asset_catalog.gd` y el manifiesto Premium centralizan la precarga, pero meter 168 nuevos PNG de golpe multiplicaría memoria, tiempos de importación y gasto de VRAM.
- `game/room_bake.gd`, pooling de proyectiles, controles y sistema de guardado existen y deben permanecer estables.
- `game/themes/` tiene cuatro temas para capítulos. Los fondos panorámicos externos no pueden sustituir automáticamente geometría de mundo ni tilesets transitables.
- El workflow Android de `main` validó pruebas, exportación y firma en la última ejecución, pero el emulador no arrancó (`emulator-5554 not found`, `Timeout waiting for emulator to boot`); la ejecución fue cancelada. Se requiere prueba de apertura real.

## Gates pendientes antes de merge
- Instalación verificada del banco binario en `asset_bank/playground/`.
- Galería visual a escala real e identificación de sprites candidatos.
- Vertical slice con jugador ranged + melee, 2 enemigos, 1 sala compacta, grips/muzzle correctos, controles Android.
- `python3 tools/check_premium_art.py`
- `python3 -m unittest tests.test_premium_pipeline`
- `godot --headless --path . --import`
- `godot --headless --path . --script tests/run_tests.gd`
- `tools/check_all.sh`, revisión de APK y prueba de arranque Android físico.
- Perf 60 FPS como objetivo, no como conclusión sin medición.
- Licencia/atribución de assets y audio nuevos.

**No modificar `main` ni habilitar el banco en runtime en este paso documental.**
