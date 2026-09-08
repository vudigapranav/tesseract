/**
 * The generated analysis, for a caregiver or a doctor.
 *
 * One component serves both, because the *content* is the same: counts the
 * server computed from stored sessions, optionally rephrased by a model, plus
 * the limitations that go with them. What differs between the two roles is not
 * the layout — it is what the server will hand over.
 *
 * Authorization is entirely the server's.
 * `POST /v1/patients/{id}/reports` requires caregiver membership or a live
 * doctor assignment (`require_patient_access`). Choosing "Doctor" at sign-in
 * grants nothing: an unassigned doctor gets 403 for this patient, and this
 * screen shows that refusal rather than working around it. Nothing here
 * decides access, and nothing here is cached across accounts.
 *
 * States, all of them visible rather than implied:
 *  - no server configured  → says so, offers nothing to press
 *  - loading               → the button shows busy, nothing else changes
 *  - refused (403)         → says access was refused, offers no retry
 *  - failed                → says so and offers Try again
 *  - no sessions yet       → says there is nothing to summarise, and that this
 *                            is a fact about the app's data, not the person
 *  - fallback text         → says the summary is the built-in wording and why
 */
import React, { useCallback, useState } from 'react';
import { View } from 'react-native';
import {
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
import type { ReportOut } from '../data/apiClient';

/** How far back the report looks. The server clamps this too. */
const WINDOW_DAYS = 30;

type Phase =
  | { kind: 'idle' }
  | { kind: 'loading' }
  | { kind: 'ready'; report: ReportOut }
  | { kind: 'refused' }
  | { kind: 'failed' };

/** What the report's content block actually carries, as far as this screen reads it. */
interface ReportContent {
  narrative?: string;
  fallback_reason?: string | null;
  limitations?: string[];
  review_state?: string;
  summary?: {
    games?: Array<{
      game_id?: string;
      sessions_total?: number;
      sessions_comparable?: number;
      baseline_state?: string;
      recent_sessions?: Array<{ unavailable_metrics?: string[] }>;
    }>;
  };
}

export function AnalysisScreen({
  patientId,
  patientName,
  onBack,
}: {
  patientId: string;
  patientName: string;
  onBack: () => void;
}) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);

  const [phase, setPhase] = useState<Phase>({ kind: 'idle' });

  const generate = useCallback(async () => {
    if (!app.api) return;
    setPhase({ kind: 'loading' });
    try {
      setPhase({ kind: 'ready', report: await app.api.createReport(patientId, WINDOW_DAYS) });
    } catch (error) {
      // A refusal is not a failure to retry. Retrying a 403 in a loop tells
      // the person nothing and hammers the server.
      const status = (error as { status?: number } | null)?.status;
      setPhase({ kind: status === 403 || status === 404 ? 'refused' : 'failed' });
    }
  }, [app.api, patientId]);

  const report = phase.kind === 'ready' ? phase.report : null;
  const content = (report?.content ?? {}) as ReportContent;
  const games = content.summary?.games ?? [];
  const hasSessions = games.some((g) => (g.sessions_total ?? 0) > 0);

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <HeadlineLarge>{t('analysisTitle')}</HeadlineLarge>
      <BodyMedium tone="soft">{patientName}</BodyMedium>

      {!app.apiConfigured ? (
        <StatusNote icon="sync" tone="attention" text={t('analysisNeedsServer')} />
      ) : null}

      <Card>
        <BodyMedium tone="soft">{t('analysisWindow')}</BodyMedium>
        <PillButton
          label={report ? t('analysisRefresh') : t('analysisGenerate')}
          busy={phase.kind === 'loading'}
          disabled={!app.apiConfigured || phase.kind === 'loading'}
          onPress={() => void generate()}
        />

        {phase.kind === 'refused' ? (
          // The server decided this, and it is the answer — not an error to
          // work around in the client.
          <StatusNote icon="alert" tone="attention" text={t('analysisRefused')} />
        ) : null}

        {phase.kind === 'failed' ? (
          <>
            <StatusNote icon="alert" tone="attention" text={t('analysisFailed')} />
            <PillButton
              label={t('tryAgain')}
              variant="outline"
              onPress={() => void generate()}
            />
          </>
        ) : null}
      </Card>

      {report ? (
        <>
          <SectionHeading title={t('analysisSummary')} />
          <Card>
            {!hasSessions ? (
              <BodyLarge tone="soft">{t('analysisNoSessions')}</BodyLarge>
            ) : (
              <BodyLarge>{content.narrative ?? ''}</BodyLarge>
            )}

            {/* Which generator wrote this, always. A caregiver should never
                have to guess whether they are reading a model's wording. */}
            <BodyMedium tone="soft">
              {report.generator === 'llm'
                ? t('analysisByModel')
                : t('analysisByTemplate')}
            </BodyMedium>

            {report.generator !== 'llm' && content.fallback_reason ? (
              // Named, not hidden: "the model timed out" and "the model was
              // switched off" are different things to the person maintaining this.
              <BodyMedium tone="soft">
                {`${t('analysisFallbackReason')} ${content.fallback_reason}`}
              </BodyMedium>
            ) : null}

            <StatusNote icon="info" text={t('doctorDisclaimer')} />
          </Card>

          <SectionHeading title={t('analysisActivity')} />
          {games.length === 0 ? (
            <Card>
              <BodyLarge tone="soft">{t('analysisNoSessions')}</BodyLarge>
            </Card>
          ) : (
            games.map((game) => {
              const missing = Array.from(
                new Set(
                  (game.recent_sessions ?? []).flatMap(
                    (s) => s.unavailable_metrics ?? [],
                  ),
                ),
              );
              return (
                <Card key={game.game_id ?? Math.random().toString()}>
                  <TitleLarge>
                    {String(game.game_id ?? '').replace(/_/g, ' ')}
                  </TitleLarge>
                  <BodyLarge>
                    {`${t('analysisSessionsRecorded')} ${game.sessions_total ?? 0}`}
                  </BodyLarge>
                  <BodyLarge>
                    {`${t('analysisSessionsComparable')} ${game.sessions_comparable ?? 0}`}
                  </BodyLarge>
                  {game.baseline_state !== 'established' ? (
                    <BodyMedium tone="soft">{t('analysisNoBaseline')}</BodyMedium>
                  ) : null}
                  {missing.length > 0 ? (
                    // Absent is shown as absent. A metric this game does not
                    // export must never be rendered as a zero.
                    <BodyMedium tone="soft">
                      {`${t('analysisNotMeasured')} ${missing
                        .map((m) => m.replace(/_/g, ' '))
                        .join(', ')}`}
                    </BodyMedium>
                  ) : null}
                </Card>
              );
            })
          )}

          <SectionHeading title={t('analysisLimitations')} />
          <Card>
            {(content.limitations ?? []).map((line) => (
              <BodyMedium key={line} tone="soft">
                {`• ${line}`}
              </BodyMedium>
            ))}
            <StatusNote icon="flag" tone="attention" text={t('analysisDraftOnly')} />
          </Card>
        </>
      ) : null}

      <View style={{ height: 8 }} />
      <PillButton label={t('goBack')} onPress={onBack} />
    </Screen>
  );
}
