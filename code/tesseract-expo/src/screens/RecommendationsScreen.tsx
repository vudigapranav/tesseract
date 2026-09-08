/**
 * The caregiver decision loop.
 *
 * The app proposes; the caregiver decides. Nothing here changes what a patient
 * is offered until a decision is recorded — accept, change the level, or
 * reject. Every suggestion shows the counts it was derived from, so a
 * caregiver can check it against what they actually saw.
 */
import React, { useEffect, useMemo, useState } from 'react';
import { View } from 'react-native';
import {
  Badge,
  BodyLarge,
  BodyMedium,
  Card,
  HeadlineLarge,
  PillButton,
  Screen,
  SectionHeading,
  StatusNote,
  TitleLarge,
} from '../design/components';
import { useApp } from '../state/AppState';
import { translate } from '../l10n/i18n';
import { GAME_REGISTRY, registrationFor } from '../games/registry';
import {
  describeSignal,
  signalsFrom,
  suggestionsFrom,
  type Decision,
  type Suggestion,
} from '../intelligence/recommendations';
import { readJson, writeJson } from '../data/storage';

const DECISIONS_KEY = 'activityDecisions';

export function RecommendationsScreen({ onBack }: { onBack: () => void }) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);

  const [decisions, setDecisions] = useState<Decision[]>([]);
  const [status, setStatus] = useState<string | null>(null);

  useEffect(() => {
    void readJson<Decision[]>(DECISIONS_KEY, []).then(setDecisions);
  }, []);

  const signals = useMemo(
    () => signalsFrom(app.outbox.sessions),
    [app.outbox.sessions],
  );

  const suggestions = useMemo(
    () =>
      suggestionsFrom(
        signals,
        (gameId) => registrationFor(gameId)?.maxLevel ?? 3,
      ),
    [signals],
  );

  const nameOf = (gameId: string) => {
    const reg = registrationFor(gameId);
    return reg
      ? translate(app.interfaceLanguage, reg.displayNameKey as never)
      : gameId;
  };

  const decide = async (
    s: Suggestion,
    decision: Decision['decision'],
    level: number,
  ) => {
    const record: Decision = {
      suggestionId: s.id,
      gameId: s.gameId,
      decision,
      level,
      decidedAt: new Date().toISOString(),
      basedOnRevision: app.selectedPatient?.profileRevision,
    };
    const next = [...decisions.filter((d) => d.gameId !== s.gameId), record];
    setDecisions(next);
    await writeJson(DECISIONS_KEY, next);

    // Sent to the server when there is one; the local decision already
    // applies either way, so an offline caregiver is never blocked.
    if (app.api) {
      try {
        await app.api.decideRecommendation(s.id, { decision, level });
        setStatus(t('decisionApproved'));
      } catch (e) {
        const conflict =
          typeof e === 'object' && e !== null && 'isConflict' in e
            ? (e as { isConflict: boolean }).isConflict
            : false;
        setStatus(
          conflict
            ? 'The server has a newer version of this patient. Your choice is saved here; refresh and review before sending it.'
            : t('savedOnDevice'),
        );
      }
    } else {
      setStatus(t('savedOnDevice'));
    }
  };

  const actionable = suggestions.filter(
    (s) => s.kind === 'raiseLevel' || s.kind === 'lowerLevel',
  );

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <HeadlineLarge>{t('needsYourDecision')}</HeadlineLarge>
      <BodyMedium tone="soft">{t('suggestionCaveat')}</BodyMedium>

      {status ? <StatusNote glyph="ℹ" text={status} /> : null}

      {actionable.length === 0 ? (
        <Card>
          <BodyLarge>{t('noActivityYet')}</BodyLarge>
          <StatusNote
            glyph="ℹ"
            text="Suggestions appear once there are enough finished sessions to base one on."
          />
        </Card>
      ) : null}

      {actionable.map((s) => {
        const decided = decisions.find((d) => d.gameId === s.gameId);
        return (
          <Card key={s.id}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
              <TitleLarge style={{ flex: 1 }}>{nameOf(s.gameId)}</TitleLarge>
              {decided ? <Badge label={decided.decision} /> : null}
            </View>
            <View style={{ height: 6 }} />
            <BodyLarge>
              {s.kind === 'raiseLevel'
                ? `Suggested: a slightly larger version (level ${s.proposedLevel}).`
                : `Suggested: a smaller version (level ${s.proposedLevel}).`}
            </BodyLarge>
            <View style={{ height: 6 }} />
            {/* The counts behind the suggestion, so it can be checked. */}
            <BodyMedium tone="soft">{s.reason}</BodyMedium>
            <View style={{ height: 6 }} />
            <StatusNote glyph="ℹ" text={s.caveat} />

            <View style={{ height: 8 }} />
            <PillButton
              label={t('useLevel')}
              onPress={() => void decide(s, 'accepted', s.proposedLevel)}
            />
            <PillButton
              label={t('chooseLevel')}
              variant="outline"
              onPress={() =>
                // "Modify" means the caregiver picks a different level than
                // the one proposed — here, staying where they are.
                void decide(s, 'modified', s.currentLevel)
              }
            />
            <PillButton
              label={t('keepAsIs')}
              variant="outline"
              onPress={() => void decide(s, 'rejected', s.currentLevel)}
            />
          </Card>
        );
      })}

      <SectionHeading title={t('observedMeasures')} />
      <Card>
        {signals.length === 0 ? (
          <BodyMedium tone="soft">{t('noActivityYet')}</BodyMedium>
        ) : (
          signals.map((sig) => (
            <View key={sig.gameId} style={{ paddingVertical: 6 }}>
              <BodyLarge>{describeSignal(sig, nameOf(sig.gameId))}</BodyLarge>
            </View>
          ))
        )}
        {/* Never a cognitive score, a diagnosis, or a progression measure. */}
        <StatusNote glyph="ℹ" text={t('doctorDisclaimer')} />
      </Card>

      <View style={{ height: 8 }} />
      <PillButton label={t('goBack')} onPress={onBack} />
      {/* Referenced so the registry stays the single source of activity names. */}
      {GAME_REGISTRY.length === 0 ? <BodyMedium>—</BodyMedium> : null}
    </Screen>
  );
}
