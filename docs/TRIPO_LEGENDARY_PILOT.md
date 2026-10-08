# P0 #1: Tripo legendary-gear vision pilot

**Owner directive (9 October 2026):** Tripo modelling is the **highest-priority immediate item in the entire Idle RPG roadmap**. The owner wants to *see* the game's visual potential in real legendary equipment, not read another abstract art plan. Existing Tripo access/investment should be used first, subject to available plan credits. This is a visual **proof-of-quality pilot**, not approval for a full asset remake.

**Issue:** [Tripo legendary vision pilot #47](https://github.com/gabebartolo-spec/Idlerpg/issues/47)  
**Primary references:** [ART_STYLE_GUIDE.md](ART_STYLE_GUIDE.md), [ART_PIPELINE.md](ART_PIPELINE.md), [THREE_PILLARS.md](THREE_PILLARS.md). 
**Current art target:** original **World of Warcraft-inspired painterly heroic fantasy**, implemented in mobile-friendly low-poly models. The **same-hand rule** is compulsory across equipment and regions. Do not reproduce Blizzard characters, armour or recognisable weapons.

## First delivery: show three real models, equipped in our game

Only three **existing** named items from `src/data/gear_catalog.gd`. Do not create a large new collection until the owner has seen and judged these.

| Item | Slot | Brief for Tripo concept/model | In-world proof |
|---|---|---|---|
| **Crownblade** | Weapon | Dramatic asymmetric but balanced heroic longsword; broad faceted silver-steel blade, deep charcoal fuller, pale gold guard and small amber heart-glow; unique tapered blade motif, *not* a known Warcraft weapon. Profile legible on a small phone. | Show idle, running, one attack and preview; clear hand/grip alignment |
| **Starforged Helm** | Head | Original angular domed helm with deep blue iron, worn bronze star-shaped inset and two restrained fin ridges; large silhouette, visible brow/face read, no giant high-frequency decoration. | Correct head attachment, face/helmet visibility in normal follow camera |
| **Titanheart Plate** | Chest | Bold sculpted heavy breastplate with a chest-centred ember/stone heart emblem, chunky warm-metal shoulder masses and distinct matte dark-metal panels. Avoid preexisting Warcraft armour motifs. | Compatible with hero's head, hands, legs, weapons and animation with no clipping |

**Coherence:** All three share consistent bevel language, painterly color grouping, broad-to-fine detail density, rough/matte finish, silhouette exaggeration, subdued emissive accents and scale. They should be exciting *together* even though each has its own theme. A 'legendary' means a memorable form and presentation, not merely more glow or polygon count.

## Fastest workable asset workflow

1. **Start from approved original references.** Use a compact original style/anchor sheet (existing hero, starting weapon, basic armour, the selected village/forest environment). If these are inconsistent, make a temporary pilot reference that clearly declares proposed improvements; final master sheet still requires owner's approval. Keep one stable art prompt/moodboard for all three assets. Tripo image-to-3D is preferred when coherent source art is available; text-to-3D can be tested but must be reviewed for drift.
2. **Generate in Tripo.** Choose the cleanest output per item rather than mass generating dozens of concepts. Save the original generated source, settings, relevant licensing provenance and expected editable/export representation. Do not claim Tripo's output is automatically optimised or legally cleared.
3. **Clean in Blender.** Apply consistent scale/orientation, pivot/grip/attachments, sensible topology and normals, UVs/materials, baked/minimised textures and optional restrained emissive surfaces. Preserve an editable source. Rigging is unnecessary for these *modular gear* models; they attach to existing moving hero parts.
4. **Add a reproducible imported-GLB branch** to the current build/import process, without breaking the existing `tools/art/models/*.py` procedural path. Add manifest/icon generation and category validation for imported models, with reviewed budget appropriate to the actual Android effect. Do not apply the current extremely low 300/400 triangle procedural limits blindly to hero equipment.
5. **Render in the real Godot game.** Equip the three pieces on the actual adventurer; verify animation, size, collision/occlusion, shader/material rendering, preview and icon match. Use a controlled developer/demo loadout without changing permanent saves or any normal player's gacha inventory/odds. Do not accidentally include developer infinite pulls in a production build.
6. **Show the owner the vision.** Deliver a single phone-scale side-by-side before/after comparison of old vs Tripo equipment, a clear neutral turntable/rotation of the three pieces, and a true portrait gameplay screenshot or short capture with all three equipped. This is the first required milestone. If the prototype looks off-model, revise it, not the approved game's style.
7. **Verify.** Desktop import/render/test pass, then real Android portrait installation and performance/readability if build available. Record texture size, material/draw-call count, triangle count, memory/frame characteristics and known device limitations. Existing procedural art remains a rollback/fallback until owner sign-off.

## Stable Tripo prompting constraints

Use the following **shared** production style text for each concept, plus that item's distinctive silhouette, name and palette:

> Original stylized 3D heroic fantasy game equipment. Strong readable silhouette and exaggerated confident proportions. Sculpted low-poly forms with considered bevels and broad asymmetrical details. Harmonized painterly hand-painted-looking colour blocks, matte/rough surfaces, restrained metallic/magical accents. Professional mobile game art with a consistent shared fantasy world style. Simple coherent mesh and UVs, neutral background, full product visible; no text, logos or extra objects. Original design—not from an existing franchise, no photorealism, no anime gloss, no Minecraft voxels.

The phrase 'World of Warcraft-inspired' describes visual principles for internal reference and style evaluation; avoid prompting Tripo to copy a specific Warcraft item or Blizzard composition.

## Scope, permissions and gates

- **Highest priority for the next immediately reviewable visual slice, ahead of routine feature expansion and large research work.** Keep the pilot short and bounded; it's a test, not a multi-month asset-system rewrite. After a visible owner-approved result, proceed with the ongoing **P0 progression/economy overhaul** (#45) and other dependencies.
- Use paid Tripo credits already held by the owner where available; **no new paid subscription, extra credits or separate modelling service without explicit owner approval.** If a required login/credit grant is unavailable, request only the needed connection/action, report the blocker and proceed with non-chargeable setup.
- Protect one persistent adventurer, current save, existing gear catalogue, body attachments, watched/offline simulation parity and Android portrait readability.
- Unrelated art content, entire-character rig replacement, wholesale procedural art deletion, new graphics engine, item-stat rebalancing, commercial gacha changes and broader world redress are **out of scope**.
- **Definition of done:** three imported Tripo-derived GLBs, demonstrably worn by the existing hero in Godot, consistent same-hand style and clear owner-facing comparisons. Existing functional tests and render checks pass, with Android device status reported truthfully. **Do not claim model generation or in-game integration has occurred solely because this brief is committed.**

## Post-pilot decision

Owner chooses: (1) approve Tripo + Blender for primary *hero/monster/important equipment/buildings* art, (2) limit Tripo to particular asset categories or (3) return to procedural assets if results don't justify cleanup or costs. Preserve procedural terrain and reusable small props unless proven beneficial to change.
