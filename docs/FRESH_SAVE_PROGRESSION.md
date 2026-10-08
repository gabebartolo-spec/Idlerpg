# Fresh-save progression evidence

This is an automated design check, not tester data. The owner is the only tester now; there is no recruitment requirement or scheduled attendance.

Two scripted seven-day schedules start with a level-one adventurer, empty gear inventory and no route clears. They use only gameplay actions, actual local save files and offline catch-up. They opt out of random hunt drops and make no summon draws. Each scripted visit lasts 30 simulated live seconds, with a 90-second opening session; these are model inputs, not measured human task times.

The script equips owned guaranteed starter gear, spends earned talent points on Thick hide/Heavy hand/Sharpened edge, opens earned chests, chooses an available uncleared route, then pursues repeat-clear milestones. It never grants gear, assigns levels, marks routes cleared or skips an outing by calling a private cycle-start method.

| Actual earned item | Two scripted returns/day | Three scripted returns/day |
|---|---|---|
| Goblin Cleaver / Wolfskin Hood | Opening session | Opening session |
| Briarheart Charm | Hour 12 | Hour 8 |
| Mothglass Spear | Hour 60 | Hour 40 |
| Mooncap Mantle | Hour 72 | Hour 56 |
| Lamplighter Seal | Hour 108 | Hour 88 |

Both schedules genuinely clear all seven route gates and open all three regional gear chests within 168 hours. Earned loadouts are saved to disk, restored and applied without missing pieces. Additional post-scenario trials apply each in-game build recipe and complete the deepest journey; those extra trials are not included in the seven-day timing table.

Reopening each return at the same timestamp simulates zero additional time and preserves progression counters, expedition state and the chest ledger. Inert negative activity timers and tiny floating-point clock normalization are not treated as reward duplication; the check compares the authoritative progression state.

## Pacing observations

The two-return schedule reaches level 319; the three-return schedule reaches level 302 because it spends more time on expeditions. Flat item stats are small relative to late base stats, while their percentage-based effects and appearance ownership still differ. This is a balance concern to assess during the owner's playtest, not evidence that the rewards feel meaningful.

The 2h/8h/24h trips often finish before the next scripted visit. Repeated clears and mastery are therefore paced by chosen return times as well as trip clocks. The 102-hour minimum journey horizon for all three masteries does not promise all masteries in a seven-day casual schedule. There is still an unfinished pursuit at the end of these schedules. No retention or enjoyment inference follows from scripted returns.

## Usability changes

Expeditions → Builds provides optional Striker, Guardian and Lamplighter gear recipes. Ownership and any needed talent point are checked before applying changes. Striker explicitly shows its one-point Thick hide cost. Recipes replace weapon, hood, chest and accessory, retain other equipment/talents/companion/relic and never heal. Departed expedition preparation remains frozen. Saved custom presets remain separate and are not overwritten.

Adventure goals now show their actual pursuit count and a short hint. Detailed trail rules remain in the Field Guide. Owner notes are optional and no longer ask for a participant number.

Verification: 38 desktop Godot suite runs passed; standalone final fresh-save report passed; actual 405×720 larger-text/reduced-motion Build-page capture and Guardian action completed without engine errors. The physical phone checks remain pending the owner's APK export.
