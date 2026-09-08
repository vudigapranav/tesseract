"""Server-side game catalogue.

Mirrors `Apnapan/host/lib/games/game_registry.dart`. It exists so the server can
clamp a recommendation to a level the game actually has, and hand out a safe
default activity — not to duplicate game logic.

Only the two built games are listed. The other seven are registered here by
their owners when they land; an unknown ``game_id`` is still accepted for
ingestion (see the contract, §1.1) and simply has no calculator or ceiling.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class GameSpec:
    game_id: str
    min_level: int
    max_level: int
    default_input_mode: str


CATALOGUE: dict[str, GameSpec] = {
    "route_quest": GameSpec("route_quest", 1, 3, "touch"),
    "marble_maze": GameSpec("marble_maze", 1, 3, "tilt"),
}

# Handed out by GET /v1/patients/{id}/activity when no caregiver-approved
# configuration exists yet. Deliberately the gentlest option.
SAFE_DEFAULT_GAME_ID = "route_quest"
SAFE_DEFAULT_LEVEL = 1


def get_spec(game_id: str) -> GameSpec | None:
    return CATALOGUE.get(game_id)


def clamp_level(game_id: str, level: int) -> int:
    spec = get_spec(game_id)
    if spec is None:
        return level
    return max(spec.min_level, min(spec.max_level, level))


def at_ceiling(game_id: str, level: int) -> bool:
    spec = get_spec(game_id)
    return spec is not None and level >= spec.max_level


def at_floor(game_id: str, level: int) -> bool:
    spec = get_spec(game_id)
    return spec is not None and level <= spec.min_level
