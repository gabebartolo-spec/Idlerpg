"""Model registry. Each builder returns a list of Parts, parents before children."""

from collections import namedtuple

Spec = namedtuple("Spec", "id category item companion build")

# Per category: triangle budget, largest allowed dimension (m), most materials
# (the shared matte material plus glow accents).
BUDGETS = {
    "weapon": (300, 2.0, 3),
    "armour": (400, 1.0, 3),
    "prop": (500, 5.0, 3),
    "character": (1500, 2.6, 3),
    "backdrop": (300, 45.0, 3),
}

MODELS = {}


def model(model_id, category, item=None, companion=None):
    """Register a builder. `item` or `companion` is the catalogue name this model is the visual for."""
    def register(build):
        MODELS[model_id] = Spec(model_id, category, item, companion, build)
        return build
    return register


from . import armour, backdrops, briarfen, characters, companions, enemies, props, weapons, lanternwood  # noqa: E402,F401
