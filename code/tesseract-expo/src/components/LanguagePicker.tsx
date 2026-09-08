/**
 * Language selection, used both before sign-in and later in Settings.
 *
 * Every language shows its own name in its own script, so a speaker can find
 * theirs without reading English. Draft status and measured coverage are shown
 * plainly — a partial language is offered, but never as if it were finished.
 */
import React from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { colors, fontFamilyForScript, spacing } from '../design/tokens';
import { Badge, BodyMedium, StatusNote, TitleLarge } from '../design/components';
import {
  LANGUAGES,
  UNCOVERED_REGIONS,
  type LanguageCode,
  type LanguageOption,
} from '../l10n/languages';
import { translate } from '../l10n/i18n';

export function LanguagePicker({
  selected,
  onSelect,
  uiLanguage,
  showUncovered = true,
}: {
  selected: LanguageCode;
  onSelect: (code: LanguageCode) => void;
  /** Language the surrounding labels are drawn in. */
  uiLanguage: LanguageCode;
  showUncovered?: boolean;
}) {
  return (
    <View>
      {LANGUAGES.map((l: LanguageOption) => {
        const isSelected = l.code === selected;
        return (
          <Pressable
            key={l.code}
            accessibilityRole="radio"
            accessibilityState={{ selected: isSelected }}
            accessibilityLabel={`${l.endonym}. ${l.englishName}${
              l.reviewStatus === 'draft'
                ? `. Draft, ${l.coveragePercent} percent translated`
                : ''
            }`}
            onPress={() => onSelect(l.code)}
            style={({ pressed }) => [
              styles.row,
              isSelected && styles.rowSelected,
              pressed && { opacity: 0.8 },
            ]}
          >
            <View style={styles.rowText}>
              <TitleLarge fontFamily={fontFamilyForScript(l.script)}>
                {l.endonym}
              </TitleLarge>
              <BodyMedium tone="soft">
                {l.region ? `${l.englishName} · ${l.region}` : l.englishName}
              </BodyMedium>
            </View>
            {l.reviewStatus === 'draft' ? (
              <Badge label={`Draft · ${l.coveragePercent}%`} />
            ) : null}
            {isSelected ? <BodyMedium>✓</BodyMedium> : null}
          </Pressable>
        );
      })}

      {/* A partial language is honest about being partial. */}
      <StatusNote
        glyph="ℹ"
        text={translate(uiLanguage, 'draftTranslationNotice')}
      />

      {showUncovered ? (
        // The gap stays visible rather than being quietly papered over.
        <StatusNote
          glyph="!"
          tone="attention"
          text={`No language here yet for: ${UNCOVERED_REGIONS.join(', ')}.`}
        />
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    minHeight: spacing.minTarget + 16,
    paddingVertical: 14,
    paddingHorizontal: 16,
    borderRadius: spacing.cardRadius,
    backgroundColor: colors.white,
    marginVertical: 5,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  rowSelected: { borderColor: colors.ink },
  rowText: { flex: 1 },
});
