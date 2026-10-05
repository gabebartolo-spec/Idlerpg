"""Briarfen: a colder, thornier zone east of Mossgate. Its enemies, its boss, the boss's
reward and the props that dress it. Vocabulary: bare twisted wood, olive briar, long thorns
and dark bog water.
"""

from lowpoly import Part

from . import model


# --- enemies ----------------------------------------------------------------

@model("briarling", "character")
def briarling():
    """A walking bramble: twisted trunk, a thorn-bush head with ember eyes, long claw arms."""
    root = Part("briarling")
    torso = Part("torso", (0, 0, 0.42), root)
    torso.cyl(0.17, 0.56, (0, 0, 0.7), "thorn", sides=6, top=0.11, rot=(0, 5, 0))
    torso.ball(0.2, (0, 0.02, 0.5), "briar", detail=1, jitter=0.15, seed=51, scale=(1, 0.9, 0.7))
    for x, z, lean in ((0.12, 0.8, 55), (-0.11, 0.66, -60), (0.0, 0.9, 10)):
        torso.cyl(0.03, 0.2, (x, 0.1, z), "thorn", sides=4, top=0.0, rot=(-40, lean, 0))

    head = Part("head", (0, 0, 0.98), torso)
    head.ball(0.24, (0, -0.02, 1.14), "briar", detail=1, jitter=0.18, seed=52)
    head.ball(0.15, (0.12, 0.08, 1.28), "leaf_dark", detail=1, jitter=0.18, seed=53)
    for x in (-0.09, 0.09):
        head.box((0.07, 0.03, 0.05), (x, -0.225, 1.15), "ember", rot=(0, x * 250, 0))
    for x, z, lean in ((-0.2, 1.3, -40), (0.22, 1.25, 45), (0.0, 1.4, 5), (-0.1, 1.38, -15)):
        head.cyl(0.035, 0.24, (x, 0, z), "thorn", sides=4, top=0.0, rot=(0, lean, 0))

    parts = [root, torso, head]
    for side, sx in (("l", 1), ("r", -1)):
        x = sx * 0.2
        arm = Part("arm_" + side, (x, 0, 0.92), torso)
        arm.cyl(0.035, 0.36, (x + sx * 0.05, 0, 0.76), "thorn", sides=5, top=0.05, rot=(0, sx * 16, 0))
        arm.cyl(0.03, 0.36, (x + sx * 0.1, -0.03, 0.44), "thorn", sides=5, top=0.035)
        for dx in (-0.045, 0.0, 0.045):
            arm.cyl(0.02, 0.16, (x + sx * 0.1 + dx, -0.05, 0.2), "bone", sides=4, top=0.0, rot=(170, dx * 300, 0))
        parts.append(arm)

        x = sx * 0.1
        leg = Part("leg_" + side, (x, 0, 0.42), root)
        leg.cyl(0.1, 0.44, (x + sx * 0.03, 0, 0.24), "thorn", sides=5, top=0.06, rot=(0, sx * -8, 0))
        leg.box((0.16, 0.26, 0.07), (x + sx * 0.05, -0.04, 0.035), "thorn", bevel=0.02)
        parts.append(leg)
    return parts


