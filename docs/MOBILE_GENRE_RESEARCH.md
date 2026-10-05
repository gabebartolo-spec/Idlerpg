# IdleRPG: mobile market, engagement and commercial design research

Research date: **5 October 2026 (Australia/Sydney)**. Repository examined: `main` at `e029a1655987e7b107ddb9713bbd21dfa35d8c0e`.

## Recommendation

Make the living adventurer a game about **attachment, preparation, discovery and collection**. The most promising next work is giving players better reasons to choose an adventure, change a build, anticipate a reward and enjoy returning. Monetize the breadth of that experience once it works: collections, expressive cosmetics, affordable value purchases, seasonal free/paid passes with a purchased-pass archive and eventually expansions.

The owner explicitly wants enjoyable play, generous free/light-spender progression, and substantial MTX/whale scope. These are compatible goals, but the compatibility must be demonstrated in the economy rather than asserted in marketing. A whale should be able to collect and customize extensively, accelerate some personal progression and fund continued development. A free player must still have viable builds, reliable upgrades and attainable aspirations.

The actionable follow-through is [44 implementation tickets](RESEARCH_BACKLOG.md), connected to the existing gated phases in [the design bible](DESIGN_BIBLE.md). These are researched hypotheses to test, not claims that any copied feature will produce the same revenue. The owner's updated direction makes **real guilds, PvP, cooperative raids, global bosses and guild wars** central to the product; earlier NPC-only social scope is superseded. The first implementation should be asynchronous multiplayer, compatible with an autonomous adventurer and offline life.

## What the evidence can establish

Public mobile charts rank **estimated revenue or consumer spending, not game-level profit**. We cannot honestly identify the most profitable games without their acquisition, platform, development and operating costs. Publisher-wide profits do not resolve that gap.

The financial comparison below uses a completed year and a recent month separately. AppMagic-derived annual figures are estimated store earnings after the reported 30% platform deduction, excluding ads, webshops and Chinese third-party Android. Sensor Tower figures are a different consumer-spend series. Do not add or directly compare their dollar totals. The annual chart is a secondary publication of AppMagic estimates; the recent chart is a primary Sensor Tower publication.

This is desk research of market reports, developer documentation, published studies and publicly displayed player reviews. It does not include hands-on competitor play, paid dashboards, a representative review sample, or IdleRPG player telemetry. Revenue associations are not controlled retention experiments. Store reviews are examples of experiences, not prevalence estimates. Prototype prices, pacing and release criteria below are our proposals.

## Commercial leaders worth studying

### Completed-year baseline: 2025

| Rank | Game | Reported estimated store earnings | Useful reference area |
|---|---|---:|---|
| 1 | Honor of Kings | $1.68B | Mastery, identity, cosmetic desirability |
| 2 | Last War: Survival | $1.57B | Approachable opening, expanding progression, alliances |
| 3 | Roblox | Nearly $1.5B | Variety, expression, social identity |
| 4 | Whiteout Survival | More than $1.4B | Persistent world, long-term plans, belonging |
| 5 | Royal Match | $1.37B | Readable wins, feedback, milestone anticipation |
| 6 | MONOPOLY GO! | $1.36B | Collections, cooperation, overlapping rewards |
| 7 | PUBG Mobile | Top-ten placement; no figure transcribed | Identity and aspirational presentation |
| 8 | Candy Crush Saga | More than $1B | Familiar core, escalating challenges |
| 9 | Pokémon TCG Pocket | Top-ten placement; no figure transcribed | Collection desire and presentation |
| 10 | Coin Master | About $650M | Collections and persistent progression |

