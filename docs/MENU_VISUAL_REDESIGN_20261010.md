# Rediseño de menús — 2026-10-10

Rama: `feat/premium-menu-polish-20261010`. Cambios locales; sin merge.

## Dirección visual

La segunda iteración reemplaza la composición de la portada por navegación lateral, un capítulo ilustrado de gran formato y una franja de preparación con combatiente y JUGAR. El selector de modos combina una vista ilustrada de la experiencia elegida con siete tarjetas en dos columnas. Los estados de dificultad, selección y bloqueo siguen siendo explícitos.

Barlow y Barlow Condensed, fondos oscuros, marfil, oro y acentos por contenido forman el sistema compartido `MenuStyle`. Este sistema se limita a los menús: `UiKit`, el HUD y los sistemas de gameplay no cambian. Las ilustraciones son recursos de presentación ya existentes; no se incorporaron personajes ni fuentes gráficas nuevas del banco Playground.

## Archivos

- `ui/menu_style.gd`: tipografía, paneles, barras, imágenes y retratos con proporciones conservadas.
- `ui/home.gd`, `ui/home_button.gd`: composición del inicio, controles, estados e interacción.
- `ui/mode_select_screen.gd`: selector de modos, reglas y dificultad.
- `ui/menu_screen.gd`: cabecera, fondo, transición y botones de los menús secundarios.
- `ui/collection_screen.gd`: catálogo en dos columnas y más espacio para habilidades y estadísticas.
- `ui/armory_screen.gd`: tarjetas mayores, detalle ilustrado y coordenadas de dibujo coherentes al desplazar.
- `ui/shop_screen.gd`: ofertas adaptadas al ancho y retratos sin deformación.
- `ui/pass_screen.gd`: cabecera ilustrada y pistas sin colisión con el botón inferior.
- `ui/missions_screen.gd`, `ui/news_screen.gd`: composiciones con ilustración, jerarquía editorial y contenido legible.
- `ui/settings_panel.gd`, `ui/pause_menu.gd`: tamaño y separación corregidos para evitar controles superpuestos.
- `ui/result_screen.gd`, `ui/perk_picker.gd`, `ui/route_picker.gd`: presentación coordinada con el resto del producto. No cambia la aplicación de recompensas ni la elección de perks/rutas.
- `assets/ui/fonts/`, `THIRD_PARTY_ASSETS.md`: fuentes OFL, licencia y manifiesto de origen con SHA256.
- `tools/premium_menu_review.gd`, `tools/premium_all_menus_review.gd`, `tools/premium_overlay_review.gd`: comprobaciones focalizadas y capturas reproducibles.

## Validación realizada

Godot **4.7.2**:

- Inicio real `scenes/home.tscn`; seis accesos secundarios, combatiente, JUGAR y ajustes mediante toque.
- Modos: toque, teclado, mando simulado, dificultad, bloqueo, seis señales de lanzamiento y Desafío; selección separada de confirmación, regreso y layout 16:9/ancho.
- Capturas de todos los menús secundarios, contenido desplazado, ajustes y pausa.
- Dibujo real de resultado, perks y rutas con datos de prueba; esas capturas no ejecutan recompensas ni alteran una partida.
- `tests/run_tests.gd -- --only=modes`: **842 OK, 0 fallos**.
- `tests/run_tests.gd -- --only=difficulty`: **46 OK, 0 fallos**.
- `tools/check_premium_art.py`: **OK**.
- `git diff --check`: **OK**.

No se ejecutó la suite global ni se exportó APK. Pendiente: revisión visual en Android físico y con mando físico. Las mediciones de escritorio no certifican FPS Android.

## Reproducir

Desde la raíz del proyecto, ejecutar F5 en Godot (escena principal: `scenes/home.tscn`). La portada nueva tiene una barra lateral y el encabezado **“Prepará tu próxima leyenda.”**.

```sh
XDG_DATA_HOME=/tmp/premium-menu-qa godot --path . --rendering-driver opengl3 --script tools/premium_all_menus_review.gd
XDG_DATA_HOME=/tmp/premium-menu-qa godot --path . --rendering-driver opengl3 --script tools/premium_menu_review.gd
XDG_DATA_HOME=/tmp/premium-overlay-qa godot --path . --rendering-driver opengl3 --script tools/premium_overlay_review.gd
```

Capturas: `/tmp/premium-menu-redesign/`; las del selector focalizado quedan en `/tmp/premium-modes-after.png`, `/tmp/premium-rules-after.png` y `/tmp/premium-modes-wide.png`.
