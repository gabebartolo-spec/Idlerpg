# Trail expeditions (R17 desktop prototype)

Choose one of two authored five-node routes before leaving. The current outing finishes first; from the fishing pond, the adventurer can depart immediately. Each node takes one simulated minute and resolves automatically, including while away. The entry attack, health, Thornward protection and eligibility for one prepared stew are frozen. Changing gear midway cannot rewrite the route's build.

| Route | Encounters in order | Final gold, first / repeat |
|---|---|---:|
| Gentle Greenway | stream, camp, wolves, stream, cache | 35 / 10 |
| Shattered Causeway | bridge, wolves, cache, guardian, camp | 60 / 20 |

The six encounters are fixed authored content. Streams heal three health, camp heals six, and the cache grants eight gold. Wolves deal `max(4, 18 - entry attack)` damage. The bridge deals ten damage. The guardian deals 24, halved by earned Thornward protection. These are prototype balance assumptions disclosed before departure.

Passive fishing preparation or earned Briarheart Charm protection can make the risky route viable for an early free build. At most one Pond Stew restores twelve health when the full heal fits, consuming it at that moment. Missed sessions require no rescue or live route decisions. Summon income continues accruing; ordinary quest rewards pause during the expedition.

Leaving or failing preserves found cache gold, discovered encounters and unused preparation, while withholding the final reward. A retry must be explicitly selected and uses ordinary simulated time. First-completion flags are independent per route; later completions receive the stated smaller reward. Node progress and grants settle before event-triggered checkpoints can save them. The controller, wallet and route flags serialize together in save format 15.

The Choose Route tab shows risks, counters and reward rules. Last Journey shows the latest run's actual route and coherent ordered encounter log; it is a bounded latest-run recap, not an archive of every past expedition. First route completions enter the chronicle and return highlights. The watch view follows the adventurer's route waypoints.

Tests cover both routes, five-node duration, all six discoveries, free counters, lower repeat payouts, queued watched/offline equality, frozen builds, partial-node reload, event-time checkpoint replay, stew consumption, abort and old-save defaults. UI tests cover route selection, compact results and retention of the actual journey in **Field journal → Field guide → Trails**. Actual phone-sized desktop renders are inspected; real Android controls/performance and player route-preference sessions remain VERIFY.
