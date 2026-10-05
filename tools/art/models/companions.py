"""Companions that travel beside the adventurer. One model per entry in
src/data/companion_catalog.gd, using the same part names as the other characters so the
game animates them the same way (plus wing_l / wing_r, which flap).

People share one body, a little smaller than the hero, and differ by silhouette: headgear,
what they carry, and one colour family each. Presence grows with rarity.
"""

from lowpoly import Part

from . import model


def _person(name, s, skin, top, legs, boots, trim, robe=None):
    """Shared companion body at scale `s`. Returns its parts by name; `robe` adds a skirt."""
    p = {}
    root = p["root"] = Part(name)
    torso = p["torso"] = Part("torso", (0, 0, 0.82 * s), root)
    torso.box((0.4 * s, 0.24 * s, 0.5 * s), (0, 0, 1.07 * s), top, taper=1.35, bevel=0.035 * s)
    torso.box((0.43 * s, 0.27 * s, 0.09 * s), (0, 0, 0.85 * s), trim, bevel=0.02 * s)
    torso.cyl(0.075 * s, 0.08 * s, (0, 0, 1.35 * s), skin, sides=6)
    if robe:
        torso.cyl(0.3 * s, 0.6 * s, (0, 0, 0.5 * s), robe, sides=8, top=0.2 * s, scale=(1, 0.8))

    head = p["head"] = Part("head", (0, 0, 1.36 * s), torso)
    head.box((0.3 * s, 0.29 * s, 0.3 * s), (0, 0, 1.53 * s), skin, bevel=0.05 * s)
    for x in (-0.07, 0.07):
        head.box((0.045 * s, 0.02, 0.07 * s), (x * s, -0.146 * s, 1.55 * s), "black")

    for side, sx in (("l", 1), ("r", -1)):
        x = sx * 0.34 * s
        arm = p["arm_" + side] = Part("arm_" + side, (x, 0, 1.26 * s), torso)
        arm.ball(0.1 * s, (x, 0, 1.26 * s), top, detail=1)
        arm.cyl(0.07 * s, 0.26 * s, (x, 0, 1.13 * s), top, sides=6, top=0.085 * s)
        arm.cyl(0.075 * s, 0.24 * s, (x, 0, 0.89 * s), top, sides=6, top=0.065 * s)
        arm.box((0.13 * s, 0.15 * s, 0.16 * s), (x, 0, 0.7 * s), skin, bevel=0.03 * s)

        x = sx * 0.12 * s
        leg = p["leg_" + side] = Part("leg_" + side, (x, 0, 0.82 * s), root)
        leg.cyl(0.095 * s, 0.7 * s, (x, 0, 0.48 * s), legs, sides=6, top=0.125 * s)
        leg.box((0.19 * s, 0.32 * s, 0.15 * s), (x, -0.05 * s, 0.075 * s), boots, bevel=0.035 * s)
    return p


def _held(arm, s, side=-1):
    """Where a hand is, for things modelled into an arm part."""
    return side * 0.34 * s, -0.02 * s, 0.7 * s


# --- common -----------------------------------------------------------------

