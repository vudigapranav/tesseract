/**
 * The patient-facing screens: home, choose an activity, instructions, play,
 * finished and rest.
 *
 * Calmer than the caregiver side by design — few choices, large labelled
 * targets, no analytics, no developer controls, nothing that reads as a
 * medical record. Everything here is drawn in the **patient's** language,
 * which is configured separately from the caregiver's.
 */
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { colors, fontScaleCaps, fontFamilyForScript, spacing } from '../design/tokens';
import {
  BigPatientAction,
  BodyLarge,
  Card,
  CoralAccent,
  HeadlineLarge,
  PatientInstruction,
  PillButton,
  Screen,
  StatusNote,
  TitleLarge,
} from '../design/components';
import { SpeakButton } from '../components/SpeakButton';
import { ActivityPreview } from '../content/ActivityPreview';
import { PictureView } from '../content/PictureView';
import { useApp } from '../state/AppState';
import { translate } from '../l10n/i18n';
import { languageByCode } from '../l10n/languages';
import { GAME_REGISTRY, type GameRegistration } from '../games/registry';
import {
  GameInputMode,
  type GameConfig,
  type GameEvent,
  type GameResult,
  type GameStrings,
} from '../games/contract';
import { createOutboxSession } from '../data/outbox';
import { GAME_TEXT_EN, PLACEHOLDER_CONTENT } from '../games/gameText';
import { emptyKnowMe, itemsForGame, loadKnowMe, type KnowMeContent } from '../data/knowMe';

/**
 * Game strings, localised by the host.
 *
 * The six shared control labels come from the translated catalogue. The
 * game-specific wording is English-only — see `gameText.ts` for why that is a
 * stated limitation rather than a silent one.
 */
function buildGameStrings(code: string): GameStrings {
  const t = (k: Parameters<typeof translate>[1]) => translate(code as never, k);
  return {
    helpButtonLabel: t('help'),
    breakButtonLabel: t('breakLabel'),
    pausedTitle: t('takingABreak'),
    pausedBody: t('takingABreakBody'),
    resumeButtonLabel: t('continueLabel'),
    finishNowButtonLabel: t('finishForNow'),
    values: GAME_TEXT_EN,
  };
}

/* ------------------------------------------------------------------ home - */

export function PatientHomeScreen({
  onPlay,
  onRest,
  onReminders,
  onReturn,
}: {
  onPlay: () => void;
  onRest: () => void;
  onReminders: () => void;
  onReturn: () => void;
}) {
  const app = useApp();
  const code = app.patientLanguage;
  const t = (k: Parameters<typeof translate>[1]) => translate(code, k);
  const font = fontFamilyForScript(languageByCode(code).script);
  const greeting = t('patientHello');

  return (
    <Screen>
      <View style={{ height: 8 }} />
      {/* A familiar picture before any words. It is the first thing on the
          screen because it is the first thing that can be understood without
          reading. */}
      <View style={styles.homeArt}>
        <PictureView pictureId="img005" size={148} decorative />
      </View>

      <CoralAccent />
      <HeadlineLarge fontFamily={font}>{greeting}</HeadlineLarge>
      <SpeakButton text={greeting} languageCode={code} />

      <View style={{ height: 16 }} />
      {/* One clear action. Everything else on this screen is smaller than it. */}
      <BigPatientAction
        label={t('readyToPlay')}
        onPress={onPlay}
        fontFamily={font}
      />

      <View style={{ height: 4 }} />
      <View style={styles.homeSecondary}>
        <PillButton
          label={t('todaysReminders')}
          variant="outline"
          onPress={onReminders}
          style={styles.flex}
        />
        <PillButton
          label={t('resting')}
          variant="outline"
          onPress={onRest}
          style={styles.flex}
        />
      </View>

      <View style={{ height: 16 }} />
      {/* Small and out of the way: this is the caregiver's door back, and it
          is protected on the other side. */}
      <PillButton
        label={t('goBack')}
        variant="outline"
        onPress={onReturn}
      />
    </Screen>
  );
}

