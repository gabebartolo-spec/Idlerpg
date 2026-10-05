"""World props. Origin on the ground at the footprint centre, front towards -Y.

Per docs/ART_STYLE_GUIDE.md section 5: buildings have steep roofs, thick beams, stone
courses and chunky doors and windows, and nothing is perfectly square; trees have
many-sided trunks and clustered foliage; rocks are faceted with broad planes.
"""

import math

from lowpoly import Part

from . import model


@model("tree_oak", "prop")
def tree_oak():
    part = Part("tree_oak")
    part.cyl(0.34, 0.3, (0, 0, 0.15), "wood_dark", sides=8, top=0.22)
    part.cyl(0.22, 1.1, (0.02, 0, 0.8), "wood_dark", sides=8, top=0.15, rot=(0, 3, 0))
    part.cyl(0.07, 0.5, (0.3, 0.05, 1.3), "wood_dark", sides=5, top=0.05, rot=(0, 50, 0))
    part.ball(0.85, (0, 0, 2.0), "leaf", scale=(1, 1, 0.8), jitter=0.1, seed=1)
    part.ball(0.58, (0.6, 0.2, 1.65), "leaf_dark", jitter=0.1, seed=2)
    part.ball(0.52, (-0.55, -0.25, 1.7), "leaf_light", jitter=0.1, seed=3)
    part.ball(0.45, (0.1, 0.5, 1.6), "leaf_dark", jitter=0.1, seed=4)
    return [part]


@model("tree_pine", "prop")
def tree_pine():
    part = Part("tree_pine")
    part.cyl(0.2, 0.25, (0, 0, 0.125), "wood_dark", sides=6, top=0.14)
    part.cyl(0.14, 0.6, (0, 0, 0.5), "wood_dark", sides=6, top=0.1)
    part.cyl(0.9, 0.95, (0, 0, 1.1), "leaf_dark", sides=8, top=0.12, rot=(3, 0, 0))
    part.cyl(0.7, 0.9, (0.03, 0, 1.7), "leaf", sides=8, top=0.1, rot=(-3, 2, 25))
    part.cyl(0.46, 0.9, (0, 0.02, 2.3), "leaf", sides=8, top=0.0, rot=(2, -3, 50))
    return [part]


@model("bush", "prop")
def bush():
    part = Part("bush")
    part.ball(0.42, (0, 0, 0.25), "leaf", scale=(1.2, 1, 0.8), jitter=0.12, seed=4, floor=0.0)
    part.ball(0.3, (0.36, 0.1, 0.2), "leaf_dark", jitter=0.12, seed=5, floor=0.0)
    part.ball(0.26, (-0.32, -0.15, 0.2), "leaf_light", jitter=0.12, seed=6, floor=0.0)
    return [part]


@model("rock_small", "prop")
def rock_small():
    part = Part("rock_small")
    part.ball(0.4, (0, 0, 0.2), "stone", scale=(1.3, 0.95, 0.8), jitter=0.22, seed=7, floor=0.0, rot=(0, 0, 20))
    part.ball(0.2, (0.36, 0.14, 0.08), "stone_dark", jitter=0.22, seed=17, floor=0.0)
    return [part]


@model("rock_large", "prop")
def rock_large():
    part = Part("rock_large")
    part.ball(0.85, (0, 0, 0.5), "stone", scale=(1.2, 0.9, 1.0), jitter=0.2, seed=8, floor=0.0, rot=(0, 12, 0))
    part.ball(0.5, (0.85, -0.3, 0.25), "stone_dark", scale=(1, 1, 1.2), jitter=0.2, seed=9, floor=0.0)
    part.ball(0.3, (-0.8, 0.35, 0.12), "stone_dark", jitter=0.2, seed=19, floor=0.0)
    return [part]


@model("cottage", "prop")
def cottage():
    part = Part("cottage")
    part.box((2.8, 2.2, 0.45), (0, 0, 0.225), "stone", bevel=0.06)
    part.box((2.55, 1.95, 1.1), (0, 0, 0.95), "plaster", taper=1.04, bevel=0.04)
    for x in (-1.3, 1.3):
        for y in (-1.0, 1.0):
            part.box((0.22, 0.22, 1.15), (x, y, 0.95), "wood_dark", rot=(0, 0, 4))
    part.box((2.85, 0.2, 0.2), (0, -1.02, 1.5), "wood_dark")
    # steep roof with an overhang, ridge a little off-centre
    part.prism([(-1.75, 1.42), (1.75, 1.42), (0.08, 3.2)], 2.7, (0, 0, 0), "roof")
    for y in (-1.38, 1.38):
        part.prism([(-1.87, 1.34), (0.08, 3.34), (1.87, 1.34), (1.66, 1.34), (0.08, 3.1), (-1.66, 1.34)], 0.12, (0, y, 0), "wood_dark")
    # chunky door and window
    part.box((0.78, 0.12, 1.15), (-0.55, -1.02, 0.78), "wood_dark", bevel=0.03)
    part.box((0.6, 0.14, 1.0), (-0.55, -1.03, 0.73), "wood", bevel=0.02)
    part.box((0.08, 0.06, 0.08), (-0.36, -1.11, 0.75), "leather_dark")
    part.box((0.72, 0.12, 0.66), (0.62, -1.0, 1.0), "wood_dark", bevel=0.03)
    part.box((0.52, 0.14, 0.46), (0.62, -1.01, 1.0), "window")
    part.box((0.06, 0.16, 0.46), (0.62, -1.01, 1.0), "wood_dark")
    # chimney, leaning a touch
    part.box((0.46, 0.46, 1.5), (0.95, 0.5, 2.5), "stone", taper=0.8, rot=(0, 3, 0), bevel=0.04)
    part.box((0.5, 0.5, 0.12), (0.99, 0.5, 3.25), "stone_dark")
    return [part]