@model("pack_rat", "character", companion="Pack Rat")
def pack_rat():
    """Scavenger: a plump rat under an oversized pack."""
    root = Part("pack_rat")
    body = Part("body", (0, 0, 0.2), root)
    body.box((0.22, 0.22, 0.5), (0, 0.04, 0.2), "leather", rot=(90, 0, 0), taper=0.75, bevel=0.05)
    body.box((0.3, 0.3, 0.26), (0, 0.1, 0.42), "wood_light", bevel=0.04)
    body.cyl(0.07, 0.34, (0, 0.1, 0.6), "cloth_red", sides=6, rot=(0, 90, 0))
    body.box((0.32, 0.04, 0.05), (0, -0.04, 0.42), "leather_dark")

    head = Part("head", (0, -0.2, 0.22), body)
    head.box((0.18, 0.16, 0.22), (0, -0.3, 0.22), "leather", rot=(90, 0, 0), taper=0.5, bevel=0.03)
    head.box((0.04, 0.03, 0.04), (0, -0.42, 0.23), "skin")
    for x in (-0.09, 0.09):
        head.ball(0.06, (x, -0.2, 0.34), "skin", detail=1, scale=(1, 0.5, 1))
        head.box((0.03, 0.02, 0.03), (x * 0.6, -0.36, 0.27), "black")

    parts = [root, body, head]
    for name, x, y in (("leg_fl", 0.09, -0.14), ("leg_fr", -0.09, -0.14), ("leg_bl", 0.1, 0.2), ("leg_br", -0.1, 0.2)):
        leg = Part(name, (x, y, 0.12), root)
        leg.box((0.06, 0.09, 0.12), (x, y - 0.01, 0.06), "skin", bevel=0.015)
        parts.append(leg)
    tail = Part("tail", (0, 0.28, 0.16), body)
    tail.cyl(0.03, 0.4, (0, 0.46, 0.13), "skin", sides=5, top=0.012, rot=(-100, 0, 0))
    parts.append(tail)
    return parts


@model("stable_hound", "character", companion="Stable Hound")
def stable_hound():
    """Trail companion: a friendly hound with floppy ears, a red collar and its tail up."""
    root = Part("stable_hound")
    body = Part("body", (0, 0, 0.4), root)
    body.box((0.26, 0.26, 0.74), (0, 0.02, 0.44), "wood_light", rot=(90, 0, 0), taper=1.25, bevel=0.05)
    body.box((0.2, 0.3, 0.1), (0, 0.1, 0.56), "leather", bevel=0.03)
    body.cyl(0.13, 0.06, (0, -0.33, 0.5), "cloth_red", sides=8, rot=(70, 0, 0))
    body.box((0.05, 0.03, 0.06), (0, -0.4, 0.4), "gold")

    head = Part("head", (0, -0.36, 0.56), body)
    head.box((0.24, 0.22, 0.22), (0, -0.46, 0.62), "wood_light", bevel=0.05)
    head.box((0.15, 0.13, 0.18), (0, -0.63, 0.57), "cloth_cream", rot=(90, 0, 0), taper=0.75, bevel=0.02)
    head.box((0.07, 0.05, 0.05), (0, -0.73, 0.6), "black")
    for x in (-0.13, 0.13):
        head.box((0.05, 0.12, 0.2), (x, -0.44, 0.56), "leather", rot=(0, x * 80, 0), bevel=0.02)
        head.box((0.04, 0.02, 0.05), (x * 0.5, -0.573, 0.66), "black")

    parts = [root, body, head]
    for name, x, y in (("leg_fl", 0.1, -0.24), ("leg_fr", -0.1, -0.24), ("leg_bl", 0.09, 0.3), ("leg_br", -0.09, 0.3)):
        leg = Part(name, (x, y, 0.36), root)
        leg.cyl(0.04, 0.34, (x, y, 0.2), "wood_light", sides=6, top=0.06)
        leg.box((0.09, 0.13, 0.06), (x, y - 0.02, 0.03), "cloth_cream", bevel=0.015)
        parts.append(leg)
    tail = Part("tail", (0, 0.38, 0.5), body)
    tail.cyl(0.045, 0.3, (0, 0.44, 0.63), "wood_light", sides=5, top=0.02, rot=(-25, 0, 0))
    parts.append(tail)
    return parts


@model("torch_sprite", "character", companion="Torch Sprite")
def torch_sprite():
    """Battle spark: a living flame with a bright core. The game floats it at shoulder height."""
    root = Part("torch_sprite")
    body = Part("body", (0, 0, 0.2), root)
    body.ball(0.2, (0, 0, 0.2), "ember", detail=1, scale=(1, 1, 1.05))
    body.cyl(0.11, 0.16, (0, 0, 0.08), "ember", sides=5, top=0.0, rot=(180, 0, 0))
    for x, lean in ((-0.16, 28), (0.16, -28)):
        body.cyl(0.06, 0.18, (x, 0, 0.3), "ember", sides=4, top=0.0, rot=(0, lean, 0))

    head = Part("head", (0, 0, 0.34), body)
    head.cyl(0.14, 0.3, (0, 0, 0.47), "flame", sides=5, top=0.0)
    head.cyl(0.07, 0.2, (0.07, 0.02, 0.44), "flame", sides=4, top=0.0, rot=(0, 20, 0))
    for x in (-0.07, 0.07):
        head.box((0.05, 0.02, 0.07), (x, -0.185, 0.24), "black")
    return [root, body, head]


