/**
 * Caregiver / doctor sign-in, and the language choice that comes before it.
 *
 * Language is selectable **before** anyone signs in, because a caregiver who
 * cannot read English needs the sign-in screen itself in their language.
 * Switching does not clear what has been typed.
 *
 * There is no synthetic fallback here. A failed sign-in stays failed; the
 * preview is a separate, explicitly chosen, visibly labelled path.
 */
import React, { useState } from 'react';
import { Image, TextInput, StyleSheet, View } from 'react-native';
import { colors, fontFamilyForScript, spacing } from '../design/tokens';
import {
  BodyMedium,
  Card,
  CoralAccent,
  Divider,
  HeadlineLarge,
  PillButton,
  Screen,
  SectionHeading,
  StatusNote,
  TitleLarge,
} from '../design/components';
import { LanguagePicker } from '../components/LanguagePicker';
import { useApp, type Role } from '../state/AppState';
import { translate } from '../l10n/i18n';
import { languageByCode } from '../l10n/languages';
import { IdentityError } from '../data/identity';

export function SignInScreen() {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1], v?: Record<string, string>) =>
    translate(app.interfaceLanguage, k, v);
  const script = languageByCode(app.interfaceLanguage).script;
  const font = fontFamilyForScript(script);

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<Role>('caregiver');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showLanguages, setShowLanguages] = useState(false);

  const submit = async () => {
    setBusy(true);
    setError(null);
    try {
      await app.signIn(email.trim(), password, role);
    } catch (e) {
      // Distinguishes "wrong password" from "no connection" — telling someone
      // their details are wrong when the network is down sends them chasing
      // a problem that does not exist.
      setError(
        e instanceof IdentityError
          ? e.message
          : 'Sign-in did not work. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  };

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <View style={styles.brandRow}>
        <Image
          source={require('../../assets/branding/apnapan-icon.png')}
          style={styles.brandMark}
          resizeMode="contain"
          accessibilityElementsHidden
          importantForAccessibility="no"
        />
        <View style={{ flex: 1 }}>
          <HeadlineLarge fontFamily={font}>{t('appName')}</HeadlineLarge>
          {/* The Devanagari wordmark as real text, so it scales and is
              announced — not only as pixels inside the logo. */}
          <TitleLarge tone="soft" fontFamily="NotoSansDevanagari">
            {t('appNameHindi')}
          </TitleLarge>
        </View>
      </View>
      <CoralAccent />
      <BodyMedium tone="soft" fontFamily={font} style={{ marginTop: 2 }}>
        {t('appTagline')}
      </BodyMedium>
      <BodyMedium tone="soft" fontFamily={font} style={{ marginTop: 6 }}>
        {t('signInSubtitle')}
      </BodyMedium>

      <SectionHeading title={t('languageLabel')} />
      <Card>
        <TitleLarge fontFamily={fontFamilyForScript(script)}>
          {languageByCode(app.interfaceLanguage).endonym}
        </TitleLarge>
        <PillButton
          label={t('chooseLanguage')}
          variant="outline"
          onPress={() => setShowLanguages((s) => !s)}
        />
        {showLanguages ? (
          <View style={{ marginTop: 8 }}>
            <LanguagePicker
              compact
              selected={app.interfaceLanguage}
              uiLanguage={app.interfaceLanguage}
              onSelect={(code) => {
                // Applies immediately and keeps what is already typed.
                void app.setInterfaceLanguage(code);
              }}
            />
          </View>
        ) : null}
      </Card>

      <SectionHeading title={t('signIn')} />
      <Card>
        <View style={styles.roleRow}>
          <PillButton
            label={t('roleCaregiver')}
            variant={role === 'caregiver' ? 'primary' : 'outline'}
            onPress={() => setRole('caregiver')}
            style={styles.roleButton}
          />
          <PillButton
            label={t('roleDoctor')}
            variant={role === 'doctor' ? 'primary' : 'outline'}
            onPress={() => setRole('doctor')}
            style={styles.roleButton}
          />
        </View>
        <BodyMedium tone="soft">{t('signInTitle')}</BodyMedium>

        <Divider />

        <BodyMedium>
          {role === 'doctor' ? t('emailDoctor') : t('emailCaregiver')}
        </BodyMedium>
        <TextInput
          accessibilityLabel={
            role === 'doctor' ? t('emailDoctor') : t('emailCaregiver')
          }
          value={email}
          onChangeText={setEmail}
          autoCapitalize="none"
          autoComplete="email"
          keyboardType="email-address"
          style={styles.input}
        />
        <View style={{ height: 12 }} />
        <BodyMedium>{t('password')}</BodyMedium>
        <TextInput
          accessibilityLabel={t('password')}
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          autoCapitalize="none"
          style={styles.input}
        />

        <View style={{ height: 16 }} />

        {!app.identityConfigured ? (
          // Says exactly why sign-in cannot run, rather than failing opaquely.
          <StatusNote icon="alert" tone="attention" text={t('signInNotConfigured')} />
        ) : null}

        {error ? <StatusNote icon="alert" tone="attention" text={error} /> : null}

        <PillButton
          label={t('signIn')}
          busy={busy}
          disabled={!app.identityConfigured || email.length === 0 || password.length === 0}
          onPress={submit}
        />
      </Card>

      <SectionHeading title={t('openPreview')} />
      <Card>
        <StatusNote
          icon="flag"
          tone="attention"
          text={t('previewDataWarning')}
        />
        <PillButton
          label={t('openPreview')}
          variant="outline"
          onPress={() => void app.enterPreview()}
        />
      </Card>
    </Screen>
  );
}

const styles = StyleSheet.create({
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    marginBottom: 10,
  },
  brandMark: { width: 68, height: 68, borderRadius: 18 },
  roleRow: { flexDirection: 'row', gap: 12 },
  roleButton: { flex: 1 },
  input: {
    minHeight: spacing.minTarget,
    borderWidth: 1.5,
    borderColor: colors.hairline,
    borderRadius: 14,
    paddingHorizontal: 14,
    fontSize: 18,
    color: colors.ink,
    backgroundColor: colors.cream,
  },
});
