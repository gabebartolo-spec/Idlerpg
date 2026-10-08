# A look you get to keep

More → Wardrobe previews five curated appearances: Trail blade, Goblin cleaver,
Wolf hood, Star helm and Briar shell. Collecting their source gear permanently
unlocks the look. The catalog uses existing reviewed model/icon pairs; it does
not assume every gear asset is already ready for cosmetic use. Every source
item is available through the existing free game.

Tap a look to preview it on your current adventurer, including palette and
other worn pieces. A locked look can be inspected but cannot be worn. **Wear
this look** sets a cosmetic override for its slot; **Use equipment look** clears
that override. The same character renderer and attachment points create the
preview and watched adventurer. The preview is still, and only renders while
its screen is visible.

Selling, salvaging or replacing source gear preserves unlocked appearances.
Combat loadouts leave fashion choices intact. Appearance ownership/selection
never contributes health, attack, gear effects, movement, timers, RNG, gold,
income or boss eligibility. An unlocked look can remain visible even if its
functional item is no longer held.

## Ownership and migration

Save format 17 adds `sim.wardrobe`, containing its own schema version,
permanent ownership/provenance and separately equipped appearance IDs.
First acquisition records a `gear:` source once; repeated acquisition is
idempotent. Invalid, unknown, locked or wrong-slot choices fall back to the
functional equipment model.

Old saves seed only from evidence already held: functional gear, known world
discoveries and the permanent gear collection. No gear or rewards are granted,
and no look is auto-equipped. A source sold before this feature without any
remaining inventory/discovery/collection evidence cannot be reconstructed.

Local restoration fixtures merge provenance without replacing earned records
or the chosen outfit. They demonstrate merge/idempotency behavior, not real
paid ownership, billing verification or cross-device authentication. Those
remain gated by R25/R28/R29. There is no purchase flow, paid-only appearance,
dye system or historical replay appearance snapshot in this slice.

## Verification

Tests cover first acquisition, sale/salvage/reacquisition, JSON and atomic
save/reload, legacy evidence, malformed ownership, wrong slots, duplicate
restoration, loadout isolation, full combat-state invariance, watched/offline
parity, locked/owned previews and real world model matching. Standard and
Larger text touch/layout checks cover every slot and its footer actions.
Actual phone-sized desktop renders are inspected. Android rendering cost,
silhouette readability and player desirability/equip observations remain
VERIFY; this is the local R36 foundation, not completion of R21's research.
