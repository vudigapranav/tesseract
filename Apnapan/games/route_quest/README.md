# Route Quest (G2)

Go somewhere familiar, collect one thing, and find the way back.

Built as a node graph: locations are `GameItem`s bound onto a per-level,
hand-authored topology (`RouteTopology`); the patient moves by tapping an
adjacent location. No tile map, no character controller, no physics engine,
no pathfinding AI — BFS (`RouteGraph.shortestPathLength`) only ever measures
a route, computed once at level load.

- **Level 1** — 3 locations, direct path there and back.
- **Level 2** — 5 locations, one branch.
- **Level 3** — 6 locations, two branches.

Difficulty changes the map only (see `RouteQuestGame.difficultyParamsForLevel`
for the real `nodeCount`/`branchCount`/`requiresReturn` settings) — never a
time limit or movement speed.

## Events

| type | payload | when |
|---|---|---|
| `location_entered` | `{nodeId}` | the patient taps an adjacent location and moves to it |
| `destination_reached` | — | arriving at the destination node, outbound |
| `item_collected` | — | immediately after `destination_reached` |
| `return_completed` | — | arriving back at the home node, on the return leg |
| `wrong_interaction` | `{objectId}` | tapping a non-adjacent location (or the current one) — the move is ignored |

Plus the shared lifecycle events (`session_started`, `hint_requested`,
`paused`, `resumed`, `session_finished`) from `TesseractEventRecorder`.
`objectId`/`nodeId` are always the tapped `GameItem.id` — never a label or
position.

## Route efficiency

`shortest path length / actual path length`, for completed routes only.
Shortest length is BFS'd once per leg at level load
(`RouteGraph.shortestPathLength`); actual length is the number of
`location_entered` events for the session — downstream metrics code
reconstructs this from the event log, the game does not emit a
pre-computed efficiency value itself.