/**
 * How many activities the patient is offered before "Show me more".
 *
 * Ten at once is a wall. Four fits a phone without scrolling and is a
 * manageable number of things to choose between.
 */
const ACTIVITY_PAGE_SIZE = 4;

/** One activity, as a picture with its name underneath. */
function ActivityCard({
  registration,
  label,
  width,
  fontFamily,
  onPress,
}: {
  registration: GameRegistration;
  label: string;
  width: number;
  fontFamily?: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={({ pressed }) => [
        styles.activityCard,
        { width },
        pressed && styles.pressed,
      ]}
    >
      <ActivityPreview gameId={registration.gameId} size={width - 32} />
      <BodyLarge
        center
        numberOfLines={2}
        fontFamily={fontFamily}
        style={styles.activityLabel}
      >
        {label}
      </BodyLarge>
    </Pressable>
  );
}

/* -------------------------------------------------------- choose activity - */

export function ChooseActivityScreen({
  onChoose,
  onBack,
}: {
  onChoose: (reg: GameRegistration) => void;
  onBack: () => void;
}) {
  const app = useApp();
  const code = app.patientLanguage;
  const t = (k: Parameters<typeof translate>[1]) => translate(code, k);
  const font = fontFamilyForScript(languageByCode(code).script);

  const { width } = useWindowDimensions();
  const cardWidth = (width - spacing.gutter * 2 - 12) / 2;

  // A few at a time, with a way to see the rest. The whole catalogue at once
  // is more choices than this screen should ever put in front of someone.
  const [page, setPage] = useState(0);
  const pageCount = Math.ceil(GAME_REGISTRY.length / ACTIVITY_PAGE_SIZE);
  const shown = GAME_REGISTRY.slice(
    page * ACTIVITY_PAGE_SIZE,
    page * ACTIVITY_PAGE_SIZE + ACTIVITY_PAGE_SIZE,
  );

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <HeadlineLarge fontFamily={font}>{t('whatWouldYouLikeToDo')}</HeadlineLarge>
      <View style={{ height: 12 }} />

      <View style={styles.activityGrid}>
        {shown.map((g) => (
          <ActivityCard
            key={g.gameId}
            registration={g}
            label={translate(code, g.displayNameKey as never)}
            width={cardWidth}
            fontFamily={font}
            onPress={() => onChoose(g)}
          />
        ))}
      </View>

      {pageCount > 1 ? (
        <PillButton
          label={
            page + 1 < pageCount ? t('showMoreActivities') : t('showFirstActivities')
          }
          variant="outline"
          onPress={() => setPage((current) => (current + 1) % pageCount)}
        />
      ) : null}

      <View style={{ height: 8 }} />
      <PillButton label={t('home')} variant="outline" onPress={onBack} />
    </Screen>
  );
}

/* --------------------------------------------------------- how to play - */

