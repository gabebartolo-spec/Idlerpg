# First shared asynchronous raid

The persistent service resolves **The Hollow Warden** for three independent accounts. Real Godot HTTP clients and playable More → Guild controls demonstrate the shared guild → role preparation → result → private chest loop. Deployment and physical phone gates remain open; this is not yet the completed playtest release.

## A short visit, then leave

The guild leader starts a raid. Three members commit one server-owned build each to **damage**, **protection** and **preparation**. The preparation window is 24 server-clock hours. There is no synchronous attendance, reaction input or paid revival. A participant may change to an unoccupied role or withdraw before the deadline; enrollment and stats freeze at the deadline. New members cannot replace anyone after lock.

Leaving retains an existing commitment and personal rewards. A committed account cannot enroll in another unresolved raid until withdrawing before the deadline or the original raid settling. A departing leader does not reset the raid. Offline enrolled members participate. A guild member or committed participant can request the result after the deadline; the service catches up the deterministic fight transactionally. Client integration will check automatically on return; the HTTP resolve action is not a manual combat decision.

## Useful roles

Build stats are snapshotted at enrollment; boss/reward rules at raid creation. No local equipment, clock, attack, HP, uploaded victory or reward is accepted.

| Build | How earned online | HP | Damage-role hit | Protection per round | Preparation heal |
|---|---|---:|---:|---:|---:|
| Trail | New account | 45 | 12 | 10 | 5 |
| Thornward | 40 earned supply gold | 55 | 10 | 16 | 5 |
| Keeper | 60 earned supply gold | 50 | 18 | 12 | 7 |

Other roles hit for 3. The Warden has 120 HP, strikes for 30, starts with 8 party-wide armour and three seals. Preparation breaks one seal per round, removes armour after all seals break and heals surviving party HP. Protection prevents part of each strike. The fight ends within ten rounds. This is an initial encounter, not completed multi-day progression or a claim of enjoyable balance.

Three Trail builds win. Removing any one role loses. Keeper damage and Thornward protection still need the developing Trail preparation member. Recaps record damage, prevented damage, healing and broken seals per participant, plus compact round checkpoints. Local NPC practice remains separate.

## Rewards and retry safety

Victory secures a personal chest per committed participant: **60 supply gold and the Warden lantern appearance**. Failure secures 15 gold per participant, preserves builds/ownership and permits another free preparation window. Withdrawing before lock earns no chest. Opening credits once even across simultaneous devices or fresh retry keys. Repeated victories add gold without duplicate appearance copies. Leaving never removes rewards.

The Warden lantern has original source geometry in `tools/art/models/lanternwood.py`, a game model/icon and Wardrobe preview. It has no combat stats. Authenticated server ownership restores it into the local wardrobe for offline use and direct Wear after opening. The live capture earns it against the real disposable service; locked preview fixtures do not fabricate ownership.

## Versioning and verification

Schema 2 adds raid tables transactionally to schema 1. Accounts, sessions, wallets, guilds, outings and ledgers remain intact. Unknown newer schemas are refused. Unknown resolver versions stay unresolved and grant nothing. Back up before upgrading; the old binary refuses schema 2 on startup.

Run `python -m unittest server.test_service server.test_raids -v` for 20 scenarios. Coverage includes offline members/restart, departure, early/late/foreign requests, forged stats/results, occupied roles, unearned builds, cross-guild locks, withdrawal/no-show failure, concurrent settlement/opening, retained stats, incompatible versions, schema upgrade, three build compositions and role removal.

`python -m server.verify_client --godot <binary> --project <isolated-project>` creates three Godot clients against one listening service, commits starter roles, observes leader departure, wins and opens/reopens all personal chests. **Only the disposable test server accelerates time** (24 hours become ten seconds); production uses real server time and a 24-hour window. This proves communication/settlement, not phone usability, participant access or human enjoyment.
