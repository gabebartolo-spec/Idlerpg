# Idle RPG — Art Style Guide

**Status:** Production source of truth  
**Primary platform:** Android portrait  
**Rendering target:** Godot 4.7.2 mobile renderer  
**Primary visual reference:** World of Warcraft — stylised, painterly heroic fantasy  
**Secondary references:** RuneScape for efficient/readable geometry; Kingdoms of Amalur for expressive, sculpted shapes  
**Rule:** borrow visual principles, never copy identifiable assets, characters, armour sets, locations, logos, UI, or compositions.

**Current P0 #1 visual task:** use the owner's existing Tripo access to prototype the **Crownblade, Starforged Helm and Titanheart Plate**, clean/import them through Blender into the running game, and show the owner real portrait captures. The [Tripo legendary pilot brief](TRIPO_LEGENDARY_PILOT.md) is the active visual-art priority. Three first-pass Tripo sources have been generated and retrieved; cleanup and hero-fit review are in progress. Owner feedback: the first designs read as **Epic, not Legendary**. A stronger second concept direction awaits review. Keep the shared 'same hand' style and defer all-catalogue generation until the owner has judged three real assets. See [process evidence](TRIPO_PROCESS_LEARNINGS.md).

---

# 1. Visual north star

The game should look like a **small, readable fantasy MMO world you want to leave running beside you**.

The player should be able to glance at the screen and immediately understand:
- where the adventurer is;
- what they are fighting;
- what gear they are wearing;
- whether something rare or important just happened.

The target is **World of Warcraft-inspired heroic fantasy, executed as original mobile-friendly low-poly 3D**. World of Warcraft is the **main visual guide**, not one of several equally weighted looks. Use its approachable, hand-painted fantasy sensibility: expressive silhouettes, bold colour grouping, exaggerated equipment, distinctive enemies, lively zones and an inviting sense of adventure. Keep the production geometry, texture complexity and rendering costs appropriate for Android.

Reference hierarchy:
- **World of Warcraft — primary:** overall character and creature art direction, expressive armour and weapons, painterly colour/material treatment, memorable landmarks, readable fantasy zones and visual progression from humble gear to dramatic legendary loot. Think recognisable in-game stylised art, **not** an attempt to reproduce WoW's cinematic realism or its UI.
- **RuneScape — secondary production discipline:** simple/efficient shapes, clear interactable world spaces and lower asset cost; **not** the primary surface style or character proportions.
- **Kingdoms of Amalur — secondary form inspiration:** broad curves, sculpted heroic shapes, expressive fantasy ornament and restrained magical accents, used where they reinforce WoW-like readability.
- **Voxels — optional selective technique only:** faceted props or experiments are welcome if they match the overall painterly heroic style. **No wholesale shift to a uniform cube-grid aesthetic** without a separate visual comparison and owner decision.

**Non-negotiable:** The result must have its own character and world identity. Do not copy Blizzard characters, races, armour sets, recognisable weapons, locations, faction motifs, interface elements, logos, texture designs or compositions. Visual *principles* are the reference, not assets to reproduce.

---

# 2. Core principles

## 2.1 Readable before detailed

At phone size, silhouette wins.

Prefer:
- broad weapon shapes;
- simple armour masses;
- oversized readable helmets/shoulders where appropriate;
- clear enemy proportions;
- strong separation between character, enemy and ground.

Avoid:
- tiny engravings;
- noisy materials;
- micro-detail that vanishes on a phone;
- realistic cloth folds;
- cluttered terrain.

## 2.2 Chunky, not blocky

Low-poly does not mean primitive cubes everywhere.

Shapes should have:
- softened bevels;
- broad curves;
- deliberate tapers;
- slightly exaggerated proportions;
- simple but authored silhouettes.

Do not make the world look like placeholder geometry once production assets begin replacing greybox forms.

## 2.3 Warm, painterly fantasy, not grimdark

The default world should feel adventurous and inviting. Take WoW's clear large-scale colour grouping as inspiration: each region should have a recognisable palette and lighting mood, with readable warm/cool separation and vivid colours used with restraint at the right focal points.

Use:
- warm earth;
- mossy greens;
- slate greys;
- muted blue;
- parchment/cream;
- region-specific sky, terrain and architecture colour families;
- occasional saturated magical accents.

Avoid:
- brown-on-brown realism;
- generic neon mobile gradients;
- constant purple rarity glow;
- green UI tint everywhere;
- oppressive grimdark lighting.

