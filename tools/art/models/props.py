"""World props. Origin on the ground at the footprint centre, front towards -Y."""

import math

from lowpoly import Part

from . import model


@model("tree_oak", "prop")
def tree_oak():
    part = Part("tree_oak")
    part.cyl(0.22, 1.3, (0, 0, 0.65), "wood_dark", sides=6, top=0.14)
    part.ball(0.85, (0, 0, 1.95), "leaf", scale=(1, 1, 0.85), jitter=0.08, seed=1)
    part.ball(0.55, (0.55, 0.2, 1.6), "leaf_dark", jitter=0.08, seed=2)
    part.ball(0.5, (-0.5, -0.25, 1.65), "leaf_light", jitter=0.08, seed=3)
    return [part]


@model("tree_pine", "prop")
def tree_pine():
    part = Part("tree_pine")
    part.cyl(0.15, 0.7, (0, 0, 0.35), "wood_dark", sides=6, top=0.11)
    part.cyl(0.85, 0.95, (0, 0, 1.05), "leaf_dark", sides=7, top=0.0)
    part.cyl(0.65, 0.85, (0, 0, 1.65), "leaf", sides=7, top=0.0, rot=(0, 0, 25))
    part.cyl(0.42, 0.75, (0, 0, 2.2), "leaf", sides=7, top=0.0, rot=(0, 0, 50))
    return [part]


@model("bush", "prop")
def bush():
    part = Part("bush")
    part.ball(0.4, (0, 0, 0.25), "leaf", scale=(1.2, 1, 0.8), jitter=0.1, seed=4, floor=0.0)
    part.ball(0.28, (0.35, 0.1, 0.2), "leaf_dark", jitter=0.1, seed=5, floor=0.0)
    part.ball(0.25, (-0.3, -0.15, 0.2), "leaf_light", jitter=0.1, seed=6, floor=0.0)
    return [part]


@model("rock_small", "prop")
def rock_small():
    part = Part("rock_small")
    part.ball(0.38, (0, 0, 0.18), "stone", scale=(1.25, 1, 0.75), jitter=0.14, seed=7, floor=0.0)
    return [part]


@model("rock_large", "prop")
def rock_large():
    part = Part("rock_large")
    part.ball(0.8, (0, 0, 0.45), "stone", scale=(1.25, 1, 0.85), jitter=0.14, seed=8, floor=0.0)
    part.ball(0.45, (0.8, -0.3, 0.2), "stone_dark", jitter=0.14, seed=9, floor=0.0)
    return [part]


@model("cottage", "prop")
def cottage():
    part = Part("cottage")
    part.box((2.6, 2.0, 1.4), (0, 0, 0.7), "plaster")
    for x in (-1.3, 1.3):
        for y in (-1.0, 1.0):
            part.box((0.16, 0.16, 1.4), (x, y, 0.7), "wood_dark")
    part.box((2.7, 0.12, 0.12), (0, -1.0, 1.36), "wood_dark")
    part.prism([(-1.55, 1.35), (1.55, 1.35), (0, 2.5)], 2.4, (0, 0, 0), "roof")
    part.box((0.55, 0.08, 0.95), (-0.55, -1.01, 0.475), "wood")
    part.box((0.06, 0.05, 0.06), (-0.38, -1.06, 0.48), "wood_dark")
    part.box((0.5, 0.06, 0.45), (0.6, -1.01, 0.85), "window")
    part.box((0.6, 0.08, 0.06), (0.6, -1.02, 0.6), "wood_dark")
    part.box((0.34, 0.34, 0.9), (0.85, 0.5, 2.2), "stone")
    return [part]


@model("market_stall", "prop")
def market_stall():
    part = Part("market_stall")
    for x in (-0.8, 0.8):
        for y in (-0.45, 0.45):
            part.box((0.1, 0.1, 1.7), (x, y, 0.85), "wood_dark")
    part.box((1.8, 0.7, 0.1), (0, -0.2, 0.75), "wood")
    part.box((1.7, 0.08, 0.7), (0, -0.5, 0.36), "wood_light")
    for i, x in enumerate((-0.72, -0.36, 0.0, 0.36, 0.72)):
        part.box((0.36, 1.3, 0.06), (x, 0, 1.75), "cloth_red" if i % 2 == 0 else "cloth_cream", rot=(12, 0, 0))
    part.ball(0.1, (-0.4, -0.25, 0.88), "cloth_red", detail=1)
    part.ball(0.1, (-0.2, -0.2, 0.88), "gold", detail=1)
    part.box((0.3, 0.25, 0.18), (0.4, -0.2, 0.89), "wood_light")
    return [part]


@model("well", "prop")
def well():
    part = Part("well")
    part.cyl(0.55, 0.5, (0, 0, 0.25), "stone", sides=8)
    part.cyl(0.4, 0.02, (0, 0, 0.51), "black", sides=8)
    for x in (-0.5, 0.5):
        part.box((0.1, 0.1, 1.3), (x, 0, 0.9), "wood_dark")
    part.prism([(-0.75, 1.5), (0.75, 1.5), (0, 1.95)], 0.9, (0, 0, 0), "roof")
    part.cyl(0.04, 1.0, (0, 0, 1.3), "wood", sides=5, rot=(0, 90, 0))
    return [part]


@model("fence", "prop")
def fence():
    part = Part("fence")
    for x in (-0.7, 0.7):
        part.box((0.12, 0.12, 0.8), (x, 0, 0.4), "wood_dark")
    part.box((1.5, 0.06, 0.1), (0, 0, 0.6), "wood", rot=(0, 2, 0))
    part.box((1.5, 0.06, 0.1), (0, 0, 0.3), "wood", rot=(0, -3, 0))
    return [part]


