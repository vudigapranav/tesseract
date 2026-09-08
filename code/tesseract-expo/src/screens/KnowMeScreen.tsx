/**
 * Know Me: where a caregiver puts the real places, routine steps, words and
 * pictures that make the activities about the person, not about a generic app.
 *
 * Everything typed here stays in the caregiver's own script, and none of it
 * ever reaches an event payload — games see labels, telemetry sees ids.
 */
import React, { useEffect, useState } from 'react';
import { Pressable, StyleSheet, TextInput, View } from 'react-native';
import { colors, fontFamilyForScript, spacing } from '../design/tokens';
import {
  Badge,
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
import { useApp } from '../state/AppState';
import { translate } from '../l10n/i18n';
import { languageByCode } from '../l10n/languages';
import {
  PICTURE_CATEGORIES,
  bumpLocalVersion,
  countFor,
  emptyKnowMe,
  hasEnoughContent,
  loadKnowMe,
  saveKnowMe,
  type KnowMeContent,
  type KnowMeKind,
} from '../data/knowMe';
import { newId } from '../data/outbox';
import { GAME_REGISTRY } from '../games/registry';

const SECTIONS: Array<{
  kind: KnowMeKind;
  title: string;
  hint: string;
  feeds: string;
}> = [
  {
    kind: 'place',
    title: 'Places they know',
    hint: 'Home first, then places they walk to. Used in Route Quest.',
    feeds: 'route_quest',
  },
  {
    kind: 'step',
    title: 'Their morning, in order',
    hint: 'The real order matters — it is the answer. Used in Daily Routine Recall.',
    feeds: 'routine_recall',
  },
  {
    kind: 'word',
    title: 'Words that mean something',
    hint: 'Short words work best. Used in Word Search.',
    feeds: 'word_search',
  },
  {
    kind: 'picture',
    title: 'Things to sort',
    hint: 'Pick where each one belongs. Used in Picture Sorting.',
    feeds: 'picture_sorting',
  },
];

export function KnowMeScreen({ onBack }: { onBack: () => void }) {
  const app = useApp();
  const t = (k: Parameters<typeof translate>[1]) =>
    translate(app.interfaceLanguage, k);
  const patientId = app.selectedPatient?.id ?? 'local';
  // Content is entered in the patient's language, so it renders in that script.
  const patientScript = languageByCode(app.patientLanguage).script;
  const font = fontFamilyForScript(patientScript);

  const [content, setContent] = useState<KnowMeContent>(emptyKnowMe());
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  const [category, setCategory] = useState<string>(PICTURE_CATEGORIES[0].id);
  const [loaded, setLoaded] = useState(false);
  const [status, setStatus] = useState<string | null>(null);

  useEffect(() => {
    void loadKnowMe(patientId).then((c) => {
      setContent(c);
      setLoaded(true);
    });
  }, [patientId]);

  const persist = async (next: KnowMeContent) => {
    setContent(next);
    await saveKnowMe(patientId, next);
  };

  const add = async (kind: KnowMeKind) => {
    const label = (drafts[kind] ?? '').trim();
    if (!label) return;
    const next: KnowMeContent = {
      ...content,
      entries: [
        ...content.entries,
        {
          id: newId(),
          kind,
          label,
          locale: app.patientLanguage,
          categoryId: kind === 'picture' ? category : undefined,
        },
      ],
      dirty: true,
      localVersion: bumpLocalVersion(),
    };
    setDrafts((d) => ({ ...d, [kind]: '' }));
    await persist(next);
  };

  const remove = async (id: string) => {
    await persist({
      ...content,
      entries: content.entries.filter((e) => e.id !== id),
      dirty: true,
      localVersion: bumpLocalVersion(),
    });
  };

  const move = async (id: string, delta: number) => {
    const list = [...content.entries];
    const i = list.findIndex((e) => e.id === id);
    const sameKind = list.filter((e) => e.kind === list[i].kind);
    const j = sameKind.findIndex((e) => e.id === id) + delta;
    if (j < 0 || j >= sameKind.length) return;
    // Swap within the kind, so reordering steps does not disturb places.
    const targetId = sameKind[j].id;
    const ti = list.findIndex((e) => e.id === targetId);
    [list[i], list[ti]] = [list[ti], list[i]];
    await persist({
      ...content,
      entries: list,
      dirty: true,
      localVersion: bumpLocalVersion(),
    });
  };

  const upload = async () => {
    if (!app.api) {
      setStatus('No server is configured, so this stays on the device.');
      return;
    }
    try {
      const body = {
        // Sent against the revision last read. A 409 means the server moved
        // on, and local edits are kept rather than overwritten.
        revision: content.revision,
        entries: content.entries.map((e) => ({
          id: e.id,
          kind: e.kind,
          label: e.label,
          category_id: e.categoryId,
          locale: e.locale,
        })),
      };
      const result = await app.api.putPersonalization(patientId, body);
      await persist({
        ...content,
        revision: (result as { revision?: string }).revision ?? content.revision,
        dirty: false,
      });
      setStatus('Uploaded.');
    } catch (e) {
      const conflict =
        typeof e === 'object' && e !== null && 'isConflict' in e
          ? (e as { isConflict: boolean }).isConflict
          : false;
      setStatus(
        conflict
          ? 'The server has a newer version. Your edits are kept here; review before replacing them.'
          : 'Could not upload. Your edits are saved on this device.',
      );
    }
  };

  if (!loaded) return <Screen><View /></Screen>;

  return (
    <Screen>
      <View style={{ height: 12 }} />
      <HeadlineLarge>{t('knowMe')}</HeadlineLarge>
      <BodyMedium tone="soft">{t('withPlacesYouKnow')}</BodyMedium>

      {/* Says which activities will actually use real content and which are
          still running on generic filler. */}
      <Card>
        <TitleLarge>Ready to personalise</TitleLarge>
        <View style={{ height: 8 }} />
        {GAME_REGISTRY.filter((g) => g.gameId !== 'marble_maze').map((g) => {
          const ready = hasEnoughContent(content, g.gameId);
          return (
            <View key={g.gameId} style={styles.readyRow}>
              <BodyLarge style={{ flex: 1 }}>
                {translate(app.interfaceLanguage, g.displayNameKey as never)}
              </BodyLarge>
              <Badge label={ready ? 'Your content' : 'Generic'} />
            </View>
          );
        })}
        <StatusNote
          glyph="ℹ"
          text="An activity without enough of your content uses generic examples. It is never a mix presented as personal."
        />
      </Card>

      {SECTIONS.map((section) => {
        const entries = content.entries.filter((e) => e.kind === section.kind);
        return (
          <View key={section.kind}>
            <SectionHeading
              title={`${section.title} (${countFor(content, section.kind)})`}
            />
            <Card>
              <BodyMedium tone="soft">{section.hint}</BodyMedium>
              <View style={{ height: 10 }} />

              {entries.map((e, i) => (
                <View key={e.id} style={styles.entryRow}>
                  <BodyLarge style={{ flex: 1 }} fontFamily={font}>
                    {section.kind === 'step' ? `${i + 1}. ${e.label}` : e.label}
                  </BodyLarge>
                  {e.categoryId ? <Badge label={e.categoryId} /> : null}
                  {section.kind === 'step' ? (
                    <>
                      <Tiny label="↑" onPress={() => void move(e.id, -1)} />
                      <Tiny label="↓" onPress={() => void move(e.id, 1)} />
                    </>
                  ) : null}
                  <Tiny label="✕" onPress={() => void remove(e.id)} />
                </View>
              ))}

              {section.kind === 'picture' ? (
                <>
                  <View style={{ height: 8 }} />
                  <BodyMedium tone="soft">Where does the next one go?</BodyMedium>
                  <View style={styles.categoryRow}>
                    {PICTURE_CATEGORIES.map((c) => (
                      <PillButton
                        key={c.id}
                        label={c.labelKey}
                        variant={category === c.id ? 'primary' : 'outline'}
                        onPress={() => setCategory(c.id)}
                        style={{ flex: 1 }}
                      />
                    ))}
                  </View>
                </>
              ) : null}

              <TextInput
                accessibilityLabel={section.title}
                value={drafts[section.kind] ?? ''}
                onChangeText={(v) =>
                  setDrafts((d) => ({ ...d, [section.kind]: v }))
                }
                onSubmitEditing={() => void add(section.kind)}
                placeholder="Type here, then Add"
                placeholderTextColor={colors.inkSoft}
                style={[styles.input, font ? { fontFamily: font } : null]}
              />
              <PillButton
                label={t('add')}
                variant="outline"
                disabled={!(drafts[section.kind] ?? '').trim()}
                onPress={() => void add(section.kind)}
              />
            </Card>
          </View>
        );
      })}

      <Divider />
      {content.dirty ? (
        <StatusNote glyph="⇅" text="You have changes that are not uploaded." />
      ) : null}
      {status ? <StatusNote glyph="ℹ" text={status} /> : null}
      <PillButton
        label="Upload to the server"
        variant="outline"
        disabled={!app.api}
        onPress={upload}
      />
      <PillButton label={t('goBack')} onPress={onBack} />
    </Screen>
  );
}

function Tiny({ label, onPress }: { label: string; onPress: () => void }) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label === '✕' ? 'Remove' : label === '↑' ? 'Move up' : 'Move down'}
      onPress={onPress}
      style={({ pressed }) => [styles.tiny, pressed && { opacity: 0.6 }]}
    >
      <BodyLarge>{label}</BodyLarge>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  entryRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingVertical: 6,
  },
  readyRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 6,
  },
  categoryRow: { flexDirection: 'row', gap: 8, marginVertical: 8 },
  tiny: {
    minWidth: spacing.minTarget,
    minHeight: spacing.minTarget,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
    backgroundColor: colors.cream,
  },
  input: {
    minHeight: spacing.minTarget,
    borderWidth: 1.5,
    borderColor: colors.hairline,
    borderRadius: 14,
    paddingHorizontal: 14,
    fontSize: 18,
    color: colors.ink,
    backgroundColor: colors.cream,
    marginTop: 8,
  },
});
