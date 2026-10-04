"""Weapons. Origin at the grip, business end towards +Z, flat in the XZ plane."""

from lowpoly import Part

from . import model


def _sword(name, length, width, blade, guard, grip, pommel, guard_width=0.3, fuller=None):
    part = Part(name)
    part.cyl(0.03, 0.2, (0, 0, 0), grip, sides=6)
    part.ball(0.05, (0, 0, -0.13), pommel, detail=1)
    part.box((guard_width, 0.07, 0.05), (0, 0, 0.125), guard)
    half = width / 2.0
    tip = 0.15 + length
    part.prism([(-half, 0.15), (half, 0.15), (half, tip - width), (0, tip), (-half, tip - width)], 0.04, (0, 0, 0), blade)
    if fuller:
        part.box((width * 0.3, 0.05, length * 0.7), (0, 0, 0.15 + length * 0.4), fuller)
    return part


@model("iron_sword", "weapon", item="Iron Sword")
def iron_sword():
    return [_sword("iron_sword", 0.7, 0.11, "steel", "iron", "leather", "iron")]


@model("moonsteel_blade", "weapon", item="Moonsteel Blade")
def moonsteel_blade():
    part = _sword("moonsteel_blade", 0.82, 0.12, "steel", "steel_dark", "cloth_blue", "moon", guard_width=0.2, fuller="moon")
    # crescent guard
    part.prism([(-0.2, 0.2), (-0.13, 0.1), (0.13, 0.1), (0.2, 0.2), (0.1, 0.15), (-0.1, 0.15)], 0.07, (0, 0, 0), "steel_dark")
    return [part]


@model("crownblade", "weapon", item="Crownblade")
def crownblade():
    part = _sword("crownblade", 0.95, 0.14, "white", "gold", "cloth_red", "ruby", guard_width=0.38, fuller="gold")
    for x in (-0.15, 0.0, 0.15):
        part.cyl(0.035, 0.09, (x, 0, 0.19), "gold", sides=4, top=0.0)
    return [part]


@model("goblin_cleaver", "weapon", item="Goblin Cleaver")
def goblin_cleaver():
    part = Part("goblin_cleaver")
    part.cyl(0.035, 0.26, (0, 0, 0), "wood_dark", sides=5)
    part.box((0.09, 0.09, 0.04), (0, 0, 0.05), "leather")
    part.box((0.09, 0.09, 0.04), (0, 0, -0.06), "leather")
    part.prism([(-0.04, 0.13), (0.14, 0.16), (0.2, 0.42), (0.12, 0.62), (-0.04, 0.58)], 0.045, (0, 0, 0), "iron")
    part.prism([(0.14, 0.16), (0.24, 0.3), (0.2, 0.42)], 0.03, (0, 0, 0), "steel_dark")
    return [part]


@model("runed_longbow", "weapon", item="Runed Longbow")
def runed_longbow():
    part = Part("runed_longbow")
    part.box((0.06, 0.06, 0.22), (0, 0, 0), "leather")
    limbs = [(0.03, 0.2, 14), (0.0, 0.42, 4), (-0.07, 0.62, -22)]
    for sign in (1, -1):
        for x, z, lean in limbs:
            part.box((0.05, 0.045, 0.24), (x, 0, z * sign), "wood", rot=(0, lean * sign, 0))
        part.box((0.07, 0.055, 0.05), (0.0, 0, 0.32 * sign), "moon")
        part.box((0.07, 0.055, 0.05), (-0.03, 0, 0.53 * sign), "moon")
    part.box((0.012, 0.012, 1.42), (-0.12, 0, 0), "cloth_cream")
    return [part]


@model("ember_staff", "weapon", item="Ember Staff")
def ember_staff():
    part = Part("ember_staff")
    part.cyl(0.03, 1.4, (0, 0, 0.25), "wood_dark", sides=6)
    part.box((0.08, 0.08, 0.05), (0, 0, 0.1), "bronze")
    part.box((0.08, 0.08, 0.05), (0, 0, -0.1), "bronze")
    for x, lean in ((-0.09, -22), (0.09, 22)):
        part.box((0.045, 0.06, 0.26), (x, 0, 1.03), "wood", rot=(0, lean, 0))
    part.ball(0.1, (0, 0, 1.08), "ember", detail=1)
    return [part]


@model("stormcaller", "weapon", item="Stormcaller")
def stormcaller():
    part = Part("stormcaller")
    part.cyl(0.03, 1.35, (0, 0, 0.22), "steel_dark", sides=6)
    part.box((0.08, 0.08, 0.05), (0, 0, 0.1), "gold")
    part.box((0.08, 0.08, 0.05), (0, 0, -0.1), "gold")
    part.cyl(0.1, 0.2, (0, 0, 1.14), "storm", sides=4, top=0.0)
    part.cyl(0.1, 0.14, (0, 0, 0.97), "storm", sides=4, top=0.0, rot=(180, 0, 0))
    for sign in (1, -1):
        part.prism([(0.08 * sign, 0.9), (0.3 * sign, 1.1), (0.2 * sign, 1.2), (0.13 * sign, 1.06)], 0.035, (0, 0, 0), "gold")
    return [part]
