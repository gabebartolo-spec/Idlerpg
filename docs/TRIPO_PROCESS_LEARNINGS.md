# Tripo → Blender → Godot: pilot process learnings

Updated 9 October 2026. Working record for the Crownblade, Starforged Helm and
Titanheart Plate pilot. Record observed results separately from intended outcomes.

## Access: API and Studio are different checks

**Problem:** `TRIPO_API_KEY` was configured and authenticated successfully, but
`GET https://openapi.tripo3d.ai/v3/account/balance` returned zero available and
zero frozen credits. The older V2 balance request returned HTTP 403. Studio was
initially signed out. Treating that as "Tripo has no credits" would have been wrong.

**Impact:** API-only automation would have stopped a task that the owner's existing
Studio account can perform. After the owner signed into Studio, its displayed
balance was **24,360**. One Crownblade job reduced it to 24,295; one helmet job to
24,230; the plate job reduced it to **24,165**. Studio displayed the existing
**Max** plan. Total generation spend: **195 existing credits**, no purchases.

**Convention:** check authentication, API wallet and signed-in Studio separately.
Keep the API key in the environment; never print it, copy it into a document,
commit it, or infer Studio entitlement from the API wallet. Use the existing paid
account rather than recommending another paid service or a duplicate subscription.

## References: design a coherent group before 3D generation

The original concept PNGs are in `art/imported/references/`. Crownblade was the
first anchor; the helmet referenced the sword's material/bevel style, and the
plate referenced both. All three use broad painterly metal planes, worn gold,
dark iron and amber stone accents. Each image shows one isolated complete item
on a neutral background, without a hero/mannequin/base/text or duplicate views.

The helmet reference explicitly leaves face/chin gaps. The plate leaves neck/arm
gaps and avoids sleeves, legs or a mannequin. Gear must attach to the existing
hero; generating an impressive full character would solve the wrong problem.

**Convention:** an AI concept is a reference, not a mesh, render proof or approval.
Preserve the source image and item ID. Judge the mesh at portrait gameplay scale
and in motion; a flattering large concept image cannot establish in-game quality.

## Studio: bounded generation and reference replacement

Observed workspace settings: **HD Model**, **H3.1 – Best Quality**, **Geometry &
Texture**, 8K texture off, Generate in Parts off, Privacy on, Sharing Only.
The generation button showed **65 existing credits per job**. Use one generation
for each of the three items initially (195 credits total), then inspect results.

The Smart Mesh tab initially selected **four variants**, with a 100-credit button;
switching tabs is not enough to establish a bounded one-item job. Inspect settings
and cost before submitting. This pilot chose textured HD output and local Blender
reduction rather than that default multi-variant mesh-only flow.

Clicking the uploaded image opens a large preview; it does **not** open a replacement
file chooser. Escape did not close that preview in this session. Close its top-right
X, then use the trash icon **inside the source-upload panel** to clear only the input
reference, and Choose File to upload the next image. Do not delete the generated
asset. Await the upload; only submit when Generate is enabled. Verify a new task
URL/balance change and save its identifier before moving on. Never retry Generate
merely because the asynchronous task hasn't finished yet.

## Blender: validate fitted gear, preserve the original

`scripts/import_legendary_art.sh --preflight` validates configuration/references
and explicitly reports missing GLBs. A real build requires source files, Tripo
task provenance and a checked source license. Original GLBs stay in `sources/`;
cleaned editable Blender sources go in `cleaned/`.

The existing hero is about 1.73m tall with rigid animated parts, not a new skinned
skeleton. Blender gear uses Z-up and faces -Y; GLB export converts to Godot Y-up.
Existing gear origins are the hand grip, head centre or torso centre. Normalize
axes and scale, then set the pivot for the actual attachment. The initial fit
values in `pilot.json` are guesses until inspected on the hero.

Bake imported hierarchy transforms before adjusting the mesh. Copy mesh data
before transforming separate instances; linked instances can otherwise be
transformed more than once. Keep UVs/texture data through decimation. Preserve
broad colour maps, use rough materials and cap texture size to the pilot budget.
Reject skeletons, missing UVs/textures, non-finite vertices, excessive materials
and oversized attachment envelopes. A successful import alone cannot prove hollow
helmet openings, shoulder clearance, back surfaces or grip fit.

**Observed tool test:** a separately labelled synthetic textured sphere fixture
exercised import → decimation → texture reduction → GLB export → icon/four-view
render → editable source → manifest. It ended at 196 triangles, one material and
a 1024×1024 texture from a 2048 source. That fixture is **not Tripo artwork** and
was kept outside the game repo. Seven preflight tests and the Godot art loader
checks passed. Real Tripo cleanup/results are recorded below when verified.

## Godot: preserve fallbacks and saves