Dangerous areas can become colder, darker or more saturated, but the base game should remain pleasant to watch.

## 2.4 Exaggeration carries information

Make gameplay-visible equipment visibly different.

A stronger sword should generally:
- have a stronger silhouette;
- be longer/wider or more unusual;
- use more deliberate accent shapes;
- look meaningfully different from starter gear.

Do not rely only on colour changes.

## 2.5 One world, not asset-pack soup

**Owner art-direction rule (9 October 2026): every region may have its own identity, but the entire game must look as if it were drawn by the same hand.** This means a snowfield, a cursed swamp, a woodland and a city can have wholly different climates, architecture, flora, enemy types and lighting moods while sharing the same deliberate visual grammar. Distinct biome does not mean distinct art style.

Generated assets must be revised until they match this guide.

Reject assets that:
- look photorealistic;
- use wildly different proportions;
- have anime-gacha rendering;
- use glossy PBR realism;
- default to uniform block-grid/Minecraft-like voxel art (selectively faceted models are fine);
- look like generic Unreal fantasy;
- imitate one reference game too literally.

---

# 3. Character proportions

## Adventurer

Target:
- roughly 5.5–6 heads tall;
- slightly oversized head and hands for phone readability;
- broad torso;
- sturdy feet;
- weapons 10–20% oversized relative to realistic scale.

The character should feel like a **small heroic figurine**, not a realistic human.

Face detail should stay minimal:
- readable eyes/brow;
- simple nose/mouth;
- optional simple beard/hair masses;
- no need for realistic facial rigging early.

## Enemies

Each enemy family needs a silhouette rule.

Examples:
- goblins: narrow torso, long forearms, oversized ears/head, crooked weapons;
- wolves: broad shoulder wedge, low profile, exaggerated snout;
- heavy enemies: wide stance, large upper body, slow silhouette;
- ranged enemies: narrower frame, obvious ranged weapon;
- bosses: 25–60% larger than ordinary enemies with one unmistakable visual motif.

---

# 4. Equipment language

## Weapons

Weapons are highest-priority visible gear.

Shape progression:
- Common: practical, simple silhouette.
- Rare: stronger profile, one secondary material/accent.
- Epic: distinctive silhouette, ornamental or magical element.
- Legendary: unmistakable profile plus restrained magical treatment.

Magic should be readable without becoming a particle storm.

## Armour

Armour visuals should change broad body regions:
- head: helmet/hood/hair silhouette;
- chest: torso bulk, coat/plate silhouette;
- legs: lower-body mass/colour;
- hands: gloves/gauntlet shape;
- feet: boot silhouette;
- off-hand: shield/tome/focus;
- accessory: usually not directly visible unless deliberately iconic.

Do not require a unique full character model per item. Build modular visual pieces.

## Rarity presentation

Rarity colours are secondary information, not the design itself.

Suggested direction:
- Common: neutral iron/leather/wood;
- Rare: cool steel/blue accent;
- Epic: restrained saturated accent;
- Legendary: warm gold/ivory or item-specific magical accent.

Never turn the entire item into a glowing rarity colour.

---

# 5. Environment language

## A single visual handwriting across the world

**These are global invariants for every region and every source of art** (Blender models, AI-assisted concepts, textures, UI previews and effects):

- **Shape language:** soft, authored low-poly forms, deliberate tapers/bevels, heroic exaggeration and readable silhouettes; avoid abrupt shifts from sculpted curves to raw voxel cubes or from stylisation to realism.
- **Proportions and detail budget:** the same heroic character anatomy, item scale, creature silhouette discipline and broad-to-fine detail hierarchy; never make one zone's models dramatically denser or more intricate simply because a different generator made them.
- **Surface treatment:** matte/rough, painterly colour grouping, broad painted-looking variation and restrained highlights; no sudden plastic gloss, realistic photo textures, radically different outlines, or high-frequency noise.
- **Lighting vocabulary:** a coherent approach to key/fill, material response, emissive magic and readable faces/gear. Individual regions can shift time of day, warmth, contrast and mood *within* this shared approach.
- **Colour handling:** use the shared palette system and harmonised saturation/contrast rather than independently invented material colours. Region palettes may be vibrant, dark, icy, warm, sickly or magical, but must have the same painterly logic.
- **Animation and VFX:** the same readable motion timing and compact, authored magical effects; do not introduce a photorealistic or neon-heavy VFX style in a single biome.
- **Scale and composition:** compatible prop scales, architecture exaggeration, ground texture vocabulary and portrait-camera readability.

