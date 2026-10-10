# RPG PREMIUM — banco completo de recursos Playground

**Este es el repositorio correcto: `AgustinWojtyszyn/roguelike_premium`.**

El banco es un área de conservación/curaduría para el RPG Premium existente en Godot 4.7, NO un nuevo juego ni un reemplazo de su runtime.

## Archivos
- `round_01_drowned_harbor/`: 83 imágenes + 1 MP3.
- `round_02_four_worlds/`: 85 imágenes + 2 MP3.
- `manual_selection/source_jpg/`: 22 referencias elegidas a mano.
- `raw_export_zips/`: los tres ZIP originales, incluidos los dos completos y un snapshot parcial.
- `reports/`: manifiestos con SHA256, formatos, transparencia, auditoría de animaciones y planchas visuales.

**Estado remoto:** Los binarios del banco NO están aún en GitHub; este directorio de la rama solo contiene las instrucciones. Importar uno de los paquetes entregados en ChatGPT con:
```bash
python3 tools/install_playground_bank.py "/ruta/RPG_PREMIUM_SOURCE_BANK_COMPACT_FOR_REPO.zip"
```
o usar `RPG_PREMIUM_COMPLETE_BANK_FOR_REPO.zip` si se prefieren todos los PNG convertidos. Los dos pasaron pruebas de extracción SHA256 en un proyecto simulado.

El paquete compacto conserva los originales en archivos `.webp`, identificados según su formato real. El paquete completo convierte las imágenes a PNG auténtico preservando el alfa. Ambos mantienen los ZIP históricos y los 22 JPG.

**Nunca descartar del banco un recurso por no servir hoy.** Aceptar visuales en runtime selectivamente después de verificar cámara/perspectiva, animación, agarre de arma, oclusión, colisiones, rendimiento Android y derechos de uso comercial.

Lectura obligatoria: `docs/RPG_PREMIUM_COMPLETE_AUDIT_20261010.md`, `docs/CLAUDE_RPG_PREMIUM_MASSIVE_REBUILD_PROMPT.md`, `asset_bank/playground/COMPLETE_BANK_RECEIPT_20261010.md` y `AGENTS.md`.

`asset_bank/.gdignore` mantiene fuera del escaneo de Godot estos originales.
