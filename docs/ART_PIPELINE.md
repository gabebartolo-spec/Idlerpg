# Art pipeline

Every 3D model in the game is written as a short Python script and built by Blender, headless.
One command turns those scripts into game-ready models, gear icons and review sheets.

```
tools/art/models/*.py  ->  validate  ->  assets/models/**.glb     ->  ArtCatalog  ->  game
   (Blender Python)        budgets       assets/icons/*.png           (manifest)
                                         art/review/*.png (for people)
```

```sh
scripts/build_art.sh                     # whatever changed since the last build
scripts/build_art.sh --only iron_sword   # these models, even if unchanged
scripts/build_art.sh --force             # everything
```

Needs Blender (built with 5.2). Set `BLENDER_BIN` if it is not on the path or in the default
install folder. The outputs are committed, so the game, the tests and CI do not need Blender.

## Only changed models are rebuilt

Renders are not byte-identical from run to run, so the build never re-exports or re-renders
a model whose inputs have not changed. Each model gets a fingerprint of its shape, colours,
part layout and render settings; the fingerprints are committed in `art/build_state.json`.
A model is rebuilt when its fingerprint changes or one of its output files is missing, and
a review sheet is redrawn only when one of its models was rebuilt.

Editing `tools/art/build.py` or `tools/art/lowpoly.py` changes every fingerprint, so the
next build redoes everything. Commit `art/build_state.json` with the outputs it describes.
`--adopt` records the outputs on disk as current without rebuilding; it exists for setting
this up on outputs you already trust, not for everyday use.

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
| weapon | 300 | 2.0 m | 3 | origin on the grip |
| armour | 400 | 1.0 m | 3 | |
| prop | 500 | 5.0 m | 3 | sits on the ground |
| character | 1500 | 2.6 m | 3 | sits on the ground |
| backdrop | 300 | 45 m | 3 | sits on the ground |

Budgets live in `tools/art/models/__init__.py`. Colours come only from `tools/art/palette.py`;
change a colour there and every model that uses it changes on the next build.

Colours are stored per face, so a model needs one matte material however many colours it
uses. Only the glow colours (`GLOWS` in the palette) get a material of their own. In the game
`ArtCatalog` swaps every model's matte surface for one shared material.

The look follows `docs/ART_STYLE_GUIDE.md`: a hero about 5.5 heads tall, tapered and
bevelled forms, oversized weapons, an enemy silhouette rule per family, and buildings with
steep roofs and thick beams. New models should be checked against it.

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

## Companions

Each entry in `src/data/companion_catalog.gd` needs a model registered with
`@model("pack_rat", "character", companion="Pack Rat")` in `tools/art/models/companions.py`.
The build fails if a companion has no model, and renders an icon for each one. People share
one body (`_person`) and differ by headgear, what they carry and a colour family; winged
companions name their wings `wing_l` and `wing_r` and the game flaps them.

## Zones

A zone keeps its enemies, boss, reward and props together in one file, as
`tools/art/models/briarfen.py` does, with a small prop vocabulary and its own colours added
to the palette. An enemy's model id must match the simulation's enemy kind (`briarling`,
`thornback`), because the game loads the enemy model by that name.

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

`Part` offers `box` (with `taper` and `bevel`), `cyl` (cylinders and cones), `ball`
(icospheres, rocks) and `prism` (extruded outlines); see `tools/art/lowpoly.py`. A gear item added to
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
