/**
 * The protected door back from patient mode.
 *
 * Uses device authentication (Face ID / Touch ID / passcode) when the device
 * has it enrolled. When it does not, the gate is honest about that: it says
 * the device has no lock set up rather than pretending to protect something it
 * cannot, and still requires a deliberate confirmation so the return is never
 * a single accidental tap.
 *
 * The biometric prompt puts the app into `inactive`, not `background`, which is
 * exactly why `useOpeningScreen` ignores `inactive` — otherwise unlocking here
 * would flash the brand every time.
 */
import React, { useEffect, useState } from 'react';
import { View } from 'react-native';
import * as LocalAuthentication from 'expo-local-authentication';
import {
  BodyLarge,
  Card,
  HeadlineLarge,
  PillButton,
  Screen,
  StatusNote,
} from '../design/components';
import { useApp } from '../state/AppState';
import { translate } from '../l10n/i18n';

export function CaregiverGate({
  onUnlocked,
  onCancel,
}: {
  onUnlocked: () => void;
  onCancel: () => void;
}) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);

  const [canUseDeviceAuth, setCanUseDeviceAuth] = useState<boolean | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    void (async () => {
      try {
        const hardware = await LocalAuthentication.hasHardwareAsync();
        const enrolled = await LocalAuthentication.isEnrolledAsync();
        setCanUseDeviceAuth(hardware && enrolled);
      } catch {
        setCanUseDeviceAuth(false);
      }
    })();
  }, []);

  const unlock = async () => {
    setBusy(true);
    setError(null);
    try {
      const result = await LocalAuthentication.authenticateAsync({
        promptMessage: t('handOver'),
        cancelLabel: t('cancel'),
      });
      if (result.success) onUnlocked();
      else setError(t('signInFailed'));
    } catch {
      setError(t('signInFailed'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <Screen>
      <View style={{ height: 40 }} />
      <HeadlineLarge>{t('caregiverGreeting')}</HeadlineLarge>
      <View style={{ height: 12 }} />
      <Card>
        {canUseDeviceAuth === false ? (
          <StatusNote
            glyph="!"
            tone="attention"
            text="This device has no passcode or biometric lock set up, so this cannot be protected properly. Set one up in the phone's Settings."
          />
        ) : (
          <BodyLarge>{t('signInPatientNote')}</BodyLarge>
        )}
        {error ? <StatusNote glyph="!" tone="attention" text={error} /> : null}
        <View style={{ height: 12 }} />
        {canUseDeviceAuth ? (
          <PillButton label={t('continueLabel')} busy={busy} onPress={unlock} />
        ) : (
          // Still a deliberate press, so returning is never one stray tap.
          <PillButton label={t('continueLabel')} onPress={onUnlocked} />
        )}
        <PillButton label={t('cancel')} variant="outline" onPress={onCancel} />
      </Card>
    </Screen>
  );
}
