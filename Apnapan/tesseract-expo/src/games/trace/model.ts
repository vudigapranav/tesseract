/**
 * Trace (G4) — follow a line with a finger.
 * Ported from Aryan's Flutter `trace_controller.dart` / `trace_geometry.dart`.
 * Original design: Aryan.
 *
 * Pure TypeScript. Coordinates are unit fractions of the board.
 *
 * How "did they follow it" is decided, preserved from the original: the
 * reference path is cut into equal arc-length **bins**, and a bin counts as
 * visited when a sampled finger position comes within half the corridor width
 * of it. Progress is the fraction of bins visited.
 *
 * That is deliberately not "did the stroke look like the line". It means a
 * patient can go slowly, stop, lift their finger, start again in the middle,
 * or wander well off the line and come back — and still finish. Nothing here
 * measures neatness.
 *
 * Privacy: the raw stroke is kept for drawing and is capped, but it is the
 * view's to display and nobody's to send. Only bin coverage, counts and a
 * normalised average deviation ever leave the model.
 */

export interface TracePoint {
  x: number;
  y: number;
}

export interface TraceParams {
  /** How far apart sampled points are kept, in box fractions. */
  sampleSpacing: number;
  /** Bins along the path. More bins means a stricter idea of "all of it". */
  requiredBins: number;
  /** Corridor width; a bin counts as visited within half of this. */
  corridorWidth: number;
  /** Fraction of bins needed to finish. Never 1 — that would demand precision. */
  completionCoverage: number;
  [key: string]: unknown;
}

/**
 * Real settings per level, and a real change in what is being traced.
 *
 * Level 1 is a gentle curve with a wide corridor; level 3 is the house outline
 * with corners, a narrower corridor and more of the path required. The
 * templates come from the bundled catalogue, so difficulty is a different
 * shape, not the same shape judged more harshly.
 */
export function traceDifficultyParams(level: number): TraceParams {
  switch (level) {
    case 1:
      return {
        sampleSpacing: 0.01,
        requiredBins: 32,
        corridorWidth: 0.18,
        completionCoverage: 0.8,
      };
    case 2:
      return {
        sampleSpacing: 0.01,
        requiredBins: 48,
        corridorWidth: 0.14,
        completionCoverage: 0.85,
      };
    default:
      return {
        sampleSpacing: 0.01,
        requiredBins: 64,
        corridorWidth: 0.12,
        completionCoverage: 0.88,
      };
  }
}

const distance = (a: TracePoint, b: TracePoint) =>
  Math.sqrt((a.x - b.x) ** 2 + (a.y - b.y) ** 2);

const interpolate = (a: TracePoint, b: TracePoint, t: number): TracePoint => ({
  x: a.x + (b.x - a.x) * t,
  y: a.y + (b.y - a.y) * t,
});

/** Shortest distance from a point to a segment. */
export function segmentDistance(p: TracePoint, a: TracePoint, b: TracePoint): number {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const lengthSquared = dx * dx + dy * dy;
  if (lengthSquared === 0) return distance(p, a);
  const t = Math.max(
    0,
    Math.min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared),
  );
  return distance(p, interpolate(a, b, t));
}

export function nearestPathDistance(p: TracePoint, path: readonly TracePoint[]): number {
  let best = Number.POSITIVE_INFINITY;
  for (let i = 1; i < path.length; i++) {
    best = Math.min(best, segmentDistance(p, path[i - 1], path[i]));
  }
  return best;
}

/**
 * Bin centres at equal arc length along the path.
 *
 * Equal *arc length*, not equal index: an authored polyline has segments of
 * very different lengths, and binning by index would make a long straight run
 * count for as little as a tiny corner.
 */
export function referenceBins(
  path: readonly TracePoint[],
  count: number,
): TracePoint[] {
  const lengths: number[] = [];
  for (let i = 1; i < path.length; i++) lengths.push(distance(path[i - 1], path[i]));
  const total = lengths.reduce((a, b) => a + b, 0);
  if (total === 0) return [];

  const bins: TracePoint[] = [];
  for (let bin = 0; bin < count; bin++) {
    const target = (total * (bin + 0.5)) / count;
    let accumulated = 0;
    for (let i = 0; i < lengths.length; i++) {
      if (target <= accumulated + lengths[i] || i === lengths.length - 1) {
        const t = lengths[i] === 0 ? 0 : (target - accumulated) / lengths[i];
        bins.push(interpolate(path[i], path[i + 1], Math.max(0, Math.min(1, t))));
        break;
      }
      accumulated += lengths[i];
    }
  }
  return bins;
}

