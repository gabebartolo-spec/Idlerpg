"""Characters, split into parts that pivot at the joints. The game animates them by
swinging parts (src/view/character_visual.gd), so there is no skinning.

Humanoid parts: torso, head, arm_l, arm_r, leg_l, leg_r.
Quadruped parts: body, head, leg_fl, leg_fr, leg_bl, leg_br, tail.
Attach points (empties): attach_hand_r, attach_hand_l, attach_head, attach_chest,
attach_accessory, and a left/right pair each of attach_glove, attach_leg, attach_foot.
"""

from lowpoly import Part

from . import model


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
    parts["attach_head"] = Part("attach_head", (0, 0, head_z), head)
    parts["attach_chest"] = Part("attach_chest", (0, 0, 0.9 * s), torso)
    parts["attach_accessory"] = Part("attach_accessory", (0, -0.17 * s, 0.98 * s), torso)

    for side, sx in (("l", 1), ("r", -1)):
        x = sx * 0.33 * s
        arm = parts["arm_" + side] = Part("arm_" + side, (x, 0, 1.1 * s), torso)
        arm.box((0.15 * s, 0.17 * s, 0.36 * s), (x, 0, 0.95 * s), shirt)
        arm.box((0.14 * s, 0.16 * s, 0.15 * s), (x, 0, 0.7 * s), skin)
        # Weapons point +Z; tilt the grip so a held weapon points forward and a little up.
        tilt = (70, 0, 0) if side == "r" else (0, 0, 0)
        parts["attach_hand_" + side] = Part("attach_hand_" + side, (x, -0.03 * s, 0.68 * s), arm, rot=tilt)
        parts["attach_glove_" + side] = Part("attach_glove_" + side, (x, 0, 0.7 * s), arm)

        x = sx * 0.13 * s
        leg = parts["leg_" + side] = Part("leg_" + side, (x, 0, 0.62 * s), root)
        leg.box((0.2 * s, 0.22 * s, 0.44 * s), (x, 0, 0.41 * s), pants)
        leg.box((0.22 * s, 0.3 * s, 0.2 * s), (x, -0.03 * s, 0.1 * s), boots)
        parts["attach_leg_" + side] = Part("attach_leg_" + side, (x, 0, 0.41 * s), leg)
        parts["attach_foot_" + side] = Part("attach_foot_" + side, (x, -0.03 * s, 0.1 * s), leg)
    return parts


@model("hero", "character")
def hero():
    parts = _humanoid("hero", 1.0, "skin", "cloth_blue", "leather_dark", "leather", "leather")
    parts["torso"].box((0.1, 0.03, 0.1), (0, -0.16, 0.68), "gold")
    parts["torso"].box((0.3, 0.02, 0.14), (0, -0.155, 1.06), "cloth_cream")
    head = parts["head"]
    head.box((0.46, 0.42, 0.08), (0, 0.01, 1.64), "hair")
    head.box((0.46, 0.1, 0.3), (0, 0.19, 1.5), "hair")
    head.box((0.46, 0.06, 0.07), (0, -0.19, 1.59), "hair")
    head.box((0.06, 0.05, 0.07), (0, -0.215, 1.36), "skin")
    return list(parts.values())


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
