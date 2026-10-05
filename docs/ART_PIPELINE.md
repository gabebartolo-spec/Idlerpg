# Art pipeline

Every 3D model in the game is written as a short Python script and built by Blender, headless.
One command turns those scripts into game-ready models, gear icons and review sheets.

```
tools/art/models/*.py  ->  validate  ->  assets/models/**.glb     ->  ArtCatalog  ->  game
   (Blender Python)        budgets       assets/icons/*.png           (manifest)
                                         art/review/*.png (for people)
```

```sh
scripts/build_art.sh                     # everything
scripts/build_art.sh --only iron_sword   # just these models, manifest untouched
```

Needs Blender (built with 5.2). Set `BLENDER_BIN` if it is not on the path or in the default
install folder. The outputs are committed, so the game, the tests and CI do not need Blender.

## What a build does

1. Runs every builder registered in `tools/art/models/`.
2. Fails the build if a model breaks a rule (below) or a gear catalogue item has no model.
3. Exports each model to `assets/models/<category>s/<id>.glb`.
4. Renders a 256 px transparent icon for every gear item to `assets/icons/<id>.png`.
5. Renders labelled review sheets, one per category, to `art/review/`.
6. Writes `src/data/art_manifest.gd` and deletes outputs whose model no longer exists.

## Rules the build enforces

| Category | Triangles | Largest dimension | Materials | Also |
|---|---|---|---|---|
| weapon | 250 | 1.8 m | 5 | origin on the grip |
| armour | 250 | 1.0 m | 5 | |
| prop | 500 | 5.0 m | 6 | sits on the ground |
| character | 800 | 2.0 m | 8 | sits on the ground |
| backdrop | 300 | 45 m | 3 | sits on the ground |

Budgets live in `tools/art/models/__init__.py`. Colours come only from `tools/art/palette.py`;
change a colour there and every model that uses it changes on the next build.

## Conventions

- Blender axes: Z up, model faces -Y, a character's right hand is at -X. Sizes are metres; the
  hero is about 1.7 m tall.
- Weapons: origin at the grip, business end towards +Z, flat in the XZ plane.
- Armour is sized for the hero and modelled around the attach point it is worn at: head pieces
  around the head centre, chest pieces around the torso centre, off-hand around the grip.
- Legs, hands and feet are modelled as one symmetric piece for a single limb; the game shows it
  on both sides. Accessories hang as a pendant on the chest.
- Props: origin on the ground at the footprint centre.
- Characters are split into parts that pivot at the joints, with no skinning. The game animates
  them by swinging parts (`src/view/character_visual.gd`): `torso, head, arm_l, arm_r, leg_l,
  leg_r` for humanoids and `body, head, leg_fl, leg_fr, leg_bl, leg_br, tail` for quadrupeds.
- Gear is shown by parenting its model to an attach point on the character: `attach_hand_r`
  (weapon), `attach_hand_l` (off-hand), `attach_head`, `attach_chest`, `attach_accessory`, and
  left/right pairs of `attach_leg`, `attach_glove` and `attach_foot`.

## Adding a model

Add a builder to the right file in `tools/art/models/` and rebuild:

```python
@model("bronze_axe", "weapon", item="Bronze Axe")   # item: the gear catalogue name, if any
def bronze_axe():
    part = Part("bronze_axe")
    part.cyl(0.03, 0.7, (0, 0, 0.2), "wood", sides=6)
    part.prism([(0.0, 0.4), (0.25, 0.3), (0.25, 0.6), (0.0, 0.52)], 0.04, (0, 0, 0), "bronze")
    return [part]
```

`Part` offers `box`, `cyl` (cylinders and cones), `ball` (icospheres, rocks) and `prism`
(extruded outlines); see `tools/art/lowpoly.py`. A gear item added to
`src/data/gear_catalog.gd` without a model fails both the art build and `tests/test_art.gd`.

## In the game

`src/data/art_catalog.gd` is the only thing game code talks to:

```gdscript
ArtCatalogScript.instantiate("tree_oak")        # Node3D, or null
ArtCatalogScript.item_model("Iron Sword")       # "iron_sword"
ArtCatalogScript.item_icon("Iron Sword")        # Texture2D for UI
```

## Review

- `art/review/<category>s.png`: every model with its name and triangle count.
- `godot --path . -s res://tools/art/capture.gd` (not headless) runs the real main scene and
  saves `art/review/ingame_*.png`: walking, and fighting each enemy in different gear. It moves
  the player's save aside while it runs and puts it back afterwards.
- `tests/test_art.gd` (part of `scripts/run_tests.sh`) checks every manifest model loads with
  its parts, every gear item has a model and icon, and gear attaches to the hero.
