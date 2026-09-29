# Zone artwork

These four environment illustrations were AI-generated specifically for this
project using Arena's image-generation tool. They are not sourced from an image
search or a third-party asset pack.

- `zones/marrowfields.jpg` — flooded reed beds and a distant belfry.
- `zones/chime_deep.jpg` — the drowned basilica and its suspended bells.
- `zones/requiem_scar.jpg` — the crater and the fallen bronze bell.
- `zones/lantern_wastes.jpg` — pilgrim lamps, black glass, and the Lantern-Eater.

The paintings were center-cropped to 1280×720 and optimized as JPEGs (about 675 KiB
combined). All four use a restrained ash, bone, and antique-bronze palette, without
baked-in text or UI. Zone names and gameplay information remain real UI text.

Godot imports these as normal textures. `src/ui/zone_art.gd` caches them and also
supports loading the raw files for fresh-checkout headless tests before an editor
import pass. Use **Export all resources** when packaging the game; the artwork is
looked up through the zone content tables.
