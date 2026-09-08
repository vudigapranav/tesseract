/**
 * Settings, the speech capability probe, and About Tesseract.
 *
 * The speech section is the honest answer to "does speech work in our
 * language?". It does not read a compiled-in table — it asks the engine on
 * this phone, per language, and reports exactly what it said. Until the
 * caregiver taps the check, every row says "not checked on this phone yet",
 * because that is the truth.
 */
import React, { useState } from 'react';
import { Image, StyleSheet, Switch, View } from 'react-native';
import { fontFamilyForScript } from '../design/tokens';
import {
  BodyLarge,
  BodyMedium,
  Card,
  Divider,
  HeadlineLarge,
  PillButton,
  Screen,
  SectionHeading,
  StatusNote,
  TitleLarge,
} from '../design/components';
import { LanguagePicker } from '../components/LanguagePicker';
import { useApp } from '../state/AppState';
import { translate } from '../l10n/i18n';
import { LANGUAGES, languageByCode } from '../l10n/languages';
import { appVersion } from '../data/config';
import { SPEECH_MATRIX } from '../speech/capability';
import {
  ExpoGoUnavailableRecognizer,
  VoiceInputController,
} from '../speech/voiceInput';

export function SettingsScreen({ onBack }: { onBack: () => void }) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);
  const font = fontFamilyForScript(languageByCode(app.interfaceLanguage).script);

  const [speechResults, setSpeechResults] = useState<
    Record<string, { out: boolean; inp: boolean; tag?: string }>
  >({});
  const [checked, setChecked] = useState(false);
  const [checking, setChecking] = useState(false);

  const runSpeechCheck = async () => {
    setChecking(true);
    const probe = new VoiceInputController(new ExpoGoUnavailableRecognizer());
    const next: typeof speechResults = {};
    try {
      for (const row of SPEECH_MATRIX) {
        // Output and input are asked separately. Support for one direction has
        // never implied the other, and on these languages it usually does not.
        const out = await app.speech.probe(row.code);
        const inp = await probe.probe(row.code);
        next[row.code] = { out: out.available, inp, tag: out.resolvedTag };
      }
    } finally {
      probe.dispose();
      setSpeechResults(next);
      setChecked(true);
      setChecking(false);
    }
  };

  const version = appVersion();

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <HeadlineLarge fontFamily={font}>{t('settingsAndSync')}</HeadlineLarge>

      <SectionHeading title={t('interfaceLanguage')} />
      <Card>
        <BodyMedium tone="soft">{t('interfaceLanguageHelp')}</BodyMedium>
        <View style={{ height: 8 }} />
        <LanguagePicker
          selected={app.interfaceLanguage}
          uiLanguage={app.interfaceLanguage}
          onSelect={(c) => void app.setInterfaceLanguage(c)}
        />
      </Card>

      <SectionHeading title={t('patientLanguage')} />
      <Card>
        <BodyMedium tone="soft">{t('patientLanguageHelp')}</BodyMedium>
        <View style={{ height: 8 }} />
        <LanguagePicker
          selected={app.patientLanguage}
          uiLanguage={app.interfaceLanguage}
          onSelect={(c) => void app.setPatientLanguage(c)}
          showUncovered={false}
        />
      </Card>

      <SectionHeading title={t('reminderSound')} />
      <Card>
        <Row
          label={t('reminderSound')}
          value={app.prefs.audioEnabled}
          onChange={(v) => void app.setPrefs({ audioEnabled: v })}
        />
        <Row
          label={t('reduceMotion')}
          value={app.prefs.reducedMotion}
          onChange={(v) => void app.setPrefs({ reducedMotion: v })}
        />
        <Row
          label="Use touch instead of phone motion"
          value={app.prefs.preferTouch}
          onChange={(v) => void app.setPrefs({ preferTouch: v })}
        />
      </Card>

      <SectionHeading title={t('speechSettingsTitle')} />
      <Card>
        <BodyMedium tone="soft">{t('speechSettingsSubtitle')}</BodyMedium>
        <View style={{ height: 12 }} />
        <PillButton
          label={t('speechCheckThisPhone')}
          variant="outline"
          busy={checking}
          onPress={runSpeechCheck}
        />
        <View style={{ height: 8 }} />

        {LANGUAGES.map((l) => {
          const r = speechResults[l.code];
          return (
            <View key={l.code} style={{ paddingVertical: 8 }}>
              <TitleLarge fontFamily={fontFamilyForScript(l.script)}>
                {l.endonym}
              </TitleLarge>
              {!checked ? (
                <BodyMedium tone="soft">{t('speechNotCheckedYet')}</BodyMedium>
              ) : (
                <>
                  <BodyMedium tone="soft">
                    {(r?.out ? '✓ ' : '✕ ') +
                      (r?.out
                        ? t('speechReadAloudAvailable')
                        : t('speechReadAloudUnavailable'))}
                  </BodyMedium>
                  <BodyMedium tone="soft">
                    {(r?.inp ? '✓ ' : '✕ ') +
                      (r?.inp
                        ? t('speechListeningAvailable')
                        : t('speechListeningUnavailable'))}
                  </BodyMedium>
                  {r?.tag ? <BodyMedium tone="soft">{r.tag}</BodyMedium> : null}
                </>
              )}
            </View>
          );
        })}

        {/* Applies to every row above, including any that came back available.
            A working voice is not a good voice. */}
        <StatusNote glyph="🗣" text={t('speechDraftWarning')} />
        {/* The Expo Go limitation, stated where it is relevant. */}
        <StatusNote
          glyph="!"
          tone="attention"
          text={
            'Speaking to the app is not possible in Expo Go: speech recognition ' +
            'needs a native module the Expo Go app does not contain. Reading ' +
            'aloud works. Every text and touch control is unaffected.'
          }
        />
      </Card>

      <SectionHeading title={t('synchronization')} />
      <Card>
        <BodyMedium tone="soft">
          {app.apiConfigured
            ? `${t('pendingUploads')}: ${app.pendingUploads}`
            : t('savedOnDevice')}
        </BodyMedium>
        <PillButton
          label={t('syncNow')}
          variant="outline"
          disabled={!app.apiConfigured}
          onPress={() => void app.syncNow()}
        />
      </Card>

      <SectionHeading title={t('aboutTesseract')} />
      <Card>
        {/* The full logo, wordmarks included, is the About presentation. */}
        <Image
          source={require('../../assets/branding/apnapan-logo.png')}
          style={aboutStyles.logo}
          resizeMode="contain"
          accessibilityLabel={`${t('appName')} — ${t('appNameHindi')}`}
        />
        <BodyLarge center style={{ marginBottom: 4 }}>
          {t('appTagline')}
        </BodyLarge>
        <Divider />
        <BodyLarge>{t('aboutDescription')}</BodyLarge>
        <Divider />
        {/* The app's own version, not the container it happens to run in. */}
        <BodyMedium tone="soft">
          {`${t('versionLabel')}: ${version.version}`}
        </BodyMedium>
        <BodyMedium tone="soft">{`Running in: ${version.runtime}`}</BodyMedium>
        {version.isExpoGo ? (
          <StatusNote
            glyph="ℹ"
            text={
              'This is the Tesseract version. Expo Go has its own separate ' +
              'version number, which is not ours.'
            }
          />
        ) : null}
        <Divider />
        {/* Exact attribution. Never translated, never altered. */}
        <BodyLarge>{t('builtBy')}</BodyLarge>
      </Card>

      <View style={{ height: 8 }} />
      <PillButton label={t('goBack')} variant="outline" onPress={onBack} />
      <PillButton label={t('signOut')} variant="outline" onPress={() => void app.signOut()} />
    </Screen>
  );
}

const aboutStyles = StyleSheet.create({
  logo: { width: '100%', height: 190, alignSelf: 'center', marginBottom: 8 },
});

function Row({
  label,
  value,
  onChange,
}: {
  label: string;
  value: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <View
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        minHeight: 48,
      }}
    >
      <BodyLarge style={{ flex: 1 }}>{label}</BodyLarge>
      <Switch
        accessibilityLabel={label}
        value={value}
        onValueChange={onChange}
      />
    </View>
  );
}
