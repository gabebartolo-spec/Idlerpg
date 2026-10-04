"""Model registry. Each builder returns a list of Parts, parents before children."""

from collections import namedtuple

Spec = namedtuple("Spec", "id category item build")

# Per category: triangle budget, largest allowed dimension (m), most materials
# (the shared matte material plus glow accents).
BUDGETS = {
    "weapon": (300, 2.0, 3),
    "armour": (400, 1.0, 3),
    "prop": (500, 5.0, 3),
    "character": (1500, 2.0, 3),
    "backdrop": (300, 45.0, 3),
}

MODELS = {}


def model(model_id, category, item=None):
    """Register a builder. `item` is the gear catalogue name this model is the visual for."""
    def register(build):
        MODELS[model_id] = Spec(model_id, category, item, build)
        return build
    return register


from . import armour, backdrops, characters, props, weapons  # noqa: E402,F401
