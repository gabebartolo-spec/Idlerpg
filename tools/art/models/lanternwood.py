"""Original Lanternwood silhouettes: cream moth wings, root shields and amber lamps.

All geometry is authored here in the game's shared palette. No external models.
"""
from lowpoly import Part
from . import model


def lamp(part, x, y, z, size=1.0):
    part.box((.22*size, .20*size, .28*size), (x, y, z), "window", bevel=.025*size)
    for dx in (-.13, .13):
        part.box((.035*size, .25*size, .34*size), (x+dx*size, y, z), "bronze")
    part.cyl(.19*size, .10*size, (x, y, z+.22*size), "bronze", sides=5, top=.04*size)
    part.box((.33*size, .28*size, .045*size), (x, y, z-.18*size), "bronze")


@model("lantern_moth", "character")
def lantern_moth():
    root = Part("lantern_moth")
    body = Part("body", (0, 0, .8), root)
    body.ball(.25, (0, 0, .8), "wood_dark", detail=1, scale=(.65, .7, 1.9))
    body.cyl(.10, .15, (0, 0, .075), "wood_dark", sides=5)
    head = Part("head", (0, -.1, 1.18), body)
    head.ball(.21, (0, -.12, 1.17), "cloth_cream", detail=1)
    for x in (-.1, .1):
        head.ball(.055, (x, -.27, 1.2), "window", detail=1)
        head.cyl(.025, .3, (x*1.2, -.08, 1.43), "wood_dark", sides=4, top=.01, rot=(0, x*180, 0))
    parts = [root, body, head]
    for sign, side in ((-1, "l"), (1, "r")):
        wing = Part("wing_"+side, (sign*.1, 0, .95), root)
        shape = [(.1, .8), (.48, .52), (.98, .62), (1.03, 1.03), (.72, 1.5), (.3, 1.37)]
        wing.prism([(x*sign, z) for x,z in shape], .065, (0, 0, 0), "cloth_cream")
        wing.prism([(x*sign, z) for x,z in ((.25,.85),(.78,.74),(.79,1.08),(.55,1.27))], .075, (0, -.02, 0), "bronze")
        wing.ball(.12, (sign*.67, -.06, 1.03), "window", detail=1, scale=(1,.35,1))
        parts.append(wing)
    return parts


@model("root_keeper", "character")
def root_keeper():
    root = Part("root_keeper")
    body = Part("body", (0, 0, .95), root)
    body.cyl(.40, .95, (0, 0, 1.02), "wood_dark", sides=7, top=.29)
    body.ball(.38, (.15, .02, 1.43), "leaf_dark", detail=1, scale=(1.15,1,.55))
    head = Part("head", (0, -.05, 1.66), body)
    head.box((.44, .35, .40), (0, -.06, 1.72), "wood_light", bevel=.06)
    for x in (-.12, .12):
        head.box((.07, .035, .07), (x, -.26, 1.76), "window")
        head.cyl(.05, .4, (x*1.8, 0, 2.0), "wood_dark", sides=5, top=.02, rot=(0,x*180,0))
    parts = [root, body, head]
    for sign, side in ((-1,"l"),(1,"r")):
        arm = Part("arm_"+side, (sign*.36, 0, 1.36), body)
        arm.cyl(.12, .65, (sign*.47, -.04, 1.0), "wood", sides=6, top=.17, rot=(0,sign*12,0))
        if side == "l":
            arm.prism([(-.72,.55),(-.28,.55),(-.16,.95),(-.30,1.48),(-.75,1.44),(-.87,.95)], .13, (0,-.3,0), "wood_light")
            arm.cyl(.065,.60,(-.52,-.39,1.03),"leaf_dark",sides=5,rot=(0,15,0))
        else:
            arm.cyl(.065, .95, (.53,-.1,.68), "wood_dark", sides=5, top=.045)
            arm.ball(.18,(.53,-.1,1.18),"stone",detail=1,scale=(1.4,1,1))
        parts.append(arm)
        leg = Part("leg_"+side, (sign*.18,0,.55), root)
        leg.cyl(.13,.50,(sign*.18,0,.3),"wood_dark",sides=6,top=.17)
        leg.box((.30,.39,.10),(sign*.18,-.07,.05),"wood",bevel=.025)
        parts.append(leg)
    return parts


@model("lantern_post", "prop")
def lantern_post():
    part = Part("lantern_post")
    part.cyl(.13,.22,(0,0,.11),"stone",sides=6,top=.10)
    part.cyl(.07,1.8,(0,0,1.02),"wood_dark",sides=6,top=.05)
    part.box((.67,.10,.10),(.23,0,1.87),"wood",rot=(0,-8,0))
    part.cyl(.02,.16,(.48,0,1.72),"bronze",sides=4)
    lamp(part,.48,0,1.45)
    return [part]


