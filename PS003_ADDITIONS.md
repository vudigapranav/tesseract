# PS003 additions — seven further uses of gameplay

Created 2026-09-06 by Claude, at the user's request. **Planning only. Nothing here is approved and nothing has been implemented.** No existing file was modified to accommodate these; the user will decide first, and only then will `PS003_GAME_ASSIGNMENTS_AND_UI.md`, `PS003_ROADMAP.md` and `PS003_MASTER_CONTEXT.md` be updated.

## What this document is

The product currently uses gameplay for three things: analytics, difficulty adjustment and activity recommendation. This document specifies **seven additional uses of the same gameplay data**, selected by the user from a longer list. They are numbered A1–A7 here; the user's original numbering is noted on each.

It uses the vocabulary already established elsewhere: games are G1–G9, patient screens P1–P9, caregiver C1–C7, doctor D1–D8, and the event envelope and comparability rules are those in `docs/PS003_GAME_ASSIGNMENTS_AND_UI.md`. Read that guide first. This file only describes what is **new or changed**.

One item from the original list — an explicitly unmeasured "free play" mode — was **not** selected and is out of scope.

## Read this before designing any of it

Three of these seven (A2, A5, A6) introduce new conditions under which a session is played. **Every one of them must be added to the comparability key**, or the provisional reference and the trend views quietly degrade: a session played together with a caregiver, a 60-second session launched from a reminder, and an evening session are not comparable with a normal solo daytime session, and pooling them invisibly is exactly the failure the current guide already warns against for assisted play.

This is the single largest engineering consequence of adopting these features. It is cheap to design in now and expensive to retrofit after the metric calculator exists.

Two of them (A3, A4) describe **the content and the interface**, not the person. That framing is what keeps them outside clinical territory, and the copy rules below are load-bearing, not stylistic.

---

# A1 — Conversation prompt for the caregiver