@model("market_stall", "prop")
def market_stall():
    part = Part("market_stall")
    for x, y, height in ((-0.85, -0.45, 1.75), (0.85, -0.45, 1.7), (-0.85, 0.45, 1.95), (0.85, 0.45, 1.95)):
        part.box((0.14, 0.14, height), (x, y, height / 2.0), "wood_dark", bevel=0.02)
    part.box((1.9, 0.75, 0.12), (0, -0.2, 0.78), "wood", bevel=0.025)
    part.box((1.75, 0.1, 0.72), (0, -0.5, 0.37), "wood_light", bevel=0.02)
    for i, x in enumerate((-0.78, -0.39, 0.0, 0.39, 0.78)):
        part.box((0.39, 1.45, 0.07), (x, -0.05, 1.86), "cloth_red" if i % 2 == 0 else "cloth_cream", rot=(14, 0, 0))
        part.prism([(-0.195, 0.0), (0.195, 0.0), (0, -0.16)], 0.04, (x, -0.76, 1.7), "cloth_red" if i % 2 == 0 else "cloth_cream")
    part.ball(0.11, (-0.45, -0.25, 0.92), "cloth_red", detail=1)
    part.ball(0.11, (-0.22, -0.2, 0.92), "gold", detail=1)
    part.box((0.34, 0.28, 0.2), (0.42, -0.2, 0.94), "wood_light", bevel=0.02)
    return [part]


@model("well", "prop")
def well():
    part = Part("well")
    part.cyl(0.62, 0.55, (0, 0, 0.275), "stone", sides=8, top=0.56, bevel=0.04)
    part.cyl(0.42, 0.02, (0, 0, 0.56), "black", sides=8)
    for x in (-0.52, 0.52):
        part.box((0.14, 0.14, 1.4), (x, 0, 1.0), "wood_dark", bevel=0.02)
    part.prism([(-0.85, 1.6), (0.85, 1.6), (0, 2.35)], 1.05, (0, 0, 0), "roof")
    part.cyl(0.05, 1.04, (0, 0, 1.4), "wood", sides=6, rot=(0, 90, 0))
    part.box((0.03, 0.03, 0.45), (0.1, 0, 1.17), "cloth_cream")
    part.cyl(0.11, 0.16, (0.1, 0, 0.9), "wood", sides=6, top=0.13)
    return [part]


@model("fence", "prop")
def fence():
    part = Part("fence")
    part.box((0.16, 0.16, 0.9), (-0.7, 0, 0.45), "wood_dark", rot=(0, -3, 0), bevel=0.025)
    part.box((0.16, 0.16, 0.8), (0.7, 0, 0.4), "wood_dark", rot=(0, 4, 0), bevel=0.025)
    part.box((1.55, 0.08, 0.13), (0, 0, 0.62), "wood", rot=(0, 3, 0))
    part.box((1.55, 0.08, 0.13), (0, 0, 0.3), "wood", rot=(0, -4, 0))
    return [part]


@model("signpost", "prop")
def signpost():
    part = Part("signpost")
    part.box((0.14, 0.14, 1.6), (0, 0, 0.8), "wood_dark", rot=(0, 3, 0), bevel=0.02)
    part.prism([(-0.12, -0.13), (0.55, -0.13), (0.72, 0.0), (0.55, 0.13), (-0.12, 0.13)], 0.07, (0.04, -0.09, 1.32), "wood_light", rot=(0, -4, 0))
    part.prism([(0.12, -0.12), (-0.5, -0.12), (-0.65, 0.0), (-0.5, 0.12), (0.12, 0.12)], 0.07, (0.03, -0.09, 1.0), "wood_light", rot=(0, 5, 0))
    return [part]


@model("barrel", "prop")
def barrel():
    part = Part("barrel")
    part.cyl(0.27, 0.36, (0, 0, 0.18), "wood", sides=8, top=0.34)
    part.cyl(0.34, 0.36, (0, 0, 0.54), "wood", sides=8, top=0.27)
    part.cyl(0.355, 0.06, (0, 0, 0.36), "iron", sides=8)
    part.cyl(0.29, 0.04, (0, 0, 0.08), "iron", sides=8)
    part.cyl(0.29, 0.04, (0, 0, 0.64), "iron", sides=8)
    part.cyl(0.24, 0.02, (0, 0, 0.72), "wood_dark", sides=8)
    return [part]


