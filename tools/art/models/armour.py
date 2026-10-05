"""Armour, sized for the hero. Origin sits on the attach point it is worn at:
head pieces on the head centre, chest pieces on the torso centre, off-hand on the grip."""

import math

from lowpoly import Part

from . import model


def _hood(name, colour):
    part = Part(name)
    part.box((0.5, 0.5, 0.12), (0, 0.0, 0.25), colour)
    part.box((0.5, 0.08, 0.5), (0, 0.24, 0.0), colour)
    for x in (-0.24, 0.24):
        part.box((0.07, 0.44, 0.46), (x, 0.03, 0.0), colour)
    return part


@model("leather_hood", "armour", item="Leather Hood")
def leather_hood():
    part = _hood("leather_hood", "leather")
    part.cyl(0.12, 0.16, (0, 0.14, 0.36), "leather_dark", sides=4, top=0.0, rot=(-25, 0, 45))
    part.box((0.52, 0.04, 0.05), (0, -0.24, 0.2), "leather_dark")
    return [part]


@model("wolfskin_hood", "armour", item="Wolfskin Hood")
def wolfskin_hood():
    part = _hood("wolfskin_hood", "fur_grey")
    part.box((0.3, 0.2, 0.1), (0, -0.32, 0.24), "fur_dark")
    part.box((0.1, 0.05, 0.05), (0, -0.43, 0.25), "black")
    for x in (-0.15, 0.15):
        part.cyl(0.07, 0.16, (x, 0.08, 0.38), "fur_dark", sides=4, top=0.0)
        part.cyl(0.025, 0.08, (x * 0.6, -0.38, 0.16), "bone", sides=4, top=0.0, rot=(180, 0, 0))
    return [part]


@model("oak_buckler", "armour", item="Oak Buckler")
def oak_buckler():
    part = Part("oak_buckler")
    part.cyl(0.3, 0.04, (0, -0.08, 0), "iron", sides=8, rot=(90, 0, 0))
    part.cyl(0.25, 0.07, (0, -0.09, 0), "wood", sides=8, rot=(90, 0, 0))
    part.ball(0.08, (0, -0.13, 0), "steel", detail=1, scale=(1, 0.6, 1))
    part.box((0.5, 0.03, 0.05), (0, -0.125, 0), "iron")
    part.box((0.06, 0.06, 0.2), (0, -0.02, 0), "leather")
    return [part]


@model("knight_mail", "armour", item="Knight Mail")
def knight_mail():
    part = Part("knight_mail")
    part.box((0.56, 0.36, 0.5), (0, 0, 0.02), "steel")
    part.box((0.58, 0.38, 0.09), (0, 0, -0.22), "leather_dark")
    part.prism([(-0.1, 0.12), (0.1, 0.12), (0.1, 0.0), (0, -0.1), (-0.1, 0.0)], 0.03, (0, -0.185, 0.04), "gold")
    part.box((0.3, 0.3, 0.1), (0, 0, 0.3), "steel_dark")
    for x in (-0.36, 0.36):
        part.box((0.24, 0.32, 0.13), (x, 0, 0.24), "steel", taper=0.7)
    return [part]


@model("wyrmhide_coat", "armour", item="Wyrmhide Coat")
def wyrmhide_coat():
    part = Part("wyrmhide_coat")
    part.box((0.56, 0.36, 0.5), (0, 0, 0.02), "scale_green")
    part.box((0.5, 0.32, 0.24), (0, 0, -0.34), "scale_dark", rot=(180, 0, 0), taper=1.25)
    part.box((0.58, 0.38, 0.07), (0, 0, -0.2), "leather_dark")
    part.box((0.08, 0.03, 0.07), (0, -0.2, -0.2), "gold")
    part.box((0.36, 0.34, 0.1), (0, 0.02, 0.3), "scale_dark")
    for x in (-0.35, 0.35):
        part.box((0.2, 0.3, 0.1), (x, 0, 0.25), "scale_dark", taper=0.6)
    for z in (-0.1, 0.06, 0.22):
        part.cyl(0.05, 0.12, (0, 0.22, z), "bone", sides=4, top=0.0, rot=(-70, 0, 0))
    return [part]


