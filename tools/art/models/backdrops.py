"""Backdrop scenery seen far beyond the play area. Origin on the ground at the centre."""

from lowpoly import Part

from . import model


@model("hill_round", "backdrop")
def hill_round():
    part = Part("hill_round")
    part.ball(12.0, (0, 0, 0.5), "grass", scale=(1.3, 1.1, 0.5), detail=2, jitter=0.06, seed=31, floor=0.0)
    part.ball(7.0, (11.0, 3.0, 0.0), "grass_dark", scale=(1.2, 1.0, 0.5), detail=1, jitter=0.08, seed=32, floor=0.0)
    return [part]


@model("hill_ridge", "backdrop")
def hill_ridge():
    part = Part("hill_ridge")
    part.ball(9.0, (-8.0, 0, 0.0), "grass_dark", scale=(1.3, 1.0, 0.75), detail=1, jitter=0.1, seed=33, floor=0.0)
    part.ball(11.0, (4.0, 1.0, 0.0), "grass", scale=(1.2, 0.9, 0.9), detail=2, jitter=0.07, seed=34, floor=0.0)
    part.ball(6.0, (14.0, -1.0, 0.0), "stone_dark", scale=(1.0, 0.9, 1.3), detail=1, jitter=0.12, seed=35, floor=0.0)
    return [part]
