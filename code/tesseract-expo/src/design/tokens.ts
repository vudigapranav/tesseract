/**
 * Design tokens, ported from the Flutter app's TesseractDesign so the two
 * builds look like one product.
 *
 * Coral is decorative only. It never carries meaning on its own and is never
 * used for body text, because a caregiver may be colour-blind and a patient
 * may have reduced contrast sensitivity. Anything meaningful is also stated
 * in words, and usually an icon too.
 */
export const colors = {
  cream: '#FFF8EC',
  creamTop: '#FFF3E2',
  peach: '#FFE2D4',
  coral: '#F47F78',
  ink: '#24211F',
  /** Muted ink for supporting text, kept above 4.5:1 on cream and on white. */
  inkSoft: '#5B5450',
  white: '#FFFFFF',
  /** Only for attention states, alongside an icon and words. */
  attention: '#8A4B1F',
  hairline: '#EFE4D6',
} as const;

export const spacing = {
  gutter: 20,
  cardRadius: 24,
  /**
   * Minimum patient-facing target, above the 44pt iOS guidance because the
   * people using patient mode may have tremor or low precision.
   */
  patientTarget: 64,
  /** Floor for any control anywhere, including caregiver screens. */
  minTarget: 48,
} as const;

/**
 * Type scale. Sizes are unscaled: every Text in the app allows Dynamic Type
 * to scale them, so these are the 100% values, not caps.
 */
export const type = {
  headlineLarge: { fontSize: 32, fontWeight: '700', letterSpacing: -0.8 },
  headlineSmall: { fontSize: 27, fontWeight: '700' },
  titleLarge: { fontSize: 22, fontWeight: '600' },
  bodyLarge: { fontSize: 18, lineHeight: 26 },
  bodyMedium: { fontSize: 16, lineHeight: 23 },
  label: { fontSize: 14, fontWeight: '600' },
} as const;

/**
 * Scripts that need a bundled face.
 *
 * Latin is covered by the system font. Bengali-Assamese and Meetei Mayek are
 * bundled because an entry-level device may not ship them, and a missing font
 * renders as empty boxes rather than as an error the user could act on.
 */
export const fontFamilyForScript = (script: string): string | undefined => {
  switch (script) {
    case 'Bengali-Assamese':
      return 'NotoSansBengali';
    case 'Meetei Mayek':
      return 'NotoSansMeeteiMayek';
    case 'Devanagari':
      return 'NotoSansDevanagari';
    default:
      return undefined;
  }
};
