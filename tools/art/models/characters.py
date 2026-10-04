"""Characters, split into parts that pivot at the joints. The game animates them by
swinging parts (src/view/character_visual.gd), so there is no skinning.

Humanoid parts: torso, head, arm_l, arm_r, leg_l, leg_r.
Quadruped parts: body, head, leg_fl, leg_fr, leg_bl, leg_br, tail.
Attach points (empties): attach_hand_r, attach_hand_l, attach_head, attach_chest,
attach_accessory, and a left/right pair each of attach_glove, attach_leg, attach_foot.
"""

from lowpoly import Part

from . import model

# Weapons point +Z; tilt the right grip so a held weapon points forward and a little up.
GRIP_TILT = (70, 0, 0)


@model("hero", "character")
def hero():
    """The adventurer, per docs/ART_STYLE_GUIDE.md section 3: about 5.5 heads tall, broad
    torso, slightly oversized head and hands, sturdy feet. Gear in armour.py is fitted to
    these dimensions, so change them together."""
    root = Part("hero")
    torso = Part("torso", (0, 0, 0.82), root)
    torso.box((0.4, 0.24, 0.5), (0, 0, 1.07), "cloth_blue", taper=1.35, bevel=0.035)
    torso.box((0.43, 0.27, 0.09), (0, 0, 0.85), "leather", bevel=0.02)
    torso.box((0.09, 0.03, 0.08), (0, -0.14, 0.85), "gold")
    torso.box((0.2, 0.02, 0.09), (0, -0.152, 1.25), "cloth_cream")
    torso.cyl(0.075, 0.08, (0, 0, 1.35), "skin", sides=6)

    head = Part("head", (0, 0, 1.36), torso)
    head.box((0.3, 0.29, 0.3), (0, 0, 1.53), "skin", bevel=0.05)
    head.box((0.33, 0.32, 0.11), (0, 0.01, 1.675), "hair", bevel=0.03)
    head.box((0.33, 0.11, 0.24), (0, 0.13, 1.56), "hair", bevel=0.03)
    head.box((0.33, 0.05, 0.06), (0, -0.14, 1.65), "hair")
    head.box((0.04, 0.04, 0.05), (0, -0.155, 1.5), "skin")
    for x in (-0.07, 0.07):
        head.box((0.045, 0.02, 0.07), (x, -0.146, 1.55), "black")
        head.box((0.07, 0.02, 0.02), (x, -0.148, 1.605), "hair")

    parts = [
        root, torso, head,
        Part("attach_head", (0, 0, 1.53), head),
        Part("attach_chest", (0, 0, 1.07), torso),
        Part("attach_accessory", (0, -0.2, 1.2), torso),
    ]
    for side, sx in (("l", 1), ("r", -1)):
        x = sx * 0.34
        arm = Part("arm_" + side, (x, 0, 1.26), torso)
        arm.ball(0.1, (x, 0, 1.26), "cloth_blue", detail=1)
        arm.cyl(0.07, 0.26, (x, 0, 1.13), "cloth_blue", sides=6, top=0.085)
        arm.cyl(0.075, 0.24, (x, 0, 0.89), "skin", sides=6, top=0.065)
        arm.box((0.13, 0.15, 0.16), (x, 0, 0.7), "skin", bevel=0.03)
        parts += [
            arm,
            Part("attach_hand_" + side, (x, -0.02, 0.7), arm, rot=GRIP_TILT if side == "r" else (0, 0, 0)),
            Part("attach_glove_" + side, (x, 0, 0.7), arm),
        ]

        x = sx * 0.12
        leg = Part("leg_" + side, (x, 0, 0.82), root)
        leg.cyl(0.095, 0.7, (x, 0, 0.48), "leather_dark", sides=6, top=0.125)
        leg.box((0.19, 0.32, 0.15), (x, -0.05, 0.075), "leather", bevel=0.035)
        parts += [
            leg,
            Part("attach_leg_" + side, (x, 0, 0.48), leg),
            Part("attach_foot_" + side, (x, -0.05, 0.075), leg),
        ]
    return parts


