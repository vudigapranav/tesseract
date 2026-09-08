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
} from '../intelligence/recommendations';
import type { RecommendationOut } from '../data/apiClient';
import { patientKey } from '../data/storage';

const DECISIONS_KEY = 'activityDecisions';

export function RecommendationsScreen({ onBack }: { onBack: () => void }) {
  const app = useApp();
  const t = (
    k: Parameters<typeof translate>[1],
    values?: Record<string, string | number>,
  ) => translate(app.interfaceLanguage, k, values);

  const patientId = app.selectedPatient?.id ?? null;
  const [proposals, setProposals] = useState<RecommendationOut[] | null>(null);
  const [status, setStatus] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  /** Server proposals are the authority. Local observations are advice. */
  useEffect(() => {
    void (async () => {
      if (!app.api || !patientId) {
        setProposals([]);
        return;
      }
      try {
        const list = await app.api.listRecommendations(patientId);
        setProposals(list.items.filter((r) => r.status === 'pending'));
        setStatus(null);
      } catch {
        setProposals([]);
        setStatus(t('savedOnDevice'));
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [app.api, patientId]);

  const signals = useMemo(
    () => signalsFrom(app.outbox.sessions.filter((s) => s.snapshot.patientId === patientId)),
    [app.outbox.sessions, patientId],
  );

  const localObservations = useMemo(
    () =>
      suggestionsFrom(
        signals,
        (gameId) => registrationFor(gameId)?.maxLevel ?? 3,
      ).filter((x) => x.kind === 'raiseLevel' || x.kind === 'lowerLevel'),
    [signals],
  );

  const nameOf = (gameId: string) => {
    const reg = registrationFor(gameId);
    return reg
      ? translate(app.interfaceLanguage, reg.displayNameKey as never)
      : gameId;
  };

  /**
   * Records a decision against the **server's** recommendation id.
   *
   * The approved configuration is only stored after the server accepts. A
   * decision applied locally first would let the patient be handed an
   * activity the server never approved, and a 409 would leave the two
   * disagreeing with no way to tell which was right.
   */
  const decide = async (
    r: RecommendationOut,
    decision: 'accept' | 'modify' | 'reject',
    modifiedConfig?: Record<string, unknown>,
  ) => {
    if (!app.api || !patientId) {
      setStatus(t('savedOnDevice'));
      return;
    }
    setBusyId(r.recommendation_id);
    try {
      const updated = await app.api.decideRecommendation(r.recommendation_id, {
        decision,
        ...(modifiedConfig ? { modified_config: modifiedConfig } : {}),
        expected_config_version: r.based_on_config_version,
      });
      // Only now does the approved activity change locally.
      const activity = await app.api.getActivity(patientId);
      await app.store.write(patientKey(patientId, 'approvedActivity'), activity);
      setProposals((prev) =>
        (prev ?? []).filter((x) => x.recommendation_id !== updated.recommendation_id),
      );
      setStatus(
        decision === 'accept'
          ? t('decisionApproved')
          : decision === 'modify'
            ? t('decisionModified')
            : t('decisionRejected'),
      );
    } catch (e) {
      const conflict =
        typeof e === 'object' && e !== null && 'isConflict' in e
          ? (e as { isConflict: boolean }).isConflict
          : false;
      // Never overwrite approved configuration after a conflict.
      setStatus(conflict ? t('decisionFailed') : t('decisionFailed'));
    } finally {
      setBusyId(null);
    }
  };

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <HeadlineLarge>{t('needsYourDecision')}</HeadlineLarge>
      <BodyMedium tone="soft">{t('suggestionCaveat')}</BodyMedium>
      {status ? <StatusNote icon="info" text={status} /> : null}

      {proposals !== null && proposals.length === 0 ? (
        <Card>
          <BodyLarge>{t('noActivityYet')}</BodyLarge>
        </Card>
      ) : null}

      {(proposals ?? []).map((r) => {
        const level = Number(
          (r.proposed_config as { level?: unknown }).level ?? 0,
        );
        return (
          <Card key={r.recommendation_id}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
              <TitleLarge style={{ flex: 1 }}>
                {nameOf(String((r.proposed_config as { game_id?: unknown }).game_id ?? ''))}
              </TitleLarge>
              <Badge label={t('suggestedChange')} />
            </View>
            <View style={{ height: 6 }} />
            <BodyLarge>
              {level ? t('useLevel', { level }) : t('suggestedChange')}
            </BodyLarge>
            <BodyMedium tone="soft">
              {typeof r.reason === 'object'
                ? Object.entries(r.reason)
                    .map(([k, v]) => `${k.replace(/_/g, ' ')}: ${String(v)}`)
                    .join(' \u00b7 ')
                : String(r.reason)}
            </BodyMedium>
            <View style={{ height: 8 }} />
            <PillButton
              label={t('useLevel', { level })}
              busy={busyId === r.recommendation_id}
              onPress={() => void decide(r, 'accept')}
            />
            <PillButton
              label={t('chooseLevel')}
              variant="outline"
              onPress={() =>
                void decide(r, 'modify', {
                  ...r.current_config,
                })
              }
            />
            <PillButton
              label={t('keepAsIs')}
              variant="outline"
              onPress={() => void decide(r, 'reject')}
            />
          </Card>
        );
      })}

      {localObservations.length > 0 ? (
        <>
          <SectionHeading title={t('recentActivity')} />
          <Card>
            {/* Explicitly local. These are not server recommendations and
                cannot be accepted — they only tell a caregiver what this
                device has seen while offline. */}
            <StatusNote
              icon="info"
              tone="attention"
              text="From this device only. Not an approved recommendation, and nothing changes from here."
            />
            {localObservations.map((o) => (
              <View key={o.id} style={{ paddingVertical: 6 }}>
                <BodyLarge>{nameOf(o.gameId)}</BodyLarge>
                <BodyMedium tone="soft">{o.reason}</BodyMedium>
              </View>
            ))}
          </Card>
        </>
      ) : null}

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
        <StatusNote icon="info" text={t('doctorDisclaimer')} />
      </Card>

      <View style={{ height: 8 }} />
      <PillButton label={t('goBack')} onPress={onBack} />
      {/* Referenced so the registry stays the single source of activity names. */}
      {GAME_REGISTRY.length === 0 ? <BodyMedium>—</BodyMedium> : null}
    </Screen>
  );
}
