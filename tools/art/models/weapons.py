"""Weapons. Origin at the grip, business end towards +Z, flat in the XZ plane.

Per docs/ART_STYLE_GUIDE.md section 4 they are chunky and 10-20% oversized, and the
silhouette grows with rarity: Common is plain, Rare adds one accent, Epic a distinctive
shape or magical element, Legendary an unmistakable profile.
"""

from lowpoly import Part

from . import model


def _sword(name, length, width, blade, guard, grip, pommel, guard_width=0.34, ridge=None):
    part = Part(name)
    part.cyl(0.035, 0.22, (0, 0, 0), grip, sides=6)
    part.ball(0.06, (0, 0, -0.15), pommel, detail=1)
    part.box((guard_width, 0.09, 0.06), (0, 0, 0.135), guard, bevel=0.015)
    half = width / 2.0
    tip = 0.16 + length
    part.prism([(-half, 0.16), (half, 0.16), (half, tip - width), (0, tip), (-half, tip - width)], 0.05, (0, 0, 0), blade)
    # A raised ridge down the blade keeps it from reading as a flat plank.
    part.box((width * 0.34, 0.075, length * 0.72), (0, 0, 0.16 + length * 0.4), ridge or guard, bevel=0.01)
    return part


@model("iron_sword", "weapon", item="Iron Sword")
def iron_sword():
    return [_sword("iron_sword", 0.72, 0.14, "steel", "iron", "leather", "iron")]


@model("moonsteel_blade", "weapon", item="Moonsteel Blade")
def moonsteel_blade():
    part = _sword("moonsteel_blade", 0.88, 0.15, "steel", "steel_dark", "cloth_blue", "moon", guard_width=0.22, ridge="moon")
    # crescent guard
    part.prism([(-0.24, 0.24), (-0.15, 0.11), (0.15, 0.11), (0.24, 0.24), (0.12, 0.17), (-0.12, 0.17)], 0.09, (0, 0, 0), "steel_dark")
    return [part]


@model("crownblade", "weapon", item="Crownblade")
def crownblade():
    part = _sword("crownblade", 1.02, 0.18, "white", "gold", "cloth_red", "ruby", guard_width=0.44, ridge="gold")
    for x in (-0.17, 0.0, 0.17):
        part.cyl(0.045, 0.11, (x, 0, 0.215), "gold", sides=4, top=0.0)
    return [part]


@model("goblin_cleaver", "weapon", item="Goblin Cleaver")
def goblin_cleaver():
    part = Part("goblin_cleaver")
    part.cyl(0.04, 0.28, (0, 0, 0), "wood_dark", sides=5)
    part.box((0.1, 0.1, 0.045), (0, 0, 0.06), "leather")
    part.box((0.1, 0.1, 0.045), (0, 0, -0.07), "leather")
    part.prism([(-0.05, 0.14), (0.17, 0.17), (0.25, 0.46), (0.15, 0.7), (-0.05, 0.66)], 0.06, (0, 0, 0), "iron")
    part.prism([(0.17, 0.17), (0.3, 0.33), (0.25, 0.46)], 0.04, (0, 0, 0), "steel_dark")
    return [part]


@model("runed_longbow", "weapon", item="Runed Longbow")
def runed_longbow():
    part = Part("runed_longbow")
    part.box((0.075, 0.075, 0.24), (0, 0, 0), "leather", bevel=0.015)
    limbs = [(0.03, 0.22, 14), (0.0, 0.46, 4), (-0.08, 0.68, -22)]
    for sign in (1, -1):
        for x, z, lean in limbs:
            part.box((0.065, 0.06, 0.27), (x, 0, z * sign), "wood", rot=(0, lean * sign, 0))
        part.box((0.085, 0.07, 0.055), (0.0, 0, 0.35 * sign), "moon")
        part.box((0.085, 0.07, 0.055), (-0.035, 0, 0.58 * sign), "moon")
    part.box((0.014, 0.014, 1.56), (-0.135, 0, 0), "cloth_cream")
    return [part]


@model("ember_staff", "weapon", item="Ember Staff")
def ember_staff():
    part = Part("ember_staff")
    part.cyl(0.04, 1.45, (0, 0, 0.27), "wood_dark", sides=6)
    part.box((0.1, 0.1, 0.06), (0, 0, 0.11), "bronze", bevel=0.015)
    part.box((0.1, 0.1, 0.06), (0, 0, -0.11), "bronze", bevel=0.015)
    for x, lean in ((-0.11, -24), (0.11, 24)):
        part.box((0.06, 0.075, 0.3), (x, 0, 1.07), "wood", rot=(0, lean, 0), bevel=0.015)
    part.ball(0.13, (0, 0, 1.14), "ember", detail=1)
    return [part]


@model("stormcaller", "weapon", item="Stormcaller")
def stormcaller():
    part = Part("stormcaller")
    part.cyl(0.04, 1.4, (0, 0, 0.24), "steel_dark", sides=6)
    part.box((0.1, 0.1, 0.06), (0, 0, 0.11), "gold", bevel=0.015)
    part.box((0.1, 0.1, 0.06), (0, 0, -0.11), "gold", bevel=0.015)
    part.cyl(0.13, 0.26, (0, 0, 1.2), "storm", sides=4, top=0.0)
    part.cyl(0.13, 0.18, (0, 0, 0.98), "storm", sides=4, top=0.0, rot=(180, 0, 0))
    for sign in (1, -1):
        part.prism([(0.09 * sign, 0.9), (0.36 * sign, 1.14), (0.24 * sign, 1.28), (0.16 * sign, 1.1)], 0.05, (0, 0, 0), "gold")
    return [part]
