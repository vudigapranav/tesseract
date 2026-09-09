/**
 * Picture Recall (G9) — the model, ported from Aryan's Flutter
 * `picture_recall_controller.dart`. Original design: Aryan.
 *
 * Pure TypeScript: no React, no timers, no I/O. The caller supplies the clock
 * in *active* milliseconds (the recorder's, which excludes paused time), so
 * exposure and answer latency stay honest across a break.
 *
 * The shape of the activity, preserved from the original:
 *
 *   viewing ──ready──► question ──answer/skip──► feedback ──next──► question
 *      ▲                   │                                          │
 *      └──── showAgain ────┘                                     …until done
 *
 * Two things it deliberately is not:
 *  - It is not Picture Pairs with different words. The patient looks at one
 *    *scene*, the scene goes away, and they are asked about what was in it.
 *  - It is not a test. Looking again is a first-class control, not a penalty,
 *    and the original records that support alongside the answer rather than
 *    subtracting for it.
 */
import { RECALL_SCENES, type RecallQuestion, type RecallScene } from '../../content/pictures';

export type RecallPhase = 'viewing' | 'question' | 'feedback' | 'finished';

export interface PictureRecallParams {
  /** How many of the scene's questions are asked. */
  questionCount: number;
  /** Answer choices per question. */
  choiceCount: number;
  /** Whether the patient may look at the scene again while answering. */
  allowShowAgain: boolean;
  [key: string]: unknown;
}

/**
 * Real settings per level.
 *
 * Level 1 asks one question with two choices and keeps "show me again"
 * available — the supported tier. Level 3 asks both authored questions with
 * three choices and no second look. The number of choices is capped by what
 * the content actually authored, so a level can never invent a distractor.
 */
export function pictureRecallDifficultyParams(level: number): PictureRecallParams {
  switch (level) {
    case 1:
      return { questionCount: 1, choiceCount: 2, allowShowAgain: true };
    case 2:
      return { questionCount: 2, choiceCount: 2, allowShowAgain: true };
    default:
      return { questionCount: 2, choiceCount: 3, allowShowAgain: false };
  }
}

export interface RecallAnswer {
  questionId: string;
  choiceId: string;
  correct: boolean;
  /** True when the patient looked again or used the hint for this question. */
  supported: boolean;
  showAgainCount: number;
  hintUsed: boolean;
  latencyMs: number;
}

export interface PictureRecallMetrics {
  questionsAnswered: number;
  questionsSkipped: number;
  showAgainCount: number;
  hintsUsed: number;
  exposureMs: number;
  /** Null when nothing was answered — never 0, which would read as failure. */
  firstAttemptAccuracy: number | null;
  /** Accuracy over answers given with no second look and no hint. */
  unsupportedAccuracy: number | null;
  completion: boolean;
}

/** Picks a scene. Deterministic given the same index, so a session can be replayed. */
export function sceneForIndex(index: number): RecallScene {
  return RECALL_SCENES[index % RECALL_SCENES.length];
}

export class PictureRecallBoard {
  private phaseValue: RecallPhase = 'viewing';
  private index = 0;
  private phaseStartedMs = 0;
  private exposureAccumulatedMs = 0;
  private answerAccumulatedMs = 0;
  private showAgainTotal = 0;
  private hintsTotal = 0;
  private hintOnThisQuestion = false;
  private readonly answers: RecallAnswer[] = [];
  private readonly skipped = new Set<string>();
  private readonly questionList: RecallQuestion[];

  constructor(
    readonly scene: RecallScene,
    private readonly params: PictureRecallParams,
  ) {
    // Never more questions than the scene actually authored. Asking a question
    // nobody wrote would mean inventing one about a picture.
    this.questionList = scene.questions.slice(0, params.questionCount);
  }

  get phase(): RecallPhase {
    return this.phaseValue;
  }

  get questionIndex(): number {
    return this.index;
  }

  get questionTotal(): number {
    return this.questionList.length;
  }

  get question(): RecallQuestion | null {
    return this.questionList[this.index] ?? null;
  }

  /**
   * The choices for the current question, trimmed to the level's count.
   *
   * The correct choice is always kept, however few are shown — trimming a list
   * down to distractors only would make the question unanswerable.
   */
  choices(): RecallQuestion['choices'] {
    const question = this.question;
    if (!question) return [];
    const correct = question.choices.find((c) => c.id === question.correctChoiceId);
    const others = question.choices.filter((c) => c.id !== question.correctChoiceId);
    const wanted = Math.max(2, Math.min(this.params.choiceCount, question.choices.length));
    const chosen = correct ? [correct, ...others] : [...others];
    return chosen.slice(0, wanted);
  }

