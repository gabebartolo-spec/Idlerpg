# Management screens and touch rules (IRPG-R00)

Gear, talents and gacha are bespoke sheets built on one frame and one set of touch rules.
The gear screen came first and is described in most detail; talents and gacha follow it.

**Status:** implemented and passing synthetic-touch tests. **Not yet verified on a phone.**
The Android retest in the checklist at the end is what closes R00.

## The fault it answers

On 5 October 2026 the owner reported that on Android the gear menu could not be scrolled back
up after scrolling down. That could not be reproduced on a desktop: Godot's `ScrollContainer`
only drag-scrolls when a real touchscreen is present, so its touch behaviour cannot be
exercised here at all. The exact cause on the device is therefore **not confirmed**.

What the old drawer did that makes the fault plausible:

- The list was a `ScrollContainer` full of `Button`s. A swipe that starts on a button is
  contested between the button and the container.
- The list window was 160 px tall on a 1280 px canvas, about 2.8 rows, at the very bottom of
  the screen where Android's gesture bar also takes swipes.
- Rows were 56 px tall and the drawer buttons 31 px, roughly 5 mm and 3 mm on a phone.

Rather than tune behaviour that cannot be tested off-device, the list no longer depends on it.

## Touch rules

Implemented in `src/ui/touch_list.gd`, used by every list on the gear, talent and gacha sheets.

1. **The list owns every touch that starts inside it.** Rows and the buttons in them never
   receive input themselves, so nothing can intercept a swipe part-way.
2. **A touch that moves more than 16 px is a scroll, in either direction.** One that does
   not is a tap on the row under the finger.
3. **A swipe never presses anything.** A tap presses exactly one row, once.
4. **The list keeps its position** when rows are rebuilt (after equipping, selling, new loot)
   and when the screen is closed and reopened. It returns to the top only when the slot
   filter changes or the content now fits.
5. **Touch targets are at least 80 px** on the 720 px canvas, about 8 mm on a phone
   (`TOUCH` in `src/ui/ui_style.gd`).
6. **Actions do not scroll.** Anything you act with stays pinned and on screen.
7. **Sideways swipes and cancelled touches never select rows.** Losing focus cancels
   a pending gesture. Hiding a list stops its flick momentum while preserving its position.
8. **Escape returns to the adventure** from a management sheet.
9. **Filtering away the selected gear clears its actions.** Switching to All keeps a
   selection that is still visible, so an off-screen item cannot be equipped by mistake.

## Layout

A sheet over the lower two-thirds of the portrait screen. The world stays visible above it,
and tapping the world closes the sheet.

```
+------------------------------------------+
|  HUD: name, level, health, activity      |   world stays visible (top 34%)
|                                          |   tap here = back to adventure
|            (the adventurer)              |
+==========================================+
| Gear                  [Back to adventure]|   header: totals, one way out
| Attack 8 · Health 56                     |
| [All][wpn][shd][head][chest][legs]...    |   slot strip: shows what is worn,
| All gear · 28 items                      |   tap to filter by slot
| +--------------------------------------+ |
| | icon  Crownblade         +10 attack  | |   list: 96 px rows, name in rarity
| |       Legendary weapon   +4 health   | |   colour, change against what is worn
| +--------------------------------------+ |   (green better, red worse, gold worn)
| | icon  Moonsteel Blade    +5 attack   | |
| +--------------------------------------+ |   scrolls both ways, flicks carry on
| ---------------------------------------- |
| Moonsteel Blade · +7 attack · +2 health  |   pinned comparison for the selection
| Replaces Iron Sword: +5 attack · +2 hp   |
| [   Equip   ] [ Sell +70g ] [Salvage +5] |   pinned actions, 36 px above the edge
+------------------------------------------+
```

- **Browsing:** items sort by slot, then rarity, then name. Each row answers "is this
  better than what I'm wearing?" without opening anything.
- **Comparing and equipping:** tapping a row selects it. The pinned bar names what it would
  replace and the change. Equip, Take off, Sell and Salvage act on the selection.
- **Filters:** the slot strip is the only filter. Each slot shows the icon of what is worn
  there, so it doubles as the "what am I wearing" summary.
- **Returning to the watch view:** the Back button, or a tap on the world above the sheet.
- **Protection:** locked gear and the last copy of worn gear cannot be sold or salvaged, as
  before; the buttons disable and the comparison line says "Locked".

Look, per `docs/ART_STYLE_GUIDE.md` section 11: warm neutral surface, sentence case, thin
separator, modest corners, rarity colour only on item names, one gold accent for the primary
action and the current selection.

Screenshots from the real scene: `art/review/ui_1_gear_browse.png` to
`ui_4_gear_filtered.png`. Regenerate with `godot --path . -s res://tools/ui/capture.gd`.

## Talents and gacha

Both use the same sheet frame (`src/ui/sheet.gd`): world above, title and Back in the
header, a touch-owned list in the middle, and the selection's details and actions pinned
underneath.

**Talents** (`src/ui/talent_screen.gd`)

- Three branch tabs, then that branch's talents as rows: name, what it does, and its state
  (Learned, Can learn, Needs another talent, No points).
- Tapping a row only selects it. **Learn** on the pinned bar spends the point. The old
  drawer spent a point the moment a talent was tapped, which a stray touch could trigger.
- **Reset talents** sits beside Learn and gives every point back.

**Gacha** (`src/ui/gacha_screen.gd`)

- Two rows of tabs: the view (Summon, Collection, History) and the banner (Gear, Companions,
  Relics). The banner applies to summoning and the collection.
- **Summon:** a results list, and Summon x1 and x10 pinned with their token cost. A pull
  shows its totals and then each new, epic or legendary result as a row.
