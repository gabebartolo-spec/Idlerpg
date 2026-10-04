"""Shared palette. Every model colour comes from here so the whole game reads as one set.

Colours are sRGB hex. Everything is drawn with one matte material coloured per face;
only the colours listed in GLOWS get a material of their own, so they can emit light.
"""

PALETTE = {
    # metals
    "steel": "#b9c0c9",
    "steel_dark": "#6f7782",
    "iron": "#8a8f94",
    "gold": "#e2b53e",
    "bronze": "#b07a3a",
    # wood, leather, cloth
    "wood": "#7a5230",
    "wood_dark": "#55361f",
    "wood_light": "#a87a4a",
    "leather": "#8b5a33",
    "leather_dark": "#5e3b22",
    "cloth_red": "#b23a34",
    "cloth_blue": "#3b62b0",
    "cloth_cream": "#e3d6b5",
    # living things
    "skin": "#e0b48c",
    "hair": "#5a3a22",
    "goblin": "#6aa53a",
    "goblin_dark": "#4a7a2a",
    "fur_grey": "#7d8288",
    "fur_dark": "#565a60",
    "fur_light": "#c9ccd0",
    "scale_green": "#3d7f6b",
    "scale_dark": "#2b5a4d",
    "shadow": "#4b3a6b",
    "bone": "#e6dfc8",
    # world
    "stone": "#8c8f8a",
    "stone_dark": "#63665f",
    "leaf": "#3f8a3a",
    "leaf_dark": "#2e6b33",
    "leaf_light": "#6fae45",
    "grass": "#3d5c33",
    "grass_dark": "#34502d",
    "plaster": "#d9cdb0",
    "roof": "#a8473a",
    "black": "#23201f",
    "white": "#f2efe6",
    # glows
    "window": "#f3d27a",
    "moon": "#a9d4f5",
    "ember": "#ff7a2a",
    "flame": "#ffd24a",
    "storm": "#7fd6ff",
    "sapphire": "#3f7be0",
    "ruby": "#d8324a",
}

# Emission strength for the few colours that glow.
GLOWS = {
    "window": 0.8,
    "moon": 0.6,
    "ember": 2.0,
    "flame": 2.5,
    "storm": 2.0,
    "sapphire": 0.5,
    "ruby": 0.4,
}
