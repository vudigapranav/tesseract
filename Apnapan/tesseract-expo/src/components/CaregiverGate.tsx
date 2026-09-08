/**
 * The protected door back from patient mode.
 *
 * **Fails closed.** While capability is still loading there is no way through;
 * if the device offers no factor at all the gate stays shut and explains why.
 * The only paths that call `onUnlocked` are a successful OS authentication or
 * a correct caregiver PIN.
 *
 * The OS prompt puts the app into `inactive`, not `background`, which is why
 * `useOpeningScreen` ignores `inactive` — otherwise unlocking here would flash
 * the opening screen every time.
 */
import React, { useEffect, useState } from 'react';
import { TextInput, StyleSheet, View } from 'react-native';
import { colors, spacing } from '../design/tokens';
import {
  BodyLarge,
  BodyMedium,
  Card,
  HeadlineLarge,
  PillButton,
  Screen,
  StatusNote,
} from '../design/components';
import { useApp } from '../state/AppState';
import { translate } from '../l10n/i18n';
import {
  availableFactor,
  readCapability,
  unlockWithDevice,
  unlockWithPin,
  type AuthCapability,
} from '../data/caregiverAuth';

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

  const [capability, setCapability] = useState<AuthCapability | null>(null);
  const [pin, setPin] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    let alive = true;
    void readCapability().then((c) => {
      if (alive) setCapability(c);
    });
    return () => {
      alive = false;
    };
  }, []);

  const factor = availableFactor(capability);

  const tryDevice = async () => {
    setBusy(true);
    setError(null);
    const result = await unlockWithDevice(t('handOver'), t('cancel'));
    setBusy(false);
    if (result.ok) {
      onUnlocked();
      return;
    }
    // A cancellation is not a failure worth alarming anyone about, but it is
    // still not an unlock.
    if (result.reason !== 'cancelled') setError(t('signInFailed'));
  };

  const tryPin = async () => {
    setBusy(true);
    setError(null);
    const result = await unlockWithPin(pin);
    setBusy(false);
    setPin('');
    if (result.ok) onUnlocked();
    else setError(t('signInFailed'));
  };

  return (
    <Screen>
      <View style={{ height: 40 }} />
      <HeadlineLarge>{t('caregiverGreeting')}</HeadlineLarge>
      <View style={{ height: 12 }} />
      <Card>
        {factor === 'loading' ? (
          // No route through while capability is unknown.
          <StatusNote icon="lock" text={t('signingIn')} />
        ) : null}

        {factor === 'device' ? (
          <>
            <BodyLarge>{t('signInPatientNote')}</BodyLarge>
            <View style={{ height: 12 }} />
            <PillButton
              label={t('continueLabel')}
              busy={busy}
              onPress={tryDevice}
            />
          </>
        ) : null}

        {factor === 'pin' ? (
          <>
            <BodyLarge>{t('signInPatientNote')}</BodyLarge>
            <BodyMedium tone="soft">
              This device has no lock set up, so the caregiver PIN is used
              instead.
            </BodyMedium>
            <TextInput
              accessibilityLabel="Caregiver PIN"
              value={pin}
              onChangeText={setPin}
              keyboardType="number-pad"
              secureTextEntry
              style={styles.input}
            />
            <PillButton
              label={t('continueLabel')}
              busy={busy}
              disabled={pin.trim().length < 4}
              onPress={tryPin}
            />
          </>
        ) : null}

        {factor === 'none' ? (
          // Shut, and honest about it. No bypass button.
          <StatusNote
            icon="lock"
            tone="attention"
            text={
              'This device has no passcode, no biometrics and no caregiver PIN, ' +
              'so returning cannot be protected. Set a device passcode, or set ' +
              'a caregiver PIN in Settings while signed in.'
            }
          />
        ) : null}

        {error ? <StatusNote icon="alert" tone="attention" text={error} /> : null}

        <View style={{ height: 8 }} />
        <PillButton label={t('cancel')} variant="outline" onPress={onCancel} />
      </Card>
    </Screen>
  );
}

const styles = StyleSheet.create({
  input: {
    minHeight: spacing.minTarget,
    borderWidth: 1.5,
    borderColor: colors.hairline,
    borderRadius: 14,
    paddingHorizontal: 14,
    fontSize: 22,
    letterSpacing: 6,
    color: colors.ink,
    backgroundColor: colors.cream,
    marginVertical: 12,
  },
});
