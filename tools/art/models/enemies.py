"""Enemies. Each family has a silhouette rule from docs/ART_STYLE_GUIDE.md section 3,
and uses the same part names as the hero so the game animates them the same way.
"""

from lowpoly import Part

from . import model


@model("goblin", "character")
def goblin():
    """Narrow torso, long forearms, oversized head and ears, crooked club."""
    root = Part("goblin")
    torso = Part("torso", (0, 0, 0.5), root)
    torso.box((0.24, 0.19, 0.34), (0, 0, 0.68), "goblin", taper=1.25, bevel=0.03)
    torso.box((0.3, 0.22, 0.15), (0, 0, 0.5), "leather", bevel=0.025)
    torso.box((0.16, 0.03, 0.2), (0, -0.115, 0.42), "leather_dark")

    head = Part("head", (0, 0, 0.86), torso)
    head.box((0.4, 0.36, 0.34), (0, -0.03, 1.04), "goblin", bevel=0.06)
    head.cyl(0.05, 0.16, (0, -0.27, 1.01), "goblin_dark", sides=4, top=0.0, rot=(90, 0, 0))
    for sign in (1, -1):
        head.prism([(0.17 * sign, -0.03), (0.52 * sign, 0.16), (0.17 * sign, 0.1)], 0.04, (0, 0.02, 1.04), "goblin")
        head.box((0.08, 0.02, 0.05), (0.1 * sign, -0.212, 1.09), "flame")
        head.box((0.12, 0.03, 0.035), (0.1 * sign, -0.215, 1.135), "goblin_dark", rot=(0, 22 * sign, 0))
        head.cyl(0.025, 0.08, (0.09 * sign, -0.2, 0.94), "bone", sides=4, top=0.0)

    parts = [root, torso, head]
    for side, sx in (("l", 1), ("r", -1)):
        x = sx * 0.2
        arm = Part("arm_" + side, (x, 0, 0.8), torso)
        arm.cyl(0.045, 0.22, (x, 0, 0.7), "goblin", sides=6)
        arm.cyl(0.065, 0.3, (x, 0, 0.45), "goblin", sides=6, top=0.045)
        arm.box((0.11, 0.12, 0.12), (x, 0, 0.27), "goblin_dark", bevel=0.025)
        if side == "r":
            # crooked club, held like a weapon
            arm.cyl(0.03, 0.32, (x, -0.16, 0.325), "wood", sides=5, rot=(70, 0, 0))
            arm.cyl(0.045, 0.3, (x + 0.02, -0.4, 0.45), "wood_dark", sides=5, top=0.085, rot=(56, 0, 8))
            arm.cyl(0.03, 0.1, (x + 0.03, -0.5, 0.6), "bone", sides=4, top=0.0)
        parts.append(arm)

        x = sx * 0.09
        leg = Part("leg_" + side, (x, 0, 0.5), root)
        leg.cyl(0.05, 0.42, (x, 0, 0.29), "goblin", sides=6, top=0.065)
        leg.box((0.13, 0.24, 0.1), (x, -0.04, 0.05), "goblin_dark", bevel=0.025)
        parts.append(leg)
    return parts


@model("wolf", "character")
def wolf():
    """Broad shoulder wedge, low profile, exaggerated snout."""
    root = Part("wolf")
    body = Part("body", (0, 0, 0.45), root)
    # One wedge from narrow haunches to broad shoulders (the box's top faces forward).
    body.box((0.3, 0.3, 1.0), (0, 0.02, 0.5), "fur_grey", rot=(90, 0, 0), taper=1.5, bevel=0.05)
    body.box((0.24, 0.42, 0.1), (0, -0.2, 0.74), "fur_dark", bevel=0.03)
    body.box((0.3, 0.2, 0.2), (0, -0.4, 0.4), "fur_light", bevel=0.04)

    head = Part("head", (0, -0.48, 0.6), body)
    head.box((0.28, 0.26, 0.24), (0, -0.6, 0.62), "fur_grey", bevel=0.05)
    head.box((0.17, 0.13, 0.3), (0, -0.86, 0.58), "fur_light", rot=(90, 0, 0), taper=0.6, bevel=0.02)
    head.box((0.07, 0.05, 0.05), (0, -1.02, 0.6), "black")
    for x in (-0.1, 0.1):
        head.cyl(0.06, 0.17, (x, -0.54, 0.81), "fur_dark", sides=4, top=0.0)
        head.box((0.05, 0.02, 0.04), (x * 0.85, -0.735, 0.67), "flame")
        head.cyl(0.02, 0.07, (x * 0.5, -0.95, 0.5), "bone", sides=4, top=0.0, rot=(180, 0, 0))

    parts = [root, body, head]
    for name, x, y in (("leg_fl", 0.15, -0.3), ("leg_fr", -0.15, -0.3), ("leg_bl", 0.11, 0.4), ("leg_br", -0.11, 0.4)):
        leg = Part(name, (x, y, 0.42), root)
        leg.cyl(0.045, 0.4, (x, y, 0.23), "fur_grey", sides=6, top=0.075)
        leg.box((0.11, 0.17, 0.07), (x, y - 0.02, 0.035), "fur_dark", bevel=0.02)
        parts.append(leg)

    tail = Part("tail", (0, 0.5, 0.52), body)
    tail.cyl(0.07, 0.36, (0, 0.66, 0.46), "fur_grey", sides=6, top=0.04, rot=(-110, 0, 0))
    tail.ball(0.05, (0, 0.84, 0.4), "fur_light", detail=1)
    parts.append(tail)
    return parts