A region can own its **biome palette, architecture motifs, vegetation, wildlife, enemies, landmarks, weather, lighting mood and environmental storytelling**. These are expressions of the one world, not exceptions to the shared rules. Avoid applying exactly the same palette to every region in the name of consistency: **unity of treatment, diversity of place**.

### Shared reference sheet before the next large asset batch

Create and maintain one **approved master style sheet** from *our own* finished assets, not images taken from WoW. Use the same hero, common/legendary weapon and armour, one creature, one tree, one rock/building and one complete zone vignette as visual anchors. Record the approved proportions, colour/material approach, bevel/shape language and neutral review lighting. If those existing assets are inconsistent, first author/rework the smallest representative set and get approval rather than treating inconsistency as the new standard. This reference sheet is a required production deliverable, **not claimed to exist yet**.

For each new biome, prepare a brief of its unique motifs and limited local palette, then compare its new assets **beside** the approved anchors and at normal Android portrait scale under equivalent neutral lighting, followed by a native biome-lighting capture. A new region passes only when it is clearly a different place **and** visibly belongs in the same game.

## Zones

Zones should be small, authored dioramas with clear paths and landmarks.

Each zone needs:
- one dominant terrain colour;
- one secondary vegetation/material family;
- one landmark silhouette;
- clear quest/combat spaces;
- limited prop vocabulary reused deliberately.

## Buildings

Fantasy buildings should use:
- exaggerated roof pitch;
- thick beams;
- broad stone courses;
- chunky doors/windows;
- slightly irregular silhouettes.

Avoid realistic medieval architecture detail that costs performance and adds no readability.

## Trees and rocks

Trees:
- 6–12 sided trunks;
- clustered foliage masses;
- distinct canopy silhouettes by biome.

Rocks:
- faceted;
- broad planes;
- slightly exaggerated angular forms;
- no noisy scanned surfaces.

---

# 6. Materials and textures

Default material style:
- matte to lightly rough;
- **painterly, hand-authored-looking colour breakup on broad readable forms** (WoW-like in spirit, with wholly original patterns and textures);
- subtle gradient/vertex colour acceptable, including inexpensive colour blocking for low-poly models;
- restrained specular;
- outlines and surface accents used to reinforce silhouettes and material identity, not noisy procedural detail.

Avoid:
- glossy plastic;
- photogrammetry;
- high-frequency normal maps;
- realistic skin;
- chrome-like metal outside deliberate magical gear.

Texture detail should survive downscaling.

If a texture is invisible at normal portrait viewing size, it probably should not exist.

---

# 7. Lighting

Default outdoor look:
- warm key light;
- soft cool fill;
- readable shadows;
- moderate contrast;
- no crushed blacks.

Characters and enemies must remain readable against terrain.

Magic can use emissive accents, but emissive effects should remain local.

Watch mode should be visually comfortable for long periods.

---

# 8. Animation

Animation should favour readable action over realism.

## Movement

Adventurer:
- slightly bouncy run;
- clear foot rhythm;
- weapon/gear secondary motion later.

Enemies:
- movement style should reinforce silhouette and role.

## Combat

Attacks:
- clear anticipation;
- fast impact;
- short recovery;
- exaggerated weapon arc;
- no complex combo choreography needed early.

Automatic combat still needs to look intentional.

The player should be able to tell:
- who attacked;
- what kind of attack occurred;
- who got hit;
- when something died.

---

# 9. VFX

VFX should be:
- short;
- high-contrast;
- low-particle-count;
- readable on phone;
- tied to real simulation events.

Examples:
- small slash arc;
- brief hit spark;
- compact loot glint;
- short level-up burst;
- restrained rarity reveal.

Avoid:
- screen-filling bloom;
- constant combat particles;
- long lingering trails;
- effects that obscure characters.

---

# 10. Camera composition

Primary watch camera:
- elevated third-person/three-quarter view;
- character large enough to read equipment;
- enough surrounding space to understand destination/context.

Combat camera can tighten slightly but should not become cinematic every fight.

Portrait composition should preserve:
- useful world space in the centre;
- lightweight status at top;
- management drawers at bottom.

Do not design scenes around widescreen first and crop them later.

---

# 11. UI visual language

The UI should feel adjacent to the world, not like a separate sci-fi dashboard.

