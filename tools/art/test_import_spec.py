"""Import preflight must reject unsafe paths, provenance gaps and invalid budgets."""
import copy
import json
from pathlib import Path
import tempfile
import unittest

from import_spec import load_specs


class ImportSpecTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.path = self.folder / "pilot.json"
        self.document = json.loads((Path(__file__).resolve().parents[2] / "art/imported/pilot.json").read_text())
        for spec in self.document["assets"]:
            ref = self.folder / spec["reference"]
            ref.parent.mkdir(parents=True, exist_ok=True)
            ref.write_bytes(b"reference fixture, not a playable asset")

    def load(self, document=None, require_sources=False):
        self.path.write_text(json.dumps(document or self.document))
        return load_specs(self.path, require_sources)

    def test_preflight_allows_missing_sources_without_claiming_models(self):
        self.assertEqual(len(self.load()), 3)

    def test_real_build_rejects_missing_sources(self):
        with self.assertRaisesRegex(ValueError, "Missing real Tripo source"):
            self.load(require_sources=True)

    def test_source_paths_cannot_escape(self):
        self.document["assets"][0]["source"] = "../outside.glb"
        with self.assertRaisesRegex(ValueError, "inside the import directory"):
            self.load()

    def test_duplicate_or_new_catalog_ids_rejected(self):
        self.document["assets"].append(copy.deepcopy(self.document["assets"][0]))
        with self.assertRaisesRegex(ValueError, "duplicate"):
            self.load()

    def test_wrong_equipment_slot_rejected(self):
        self.document["assets"][0]["slot"] = "head"
        with self.assertRaisesRegex(ValueError, "Item and slot"):
            self.load()

    def test_transform_and_budget_validation(self):
        for field, value in (("height_m", float("nan")), ("rotation_degrees", [0, float("inf"), 0]),
                             ("pivot_fraction", [0.5, 2, 0]), ("max_triangles", 500000),
                             ("max_materials", True), ("max_texture_size", 4096),
                             ("fit_scale", [1, float("nan"), 1]), ("fit_scale", [1, 3, 1])):
            document = copy.deepcopy(self.document)
            document["assets"][0][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.load(document)

    def test_provenance_required_before_actual_build(self):
        spec = self.document["assets"][0]
        source = self.folder / spec["source"]
        source.parent.mkdir(parents=True)
        source.write_bytes(b"test fixture, not Tripo output")
        self.document["assets"] = [spec]
        spec["provenance"]["task_id"] = ""
        spec["provenance"]["license_review"] = "pending"
        with self.assertRaisesRegex(ValueError, "Missing Tripo task provenance"):
            self.load(require_sources=True)
        spec["provenance"]["task_id"] = "TEST-FIXTURE-ONLY"
        with self.assertRaisesRegex(ValueError, "license review pending"):
            self.load(require_sources=True)


if __name__ == "__main__":
    unittest.main()
