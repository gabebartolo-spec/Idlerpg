"""Pure validation shared by the Blender importer and cheap preflight checks."""
import json
import math
from pathlib import Path

PILOT = {"crownblade": ("Crownblade", "weapon"),
         "starforged_helm": ("Starforged Helm", "head"),
         "titanheart_plate": ("Titanheart Plate", "chest")}


def confined_path(base, name):
    path = (base / name).resolve()
    if not path.is_relative_to(base.resolve()):
        raise ValueError("Source/reference path must remain inside the import directory")
    return path


def load_specs(path, require_sources=False):
    path = Path(path).resolve()
    document = json.loads(path.read_text(encoding="utf-8"))
    if document.get("schema") != 1:
        raise ValueError("Unsupported import schema")
    seen = set()
    specs = document.get("assets", [])
    if not isinstance(specs, list) or not specs:
        raise ValueError("Expected pilot asset list")
    for spec in specs:
        model_id = spec.get("id")
        if model_id not in PILOT or model_id in seen:
            raise ValueError("Unknown or duplicate pilot model ID")
        seen.add(model_id)
        if (spec.get("item"), spec.get("slot")) != PILOT[model_id]:
            raise ValueError("Item and slot must match existing pilot catalogue")
        for key in ("rotation_degrees", "pivot_fraction", "offset_m"):
            v = spec.get(key)
            if not isinstance(v, list) or len(v) != 3 or any(
                    not isinstance(x, (int, float)) or isinstance(x, bool) or not math.isfinite(x) for x in v):
                raise ValueError("Expected three finite numbers for " + key)
        if any(not 0 <= x <= 1 for x in spec["pivot_fraction"]):
            raise ValueError("Pivot fractions must be between zero and one")
        fit = spec.get("fit_scale", [1, 1, 1])
        if not isinstance(fit, list) or len(fit) != 3 or any(
                type(x) not in (int, float) or not math.isfinite(x) or not 0.5 <= x <= 2 for x in fit):
            raise ValueError("Invalid fit scale")
        height = spec.get("height_m")
        if not isinstance(height, (int, float)) or not math.isfinite(height) or not 0.1 <= height <= 2:
            raise ValueError("Invalid gear height")
        for key, ceiling in (("max_triangles", 5000), ("max_materials", 3), ("max_texture_size", 1024)):
            value = spec.get(key)
            if type(value) is not int or not 1 <= value <= ceiling:
                raise ValueError("Invalid mobile budget for " + key)
        source = confined_path(path.parent, spec["source"])
        reference = confined_path(path.parent, spec["reference"])
        if source.suffix.lower() != ".glb" or reference.suffix.lower() != ".png":
            raise ValueError("Expected GLB source and PNG reference")
        if not reference.is_file():
            raise ValueError("Missing modelling reference for " + model_id)
        if require_sources:
            if not source.is_file():
                raise ValueError("Missing real Tripo source: " + model_id)
            provenance = spec.get("provenance", {})
            if provenance.get("provider") != "Tripo" or not provenance.get("task_id"):
                raise ValueError("Missing Tripo task provenance: " + model_id)
            if provenance.get("license_review") != "approved":
                raise ValueError("Source license review pending: " + model_id)
    return specs
