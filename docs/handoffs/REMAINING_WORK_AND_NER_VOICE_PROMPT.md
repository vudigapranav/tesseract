# Continuation prompt: remaining application work and NER speech

User-confirmed scope, 2026-09-08. This file records requirements, not implemented functionality. This documentation update does not start implementation or reactivate any automation.

## Prompt to use for the next implementation task

Continue Tesseract in `/Users/pranav07vudiga/.codex/worktrees/4fa8/pranav07vudiga/tesseract`, branch `codex/patient-caregiver-integration`. Inspect actual HEAD, status and diffs first. This is a nested isolated clone; its parent is an unrelated UserProfileApp repository. Preserve all existing work. Do not push or modify the original Desktop/Projects/Hackathon/SIH checkout.

Read AGENTS.md, newest Brain.md and PS003_MOBILE_CODE_STATUS.md entries, docs/handoffs/CODEX_CONTINUATION_2026-09-08.md, docs/handoffs/SHANKS_API_REVIEW.md, docs/handoffs/TRANSLATION_REVIEW_2026-09-08.md, the master context, relevant handbook/roadmap and Pranav's API contract. Reconcile older handoff statements against code. Preserve the polished, fully functional application target; skeletons, untranslated screens and unverified adapters are not completion.

Complete the following remaining scope, continuing independent work while external dependencies are pending:

1. Translation coverage and review
   Recorded coverage is Assamese 90%, Bengali 93%, Meitei 9%, Khasi 10%, Mizo 10%. Recompute from current ARBs before changing anything. Raise coverage with accurate translations, updating ARBs and language_catalogue.dart together. Do not invent low-confidence wording to inflate coverage. All non-English languages remain draft until an identified fluent speaker actually reviews them. Track review evidence and outstanding strings. Do not add languages for currently uncovered regional scope without an explicit user decision. Preserve immediate language selection before sign-in and in Settings, durable offline preferences, separate patient language and About Tesseract attribution.

2. Real authentication and backend verification
   Firebase project tesseract-3ac5a and Email/Password were recorded as confirmed; inspect current configuration. Missing public FIREBASE_API_KEY and HTTPS TESSERACT_API_URL must be supplied by the user if still absent. Ask only for public configuration or local configuration paths; never request passwords, service-account JSON, private keys or AI-provider secrets in chat. Validate actual caregiver and assigned-doctor sign-in, access denial, expiry, sign-out and account/patient isolation. Never fall back from failed real authentication to synthetic access. Do not count mocked tests as live Firebase verification.

3. Physical Android verification
   Device behavior remains NOT TESTED until a real phone is connected and checks are performed. Verify notification delivery/permissions/reboot/time-zone/duplicates, biometric gate, gyroscope feel, text/script rendering, large text, TalkBack, offline/reconnect and the complete caregiver setup → handover → game → saved history → protected return loop. Record model, Android version, build and actual results. Browser/golden evidence does not substitute for phone checks.

4. Backend dependencies
   Coordinate with Pranav on the missing patient-basics update endpoint and calculators for step_presented, attempt_resolved, word_found, selection_rejected, all_words_found, content_unavailable, item_sorted and sorting_completed. Inspect existing routes/calculators before declaring a gap. Prepare explicit bounded backend handoffs, payload/metric decisions and test fixtures; do not independently redefine API contracts or analytics. Once approved backend work is available, integrate and verify it. Existing basics edits must remain visibly local-only until supported. Unavailable metrics must never appear as fabricated zeroes or clinical scores.

5. Required game catalogue
   Current verified registry was Route Quest, Marble Maze, Word Search, Routine Recall and Picture Sorting: FOUR of the NINE required games, plus ONE extra. Aryan's Reveal Match, Trace, Coloring, Spot Difference and Picture Recall remain missing. Inspect current registry and authorized repository availability. Ask for exact repositories/handoffs if absent; do not guess, invent completion or independently redesign teammates' modules. Integrate approved implementations through the shared contract with ownership preserved. Games gain no network, database or auth dependencies; telemetry contains opaque IDs only. Preserve existing games and Marble Maze gyroscope-first behavior with accessible touch fallback.

6. NEW REQUIRED SCOPE: spoken output
   Implement patient-requested spoken instructions, Help and reminder text in the patient's selected language. Provide clearly labelled replay/stop controls, honor the audio preference, avoid overlapping speech, and handle activity/background lifecycle changes. Speech is optional to use; text/touch must remain fully usable. Keep speech integration in the host/shared application layer and preserve game boundaries. Do not claim spoken support just because translated text exists.

7. NEW REQUIRED SCOPE: voice input
   Implement optional, explicitly activated tap-to-speak commands or dictation. Indicate listening, provide cancel/stop, request microphone permission at point of use, and handle denial, unavailable recognition, timeout and errors. Present recognized text/action in the selected language for explicit confirmation BEFORE saving data or executing a command. No always-on listening, automatic submission, voice bypass of caregiver protection or unconfirmed changes to settings. Keep personal words and recognized text out of analytics/event payloads and unnecessary logs.

8. Speech language/provider verification
   Separately assess output voices and input recognition for Assamese, Bengali, Meitei, Khasi and Mizo. Research current authoritative provider/OS capabilities before selecting an adapter; support for one direction does not prove the other. Record a per-language matrix of TTS, STT, script/locale, provider, online/offline requirements, actual device result and fluent-speaker review. Automated mocks verify behavior, not pronunciation or recognition quality. Test representative instructions, reminder phrases and spoken commands with fluent speakers. Mark unavailable, draft and NOT TESTED accurately. No language may be marked speech-verified without that evidence.

9. Explicit fallback and service choices
   If a selected language has no supported voice or recognizer, explain that speech is unavailable for that language and retain localized text/touch controls. NEVER silently speak or recognize another language. Language/provider fallback must be explicit and user-selected. Handle offline loss without losing entered content. Evaluate OS/on-device and approved service options; do not assume that all NER languages have available engines. Obtain approval before paid services or external audio processing. If external processing is selected, disclose it at point of use and keep service credentials server-side. Do not send recordings or personal reminder content externally without appropriate user authorization. Missing provider coverage is a blocker to report, not a feature to fake.

Verification and delivery:
- Preserve sign-in/Settings language switching, separate patient language, accessible design, reduced motion and About attribution: “Built and developed by the Tesseract Team.”
- Run fresh formatting, analysis, relevant behavioral and integration tests, localization coverage checks, game regressions and current Android APK build.
- Add speech tests for language routing, unavailable-engine fallback, confirmation before action, permissions, cancellation, lifecycle, errors and audio preference. Verify real speech quality separately on-device with fluent reviewers.
- Record tests actually run, screenshots, APK path, live API/device evidence and blockers. Historical passing counts are not current evidence.
- Update Brain.md and PS003_MOBILE_CODE_STATUS.md after milestones, including translation and speech coverage/review matrices. Keep implementation status separate from external configuration/native review/device acceptance.
- Use scoped commits in the correct repo; no push, no unrelated work, no paid deployment without authorization. Maintain explicit handoff notes without pretending to contact teammates.
- Deliver real behavior and truthful evidence. Continue safe authorized work; ask only for concrete missing configuration, repositories, decisions or review/device access that cannot be inferred.
