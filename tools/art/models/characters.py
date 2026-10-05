"""Characters, split into parts that pivot at the joints. The game animates them by
swinging parts (src/view/character_visual.gd), so there is no skinning.

Humanoid parts: torso, head, arm_l, arm_r, leg_l, leg_r.
Quadruped parts: body, head, leg_fl, leg_fr, leg_bl, leg_br, tail.
Enemies are in enemies.py and use the same part names.
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
