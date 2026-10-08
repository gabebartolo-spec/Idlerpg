# Adventurer life: R11–R14 desktop prototype

These four slices are implemented with desktop regression coverage. They remain VERIFY until phone readability/performance and player reward-recognition sessions are recorded.

## Earned draws

Ordinary simulated time earns one summon token per 12 minutes: 120 per day, or 12 gross draws at the current cost. The integer microsecond remainder survives saving. Watched and offline time use the same clock; the existing seven-day offline cap limits a single return to 840 tokens. Quest completion frequency does not increase income. Checkpoints settle the difference between the simulation's cumulative earned total and the wallet's persisted claimed cursor, preventing repeated returns from paying twice. Older saves begin with zero accrued income; there is no retrospective time grant.

The existing chosen-item route remains available with its 30-pull guarantee. Starting tokens, duplicate refunds, salvage and earned tokens are separately accounted for. [Earned-draw tables](economy/earned_draw_tables.md) and their JSON report cover 1/7/30/90/180 days for free/light/high hypothetical spending cohorts. Each account receives real earned income; supplemental income scenarios add 0 or 120/day. One seed per cell is sensitivity evidence, not a population or fairness study. Immediate usefulness uses the stated attack/HP autopilot score and cannot establish player enjoyment. The historical R10 results remain unchanged.

The wallet shows time until the next earned token, rounded upward and refreshed while the sheet is open. It resets on earning without requiring a summon or another check-in.

## Permanent field journal

The Greenway volume has 15 entries: five places, four enemies, three existing world items and three authored discoveries. Unseen entries show acquisition clues. Three goblin victories reveal a campfire mark; a wolf victory reveals moon tracks; four Briarling victories reveal the amber pool. Each authored discovery grants ten gold once, and enters the chronicle for return highlights. Entries survive selling gear. Legacy inventory and progression seed supported discoveries without granting old rewards again.

Chronicle discovery links select and scroll to the relevant journal entry. Newly discovered entries refresh an open journal while preserving the selected destination.

## Identity

The Adventurer sheet edits a local name (24 characters, controls removed), previews three free accent colors, and equips two earned titles. The opening errand earns Greenway Scout; the first boss victory earns Thornbreaker and the gold keepsake pin. The watch view and return report show the name, and the model shows the selected accent and earned pin. These grant no combat bonuses. A future public profile still needs server moderation; local name filtering is not a social safety implementation.

## Companion choices

Frost Ranger adds five attack, Sun Cleric adds 24 health, and Rare Marsh Witch heals four after a kill. Ancient Warden retains its three attack, 16 health and travel bonus. Specialized companions now exceed the Legendary all-rounder in their own niche; each trades away the other benefits. Tests compare actual boss damage, survival of the same burst, and recovery after the same goblin encounter.

Each of the three specialists earns one authored campfire memory on crossing bond level two (ten shared victories). The chronicle records it permanently with a companion link; watched play adds a short ground pulse. Existing bond scaling and duplicate ownership rules remain unchanged. Offline progression produces the same saved outcomes, and reload/further bond growth cannot repeat a story.

## Verification

Save format 12 adds earned income and its wallet cursor (10), the journal (11), and identity (12). Existing versioned migrations, future-save protection and backup handling remain in force. Focused tests cover time/check-in parity, seven-day caps, replay settlement, journal permanence and old-save rewards, name/title safety, stat invariance, companion fights, bond stories and JSON restoration. The full regression run and actual rendered 405×720 screenshots complement these checks. Device performance, touch/keyboard interaction, silhouette recognition and player desirability remain open.