export function HowToPlayScreen({
  registration,
  onBegin,
  onBack,
}: {
  registration: GameRegistration;
  onBegin: () => void;
  onBack: () => void;
}) {
  const app = useApp();
  const code = app.patientLanguage;
  const t = (k: Parameters<typeof translate>[1]) => translate(code, k);
  const font = fontFamilyForScript(languageByCode(code).script);

  // Marble Maze reads differently depending on whether motion is being used.
  const instructionKey =
    registration.motionFirst && app.prefs.preferTouch
      ? 'howToPlayMarbleMazeTouch'
      : registration.instructionKey;
  const instructions = translate(code, instructionKey as never);

  // The demonstration can be replayed. `demo` is a key that remounts the
  // picture, so pressing "Show me again" restarts it rather than doing nothing
  // visible — the patient asked to see it again, so something must happen.
  const [demo, setDemo] = useState(0);

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <TitleLarge center fontFamily={font}>
        {translate(code, registration.displayNameKey as never)}
      </TitleLarge>

      {/* The demonstration comes before the words, and is large enough to be
          the thing the eye lands on. */}
      <View style={styles.demoArt}>
        <ActivityPreview key={demo} gameId={registration.gameId} size={200} />
      </View>

      <PillButton
        label={demo === 0 ? t('watchHowItWorks') : t('watchAgain')}
        variant="outline"
        onPress={() => setDemo((n) => n + 1)}
      />

      <View style={{ height: 8 }} />
      {/* One instruction, at the patient instruction size. */}
      <PatientInstruction center fontFamily={font}>
        {instructions}
      </PatientInstruction>
      {/* Optional. The instruction stays on screen and Start works whether or
          not anything is ever spoken. */}
      <SpeakButton text={instructions} languageCode={code} />

      <View style={{ height: 12 }} />
      <BigPatientAction label={t('start')} onPress={onBegin} fontFamily={font} />
      <PillButton label={t('goBack')} variant="outline" onPress={onBack} />
    </Screen>
  );
}

/* --------------------------------------------------------------- play - */

export function PlayScreen({
  registration,
  level,
  onFinished,
}: {
  registration: GameRegistration;
  level: number;
  onFinished: (result: GameResult) => void;
}) {
  const app = useApp();
  const code = app.patientLanguage;
  const Game = registration.component;

  // The caregiver's own places, steps and words, when they have entered
  // enough. Below the threshold the game runs on the generic set instead of a
  // half-personal mixture, which would look personal without being it.
  const [knowMe, setKnowMe] = useState<KnowMeContent | null>(null);
  useEffect(() => {
    void loadKnowMe(app.store, app.selectedPatient?.id ?? 'local').then(setKnowMe);
  }, [app.store, app.selectedPatient?.id]);

  // The queued session is created only once content is known, so the
  // snapshot it uploads matches the configuration actually played. Creating
  // it earlier is what let 'local-v1' be recorded for a session that ran
  // different content.
  const session = useRef<ReturnType<typeof createOutboxSession> | null>(null);

  const config: GameConfig = useMemo(
    () => ({
      gameId: registration.gameId,
      gameVersion: '1',
      schemaVersion: '1',
      configVersion: 'local-v1',
      // The real content revision this session used, not a hardcoded '1'.
      contentVersion: knowMe?.localVersion ?? 'local-v1',
      metricVersion: '1',
      level,
      difficultyParams: registration.difficultyParamsForLevel(level),
      items:
        (knowMe ? itemsForGame(knowMe, registration.gameId) : null) ??
        sampleItemsFor(registration.gameId),
      strings: buildGameStrings(code),
      textScale: app.prefs.textScale,
      inputMode:
        registration.motionFirst && !app.prefs.preferTouch
          ? GameInputMode.tilt
          : GameInputMode.touch,
      showLabels: true,
      locale: code,
      isTutorial: false,
    }),
    [registration, level, code, app.prefs.textScale, app.prefs.preferTouch, knowMe],
  );

  // Held one frame until content is known, so a session never starts on the
  // generic set and then swaps to the caregiver's mid-play.
  if (knowMe === null) return <View style={{ flex: 1 }} />;

  if (session.current === null) {
    session.current = createOutboxSession({
      gameConfig: config,
      patientId: app.selectedPatient?.id ?? 'local',
      gameId: config.gameId,
      gameVersion: config.gameVersion,
      schemaVersion: config.schemaVersion,
      // The frozen, real values — not placeholders.
      configVersion: config.configVersion,
      contentVersion: config.contentVersion,
      metricVersion: config.metricVersion,
      level: config.level,
      difficultyParams: config.difficultyParams,
      requestedInputMode: config.inputMode,
      isTutorial: config.isTutorial,
      textScale: config.textScale,
      locale: config.locale,
    });
    void app.outbox.enqueue(session.current);
  }
  const active = session.current;

  return (
    <View style={{ flex: 1, paddingTop: spacing.gutter }}>
      <Game
        config={config}
        onEvent={(e: GameEvent) => {
          void app.outbox.record(active.clientSessionId, e);
        }}
        onFinish={(r: GameResult) => {
          void app.outbox.finalize(active.clientSessionId, r).then(() => {
            void app.syncNow();
          });
          onFinished(r);
        }}
      />
    </View>
  );
}

