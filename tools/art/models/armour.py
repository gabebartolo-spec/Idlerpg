"""Armour, fitted to the hero in characters.py. Each piece is modelled around the attach
point it is worn at, so its origin is: the head centre (head), the torso centre (chest),
the grip (off-hand), the middle of one leg (legs), one hand (hands), one foot (feet), or
the pendant centre on the chest (accessory).

Legs, hands and feet are one symmetric piece for a single limb; the game shows it on both.
"""

import math

from lowpoly import Part

from . import model


# --- head -------------------------------------------------------------------

def _hood(name, colour):
    """Open-faced shell around the head: crown, back and sides."""
    part = Part(name)
    part.box((0.39, 0.39, 0.13), (0, 0.01, 0.17), colour, bevel=0.04)
    part.box((0.39, 0.1, 0.4), (0, 0.17, -0.02), colour, bevel=0.03)
    for x in (-0.175, 0.175):
        part.box((0.07, 0.33, 0.36), (x, 0.01, -0.03), colour, bevel=0.02)
    return part


@model("leather_hood", "armour", item="Leather Hood")
def leather_hood():
    part = _hood("leather_hood", "leather")
    part.box((0.46, 0.34, 0.09), (0, 0.01, -0.24), "leather_dark", bevel=0.03)
    part.cyl(0.1, 0.18, (0, 0.14, 0.28), "leather_dark", sides=5, top=0.0, rot=(-30, 0, 0))
    part.box((0.4, 0.05, 0.05), (0, -0.185, 0.13), "leather_dark")
    return [part]


@model("wolfskin_hood", "armour", item="Wolfskin Hood")
def wolfskin_hood():
    part = _hood("wolfskin_hood", "fur_grey")
    part.box((0.48, 0.36, 0.1), (0, 0.02, -0.24), "fur_light", bevel=0.03)
    part.box((0.22, 0.2, 0.1), (0, -0.26, 0.17), "fur_dark", bevel=0.02)
    part.box((0.07, 0.04, 0.04), (0, -0.36, 0.18), "black")
    for x in (-0.12, 0.12):
        part.cyl(0.06, 0.15, (x, 0.05, 0.3), "fur_dark", sides=4, top=0.0)
        part.cyl(0.02, 0.07, (x * 0.6, -0.31, 0.09), "bone", sides=4, top=0.0, rot=(180, 0, 0))
    return [part]


@model("starforged_helm", "armour", item="Starforged Helm")
def starforged_helm():
    part = _hood("starforged_helm", "white")
    part.box((0.41, 0.41, 0.05), (0, 0.01, 0.1), "gold")
    part.box((0.05, 0.05, 0.2), (0, -0.185, 0.02), "gold")
    part.prism([(-0.2, 0.2), (0.2, 0.2), (0.25, 0.38), (-0.1, 0.33)], 0.05, (0, 0, 0), "gold", rot=(0, 0, 90))
    part.cyl(0.05, 0.05, (0, -0.2, 0.15), "storm", sides=4, rot=(90, 0, 0))
    for x in (-0.2, 0.2):
        part.prism([(0.0, 0.0), (0.16, 0.1), (0.1, 0.12), (0.18, 0.22), (0.0, 0.14)], 0.03, (x, 0.1, 0.02), "white", rot=(0, 0, 90))
    return [part]


# --- chest ------------------------------------------------------------------

def _cuirass(part, colour, grow=0.05):
    """Torso shell that follows the hero's tapered chest."""
    part.box((0.4 + grow, 0.24 + grow, 0.5), (0, 0, 0.005), colour, taper=1.35, bevel=0.04)


