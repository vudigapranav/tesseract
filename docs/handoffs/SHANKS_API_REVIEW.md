# Host integration review — 2026-09-07

Target: polished, fully functional production-quality app, with measured acceptance; no demo-only completion claim. Prepared for Pranav and Maharshitha; no message has been sent to either person.

The task opened in an unrelated home-directory UserProfileApp worktree. Implementation is isolated in the nested `tesseract` clone of the actual SIH repository, starting at 00f5cc9. Original checkout and uncommitted AGENTS.md are preserved; that guidance is copied here.

## Contract draft review (not a unilateral freeze)

P1: user explicitly requests host mapping elapsedMs → elapsed_ms; implemented at the host boundary. Game serialization unchanged.
P2/P3: adapter can retain redundant session metadata locally; API binds patient and versions through session creation. No server changes requested.
P4: existing game callback does not export actual tilt/fallback mode. Omit actual_input_mode for Marble Maze; server must preserve input_mode_unverified and avoid treating this as verified tilt. Explicit touch configuration is known. Game-owner export remains a dependency.
P5: retain client UUID and stable event UUIDs across retries.
P6: Firebase remains the real identity path, pending public client configuration/provider and actual-project verification. Demo is explicit; never fallback from failed real authentication.
P7: consume opaque cursors, no offset conversion.

§14 answers proposed by host implementation: snake_case mapping as requested; actual Maze mode unavailable; batches capped at 500; use existing create → events → complete calls even for offline sessions. Pranav review remains outstanding; backend contract is unchanged.

Conflict policy: keep rejected local session data, stop automatic retries on permanent 4xx, preserve IDs on transport/5xx retry. Expired identity/access denial pauses sync. Profile/config revision conflicts require explicit refresh/review, never last-write-wins. Multi-device reminder conflict/occurrence identity policy still needs Pranav's review.

## Maharshitha handoff

Use warm cream/peach, decorative coral, dark readable text, white rounded cards and black pill buttons. Reference image inspected. Shared design components belong in host, not games. Review caregiver density, patient large labelled controls, 2× text layout, contrast, TalkBack order and reduced motion. Assets must depict Tesseract/activities, without medical-marketplace features. No external assets or team contact claimed.

## Independent doctor scope

D1–D8 required, platform question pending. If web selected: separate bounded frontend package for authenticated assigned-patient list, overview/history, measured analytics/trends, cited draft reports, and attributed notes/recommendations against existing doctor endpoints. Acceptance includes direct-ID access denial, revocation, empty/stale/error states and reviewer authority. Mobile P/C screens do not fulfill it.