Source and methodology: [Mobilegamer: AppMagic's 2025 top-grossing charts, 13 January 2026](https://mobilegamer.biz/the-top-grossing-mobile-games-of-2025/). The qualitative reference areas are our design interpretations, not findings from the ranking. This shortlist does not make these titles idle RPGs.

### Recent context: September 2026

Sensor Tower's October publication lists **Honor of Kings, Roblox, Gossip Harbor, Candy Crush Saga and MONOPOLY GO!** as September's top five. Its narrative associates fresh gameplay, cosmetics, anniversaries and new collection targets with spending activity; it does not prove that these caused sustained player enjoyment. Third-party Android markets are excluded. [Sensor Tower: September 2026 worldwide mobile rankings](https://develop.sensortower.com/blog/top-10-worldwide-mobile-games-by-revenue-and-downloads-in-september-2026).

A Gamesforum article dated **28 September** reports a different AppMagic-based September order and dollar amounts. Because it predates month-end and uses a different series, its scope/completeness is unclear. It is not used as the definitive completed-month ranking. [Gamesforum's September article](https://www.globalgamesforum.com/news-media/the-biggest-mobile-games-of-september-2026).

The market is difficult: Sensor Tower reports H1 2026 mobile IAP around $40B, down 2% year over year, downloads down 12%, with advertising spend up 8%. That makes differentiated appeal and acquisition economics important. [Sensor Tower: H1 2026 index](https://sensortower.com/blog/h1-2026-digital-gaming-market-index).

### Direct genre evidence

Legend of Mushroom had reached an estimated **$270M worldwide IAP by the end of April 2024**, according to Sensor Tower. That is a historical success signal, not a current genre rank. The same source identifies casual idle play, recognizable character appeal and localized marketing as parts of its success. [Sensor Tower: APAC 2024 report](https://sensortower.com/blog/state-of-mobile-games-in-apac-2024-report).

AFK Journey's August 2024 Asian launch brought nearly tenfold monthly revenue growth, with over 70% of revenue from newly added markets. Distribution, localization and advertising matter alongside mechanics. [Sensor Tower: August 2024 recap](https://sensortower.com/blog/august-2024-mobile-gaming-recap).

Capybara Go! passed $10M estimated lifetime iOS revenue in November 2024. A later trade-press report cites $109M gross player spending by 10 February 2025. Different platform scope, periods and gross/net definitions make these unsuitable for a combined chart. [Sensor Tower's iOS milestone](https://app.sensortower.com/news-feed/habbys-capybara-go-hits-10m-all-time-ios-revenue-one-month-after-launch/6743fb327bcfcd12834eb471), [PocketGamer.biz's AppMagic milestone report](https://www.pocketgamer.biz/habbys-capybara-go-surpasses-100m-in-gross-player-spending/).

AppMagic's Monetization Report shows Idle RPG estimated IAP declining **18.56%** between October 2023–September 2024 and October 2024–September 2025; its taxonomy and periods differ from calendar-year reports. The report also describes higher-price offers in top strategy games. IdleRPG should learn how to create desirable purchases while avoiding an assumption that the idle label alone guarantees growth. [AppMagic Monetization Report 2025, methodology and RPG section, mirrored PDF](https://investgame.net/wp-content/uploads/2025/11/EN_Monetization_Report_2025.pdf).

## Competitor deconstructions

The observed systems and reported player experiences below are sourced. The proposed engagement mechanism, business implication and IdleRPG adaptation are **our hypotheses**.

### Legend of Mushroom: frequent loot decisions

Its lamp trades consumable lamps for equipment; gear becomes an upgrade or is sold for XP/gold. Auto-use and filters remove repetitive handling. [Theria's lamp guide](https://theriagames.com/guide/lom-magic-lamp/). The developer presents class choice, visual customization, alliance bosses and gardening. Displayed Google Play reviews include criticism of feature overload and later spending pressure. [Developer description and displayed reviews](https://play.google.com/store/apps/details?hl=en-US&id=com.mxdzzus.google).

**Hypothesis:** frequent comparison creates anticipation and feedback; automation preserves the interesting decisions. Collection breadth creates spending opportunities, but more currencies and daily systems can bury the fun.

**Adaptation:** world chase items, free targeted collection, a reliable earning loop and protected inventory batch actions. Keep the one-adventurer identity rather than introducing a lamp treadmill. Tickets R09–R11.

### AFK Journey: experimentation without rebuilding everything

Shared hero equipment/levels lower the cost of trying formations. GameRefinery also describes exploration, puzzles and strategic variety. [GameRefinery's 2024 landscape analysis](https://www.gamerefinery.com/breaking-down-the-biggest-trends-shaping-the-mobile-gaming-landscape/). The developer promotes shared progression; displayed reviews praise it and the world, while other reviews criticize value or the amount of active play required. [AFK Journey store description and reviews](https://play.google.com/store/apps/details?hl=en_US&id=com.farlightgames.igame.gp).

**Hypothesis:** experimentation improves the player's sense that choices matter. New characters can be desirable immediately when switching does not invalidate previous investment.

**Adaptation:** free loadouts/respec, sidegrade relics, boss counters and meaningful companion niches. Do not convert the game into five-hero roster management. R06–R08 and R14.

### Capybara Go!: small adventures with uncertain outcomes

The developer describes randomized events, equipment and animal companions in a roguelike adventure. Displayed reviews praise the visual appeal but criticize abrupt progression stalls, high prices and time-zone restrictions. [Capybara Go! store listing](https://play.google.com/store/apps/details?hl=en_US&id=com.habby.capybara).

**Hypothesis:** short adventures and temporary variation make repeated attempts interesting; persistent progress can make failure useful. Paid acceleration becomes unattractive if the free game stops offering decisions.

**Adaptation:** autonomous expeditions with route policies, a small boon pool, readable failures and banked progress. Choices happen before departure; no mid-run attention is required. R05, R16–R17.

### Melvor Idle: long-term plans and interlocking skills

The developer describes skills that support one another, dungeons, pets and item collection. A displayed review praises substantial free play and the prospect of more paid content. [Melvor listing and reviews](https://play.google.com/store/apps/details?hl=en_US&id=com.malcs.melvoridle). Its published license describes one-off payments rather than a required recurring subscription or recurring in-game payments. [Jagex's Melvor terms](https://legal.jagex.com/docs/terms/eula).

**Hypothesis:** knowing why to train a skill supports enjoyable planning; expansions can sell more experiences after a satisfying base game.

**Adaptation:** one useful passive profession with a collection goal, then a small profession-to-preparation connection. Paid future regions may expand breadth, but the free campaign must stand on its own. R15 and R22. Melvor is a design counterexample, not an asserted top-grossing game.

### Whiteout Survival and Last War: belonging, preparation and spending depth

Their developer listings emphasize building, heroes and alliances. [Whiteout Survival](https://play.google.com/store/apps/details?hl=en_US&id=com.gof.global), [Last War](https://play.google.com/store/apps/details?hl=en_US&id=com.fun.lastwar.gp). Last War's displayed reviews include complaints about advertised gameplay not matching the main experience and escalating resource pressure.

A 2026 Whiteout study uses interviews and gameplay walkthroughs to examine perceived inequality; it finds that interpretations of fairness depend on social position and community structures. This is qualitative work, not a representative estimate of all players. [Lei et al., Whiteout inequality study](https://arxiv.org/abs/2607.25574).

**Hypothesis:** shared goals and long preparation horizons create belonging and aspiration. Spending hierarchies can also create frustration and social obligation.

**Adaptation:** real guild projects, asynchronous raids, world bosses and wars; readable preparation, socially visible cosmetics and bounded collection/progression purchases. Preserve useful free-player roles and avoid selling protection from destructive attacks. R16, R18, R20–R23, R28–R35.

### Royal Match: clean feedback and a recognizable aspiration

Dream Games documents a Super Light Ball earned by completing ten levels, retained while winning and reset on failure. [Official help](https://dreamgames.helpshift.com/hc/en/3-royal-match/faq/234-what-is-the-super-light-ball/?p=web).

**Hypothesis:** strong feedback and a visible attainable target give wins momentum; losing a valuable streak may add pressure. That pressure is an unsuitable match for a relaxed persistent adventurer.

**Adaptation:** clear next milestones, satisfying loot/level-up/audio and unlock celebrations. Use cumulative achievements instead of lose-it-all streaks. R04, R13, R27.

### MONOPOLY GO!: collection completion and shared progress

Google Play's editorial explains partner events with shared progress and milestone rewards. [Partner-event editorial](https://play.google.com/store/apps/editorial?hl=en-US&id=mc_editorialmd_monopoly_go_evergreen_partner_coop_june_fcp). Scopely reports over $6B lifetime IAP in 2025 using Sensor Tower estimates; that is evidence of scale, not evidence every mechanic improves enjoyment. [Scopely's milestone report](https://www.scopely.com/en/news/sensor-tower-scopelys-monopoly-go-hit-6-billion-revenue-milestone-in-2025-in-record-time).

**Hypothesis:** recognizable missing pieces and shared accomplishments can be desirable. Time-limited completion and dependence on another person's attendance may make optional play feel obligatory.

**Adaptation:** permanent collection volumes, a visible route to missing pieces and real-player cooperative projects. No resetting owned collection or abandoning an earned pass. R10, R18–R19, R24, R30–R31.

### Gossip Harbor: care about what comes next

Its developer describes a mystery, recurring relationships and restaurant restoration. A displayed review praises the underlying gameplay but criticizes increasing energy requirements. [Gossip Harbor listing](https://play.google.com/store/apps/details?hl=en_US&id=com.mergegames.gossipharbor).

**Hypothesis:** narrative curiosity and visible changes can create interest beyond numeric power; interrupting a story with resource pressure can weaken that appeal.

**Adaptation:** recurring quest NPCs, first discoveries and a persistent adventurer chronicle. Small authored vignettes rather than a dialogue production treadmill. R03, R12–R14.

### Brawl Stars and MapleStory Idle: trust is part of the economy

Supercell's July 2025 explanation acknowledged that pricing a new rarity more highly missed the mark and discussed changing early access. Its 2025 retrospective calls that year its second best for users and revenue. [July developer explanation](https://supercell.com/en/games/brawlstars/blog/game-updates/about-the-update-records-changes/), [2025 retrospective](https://supercell.com/en/games/brawlstars/blog/community/2025-in-review-franks-blog-post/).

Nexon's February 2026 investor update describes incorrect displayed probabilities for paid MapleStory Idle items and compensation/full refunds for the affected period. [Nexon's official update](https://www.nexon.co.jp/en/news/detail/?id=20260202-034c3abd).

**Hypothesis:** players value surprise more when guarantees, acquisition paths and prices are understandable. A technical error in purchase odds can become a product-trust failure.

**Adaptation:** one source for actual/displayed odds, persistent pity and selection guarantees, transaction replay protection, no surprise price/rarity escalation. R10, R23, R25.

## Why the loop can be engaging and enjoyable

A published experiment links game enjoyment to competence and relatedness, examining feedback, rules and social elements. It does not establish that any specific idle mechanic causes addiction. [Rogers, 2017](https://www.sciencedirect.com/science/article/abs/pii/S0747563217302054). An experiment manipulating need support in a game-learning context also supports the relevance of autonomy, competence and relatedness; transfer to this commercial game remains a hypothesis. [Sheldon and Filak](https://pubmed.ncbi.nlm.nih.gov/17761025/).

For IdleRPG, the practical design model is:

| Player feeling | Concrete experience | Testable design hypothesis |
|---|---|---|
| Competence | A defensive build survives the boss that previously defeated me | Understanding and counterplay feel better than a power wall |
| Autonomy | I choose a safe hunt, a relic chase or a dungeon | Selecting goals makes autonomous play feel like my plan |
| Attachment | My named adventurer's chronicle records a memorable recovery | Specific shared history gives me a reason to return |
| Anticipation | I know the next milestone and where my desired item comes from | Predictable progress plus occasional surprise sustains interest |
| Discovery | A route yields a new encounter or keepsake | Small authored surprises outperform endless identical quests |
| Belonging | Guildmates finish a project together; your support build changes a raid | Real cooperation makes progress socially meaningful without mandatory live attendance |
| Expression | A chosen outfit and companion make the character mine | Visible identity can make cosmetic purchases desirable |
| Relief | An overnight return takes under a minute to understand | Efficient management preserves enthusiasm and player time |

These are implementation hypotheses. Long sessions, many taps, retention and spending alone do not prove enjoyment. Pair behavior with questions about fun, agency, perceived fairness and obligation.

## Deeper findings: generosity, contribution, expression and seasons

The strongest direction is **a generous personal adventure, a useful place in a guild and a desirable cosmetic collection**. Seasonal free/paid passes connect those experiences. This revision challenges three assumptions in the initial proposal: abundant pulls need not remain interesting, small paid bonuses can compound, and cosmetic ownership alone does not make cosmetics desirable or visible. The following separates observed evidence from design interpretation and exploratory calculations.

### Generosity must deliver meaningful rewards

In April 2026, Supercell said broader access to Brawl Stars cosmetics had not delivered its expected engagement increase. It discussed accumulated cosmetic currency and declining excitement around new skins. This is the developer's interpretation of its game, not a controlled experiment or evidence against generosity generally. **Interpretation:** more rewards can lose value when players do not want or use them. [Supercell's cosmetic review, 1 April 2026](https://supercell.com/en/games/brawlstars/blog/news/changes-to-bling-shop-and-cosmetics/).

An exploratory model of IdleRPG's current catalogs estimates the share of draws yielding a previously unowned catalog identity:

| Seven-day window | Previously unowned item / all draws | Mean unique gear / companions / relics owned |
|---|---:|---:|
| Days 1–7 | 34.6% | 15.4 / 7.6 / 6.1 |
| Days 24–30 | 1.8% | 22.4 / 9.9 / 8.9 |
| Days 84–90 | 0.1% | 24.6 / 10.0 / 10.0 |

**Method:** 2,000 initially empty accounts, 90 days, seed 20261005, fixed daily order of six gear, four companion and two relic draws. These 12 daily draws are a proposed earning scenario, not measured player income. Catalog counts from `src/game.gd` at the research baseline are 25 gear (7/7/7/4 by rarity) and 10 companions and 10 relics (3/3/3/1 each). Model rarity weights are Common 68%, Rare 22%, Epic 9%, Legendary 1%; the 90th consecutive non-Legendary sequence guarantees Legendary, and any Legendary resets that banner's counter. Items are sampled uniformly within rarity; each banner tracks its own ownership and pity. Each table window contains 84 draws per account; mean novelty is averaged across accounts.

**Limits:** excludes introductory draws, purchases, duplicate conversion, actual reward-source pacing, salvage loops and combat utility. Owned sets never shrink. The Python sampling generator reproduces rarity rules statistically; it does not reproduce Godot's random sequence. This measures **collection novelty, not enjoyment or upgrade usefulness**. It is neither a forecast of retention nor a proposal to keep the exact catalog/rates indefinitely. The reproduction listing at the end of this report specifies the implementation.

**Roadmap consequence:** R01/R10/R11 separately measure useful upgrades, selected-item progress, new viable builds and desirable cosmetic pursuits at saturation. Adding continually stronger items merely to preserve novelty would create a power-creep problem. Generosity remains a product commitment; useful outcomes are the validation target.

### Free players need mechanical contributions that matter

Supercell described Clan Capital as a way for members to feel valuable despite differences in personal progression. Its rules preserve damage between attacks, allowing one member's work to help the next. This is a useful design precedent, not proof that IdleRPG will retain players through the same mechanic. [Developer rationale](https://supercell.com/en/games/clashofclans/blog/community/clashofclans-present-and-future-2/), [Clan Capital rules](https://support.supercell.com/clash-of-clans/en/articles/what-is-the-clan-capital-3.html).

A July 2026 Whiteout Survival study interviewed 11 players and found recognition could involve organization and relationships alongside spending. Its small selected qualitative sample cannot establish prevalence, causal effects or what excluded/former players would say. **Interpretation:** contribution and recognition need not collapse into a spending ladder, but free players should not have to become unpaid administrators to be valued. [Study and methods](https://arxiv.org/html/2607.25574v1).

R18/R31/R34 therefore define **damage, protection, preparation and objective completion** as mechanical routes to contribution. A free player should choose an enjoyable build/action, see what it changed, and receive recognition in the recap. Role-removal trials ask whether the outcome changes without that player's help. Participation rewards, persistent progress and mixed-cohort viability are checked separately from top-damage rankings. R32's global boss should retain the same principle.

### Cosmetics serve attachment, expression and patronage

Interviews with 32 League of Legends players identified enjoyment and social motivations, including purchases meant to support the developer. These findings support several possible motivations, not a guarantee that cosmetic-only monetization will sustain an idle RPG. [Marder and colleagues, 2019](https://research.hanken.fi/en/publications/the-avatars-new-clothes-understanding-why-players-purchase-non-fu/).

Riot acknowledged in February 2025 that some seasonal skins missed expectations and reduced their quantity to improve quality. **Interpretation:** coherent themes, recognizable execution and player attachment merit testing ahead of catalog volume. [Riot's February 2025 changes](https://www.leagueoflegends.com/en-sg/news/dev/dev-hextech-chests-getting-champs-more/).

Build three complementary families:

| Family | Prototype examples | Engagement/spending hypothesis |
|---|---|---|
| Earned achievement | Boss trophies, profession outfits, collection appearances, veteran titles | Memorable accomplishment and free-player prestige |
| Paid expression | Themed outfits, companion skins, poses and restrained animations | Desired style, character attachment and developer support |
| Social expression | Guild banners, hall decorations and celebration effects | Shared identity and a visible audience |

Free cosmetics need attractive designs of their own; premium value comes from desirable artistry and variety. Permanent appearance ownership survives selling functional gear and changes no combat stats (R36). Earned pursuits (R37), dyes/presets with free switching (R38), profiles, preparation lineups and readable raid recaps/replays (R39) turn ownership into actual expression. Observe phone-scale recognition, previews, equip frequency and use; ask whether someone wants to wear an item, rather than counting unlocks as enjoyment. Large cosmetic spending depends on sustainable art quality and production capacity; model that cost as well as sales.

### Seasons can stay exciting without losing purchases

Halo permits completing purchased passes after their active season, with retroactive paid reward eligibility. It normally uses one equipped pass; our proposed current-plus-one-archive progression is an adaptation. Guild Wars 2 keeps older seasonal cosmetics in an earned legacy catalog; its Wizard's Vault has no paid reward tier and is a precedent for reward longevity, not pass monetization. Both are PC/console design analogues, not mobile revenue evidence. [Halo's pass rules](https://support.halowaypoint.com/hc/en-us/articles/4408373413268-Halo-Infinite-Battle-Pass-Free-to-Play-FAQ), [ArenaNet's legacy rewards](https://help.guildwars2.com/hc/en-us/articles/19617357502867-Secrets-of-the-Obscure-Wizard-s-Vault).

**Chosen product direction:** replace the initial permanent-pass-only proposal with seasonal free/paid tracks and an archive. One current season and one selectable archived purchased pass advance through ordinary eligible autonomous play. Purchased passes remain completable; weekly objectives bank, obsolete objectives receive evergreen equivalents, and earned rewards deliver automatically. Late purchase grants previously earned paid rewards once. Rollover preserves ownership/progress; unearned older free cosmetics retain a published earned route through the legacy catalog.

R24 owns those mechanics; R40 authors the first cohesive theme; R42 serves returners and older free rewards. Paid tracks emphasize cosmetics; essential counters and multiplayer access remain free. R41 adds explicit cosmetic/pass gifting only after trusted identity, billing and ownership exist. Fixed contents, recipient eligibility, duplicate ownership, failed delivery and refund reconciliation must be clear; gifts grant no war score. Season length, prices, XP and reward counts remain prototype assumptions. No completion forecast is treated as a player obligation.

### Paid acceleration must be evaluated over time

An earning boost can become combat power through earlier gear, boss access, better drops and further reinvestment. Several individually small benefits can stack. A +25% cap on one source is a prototype input; it does not establish a +25% power ceiling, and “no direct stats” does not establish competitive neutrality.

R01/R23/R43 compare complete free/light/high-spend configurations at 30/90/180 days, with specified purchases, pass contents, boost expiry, selected-item acquisition and feedback loops. Report useful-reward frequency, power-gap trajectories, accessible counters, role distribution and reachable opponents, with sensitivity to unlucky free paths. Normalized ranked rules exclude paid combat advantages; progression competition discloses its differences and needs measured bounds. The exact acceptable gap remains unresolved until simulation and implemented-mode playtests demonstrate useful free participation.

### Multiplayer must function with few players

Illustratively, 1,000 daily players averaging ten minutes of play contribute 10,000 player-minutes: **10,000 / 1,440 ≈ 6.9 average concurrent players**. This is arithmetic under the stated scenario, not a forecast of launch population, peaks or matchmaking wait. Regions and several live queues would subdivide that availability.

IdleMMO already uses scheduled guild raids with enrollment and automatic starts, offering a direct genre precedent for asynchronous participation. Its rules should not be copied wholesale; our design still needs predictable no-show handling and offline participation. [IdleMMO raid documentation](https://wiki.idle-mmo.com/guilds/raids).

R43 simulates sparse activity, time zones, guild sizes, shared pools and queue splits before R33/R34 competition. R31 ships one small human raid first. Honest NPC practice supports learning when population is sparse; it must remain visibly separate from human multiplayer. Reports flag unmatched players and unusable roles instead of making arbitrary population promises.

## Multiplayer: belonging, rivalry and spending without making people disposable

The commercial relevance is strongest in Whiteout Survival, Last War, MONOPOLY GO! and the Supercell portfolio. Their social systems give players an audience, a shared objective and a reason to prepare. This is a mechanism hypothesis supported by feature observation, not evidence that guilds alone caused their revenue. IdleRPG should make a player think “my guild needs my build,” alongside “my adventurer found something good.”

**Guilds:** start with real membership, inspectable adventurers, an activity feed and one shared project. Make guild size small enough for an early population; test 12–20 members rather than launching an empty massive alliance. Give support, scouting and provision roles rewards comparable to damage contribution. Membership is free. Shared projects earn a guild hall trophy and personal rewards; leaving a guild must not erase earned personal progress. R18/R30.

**Raiding:** use a 24–48-hour preparation window, committed loadouts and server-resolved autonomous combat. Players can participate while asleep after enrolling. A support effect that prevents a wipe must appear in the recap. Start with three human adventurers and one boss, not a twenty-person raid; a clearly labeled NPC practice dungeon remains useful for learning. R16/R31. Windows and sizes are test proposals.

**Global bosses:** aggregate real server-validated contributions into one event identity. Use population-based health set before an event starts, staggered participation windows and personal progress rewards even if the community fails. Never sell the last hit, require waking for a spawn, or reward only the top damage dealers. Guild Wars 2's published design offers useful precedent for predictable rotations and guild-controlled boss activation; it is a PC design analogue, not a mobile revenue comparison. [ArenaNet's world-boss design](https://www.guildwars2.com/en-gb/news/the-megaserver-system-world-bosses-and-events/). R32.

**PvP:** two explicit modes. A normalized ranked arena tests preparation and counters with equalized combat budgets and an accessible free ruleset roster. A separately labeled progression arena celebrates earned/paid collection strength with power bands and rewards for participation. Neither requires manual combat. Do not promise equal competition while secretly matching on spending. Show the rules, opponent strength and a useful loss explanation. R33.

**Guild wars:** begin with asynchronous objectives, fixed free attempts and opt-in rosters. Match on eligible roster strength, activity and results; lock the roster and loadouts before resolution. Support objectives allow a developing character to matter. Supercell distinguishes regular war strength matching from Clan War League matching by league, illustrating that a league system alone does not guarantee equal power. [Regular war matchmaking](https://support.supercell.com/clash-of-clans/en/articles/clan-wars-matchmaking.html), [League matchmaking](https://support.supercell.com/clash-of-clans/en/articles/cwl-matchmaking-and-groups.html). R34.

**Spending opportunities:** guild banners, hall decoration, raid entrance effects, visible companion skins, trophy displays, permanent collection volumes, banner bundles and bounded personal acceleration. Optional patron gifts can celebrate a purchase with a small capped benefit for every eligible guildmate; keep war points and attempts unavailable for purchase. Paid progression can matter in PvE and progression PvP, while normalized ranked rules protect a competitive space. Cosmetic prestige also needs earned equivalents, so a free veteran has status.

The failure modes are social obligation, whale monopolies, weak-player exclusion, guild shopping for rewards, smurfing and empty matchmaking. Measure contribution by role and spend cohort, matchmaking wait, power-gap win rates, repeat encounters, guild churn, reports and perceived fairness. Test sparse populations before adding modes. Do not fragment launch players across servers, leagues and five queues. Offer honest practice opponents when no human match exists. Notifications remain optional; no absence penalties, lost owned loot, shield sales or paid war retries.

Real competition changes the trust model. Local saves, debug tokens and client clocks cannot authorize currency, leaderboards or contributions. R28/R29 establish accounts, server-owned outcomes and a migration decision before any multiplayer economy. Offline solo play remains useful, with reconciliation rules explained to players. Chat requires reporting, blocking, moderation and operating capacity; start with structured messages until those exist. Live billing also requires backend purchase verification and duplicate-safe entitlements. [Google Play security guidance](https://developer.android.com/google/play/billing/security).

## Revenue opportunities that fit this particular game

### Free play must have a complete promise

All core management, base campaign, viable combat roles, world chase rewards, free respec/loadouts, ordinary offline simulation and useful collections remain accessible. Free tokens accumulate through gameplay/offline progress, not daily attendance streaks. Free progression is tested with unlucky draw sequences as well as average luck.

Prototype candidate: after the introductory grants, **10–15 free pulls per 24 hours of ordinary simulated progression**, with no need for repeated check-ins. At a 90-pull hard pity that means a maximum 6–9 earning days for a Legendary on one chosen banner, before existing starter currency. This is arithmetic, not an observed market benchmark or a commitment to retain the current rates. At 10 tokens per pull, it requires 100–150 tokens/day, so the current fast quest loop must not award that amount on every completion. R01/R11 define measured earning buckets and source/sink simulation.

The current 1% base Legendary rate, 9% Epic, 22% Rare, 68% Common and 90 hard pity are prototype behavior in `src/game.gd`. A Legendary guarantee alone does not guarantee a useful missing item. Add an explicitly bounded selected-item route separately and publish its rules.

### Offer depth, not just a single cheap pack

| Audience | Proposed purchase family | Value delivered | Boundary |
|---|---|---|---|
| Free | Campaign rewards, earned draws, world exclusives, earned outfits | Complete base experience | Never require purchase to rescue a stuck core build |
| Light spender | Starter keepsake; one permanent supporter purchase; inexpensive outfit | Tangible identity and straightforward value | Core automation and reporting stay free |
| Regular spender | Seasonal paid pass with archive; optional cosmetic membership; themed bundles | Cohesive rewards, expression and continued collection | Purchased passes remain completable; no daily claim requirement |
| Collector / whale | Premium cosmetic suites, companion variants, mount skins later, banner bundles, optional personal acceleration, guild celebration gifts | Breadth, visible prestige, faster collection and generosity to friends | Normalized ranked arena; bounded progression competition; no compulsory spend gate |

Test a price ladder of approximately **US$2.99, $4.99, $9.99, $19.99, $49.99 and $99.99** in a mock store before live billing. These are proposed design anchors, not current competitor price claims; use localized platform prices at release. Large bundles must add genuinely desirable content/value, not simply larger numbers of unwanted duplicates. Catalog breadth and sustainable art production are the primary constraints on cosmetic whale spending.

Paid pulls and bounded personal acceleration are viable candidate options, not prohibited. However, they require free acquisition of gameplay identities, upper bounds on paid progression effects, protection for world loot, and a reason to continue after completing a banner. Prototype boosts should improve earning breadth rather than raise boss combat stats directly; first test a non-stacking maximum +25% on a specified earning source. Final limits remain open until 30/90/180-day complete-cohort simulations and playtests justify them; indirect combat advantage and reinvestment must be measured.

Real guilds, inspectable profiles, raid replays and war results give cosmetics a social audience. Build on-character previews, earned raid trophies, guild hall displays and optional patron celebrations. Do not assume cosmetics alone will sustain the business: collection breadth, archived seasonal passes, future content expansions and bounded progression purchases diversify revenue. Spending may improve PvE progression and the separate progression arena; that tradeoff must be explicit. Paid advantages do not enter the normalized ranked arena. Matchmaking, accessible counters and contribution floors must be tested before progression competition launches.

Avoid selling friction the game created: basic inventory filters, free loadouts, readable offline reports or essential build tools. Optional rewarded ads, if tested, cannot become the assumed free-player income floor. No forced interstitials during watching, returns or combat.

### Release economics

Track **payer conversion, ARPDAU, ARPPU, cohort revenue, repeat purchases, refunds and net contribution**, alongside enjoyment and free progression. Contribution equals collected revenue less actual platform/payment deductions, refunds, acquisition and attributable operation/content costs. Track payer concentration and model the effect of losing the largest buyers; whale dependence is a business risk even in a fair game.

Start with cohort evidence and a small controlled launch. No paid acquisition scale-up until conservative cohort contribution can support acquisition cost. A profitable cohort and an enjoyable experience are two gates, not interchangeable metrics.

## Priority and validation

1. Preserve the phone verification gate. The owner reports on 5 October that the current Android build runs very smoothly but gear scrolling cannot return upward after scrolling down; device/build details are unspecified. R00 prioritizes bespoke portrait UI design and scroll repair, then a phone retest. This report is partial evidence, not a completed verification gate.
2. Establish the economy/fun baseline and efficient, robust offline simulation.
3. Improve attachment and player agency using the existing two zones.
4. Make builds, relics, targeted collection and earning meaningful.
5. Deliver the scoped profession, dungeon and expedition slices.
6. Validate generous free progression and actual player enjoyment.
7. Build the account/trust foundation and one real guild project, then test a small cooperative raid.
8. Prototype desirable paid offerings, then build trustworthy live commerce.
9. Add global bosses, PvP and wars in that order only when population, moderation and fairness tests justify them.

Initial playtest: recruit 8–12 people who play idle/RPG games with a mix of free and paying habits, observe the first session, then run a seven-day diary/interview. This is formative research, not statistical proof. Ask why they returned, what choice mattered, what felt tedious, whether they would return without a reward, and whether any purchase seemed good value. Record build choices, meaningful upgrades, stuck intervals, return-report actions, cosmetic desirability/actual use, pass value/completion, voluntary social participation and perceived obligation. Pair these with refunds and spending concentration; distinguish “I want that reward” from “I feel required to finish.”

Prototype stop signals: non-spenders cannot find a viable boss counter; opening a report creates more sorting than interest; a player feels pressured to attend; a new system adds taps without meaningful choices; buyers exhaust content immediately; a paid item makes all world rewards irrelevant. Fix those before multiplying features.

GameRefinery's June 2026 report describes a large MONOPOLY GO! collaboration without a meaningful revenue improvement; its July/August report describes purchase-gated event milestones. These are reminders that novelty is not automatically a business win and monetization can reshape the activity itself. [June analysis](https://www.gamerefinery.com/mobile-game-market-review-june-2026/), [July/August analysis](https://www.gamerefinery.com/mobile-game-market-review-july-august-2026/).

## Reproducing the exploratory novelty calculation

This standalone Python listing is research methodology only; it adds no game API and changes no game behavior. Python 3.14 was used for the reported run. Catalog order is gear, companions, relics. The RNG is seeded once for all sequential accounts.

```python
import random
import statistics

rng = random.Random(20261005)
sizes = [[7, 7, 7, 4], [3, 3, 3, 1], [3, 3, 3, 1]]
daily = [6, 4, 2]
observations = {day: [] for day in [7, 30, 90]}

for account in range(2000):
    owned = [set(), set(), set()]
    pity = [0, 0, 0]
    new_by_day = []
    for day in range(1, 91):
        new = 0
        for banner, count in enumerate(daily):
            for draw in range(count):
                roll = rng.random()
                tier = (3 if pity[banner] >= 89 or roll < 0.01
                        else 2 if roll < 0.10
                        else 1 if roll < 0.32 else 0)
                pity[banner] = 0 if tier == 3 else pity[banner] + 1
                item = (tier, rng.randrange(sizes[banner][tier]))
                if item not in owned[banner]:
                    new += 1
                    owned[banner].add(item)
        new_by_day.append(new)
        if day in observations:
            observations[day].append(
                (sum(new_by_day[-7:]) / 84,
                 *(len(items) for items in owned))
            )

for day, samples in observations.items():
    novelty = round(100 * statistics.mean(s[0] for s in samples), 1)
    uniques = [round(float(statistics.mean(s[i] for s in samples)), 1)
               for i in [1, 2, 3]]
    print(day, novelty, uniques)
```

Expected output: `7 34.6 [15.4, 7.6, 6.1]`, `30 1.8 [22.4, 9.9, 8.9]`, `90 0.1 [24.6, 10.0, 10.0]`. R01/R43 must replace simplified ownership-only modeling with implemented economy/usefulness and complete spending cohorts before tuning or fairness decisions.

## Explicit limits and unresolved decisions

There is no verified 2026 global idle-RPG profit ranking in this research. We do not infer one from small-country automated charts. Exact retention thresholds, budgets, final drop rates, booster limits, multiplayer population requirements and shop prices need testing. Asynchronous multiplayer is a proposed adaptation, not proof of retention or revenue. No Android build or new gameplay was implemented by this documentation task.