# --- rare -------------------------------------------------------------------

@model("hill_squire", "character", companion="Hill Squire")
def hill_squire():
    """Bodyguard: kettle helm, tabard and a big shield held forward."""
    s = 0.92
    p = _person("hill_squire", s, "skin", "steel_dark", "leather_dark", "leather", "leather")
    p["torso"].box((0.26 * s, 0.03, 0.5 * s), (0, -0.165 * s, 1.0 * s), "cloth_cream")
    p["torso"].box((0.1 * s, 0.035, 0.1 * s), (0, -0.17 * s, 1.1 * s), "cloth_blue")
    head = p["head"]
    head.cyl(0.27 * s, 0.05 * s, (0, 0, 1.66 * s), "steel", sides=8)
    head.cyl(0.19 * s, 0.14 * s, (0, 0, 1.75 * s), "steel", sides=8, top=0.1 * s)
    x, y, z = _held(p["arm_l"], s, side=1)
    p["arm_l"].box((0.42 * s, 0.07, 0.56 * s), (x + 0.02, y - 0.12 * s, z + 0.12 * s), "steel", taper=0.8, rot=(180, 0, 0), bevel=0.03)
    p["arm_l"].box((0.14 * s, 0.09, 0.3 * s), (x + 0.02, y - 0.13 * s, z + 0.12 * s), "cloth_blue")
    x, y, z = _held(p["arm_r"], s)
    p["arm_r"].box((0.07, 0.05, 0.6 * s), (x, y - 0.26 * s, z + 0.1 * s), "steel", rot=(70, 0, 0))
    p["arm_r"].box((0.2 * s, 0.06, 0.05), (x, y - 0.06 * s, z + 0.02 * s), "iron", rot=(70, 0, 0))
    return list(p.values())


@model("marsh_witch", "character", companion="Marsh Witch")
def marsh_witch():
    """Hedge healer: tall bent hat, long robe and a gnarled staff with a green charm."""
    s = 0.92
    p = _person("marsh_witch", s, "skin", "shadow", "shadow", "leather_dark", "leaf_dark", robe="shadow")
    head = p["head"]
    head.box((0.33 * s, 0.14 * s, 0.34 * s), (0, 0.11 * s, 1.5 * s), "leaf_dark", bevel=0.03)
    head.cyl(0.34 * s, 0.04 * s, (0, 0, 1.69 * s), "shadow", sides=8)
    head.cyl(0.18 * s, 0.26 * s, (0, 0.02, 1.83 * s), "shadow", sides=6, top=0.1 * s, rot=(-8, 0, 0))
    head.cyl(0.1 * s, 0.22 * s, (0, 0.09, 2.02 * s), "shadow", sides=5, top=0.0, rot=(-40, 0, 0))
    head.box((0.36 * s, 0.36 * s, 0.035), (0, 0, 1.73 * s), "leaf_dark")
    x, y, z = _held(p["arm_r"], s)
    p["arm_r"].cyl(0.03, 1.5 * s, (x, y - 0.04, z + 0.25 * s), "wood_dark", sides=5, rot=(8, 0, 0))
    p["arm_r"].cyl(0.03, 0.2 * s, (x + 0.05, y - 0.16, z + 1.02 * s), "wood_dark", sides=5, rot=(10, 40, 0))
    p["arm_r"].ball(0.08 * s, (x, y - 0.17, z + 1.02 * s), "leaf_light", detail=1)
    return list(p.values())


