# Banco íntegro de Playground — recibo verificable

Este directorio existe para preservar TODOS los recursos enviados por el usuario, **sin importar si finalmente entran en la versión jugable de RPG Premium**. Godot lo ignora mediante `asset_bank/.gdignore`.

## Contenido esperado tras importar el paquete
- `round_01_drowned_harbor/`: 83 imágenes y 1 audio.
- `round_02_four_worlds/`: 85 imágenes y 2 audios.
- `manual_selection/source_jpg/`: 22 JPG seleccionados personalmente.
- `raw_export_zips/`: tres ZIP originales, incluyendo el parcial.
- `reports/FULL_MEDIA_MANIFEST.json`: hash SHA256 individual de cada archivo, dimensiones, formato y categoría.
- `reports/MEDIA_INVENTORY.csv`, `reports/SPRITESHEET_QA.json`, `reports/R02_PARTIAL_COMPARISON.json` y seis planchas visuales para revisión.

**No se deben eliminar recursos del staging:** los 168 archivos de imagen validados, los 3 audios y las 22 referencias forman el recibo mínimo. Los 4 medios válidos del ZIP parcial ya están en el ZIP completo, pero el snapshot parcial se conserva en bruto.

### Distribución verificada
| Clase | Imágenes |
|---|---:|
| Personajes | 30 |
| Enemigos | 41 |
| Jefes | 22 |
| Armas | 13 |
| Props | 28 |
| VFX | 14 |
| Tilesets | 5 |
| Fondos | 15 |
| **Total de imágenes** | **168** |

Los 5 tilesets pertenecen al primer lote. **No hay tilesets nuevos de los cuatro mundos** en el segundo lote, solamente 9 fondos. Esas escenas no constituyen mapas caminables.

## Paquetes de entrega (creados fuera de GitHub)
| Paquete | Tamaño | SHA256 |
|---|---:|---|
| RPG_PREMIUM_COMPLETE_BANK_FOR_REPO.zip | 344.540.097 bytes | `2571817d6416b9addf2e2f4fb57c783b14351da36c5f3d2650601d976d6e20d9` |
| RPG_PREMIUM_SOURCE_BANK_COMPACT_FOR_REPO.zip | 110.568.683 bytes | `9a4947ea2a2abf95843f0fcf24e76ee7448bdbbb25a2f1a51ff05fb3709fd476` |

El paquete completo contiene PNG verdaderos, 3 MP3, 22 JPG, los tres ZIP originales y reportes. El compacto conserva idénticos medios como WebP originales, sin alterar los píxeles ni ocultar archivos. **Ambos paquetes se instalaron en una carpeta de pruebas** con validación SHA256 de 168 recursos gráficos, 3 audios y 22 referencias.

### Instrucción de instalación
Desde un checkout de esta rama del repositorio:
```bash
python3 tools/install_playground_bank.py "/ruta/RPG_PREMIUM_SOURCE_BANK_COMPACT_FOR_REPO.zip" --dry-run
python3 tools/install_playground_bank.py "/ruta/RPG_PREMIUM_SOURCE_BANK_COMPACT_FOR_REPO.zip"
```
El instalador impide sobrescribir medios distintos y rechaza rutas peligrosas. Luego verificar que el recibo muestra 168 WebP + 3 audio + 22 JPG, o 168 PNG + 3 audio + 22 JPG con el paquete grande.

**IMPORTANTE: estado GitHub**: los ZIP binarios no fueron transferidos directamente a GitHub desde este entorno; sólo la documentación y el instalador están en la rama. Los medios quedan en los paquetes descargables entregados al usuario. Después de instalar desde un checkout con acceso a red, incorporarlos con Git a ESTA rama. No confundir documentación del banco con datos binarios efectivamente subidos.

### Derechos
Pendiente revisar condiciones comerciales de Google Playground y cada recurso de audio. El archivo `THIRD_PARTY_NOTICES.md` en la exportación se refiere a librerías utilizadas por el juego web, no certifica por sí mismo el derecho a redistribuir todo el arte.

### Aceptación
No promover elementos a `assets/premium/` hasta que pasen las reglas de `AGENTS.md`, `docs/PREMIUM_ASSET_REBUILD.md`, la revisión de sprites/grips, la calidad visual y los tests.