@model("thornback", "character")
def thornback():
    """Old Thornback, the boss: a boar half as big again as a wolf, with a ridge of thorns
    down its back and great tusks."""
    root = Part("thornback")
    body = Part("body", (0, 0, 0.7), root)
    body.box((0.62, 0.62, 1.5), (0, 0.08, 0.78), "thorn", rot=(90, 0, 0), taper=1.35, bevel=0.09)
    body.box((0.5, 0.9, 0.16), (0, -0.1, 1.2), "briar", bevel=0.05)
    body.ball(0.22, (0.2, 0.4, 1.08), "briar", detail=1, jitter=0.15, seed=61, scale=(1, 1.3, 0.6))
    for y, height, lean in ((-0.55, 0.42, 18), (-0.3, 0.52, 8), (-0.02, 0.5, -4), (0.26, 0.42, -14), (0.52, 0.32, -24), (0.74, 0.22, -34)):
        body.cyl(0.085, height, (0, y, 1.28 + height / 2.0), "bone", sides=5, top=0.0, rot=(lean, 0, 0))
    for y, x in ((-0.4, 0.2), (-0.1, 0.24), (0.2, 0.2), (0.48, 0.16)):
        for sign in (1, -1):
            body.cyl(0.05, 0.26, (x * sign, y, 1.28), "bone", sides=4, top=0.0, rot=(0, 38 * sign, 0))

    head = Part("head", (0, -0.7, 0.8), body)
    head.box((0.56, 0.5, 0.54), (0, -0.92, 0.78), "thorn", bevel=0.09)
    head.box((0.32, 0.26, 0.36), (0, -1.25, 0.66), "leather_dark", rot=(90, 0, 0), taper=0.8, bevel=0.04)
    head.box((0.24, 0.05, 0.16), (0, -1.44, 0.66), "skin")
    for sign in (1, -1):
        head.cyl(0.06, 0.3, (0.2 * sign, -1.24, 0.66), "bone", sides=5, top=0.035, rot=(0, 62 * sign, 0))
        head.cyl(0.045, 0.3, (0.37 * sign, -1.26, 0.84), "bone", sides=5, top=0.0, rot=(12, 12 * sign, 0))
        head.box((0.07, 0.03, 0.06), (0.16 * sign, -1.175, 0.9), "ember")
        head.box((0.14, 0.05, 0.05), (0.16 * sign, -1.18, 0.96), "thorn", rot=(0, 20 * sign, 0))
        head.prism([(0.0, 0.0), (0.2 * sign, 0.12), (0.06 * sign, 0.2)], 0.05, (0.24 * sign, -0.74, 1.0), "leather_dark")

    parts = [root, body, head]
    for name, x, y in (("leg_fl", 0.26, -0.5), ("leg_fr", -0.26, -0.5), ("leg_bl", 0.2, 0.62), ("leg_br", -0.2, 0.62)):
        leg = Part(name, (x, y, 0.6), root)
        leg.cyl(0.085, 0.56, (x, y, 0.33), "thorn", sides=6, top=0.14)
        leg.box((0.2, 0.24, 0.1), (x, y - 0.02, 0.05), "black", bevel=0.03)
        parts.append(leg)

    tail = Part("tail", (0, 0.82, 0.86), body)
    tail.cyl(0.04, 0.3, (0, 0.9, 0.74), "thorn", sides=5, top=0.02, rot=(-150, 0, 0))
    tail.ball(0.06, (0, 0.98, 0.6), "briar", detail=1, jitter=0.2, seed=62)
    parts.append(tail)
    return parts


# --- reward -----------------------------------------------------------------

@model("briarheart_charm", "armour", item="Briarheart Charm")
def briarheart_charm():
    """A wooden heart bound in thorns, with one living leaf. Worn as a pendant."""
    part = Part("briarheart_charm")
    part.prism([(0.0, -0.13), (0.13, 0.02), (0.11, 0.1), (0.05, 0.12), (0.0, 0.07), (-0.05, 0.12), (-0.11, 0.1), (-0.13, 0.02)], 0.05, (0, 0, 0), "thorn")
    part.prism([(0.0, -0.07), (0.07, 0.02), (0.04, 0.07), (0.0, 0.03), (-0.04, 0.07), (-0.07, 0.02)], 0.07, (0, 0, 0), "cloth_red")
    for x, z, lean in ((0.14, 0.0, -70), (-0.14, 0.0, 70), (0.1, 0.13, -30), (-0.1, 0.13, 30), (0.07, -0.1, -130), (-0.07, -0.1, 130)):
        part.cyl(0.02, 0.09, (x, 0, z), "bone", sides=4, top=0.0, rot=(0, -lean, 0))
    part.prism([(0.0, 0.0), (0.07, 0.05), (0.02, 0.1)], 0.02, (0.02, -0.03, 0.1), "leaf_light")
    part.box((0.03, 0.03, 0.05), (0, 0, 0.15), "leather_dark")
    return [part]


# --- props ------------------------------------------------------------------

@model("briar_thorn", "prop")
def briar_thorn():
    part = Part("briar_thorn")
    part.cyl(0.17, 1.3, (0, 0, 0.68), "thorn", sides=5, top=0.03, rot=(0, 10, 0))
    part.cyl(0.12, 0.9, (-0.26, 0.1, 0.49), "thorn", sides=5, top=0.02, rot=(8, -22, 0))
    part.cyl(0.1, 0.7, (0.22, -0.16, 0.4), "thorn", sides=5, top=0.02, rot=(-14, 26, 0))
    for x, z, lean in ((0.14, 0.75, 65), (-0.02, 0.5, -70), (0.2, 1.0, 50), (-0.36, 0.6, -60)):
        part.cyl(0.035, 0.22, (x, 0.02, z), "bone", sides=4, top=0.0, rot=(0, lean, 0))
    part.ball(0.2, (0, 0, 0.1), "briar", detail=1, jitter=0.2, seed=71, scale=(1.5, 1.3, 0.7), floor=0.0)
    return [part]