@model("clockwork_raven", "character", companion="Clockwork Raven")
def clockwork_raven():
    """Scout: a brass bird with a wind-up key and one glowing eye. The game floats it."""
    root = Part("clockwork_raven")
    body = Part("body", (0, 0, 0.2), root)
    body.ball(0.17, (0, 0.02, 0.2), "bronze", detail=1, scale=(0.85, 1.4, 0.85))
    body.prism([(-0.1, 0.0), (0.1, 0.0), (0.14, -0.3), (0, -0.24), (-0.14, -0.3)], 0.03, (0, 0.24, 0.2), "steel_dark", rot=(-75, 0, 0))
    body.cyl(0.02, 0.14, (0, 0.06, 0.4), "gold", sides=5)
    body.box((0.16, 0.03, 0.09), (0, 0.06, 0.5), "gold", bevel=0.01)
    for x in (-0.06, 0.06):
        body.cyl(0.015, 0.1, (x, 0.02, 0.05), "gold", sides=4)
        body.box((0.05, 0.09, 0.02), (x, -0.01, 0.01), "gold")

    head = Part("head", (0, -0.18, 0.26), body)
    head.ball(0.11, (0, -0.24, 0.32), "steel_dark", detail=1)
    head.cyl(0.05, 0.2, (0, -0.4, 0.3), "gold", sides=4, top=0.0, rot=(95, 0, 0))
    head.box((0.03, 0.03, 0.05), (0.09, -0.29, 0.34), "storm")
    head.box((0.03, 0.03, 0.05), (-0.09, -0.29, 0.34), "black")

    parts = [root, body, head]
    for side, sx in (("l", 1), ("r", -1)):
        wing = Part("wing_" + side, (sx * 0.13, 0.0, 0.26), body)
        wing.prism([(0.0, 0.0), (0.42 * sx, 0.06), (0.5 * sx, -0.04), (0.36 * sx, -0.1), (0.3 * sx, -0.2), (0.16 * sx, -0.14), (0.0, -0.16)],
                   0.03, (sx * 0.13, 0.06, 0.26), "steel_dark", rot=(-80, 0, 0))
        wing.box((0.2, 0.06, 0.035), (sx * 0.24, -0.02, 0.265), "bronze")
        parts.append(wing)
    return parts


# --- epic -------------------------------------------------------------------

@model("frost_ranger", "character", companion="Frost Ranger")
def frost_ranger():
    """Hunter: fur-trimmed hood, quiver on the back and a pale bow."""
    s = 0.95
    p = _person("frost_ranger", s, "skin", "cloth_blue", "steel_dark", "fur_light", "leather_dark")
    torso = p["torso"]
    torso.box((0.5 * s, 0.34 * s, 0.1 * s), (0, 0, 1.3 * s), "fur_light", bevel=0.03)
    torso.cyl(0.07 * s, 0.5 * s, (0.1 * s, 0.2 * s, 1.15 * s), "leather", sides=6, rot=(0, 18, 0))
    for x in (0.03, 0.08, 0.13):
        torso.box((0.02, 0.02, 0.16 * s), ((x + 0.12) * s, 0.2 * s, 1.44 * s), "moon", rot=(0, 18, 0))
    head = p["head"]
    head.box((0.38 * s, 0.38 * s, 0.13 * s), (0, 0.01, 1.7 * s), "cloth_blue", bevel=0.04)
    head.box((0.38 * s, 0.1 * s, 0.4 * s), (0, 0.17 * s, 1.51 * s), "cloth_blue", bevel=0.03)
    for x in (-0.175, 0.175):
        head.box((0.07 * s, 0.33 * s, 0.36 * s), (x * s, 0.01, 1.5 * s), "cloth_blue", bevel=0.02)
    head.box((0.42 * s, 0.07 * s, 0.07 * s), (0, -0.17 * s, 1.67 * s), "fur_light", bevel=0.02)
    x, y, z = _held(p["arm_l"], s, side=1)
    arm = p["arm_l"]
    for sign in (1, -1):
        arm.box((0.05, 0.05, 0.3 * s), (x, y - 0.06 - 0.02 * sign * sign, z + 0.17 * s * sign), "fur_light", rot=(-12 * sign, 0, 0))
        arm.box((0.05, 0.05, 0.3 * s), (x, y + 0.01, z + 0.44 * s * sign), "fur_light", rot=(22 * sign, 0, 0))
        arm.box((0.06, 0.06, 0.05), (x, y - 0.04, z + 0.31 * s * sign), "moon")
    arm.box((0.012, 0.012, 1.14 * s), (x, y + 0.07, z), "cloth_cream")
    return list(p.values())