@model("mooncap_cluster", "prop")
def mooncap_cluster():
    part = Part("mooncap_cluster")
    for x,y,height,radius in ((0,0,.46,.38),(.42,.12,.26,.22),(-.3,-.22,.19,.18)):
        part.cyl(.06,height,(x,y,height/2),"cloth_cream",sides=5,top=.04)
        part.ball(radius,(x,y,height),"cloth_blue",detail=1,scale=(1,1,.4))
        part.cyl(radius*.65,.025,(x,y,height-.09),"moon",sides=7)
    return [part]


@model("lantern_arch", "prop")
def lantern_arch():
    part = Part("lantern_arch")
    for sign in (-1,1):
        part.cyl(.30,1.7,(sign*1.25,0,.91),"wood_dark",sides=6,top=.20,rot=(0,-sign*12,0))
        part.cyl(.22,1.4,(sign*.7,0,2.02),"wood",sides=6,top=.15,rot=(0,-sign*42,0))
        part.ball(.65,(sign*1.0,.15,2.1),"leaf_dark",detail=1,scale=(1.2,.85,.55))
        lamp(part,sign*.87,-.30,1.40,.8)
        part.ball(.4,(sign*1.3,0,.24),"briar",detail=1,scale=(1.3,1,.6),floor=0)
    part.cyl(.2,.8,(0,0,2.5),"wood_dark",sides=6,rot=(0,90,0))
    return [part]


@model("keeper_shrine", "prop")
def keeper_shrine():
    part = Part("keeper_shrine")
    part.cyl(1.0,.15,(0,0,.075),"stone_dark",sides=8,top=.92)
    part.cyl(.65,.17,(0,0,.23),"stone",sides=8,top=.58)
    part.cyl(.24,1.45,(0,.23,1.03),"wood_dark",sides=6,top=.12)
    for sign in (-1,1):
        part.cyl(.11,.8,(sign*.28,.23,1.55),"wood",sides=5,top=.025,rot=(0,sign*48,0))
        part.ball(.30,(sign*.5,.23,1.82),"leaf_dark",detail=1,scale=(1.3,1,.45))
        lamp(part,sign*.65,-.22,.75,.85)
    part.prism([(-.25,.65),(.25,.65),(.30,.90),(0,1.23),(-.30,.90)],.10,(0,-.14,0),"cloth_cream")
    part.ball(.09,(0,-.21,.94),"window",detail=1)
    return [part]


@model("lantern_crook", "weapon", item="Lantern Crook")
def lantern_crook():
    part = Part("lantern_crook")
    part.cyl(.04,1.30,(0,0,.30),"wood_dark",sides=6,top=.035)
    part.cyl(.06,.24,(0,0,0),"leather",sides=6)
    part.cyl(.045,.4,(-.1,0,.93),"wood",sides=6,rot=(0,-50,0))
    part.cyl(.04,.24,(-.28,0,1.03),"wood",sides=6,rot=(0,-115,0))
    lamp(part,-.34,0,.80,1.1)
    part.ball(.06,(0,0,-.40),"bronze",detail=1)
    return [part]


@model("keeper_crown", "armour", item="Keeper Crown")
def keeper_crown():
    part = Part("keeper_crown")
    part.box((.39,.39,.12),(0,.01,.17),"wood_dark",bevel=.035)
    part.box((.39,.08,.28),(0,.17,-.02),"wood",bevel=.02)
    for sign in (-1,1):
        part.box((.06,.30,.20),(sign*.175,.02,.02),"wood_dark",bevel=.015)
        part.cyl(.04,.27,(sign*.20,.04,.33),"wood",sides=5,top=.02,rot=(0,sign*35,0))
        part.cyl(.025,.18,(sign*.30,.04,.46),"wood",sides=4,top=.0,rot=(0,sign*70,0))
        part.ball(.08,(sign*.20,-.03,.3),"leaf_light",detail=1,scale=(1.3,.7,.5))
    part.prism([(-.06,.14),(.06,.14),(.05,.25),(0,.29),(-.05,.25)],.04,(0,-.20,0),"window")
    return [part]


@model("warden_lantern", "weapon", item="Warden Lantern")
def warden_lantern():
    """A hand-carried amber cage with root antlers; raid appearance only."""
    part = Part("warden_lantern")
    part.cyl(.045,.25,(0,0,0),"leather",sides=6)
    part.cyl(.04,.40,(-.13,0,-.12),"bronze",sides=6,rot=(0,-55,0))
    lamp(part,-.28,0,-.48,1.45)
    for sign in (-1,1):
        part.cyl(.028,.34,(-.28+sign*.23,0,-.48),"wood_dark",sides=5,top=.014,rot=(0,sign*24,0))
        part.ball(.08,(-.28+sign*.27,0,-.30),"leaf_light",detail=1,scale=(1.2,.6,.45))
    part.prism([(-.06,-.06),(.06,-.06),(.07,.06),(0,.12),(-.07,.06)],.03,(-.28,-.16,-.48),"cloth_cream")
    return [part]
