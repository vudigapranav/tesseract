# Aryan package staging — 2026-09-08

Scope: download, safe extraction and source inventory only. No implementation, port, downloaded script execution, commit or push.

Source: https://drive.google.com/drive/folders/1NsGG9oPT9I020Qp615d3LsOiGSkKI7Fi
Archive: `tmp/incoming/aryan/aryan-drive-20260908.zip`
Extracted source: `tmp/incoming/aryan/extracted/`
Inventory: `tmp/incoming/aryan/inventory.json`
SHA-256: `548a1fdd82a9ea858c0b5a364b03ed3419a5a05d0c93ce7555635692e7563763`
31,167,216 archive bytes; 126 entries; 100,088,605 expanded bytes.

Verified ZIP CRCs and checked paths for traversal, absolute paths, duplicate case-insensitive names, symlinks and encryption before extraction. No downloaded executable permissions preserved. Generated build/.dart_tool files remain isolated. Staging is gitignored; another checkout will need the package separately.

Source present under extracted/lib/games:
- G1: reveal_match — model/controller/view/config/metrics/activity.
- G4: trace — geometry/resampler/controller/view/renderer/config/metrics/activity.
- G5: swipe_reveal — titled Swipe-to-Reveal Coloring; model/mask/controller/view/renderer/config/metrics/activity.
- G6: spot_difference — content/hit-test/controller/view/renderer/config/metrics/activity.
- G9: picture_recall — model/content/controller/view/config/metrics/activity.

The demo catalogue imports all five. Two declared JSON demo assets are present, with vector image rendering in lib/demo/demo_vector_image.dart. Tests and docs/ARYAN_GAMES_IMPLEMENTATION.md are present. This establishes source presence, not completeness, test success, production quality or Expo integration. No Flutter/Expo tests run in this staging task. Current Expo registry still lists four required games plus Picture Sorting extra.

Next: Prompt 2 Stage A, read-only triage; inspect actual source, assets, lifecycle and contract compatibility. Stop before any port. Preserve existing Prompt 1 working-tree changes. Seven of nine is an interim milestone only; the full target remains nine polished functional games. Native behavior remains unverified. Keep Hindi and the requested NE languages in localization/speech scope, with honest per-language draft and device/provider verification labels.

Prompt review corrections: verify assumptions against current diffs; resolve src paths under Apnapan/tesseract-expo; avoid blanket text-scaling rewrites; permit narrowly scoped host/l10n/calculator integration proposals at a later approval gate; do not claim arbitrary native transition timings supported without checking; use reproducible lockfile installs where valid; do not delete a lockfile without checking its purpose; record unavailable device checks as NOT TESTED. Synthetic demo profiles must be explicitly scoped and must not overwrite real profiles. Deployment credentials stay server-side, except intentionally public client configuration. Final demo gates do not establish full production acceptance.
