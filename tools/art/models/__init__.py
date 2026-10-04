"""Model registry. Each builder returns a list of Parts, parents before children."""

from collections import namedtuple

Spec = namedtuple("Spec", "id category item build")

# Per category: triangle budget, largest allowed dimension (m), most materials.
BUDGETS = {
    "weapon": (250, 1.8, 5),
    "armour": (250, 1.0, 5),
    "prop": (500, 5.0, 6),
    "character": (800, 2.0, 8),
}

MODELS = {}


def model(model_id, category, item=None):
    """Register a builder. `item` is the gear catalogue name this model is the visual for."""
    def register(build):
        MODELS[model_id] = Spec(model_id, category, item, build)
        return build
    return register


from . import armour, characters, props, weapons  # noqa: E402,F401
