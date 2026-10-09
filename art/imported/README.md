# Imported gear pilot

Three real Tripo Studio H3.1 textured HD sources are local: Crownblade,
Starforged Helm and Titanheart Plate. They cost 195 existing Max credits;
no purchase or repeat generation was needed. Task IDs, settings, source hashes
and dated rights review are in pilot.json.

The owner considers this first pass **Epic-level, not approved Legendary art**.
The original blue-metal/gold-trim follow-up concepts were rejected and removed. See `references/fresh_legendary_direction.svg` for the new shape and material studies; they are concepts, not generated meshes. Original source art is preserved.

## Rebuild

1. From the repo root, run npm ci --ignore-scripts --prefix tools/art/glb_decode.
2. Run scripts/import_legendary_art.sh. It losslessly decodes preserved
   sources/*_studio_meshopt.glb files when decoded intermediates are absent,
   then imports, fits, reduces, textures, exports and renders with Blender.
   --preflight validates specifications without building.
3. Runtime meshes/icons go to assets/imported/legendary; editable Blender
   files to cleaned; measurements and neutral views to art/review/legendary.
   The generated manifest contains all three real assets.

Measured triangle counts: 2,940 / 3,920 / 4,900. Each has one material and
surface; texture maps are reduced to 1024 pixels. These are budgets, not measured
Android performance. fit_scale adjusts body proportions after height scaling.
Source/reference/editable/review files are excluded from Android exports.

## Actual game review

The session-only ArtCatalog.imported_pilot_enabled flag defaults to false and
is never saved. Normal gameplay uses existing procedural art; missing imports
fall back. Item IDs, stats and drop odds stay unchanged.

tools/ui/capture_imported_gear.gd runs only in the isolated project named
**Idle RPG Codex audit 30**. It equips the real hero, captures procedural/imported
idle, walk, attack, inspection and three gear screens, and restores review saves.
Visual fit and art acceptance require these captures; Android performance
remains unmeasured.

## Retrieval and bridges

Studio's DCC transfer remained at Connecting despite local listeners being
ready. Retrieval succeeded through the actual GLB resource exposed by the
completed model's page asset inventory. Original meshopt GLBs are preserved;
decoded intermediates are ignored. Do not store signed URLs or credentials.

Official Tripo DCC bridges and additional Blender/Godot MCP control bridges
were installed and tested in the isolated workspace. Local control does not
prove Studio transfer. See docs/TRIPO_PROCESS_LEARNINGS.md for the full process,
Windows fixes, verification and art-direction lessons.


