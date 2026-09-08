#!/usr/bin/env node
/**
 * Regenerates src/l10n/*.ts from the Flutter ARB files.
 *
 * The ARBs in Apnapan/host/lib/l10n stay the single source of truth for wording.
 * Two apps maintaining two copies of six languages by hand is how a project
 * ends up claiming coverage it does not have, so this is generated and the
 * generated files are never hand-edited.
 *
 *   node tools/sync-l10n.mjs           regenerate
 *   node tools/sync-l10n.mjs --check   fail if out of date (used by tests/CI)
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const ARB = join(here, '..', '..', 'host', 'lib', 'l10n');
const OUT = join(here, '..', 'src', 'l10n');
const LOCALES = ['hi', 'as', 'bn', 'mni', 'kha', 'lus'];
const check = process.argv.includes('--check');

if (!existsSync(ARB)) {
  console.error(`Flutter ARB directory not found at ${ARB}.`);
  process.exit(1);
}

const readArb = (code) =>
  JSON.parse(readFileSync(join(ARB, `app_${code}.arb`), 'utf8'));

const en = readArb('en');
const messageKeys = Object.keys(en).filter((k) => !k.startsWith('@'));

// Keys English marks as untranslatable — the product name and the fixed team
// attribution. They must render in exact English everywhere, so they are
// excluded from every locale file and from the coverage denominator.
const untranslatable = Object.entries(en)
  .filter(([k, v]) => k.startsWith('@') && v && v['x-untranslatable'] === true)
  .map(([k]) => k.slice(1));

const denominator = messageKeys.filter((k) => !untranslatable.includes(k));

const files = {};

files['en.ts'] =
  `// GENERATED from Apnapan/host/lib/l10n/app_en.arb by tools/sync-l10n.mjs.\n` +
  `// Do not hand-edit: the Flutter ARBs remain the single source of truth so\n` +
  `// the two apps cannot drift apart in wording or coverage.\n\n` +
  `export const untranslatableKeys = [\n` +
  untranslatable.map((k) => `  ${JSON.stringify(k)},`).join('\n') +
  `\n] as const;\n\nexport const en = {\n` +
  messageKeys.map((k) => `  ${JSON.stringify(k)}: ${JSON.stringify(en[k])},`).join('\n') +
  `\n} as const;\n\nexport type StringKey = keyof typeof en;\n`;

const coverage = {};
for (const code of LOCALES) {
  const arb = readArb(code);
  const varName = code === 'as' ? 'as_' : code;
  const entries = Object.keys(arb).filter(
    (k) => !k.startsWith('@') && k in en && !untranslatable.includes(k),
  );
  coverage[code] = Math.round((entries.length / denominator.length) * 100);
  files[`${code}.ts`] =
    `// GENERATED from Apnapan/host/lib/l10n/app_${code}.arb. Do not hand-edit.\n` +
    `// Missing keys fall back to English, which the UI discloses.\n\n` +
    `import type { StringKey } from './en';\n\n` +
    `export const ${varName}: Partial<Record<StringKey, string>> = {\n` +
    entries.map((k) => `  ${JSON.stringify(k)}: ${JSON.stringify(arb[k])},`).join('\n') +
    `\n};\n`;
}

let stale = false;
for (const [name, body] of Object.entries(files)) {
  const path = join(OUT, name);
  const current = existsSync(path) ? readFileSync(path, 'utf8') : null;
  if (current === body) continue;
  stale = true;
  if (check) {
    console.error(`out of date: src/l10n/${name}`);
  } else {
    writeFileSync(path, body);
    console.log(`wrote src/l10n/${name}`);
  }
}

console.log(
  `translatable keys: ${denominator.length} (${messageKeys.length} total, ` +
    `${untranslatable.length} untranslatable)`,
);
for (const code of LOCALES) console.log(`  ${code}: ${coverage[code]}%`);

if (check && stale) {
  console.error('\nRun `node tools/sync-l10n.mjs` — the ARBs changed.');
  process.exit(1);
}
