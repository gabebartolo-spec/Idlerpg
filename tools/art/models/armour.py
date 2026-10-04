"""Armour, sized for the hero. Origin sits on the attach point it is worn at:
head pieces on the head centre, chest pieces on the torso centre, off-hand on the grip."""

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