export interface TraceMetrics {
  /** Fraction of the path's bins visited, 0..1. */
  coverage: number;
  strokeCount: number;
  /** Times the finger was lifted mid-trace. Descriptive, never a penalty. */
  liftCount: number;
  /** Mean distance from the line, as a fraction of the board diagonal. */
  normalizedDeviation: number | null;
  guideUsed: boolean;
  completion: boolean;
}

/** Caps, so a long session cannot grow the stored path without bound. */
const MAX_STROKES = 64;
const MAX_POINTS_PER_STROKE = 300;

export class TraceBoard {
  private readonly bins: TracePoint[];
  private readonly visited = new Set<number>();
  private readonly strokeList: TracePoint[][] = [];
  private current: TracePoint[] | null = null;
  private deviationSum = 0;
  private deviationSamples = 0;
  private lifts = 0;
  private guide = false;

  constructor(
    readonly path: readonly TracePoint[],
    private readonly params: TraceParams,
  ) {
    this.bins = referenceBins(path, params.requiredBins);
  }

  get strokes(): readonly TracePoint[][] {
    return this.current ? [...this.strokeList, this.current] : this.strokeList;
  }

  get start(): TracePoint | null {
    return this.path[0] ?? null;
  }

  /** Named `finishPoint` rather than `end`, which is the lift-finger method. */
  get finishPoint(): TracePoint | null {
    return this.path[this.path.length - 1] ?? null;
  }

  get guideVisible(): boolean {
    return this.guide;
  }

  get coverage(): number {
    return this.bins.length === 0 ? 0 : this.visited.size / this.bins.length;
  }

  get isComplete(): boolean {
    return this.coverage >= this.params.completionCoverage;
  }

  /** Whether a bin has been reached, so the view can light the path up. */
  isBinVisited(index: number): boolean {
    return this.visited.has(index);
  }

  get binCount(): number {
    return this.bins.length;
  }

  binAt(index: number): TracePoint | undefined {
    return this.bins[index];
  }

  showGuide(): void {
    this.guide = true;
  }

  begin(point: TracePoint): boolean {
    if (this.current || this.strokeList.length >= MAX_STROKES) return false;
    if (!this.valid(point)) return false;
    this.current = [];
    this.sample(point);
    return true;
  }

  extend(point: TracePoint): boolean {
    if (!this.current || !this.valid(point)) return false;
    const last = this.current[this.current.length - 1];
    // Spatial resampling, as in the original: points closer together than the
    // sample spacing add nothing but cost.
    if (last && distance(last, point) < this.params.sampleSpacing) return false;
    this.sample(point);
    return true;
  }

  /** Lifts the finger, closing the current stroke. */
  endStroke(): boolean {
    if (!this.current) return false;
    if (this.current.length > 0) this.strokeList.push(this.current);
    this.current = null;
    // A lift is only counted when there is more still to trace — letting go
    // at the end of a finished line is not a lift, it is finishing.
    if (!this.isComplete) this.lifts += 1;
    return true;
  }

  private valid(p: TracePoint): boolean {
    return (
      Number.isFinite(p.x) && Number.isFinite(p.y) && p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1
    );
  }

  private sample(point: TracePoint): void {
    if (!this.current) return;
    if (this.current.length < MAX_POINTS_PER_STROKE) this.current.push(point);
    else this.current[this.current.length - 1] = point;

    const tolerance = this.params.corridorWidth / 2;
    for (let index = 0; index < this.bins.length; index++) {
      if (this.visited.has(index)) continue;
      if (distance(point, this.bins[index]) <= tolerance) this.visited.add(index);
    }

    this.deviationSum += nearestPathDistance(point, this.path);
    this.deviationSamples += 1;
  }

  metrics(completion: boolean): TraceMetrics {
    return {
      coverage: this.coverage,
      strokeCount: this.strokeList.length,
      liftCount: this.lifts,
      normalizedDeviation:
        this.deviationSamples === 0
          ? null
          : this.deviationSum / this.deviationSamples / Math.SQRT2,
      guideUsed: this.guide,
      completion,
    };
  }
}