@model("knight_mail", "armour", item="Knight Mail")
def knight_mail():
    part = Part("knight_mail")
    _cuirass(part, "steel")
    part.box((0.47, 0.31, 0.09), (0, 0, -0.22), "leather_dark", bevel=0.02)
    part.prism([(-0.09, 0.1), (0.09, 0.1), (0.09, 0.0), (0, -0.09), (-0.09, 0.0)], 0.03, (0, -0.185, 0.06), "gold")
    part.cyl(0.12, 0.08, (0, 0, 0.27), "steel_dark", sides=8)
    for x in (-0.36, 0.36):
        part.ball(0.14, (x, 0, 0.2), "steel", scale=(1, 1.05, 0.7), detail=1)
    return [part]


@model("wyrmhide_coat", "armour", item="Wyrmhide Coat")
def wyrmhide_coat():
    part = Part("wyrmhide_coat")
    _cuirass(part, "scale_green")
    part.cyl(0.3, 0.3, (0, 0, -0.38), "scale_dark", sides=8, top=0.22, scale=(1, 0.72))
    part.box((0.47, 0.31, 0.08), (0, 0, -0.22), "leather_dark", bevel=0.02)
    part.box((0.08, 0.03, 0.07), (0, -0.165, -0.22), "gold")
    part.cyl(0.13, 0.1, (0, 0, 0.28), "scale_dark", sides=8, top=0.16)
    for x in (-0.34, 0.34):
        part.box((0.2, 0.26, 0.1), (x, 0, 0.22), "scale_dark", taper=0.6, bevel=0.02)
    for z in (-0.12, 0.04, 0.2):
        part.cyl(0.05, 0.12, (0, 0.2, z), "bone", sides=4, top=0.0, rot=(-70, 0, 0))
    return [part]


@model("titanheart_plate", "armour", item="Titanheart Plate")
def titanheart_plate():
    part = Part("titanheart_plate")
    _cuirass(part, "steel", grow=0.08)
    part.box((0.5, 0.34, 0.09), (0, 0, -0.22), "gold", bevel=0.02)
    part.cyl(0.13, 0.09, (0, 0, 0.27), "steel_dark", sides=8)
    part.cyl(0.1, 0.05, (0, -0.2, 0.08), "gold", sides=6, rot=(90, 0, 0))
    part.cyl(0.065, 0.07, (0, -0.205, 0.08), "ember", sides=6, rot=(90, 0, 0))
    for x in (-0.34, 0.34):
        part.ball(0.15, (x, 0, 0.22), "steel", scale=(1, 1.1, 0.75), detail=1)
        part.box((0.28, 0.34, 0.04), (x, 0, 0.14), "gold", bevel=0.015)
    return [part]


# --- off-hand ---------------------------------------------------------------

@model("oak_buckler", "armour", item="Oak Buckler")
def oak_buckler():
    part = Part("oak_buckler")
    part.cyl(0.32, 0.04, (0, -0.08, 0), "iron", sides=8, rot=(90, 0, 0))
    part.cyl(0.27, 0.07, (0, -0.09, 0), "wood", sides=8, rot=(90, 0, 0))
    part.ball(0.09, (0, -0.13, 0), "steel", detail=1, scale=(1, 0.6, 1))
    part.box((0.54, 0.03, 0.05), (0, -0.125, 0), "iron")
    part.box((0.06, 0.06, 0.2), (0, -0.02, 0), "leather")
    return [part]


# --- legs (one leg) ---------------------------------------------------------

@model("rough_trousers", "armour", item="Rough Trousers")
def rough_trousers():
    part = Part("rough_trousers")
    part.cyl(0.115, 0.6, (0, 0, 0.03), "wood_light", sides=6, top=0.145)
    part.cyl(0.125, 0.06, (0, 0, -0.27), "leather_dark", sides=6)
    part.box((0.1, 0.03, 0.1), (0, -0.115, 0.0), "leather")
    return [part]


@model("steel_greaves", "armour", item="Steel Greaves")
def steel_greaves():
    part = Part("steel_greaves")
    part.cyl(0.12, 0.3, (0, 0, 0.18), "leather_dark", sides=6, top=0.145)
    part.cyl(0.125, 0.34, (0, 0, -0.13), "steel", sides=6, top=0.14)
    part.ball(0.09, (0, -0.1, 0.05), "steel_dark", scale=(1, 0.7, 1), detail=1)
    part.cyl(0.135, 0.04, (0, 0, -0.28), "cloth_blue", sides=6)
    return [part]