@model("signpost", "prop")
def signpost():
    part = Part("signpost")
    part.box((0.1, 0.1, 1.5), (0, 0, 0.75), "wood_dark")
    part.prism([(-0.1, -0.1), (0.5, -0.1), (0.62, 0.0), (0.5, 0.1), (-0.1, 0.1)], 0.05, (0, -0.06, 1.25), "wood_light")
    part.prism([(0.1, -0.09), (-0.45, -0.09), (-0.56, 0.0), (-0.45, 0.09), (0.1, 0.09)], 0.05, (0, -0.06, 0.98), "wood_light")
    return [part]


@model("barrel", "prop")
def barrel():
    part = Part("barrel")
    part.cyl(0.26, 0.35, (0, 0, 0.175), "wood", sides=8, top=0.32)
    part.cyl(0.32, 0.35, (0, 0, 0.525), "wood", sides=8, top=0.26)
    part.cyl(0.33, 0.05, (0, 0, 0.35), "iron", sides=8)
    part.cyl(0.24, 0.02, (0, 0, 0.7), "wood_dark", sides=8)
    return [part]


@model("crate", "prop")
def crate():
    part = Part("crate")
    part.box((0.6, 0.6, 0.6), (0, 0, 0.3), "wood_light")
    for x in (-0.27, 0.27):
        for y in (-0.27, 0.27):
            part.box((0.09, 0.09, 0.62), (x, y, 0.31), "wood")
    part.box((0.62, 0.62, 0.07), (0, 0, 0.58), "wood")
    return [part]


@model("goblin_tent", "prop")
def goblin_tent():
    part = Part("goblin_tent")
    part.cyl(1.05, 1.5, (0, 0, 0.75), "leather", sides=6, top=0.1, rot=(0, 0, 30))
    part.prism([(-0.35, 0.0), (0.35, 0.0), (0, 0.9)], 0.1, (0, -0.72, 0.03), "black", rot=(-22, 0, 0))
    for lean in ((12, 0, 0), (-8, 10, 0), (-6, -11, 0)):
        part.cyl(0.03, 0.6, (0, 0, 1.65), "wood_dark", sides=4, rot=lean)
    part.box((0.3, 0.02, 0.3), (0.5, -0.62, 0.7), "cloth_red", rot=(-30, 0, 30))
    return [part]


@model("goblin_totem", "prop")
def goblin_totem():
    part = Part("goblin_totem")
    part.cyl(0.09, 1.7, (0, 0, 0.85), "wood_dark", sides=5, top=0.07)
    part.box((0.9, 0.08, 0.08), (0, 0, 1.35), "wood")
    part.ball(0.17, (0, -0.02, 1.8), "bone", scale=(1, 1, 1.1), detail=1)
    for x in (-0.07, 0.07):
        part.box((0.05, 0.03, 0.05), (x, -0.15, 1.82), "black")
        part.cyl(0.04, 0.2, (x * 2.6, 0, 1.95), "bone", sides=4, top=0.0, rot=(0, x * 400, 0))
    part.prism([(-0.14, 0.0), (0.14, 0.0), (0.14, -0.4), (0, -0.28), (-0.14, -0.4)], 0.02, (0.28, -0.05, 1.3), "cloth_red")
    part.prism([(-0.1, 0.0), (0.1, 0.0), (0.1, -0.28), (0, -0.2), (-0.1, -0.28)], 0.02, (-0.3, -0.05, 1.3), "leather")
    return [part]


@model("campfire", "prop")
def campfire():
    part = Part("campfire")
    for i in range(6):
        angle = math.tau * i / 6
        part.ball(0.11, (0.38 * math.cos(angle), 0.38 * math.sin(angle), 0.06), "stone", detail=1, jitter=0.15, seed=20 + i, floor=0.0)
    for yaw in (0, 60, 120):
        part.box((0.6, 0.09, 0.09), (0, 0, 0.07), "wood_dark", rot=(0, 0, yaw))
    part.cyl(0.16, 0.42, (0, 0, 0.3), "ember", sides=5, top=0.0)
    part.cyl(0.09, 0.3, (0.03, 0.02, 0.28), "flame", sides=4, top=0.0)
    return [part]


@model("wolf_den", "prop")
def wolf_den():
    part = Part("wolf_den")
    part.ball(1.25, (0, 0.3, 0.45), "stone_dark", scale=(1.5, 1.2, 0.95), jitter=0.1, seed=11, floor=0.0)
    part.prism([(-0.55, 0.0), (0.55, 0.0), (0.45, 0.6), (0, 0.85), (-0.45, 0.6)], 0.5, (0, -1.05, 0.0), "black")
    part.ball(0.5, (-1.0, -1.1, 0.3), "stone", scale=(1, 1, 1.2), jitter=0.14, seed=12, floor=0.0)
    part.ball(0.42, (0.95, -1.15, 0.25), "stone", scale=(1, 1, 1.3), jitter=0.14, seed=13, floor=0.0)
    return [part]


@model("bone_pile", "prop")
def bone_pile():
    part = Part("bone_pile")
    for x, y, yaw in ((0, 0, 20), (0.1, 0.12, 100), (-0.12, 0.05, 150), (0.05, -0.12, 60)):
        part.box((0.5, 0.06, 0.06), (x, y, 0.07), "bone", rot=(0, 6, yaw))
    part.ball(0.13, (-0.05, 0.02, 0.17), "bone", detail=1)
    part.box((0.04, 0.03, 0.04), (-0.1, -0.1, 0.19), "black")
    part.box((0.04, 0.03, 0.04), (0.0, -0.1, 0.19), "black")
    return [part]
