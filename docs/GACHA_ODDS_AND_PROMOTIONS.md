# Gacha probability, pity and event-promotion research

**Owner research request, 9 October 2026:** Find a quantitatively defensible gacha reward-rate and paid-promotion structure that attracts repeat purchases **without making players feel deceived or wasting their progress**. The specific scenario proposed was 100 event chests for guaranteed special loot, 50 earnable for free and the remaining 50 requiring purchase. Evaluate this honestly; do not silently implement it as a hard pay gate.

**Status:** Initial sourced research + explicitly labelled prototype simulations. NOT proven revenue-optimal rates or an implemented gacha. Existing `src/game.gd` reportedly starts with 250 tokens at 10/pull, 1% base legendary and 90-pull rarity pity. The owner's 15-minute full-legendary playtest may have been affected by debug infinite tokens: [P0 issue #45](https://github.com/gabebartolo-spec/Idlerpg/issues/45) calls for separate non-debug reproduction.

## 1. Competitor benchmarks — comparable mechanics, not a universal sweet spot

| Game/banner | Base top rarity | Pity / guaranteed item | Source and caveat |
|---|---:|---|---|
| **Genshin Impact** standard wish | 0.6% 5-star, 1.6% consolidated (includes guarantee) | One 5-star by 90; 4-star+ by 10 | [Official HoYoverse wish details](https://webstatic-sea.hoyoverse.com/genshin/event/e20190909gacha/index.html?gacha_id=fecafa7b6560db5f3182222395d88aaa6aaac1bc&lang=en&region=os_asia), archived banner example. |
| **Wuthering Waves** character event | 0.8% 5-star | 5-star by 80; featured initially 50/50, guaranteed after next 5-star if lost (worst case 160) | [Community guide](https://www.prydwen.gg/wuthering-waves/guides/gacha/), subject to game-version updates. |
| **AFK Journey** all-hero | 0.72% S-level *base*; 2.05% *including pity* | One S-level within 60; A+ by 10 | [Community documented rules](https://afk-journey.fandom.com/wiki/All-Hero_Recruitment), versions vary. |
| **Guardian Tales** introductory guarantees | Not comparable as a general rare-item probability | Official dev note describes a **one-time first-30-summons unique hero guarantee**, separately first-30 exclusive equipment guarantee | [Guardian Tales developer note](https://www.guardiantales.com/news/87). Starter certainty is an important separate mechanism. |
| **Our Idle RPG today** | 1% legendary | Rarity by 90 | Inspect `src/game.gd` and actual build; **not** evidence of desired final probability. |

Don't conflate base odds with 'consolidated' rates including pity, or 'any legendary' with *specific featured legendary*. Don't compare paid ten-pulls with earned chests until currencies and actual item utility are normalized.

## 2. Simple probability: what players may actually experience

With independent per-chest base chance `p`, and no pity triggered yet, `P(at least one legendary in n) = 1 - (1-p)^n`.

| Base chance | Chance in first 10 | Chance in first 50 | Chance in first 100 | Mean interval with 80-pull guaranteed top rarity* |
|---|---:|---:|---:|---:|
| 1% | 9.6% | 39.5% | 63.4% | 55.2 |
| **1.5%** | **14.0%** | **53.0%** | **77.9%** | **46.8** |
| 2% | 18.3% | 63.6% | 86.7% | 40.1 |

*Expected pulls until top rarity, independent base chance with a **hard reset-on-success pity at 80**, is `E[min(T,80)] = (1-(1-p)^80)/p`. The first-100 base-chance column is **deliberately without pity**, and should not be read as a full-pity model's actual first-100 probability. At 1.5% and hard pity 80, a legendary is guaranteed by 80. A **featured** item may still need an independent selection/spark rule.

**Commercially dangerous interpretation of the owner's example:** If the only possible free supply is 50 event chests and there is a guaranteed item at 100, **the guarantee is literally unavailable without paying**. At 1.5% random legendary probability, ~47% of players would miss any legendary in those initial 50 draws *before a hard-pity rule triggers*; probability of their specific desired featured item can be lower. Do not market the 100-chest reward as universally earnable if the player cannot obtain all 100 without buying.

## 3. Three actual test candidates — NOT committed rates

| Prototype | Base legendary | Hard rarity pity | Independent featured-item spark | Intended comparison |
|---|---:|---:|---:|---|
| A: conservative | 1.0% | 80 | 100 pulls | Longer chase, worse initial experience without excellent intermediate rewards |
| **B: balanced starting hypothesis** | **1.5%** | **80** | **100 pulls** | More early excitement, guaranteed goal without 'lost 50/50' misery |
| C: generous | 2.0% | 60 | 100–120 pulls | Higher novelty, potentially faster catalogue/duplicate saturation |

**Proposed standard reward table to test with B:** Common 65%, Rare 25%, Epic 8.5%, Legendary 1.5%. Separately guarantee a Rare+ within a ten-pull interval. The guarantee algorithm must be mathematically specified and audited: it should not secretly lower independently advertised legendary odds. Every pull can also grant a modest, disclosed progress currency toward selected crafting, refinement or cosmetics so even common/duplicate rolls feed something useful.

**Independent two-track security model:**
- **Rarity pity** at 80 guarantees *a* legendary and resets when any legendary occurs.
- **Spark** grants one non-expiring credit on every eligible draw and lets the player **choose a specific featured/rotating item** after 100 credits. It does not reset simply because a random legendary dropped. Spending or redeeming a target consumes credits as disclosed; unused spark never vanishes when a limited banner ends.
- The resulting 80 / 100 structure is transparent, differs materially from character-banner 'lose 50/50' mechanics, and can be tuned without destroying earned progress. **Check financial sustainability and target saturation before adopting**; the item pool must have ongoing utility, and making copies necessary for basic viability would be a bad trade.
- Track each currency/banner's rules in a visible details view: base rate, guaranteed max pulls, featured chance, spark balance, carryover, rewards on duplicates, whether one 10-pull is discounted and what counts toward milestones.

## 4. Event promotion design: compare two very different propositions

### Owner proposal: guaranteed special reward after 100 chests, only 50 free

This is a real-money gate wearing the appearance of a participation guarantee. A fully transparent **paid-only item** could be sold as a clearly priced fixed-content bundle, but don't represent the 100-chest progression prize as 'free unlockable' if purchase is mathematically mandatory.

### Preferred prototype: free completion is possible; purchase is a real accelerator

One **illustrative 14-day campaign**, **not** a committed grant schedule:
- Give up to **50 event-specific chests** through ordinary autonomous adventure and event goals, with banked/late-join catch-up. (Never require 14 consecutive logins.)
- Allow general freely earned summon currency to be used for more event chests. For illustration, a routine **4 standard-equivalent pulls/day over 14 days adds 56**, making **106 available** to an engaged free player. The exact value must be measured against the entire game's currency income, purchase pricing, and the accessibility of actual goal progress — not all players will collect every reward.
- Sell token/chest packs to finish early, take more shots at rare variants and cosmetic/collection breadth, or preserve regular earned currency for other banners.
- Give extra **known** resources at 10/25/50/75/100 total event pulls (example milestones; calibrate reward value), culminating in a **guaranteed chosen special item at 100**, regardless of free/paid source. Do not quietly reset milestone progress after an unfeatured drop.
- Let unused spark carry into future event banners. For retired event exclusives, define a public replay/legacy path; don't make unrecoverable purchased progress. A premium pass could grant a transparent extra 50 event chests, but a player choosing not to buy must still have a predictable attainable or retained future guarantee.
- If a limited event cannot have full free completion in its window, say so clearly and preserve target/spark progress until its scheduled rerun or evergreen exchange. Never sell a 'guarantee' that expires while the owner is just short of it.

**Other testable promotion types (separate, not stacked into a confusing shop):** (i) beginner guaranteed useful epic within first 10 free draws (not automatically a top legendary), (ii) fixed-content starter growth pack, (iii) clear buy-ten-get-two bonus pulls (show actual effective price), (iv) premium seasonal track with fixed listed rewards + capped tokens, (v) repeat acquisition via transparent duplicate materials and targeted item crafting, (vi) clearly disclosed optional featured-rate-up with the same published pity rules.

## 5. No-scamming guardrails and commercial validation

1. **Show actual odds** for each *specific* reward, base vs pity-adjusted, with a verifiable algorithm. No secret spending-history-specific odds, undisclosed dynamic rates or different rules for free and purchased pulls. Probabilities cannot be misleading or rounded to hide rarity.
2. **Never confuse pity and featured guarantee.** A 'legendary in 80' is not 'the legendary you want in 80'. Keep both counters plainly visible and persistent. Use game-server-authoritative ledgers when real money is introduced.
3. **Always retain earned/purchased progress.** No secretly expiring pity, counter loss on disconnect/refund handling that affects unrelated earned rewards, or pressure countdown when the paid purchase cannot be completed fairly.
4. **No useless consolation streaks.** Common items and duplicates should provide *bounded* refinement/crafting credits, without turning paid quantity into automatic unbounded combat/PvP power.
5. **Long-term collection** requires breadth and distinctive build functions, not just an endless extension to the numeric rarity ladder or artificially inflated duplicate copies.
6. **Monetisation only after P0 progress fix:** new ordinary account must still have meaningful gear/build goals after 15m, 1h, 1d, 7d and 30d with frequent small upgrades; debug infinite currency is analysed separately.
7. **Simulate and verify:** new/free/light/high spender, offline vs watched, unlucky P90/P99 draws, up-to-100 and post-100 purchase costs, collector completion time, duplicate value, first-session enjoyment, PvP power difference, retention and actual refunds after live release. The 'sweet spot' cannot be determined by competitor rates alone: use mock purchase value research then controlled release.
8. **Respect consumer law and player welfare:** no fake expiring deals, misleading crossed-out prices, purchases disguised as free guarantees, compulsive loss-to-buy popups or spending escalation based on inferred vulnerability.

**Research:** A [2025 randomized gacha study (N=457)](https://doi.org/10.1016/j.entcom.2025.101044) found pity systems reduced perceived risk and raised payment intention while warning about excessive-spend risks. [Google Play Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738) requires randomized-item odds near/in advance of purchase. [Australian Classification](https://www.classification.gov.au/classification-ratings/new-classifications-for-gambling-content-video-games) now imposes minimum **M** for games with chance-based paid items (M is advisory, not an automatic legal 15+ ban). The [ACCC](https://www.accc.gov.au/consumers/advertising-and-promotions/online-and-mobile-games) warns about misleading price, fake urgency, nagging popups and hidden costs. Japan's [Consumer Affairs Agency explains its prohibition on combination-gacha](https://www.caa.go.jp/policies/policy/representation/fair_labeling/faq/card) for certain combinations of separately randomly acquired paid items: review legal requirements by release region, especially if promotions reward collecting sets of random symbols.

## 6. Implementation sequence and gate

**First:** fix XP/build/gear saturation and playtest ordinary in-game earning; run 15m–180d economy cases. **Second:** build a *read-only/mock* gacha experiment comparing A/B/C published odds and properly described featured 100-spark; create engagement/economy reports. **Third:** implement one small event with meaningful rewards, persistent non-expiring spark and free-vs-paid source parity, **only after the base economy and actual reward catalogue can sustain it**. **Fourth:** once R29/R25 billing trust exists, add verified paid token packs and purchase restoration; do not turn on real payments as a shortcut.

Related: [MONETISATION_STUDY.md](MONETISATION_STUDY.md), [PACING_MATH_AND_BENCHMARKS.md](PACING_MATH_AND_BENCHMARKS.md), [RESEARCH_BACKLOG.md](RESEARCH_BACKLOG.md), [THREE_PILLARS.md](THREE_PILLARS.md) and [P0 issue #45](https://github.com/gabebartolo-spec/Idlerpg/issues/45).
