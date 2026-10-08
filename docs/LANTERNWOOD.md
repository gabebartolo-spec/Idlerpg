# Lanternwood playable content slice

Lantern Hollow and Keeper's Rise extend the existing autonomous expeditions with an authored woodland, two original creature silhouettes and two permanent earned appearances. They are local solo content. Real guild membership and multiplayer raids remain committed roadmap work and are not represented by these creatures or by NPC practice allies.

## Progression and rewards

| Trail | Opens after | Duration | First / repeat total gold | Permanent first-clear look |
|---|---|---:|---:|---|
| Gentle Greenway | Immediately | 5 min | 43 / 18 | — |
| Shattered Causeway | Immediately | 5 min | 68 / 28 | — |
| Lantern Hollow | Gentle Greenway clear | 15 min | 92 / 37 | Lantern Crook |
| Keeper's Rise | Hollow and Causeway clears | 30 min | 142 / 52 | Keeper Crown |

Each route has five autonomous encounters. Clock duration comes from the selected route, including after a reload. Builds freeze at departure; no live input or attendance is required. An expedition finishes before normal adventure resumes; it never repeats itself automatically. The displayed total includes cache gold. Found cache gold stays on failure/abort; final gold and appearance ownership require a successful clear. A later clear can restore missing earned ownership, without adding a second provenance record or changing the player's equipped appearance.

Hollow: lantern gate → moths → mooncap clearing → lamplighter cache → root keeper. Rise: moths → briar tunnel → mooncap clearing → lamplighter cache → elder keeper.

Moths deal `max(6, 24 − attack)` damage. Keeper damage is `max(14, 38 − attack)`; the elder's is `max(22, 66 − attack)`. Thornward halves keeper and briar-tunnel damage, rounded down. The tunnel deals 16 damage before protection; mooncaps restore up to 8 health; the cache adds 12 gold. One prepared Pond Stew restores 12 when all 12 fit, as on the original routes.

Controlled build examples: naked starting stats (6 attack, 36 health) fail Hollow without protection/preparation. Those stats with Thornward and stew clear it. A 22-attack build clears Hollow without either. Rise fails at 6 attack / 36 health even with both counters, but 8 attack / 42 health with both succeeds; the earned Briarheart Charm alone supplies those entry stats and Thornward. These examples establish attainable roles for ordinary progression, not evidence that balance is fun.

## Art and presentation

Eight new authored low-poly assets use the existing shared palette and matte/emissive pipeline: lantern moth, root keeper, lantern post, mooncap cluster, root arch, keeper shrine, Lantern Crook and Keeper Crown. Sources live in `tools/art/models/lanternwood.py`. Moths have cream fan-shaped wings and amber eyes; keepers have a root shield, wooden limbs and branch crowns. The elder uses the keeper silhouette at a larger scale. No external models or images are used.

`src/view/lantern_hollow.gd` dresses real world waypoints with lanterns, clearings, mushrooms, trees, caches and shrines. Paths use combined geometry per segment rather than many separate discs. Creatures appear as the hero approaches their encounter waypoint; their visible poses convey the encounter, while the existing five-stage controller resolves its outcome. These are expedition encounters, not an additional real-time combat simulation. Hidden creatures stop processing. Reduced motion keeps readable static poses.

Looks use the same hero attachment points in the watch and Wardrobe preview. They have no entries in the combat gear or summon catalogs, and no stat bonuses. The art builder now also reads cosmetic-only item mappings so these assets retain normal validation, matching icons and manifest registration without becoming combat equipment.

Main play screens keep route time, risk, unlock requirement, preparation and reward concise. Authored descriptions and exact math live in Field journal → Field guide → Trails. Four routes use two rows of full-size touch buttons, including Larger text mode. Longer result copy only adds the earned look's name.

## Save compatibility and verification

Save format 19 recognizes the new route IDs and longer clocks; all existing saves migrate with their original route timing and progress. The new content uses existing route-clear and Wardrobe ownership records, with no fabricated past clears. Gold, clear flags, stew consumption and cosmetic ownership settle before any completion event can trigger an atomic save. Older executables refuse newer saves rather than silently dropping this progress.

`tests/test_lanternwood.gd` covers unlock gates, contrasting builds, watched/offline equality, long fractional clocks, reload before settlement, event-time saves, repeat rewards, no stat bonuses, abort retention and actual models/icons. Existing expedition and full UI tests also run, including Larger text. `tools/ui/capture_lanternwood.gd` captures the real main scene only in an isolated project and refuses the ordinary project name to protect the player's save.

Desktop screenshots and automated tests support this slice. Real Android touch, speaker balance, memory/frame cost, suspend/resume and multi-day enjoyment remain open checks. This batch does not establish that the entire region sustains several days of engaging play; encounter variety, repeat pursuits and actual playtests remain next steps.
