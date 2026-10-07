# Adventure preparation — R04–R07

These four slices improve the existing adventure loop. They add no zones, classes, currency, paid slots or manual combat. All four remain **VERIFY** for actual Android interaction; local automated checks do not close the device gates.

## R04: three permanent goals

Open **Adventure → Goals**. The board always presents preparation (equip a weapon), the first Old Thornback victory and a collection pursuit (discover all three Briarfen world items). Track one pursuit; each card shows real progress and a free acquisition/preparation route. Completion delivers 25 existing gold once automatically. This reward amount is a prototype assumption. Tracking does not change drops or require attendance. Finished goals never reset; unequipping, selling and reloading cannot farm rewards. Goals complete offline and become chronicle milestones.

Older saves mark already-satisfied criteria complete without retrospectively granting gold. Permanent discovery records keep the collection pursuit complete even after an item is sold.

## R05: autonomous outing policies

Open **Adventure → Adventure policy**. Choose the policy for the next outing; the current encounter and outing continue under their saved policy. The HUD explains the current outing's destination/reason.

| Policy | Route and tradeoff | Automatic early return |
|---|---|---|
| Safe farming | Repeat Greenway goblins/wolves; no Briarfen items or boss progression | Below 40% HP after an encounter |
| Push progression | Briarfen and growing Old Thornback; higher rewards and risk | Existing boss-loss guard waits for a changed build or level |
| Targeted hunt | Chosen Boss and hunts quarry; Briarhook outings stop after Briarlings, Carapace outings attempt the boss | Below 25% HP after an encounter |

The opening errand remains unchanged. Without a selected hunt, Targeted hunt falls back to Greenway. Existing hunts automatically choose another missing hunt after a drop; that new quarry applies on the next outing. A low-health early return keeps existing loot but grants no unfinished quest reward or completion count. Invalid policy values recover to Push progression.

## R06: three free named builds

Open **Builds**, choose one of three slots, name it and save the current equipment, talents, companion and relic. Saving to an occupied slot replaces that slot. Names are limited to 32 characters.

Preview checks gear ownership and slots, talent points and prerequisites, companion ownership and relic ownership. **Apply complete loadout** changes every validated part together or changes nothing. Missing pieces block it. **Apply available pieces** explicitly retains the current owned piece in a missing slot, or leaves that slot empty; it does not fabricate items or alter the saved template. Invalid talents still block fallback. Applying clamps existing HP to the new maximum and preserves encounter proc usage/counts, so switching cannot heal or reset Last stand/Second wind.

## R07: one relic slot

Open **Relics**, or use the Relics collection's equip action. One active relic contributes its complete catalog effect. Duplicate copies add no power. Switching/unequipping removes the prior effect. No relic auto-equips.

| Relic | Effect |
|---|---|
| Copper Charm | +8 max HP; guaranteed at first boss victory |
| Old Coin | +1 attack |
| Hunter's Knot | +20% travel speed; guaranteed at opening errand completion |
| Lucky Fang | +2 attack |
| Glass Idol | +12 max HP |
| Pilgrim Bell | +20% travel speed |
| Phoenix Ash | +20 max HP |
| Void Compass | +25% travel speed |
| Dragon Eye | +3 attack |
| Worldstone Shard | +4 attack, +8 max HP |

Free Common Hunter's Knot wins the travel niche against Legendary Worldstone Shard. Health changes capacity; equipping never heals immediately. Ordinary quest recovery can fill the new capacity. Existing progressed saves receive earned alternatives based on their quest/boss history. Equipped relic choice participates in boss retry preparation and saved builds.

## Verification and remaining work

Godot 4.7.2 coverage includes once-only goals, offline completion/history, policy outcome differences and parity, early return, invalid recovery, atomic presets, sale/respec/ownership failures, JSON persistence, relic stacking boundaries and actual encounter timing. Synthetic touches verify tracking, policy selection, loadout application/fallback, relic equip/unequip, collection integration and pinned action bounds. The existing full suite remains required.

On Android, record device, OS and exact build SHA. Test all four screens in portrait, long-list swipes in both directions, Back to adventure, preset naming with the keyboard, sold-piece preview/fallback and relic equip/unequip. Suspend/resume during travel and a boss fight, verify selected/current-outing policy and build restore, and confirm a goal cannot pay again. Capture long-return timing and screenshots. R00/R02/R03 device checks remain open.

Economy baseline tables are historical: they predate boss changes, goal gold and relic effects. The updated scripted player conserves the new gold source and selects relics by its existing attack/HP score; it does not model a human's travel preference. No current enjoyment, retention or spending-gap claim follows from these tests.