@model("briar_bush", "prop")
def briar_bush():
    part = Part("briar_bush")
    part.ball(0.48, (0, 0, 0.26), "briar", scale=(1.3, 1, 0.8), jitter=0.16, seed=72, floor=0.0)
    part.ball(0.32, (0.42, 0.14, 0.2), "leaf_dark", jitter=0.16, seed=73, floor=0.0)
    part.ball(0.28, (-0.4, -0.12, 0.18), "leaf_dark", jitter=0.16, seed=74, floor=0.0)
    for x, y, z, lean in ((0.2, -0.1, 0.55, 30), (-0.25, 0.1, 0.5, -35), (0.5, 0.2, 0.42, 60), (-0.5, -0.1, 0.36, -65), (0.0, 0.2, 0.62, 5)):
        part.cyl(0.035, 0.3, (x, y, z), "thorn", sides=4, top=0.0, rot=(0, lean, 0))
    for x, y in ((0.3, -0.3), (-0.2, -0.36), (0.0, -0.42)):
        part.ball(0.05, (x, y, 0.3), "cloth_red", detail=1)
    return [part]


@model("dead_tree", "prop")
def dead_tree():
    part = Part("dead_tree")
    part.cyl(0.32, 0.3, (0, 0, 0.15), "thorn", sides=7, top=0.2)
    part.cyl(0.2, 1.3, (0.05, 0, 0.9), "thorn", sides=7, top=0.12, rot=(0, 6, 0))
    part.cyl(0.11, 1.0, (0.3, 0.0, 1.95), "thorn", sides=5, top=0.03, rot=(0, 28, 0))
    part.cyl(0.1, 0.9, (-0.28, 0.1, 1.8), "thorn", sides=5, top=0.03, rot=(-10, -42, 0))
    part.cyl(0.06, 0.6, (0.72, 0.0, 2.1), "thorn", sides=4, top=0.0, rot=(0, 75, 0))
    part.cyl(0.05, 0.5, (-0.68, 0.14, 2.3), "thorn", sides=4, top=0.0, rot=(-10, -10, 0))
    part.cyl(0.05, 0.5, (0.36, 0.2, 1.3), "thorn", sides=4, top=0.0, rot=(-60, 30, 0))
    part.ball(0.2, (-0.5, 0.1, 2.0), "briar", detail=1, jitter=0.2, seed=75, scale=(1.4, 1, 0.5))
    part.ball(0.16, (0.5, 0.0, 2.3), "briar", detail=1, jitter=0.2, seed=76, scale=(1.4, 1, 0.5))
    return [part]


@model("bog_pool", "prop")
def bog_pool():
    part = Part("bog_pool")
    part.cyl(1.1, 0.03, (0, 0, 0.015), "bog_water", sides=9, scale=(1.2, 0.85))
    part.cyl(0.24, 0.02, (0.4, -0.2, 0.04), "leaf", sides=7)
    part.cyl(0.16, 0.02, (-0.5, 0.25, 0.04), "leaf_light", sides=7)
    for x, y, height in ((-0.95, -0.3, 0.8), (-0.8, -0.5, 0.6), (-1.05, -0.1, 0.65), (0.95, 0.45, 0.75), (1.1, 0.25, 0.55)):
        part.cyl(0.02, height, (x, y, height / 2.0), "leaf_dark", sides=4)
        part.cyl(0.045, 0.16, (x, y, height), "thorn", sides=5)
    return [part]


@model("thornback_hollow", "prop")
def thornback_hollow():
    """Old Thornback's lair: a root-bound mound with a dark mouth under arching thorns."""
    part = Part("thornback_hollow")
    part.ball(1.3, (0, 0.35, 0.4), "thorn", scale=(1.5, 1.2, 0.9), jitter=0.14, seed=77, floor=0.0)
    part.ball(0.7, (0.3, 0.3, 1.25), "briar", scale=(1.6, 1.3, 0.5), jitter=0.16, seed=78)
    part.prism([(-0.7, 0.0), (0.7, 0.0), (0.6, 0.7), (0.1, 1.05), (-0.5, 0.72)], 0.5, (0, -1.0, 0.0), "black")
    for x, lean, height in ((-0.95, 24, 1.7), (0.95, -26, 1.6), (-0.45, 40, 1.2), (0.5, -44, 1.1)):
        part.cyl(0.16, height, (x, -1.05, height / 2.0 + 0.1), "thorn", sides=5, top=0.0, rot=(0, lean, 0))
    for x, z, lean in ((-1.2, 0.9, -60), (1.2, 0.85, 60), (-0.75, 1.35, -30), (0.8, 1.3, 30)):
        part.cyl(0.05, 0.3, (x, -1.05, z), "bone", sides=4, top=0.0, rot=(0, lean, 0))
    return [part]
