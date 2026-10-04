"""Build the game's 3D art: validate every model, export GLBs, render gear icons and
review sheets, and write the manifest the game reads.

Run through scripts/build_art.sh (Blender, headless). `-- --only id [id ...]` rebuilds
just those models and leaves the manifest and review sheets alone.
"""

import argparse
import math
import os
import re
import sys
import tempfile

import bpy
import numpy as np
from mathutils import Quaternion, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)

from models import BUDGETS, MODELS  # noqa: E402

MODEL_DIR = os.path.join(ROOT, "assets", "models")
ICON_DIR = os.path.join(ROOT, "assets", "icons")
REVIEW_DIR = os.path.join(ROOT, "art", "review")
MANIFEST = os.path.join(ROOT, "src", "data", "art_manifest.gd")
GEAR_CATALOG = os.path.join(ROOT, "src", "data", "gear_catalog.gd")

ICON_SIZE = 256
SHEET_COLUMNS = 6
SHEET_BACKGROUND = (0.81, 0.84, 0.87)

# Camera per category, degrees: yaw around the model, pitch above it, roll of the frame.
VIEWS = {
    "weapon": (20, 0, 45),
    "armour": (30, 15, 0),
    "prop": (35, 20, 0),
    "character": (35, 20, 0),
}


def gear_items():
    """Item name -> slot, read from the game's gear catalogue."""
    with open(GEAR_CATALOG, encoding="utf-8") as handle:
        return dict(re.findall(r'^\s*"([^"]+)":\s*\{"slot":\s*"(\w+)"', handle.read(), re.MULTILINE))


def setup_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("stage")
    world.use_nodes = True
    background = world.node_tree.nodes["Background"]
    background.inputs[0].default_value = (1.0, 1.0, 1.0, 1.0)
    background.inputs[1].default_value = 0.7
    scene.world = world


def clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for block in (bpy.data.meshes, bpy.data.cameras, bpy.data.lights, bpy.data.curves):
        for item in list(block):
            block.remove(item)


def build_model(spec, gear):
    """Create the model's objects. Returns (objects, info, errors)."""
    parts = spec.build()
    errors = []
    names = [part.name for part in parts]
    if len(set(names)) != len(names):
        errors.append("duplicate part names")

    points = [point for part in parts for point in part.points]
    colours = {colour for part in parts for colour in part.colours}
    objects = {}
    for part in parts:
        part.finish(objects)

    tris = 0
    for obj in objects.values():
        if obj.type == "MESH":
            obj.data.calc_loop_triangles()
            tris += len(obj.data.loop_triangles)

    low = Vector([min(p[i] for p in points) for i in range(3)])
    high = Vector([max(p[i] for p in points) for i in range(3)])
    size = high - low

    max_tris, max_size, max_materials = BUDGETS[spec.category]
    if tris > max_tris:
        errors.append("%d triangles, budget %d" % (tris, max_tris))
    if max(size) > max_size:
        errors.append("%.2f m across, limit %.2f" % (max(size), max_size))
    if len(colours) > max_materials:
        errors.append("%d materials, limit %d" % (len(colours), max_materials))
    if spec.category in ("prop", "character") and not -0.01 <= low.z <= 0.05:
        errors.append("does not sit on the ground (lowest point %.2f)" % low.z)
    if spec.category == "weapon" and not all(low[i] <= 0.0 <= high[i] for i in range(3)):
        errors.append("origin is not on the grip")
    if spec.item is not None:
        slot = gear.get(spec.item)
        if slot is None:
            errors.append('item "%s" is not in the gear catalogue' % spec.item)
        elif (slot == "weapon") != (spec.category == "weapon"):
            errors.append('item "%s" is a %s but the model is a %s' % (spec.item, slot, spec.category))

    info = {"tris": tris, "size": size, "nodes": names[1:]}
    return objects, info, errors


def export_glb(objects, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects.values():
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True)


def render(objects, category, path, label=None):
    """Orthographic render framed on the model. A label makes it a review thumbnail."""
    scene = bpy.context.scene
    bpy.context.view_layer.update()
    yaw, pitch, roll = (math.radians(a) for a in VIEWS[category])
    points = [obj.matrix_world @ v.co for obj in objects.values() if obj.type == "MESH" for v in obj.data.vertices]

    towards = Vector((math.sin(yaw) * math.cos(pitch), -math.cos(yaw) * math.cos(pitch), math.sin(pitch)))
    rotation = (-towards).to_track_quat("-Z", "Y") @ Quaternion((0.0, 0.0, 1.0), roll)
    right = rotation @ Vector((1.0, 0.0, 0.0))
    up = rotation @ Vector((0.0, 1.0, 0.0))
    xs = [p.dot(right) for p in points]
    ys = [p.dot(up) for p in points]
    extent = max(max(xs) - min(xs), max(ys) - min(ys))
    scale = extent * (1.35 if label else 1.08)
    centre_y = (max(ys) + min(ys)) / 2.0 - (scale * 0.07 if label else 0.0)

    data = bpy.data.cameras.new("camera")
    data.type = "ORTHO"
    data.ortho_scale = scale
    camera = bpy.data.objects.new("camera", data)
    camera.rotation_mode = "QUATERNION"
    camera.rotation_quaternion = rotation
    camera.location = right * ((max(xs) + min(xs)) / 2.0) + up * centre_y + towards * (max(p.dot(towards) for p in points) + 10.0)
    scene.collection.objects.link(camera)
    scene.camera = camera

    sun = bpy.data.objects.new("key", bpy.data.lights.new("key", "SUN"))
    sun.data.energy = 3.5
    sun.parent = camera
    sun.rotation_euler = (math.radians(-35.0), math.radians(-30.0), 0.0)
    scene.collection.objects.link(sun)
    stage = [camera, sun]

    if label:
        curve = bpy.data.curves.new("label", "FONT")
        curve.body = label
        curve.align_x = "CENTER"
        curve.size = scale * 0.075
        material = bpy.data.materials.get("label")
        if material is None:
            material = bpy.data.materials.new("label")
            material.use_nodes = True
            material.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.02, 0.02, 0.02, 1.0)
        curve.materials.append(material)
        text = bpy.data.objects.new("label", curve)
        text.parent = camera
        text.location = (0.0, -scale * 0.45, -1.0)
        scene.collection.objects.link(text)
        stage.append(text)

    scene.render.resolution_x = ICON_SIZE
    scene.render.resolution_y = ICON_SIZE
    scene.render.filepath = path
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.render.render(write_still=True)
    for obj in stage:
        bpy.data.objects.remove(obj, do_unlink=True)


