# Mossgate and a game you can play on the way to the bus

The main screens should tell players what's happening, what they earned and
what they can tap next. Short labels take priority over descriptive paragraphs.
Rules, stories and contribution breakdowns live in **Field journal → Field
guide**. They are optional and do not gate rewards or actions.

Expedition results now show the outcome, gold, route/stages and whether stew
was used. Route choice keeps duration, the current first/repeat reward, risk
and preparation visible. Practice keeps NPC disclosure, the selected role's
effect and a short result. Fishing keeps its next catch, ingredients, recipe
and optional reel action. The HUD shows identity, health/currency and current
activity; important rewards briefly appear, while save errors remain visible.

## An original font

**Mossgate** is built from the project's own letter drawings, not another font.
Its proportional rounded strokes, open counters, high lowercase and quiet
curves suit the warm low-poly trail world. The hooked `l`, barred `I`, angled
`1` and slashed `0` reduce ambiguity at phone sizes. Tabular numbers keep
changing health and timers steady. Regular is for reading; semibold is for
actions and headings. No decorative swashes are needed to read a button.

The files are `assets/fonts/Mossgate-Regular.ttf` and
`assets/fonts/Mossgate-Semibold.ttf`, with a redistribution license beside
them. `tools/fonts/build_mossgate.py` contains the original drawings and
reproducible outline builder. It uses Python, fontTools and Shapely; these
tools are only required to rebuild the font, not to run the game.

The first release has 229 glyphs, including printable ASCII, common accented
Latin names and UI symbols. System font fallback remains enabled for other
scripts. Full international font coverage and real Android readability remain
open; the font is currently verified through Godot's actual 405 × 720 renders,
glyph coverage checks and the game's touch/layout tests.

Keep key information readable on a small phone. Body copy on the three new
activity screens is 24 logical pixels; titles are 32 and buttons 22. The sheet
surface is opaque so underlying navigation cannot show through the lettering.
The shared Back action is short, leaving room for titles and wallet totals.