Imported runtime meshes/icons use `assets/imported/legendary/`. The procedural
builder removes stale files under `assets/models/` and `assets/icons/`; placing
new generated art there without registering it would risk losing it on rebuild.
Keep a separate generated imported manifest over stable existing catalogue IDs.

`ArtCatalog.imported_pilot_enabled` is a session-only developer review switch,
off by default. Normal gameplay and permanent saves keep the original equipment;
missing imported assets fall back to the procedural model/icon. Imported textured
materials must not be replaced with the procedural `pal_matte` vertex-colour
material. Enable the switch before constructing/equipping the review hero because
equipment caches the worn item name.

**Convention:** use the isolated project "Idle RPG Codex audit 30" for full tests
and captures. The original player's save and online-session files must never be
deleted to make a screenshot. Show all three on the actual hero, idle/walk/attack,
the gear preview, portrait gameplay and before/after under matching conditions.
Only the owner can establish Android device appearance/performance; desktop tests
do not establish those results.

## Source rights and evidence

Tripo's [commercial-use guide](https://www.tripo3d.ai/help/privacy-policy/how-to-use-tripo-models-commercially)
and [Terms §5.2](https://www.tripo3d.ai/terms), checked 9 October 2026, distinguish
paid and free users' output rights. Record the account entitlement and applicable
terms at generation; preserve the source/reference and task settings. Do not infer
that a generated output grants rights to someone else's input artwork. The pilot
uses original AI-generated concepts, not existing franchise artwork.

## Generation / verification record

| Item | Studio identifier | Settings / cost | Current evidence |
|---|---|---|---|
| Crownblade | `0bd7562d-43a8-45c5-b8ae-be69aed2ea13` | H3.1, textured HD, 65 credits | Source retrieved and decoded; hero-fit review in progress |
| Starforged Helm | `7ed3280f-5237-4762-8d3c-d8277a3d12df` | Same, 65 credits | Source retrieved and decoded; hero-fit review in progress |
| Titanheart Plate | `25febece-b655-4ad5-8a55-6f8e48c5a846` | Same, 65 credits | Source retrieved and decoded; hero-fit review in progress |

Update this table and append actual cleanup/fitting lessons as work continues.
No real-model in-game quality or Android performance claim is made at this stage.

### Retrieval breakthrough (same day)

The rendered-page asset inventory exposed each completed model's actual
`*_meshopt.glb` resource. The inventory's bundler rejects the `other` asset kind,
but the observed file address could be downloaded normally without extracting
browser credentials or guessing API endpoints. All three compressed originals
are now preserved under `art/imported/sources/`; no new Tripo jobs were required.
On this browser, a full page reload exposed the GLB resource after navigation
when the first inventory was empty. Load the visible model before checking.

These Studio viewer GLBs require `EXT_meshopt_compression` and
`KHR_mesh_quantization`. Preserve the exact compressed original, then use the
pinned glTF Transform / meshoptimizer decoder in `tools/art/glb_decode/` to write
an uncompressed Blender-readable GLB. The decode records both SHA-256 hashes.
It changes the representation, not the design or geometry. Decoded intermediates
are ignored by Git; originals and the repeatable decoder remain the source record.

First Crownblade processing measured **2,940 triangles, one material/surface,
three 1024×1024 maps**. Its initial front render showed a narrow edge: source axes
differed from the hero weapon convention. A 90-degree Blender Z rotation corrects
the blade plane before setting the grip pivot. This proves why a successful
import/triangle budget cannot substitute for inspecting the actual render.

A second original three-item concept sheet, `legendary_design_pass_2.png`, explores
a cleft crown-shaped blade, a broken eclipse helmet arc and a ribbed titan-heart
cuirass. It is a proposed direction awaiting owner feedback, not a generated
Tripo model or approved replacement.

## Export: high resolution is source quality, not a runtime budget

Crownblade's Studio mesh reports **1,840,929 triangles and 937,301 vertices**.
The export dialog defaulted to **8K**, even with the generation's 8K toggle off.
Inspect export settings separately; 2K was selected for the source export and
the local runtime importer targets 1024 textures and the configured mesh budget.

Tracking the export with the browser's download event timed out twice. A normal
Export click produced a success toast but no local GLB was found. A success toast
is not delivery evidence: verify the file, import it and inspect its geometry.
The Studio task returned 404 through the configured API account; do not assume
Studio assets are accessible using a different API wallet/key.

## Bridges: separate asset transfer from agent control

The owner's suggestion to use bridges exposed an existing **Tripo3d Blender
Bridge** installation. Starting Blender activates its local WebSocket listener
at `127.0.0.1:60600`. Studio has a **DCC Bridge** menu with Blender and Godot
targets. Inspect and enable this supported transfer route before asking the
owner to manually export files. Listener readiness alone does not prove transfer.

The official **Tripo3d Godot Bridge v1.0.0** was downloaded from Studio's Install
link and installed/enabled alongside the MCP addon in the isolated review project.
Its listener is `127.0.0.1:60650`. Both official DCC listeners were verified locally.
Studio's Blender/Godot toggle still displayed **Connecting**; no model-transfer
success is claimed. A screenshot of that state accompanies the output document.
If another background Blender process owns port 60600, it can interfere with
the dedicated receiving instance; inspect the owning process and leave unrelated
project work alone. Local ports and third-party startup behavior must be checked
again after an application closes or restarts.

Additional local MCP control bridges were installed and tested:

- [MCP for Blender](https://github.com/ahujasid/mcp-for-blender), source revision
  `7a0373ec9199183cb460068c4f96aed9c579fb4f`, installed package 2.1.9 and
  matching addon protocol 13. A real MCP `get_scene_info` call returned Blender's
  current objects; nine tools were advertised. Listener: `127.0.0.1:9876`.
- [godot-mcp](https://github.com/blentz/godot-mcp), source revision
  `735bdc9c98806e5ecdd05b819bc4ac461d9af935`. Fifty tools were advertised.
  `godot_status`, `editor_state` and a read-only `execute_editor_script` query
  succeeded against Godot 4.7.2 and the isolated review project's live editor.
  Listener: `127.0.0.1:38900`, with the addon's per-session handshake token.

Codex server registration uses `codex mcp add`; see the
[official MCP configuration documentation](https://developers.openai.com/codex/mcp).
New server registration does not retroactively add tools to the current turn's
catalogue. This session verified them using an MCP SDK client; the desktop app
may need its documented MCP restart to expose the tools directly.

**Windows lesson:** godot-mcp's entrypoint compared `import.meta.url` to a manually
constructed `file://` path. Windows paths failed that comparison. A separate
`godot-entry.mjs` imports and calls `main()` explicitly, preserving upstream code.
Its editor script tool expects a function **body**, such as `return 21 + 21`,
not a complete `func` declaration. Check the returned `ok` field, not just the
MCP `isError` flag: a compile failure was carried inside a successful MCP envelope.

Bridge files, verification JSON/logs and launch helpers are kept in this chat's
`work/bridges/`, outside production art. Blender telemetry remains off. Godot's
default target is the isolated **Idle RPG Codex audit 30** project. A live control
connection does not establish source export, fitted gear or Android performance.

## Art direction: good Epic art is not automatically Legendary

Owner feedback on 9 October: **"they look very generic but good"**, followed by
**"those could be Epic items, but not Legendary"**. The pilot's initial visual
direction is therefore below the requested rarity; no Legendary approval exists.

**Impact:** polished blue metal, gold trim and amber gems can produce coherent
gear that still reads as generic fantasy equipment. More trim, resolution or
glow will not fix the identity problem.

**New convention:** establish one unmistakable silhouette and visual story per
Legendary, readable on the actual hero at portrait phone scale. Test recognition
from the outline and in motion, without its name or rarity colour. Keep Epic
polish as the baseline and reserve distinct shapes, construction and restrained
effects for Legendary identity. These first assets remain pipeline samples until
revised and reviewed; do not ship them as approved Legendary replacements.


## Fit review: dimensions alone do not prove wearable gear

The three real imports measure 2,940 / 3,920 / 4,900 triangles (11,760 total),
with one material and surface each and texture maps reduced to 1024 pixels.
Actual game captures exposed sideways helmet/chest axes, then a chest plate
hidden inside the hero's shirt. Correct axes first; fit the shell around the
existing tapered torso rather than accepting a plausible overall bounding box.
The importer now supports bounded per-axis fit_scale after uniform height scale.
Recheck idle, walk, attack and a front inspection after each fit adjustment.
A gear-list icon or neutral turntable cannot establish body fit.

The full test runner initially crashed during Godot's font import. An explicit
headless editor import completed; the suite was then restarted. Treat an import
crash as a failed run, never as a test pass. Headless imports should run before
starting the isolated live MCP editor, to avoid colliding listeners and stale
handshake discovery files.

## Verified desktop pilot result — 9 October 2026

All three sources were processed, loaded by the actual game and equipped on
its existing hero. Fourteen 405 x 720 captures cover procedural/imported idle,
walk, attack, front inspection and each of the three gear screens. The corrected
chest shell is visible around the torso; head/chest axes and sword orientation
were corrected. This is a desktop visual review of static animation poses,
not an Android device performance test or a complete animation clearance audit.

The import specification tests pass (7 tests). The full game regression runner
completed 39 runs with exit code zero and no engine/script errors after the
successful explicit editor import. The final fitted assets also receive a
separate art-loading/material check. Existing item rarity labels stay unchanged
in the isolated fixture, but the owner has not approved these models as
Legendary replacements. The normal game keeps the imported pilot off.

The stronger second-pass direction is recorded in LEGENDARY_SECOND_PASS.md.
No additional paid generation has been submitted pending art-direction review.
