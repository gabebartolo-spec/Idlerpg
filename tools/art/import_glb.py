"""Independent, fail-closed Blender preprocessing for the three legendary GLBs.

blender --background --factory-startup --python-exit-code 1 \
    --python tools/art/import_glb.py -- [--preflight]

Source GLBs stay untouched. Blender works in Z-up, facing -Y; export converts
to Godot Y-up. Transform values are an initial fit, requiring visual review.
Outputs live outside assets/models and assets/icons so procedural stale-output
cleanup cannot delete them. All assets validate before publishing a manifest.
"""
import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
from import_spec import load_specs


def bounds(objects):
    from mathutils import Vector
    points = [o.matrix_world @ v.co for o in objects for v in o.data.vertices]
    if not points:
        raise ValueError("Source has no mesh vertices")
    return (Vector([min(p[i] for p in points) for i in range(3)]),
            Vector([max(p[i] for p in points) for i in range(3)]))


def prepare(spec, source):
    import bpy
    from mathutils import Euler, Vector
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes or any(o.type == "ARMATURE" for o in bpy.context.scene.objects):
        raise ValueError("Expected rigid gear mesh, no new character skeleton")
    # Bake node hierarchy transforms before normalising model axes and origin.
    rotation = Euler(tuple(math.radians(x) for x in spec["rotation_degrees"])).to_matrix().to_4x4()
    for obj in meshes:
        world = obj.matrix_world.copy()
        obj.parent = None
        obj.data = obj.data.copy()
        obj.data.transform(rotation @ world)
        obj.matrix_world.identity()
        if any(not math.isfinite(c) for v in obj.data.vertices for c in v.co):
            raise ValueError("Source contains non-finite vertex coordinates")
        if len(obj.modifiers):
            raise ValueError("Unexpected source modifiers")
    low, high = bounds(meshes)
    size = high - low
    if min(size) < 0.00001:
        raise ValueError("Degenerate source dimensions")
    scale = spec["height_m"] / size.z
    pivot = low + Vector([size[i] * spec["pivot_fraction"][i] for i in range(3)])
    offset = Vector(spec["offset_m"])
    fit = Vector(spec.get("fit_scale", [1, 1, 1]))
    for obj in meshes:
        for vertex in obj.data.vertices:
            relative = (vertex.co - pivot) * scale
            vertex.co = Vector([relative[i] * fit[i] for i in range(3)]) + offset
        # Deterministic per-object decimation, preserving UV data through Blender.
        obj.data.calc_loop_triangles()
    total = sum(len(o.data.loop_triangles) for o in meshes)
    if total > spec["max_triangles"]:
        for obj in meshes:
            bpy.context.view_layer.objects.active = obj
            modifier = obj.modifiers.new("Mobile reduction", "DECIMATE")
            modifier.ratio = spec["max_triangles"] / total * 0.98
            bpy.ops.object.modifier_apply(modifier=modifier.name)
    for obj in meshes:
        obj.data.calc_loop_triangles()
        if not obj.data.uv_layers:
            raise ValueError("Textured gear needs UVs")
    triangles = sum(len(o.data.loop_triangles) for o in meshes)
    if triangles > spec["max_triangles"]:
        raise ValueError("Triangle budget still exceeded after reduction")
    materials = {m for o in meshes for m in o.data.materials if m}
    if not materials or len(materials) > spec["max_materials"]:
        raise ValueError("Material count outside pilot budget")
    textures = set()
    for material in materials:
        if not material.use_nodes:
            raise ValueError("Expected node material")
        material.name = "imported_" + material.name
        shader = next((n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if shader is None:
            raise ValueError("Unsupported material shader")
        # Keep painterly colour maps. Avoid specular noise in the mobile pilot.
        for socket_name, value in (("Roughness", 0.85), ("Metallic", 0.15)):
            socket = shader.inputs[socket_name]
            for link in list(socket.links):
                material.node_tree.links.remove(link)
            socket.default_value = value
        for node in material.node_tree.nodes:
            if node.type == "TEX_IMAGE" and node.image:
                textures.add(node.image)
    if not textures:
        raise ValueError("Expected original painterly texture maps")
    texture_sizes = []
    for image in textures:
        width, height = image.size[:]
        if min(width, height) < 1:
            raise ValueError("Missing texture pixels")
        factor = min(1, spec["max_texture_size"] / max(width, height))
        if factor < 1:
            image.scale(max(1, round(width * factor)), max(1, round(height * factor)))
        image.pack()
        texture_sizes.append(list(image.size[:]))
    low, high = bounds(meshes)
    size = high - low
    if max(size) > (2 if spec["slot"] == "weapon" else 1):
        raise ValueError("Gear exceeds attachment envelope; revise fit")
    if spec["slot"] == "weapon" and not all(low[i] <= 0 <= high[i] for i in range(3)):
        raise ValueError("Weapon origin is outside grip bounding volume")
    for obj in list(bpy.context.scene.objects):
        if obj not in meshes:
            bpy.data.objects.remove(obj, do_unlink=True)
    root = bpy.data.objects.new(spec["id"], None)
    bpy.context.scene.collection.objects.link(root)
    for obj in meshes:
        obj.parent = root
    return meshes, {"triangles": triangles, "materials": len(materials),
                    "surfaces": sum(len(o.data.materials) for o in meshes),
                    "textures": texture_sizes, "size_blender_m": list(size),
                    "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                    "provenance": spec["provenance"], "visual_fit_review": "pending"}


def render(meshes, path, yaw=25, pixels=256):
    import bpy
    from mathutils import Vector
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Standard"
    scene.world = bpy.data.worlds.new("Neutral world")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.35, 0.35, 0.35, 1)
    low, high = bounds(meshes)
    centre = (low + high) / 2
    points = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    angle = math.radians(yaw)
    direction = Vector((math.sin(angle), -math.cos(angle), 0.30)).normalized()
    camera_data = bpy.data.cameras.new("Review camera")
    camera_data.type = "ORTHO"
    camera = bpy.data.objects.new("Review camera", camera_data)
    scene.collection.objects.link(camera)
    camera.location = centre + direction * 5
    camera.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()
    rotation = camera.rotation_euler.to_matrix()
    right, up = rotation @ Vector((1, 0, 0)), rotation @ Vector((0, 1, 0))
    xs, ys = [p.dot(right) for p in points], [p.dot(up) for p in points]
    camera_data.ortho_scale = max(max(xs)-min(xs), max(ys)-min(ys)) * 1.16
    scene.camera = camera
    sun = bpy.data.objects.new("Review light", bpy.data.lights.new("Review light", "SUN"))
    sun.data.energy = 2.5
    sun.rotation_euler = (math.radians(25), math.radians(-25), math.radians(-20))
    scene.collection.objects.link(sun)
    scene.render.resolution_x = scene.render.resolution_y = pixels
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(camera, do_unlink=True)
    bpy.data.objects.remove(sun, do_unlink=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", type=Path, default=ROOT / "art/imported/pilot.json")
    parser.add_argument("--preflight", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    specs = load_specs(args.spec, require_sources=not args.preflight)
    if args.preflight:
        for spec in specs:
            source = args.spec.parent / spec["source"]
            print(spec["id"] + ": reference ready; source " + ("present" if source.is_file() else "MISSING"))
        return
    import bpy
    cache = ROOT / "art/.cache/imported"
    cache.mkdir(parents=True, exist_ok=True)
    built = []
    # Validate every source before touching playable outputs/manifest.
    for spec in specs:
        meshes, report = prepare(spec, args.spec.parent / spec["source"])
        blend = cache / (spec["id"] + ".blend")
        bpy.ops.wm.save_as_mainfile(filepath=str(blend))
        built.append((spec, report, blend))
    out = ROOT / "assets/imported/legendary"
    review = ROOT / "art/review/legendary"
    out.mkdir(parents=True, exist_ok=True)
    review.mkdir(parents=True, exist_ok=True)
    models, items = [], []
    for spec, report, blend in built:
        bpy.ops.wm.open_mainfile(filepath=str(blend))
        meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        model_id = spec["id"]
        bpy.ops.export_scene.gltf(filepath=str(out / (model_id + ".glb")), export_format="GLB", export_yup=True)
        render(meshes, out / (model_id + ".png"))
        for yaw in (0, 90, 180, 270):
            render(meshes, review / (model_id + "_%d.png" % yaw), yaw=yaw, pixels=768)
        (review / (model_id + ".json")).write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
        # Editable cleaned source is separate from Android runtime assets.
        editable = ROOT / "art/imported/cleaned"
        editable.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.open_mainfile(filepath=str(blend))
        bpy.ops.wm.save_as_mainfile(filepath=str(editable / (model_id + ".blend")))
        base = "res://assets/imported/legendary/" + model_id
        s = report["size_blender_m"]
        models.append('\t"%s": {"path": "%s.glb", "category": "%s", "tris": %d, "size": Vector3(%.4f, %.4f, %.4f), "nodes": []},' %
                      (model_id, base, "weapon" if spec["slot"] == "weapon" else "armour", report["triangles"], s[0], s[2], s[1]))
        items.append('\t"%s": {"model": "%s", "icon": "%s.png"},' % (spec["item"], model_id, base))
    text = "# Generated by tools/art/import_glb.py. Session-only pilot; procedural fallback remains.\nextends RefCounted\n\nconst MODELS := {\n" + "\n".join(models) + "\n}\n\nconst ITEMS := {\n" + "\n".join(items) + "\n}\n"
    manifest = ROOT / "src/data/imported_art_manifest.gd"
    temporary = manifest.with_suffix(".gd.tmp")
    temporary.write_text(text, encoding="utf-8", newline="\n")
    temporary.replace(manifest)
    print("Imported %d source meshes. Pilot remains disabled by default; fit/animation and Android review required." % len(built))


if __name__ == "__main__":
    main()