def _humanoid(name, s, skin, shirt, pants, boots, belt, head_size=0.42):
    parts = {}
    root = parts["root"] = Part(name)
    torso = parts["torso"] = Part("torso", (0, 0, 0.62 * s), root)
    torso.box((0.5 * s, 0.3 * s, 0.5 * s), (0, 0, 0.9 * s), shirt)
    torso.box((0.52 * s, 0.32 * s, 0.09 * s), (0, 0, 0.68 * s), belt)

    head_z = 1.16 * s + head_size / 2.0 + 0.03 * s
    head = parts["head"] = Part("head", (0, 0, 1.16 * s), torso)
    head.box((head_size, head_size * 0.95, head_size), (0, 0, head_z), skin)
    for x in (-0.24, 0.24):
        head.box((head_size * 0.14, 0.02, head_size * 0.2), (x * head_size, -head_size * 0.48, head_z + head_size * 0.05), "black")

    for side, sx in (("l", 1), ("r", -1)):
        x = sx * 0.33 * s
        arm = parts["arm_" + side] = Part("arm_" + side, (x, 0, 1.1 * s), torso)
        arm.box((0.15 * s, 0.17 * s, 0.36 * s), (x, 0, 0.95 * s), shirt)
        arm.box((0.14 * s, 0.16 * s, 0.15 * s), (x, 0, 0.7 * s), skin)

        x = sx * 0.13 * s
        leg = parts["leg_" + side] = Part("leg_" + side, (x, 0, 0.62 * s), root)
        leg.box((0.2 * s, 0.22 * s, 0.44 * s), (x, 0, 0.41 * s), pants)
        leg.box((0.22 * s, 0.3 * s, 0.2 * s), (x, -0.03 * s, 0.1 * s), boots)
    return parts


@model("goblin", "character")
def goblin():
    parts = _humanoid("goblin", 0.68, "goblin", "goblin_dark", "leather_dark", "goblin_dark", "leather", head_size=0.4)
    head = parts["head"]
    head_z = 1.16 * 0.68 + 0.2 + 0.03 * 0.68
    for sign in (1, -1):
        head.prism([(0.18 * sign, -0.04), (0.44 * sign, 0.12), (0.18 * sign, 0.1)], 0.04, (0, 0.02, head_z), "goblin")
        head.cyl(0.025, 0.07, (0.08 * sign, -0.19, head_z - 0.12), "bone", sides=4, top=0.0)
    head.box((0.08, 0.08, 0.07), (0, -0.21, head_z - 0.03), "goblin_dark")
    parts["torso"].box((0.3, 0.03, 0.2), (0, -0.11, 0.36), "leather")
    # crude club, held like a weapon
    arm = parts["arm_r"]
    arm.cyl(0.035, 0.5, (-0.225, -0.22, 0.52), "wood", sides=5, top=0.07, rot=(70, 0, 0))
    return list(parts.values())


@model("wolf", "character")
def wolf():
    root = Part("wolf")
    body = Part("body", (0, 0, 0.5), root)
    body.box((0.34, 0.9, 0.36), (0, 0.02, 0.52), "fur_grey")
    body.box((0.42, 0.4, 0.44), (0, -0.28, 0.56), "fur_dark")
    body.box((0.2, 0.5, 0.06), (0, 0.1, 0.72), "fur_dark")

    head = Part("head", (0, -0.45, 0.68), body)
    head.box((0.32, 0.3, 0.3), (0, -0.58, 0.74), "fur_grey")
    head.box((0.17, 0.22, 0.14), (0, -0.82, 0.68), "fur_light")
    head.box((0.07, 0.04, 0.05), (0, -0.94, 0.73), "black")
    for x in (-0.1, 0.1):
        head.cyl(0.06, 0.15, (x, -0.5, 0.95), "fur_dark", sides=4, top=0.0)
        head.box((0.05, 0.02, 0.05), (x, -0.735, 0.79), "gold")
        head.cyl(0.02, 0.06, (x * 0.6, -0.88, 0.59), "bone", sides=4, top=0.0, rot=(180, 0, 0))

    parts = [root, body, head]
    for name, x, y in (("leg_fl", 0.14, -0.32), ("leg_fr", -0.14, -0.32), ("leg_bl", 0.14, 0.36), ("leg_br", -0.14, 0.36)):
        leg = Part(name, (x, y, 0.42), root)
        leg.box((0.11, 0.13, 0.36), (x, y, 0.24), "fur_grey")
        leg.box((0.12, 0.17, 0.07), (x, y - 0.02, 0.035), "fur_dark")
        parts.append(leg)

    tail = Part("tail", (0, 0.46, 0.62), body)
    tail.box((0.1, 0.36, 0.1), (0, 0.6, 0.54), "fur_grey", rot=(-28, 0, 0))
    tail.box((0.08, 0.1, 0.08), (0, 0.78, 0.45), "fur_light", rot=(-28, 0, 0))
    parts.append(tail)
    return parts
