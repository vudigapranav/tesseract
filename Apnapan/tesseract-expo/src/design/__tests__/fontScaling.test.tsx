/**
 * The text-scaling policy.
 *
 * Scaling must stay on — an elderly user with low vision depends on it — but
 * it must be bounded, or a phone set to its largest text size bursts fixed
 * layouts. These assert both halves: nothing is pinned to 1.0, and nothing is
 * left uncapped.
 *
 * They read the rendered `maxFontSizeMultiplier` prop rather than a constant,
 * so a component that stops routing through the shared text components fails
 * here rather than silently regressing.
 */
import React from 'react';
import { render } from '@testing-library/react-native';
import { Text } from 'react-native';
import {
  Badge,
  BigPatientAction,
  BodyLarge,
  BodyMedium,
  HeadlineLarge,
  HeadlineSmall,
  PillButton,
  StatusNote,
  TitleLarge,
} from '../components';
import { fontScaleCaps, spacing, type as typeScale } from '../tokens';

/** Every `maxFontSizeMultiplier` on rendered Text nodes, in order. */
function capsIn(tree: ReturnType<typeof render>): Array<number | undefined> {
  // queryAll, not getAll: a busy button legitimately renders no Text at all.
  return tree.UNSAFE_queryAllByType(Text).map(
    (node) => node.props.maxFontSizeMultiplier as number | undefined,
  );
}

describe('the policy itself', () => {
  it('caps headings tightest, body loosest, button labels tighter still', () => {
    // Headings are already large at 100%, so they need the least extra room.
    expect(fontScaleCaps.heading).toBe(1.3);
    // Body is what someone actually has to read, so it gets the most.
    expect(fontScaleCaps.body).toBe(1.6);
    // A pill has bounded height; its label must not burst it.
    expect(fontScaleCaps.buttonLabel).toBe(1.2);
  });

  it('never pins text to unscaled', () => {
    // A cap of 1 would be "no scaling", which is the accessibility failure
    // this policy exists to avoid.
    for (const cap of Object.values(fontScaleCaps)) {
      expect(cap).toBeGreaterThan(1);
    }
  });

  it('keeps the base type scale readable for an elderly reader', () => {
    // The sizes were reduced on 2026-09-09 at the user's direction, because
    // the screens read as oversized. These floors are what stops that becoming
    // a slide towards small text: the scale may be tuned, but not shrunk past
    // the point where it needs an OS setting to be legible.
    expect(typeScale.headlineLarge.fontSize).toBeGreaterThanOrEqual(26);
    expect(typeScale.titleLarge.fontSize).toBeGreaterThanOrEqual(20);
    expect(typeScale.bodyLarge.fontSize).toBeGreaterThanOrEqual(16);
    // The patient's one instruction is the exception: it stays larger than
    // ordinary body text, because it is the sentence they actually must read.
    expect(typeScale.patientInstruction.fontSize).toBeGreaterThanOrEqual(18);
    expect(typeScale.patientInstruction.fontSize).toBeGreaterThan(
      typeScale.bodyLarge.fontSize,
    );
    // Type shrank; targets did not. Reach is not a typography decision.
    expect(spacing.patientTarget).toBe(64);
    expect(spacing.minTarget).toBe(48);
  });
});

describe('heading components', () => {
  it.each([
    ['HeadlineLarge', HeadlineLarge],
    ['HeadlineSmall', HeadlineSmall],
    ['TitleLarge', TitleLarge],
  ])('%s uses the heading cap', (_name, Component) => {
    const tree = render(<Component>Hello</Component>);
    expect(capsIn(tree)).toEqual([fontScaleCaps.heading]);
  });
});

describe('body components', () => {
  it.each([
    ['BodyLarge', BodyLarge],
    ['BodyMedium', BodyMedium],
  ])('%s uses the body cap', (_name, Component) => {
    const tree = render(<Component>Hello</Component>);
    expect(capsIn(tree)).toEqual([fontScaleCaps.body]);
  });

  it('StatusNote prose uses the body cap', () => {
    const tree = render(<StatusNote text="Saved on this device." />);
    expect(capsIn(tree)).toContain(fontScaleCaps.body);
  });
});

describe('labels inside bounded controls', () => {
  it('PillButton label uses the button cap', () => {
    const tree = render(<PillButton label="Sign in" />);
    expect(capsIn(tree)).toEqual([fontScaleCaps.buttonLabel]);
  });

  it('BigPatientAction caps both its label and its subtitle', () => {
    const tree = render(
      <BigPatientAction label="Start" subtitle="Route Quest" />,
    );
    expect(capsIn(tree)).toEqual([
      fontScaleCaps.buttonLabel,
      fontScaleCaps.buttonLabel,
    ]);
  });

  it('Badge uses the button cap', () => {
    const tree = render(<Badge label="Draft" />);
    expect(capsIn(tree)).toEqual([fontScaleCaps.buttonLabel]);
  });

  it('a busy PillButton renders a spinner and no uncapped label', () => {
    const tree = render(<PillButton label="Sign in" busy />);
    expect(capsIn(tree)).toEqual([]);
  });
});

describe('no shared text escapes the policy', () => {
  it.each([
    ['HeadlineLarge', HeadlineLarge],
    ['HeadlineSmall', HeadlineSmall],
    ['TitleLarge', TitleLarge],
    ['BodyLarge', BodyLarge],
    ['BodyMedium', BodyMedium],
  ])('%s leaves no Text uncapped', (_name, Component) => {
    const tree = render(<Component>Hello</Component>);
    for (const cap of capsIn(tree)) {
      expect(cap).toBeDefined();
    }
  });

  it('caps survive a style override from a screen', () => {
    // Screens pass `style` for colour and spacing; that must not be a way to
    // drop the cap.
    const tree = render(<BodyLarge style={{ fontSize: 40 }}>Hi</BodyLarge>);
    expect(capsIn(tree)).toEqual([fontScaleCaps.body]);
  });
});
