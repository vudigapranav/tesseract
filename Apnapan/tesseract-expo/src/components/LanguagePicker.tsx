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
  /**
   * First-run presentation: just the languages, no coverage badges and no
   * notices.
   *
   * Someone choosing a language before they have even signed in is answering
   * "which language do you read?", and a wall of percentages and caveats makes
   * that harder, not more honest. The disclosure lives in Settings, where a
   * caregiver decides what language the person they care for will actually
   * use, and where the information can change their mind. The underlying data
   * is unchanged: nothing is marked reviewed that has not been.
   */
  compact = false,
}: {
  selected: LanguageCode;
  onSelect: (code: LanguageCode) => void;
  /** Language the surrounding labels are drawn in. */
  uiLanguage: LanguageCode;
  showUncovered?: boolean;
  compact?: boolean;
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
            accessibilityLabel={
              compact
                ? `${l.endonym}. ${l.englishName}`
                : `${l.endonym}. ${l.englishName}${
                    l.reviewStatus === 'draft'
                      ? `. Draft, ${l.coveragePercent} percent translated`
                      : ''
                  }`
            }
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
            {!compact && l.reviewStatus === 'draft' ? (
              <Badge label={`Draft · ${l.coveragePercent}%`} />
            ) : null}
            {isSelected ? <BodyMedium>✓</BodyMedium> : null}
          </Pressable>
        );
      })}

      {/* A partial language is honest about being partial — in Settings,
          where the information is actionable. */}
      {!compact ? (
        <StatusNote
          icon="info"
          text={translate(uiLanguage, 'draftTranslationNotice')}
        />
      ) : null}

      {!compact && showUncovered ? (
        // The gap stays visible rather than being quietly papered over.
        <StatusNote
          icon="alert"
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
