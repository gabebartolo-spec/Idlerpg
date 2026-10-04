"""Shared palette. Every model colour comes from here so the whole game reads as one set.

name: (sRGB hex, metallic, roughness, emission strength)
"""

PALETTE = {
    # metals
    "steel": ("#b9c0c9", 0.4, 0.35, 0.0),
    "steel_dark": ("#6f7782", 0.4, 0.45, 0.0),
    "iron": ("#8a8f94", 0.3, 0.55, 0.0),
    "gold": ("#e2b53e", 0.5, 0.3, 0.0),
    "bronze": ("#b07a3a", 0.4, 0.45, 0.0),
    # wood, leather, cloth
    "wood": ("#7a5230", 0.0, 0.9, 0.0),
    "wood_dark": ("#55361f", 0.0, 0.9, 0.0),
    "wood_light": ("#a87a4a", 0.0, 0.9, 0.0),
    "leather": ("#8b5a33", 0.0, 0.8, 0.0),
    "leather_dark": ("#5e3b22", 0.0, 0.8, 0.0),
    "cloth_red": ("#b23a34", 0.0, 1.0, 0.0),
    "cloth_blue": ("#3b62b0", 0.0, 1.0, 0.0),
    "cloth_cream": ("#e3d6b5", 0.0, 1.0, 0.0),
    # living things
    "skin": ("#e0b48c", 0.0, 0.9, 0.0),
    "hair": ("#5a3a22", 0.0, 0.9, 0.0),
    "goblin": ("#6aa53a", 0.0, 0.9, 0.0),
    "goblin_dark": ("#4a7a2a", 0.0, 0.9, 0.0),
    "fur_grey": ("#7d8288", 0.0, 1.0, 0.0),
    "fur_dark": ("#565a60", 0.0, 1.0, 0.0),
    "fur_light": ("#c9ccd0", 0.0, 1.0, 0.0),
    "scale_green": ("#3d7f6b", 0.2, 0.6, 0.0),
    "scale_dark": ("#2b5a4d", 0.2, 0.6, 0.0),
    "bone": ("#e6dfc8", 0.0, 0.8, 0.0),
    # world
    "stone": ("#8c8f8a", 0.0, 1.0, 0.0),
    "stone_dark": ("#63665f", 0.0, 1.0, 0.0),
    "leaf": ("#3f8a3a", 0.0, 1.0, 0.0),
    "leaf_dark": ("#2e6b33", 0.0, 1.0, 0.0),
    "leaf_light": ("#6fae45", 0.0, 1.0, 0.0),
    "grass": ("#3d5c33", 0.0, 1.0, 0.0),
    "grass_dark": ("#34502d", 0.0, 1.0, 0.0),
    "plaster": ("#d9cdb0", 0.0, 1.0, 0.0),
    "roof": ("#a8473a", 0.0, 1.0, 0.0),
    "black": ("#23201f", 0.0, 1.0, 0.0),
    "white": ("#f2efe6", 0.0, 0.9, 0.0),
    # glows
    "window": ("#f3d27a", 0.0, 0.8, 0.8),
    "moon": ("#a9d4f5", 0.3, 0.4, 0.6),
    "ember": ("#ff7a2a", 0.0, 0.6, 2.0),
    "flame": ("#ffd24a", 0.0, 0.6, 2.5),
    "storm": ("#7fd6ff", 0.0, 0.4, 2.0),
    "ruby": ("#d8324a", 0.2, 0.3, 0.4),
}