@model("crate", "prop")
def crate():
    part = Part("crate")
    part.box((0.62, 0.62, 0.6), (0, 0, 0.3), "wood_light", bevel=0.03)
    for x in (-0.27, 0.27):
        for y in (-0.27, 0.27):
            part.box((0.11, 0.11, 0.63), (x, y, 0.315), "wood")
    part.box((0.66, 0.66, 0.08), (0, 0, 0.59), "wood", bevel=0.02)
    return [part]


@model("goblin_tent", "prop")
def goblin_tent():
    part = Part("goblin_tent")
    part.cyl(1.1, 1.55, (0, 0, 0.775), "leather", sides=7, top=0.1, rot=(0, 0, 30), scale=(1, 0.9))
    part.prism([(-0.38, 0.0), (0.38, 0.0), (0.06, 0.95)], 0.1, (0, -0.7, 0.03), "black", rot=(-24, 0, 0))
    for lean in ((14, 0, 0), (-9, 12, 0), (-7, -13, 0)):
        part.cyl(0.035, 0.7, (0, 0, 1.7), "wood_dark", sides=4, rot=lean)
    part.box((0.34, 0.03, 0.34), (0.55, -0.56, 0.72), "cloth_red", rot=(-30, 0, 30))
    part.box((0.3, 0.03, 0.26), (-0.6, -0.45, 0.6), "leather_dark", rot=(-32, 0, -35))
    return [part]


@model("goblin_totem", "prop")
def goblin_totem():
    part = Part("goblin_totem")
    part.cyl(0.13, 1.75, (0, 0, 0.875), "wood_dark", sides=6, top=0.09, rot=(0, 3, 0))
    part.box((1.0, 0.11, 0.11), (0.05, 0, 1.38), "wood", rot=(0, -5, 0), bevel=0.02)
    part.ball(0.2, (0.09, -0.02, 1.88), "bone", scale=(1, 1, 1.1), detail=1)
    for x in (-0.08, 0.08):
        part.box((0.06, 0.03, 0.06), (0.09 + x, -0.18, 1.9), "black")
        part.cyl(0.05, 0.26, (0.09 + x * 2.8, 0, 2.06), "bone", sides=4, top=0.0, rot=(0, x * 420, 0))
    part.prism([(-0.16, 0.0), (0.16, 0.0), (0.16, -0.46), (0, -0.32), (-0.16, -0.46)], 0.03, (0.36, -0.07, 1.33), "cloth_red")
    part.prism([(-0.12, 0.0), (0.12, 0.0), (0.12, -0.32), (0, -0.22), (-0.12, -0.32)], 0.03, (-0.3, -0.07, 1.4), "leather")
    return [part]


@model("campfire", "prop")
def campfire():
    part = Part("campfire")
    for i in range(6):
        angle = math.tau * i / 6
        part.ball(0.12, (0.4 * math.cos(angle), 0.4 * math.sin(angle), 0.06), "stone", detail=1, jitter=0.2, seed=20 + i, floor=0.0)
    for yaw in (0, 60, 120):
        part.cyl(0.055, 0.64, (0, 0, 0.08), "wood_dark", sides=5, rot=(90, 0, yaw))
    part.cyl(0.18, 0.5, (0, 0, 0.34), "ember", sides=5, top=0.0)
    part.cyl(0.1, 0.34, (0.03, 0.02, 0.3), "flame", sides=4, top=0.0)
    return [part]


@model("wolf_den", "prop")
def wolf_den():
    part = Part("wolf_den")
    part.ball(1.25, (0, 0.3, 0.45), "stone_dark", scale=(1.5, 1.2, 1.0), jitter=0.16, seed=11, floor=0.0)
    part.prism([(-0.6, 0.0), (0.6, 0.0), (0.5, 0.62), (0.05, 0.9), (-0.45, 0.6)], 0.5, (0, -1.05, 0.0), "black")
    part.ball(0.52, (-1.0, -1.1, 0.3), "stone", scale=(1, 1, 1.4), jitter=0.2, seed=12, floor=0.0)
    part.ball(0.45, (0.95, -1.15, 0.25), "stone", scale=(1, 1, 1.5), jitter=0.2, seed=13, floor=0.0)
    part.ball(0.4, (0.1, -0.7, 1.05), "stone", scale=(1.8, 1, 0.7), jitter=0.2, seed=14)
    return [part]


@model("bone_pile", "prop")
def bone_pile():
    part = Part("bone_pile")
    for x, y, yaw in ((0, 0, 20), (0.1, 0.12, 100), (-0.12, 0.05, 150), (0.05, -0.12, 60)):
        part.cyl(0.035, 0.5, (x, y, 0.07), "bone", sides=5, rot=(84, 0, yaw))
    part.ball(0.14, (-0.05, 0.02, 0.19), "bone", detail=1, scale=(1, 1.1, 0.95))
    part.box((0.045, 0.03, 0.045), (-0.11, -0.12, 0.21), "black")
    part.box((0.045, 0.03, 0.045), (0.01, -0.12, 0.21), "black")
    return [part]