/* ----------------------------------------------------------- finished - */

export function FinishedScreen({
  result,
  onAgain,
  onHome,
}: {
  result: GameResult;
  onAgain: () => void;
  onHome: () => void;
}) {
  const app = useApp();
  const code = app.patientLanguage;
  const t = (k: Parameters<typeof translate>[1]) => translate(code, k);
  const font = fontFamilyForScript(languageByCode(code).script);
  const message = t('allDone');

  return (
    <Screen>
      <View style={{ height: 40 }} />
      <CoralAccent />
      <HeadlineLarge fontFamily={font}>{message}</HeadlineLarge>
      <SpeakButton text={message} languageCode={code} />
      <View style={{ height: 12 }} />
      {/* No score, no stars, no ranking. Finishing is the whole point. */}
      <BodyLarge tone="soft" fontFamily={font}>
        {result.status === 'completed' ? t('outcomeFinished') : t('outcomeStoppedEarly')}
      </BodyLarge>
      <View style={{ height: 28 }} />
      <BigPatientAction label={t('playAgain')} onPress={onAgain} fontFamily={font} />
      <BigPatientAction
        label={t('home')}
        primary={false}
        onPress={onHome}
        fontFamily={font}
      />
    </Screen>
  );
}

/* --------------------------------------------------------------- rest - */

export function RestScreen({ onReady, onHome }: { onReady: () => void; onHome: () => void }) {
  const app = useApp();
  const code = app.patientLanguage;
  const t = (k: Parameters<typeof translate>[1]) => translate(code, k);
  const font = fontFamilyForScript(languageByCode(code).script);
  const body = t('comeBackWhenReady');

  return (
    <Screen>
      <View style={{ height: 40 }} />
      <HeadlineLarge center fontFamily={font}>
        {t('resting')}
      </HeadlineLarge>
      <View style={{ height: 12 }} />
      <BodyLarge center tone="soft" fontFamily={font}>
        {body}
      </BodyLarge>
      <SpeakButton text={body} languageCode={code} />
      <View style={{ height: 32 }} />
      {/* Nothing here nudges anyone back into an activity: resting is a
          legitimate place to stay. */}
      <BigPatientAction label={t('readyToPlay')} onPress={onReady} fontFamily={font} />
      <BigPatientAction
        label={t('home')}
        primary={false}
        onPress={onHome}
        fontFamily={font}
      />
    </Screen>
  );
}

/* ------------------------------------------------------------ content - */

/** Placeholder content until Know Me personalization is uploaded. */
function sampleItemsFor(gameId: string) {
  return PLACEHOLDER_CONTENT[gameId] ?? [];
}

const styles = StyleSheet.create({
  homeArt: { alignItems: 'center', paddingBottom: 12 },
  homeSecondary: { flexDirection: 'row', gap: 10 },
  flex: { flex: 1 },
  activityGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
    justifyContent: 'flex-start',
  },
  activityCard: {
    backgroundColor: colors.white,
    borderRadius: spacing.cardRadius,
    borderWidth: 1.5,
    borderColor: colors.hairline,
    alignItems: 'center',
    paddingVertical: 14,
    paddingHorizontal: 8,
    // Comfortably above the patient target: the whole card is the control.
    minHeight: spacing.patientTarget * 2,
    gap: 8,
  },
  activityLabel: { fontWeight: '600' },
  pressed: { opacity: 0.85 },
  demoArt: { alignItems: 'center', paddingVertical: 14 },
});
