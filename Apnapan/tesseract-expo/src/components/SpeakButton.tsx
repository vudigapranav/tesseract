/**
 * The control that reads the text on a screen aloud.
 *
 * A plain labelled button, not an icon alone: the people using patient mode
 * should not have to know what a speaker glyph means. It says "Read aloud",
 * says "Stop" while speaking, and when the language has no voice it says so
 * in words instead of quietly doing nothing.
 */
import React, { useEffect, useState } from 'react';
import { View } from 'react-native';
import { PillButton, StatusNote } from '../design/components';
import { useApp } from '../state/AppState';
import { translate } from '../l10n/i18n';
import { languageByCode, type LanguageCode } from '../l10n/languages';
import type { SpeechAvailability } from '../speech/tts';

export function SpeakButton({
  text,
  languageCode,
}: {
  /** Exactly the words already visible on screen. */
  text: string;
  languageCode: LanguageCode;
}) {
  const { speech } = useApp();
  const [availability, setAvailability] = useState<SpeechAvailability | null>(null);
  const [speaking, setSpeaking] = useState(false);
  const [playedOnce, setPlayedOnce] = useState(false);
  const [busy, setBusy] = useState(false);

  useEffect(() => speech.subscribe(() => setSpeaking(speech.isSpeaking)), [speech]);

  useEffect(() => {
    let cancelled = false;
    setPlayedOnce(false);
    void speech.availability(languageCode).then((a) => {
      if (!cancelled) setAvailability(a);
    });
    return () => {
      cancelled = true;
    };
  }, [speech, languageCode]);

  // Still probing: draw nothing rather than a control that is about to
  // disappear under a finger.
  if (!availability) return null;

  if (!availability.isAvailable) {
    const reason = availability.reason ?? 'engineError';
    const message =
      reason === 'audioOff'
        ? translate(languageCode, 'speechAudioOff')
        : reason === 'noEngine'
          ? translate(languageCode, 'speechNoEngine')
          : reason === 'noVoiceForLanguage'
            ? translate(languageCode, 'speechUnavailableForLanguage', {
                // Names the language, so it is obvious this is a gap in this
                // language rather than a fault the person caused.
                language: languageByCode(languageCode).endonym,
              })
            : translate(languageCode, 'speechFailed');
    return <StatusNote icon="speakerOff" text={message} />;
  }

  const label = speaking
    ? translate(languageCode, 'stopSpeaking')
    : playedOnce
      ? translate(languageCode, 'readAloudAgain')
      : translate(languageCode, 'speakThis');

  // Centred and only as wide as its words. It used to be a full-width pill,
  // which made it compete with the screen's actual action — on the
  // instructions screen there were four identical full-width pills stacked up
  // and no way to tell which one mattered.
  return (
    <View style={{ marginTop: 6, alignItems: 'center' }}>
      <PillButton
        label={label}
        variant="outline"
        compact
        disabled={busy && !speaking}
        onPress={async () => {
          if (speaking) {
            await speech.stop();
            return;
          }
          setBusy(true);
          const a = await speech.speak(text, languageCode);
          setAvailability(a);
          if (a.isAvailable) setPlayedOnce(true);
          setBusy(false);
        }}
      />
    </View>
  );
}
