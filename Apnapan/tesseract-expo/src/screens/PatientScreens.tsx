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
import { View } from 'react-native';
import { fontFamilyForScript, spacing } from '../design/tokens';
import {
  BigPatientAction,
  BodyLarge,
  Card,
  CoralAccent,
  HeadlineLarge,
  PillButton,
  Screen,
  StatusNote,
  TitleLarge,
} from '../design/components';
import { SpeakButton } from '../components/SpeakButton';
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
      <View style={{ height: 16 }} />
      <CoralAccent />
      <HeadlineLarge fontFamily={font}>{greeting}</HeadlineLarge>
      <SpeakButton text={greeting} languageCode={code} />

      <View style={{ height: 20 }} />
      <BigPatientAction
        label={t('readyToPlay')}
        onPress={onPlay}
        fontFamily={font}
      />
      <BigPatientAction
        label={t('todaysReminders')}
        primary={false}
        onPress={onReminders}
        fontFamily={font}
      />
      <BigPatientAction
        label={t('resting')}
        primary={false}
        onPress={onRest}
        fontFamily={font}
      />

      <View style={{ height: 24 }} />
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

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <HeadlineLarge fontFamily={font}>{t('whatWouldYouLikeToDo')}</HeadlineLarge>
      <View style={{ height: 16 }} />
      {GAME_REGISTRY.map((g) => (
        <BigPatientAction
          key={g.gameId}
          label={translate(code, g.displayNameKey as never)}
          primary={false}
          fontFamily={font}
          onPress={() => onChoose(g)}
        />
      ))}
      <View style={{ height: 16 }} />
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

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <TitleLarge fontFamily={font}>
        {translate(code, registration.displayNameKey as never)}
      </TitleLarge>
      <View style={{ height: 16 }} />
      <Card>
        <BodyLarge fontFamily={font}>{instructions}</BodyLarge>
        {/* Optional. The instruction stays on screen and Begin works whether
            or not anything is ever spoken. */}
        <SpeakButton text={instructions} languageCode={code} />
      </Card>
      <View style={{ height: 16 }} />
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
