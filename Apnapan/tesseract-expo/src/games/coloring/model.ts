/**
 * Coloring (G5) — swipe to bring a picture's colours back.
 * Ported from Aryan's Flutter `swipe_reveal`. Original design: Aryan.
 *
 * The confirmed product direction (docs/PS003_PATIENT_EXPERIENCE.md) is
 * swipe-to-reveal, not tap-to-fill: no palette, no staying inside outlines, no
 * requirement to uncover every part. A broad stroke uncovers the original
 * colours underneath.
 *
 * Pure TypeScript. Coordinates are unit fractions of the picture box.
 *
 * Two jobs, deliberately separated:
 *
 *  1. **Coverage measurement** — a grid of cells, marked as the brush passes
 *     over them. This is what "how much has been uncovered" means, and it is
 *     the only thing the metrics need.
 *  2. **What is drawn** — the stroke path itself, handed to the view, which
 *     paints it as one thick polyline used as a mask.
 *
 * Keeping them apart is what makes this cheap. The original scanned all 4096
 * eligible cells on every pointer move; here a segment only visits the cells
 * inside its own bounding box, and the picture is drawn as a handful of paths
 * rather than thousands of separate rectangles.
 */

export interface ColoringParams {
  /** Grid resolution used for coverage. Not a rendering resolution. */
  gridSize: number;
  /** Brush radius as a fraction of the picture box. */
  brushRadius: number;
  /** Coverage at which the picture counts as uncovered. Never 100%. */
  completionCoverage: number;
  [key: string]: unknown;
}

/**
 * Real settings per level.
 *
 * "Harder" here means a finer brush and a little more of the picture, never a
 * timer and never a precision requirement. Level 1 has a wide brush and asks
 * for barely half the picture, so a few sweeps finish it.
 */
export function coloringDifficultyParams(level: number): ColoringParams {
  switch (level) {
    case 1:
      return { gridSize: 32, brushRadius: 0.13, completionCoverage: 0.5 };
    case 2:
      return { gridSize: 32, brushRadius: 0.1, completionCoverage: 0.62 };
    default:
      return { gridSize: 32, brushRadius: 0.08, completionCoverage: 0.72 };
  }
}

export interface Point {
  x: number;
  y: number;
}

/** A finger stroke, as the points the view will draw. */
export type Stroke = Point[];

export interface ColoringMetrics {
  /** Fraction of the picture uncovered by hand, 0..1. */
  manualCoverage: number;
  strokeCount: number;
  /** Active ms actually spent moving a finger, not time on screen. */
  interactionMs: number;
  /** True when Show the picture was used. Support, not failure. */
  helpUsed: boolean;
  completion: boolean;
}

const valid = (p: Point) =>
  Number.isFinite(p.x) && Number.isFinite(p.y) && p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1;

/**
 * How far apart two points must be before the stroke records another one.
 *
 * Without this, a finger resting still adds hundreds of identical points and
 * the path grows without bound for no visible gain.
 */
const MIN_STEP = 0.008;

/** Hard ceiling on stored points, so a very long session cannot grow forever. */
const MAX_POINTS_PER_STROKE = 400;

export class ColoringCanvas {
  private readonly covered = new Set<number>();
  private readonly strokeList: Stroke[] = [];
  private current: Stroke | null = null;
  private interactionAccumulatedMs = 0;
  private strokeStartedMs: number | null = null;
  private shown = false;

  constructor(private readonly params: ColoringParams) {}

  get strokes(): readonly Stroke[] {
    return this.current ? [...this.strokeList, this.current] : this.strokeList;
  }

  get brushRadius(): number {
    return this.params.brushRadius;
  }

  get pictureShown(): boolean {
    return this.shown;
  }

  /** 1 when Show the picture was used — what the patient sees is fully coloured. */
  get displayCoverage(): number {
    return this.shown ? 1 : this.coverage;
  }