@model("sun_cleric", "character", companion="Sun Cleric")
def sun_cleric():
    """Protector: cream and gold robes, a sun disc behind the head and a sun-headed mace."""
    s = 0.95
    p = _person("sun_cleric", s, "skin", "cloth_cream", "cloth_cream", "leather", "gold", robe="cloth_cream")
    torso = p["torso"]
    torso.box((0.12 * s, 0.03, 0.9 * s), (0, -0.19 * s, 0.82 * s), "gold", rot=(-6, 0, 0))
    torso.box((0.5 * s, 0.34 * s, 0.09 * s), (0, 0, 1.29 * s), "gold", bevel=0.03)
    head = p["head"]
    head.box((0.33 * s, 0.32 * s, 0.1 * s), (0, 0.01, 1.68 * s), "white", bevel=0.03)
    head.box((0.33 * s, 0.1 * s, 0.3 * s), (0, 0.13 * s, 1.53 * s), "white", bevel=0.03)
    head.cyl(0.26 * s, 0.03, (0, 0.2 * s, 1.62 * s), "gold", sides=10, rot=(90, 0, 0))
    head.cyl(0.17 * s, 0.035, (0, 0.2 * s, 1.62 * s), "flame", sides=10, rot=(90, 0, 0))
    x, y, z = _held(p["arm_r"], s)
    arm = p["arm_r"]
    arm.cyl(0.03, 0.8 * s, (x, y - 0.03, z + 0.28 * s), "gold", sides=6, rot=(10, 0, 0))
    arm.ball(0.1 * s, (x, y - 0.11, z + 0.74 * s), "flame", detail=1)
    for yaw in (0, 45, 90, 135):
        arm.box((0.34 * s, 0.03, 0.05), (x, y - 0.11, z + 0.74 * s), "gold", rot=(0, yaw, 0))
    return list(p.values())


@model("grave_knight", "character", companion="Grave Knight")
def grave_knight():
    """Executioner: dark plate, closed helm with ember eyes, torn cloak and a great blade."""
    s = 1.0
    p = _person("grave_knight", s, "steel_dark", "steel_dark", "black", "black", "iron")
    torso = p["torso"]
    torso.box((0.46, 0.3, 0.5), (0, 0, 1.075), "steel_dark", taper=1.35, bevel=0.04)
    torso.prism([(-0.26, 0.0), (0.26, 0.0), (0.3, -0.62), (0.12, -0.5), (0.0, -0.7), (-0.14, -0.52), (-0.3, -0.62)], 0.03, (0, 0.2, 1.3), "shadow", rot=(6, 0, 0))
    for x in (-0.36, 0.36):
        torso.ball(0.15, (x, 0, 1.3), "iron", scale=(1, 1.05, 0.75), detail=1)
        torso.cyl(0.05, 0.16, (x * 1.15, 0, 1.42), "iron", sides=4, top=0.0, rot=(0, x * 80, 0))
    head = p["head"]
    head.box((0.36, 0.35, 0.36), (0, 0, 1.54), "iron", bevel=0.06)
    head.box((0.24, 0.03, 0.05), (0, -0.175, 1.57), "black")
    for x in (-0.06, 0.06):
        head.box((0.05, 0.035, 0.035), (x, -0.18, 1.57), "ember")
    head.prism([(-0.03, 0.0), (0.03, 0.0), (0.03, 0.2), (-0.03, 0.12)], 0.3, (0, 0.02, 1.72), "shadow", rot=(0, 0, 90))
    x, y, z = _held(p["arm_r"], s)
    arm = p["arm_r"]
    arm.cyl(0.035, 0.3, (x, y - 0.02, z + 0.02), "black", sides=6, rot=(70, 0, 0))
    arm.box((0.4, 0.08, 0.07), (x, y - 0.2, z + 0.085), "iron", rot=(70, 0, 0), bevel=0.015)
    arm.prism([(-0.1, 0.0), (0.1, 0.0), (0.1, 0.84), (0.0, 1.02), (-0.1, 0.84)], 0.05, (x, y - 0.23, z + 0.095), "steel_dark", rot=(70, 0, 0))
    arm.box((0.05, 0.07, 0.7), (x, y - 0.6, z + 0.23), "ember", rot=(70, 0, 0))
    return list(p.values())


