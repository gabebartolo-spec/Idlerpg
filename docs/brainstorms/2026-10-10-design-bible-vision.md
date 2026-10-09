# Brainstorm: design bible vision interview (2026-10-10, big)

An interview with the director to gather the vision for a new design bible, laid out the way the
MERCS bible is (a short director-authored vision, then one document per job). This file records
what the director said. It does not change `DESIGN_BIBLE.md`; where an answer replaces a rule in
that document, the conflict is listed under "Conflicts with the current bible".

## The idea (director's words)

"A game streamlining the WoW experience with an Idle Slayer bent. It should feel like constant
progress is being made and lots of enticing loot. Should be a fun game to play in short bursts
and in longer PvP sessions it can be a relaxed but competitive social environment."

"It's effectively an auto battler in an MMO skin."

## The moment in play

**Short burst (a few minutes, every few hours).** The player collects offline earnings, sorts
through what looks good enough to equip and sells or salvages the rest, sets new targets and
sends the adventurer out again, collects a few achievements and free gifts, perhaps buys
something in the shop, then logs out for a few hours and returns to repeat the process.

**Long session.** Raids, guild battles, faction wars, events and party levelling. Low commitment.
Chat rooms.

## Decided

Each line is something the director said or chose.

### Core test

- A feature belongs if it passes three questions: does it fit the game, would it be profitable,
  and is the content rewarding for zero-spend players.

### Combat and automation

- Auto pathing and auto attack are always on.
- Power buttons and potions start manual, then gradually automate until most of the process is
  hands-off.
- Automation is free and unlocks in the early game. (The director first said it would be paid
  with real money, then chose free after the conflict with zero-spend play was raised.)
- No raid or boss fight requires active participation; all of it can be automated, potions
  included.

### PvP, spending and fairness

- A PvP fight is won beforehand: better gear, a more offensive build, better companions.
- Spending buys an edge in PvP, and how big depends on how much is spent.
- Lots of cooperative battling gives weaker players a way to contribute without needing to carry.
- Leaderboards ensure players are matched against similarly well-geared players.

### Long-term progression

- Prestiges, rotating events, battle passes, weapon masteries and similar layered tracks.
- Anything attained with money is retained through a prestige.

### Loot and builds

- An exciting drop has a beautiful model and item design, strong power, and enables a potent
  build archetype.
- Archetypes come from elemental synergies between items. Director's example: Thunder Crown
  changes damage to lightning; a ring makes lightning damage bounce; a staff adds fire to the
  lightning; "then suddenly you have a lightning/fire build and more synergies become possible".

### Classes and characters

- Class decides skills and abilities.
- Six classes: Mage, Berserker, Rogue, Cleric, Archer, Shieldwarden.
- Players may make as many characters as they want, within reason, but play one at a time.
- What characters share across an account follows "whatever is normal and fair" for the genre.
  Working default, for the director to confirm: purchases and collections are account-wide;
  earned power (level, skills, equipped gear) is per character.

### Chests, tokens and materials

- The best gear comes from chests.
- Bosses and raids give chest tokens; otherwise tokens are bought.
- Bosses and raids also drop many crafting materials.
- Materials upgrade weapons, craft potions and fund guild contribution, among other uses.

### Companions

- A companion is a pet, obtained through the normal gacha and event process.

### Targets and the world

- The player picks a questing area and a purpose: grind XP, complete bounties, grind crafting
  materials, or fight in the faction war.

### Faction war

- Three factions to start, in the Horde-versus-Alliance mould, coloured red, blue and yellow.
- A perpetual war over neutral territories.
- Lobbies reset about every week with a new leaderboard; placement gives free rewards.
- Factions that conquered the most territories get bigger prizes each reset.
- Each faction has a unique starting zone. Factions differ in starting-region design, NPCs,
  location, colour theme and some lore; the three starting areas are functionally the same.
- PvP areas unlock as the player levels. Faction PvP is always optional for players who only
  want to level and grind.

### Left out on purpose

- No trading. No player can pass their items to another player to boost them; the director's
  reason is that a boosted player has no incentive to spend money.
- No content that demands active participation (see Combat and automation).

## Rejected and why

- **Automation sold for real money.** The director's first answer. Dropped by the director after
  it was tested against "do not force purchases, trivialize free play" in the current bible and
  against the low-commitment vision: a free player would never get the idle game.

## Conflicts with the current bible

These answers replace rules in `DESIGN_BIBLE.md`. They take effect when the director confirms
them in the new bible, not through this file.

| Director's answer | Current bible |
|---|---|
| Manual power buttons and potions early on | "There is no movement joystick, attack button, dodge button, spell rotation or tap-to-win combat" (1.2) |
| Spending buys an edge in PvP | "Normalized ranked PvP excludes paid power; a separate progression arena must disclose power differences" (1.5) |
| Six classes | "Start with one class until the loop is proven" (4.3); the prototype's one class is the Wayfarer |
| Many characters per account | "The first version is about attachment to one main adventurer" (4.1) |
| Crafting materials with several uses | "elaborate crafting trees" listed under non-goals (2) |
| Battle passes in the long tail | "battle passes/live ops before retention exists" listed under non-goals (2) |
| Voxel style under consideration | "voxels may inform individual props but are not the default visual language" (visual decision, 9 October) |

## Open questions for the director

1. What does a prestige reset, and what does the player gain from it, beyond keeping anything
   bought?
2. What happens to the prototype's Wayfarer class now that there are six named classes?
3. Confirm the account-wide versus per-character split, and whether alts help each other.
4. Art style: stay with painterly low-poly, or move to voxel? The director is "interested in but
   not married to" voxel because it is "slightly more novel". All existing models, including the
   three Tripo legendary pieces, are low-poly.
5. Names, looks and lore for the red, blue and yellow factions.
6. How many of the six classes ship first.
7. Not yet discussed: the world's tone and lore, guilds in detail, the shop's contents, chat room
   rules and moderation, and how much watching the adventurer in the 3D world matters.

## For the decision log

The project has no decision log yet. Ready to paste when one exists:

- 2026-10-10 · Director · Core test: fits the game, profitable, rewarding for zero-spend players.
- 2026-10-10 · Director · Auto pathing and auto attack always; power buttons and potions manual at first, automated free in the early game.
- 2026-10-10 · Director · No raid or boss requires active participation.
- 2026-10-10 · Director · Spending buys PvP power in proportion to the amount; fairness comes from cooperative content and gear-matched leaderboards.
- 2026-10-10 · Director · Long tail: prestiges, rotating events, battle passes, weapon masteries. Purchases survive prestige.
- 2026-10-10 · Director · Builds come from elemental item synergies (Thunder Crown example).
- 2026-10-10 · Director · Classes: Mage, Berserker, Rogue, Cleric, Archer, Shieldwarden. Class decides skills and abilities.
- 2026-10-10 · Director · Many characters per account, one played at a time.
- 2026-10-10 · Director · Best gear comes from chests; tokens from bosses, raids or purchase. Bosses and raids also drop crafting materials.
- 2026-10-10 · Director · Companions are pets from gacha and events.
- 2026-10-10 · Director · Three factions (red, blue, yellow), perpetual territory war, weekly reset with leaderboard rewards, optional PvP, functionally identical starting zones.
- 2026-10-10 · Director · No trading or item transfers between players.