  get coverage(): number {
    const total = this.params.gridSize * this.params.gridSize;
    return total === 0 ? 0 : this.covered.size / total;
  }

  get isComplete(): boolean {
    return this.shown || this.coverage >= this.params.completionCoverage;
  }

  interactionMs(nowMs: number): number {
    return (
      this.interactionAccumulatedMs +
      (this.strokeStartedMs === null ? 0 : nowMs - this.strokeStartedMs)
    );
  }

  begin(point: Point, nowMs: number): boolean {
    if (this.shown || this.current || !valid(point)) return false;
    this.current = [point];
    this.strokeStartedMs = nowMs;
    return true;
  }

  /** Returns true when the stroke actually advanced, so the view can redraw. */
  extend(point: Point): boolean {
    if (this.shown || !this.current || !valid(point)) return false;
    const last = this.current[this.current.length - 1];
    const dx = point.x - last.x;
    const dy = point.y - last.y;
    if (dx * dx + dy * dy < MIN_STEP * MIN_STEP) return false;

    this.markSegment(last, point);
    if (this.current.length < MAX_POINTS_PER_STROKE) this.current.push(point);
    else this.current[this.current.length - 1] = point;
    return true;
  }

  /** Ends the stroke. Returns how many cells it newly uncovered, for the event. */
  end(nowMs: number): { strokeIndex: number; newlyCovered: number } | null {
    if (!this.current) return null;
    const before = this.strokeList.length;
    this.strokeList.push(this.current);
    this.current = null;
    if (this.strokeStartedMs !== null) {
      this.interactionAccumulatedMs = this.interactionMs(nowMs);
      this.strokeStartedMs = null;
    }
    const newlyCovered = this.lastStrokeCells;
    this.lastStrokeCells = 0;
    return { strokeIndex: before, newlyCovered };
  }

  /** Help: uncover the whole picture. Recorded as support, never as failure. */
  showPicture(): void {
    this.shown = true;
  }

  private lastStrokeCells = 0;

  /**
   * Marks the cells a capsule between two points covers.
   *
   * Only cells inside the segment's bounding box are examined — for a 32-grid
   * and a 0.1 radius that is a few dozen, not the whole grid.
   */
  private markSegment(a: Point, b: Point): void {
    const { gridSize, brushRadius } = this.params;
    const minX = Math.max(0, Math.floor((Math.min(a.x, b.x) - brushRadius) * gridSize));
    const maxX = Math.min(gridSize - 1, Math.ceil((Math.max(a.x, b.x) + brushRadius) * gridSize));
    const minY = Math.max(0, Math.floor((Math.min(a.y, b.y) - brushRadius) * gridSize));
    const maxY = Math.min(gridSize - 1, Math.ceil((Math.max(a.y, b.y) + brushRadius) * gridSize));

    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const lengthSquared = dx * dx + dy * dy;

    for (let row = minY; row <= maxY; row++) {
      for (let col = minX; col <= maxX; col++) {
        const index = row * gridSize + col;
        if (this.covered.has(index)) continue;
        const cx = (col + 0.5) / gridSize;
        const cy = (row + 0.5) / gridSize;
        // Distance from the cell centre to the segment, clamped to its ends.
        const t =
          lengthSquared === 0
            ? 0
            : Math.max(0, Math.min(1, ((cx - a.x) * dx + (cy - a.y) * dy) / lengthSquared));
        const ex = cx - (a.x + t * dx);
        const ey = cy - (a.y + t * dy);
        if (ex * ex + ey * ey <= brushRadius * brushRadius) {
          this.covered.add(index);
          this.lastStrokeCells += 1;
        }
      }
    }
  }

  metrics(completion: boolean, nowMs: number): ColoringMetrics {
    return {
      manualCoverage: this.coverage,
      strokeCount: this.strokeList.length,
      interactionMs: this.interactionMs(nowMs),
      helpUsed: this.shown,
      completion,
    };
  }
}