@model("dragon_legguards", "armour", item="Dragon Legguards")
def dragon_legguards():
    part = Part("dragon_legguards")
    part.cyl(0.12, 0.62, (0, 0, 0.03), "scale_dark", sides=6, top=0.15)
    part.cyl(0.13, 0.2, (0, 0, -0.18), "scale_green", sides=6, top=0.135)
    part.cyl(0.155, 0.04, (0, 0, 0.3), "gold", sides=6)
    part.cyl(0.06, 0.16, (0, -0.16, 0.06), "bone", sides=4, top=0.0, rot=(65, 0, 0))
    return [part]


# --- hands (one hand) -------------------------------------------------------

@model("hide_gloves", "armour", item="Hide Gloves")
def hide_gloves():
    part = Part("hide_gloves")
    part.box((0.16, 0.18, 0.18), (0, 0, -0.005), "leather", bevel=0.035)
    part.cyl(0.085, 0.07, (0, 0, 0.11), "leather_dark", sides=6, top=0.1)
    return [part]


@model("knight_gauntlets", "armour", item="Knight Gauntlets")
def knight_gauntlets():
    part = Part("knight_gauntlets")
    part.box((0.17, 0.19, 0.18), (0, 0, -0.005), "steel", bevel=0.035)
    part.cyl(0.09, 0.16, (0, 0, 0.16), "steel_dark", sides=6, top=0.13)
    part.box((0.175, 0.06, 0.05), (0, -0.075, -0.04), "cloth_blue")
    return [part]


@model("rune_grips", "armour", item="Rune Grips")
def rune_grips():
    part = Part("rune_grips")
    part.box((0.16, 0.18, 0.18), (0, 0, -0.005), "leather_dark", bevel=0.035)
    part.cyl(0.09, 0.1, (0, 0, 0.125), "shadow", sides=6, top=0.105)
    part.cyl(0.1, 0.03, (0, 0, 0.085), "storm", sides=6)
    return [part]


# --- feet (one foot) --------------------------------------------------------

def _boot(name, colour, shaft, shaft_height, sole="wood_dark"):
    """Boot around the foot, with a shaft up the leg (which sits 5 cm behind the foot centre)."""
    part = Part(name)
    part.box((0.22, 0.35, 0.17), (0, 0, 0.01), colour, bevel=0.04)
    part.box((0.225, 0.355, 0.04), (0, 0, -0.055), sole)
    part.cyl(0.12, shaft_height, (0, 0.05, 0.085 + shaft_height / 2.0), shaft, sides=6, top=0.135)
    return part


@model("trail_boots", "armour", item="Trail Boots")
def trail_boots():
    return [_boot("trail_boots", "leather", "leather_dark", 0.1)]


@model("ranger_boots", "armour", item="Ranger Boots")
def ranger_boots():
    part = _boot("ranger_boots", "leather_dark", "leaf_dark", 0.22)
    part.cyl(0.15, 0.05, (0, 0.05, 0.3), "leaf", sides=6)
    part.box((0.08, 0.02, 0.06), (0, -0.08, 0.2), "steel")
    return [part]


@model("shadow_treads", "armour", item="Shadow Treads")
def shadow_treads():
    part = _boot("shadow_treads", "black", "shadow", 0.16, sole="steel_dark")
    part.box((0.2, 0.1, 0.1), (0, -0.14, -0.01), "steel_dark", bevel=0.02)
    part.cyl(0.14, 0.03, (0, 0.05, 0.24), "moon", sides=6)
    return [part]