Use:
- sentence case;
- restrained panels;
- readable typography;
- modest corner radii;
- thin separators;
- warm neutral surfaces;
- rarity accents only where useful.

Avoid:
- all-caps headers everywhere;
- generic green accent;
- dozens of pills/chips;
- gradient-heavy mobile-gacha panels;
- glowing borders around every object;
- dense MMO hotbars;
- number vomit.

The world remains the default screen.

Mossgate is the game's original rounded typeface, drawn from the project's own
letter coordinates. Use its regular weight for reading and semibold for actions
and titles. Keep normal play copy brief; stories and detailed rules belong in
the optional Field guide. See `docs/TYPOGRAPHY_AND_COPY.md` for the source,
coverage and phone verification limits.

---

# 12. Generated asset rules

Whenever AI-generated concepts/assets are used:

1. Start from this guide **and the approved master style sheet**. Do not generate a new region with an isolated stylistic prompt.
2. Keep the same stable style instructions for every asset batch: original WoW-inspired painterly heroic fantasy; mobile-friendly authored low-poly shapes; common proportions, materials and surface finish; same level of detail. Add **biome content** to the prompt without rewriting these global rules.
3. Generate one asset family at a time, with the region's palette/motifs recorded separately from global style.
4. Compare silhouettes, character/prop proportions, mesh density, palette, surface treatment and render lighting beside existing approved anchors, not just inside that region.
5. Reject or rework outliers even if individually attractive; never ship the telltale differences between separate AI image/model generators.
6. Prefer transparent-background character/equipment concepts where useful.
7. Rebuild or simplify generated concepts into game-ready low-poly assets where necessary.
8. Never ship obvious artefacts, gibberish text, malformed anatomy, copied logos, or inconsistent perspective.

Generated concept art is direction, not automatic final production art.

---

# 13. Technical budgets

Prototype targets, subject to phone profiling:

## Characters
- ordinary character/enemy: roughly 1k–4k triangles;
- important boss: up to roughly 8k–12k triangles if justified;
- modular equipment should reuse rigs/materials where possible.

## Textures
- prefer 256–512 px for ordinary props/equipment;
- 1024 px only where the camera genuinely benefits;
- atlas related small props where practical.

## Materials
- minimise unique materials per character;
- prefer one main material plus optional emissive/accent;
- avoid expensive transparency.

## Effects
- keep particle counts low;
- avoid full-screen post-processing dependencies.

These are starting budgets, not sacred numbers. Android performance decides.

---

# 14. First production asset set

Before expanding world content, build one coherent test family:

### Adventurer
- base body;
- starter tunic;
- starter sword;
- Goblin Cleaver;
- Wolfskin Hood;
- one chest armour visual.

### Enemies
- goblin;
- grey wolf.

### Environment
- one Mossgate house;
- one goblin camp prop family;
- one wolf-den rock set;
- one tree family;
- one rock family;
- one path/ground material family.

### Effects
- melee hit;
- loot pickup;
- level-up.

If these pieces do not look like they belong in the same game, stop and correct the style before generating more.

---

# 15. Approval test

**Style checkpoint before another large asset batch:** compare the current adventurer, a distinct armour set and a weapon at common/legendary tiers, one enemy and one complete outdoor vignette at real Android portrait viewing size. Check for a coherent WoW-inspired painterly fantasy impression, unique designs, unmistakable gear/silhouette differences and stable frame performance. Build only the smallest representative slice before committing to a mass rebuild. This is a **visual direction and future-work criterion**, not a claim current assets have already passed.

An asset is approved only if it passes all six:

1. **Readable:** identifiable instantly on a phone.
2. **Consistent:** passes the *same-hand test* beside assets from **other regions**: compatible shape, proportions, painted finish, lighting and detail density.
3. **Distinctive:** region-specific creatures, flora, landmarks and mood are recognisable without looking like a different game's art.
4. **Original:** not recognisably copied from a reference game.
5. **Useful:** communicates gameplay/state, not just decoration.
6. **Cheap enough:** appropriate for a mobile game that may remain on-screen for long watch sessions.

Before signing off a **new region**, perform a side-by-side review of its hero/enemy encounter, major prop and backdrop next to at least one established region at neutral matching lighting, then the intended local mood. Record whether it passes the same-hand test and any rework needed. If either portrait readability or art cohesion fails, do not mark the region's art polished.

When in doubt, simplify.
