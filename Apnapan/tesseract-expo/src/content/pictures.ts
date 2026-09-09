/**
 * The bundled picture catalogue.
 *
 * Original vector artwork from Aryan's staged package
 * (`tmp/incoming/aryan/extracted/assets/demo/catalog_v1.json`), authored for
 * this project. Provenance matters here: these are drawn as coloured
 * primitives rather than sourced photographs, so there is no licence to
 * honour, no remote URL to break, and — the point that actually matters — no
 * photograph of a real private person in a dementia app.
 *
 * Every picture is a short list of rectangles, ellipses and polygons on a
 * 0-100 canvas. That makes them tiny (about 20KB for the whole catalogue),
 * resolution-independent, and legible when drawn at 60px on a card or at 300px
 * as a scene. `PictureView` renders them with react-native-svg.
 *
 * Ten pictures, deliberately related:
 *   Book, Cup, Flower, Ball        — single familiar objects
 *   House and sun / House          — a pair differing by one thing
 *   Flower garden / …without sun and ball — a pair differing by two
 *   Book and cup / Flower and ball — scenes built from the single objects
 *
 * That structure is what lets one catalogue serve card faces, spot-the-
 * difference pairs, and picture-recall scenes whose answer choices are the
 * very objects that appeared in the scene.
 */
import catalog from './catalog_v1.json';

export type Primitive =
  | { type: 'rect'; rect: [number, number, number, number]; color: string }
  | { type: 'ellipse'; rect: [number, number, number, number]; color: string }
  | { type: 'polygon'; points: Array<[number, number]>; color: string };

export interface Picture {
  id: string;
  version: number;
  /** English label. Patient-facing text is localised separately. */
  label: string;
  primitives: Primitive[];
}

/** The drawing canvas every picture is authored against. */
export const PICTURE_CANVAS = 100;

export const PICTURES: Picture[] = (catalog.images as unknown as Picture[]).map(
  (image) => ({
    id: image.id,
    version: image.version,
    label: image.label,
    primitives: image.primitives,
  }),
);

const BY_ID = new Map(PICTURES.map((p) => [p.id, p]));

export function pictureById(id: string): Picture | undefined {
  return BY_ID.get(id);
}

/**
 * Single objects, suitable as a card face or an answer choice.
 *
 * The composite scenes are excluded on purpose: a card showing "book and cup"
 * next to a card showing "book" is a confusing thing to ask someone to match.
 */
export const OBJECT_PICTURE_IDS = ['img001', 'img002', 'img003', 'img004'] as const;

/** Scenes, for picture recall and coloring. */
export const SCENE_PICTURE_IDS = [
  'img005',
  'img007',
  'img009',
  'img010',
] as const;

/**
 * Pairs that differ by a known number of visible things, with the regions the
 * differences occupy. Authored alongside the artwork, not derived from it —
 * comparing two pictures pixel by pixel at runtime would be both slow and
 * wrong (an antialiased edge is not a difference a person can see).
 *
 * Regions are fractions of the picture box, so they survive any render size.
 */
export interface DifferenceRegion {
  id: string;
  left: number;
  top: number;
  width: number;
  height: number;
  /** Extra forgiveness around the region, as a fraction of the box. */
  margin: number;
}

export interface DifferencePair {
  id: string;
  leftPictureId: string;
  rightPictureId: string;
  regions: DifferenceRegion[];
}

export const DIFFERENCE_PAIRS: DifferencePair[] = (catalog.entries as any[])
  .filter((entry) => entry.config?.gameId === 'G6')
  .map((entry) => ({
    id: entry.content.id,
    leftPictureId: entry.content.assets[0],
    rightPictureId: entry.content.assets[1],
    regions: entry.content.metadata.regions as DifferenceRegion[],
  }));

/**
 * Scenes with prepared questions about what was in them.
 *
 * The questions and their distractors are authored content, not generated:
 * every choice is one of the catalogue's own objects, and the correct answer
 * is an object that genuinely appears in the scene.
 */
export interface RecallChoice {
  id: string;
  label: string;
  imageId: string;
}

export interface RecallQuestion {
  id: string;
  prompt: string;
  hint: string | null;
  correctChoiceId: string;
  choices: RecallChoice[];
}

export interface RecallScene {
  id: string;
  scenePictureId: string;
  questions: RecallQuestion[];
}

export const RECALL_SCENES: RecallScene[] = (catalog.entries as any[])
  .filter((entry) => entry.config?.gameId === 'G9')
  .map((entry) => ({
    id: entry.content.id,
    scenePictureId: entry.content.assets[0],
    questions: (entry.content.metadata.questions as any[]).map((q) => ({
      id: q.id,
      prompt: q.prompt,
      hint: q.hint ?? null,
      correctChoiceId: q.correctChoiceId,
      choices: (q.choices as any[]).map((c) => ({
        id: c.id,
        label: c.label,
        imageId: c.imageId,
      })),
    })),
  }));

/**
 * Shapes to trace, as a path through the unit square.
 *
 * `corridorWidth` is how far off the line a stroke may wander and still count,
 * also in unit terms, so tolerance scales with the screen rather than being a
 * pixel count that is generous on a tablet and cruel on a small phone.
 */
export interface TraceTemplate {
  id: string;
  kind: 'curve' | 'shape' | 'object';
  path: Array<[number, number]>;
  corridorWidth: number;
}

export const TRACE_TEMPLATES: TraceTemplate[] = (catalog.entries as any[])
  .filter((entry) => entry.config?.gameId === 'G4')
  .map((entry) => ({
    id: entry.content.id,
    kind: entry.content.metadata.kind,
    path: entry.content.metadata.referencePath as Array<[number, number]>,
    corridorWidth: entry.content.metadata.corridorWidth as number,
  }));