  get hintAvailable(): boolean {
    return (
      this.phaseValue === 'question' &&
      !this.hintOnThisQuestion &&
      !!this.question?.hint
    );
  }

  get showAgainAvailable(): boolean {
    return this.phaseValue === 'question' && this.params.allowShowAgain;
  }

  get hintVisible(): boolean {
    return this.hintOnThisQuestion;
  }

  exposureMs(nowMs: number): number {
    return (
      this.exposureAccumulatedMs +
      (this.phaseValue === 'viewing' ? nowMs - this.phaseStartedMs : 0)
    );
  }

  private answerMs(nowMs: number): number {
    return (
      this.answerAccumulatedMs +
      (this.phaseValue === 'question' ? nowMs - this.phaseStartedMs : 0)
    );
  }

  /** The patient has looked and is ready to be asked. */
  ready(nowMs: number): boolean {
    if (this.phaseValue !== 'viewing') return false;
    this.exposureAccumulatedMs = this.exposureMs(nowMs);
    this.phaseValue = 'question';
    this.phaseStartedMs = nowMs;
    return true;
  }

  /** Look at the scene again. Recorded as support, never as a mistake. */
  showAgain(nowMs: number): boolean {
    if (!this.showAgainAvailable) return false;
    this.answerAccumulatedMs = this.answerMs(nowMs);
    this.showAgainTotal += 1;
    this.phaseValue = 'viewing';
    this.phaseStartedMs = nowMs;
    return true;
  }

  useHint(): string | null {
    if (!this.hintAvailable) return null;
    this.hintOnThisQuestion = true;
    this.hintsTotal += 1;
    return this.question?.hint ?? null;
  }

  answer(choiceId: string, nowMs: number): RecallAnswer | null {
    const question = this.question;
    if (this.phaseValue !== 'question' || !question) return null;
    if (!question.choices.some((c) => c.id === choiceId)) return null;

    const record: RecallAnswer = {
      questionId: question.id,
      choiceId,
      correct: choiceId === question.correctChoiceId,
      supported: this.showAgainTotal > 0 || this.hintOnThisQuestion,
      showAgainCount: this.showAgainTotal,
      hintUsed: this.hintOnThisQuestion,
      latencyMs: this.answerMs(nowMs),
    };
    this.answers.push(record);
    this.answerAccumulatedMs = record.latencyMs;
    this.phaseValue = this.isLastQuestion ? 'finished' : 'feedback';
    return record;
  }

  /** Move past a question without answering. Always available; never punished. */
  skip(nowMs: number): boolean {
    if (this.phaseValue !== 'viewing' && this.phaseValue !== 'question') return false;
    if (this.phaseValue === 'viewing') {
      this.exposureAccumulatedMs = this.exposureMs(nowMs);
    }
    const question = this.question;
    if (question) this.skipped.add(question.id);
    this.phaseValue = this.isLastQuestion ? 'finished' : 'feedback';
    return true;
  }

  next(nowMs: number): boolean {
    if (this.phaseValue !== 'feedback' || this.isLastQuestion) return false;
    this.index += 1;
    this.hintOnThisQuestion = false;
    this.answerAccumulatedMs = 0;
    this.phaseValue = 'question';
    this.phaseStartedMs = nowMs;
    return true;
  }

  private get isLastQuestion(): boolean {
    return this.index >= this.questionList.length - 1;
  }

  get isComplete(): boolean {
    return this.phaseValue === 'finished';
  }

  /** True only when every question was actually answered. */
  get answeredEverything(): boolean {
    return this.answers.length === this.questionList.length;
  }

  metrics(completion: boolean, nowMs: number): PictureRecallMetrics {
    const unsupported = this.answers.filter((a) => !a.supported);
    const ratio = (items: RecallAnswer[]) =>
      items.length === 0 ? null : items.filter((a) => a.correct).length / items.length;
    return {
      questionsAnswered: this.answers.length,
      questionsSkipped: this.skipped.size,
      showAgainCount: this.showAgainTotal,
      hintsUsed: this.hintsTotal,
      exposureMs: this.exposureMs(nowMs),
      firstAttemptAccuracy: ratio(this.answers),
      unsupportedAccuracy: ratio(unsupported),
      completion,
    };
  }
}