@model("starforged_helm", "armour", item="Starforged Helm")
def starforged_helm():
    part = _hood("starforged_helm", "white")
    part.box((0.5, 0.07, 0.2), (0, -0.24, 0.16), "white")
    part.box((0.5, 0.07, 0.16), (0, -0.24, -0.15), "white")
    part.box((0.08, 0.08, 0.2), (0, -0.25, 0.0), "gold")
    part.box((0.54, 0.54, 0.05), (0, 0, 0.19), "gold")
    part.prism([(-0.04, 0.3), (0.04, 0.3), (0.04, 0.5), (-0.04, 0.42)], 0.44, (0, 0.04, 0), "gold", rot=(0, 0, 90))
    part.cyl(0.06, 0.06, (0, -0.29, 0.2), "storm", sides=4, rot=(90, 0, 0))
    return [part]


@model("titanheart_plate", "armour", item="Titanheart Plate")
def titanheart_plate():
    part = Part("titanheart_plate")
    part.box((0.6, 0.4, 0.52), (0, 0, 0.02), "steel", taper=1.12)
    part.box((0.6, 0.4, 0.09), (0, 0, -0.22), "gold")
    part.box((0.34, 0.32, 0.12), (0, 0, 0.32), "steel_dark")
    part.cyl(0.1, 0.05, (0, -0.215, 0.08), "gold", sides=6, rot=(90, 0, 0))
    part.cyl(0.065, 0.07, (0, -0.22, 0.08), "ember", sides=6, rot=(90, 0, 0))
    for x in (-0.36, 0.36):
        part.box((0.26, 0.38, 0.16), (x, 0, 0.26), "steel", taper=0.6)
        part.box((0.27, 0.4, 0.04), (x, 0, 0.17), "gold")
    return [part]


# Legs, hands and feet: one symmetric piece for a single limb, shown on both sides.

@model("rough_trousers", "armour", item="Rough Trousers")
def rough_trousers():
    part = Part("rough_trousers")
    part.box((0.23, 0.25, 0.46), (0, 0, 0), "wood_light")
    part.box((0.24, 0.26, 0.06), (0, 0, -0.2), "leather_dark")
    part.box((0.12, 0.02, 0.12), (0, -0.13, 0.02), "leather")
    return [part]


@model("steel_greaves", "armour", item="Steel Greaves")
def steel_greaves():
    part = Part("steel_greaves")
    part.box((0.23, 0.25, 0.2), (0, 0, 0.13), "leather_dark")
    part.box((0.25, 0.27, 0.28), (0, 0, -0.09), "steel", taper=1.08)
    part.box((0.18, 0.06, 0.12), (0, -0.15, 0.08), "steel_dark", taper=0.7)
    part.box((0.26, 0.28, 0.04), (0, 0, -0.2), "cloth_blue")
    return [part]


@model("dragon_legguards", "armour", item="Dragon Legguards")
def dragon_legguards():
    part = Part("dragon_legguards")
    part.box((0.24, 0.26, 0.46), (0, 0, 0), "scale_dark")
    part.box((0.26, 0.28, 0.14), (0, 0, -0.14), "scale_green")
    part.box((0.26, 0.28, 0.04), (0, 0, 0.2), "gold")
    part.cyl(0.06, 0.14, (0, -0.17, 0.06), "bone", sides=4, top=0.0, rot=(60, 0, 0))
    return [part]


@model("hide_gloves", "armour", item="Hide Gloves")
def hide_gloves():
    part = Part("hide_gloves")
    part.box((0.17, 0.19, 0.17), (0, 0, -0.01), "leather")
    part.box((0.19, 0.21, 0.06), (0, 0, 0.09), "leather_dark")
    return [part]


@model("knight_gauntlets", "armour", item="Knight Gauntlets")
def knight_gauntlets():
    part = Part("knight_gauntlets")
    part.box((0.18, 0.2, 0.17), (0, 0, -0.01), "steel")
    part.box((0.18, 0.2, 0.14), (0, 0, 0.13), "steel_dark", taper=1.3)
    part.box((0.19, 0.05, 0.05), (0, -0.09, -0.06), "cloth_blue")
    return [part]


@model("rune_grips", "armour", item="Rune Grips")
def rune_grips():
    part = Part("rune_grips")
    part.box((0.17, 0.19, 0.17), (0, 0, -0.01), "leather_dark")
    part.box((0.19, 0.21, 0.05), (0, 0, 0.1), "shadow")
    part.box((0.185, 0.205, 0.04), (0, 0, 0.0), "storm")
    return [part]