# --- legendary --------------------------------------------------------------

@model("ancient_warden", "character", companion="Ancient Warden")
def ancient_warden():
    """Guardian: a towering stone-and-moss figure with antlers, glowing runes and a tower shield."""
    s = 1.08
    p = _person("ancient_warden", s, "stone", "scale_dark", "stone_dark", "stone_dark", "gold")
    torso = p["torso"]
    torso.box((0.5 * s, 0.32 * s, 0.52 * s), (0, 0, 1.075 * s), "scale_green", taper=1.4, bevel=0.05)
    torso.cyl(0.08 * s, 0.05, (0, -0.2 * s, 1.14 * s), "storm", sides=6, rot=(90, 0, 0))
    torso.box((0.04, 0.03, 0.22 * s), (0, -0.19 * s, 0.94 * s), "storm")
    for x in (-0.4, 0.4):
        torso.ball(0.17 * s, (x * s, 0, 1.3 * s), "stone", scale=(1, 1.1, 0.8), detail=1, jitter=0.1, seed=41)
        torso.ball(0.09 * s, (x * s, 0.03, 1.41 * s), "leaf", detail=1, jitter=0.15, seed=42)
    head = p["head"]
    head.box((0.36 * s, 0.34 * s, 0.14 * s), (0, 0.01, 1.68 * s), "scale_green", bevel=0.04)
    head.box((0.36 * s, 0.1 * s, 0.34 * s), (0, 0.15 * s, 1.52 * s), "scale_green", bevel=0.03)
    for sign in (1, -1):
        head.box((0.04 * s, 0.025, 0.05 * s), (0.07 * s * sign, -0.15 * s, 1.55 * s), "storm")
        head.cyl(0.035 * s, 0.22 * s, (0.17 * s * sign, 0.02, 1.8 * s), "bone", sides=5, top=0.02, rot=(0, 30 * sign, 0))
        head.cyl(0.025 * s, 0.14 * s, (0.26 * s * sign, 0.02, 1.84 * s), "bone", sides=4, top=0.0, rot=(0, 75 * sign, 0))
    x, y, z = _held(p["arm_l"], s, side=1)
    p["arm_l"].box((0.5 * s, 0.09, 0.9 * s), (x + 0.03, y - 0.14 * s, z + 0.14 * s), "stone_dark", taper=0.85, bevel=0.04)
    p["arm_l"].box((0.08 * s, 0.11, 0.6 * s), (x + 0.03, y - 0.15 * s, z + 0.14 * s), "storm")
    p["arm_l"].box((0.3 * s, 0.11, 0.07 * s), (x + 0.03, y - 0.15 * s, z + 0.24 * s), "storm")
    x, y, z = _held(p["arm_r"], s)
    p["arm_r"].cyl(0.04, 1.7 * s, (x, y - 0.03, z + 0.3 * s), "wood_dark", sides=6, rot=(6, 0, 0))
    p["arm_r"].prism([(-0.05, 0.0), (0.05, 0.0), (0.16, 0.2), (0.0, 0.46), (-0.16, 0.2)], 0.05, (x, y - 0.12, z + 1.1 * s), "stone", rot=(6, 0, 0))
    return list(p.values())
