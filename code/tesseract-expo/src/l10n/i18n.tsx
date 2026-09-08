/**
 * Localisation runtime.
 *
 * Two languages are live at once and they are deliberately independent: the
 * caregiver's interface language, and the language the person playing sees.
 * A caregiver and the person they care for may not read the same language.
 *
 * A missing string falls back to English rather than showing a key. The UI
 * discloses that a language is partial; it never silently pretends otherwise.
 */
import React, { createContext, useContext, useMemo } from 'react';
import { en, type StringKey } from './en';
import { as_ } from './as';
import { bn } from './bn';
import { mni } from './mni';
import { kha } from './kha';
import { lus } from './lus';
import type { LanguageCode } from './languages';

const CATALOGUES: Record<LanguageCode, Partial<Record<StringKey, string>>> = {
  en,
  as: as_,
  bn,
  mni,
  kha,
  lus,
};

/** Substitutes {named} placeholders. Unknown names are left alone. */
export function format(
  template: string,
  values?: Record<string, string | number>,
): string {
  if (!values) return template;
  return template.replace(/\{(\w+)\}/g, (whole, name: string) =>
    name in values ? String(values[name]) : whole,
  );
}

/** Looks up `key` in `code`, falling back to English. */
export function translate(
  code: LanguageCode,
  key: StringKey,
  values?: Record<string, string | number>,
): string {
  const catalogue = CATALOGUES[code] ?? en;
  const found = catalogue[key] ?? en[key];
  return format(found as string, values);
}

/** True when this language really has its own wording for `key`. */
export function hasOwnTranslation(code: LanguageCode, key: StringKey): boolean {
  if (code === 'en') return true;
  return CATALOGUES[code]?.[key] !== undefined;
}

export type Translator = (
  key: StringKey,
  values?: Record<string, string | number>,
) => string;

interface LanguageContextValue {
  /** Caregiver / doctor interface language. */
  interfaceCode: LanguageCode;
  /** Language the person playing sees. Independent of the above. */
  patientCode: LanguageCode;
  t: Translator;
  /** Translator bound to the patient's language, for patient-facing text. */
  tPatient: Translator;
}

const LanguageContext = createContext<LanguageContextValue | null>(null);

export function LanguageProvider({
  interfaceCode,
  patientCode,
  children,
}: {
  interfaceCode: LanguageCode;
  patientCode: LanguageCode;
  children: React.ReactNode;
}) {
  const value = useMemo<LanguageContextValue>(
    () => ({
      interfaceCode,
      patientCode,
      t: (key, values) => translate(interfaceCode, key, values),
      tPatient: (key, values) => translate(patientCode, key, values),
    }),
    [interfaceCode, patientCode],
  );
  return (
    <LanguageContext.Provider value={value}>{children}</LanguageContext.Provider>
  );
}

export function useLanguage(): LanguageContextValue {
  const ctx = useContext(LanguageContext);
  if (!ctx) {
    throw new Error('useLanguage must be used inside a LanguageProvider');
  }
  return ctx;
}

/** Interface-language translator. */
export const useT = (): Translator => useLanguage().t;

/** Patient-language translator, for anything the person playing reads. */
export const useTPatient = (): Translator => useLanguage().tPatient;