*(user's item 1)*

## What it is

After a session, the caregiver sees one or two plain observations about what the patient spent time on. For example: "She spent longer on the tea garden picture today." Nothing more.

## Why

Caregivers of people with dementia routinely run out of things to talk about. This hands them a thread they can use the same evening. It is derived entirely from data already being collected, and it is the cheapest high-value item on this list.

## Frontend changes

- **C4 Caregiver Home** — a new card, "Something to talk about", holding one or two observations from the most recent completed session. Dismissible. Absent when there is no session or nothing notable.
- **Session detail view** (reached from C4) — the same observations shown alongside that session's metrics.
- No patient-side change. Nothing about this is shown in patient mode.

## Data and contract changes

None to the event envelope. Observations are derived from existing `item_presented` → resolution intervals per opaque content ID within a single session.

## Analytics rules

- Derived per session, not across sessions. This is not a trend.
- Only from completed or stopped sessions with at least one resolved item.
- Suppressed entirely when the session was interrupted or had an event-sequence gap.
- Content IDs resolve to display names **on the device**, from local caregiver content. Names never travel in telemetry.

## Honesty boundary

The observation is about **what happened in the game**, never about the person's memory, preference or emotional state.

- Allowed: "She spent longer on this picture." / "This was the first pair she matched."
- Not allowed: "She likes this picture." / "She remembers her granddaughter." / "She struggled with her son's photo."

Never generate this text with a language model. It is a fixed template over deterministic values, because a hallucinated sentence about a patient is a disqualifying failure.

## Effort and dependencies

Roughly half a day. Depends on the core session pipeline existing. Owner: whoever owns C4.

## Acceptance

A completed synthetic session produces at most two observations; an interrupted session produces none; no observation contains an inferred preference or capability; the same session always produces the same text.

---

# A2 — Played-together mode

*(user's item 2)*

## What it is

The caregiver can indicate that they are sitting with the patient and doing the activity together. The session is recorded as a companion session, and the patient-facing wording shifts from "you" to "we".

## Why

The cognitive-stimulation evidence the project cites concerns **group delivery** far more than solo app use. Offering a together mode is the closest honest analogue to what that evidence actually covers, and it lets the pitch say so without overclaiming. It is also close to free to build.

## Frontend changes

- **C5 Hand Over** — a new control before entering patient mode: "Are you doing this together?" Defaults to off. Its state is shown in the handover preview alongside activity, sound and accessibility.
- **P3 / P4 / P6 copy variants** — the existing `GameStrings` gain a companion variant ("Let's find the pairs" rather than "Find the pairs"; "We're all done" rather than "All done"). This is a strings change, **not new screens and not new game logic**. Game owners do not branch on it; they render whatever string they are handed.
- **C4 / session detail** — a companion session is labelled as such wherever it is listed.
- **D4 / D6** — companion sessions are visibly distinguished and never pooled with solo sessions in a trend line.

## Data and contract changes

- Session configuration snapshot gains `companion_mode: solo | together`, frozen for the session like every other setting.
- No new event types.

## Analytics rules

- `companion_mode` joins the comparability key. Solo and together sessions form **separate series**.
- For the purposes of automatic level progression, a together session is treated the same way as an assisted session: it does not drive a level increase.
- The provisional reference is built from solo sessions unless the patient only ever plays together, in which case the reference is built from together sessions and labelled accordingly.

## Honesty boundary

Offering the mode is justified by the shape of the existing evidence. It does **not** license a claim that playing together improves cognition, slows decline, or produces any outcome. The product records that a session was companion-supported; it does not evaluate the caregiver's involvement.

## Effort and dependencies

An hour or two once `GameStrings` injection and the session snapshot exist. Owner: C5 owner plus whoever owns the strings layer.

## Acceptance

Toggling on C5 produces a session whose snapshot records `together`; the patient-facing copy changes; the session appears in a separate series in the caregiver and doctor views; it does not trigger a level-up proposal.

---

# A3 — Content curation: which people, places and words actually land

*(user's item 4)*

## What it is

Over time the app can tell the caregiver which of their Know Me content is being used and engaged with, and which is not — so they can swap in better content. It also rotates content so the same few items do not repeat endlessly.

## Why

A caregiver enters 15–20 words and a handful of people and places, guessing at what will work. Some of it will not. This closes that loop and makes the personalisation visibly improve within a week, which is also the clearest demonstration of personalisation there is.

## Frontend changes

- **C3 Know Me** — a new section, "How your content is doing", listing items with a neutral usage indicator (used often / used rarely / not used yet) and a one-tap route to replace or remove an item.
- **C4 Caregiver Home** — an occasional, dismissible nudge when several items have never been used: "Three of your words haven't come up yet — want to swap them?"
- No patient-side change.

## Data and contract changes

- Per-content-item aggregates stored server-side, keyed by opaque content ID: `times_presented`, `times_resolved`, `times_skipped`, `last_used_at`.
- No new event types; these are derived from existing per-item events.
- Content selection at activity-resolution time reads `last_used_at` to rotate content rather than re-serving the same items.

## Analytics rules

- Aggregates are per content item, never per person.
- Items with fewer than three presentations show "not enough use yet", not a rating.
- Content rotation must not silently change the comparability of a session: if a game's content set changes materially, that is a configuration change and starts a new series, exactly as a level change does.

## Honesty boundary

**This feature describes the content, never the patient.** That distinction is the whole basis for it being safe.

- Allowed: "This picture comes up often." / "These words haven't been used yet." / "This picture is rarely chosen."
- Not allowed: "She doesn't recognise her son." / "She responds better to places than people." / anything that reads as a finding about the person.

Low engagement with an item has many causes — the photo is dark, the crop is bad, the word is long, the item simply has not been served yet. The UI must not invite a cognitive interpretation.

## Effort and dependencies

About a day, mostly backend aggregation plus a C3 section. Depends on per-item events and content IDs being stable. Owner: C3 owner plus backend.

## Acceptance

An item served five times and never chosen shows as "used rarely" and offers replacement; an item never served shows "not used yet"; no string in the feature refers to the patient's ability; replacing an item does not corrupt an existing comparison series.

---

# A4 — Self-calibrating accessibility

*(user's item 5)*

## What it is

The first sessions double as an interface fitting. If taps consistently land short of their targets, or the patient never engages with text-based content, the app proposes concrete accessibility changes — larger targets, larger text, labels on, reading-based games off.

## Why

The caregiver currently sets text size and language on C2 by guessing, before ever seeing the patient use the app. This replaces the guess with evidence, and means the interface fits the person rather than the person adapting to the interface.

## Frontend changes

- **C4 or C7** — a suggestion card: "Taps are landing slightly below the buttons. Try larger targets?" with Apply / Not now. Never auto-applied.
- **C7 Settings** — the accessibility settings show which values were caregiver-set and which were suggested and accepted.
- **P3 tutorial** — no visible change, but the tutorial session is the primary calibration source and should present at least one target of each size class.
- No new patient screen.

## Data and contract changes

- **This is the one addition that requires a new event payload field.** For tap-based games (G1, G6, G8, G9), `attempt_resolved` gains an optional bounded `hit_offset_dp` — the distance from the tap to the centre of the intended target, as a magnitude only.
- Raw coordinates are **not** transmitted. A magnitude in dp is sufficient and carries no layout or content information.
- Session snapshot already records text scale and input mode; no change needed there.

## Analytics rules

- Interface-fit signals are computed and stored **separately from performance metrics** and must never enter the level-recommendation rules. A person missing targets because the buttons are small is an ergonomics problem, not a difficulty signal.
- Requires at least two sessions before any suggestion is offered.
- A suggestion accepted by the caregiver is a configuration change and starts a new comparison series.

## Honesty boundary

A missed tap is a signal about **target size and layout**. It is not evidence of motor impairment, tremor, visual impairment or cognitive change, and no screen may present it as such. The app suggests a bigger button; it does not suggest a diagnosis.

## Effort and dependencies

About a day. Requires the `hit_offset_dp` field to be in the contract **before** game owners build G1, G6, G8 and G9 — this is the only item here with a hard ordering dependency on the game work. Owner: Pranav for the contract, C7 owner for the UI.

## Acceptance

A synthetic session with consistently offset taps produces a suggestion; a session with accurate taps produces none; accepting a suggestion changes settings and starts a new series; the interface-fit value provably does not appear in any recommendation input.

---

# A5 — Reminder bridge

*(user's item 6)*

## What it is

After the patient acknowledges a routine reminder, they are optionally offered a very short activity using content related to that routine. Always declinable, never required.

## Why

It turns a reminder from an interruption into a small ritual, and it is the natural point where the required reminders feature and the game catalogue actually meet. It also gives the patient something pleasant immediately after being interrupted.

## Frontend changes

- **Reminder card (patient-facing, defined under C6)** — after Acknowledge, an optional follow-on: "Would you like a short activity?" with a clear decline. Declining returns to P8 or P1 with no further prompt.
- **C6 Reminders** — a per-reminder caregiver setting: offer a short activity after this reminder, default off.
- Enters the existing **P3 → P4 → P6** path with a short configuration. No new game screens.

## Data and contract changes

- Session snapshot gains `origin: home | choose | recommended | reminder_bridge`.
- Reminder records already distinguish scheduled / prompted / acknowledged / postponed; the bridge adds `bridge_offered` and `bridge_accepted` as distinct values. **Neither is evidence the routine activity happened.**

## Analytics rules

- `origin` joins the comparability key. Bridge sessions are short by design and form a separate series; they must never contribute to the provisional reference for normal sessions.
- Declining the bridge is not an engagement signal and is not recorded as a refusal or a missed session.

## Honesty boundary

The existing rule stands and is reinforced here: **a reminder never requires the patient to play a game**, and game completion is never a condition for receiving, dismissing or satisfying a reminder. Acknowledging a reminder still means only that a button was pressed. The bridge adds nothing to what an acknowledgement proves.

## Effort and dependencies

Half a day once both C6 reminders and at least one game exist. Owner: C6 owner.

## Acceptance

Acknowledging a reminder with the setting on offers an activity; declining leaves no trace beyond `bridge_offered`; the resulting session carries `origin: reminder_bridge` and is excluded from the normal reference; the reminder is satisfied regardless of whether the activity is played.

---

# A6 — Time-of-day content selection

*(user's item 7)*

## What it is

The caregiver can set which content and activities are preferred at different times of day — typically calmer, more familiar, less demanding content later in the day.

## Why

Later-day restlessness is a widely reported pattern in dementia care, and caregivers plan around it. Letting them express that preference in the app is useful and costs almost nothing. Crucially, the caregiver states the preference; the app never infers it.

## Frontend changes

- **C3 or C7** — a simple daypart preference: which content or activities are preferred morning / afternoon / evening. Default: no preference, and the feature is entirely optional.
- **P1 / P7** — the suggested activity respects the preference when resolving today's activity. No visible new element; the patient simply sees appropriate content.
- No new screens.

## Data and contract changes

- Content items and activity configurations gain an optional caregiver-set `daypart_preference`.
- Session snapshot records `local_daypart` (derived from the device's local time at session start), for comparability only.

## Analytics rules

- `local_daypart` is recorded on every session regardless of whether the feature is used, because time of day is a plausible confounder for any within-person comparison.
- Whether daypart enters the comparability key is an **open decision** — it may be too aggressive a split for the small session counts expected. Recommendation: record it now, surface it in D6 as an annotation, and decide on splitting after real data exists.

## Honesty boundary

This is a **caregiver-configured schedule**, not detection. The app must not claim to detect, predict, measure or treat late-day agitation or sundowning, and must not tell the caregiver that the patient "does worse in the evening". Differences by time of day have many causes and the product is not positioned to attribute them.

## Effort and dependencies

Half a day. Depends on content selection existing. Owner: C3/C7 owner.

## Acceptance

A caregiver preference changes which content P1 offers at the relevant time; no screen infers or reports a time-of-day pattern about the patient; `local_daypart` is present on every session snapshot.

---

# A7 — Appointment one-pager for the caregiver

*(user's item 8)*

## What it is

A caregiver-initiated export: a single printable page summarising what the patient has been doing, which the caregiver can take to a medical appointment.

## Why

A consultation is short and the caregiver is usually recalling from memory. A page of concrete, dated observations is genuinely useful there — and considerably more defensible than a cognitive-score dashboard.

## Frontend changes

- **C4 or C7** — "Prepare for an appointment", producing a preview and then a share or print action.
- **Preview screen (new)** — shows exactly what will be included before anything leaves the device, with an explicit confirmation. This is the only genuinely new screen in this document.
- No patient-side change.

## Data and contract changes

None new. It reuses the existing session summary, caregiver observations and current approved activity.

## Content of the page

Sessions played with dates and games; participation frequency; current approved activity and settings; caregiver-entered observations; known clinical context exactly as the caregiver entered it; and the standing caveat paragraph.

## Analytics rules

- Deterministic template only. **This page must not be generated by a language model**, and is deliberately different from D7, which is the doctor-side AI-drafted summary with its own review workflow. A document carrying a patient's information into a clinical conversation must be reproducible and incapable of inventing anything.
- Any seeded or demonstration data must be labelled as such on the page itself.
- The page states plainly that it is a record of app activity and not a clinical assessment.

## Honesty and privacy boundary

This is an **export of personal data**, so it requires an explicit caregiver action, a preview, and a plain warning about where it is being sent. It is not generated automatically, not emailed on a schedule, and not shared with the doctor portal by this route — the doctor portal has its own access-controlled path.

## Effort and dependencies

About a day, mostly layout. Depends on the session summary existing. Owner: C4/C7 owner.

## Acceptance

The preview shows every field that will be exported; nothing is exported without confirmation; the page renders identically for the same data twice; the caveat and any demonstration-data label are always present.

---

# Summary — frontend changes implied

Beyond P9 and beyond what `docs/PS003_GAME_ASSIGNMENTS_AND_UI.md` already describes.

| Screen | Change | From |
|---|---|---|
| C3 Know Me | New "How your content is doing" section; optional daypart preference | A3, A6 |
| C4 Caregiver Home | New "Something to talk about" card; content nudge; accessibility suggestion card; "Prepare for an appointment" entry | A1, A3, A4, A7 |
| C5 Hand Over | New "doing this together?" control, shown in the handover preview | A2 |
| C6 Reminders | Per-reminder "offer a short activity" setting; patient reminder card gains an optional follow-on | A5 |
| C7 Settings | Accessibility values marked caregiver-set vs suggested; daypart preference; appointment export entry | A4, A6, A7 |
| Session detail | Companion label; conversation observations | A1, A2 |
| **Appointment preview** | **New screen** — the only new screen in this document | A7 |
| P3 / P4 / P6 | Companion copy variants via `GameStrings`. No new screens, no game logic change | A2 |
| P1 / P7 | Activity resolution respects daypart preference. No visible change | A6 |
| D4 / D6 | Companion, origin and daypart shown as distinguishing annotations | A2, A5, A6 |

**No new patient screens.** Every patient-side change is either a string variant or a change in which content gets selected. Game owners G1–G9 are unaffected except for one contract field, below.

# Summary — contract changes implied

| Change | Kind | Affects |
|---|---|---|
| `companion_mode: solo \| together` | Session snapshot | A2 |
| `origin: home \| choose \| recommended \| reminder_bridge` | Session snapshot | A5 |
| `local_daypart` | Session snapshot | A6 |
| `hit_offset_dp` on `attempt_resolved` | **Event payload — the only game-facing change** | A4 |
| Per-content aggregates and `last_used_at` | Server-side derived | A3 |
| `bridge_offered`, `bridge_accepted` | Reminder record | A5 |

`companion_mode` and `origin` join the comparability key. `local_daypart` is recorded and annotated; whether it splits series is an open decision.

# Sequencing

Given the current gates, none of this should displace the core loop.

- **Cheapest and highest value, buildable alongside the core:** A1 and A2 — together roughly a day, no critical-path dependency.
- **Must be decided before game owners build G1, G6, G8, G9:** the `hit_offset_dp` field for A4. The field is trivial; adding it after those games are written is not.
- **After the core loop passes its gate:** A3, A5, A7.
- **Last, and optional:** A6.

# Considered and excluded

- **Unmeasured free-play mode** — offered and not selected by the user. Out of scope.
- **Gameplay as evidence of medication adherence** — excluded. Already prohibited by `PS003_MASTER_CONTEXT.md`; the reminder bridge does not weaken it.
- **Gameplay as detection of decline or progression** — excluded.
- **Any claim that playing improves memory** — excluded. "Cognitive training" phrasing is a therapeutic claim the project cannot support and must stay out of both the product and the pitch.

# Open decisions

1. Whether all seven are adopted, and in what order.
2. Whether `local_daypart` splits comparison series or only annotates them.
3. Who owns each addition — this document proposes screen owners but assigns nothing.
4. Whether A7's export is PDF, share sheet, or print only.
5. Whether the A4 suggestion may ever auto-apply after repeated caregiver acceptance, or must always be confirmed.

# Status

All seven are **NOT STARTED** and unapproved. No file outside this one has been changed. On approval, the affected sections of `PS003_GAME_ASSIGNMENTS_AND_UI.md`, `PS003_ROADMAP.md` and `PS003_MASTER_CONTEXT.md` need updating together, and the contract changes must reach game owners before they build the tap-based games.
