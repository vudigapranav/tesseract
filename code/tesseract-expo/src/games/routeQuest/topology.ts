/**
 * Abstract level topology — node count, edges, which index is home and
 * destination, and how many dead-end branches exist. Purely structural: no
 * content, no rendering, no timing. Ported unchanged from route_topology.dart.
 *
 * Difficulty changes the map only. Each level is a fixed, hand-authored shape,
 * not something computed from a difficulty score.
 */
export interface RouteTopology {
  nodeCount: number;
  /** Undirected edges as [a, b] node-index pairs. */
  edges: ReadonlyArray<readonly [number, number]>;
  homeIndex: number;
  destinationIndex: number;
  /** Dead-end branches off the main path. The real reported setting. */
  branchCount: number;
}

export function topologyForLevel(level: number): RouteTopology {
  switch (level) {
    case 1:
      return {
        nodeCount: 3,
        edges: [[0, 1], [1, 2]],
        homeIndex: 0,
        destinationIndex: 2,
        branchCount: 0,
      };
    case 2:
      return {
        nodeCount: 5,
        edges: [[0, 1], [1, 2], [1, 3], [3, 4]],
        homeIndex: 0,
        destinationIndex: 2,
        branchCount: 1,
      };
    default:
      return {
        nodeCount: 6,
        edges: [[0, 1], [1, 2], [2, 3], [1, 4], [2, 5]],
        homeIndex: 0,
        destinationIndex: 3,
        branchCount: 2,
      };
  }
}

/** Neighbour indices of `node`, from the undirected edge list. */
export function neighbours(t: RouteTopology, node: number): number[] {
  const out: number[] = [];
  for (const [a, b] of t.edges) {
    if (a === node) out.push(b);
    else if (b === node) out.push(a);
  }
  return out;
}

/** Shortest node path between two nodes, or [] when unreachable. */
export function shortestPath(
  t: RouteTopology,
  from: number,
  to: number,
): number[] {
  if (from === to) return [from];
  const prev = new Map<number, number>();
  const seen = new Set<number>([from]);
  const queue: number[] = [from];
  while (queue.length) {
    const node = queue.shift()!;
    if (node === to) break;
    for (const n of neighbours(t, node)) {
      if (seen.has(n)) continue;
      seen.add(n);
      prev.set(n, node);
      queue.push(n);
    }
  }
  if (!prev.has(to)) return [];
  const path = [to];
  let cur = to;
  while (cur !== from) {
    const p = prev.get(cur);
    if (p === undefined) return [];
    path.unshift(p);
    cur = p;
  }
  return path;
}

/** Fixed layout positions in a 0..1 unit square, per level shape. */
export function layoutForLevel(level: number): ReadonlyArray<readonly [number, number]> {
  switch (level) {
    case 1:
      return [[0.5, 0.85], [0.5, 0.55], [0.5, 0.2]];
    case 2:
      return [
        [0.5, 0.88], [0.5, 0.62], [0.5, 0.3],
        [0.18, 0.62], [0.14, 0.3],
      ];
    default:
      return [
        [0.5, 0.9], [0.5, 0.68], [0.5, 0.44], [0.5, 0.16],
        [0.16, 0.68], [0.85, 0.44],
      ];
  }
}