def _boot(name, colour, cuff, cuff_height=0.08):
    part = Part(name)
    part.box((0.25, 0.33, 0.22), (0, 0, 0), colour)
    part.box((0.25, 0.27, cuff_height), (0, 0.03, 0.11 + cuff_height / 2.0), cuff)
    return part


@model("trail_boots", "armour", item="Trail Boots")
def trail_boots():
    part = _boot("trail_boots", "leather", "leather_dark")
    part.box((0.26, 0.34, 0.04), (0, 0, -0.09), "wood_dark")
    return [part]


@model("ranger_boots", "armour", item="Ranger Boots")
def ranger_boots():
    part = _boot("ranger_boots", "leather_dark", "leaf_dark", cuff_height=0.18)
    part.box((0.27, 0.29, 0.05), (0, 0.03, 0.27), "leaf")
    part.box((0.08, 0.02, 0.06), (0, -0.115, 0.2), "steel")
    return [part]


@model("shadow_treads", "armour", item="Shadow Treads")
def shadow_treads():
    part = _boot("shadow_treads", "black", "shadow", cuff_height=0.14)
    part.box((0.26, 0.1, 0.1), (0, -0.13, -0.05), "steel_dark")
    part.box((0.27, 0.29, 0.03), (0, 0.03, 0.2), "moon")
    return [part]


@model("worldwalker_boots", "armour", item="Worldwalker Boots")
def worldwalker_boots():
    part = _boot("worldwalker_boots", "white", "gold", cuff_height=0.12)
    part.box((0.26, 0.34, 0.04), (0, 0, -0.09), "gold")
    for sign in (1, -1):
        part.prism([(0.0, 0.0), (0.2, 0.1), (0.14, 0.14), (0.22, 0.22), (0.0, 0.16)], 0.03, (0.14 * sign, 0.1, 0.1), "white", rot=(0, 0, 90))
    part.box((0.08, 0.02, 0.06), (0, -0.17, 0.02), "storm")
    return [part]


# Accessories: a pendant on the chest. Origin at the pendant centre, face towards -Y.

def _ring(part, radius, thickness, colour, at=(0, 0, 0)):
    for i in range(8):
        angle = math.tau * i / 8
        x, z = radius * math.cos(angle), radius * math.sin(angle)
        part.box((radius * 0.85, thickness, thickness), (at[0] + x, at[1], at[2] + z), colour, rot=(0, 90 - math.degrees(angle), 0))


@model("copper_ring", "armour", item="Copper Ring")
def copper_ring():
    part = Part("copper_ring")
    _ring(part, 0.05, 0.022, "bronze")
    part.box((0.035, 0.03, 0.03), (0, 0, 0.055), "leather_dark")
    return [part]


@model("sapphire_charm", "armour", item="Sapphire Charm")
def sapphire_charm():
    part = Part("sapphire_charm")
    _ring(part, 0.03, 0.014, "steel", at=(0, 0, 0.085))
    part.cyl(0.07, 0.03, (0, 0, 0), "steel", sides=6, rot=(90, 0, 0))
    part.cyl(0.05, 0.05, (0, -0.01, 0), "sapphire", sides=6, rot=(90, 0, 0))
    part.cyl(0.035, 0.07, (0, 0, -0.085), "sapphire", sides=4, top=0.0, rot=(180, 0, 0))
    return [part]


@model("phoenix_sigil", "armour", item="Phoenix Sigil")
def phoenix_sigil():
    part = Part("phoenix_sigil")
    part.cyl(0.06, 0.03, (0, 0, 0), "gold", sides=8, rot=(90, 0, 0))
    part.cyl(0.035, 0.05, (0, -0.01, 0), "ember", sides=4, rot=(90, 0, 0))
    for sign in (1, -1):
        part.prism([(0.04 * sign, -0.02), (0.17 * sign, 0.1), (0.1 * sign, 0.06), (0.12 * sign, 0.14), (0.03 * sign, 0.05)], 0.025, (0, 0, 0), "gold")
    part.prism([(-0.03, -0.05), (0.03, -0.05), (0, -0.14)], 0.025, (0, 0, 0), "ember")
    return [part]