- **Collection:** what you own first, then what is still to find, dimmed and not
  selectable. Pinned: the selection's details, **Travel together / Rest companion** for
  companions, **Favourite** and **Lock**.
- **History:** the last 40 summons from every banner as a scrolling list; the banner tabs
  are hidden here.

Screenshots: `art/review/ui_5_talents.png` to `ui_9_gacha_history.png`.

## Management polish, 8 October 2026

Fifteen additional improvements, covered by `tests/test_ui.gd`:

1. Gear can be locked or unlocked directly on its comparison bar, including world loot.
2. Locked items carry a visible mark in gear rows.
3. Gear browsing shows the current gold and token balances.
4. The last worn copy explains that it must be taken off before disposal.
5. Retapping the active gear filter preserves selection and scroll position.
6. Summon buttons show token units and disable when the wallet cannot afford them;
   infinite-token debug mode still works.
7. Normal one- and ten-pulls show every result, including common duplicates.
8. Each banner keeps its own last results for the current app session; changing banners
   no longer shows results from the previous banner. These previews are not save data.
9. Owned favourites appear before other owned collection items.
10. Unowned collection items cannot be selected, locked or favourited through stale actions.
11. Collected gear details show attack, health and any item effect.
12. Reset talents disables when there is nothing to refund.
13. Retapping the active talent branch preserves its selection and scroll position.
14. Mouse-wheel input stops an existing flick, respects fractional wheel movement and is
    consumed by the list under the pointer.
15. Touching a moving list stops its flick without selecting a row; a second tap can select.

These changes preserve the earlier gesture fixes. Real Android thumb testing remains open.

## Additional batch of 30, 8 October 2026

The following are additional to the earlier five and fifteen fixes. Regression coverage
is in `tests/test_ui.gd`, `tests/test_save_resilience.gd` and `tests/test_launch.gd`.

1. Gear sorting can put stat upgrades first (both stats at least as good, one better).
2. Gear can be filtered to the equipped items only.
3. Gear favourites can be toggled directly, including world items.
4. Favourites sort ahead of other gear within the current sort priority.
5. The selected gear's copy count is visible.
6. World gear names its source in the comparison details.
7. Zero-token world salvage is disabled; its handler also refuses to destroy the item.
8. Epic and Legendary disposal requires a second press within five seconds; closing,
   changing the selection/filter or locking the item cancels the confirmation.
9. Gear's gold and token balances refresh while the sheet stays open.
10. Programmatic selection cannot expose actions for an item outside the gear filter.
11. Summon results label duplicate copy numbers.
12. History rows name their banner on a separate line.
13. Base rarity odds are published from the same constants used by the draw logic;
    the existing Legendary guarantee remains separate from base odds.
14. Relic details explicitly say they have no gameplay effect yet.
15. Tapping a summon result opens that item's collection details.
16. Collection scroll position is remembered separately for each banner for this app session.
17. Talent branch tabs show learned/total counts.
18. The Learn button states its one-point cost.
19. Owned hunt rewards can be equipped from their hunt row.
20. Boss/hunt state refreshes while open, waits for gestures/flicks to finish, and clears
    selections whose actions changed.
21. Save versions must be numeric whole numbers.
22. Save timestamps must be nonnegative numeric whole numbers.
23. Save writes flush before validation and replacement.
24. Saving refuses to replace newer-version primary, temporary or backup data.
25. Loading refuses a newer save instead of falling back to an older one; the return
    message tells the player to update and says their save is untouched.
26. Repeated damaged saves get distinct numbered recovery archives.
27. Direct saving archives a damaged primary rather than deleting it.
28. Failed archival prevents replacement of the damaged primary.
29. A missing rename source cannot delete the destination; same-path rename is harmless.
30. A failed destination removal prevents a rename from proceeding.

The gear sheet now leaves 26% of the portrait view to the world; gacha leaves 30%; other
management sheets keep 34%. Extra browsing controls and odds occupy that space while
keeping two list rows and pinned actions visible. Android/device verification remains open.

## What is still a plain drawer

- The **Dev** drawer (debug builds only) keeps its small default buttons.
- The **While you were away** report keeps its old panel. Its two buttons are default size.

Two general fixes from the first audit remain: the four bottom buttons are 80 px tall, and
a drawer taller than its slot grows up the screen, not off the bottom edge.

## Tests

`tests/test_ui.gd`, part of `scripts/run_tests.sh`, drives the list and all three sheets with
synthetic touches: scrolling down and back up, from the very end of the list, taps against
swipes, position kept across rebuilds and reopening, the slot filter, equipping, locked gear,
selecting a talent without spending, Learn and Reset, summoning, the collection and history
views, companions, and that every action stays on screen at touch size.

These prove the logic and the layout. They do not prove how it feels under a thumb.

## Phone retest checklist

Record device, Android version and build commit with the results.

- [ ] Gear list scrolls down and back up, including from the very end of the list.
- [ ] A swipe that starts on a row never selects or equips anything.
- [ ] Flicks carry on and stop at the ends without sticking.
- [ ] Swipes near the bottom edge do not trigger the Android home gesture instead.
- [ ] Equip, Sell and Salvage are comfortable to hit and clear of the gesture bar.
- [ ] Slot strip: nine targets across are wide enough to hit reliably.
- [ ] Text is readable at arm's length: item names, the change column, the pinned comparison.
- [ ] Closing and reopening the sheet returns to the same place.
- [ ] Talents: tapping a row never spends a point; Learn and Reset are comfortable to hit.
- [ ] Gacha: the two tab rows are easy to tell apart; summon results, collection and history
      lists all scroll both ways.
- [ ] Collection: about two rows are visible between the tabs and the pinned bar. Is that enough?
- [ ] Suspend and resume with each sheet open.