def contact_sheet(paths, out):
    """Tile labelled thumbnails onto one image for review."""
    size = ICON_SIZE
    rows = math.ceil(len(paths) / SHEET_COLUMNS)
    columns = min(SHEET_COLUMNS, len(paths))
    canvas = np.ones((rows * size, columns * size, 4), dtype=np.float32)
    canvas[..., :3] = SHEET_BACKGROUND
    for index, path in enumerate(paths):
        image = bpy.data.images.load(path)
        tile = np.empty(size * size * 4, dtype=np.float32)
        image.pixels.foreach_get(tile)
        bpy.data.images.remove(image)
        tile = tile.reshape(size, size, 4)
        row, column = divmod(index, SHEET_COLUMNS)
        y = (rows - 1 - row) * size
        x = column * size
        alpha = tile[..., 3:4]
        canvas[y:y + size, x:x + size, :3] = tile[..., :3] * alpha + canvas[y:y + size, x:x + size, :3] * (1.0 - alpha)

    sheet = bpy.data.images.new("sheet", columns * size, rows * size)
    sheet.pixels.foreach_set(canvas.ravel())
    sheet.filepath_raw = out
    sheet.file_format = "PNG"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save()
    bpy.data.images.remove(sheet)


def res_path(path):
    return "res://" + os.path.relpath(path, ROOT).replace(os.sep, "/")


def write_manifest(built):
    lines = [
        "# Generated by tools/art/build.py. Do not edit; run scripts/build_art.sh.",
        "extends RefCounted",
        "",
        "const MODELS := {",
    ]
    for spec, info in built:
        size = info["size"]
        lines.append('\t"%s": {"path": "%s", "category": "%s", "tris": %d, "size": Vector3(%.3f, %.3f, %.3f), "nodes": [%s]},' % (
            spec.id, res_path(model_path(spec)), spec.category, info["tris"], size.x, size.z, size.y,
            ", ".join('"%s"' % name for name in info["nodes"])))
    lines += ["}", "", "const ITEMS := {"]
    for spec, _info in built:
        if spec.item is not None:
            lines.append('\t"%s": {"model": "%s", "icon": "%s"},' % (spec.item, spec.id, res_path(icon_path(spec))))
    lines += ["}", ""]
    with open(MANIFEST, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines))


def model_path(spec):
    return os.path.join(MODEL_DIR, spec.category + "s", spec.id + ".glb")


def icon_path(spec):
    return os.path.join(ICON_DIR, spec.id + ".png")


def remove_stale(folder, extension, keep):
    """Delete outputs (and their Godot .import files) whose model no longer exists."""
    for directory, _dirs, files in os.walk(folder):
        for name in files:
            path = os.path.join(directory, name)
            if name.endswith(extension) and path not in keep:
                os.remove(path)
                if os.path.exists(path + ".import"):
                    os.remove(path + ".import")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", nargs="*", default=[])
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])

    unknown = [model_id for model_id in args.only if model_id not in MODELS]
    if unknown:
        sys.exit("Unknown model: " + ", ".join(unknown))
    specs = [spec for spec in MODELS.values() if not args.only or spec.id in args.only]

    gear = gear_items()
    failures = []
    covered = {spec.item for spec in MODELS.values() if spec.item is not None}
    for item in gear:
        if item not in covered:
            failures.append('gear item "%s" has no model' % item)

    setup_scene()
    thumbs = tempfile.mkdtemp(prefix="idlerpg_art_")
    built = []
    sheets = {}
    for spec in specs:
        clear_scene()
        objects, info, errors = build_model(spec, gear)
        failures += ["%s: %s" % (spec.id, error) for error in errors]
        print("%-10s %-16s %4d tris  %.2f x %.2f x %.2f m%s" % (
            spec.category, spec.id, info["tris"], info["size"].x, info["size"].y, info["size"].z,
            "  FAIL" if errors else ""))
        if errors:
            continue
        export_glb(objects, model_path(spec))
        if spec.item is not None:
            render(objects, spec.category, icon_path(spec))
        thumb = os.path.join(thumbs, spec.id + ".png")
        render(objects, spec.category, thumb, label="%s  %d" % (spec.id, info["tris"]))
        sheets.setdefault(spec.category, []).append(thumb)
        built.append((spec, info))

    if failures:
        print("\nArt build FAILED:")
        for failure in failures:
            print("  - " + failure)
        sys.exit(1)

    if not args.only:
        for category, paths in sheets.items():
            contact_sheet(paths, os.path.join(REVIEW_DIR, category + "s.png"))
        write_manifest(built)
        remove_stale(MODEL_DIR, ".glb", {model_path(spec) for spec, _ in built})
        remove_stale(ICON_DIR, ".png", {icon_path(spec) for spec, _ in built if spec.item is not None})
    print("\nArt build OK: %d models, %d triangles in total." % (len(built), sum(info["tris"] for _, info in built)))


main()
