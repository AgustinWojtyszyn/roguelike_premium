"""Post-proceso de identidad visual (contorno + gradacion), aplicado a la resolucion de supersampling antes de reducir.
Igual para heroes, enemigos, armas y props: el contorno da lectura en pantallas moviles y unifica fuentes distintas."""
import numpy as np
from PIL import Image, ImageFilter

HERO_OUTLINE = (6, 10, 24)
ENEMY_OUTLINE = (24, 6, 14)
PROP_OUTLINE = (10, 9, 20)


def _disk_dilate(alpha, r):
    """Dilatacion circular aproximada con MaxFilter 3x3 alternando cruz/cuadrado (r en px)."""
    a = alpha
    for i in range(int(r)):
        a = a.filter(ImageFilter.MaxFilter(3))
    return a


def outline(im, width_px, color, strength=1.0):
    """Contorno exterior de `width_px` (px de la imagen dada) alrededor de la silueta. Devuelve RGBA."""
    im = im.convert("RGBA")
    a = im.getchannel("A")
    solid = a.point(lambda v: 255 if v > 24 else 0)
    ring = _disk_dilate(solid, width_px)
    # suavizado del borde exterior (anti-alias)
    ring = ring.filter(ImageFilter.GaussianBlur(max(0.6, width_px * 0.18)))
    ring = ring.point(lambda v: min(255, int(v * 1.25 * strength)))
    base = Image.new("RGBA", im.size, color + (0,))
    base.putalpha(ring)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(base)
    out.alpha_composite(im)
    return out


def grade(im, contrast=1.08, sat=1.0, shadow_tint=(0.94, 0.95, 1.06), highlight_tint=(1.04, 1.0, 0.95)):
    """Curva suave + tinte dividido (sombras frias / luces calidas). No toca el alfa."""
    arr = np.asarray(im.convert("RGBA")).astype(np.float32) / 255.0
    rgb, a = arr[..., :3], arr[..., 3:]
    # des-premultiplica: PIL entrega RGBA recto, asi que no hace falta
    lum = (rgb * np.array([0.299, 0.587, 0.114], np.float32)).sum(-1, keepdims=True)
    rgb = (rgb - 0.5) * contrast + 0.5
    rgb = lum + (rgb - lum) * sat
    t = np.clip(lum, 0, 1)
    tint = np.array(shadow_tint, np.float32) * (1 - t) + np.array(highlight_tint, np.float32) * t
    rgb = np.clip(rgb * tint, 0, 1)
    out = np.concatenate([rgb, a], -1)
    return Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGBA")


def stylize(im, kind, ss=3, outline_px=None):
    """kind: hero | enemy | prop | weapon | flat (sin contorno: suelo y muros). outline_px: grosor en px de la imagen dada."""
    if kind == "hero":
        return outline(grade(im), outline_px or 1.5 * ss, HERO_OUTLINE)
    if kind == "enemy":
        return outline(grade(im), outline_px or 1.6 * ss, ENEMY_OUTLINE)
    if kind == "prop":
        return outline(grade(im), outline_px or 1.1 * ss, PROP_OUTLINE, 0.9)
    if kind == "weapon":
        return outline(grade(im, 1.1), outline_px or 1.3 * ss, HERO_OUTLINE)
    return grade(im, 1.06)