@model("worldwalker_boots", "armour", item="Worldwalker Boots")
def worldwalker_boots():
    part = _boot("worldwalker_boots", "white", "gold", 0.14, sole="gold")
    for x in (-0.14, 0.14):
        part.prism([(0.0, 0.0), (0.2, 0.1), (0.14, 0.14), (0.22, 0.22), (0.0, 0.16)], 0.03, (x, 0.1, 0.1), "white", rot=(0, 0, 90))
    part.box((0.08, 0.02, 0.06), (0, -0.18, 0.03), "storm")
    return [part]


# --- accessories (pendant on the chest, face towards -Y) ---------------------

def _ring(part, radius, thickness, colour, at=(0, 0, 0)):
    for i in range(8):
        angle = math.tau * i / 8
        x, z = radius * math.cos(angle), radius * math.sin(angle)
        part.box((radius * 0.85, thickness, thickness), (at[0] + x, at[1], at[2] + z), colour, rot=(0, 90 - math.degrees(angle), 0))


@model("copper_ring", "armour", item="Copper Ring")
def copper_ring():
    part = Part("copper_ring")
    _ring(part, 0.07, 0.03, "bronze")
    part.box((0.05, 0.04, 0.04), (0, 0, 0.078), "leather_dark")
    return [part]


@model("sapphire_charm", "armour", item="Sapphire Charm")
def sapphire_charm():
    part = Part("sapphire_charm")
    _ring(part, 0.04, 0.02, "steel", at=(0, 0, 0.12))
    part.cyl(0.1, 0.04, (0, 0, 0), "steel", sides=6, rot=(90, 0, 0))
    part.cyl(0.07, 0.06, (0, -0.01, 0), "sapphire", sides=6, rot=(90, 0, 0))
    part.cyl(0.05, 0.1, (0, 0, -0.12), "sapphire", sides=4, top=0.0, rot=(180, 0, 0))
    return [part]


@model("phoenix_sigil", "armour", item="Phoenix Sigil")
def phoenix_sigil():
    part = Part("phoenix_sigil")
    part.cyl(0.085, 0.04, (0, 0, 0), "gold", sides=8, rot=(90, 0, 0))
    part.cyl(0.05, 0.06, (0, -0.01, 0), "ember", sides=4, rot=(90, 0, 0))
    for sign in (1, -1):
        part.prism([(0.06 * sign, -0.03), (0.24 * sign, 0.14), (0.14 * sign, 0.08), (0.17 * sign, 0.2), (0.04 * sign, 0.07)], 0.035, (0, 0, 0), "gold")
    part.prism([(-0.04, -0.07), (0.04, -0.07), (0, -0.2)], 0.035, (0, 0, 0), "ember")
    return [part]


@model("thornback_carapace", "armour", item="Thornback Carapace")
def thornback_carapace():
    part = Part("thornback_carapace")
    _cuirass(part, "briar")
    part.box((0.47, 0.31, 0.08), (0, 0, -0.22), "leather_dark", bevel=0.02)
    part.box((0.3, 0.06, 0.34), (0, 0.16, 0.04), "thorn", taper=0.7, bevel=0.02)
    for x, z in ((-0.1, 0.16), (0.1, 0.16), (0, 0.02), (-0.09, -0.1), (0.09, -0.1)):
        part.cyl(0.045, 0.16, (x, 0.24, z), "bone", sides=4, top=0.0, rot=(-80, 0, 0))
    for x in (-0.34, 0.34):
        part.box((0.2, 0.26, 0.1), (x, 0, 0.22), "thorn", taper=0.6, bevel=0.02)
        part.cyl(0.05, 0.2, (x, 0, 0.33), "bone", sides=4, top=0.0)
    part.box((0.3, 0.05, 0.32), (0, -0.165, 0.04), "thorn", taper=0.7, bevel=0.02)
    for x, z in ((-0.08, 0.12), (0.08, 0.12), (0, -0.03)):
        part.cyl(0.04, 0.12, (x, -0.22, z), "bone", sides=4, top=0.0, rot=(80, 0, 0))
    part.cyl(0.13, 0.08, (0, 0, 0.27), "thorn", sides=8)
    return [part]
