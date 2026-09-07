# Tesseract product, UI and nine-game assignment specification

Build-plan update (2026-09-06): the active handbook and roadmap now apply this guide through 40 work packages. Use `PS003_BUILD_HANDBOOK.md` and `PS003_ROADMAP.md` for current dependencies and release gates; older roadmap relationship text below reflects the guide's creation before that revision. Exact game mapping and technical presets remain proposals.

Updated 2026-09-06. Planning only; exact game mapping and technical presets are proposed.


# One product.
Nine games.


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

One product.
Nine games.

Patient experience, caregiver support, doctor review, game assignments and analytics.
6 September 2026

The product we are planning

Tesseract is an AI-assisted cognitive gaming and memory assistance platform for elderly people with dementia, with a North Eastern Region focus. The patient receives calm, familiar activities. Caregivers manage content and routine support. Assigned doctors review session evidence and add recommendations.

Confirmed in this conversation

<b>Nine games: Aryan 5, Ruthika 2, Pranav 2.</b> The user corrected the original eight-game sum. The patient P1-P9, caregiver C1-C7 and doctor D1-D8 structure is the requested frontend model. Swipe-to-reveal coloring and main-app reminders remain required.

Proposed in this guide

The exact game-to-person mapping, numerical difficulty presets, event payloads, report format, implementation sequence and doctor portal technology are recommendations for review. The new game counts do not transfer ownership of shared Flutter architecture, backend architecture or final integration.

Status

This is a planning and assignment deliverable. It does not certify any game, API, portal, reminder, security control or AI feature as implemented. Existing records establish initial backend setup only, with no verified working end-to-end application. The supplied six-slide PPT is a source and remains unchanged.

Reading map

2: assignments. 3-6: screens and patient experience. 7-15: nine game briefs. 16-19: telemetry, analytics, difficulty and reports. 20-21: architecture, delivery and QA. 22-24: all six PPT slides explained. 25: sources and pending decisions.


# Game assignments


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

Game assignments

Confirmed counts; proposed game mapping

Owner | Proposed games | Reason

Aryan / 5 | G1 Reveal Match<br/>G4 Trace<br/>G5 Swipe-to-reveal Coloring<br/>G6 Spot Difference<br/>G9 Picture Recall | Bounded modules with reusable content and interaction patterns. Ship sequentially; five games are still a substantial workload.

Ruthika / 2 | G7 Personalized Word Search<br/>G8 Daily Routine Recall | Content-driven puzzles that connect to metric fixtures and personalisation. Grid/script handling needs Shanks's support.

Pranav / 2 | G2 Memory / Route Quest<br/>G3 Marble Maze | Movement, paths and route analytics have the largest integration risk. Keep the first versions small.

Shared ownership stays intact

<b>Shanks:</b> Flutter shell, navigation, state, common game host, pause/resume, asset loading, telemetry adapter and frontend review/integration. Game owners contribute within his structure; they do not create separate apps.

<b>Maharshitha:</b> design system, patient-friendly assets, Figma, bounded caregiver/settings components, screen states and PPT design. <b>Pranav:</b> API/database contracts, authentication boundaries, AI architecture, backend review and final integration, in addition to two game modules.

<b>Ruthika:</b> shared metric calculators and session support remain bounded work under Pranav. <b>Aryan:</b> pitch, synthetic content, smoke tests and truthful demo narrative remain shared duties. <b>Kovid:</b> research, content review and manual QA coordination; no coding requirement.

What each game owner hands over

A playable module; approved content pack; three proposed configurations where appropriate; versioned events; pause/help/exit behavior; expected metric fixtures; integration notes; and device QA evidence. Shanks reviews frontend changes. Pranav reviews analytics/contracts. A peer reviews lead-authored code.

Capacity rule

Counts express catalogue ownership, not equal effort or a promise to finish all nine immediately. Pranav protects integration time; Aryan finishes and integrates one game before starting several more. Use the core loop as the first acceptance gate.


# Patient mode


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

Patient mode

P1-P9: a short, reassuring path through the app

Screen | Content and action | Transitions / states

P1 Home | Warm greeting, familiar picture and one primary Start activity action. Small optional Progress access. | Start to P2 or approved P7. Reminder card can appear independently.

P2 Choose Activity | Two or three available activity cards at a time, with pictures and readable names. Patient can choose or go back. | Selection to P3. Empty catalogue offers caregiver help. Uncached content is unavailable offline.

P3 How to Play | One short instruction and a repeatable demonstration. Try together / Start. | Tutorial marked separately. Start to P4; replay explanation at any time.

P4 Cognitive Game | Shared frame: instruction, large play area, Help, Break and Finish. No technical metrics or countdown pressure. | Pause to P5; finish to P6; backgrounding pauses active time.

P5 Taking a Break | Paused session, calm copy, Continue and Finish for now. | Resume exact state to P4 or save partial session to P6.

P6 Session Finished | Thank the patient; acknowledge participation. Home or Rest. Optional patient preference: enjoyed / prefer another. | No failure summary. Save/upload state is handled quietly.

P7 Personalized Activity | A familiar suggested activity using caregiver-approved content and settings. Patient may choose another. | Explain in simple terms, then P3. Missing content uses approved fallback.

P8 Rest State | No active game. Calm optional image and clear Home / Ready to play action. | Distinct from P5: no paused session waiting. Reminders remain available.

P9 Simple Progress | Recent activities, familiar pictures and gentle completion acknowledgements. | No percentages, rankings, streak loss or cognitive scores. Home returns to P1.

<b>Main route:</b> C5 handover -&gt; P1 -&gt; P2/P7 -&gt; P3 -&gt; P4 -&gt; P6 -&gt; P1/P8. The caregiver area uses a protected return flow. Patients can always stop an activity without completing it.


# Caregiver mode


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

Caregiver mode

C1-C7: profile, personal content, daily support and review

Screen | Required behavior | Data / edge cases

C1 Sign In | Authenticate caregiver and resolve assigned patient membership. | Loading, invalid login, offline existing-session state and expired identity. No self-assigned doctor role.

C2 Patient Basics | Name, age, optional photo, language and accessibility. Known type/stage optional. | Unknown / not provided supported. Alzheimer's, frontotemporal, Lewy body, vascular, mixed/other. No inferred diagnosis.

C3 Know Me | People & Places, Familiar Words, plus interests and caregiver-approved captions/images. | 15-20 meaningful words is a target. Allow fewer or skip. Preview, edit and remove sensitive content.

C4 Caregiver Home | Patient status, today's activity, basic alerts; links to history, observations and pending recommendations. | Show last activity and last sync separately. Review accept / modify / reject here or in a detail view.

C5 Hand Over | Preview patient name, selected activity, sound and accessibility. Enter patient mode. | Clear caregiver return control protected by caregiver authentication or a reviewed local gate.

C6 Reminders | Create, edit, enable, postpone or remove routine reminders, independent of games. | Local schedule after setup; notification permission state; acknowledgement distinct from actual completion.

C7 Settings / Sync | Language, audio, accessibility, downloaded content, queued sessions and last successful sync. | Retry, expired login, conflict and deletion status. Do not silently discard pending sessions on sign-out.

Caregiver home must remain simple

Patient status means last known app activity and caregiver-entered context. It is not live health monitoring. Basic alerts cover failed sync, unavailable content, notification permission, or a recommendation awaiting review. Missed play alone does not create a medical alert.

Recommendation decision

Show the proposed activity/settings, the observations behind it and the previous configuration. Record the authenticated reviewer, decision time, reason and modified settings. Patient mode keeps its last approved activity until the new decision is saved.


# Doctor portal and access


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

Doctor portal and access

D1-D8: multiple assigned patients with traceable review

Screen | Contents / behavior

D1 Doctor Sign In | Verified doctor identity. Assignment provisioning is a separate trusted process; signing up does not expose patients.

D2 My Patients | Search/filter multiple assigned patients. Display patient identity, latest session and freshness. Empty assignment state.

D3 Patient Overview | Known clinical context, accessibility, caregiver observations, recent game participation and approved activity.

D4 Session History | Filter by date, game, level and status. Open event-derived metrics with assistance and sync status.

D5 Cognitive Analytics | Memory, Attention, Recognition and Language sections show relevant game observations with sample counts and caveats. No invented 0-100 clinical score.

D6 Performance Trends | Comparable within-person series, 7/30-day views, configuration changes and missing-data states. Keep games and input modes distinct.

D7 AI-Generated Report | Draft summary grounded in deterministic metrics, source sessions and data quality. Clearly label generated draft and human review status.

D8 Doctor Notes / Recommendations | Attributed notes with timestamps and revision history. Doctor proposals follow a defined review/application policy; no silent overwrite of current activity.

Role permissions

<b>Patient:</b> only assigned patient activities and simple progress through a restricted device session. <b>Caregiver:</b> own assigned patient support, content, reminders, observations and activity decisions. <b>Doctor:</b> assigned patient data, reports and notes. Doctor access does not grant unrelated caregiver account access.

Enforce membership at every API and asset/report request. Check direct session IDs as well as list pages. Revocation denies subsequent requests and invalidates cached access according to a defined policy. Test cross-patient reads, writes, guessed IDs and export links.

Platform decision remains open

The requested doctor portal is part of the product scope. A responsive web portal is proposed; technology and delivery date are not yet confirmed. Reuse the backend and metric definitions. Avoid a second analytics implementation in the portal.


# Patient comfort and reminders


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

Patient comfort and reminders

Shared interaction rules for every screen and game

Visual and interaction specification

Use warm neutral backgrounds, dark readable text, familiar imagery and restrained soft-green encouragement. Show text with icons. Proposed starting targets: 22-26 logical-pixel body text, 28-34 headings, controls at least 48 logical pixels, generous spacing and no essential information conveyed only by color. Verify these on the chosen phone with enlarged system text.

Use WCAG 2.2 as a design reference: normal text contrast at least 4.5:1 and large text at least 3:1. Logical Flutter pixels and CSS target-size criteria are different units. Device QA is required; this guide is not a conformance certification. [3]

Feedback and support

Use short, respectful prompts: "Let's try together", "Take your time" and "Would you like a break?" No Game Over, harsh wrong-answer sound, lost lives, leaderboard or mandatory streak. Audio is optional and repeats the visible instruction. Avoid childish rewards or an assumption that every familiar image is comforting.

Pause on backgrounding. Offer an immediate break, finish or skip. An inactivity prompt may ask whether help is wanted; it never diagnoses fatigue. A caregiver can choose content and input mode. Reading games always have a non-reading alternative.

Reminder card

Show one familiar icon/photo, short caregiver-entered action and simple Acknowledge / Later / Help choices. Present reminders calmly at a safe interruption point; urgent medication logic is outside this prototype. A reminder does not require the patient to win or play a game.

Store schedules locally after setup. Test permission denial, background delivery, restart, time-zone change, schedule edits, cancellation and duplicate prompts. Network-dependent caregiver changes show when they last reached the device. Do not promise guaranteed delivery until tested.

Reminder record and interpretation

Keep scheduled, prompted, acknowledged, postponed, cancelled and caregiver-confirmed events distinct. Acknowledgement means the person tapped a button, not that medicine was taken. The app stores caregiver-entered schedules and never generates prescriptions, changes doses or advises repeating a missed medicine.

Important distinctions

P5 is a paused game; P8 is rest without an active session. Daily Routine Recall is a game about a chosen sequence; C6 is real routine support. Coloring is broad swipes revealing original colors, not tap-to-fill or a color-memory test.


# G1 / Reveal Match Cards


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

G1 / Reveal Match Cards

Proposed owner: Aryan | Shared frontend reviewer: Shanks

Purpose and patient flow

Find matching pairs using large familiar pictures. Candidate observations relate to recognition and visual memory within this task.

Show a brief example. Tap one card, then another. A matched pair stays visible; a mismatch returns gently after a readable exposure period. Offer hint, break and finish. Ignore accidental double taps and taps during a resolving animation.

Configuration | Proposed starting preset

Supported | 2 pairs / 2 x 2; distinct images; optional guided preview.

Standard | 3 pairs / 2 x 3; same generous card size where possible.

Extended | 4 pairs / 2 x 4, only when controls still fit. More pairs is the first adaptation axis.

Events and analytics

card_revealed(card_id); pair_resolved(attempt_id, matched, card_ids); hint_requested(hint_type). Resolve exactly one pair attempt per valid two-card selection.

Pair accuracy = successful pair attempts / all resolved pair attempts. Mismatches = unsuccessful pair attempts. Record pairs found, hints, completion and active duration. Second-card latency runs from first reveal until valid second selection, excluding pauses; report median, not a clinical processing-speed score.

Hand-calculated fixture

Four pairs found in six attempts gives accuracy 4/6 = 66.7% and two mismatches. Zero resolved attempts gives null accuracy. Re-tapping the same card is not a new pair attempt.

Acceptance and interpretation

All pairs stay matched correctly; state survives pause; hint-assisted activity is labelled; final stored metrics match the fixture; repeated upload does not add attempts.

Image familiarity, eyesight, motor interaction and help affect performance. Number of pairs and preview support are separate settings; do not quietly change both.


# G2 / Memory / Route Quest


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

G2 / Memory / Route Quest

Proposed owner: Pranav | Shared frontend reviewer: Shanks

Purpose and patient flow

Navigate a friendly small environment to collect a flag and return to the start. This is the flagship demonstration of route events becoming explainable observations.

Introduce home and one destination with clear landmarks. Demonstrate moving with large touch controls. Reach the destination, collect the flag, then return. Offer route highlight/help. Start with a small 2D graph, not an open 3D world.

Configuration | Proposed starting preset

Supported | 3 landmarks, a single route and visible destination cue.

Standard | 4-5 landmarks with one decision junction; same input controls.

Extended | 5-6 landmarks and two junctions; optional cue reduction as a separate reviewed change.

Events and analytics

node_entered(node_id); edge_traversed(edge_id, distance_units); destination_reached; flag_collected; return_completed; wrong_interaction(target_id); route_help_used. Record map_version, start and destination IDs.

Target time = active time to destination. Return time = active time from flag collection to home. Route efficiency = shortest valid start-target-home distance / actual traversed distance for completed routes. Revisit = entry to a previously visited node, reported by outward/return phase. Planned return visits are not inherently errors.

Hand-calculated fixture

A completed route with shortest valid round trip 12 units and actual distance 18 has efficiency 66.7%. An unfinished route has null round-trip efficiency and a separate reached-target/returned status.

Acceptance and interpretation

Flag is required before return completion; path distance uses map units; wall blocking and help work; shortest-path fixture passes; pause restores map and position.

Define a wrong turn only for scripted decision junctions against the current objective, excluding valid alternate routes. A fictional familiar map cannot establish real-world navigation safety. Phaser/Godot in the PPT remain alternatives, not a requirement for this first module.


# G3 / Marble Maze


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

G3 / Marble Maze

Proposed owner: Pranav | Shared frontend reviewer: Shanks

Purpose and patient flow

Move a marble along a broad path to a goal. Touch is a first-class alternative to tilt. Observations describe interaction and path control in the selected mode.

Choose touch or tilt with caregiver support. Calibrate tilt when selected. Move slowly through a forgiving maze with no fall-off holes or lives. Hitting a boundary stops/slides the marble gently; help can show the route.

Configuration | Proposed starting preset

Supported | One broad path, few bends, low stable speed.

Standard | One extra bend with the same width and sensitivity.

Extended | Small branching maze; width or speed changes require separate review.

Events and analytics

input_mode_selected; calibration_completed; path_sample(x_norm,y_norm,active_ms); collision_started(boundary_id); goal_reached; help_used. Use fixed-version sampling and debounce continuous boundary contact.

Collision count = distinct contact episodes after separation, not every physics frame. Efficiency = shortest centerline start-goal path / traveled path when completed. Record corrections only using a versioned direction-change rule that ignores jitter. Compare touch and tilt separately.

Hand-calculated fixture

Shortest route 100 units / traveled 125 = 80% efficiency. Holding against one wall for 30 frames records one contact episode. A zero-length or unfinished trajectory produces null efficiency.

Acceptance and interpretation

Touch works without a gyroscope; tilt availability/calibration failures have a clear fallback; collision deduplication and distance fixtures pass; backgrounding stops motion and timers.

Device sensors, grip, tremor, seating and sensitivity change results. Never map collisions to dementia severity. Log board and physics version so incompatible recordings do not share a trend.


# G4 / Trace


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

G4 / Trace

Proposed owner: Aryan | Shared frontend reviewer: Shanks

Purpose and patient flow

Follow broad shapes, objects, letters or numbers with forgiving touch input. Use non-letter shapes when reading or script familiarity is unsuitable.

Show the whole shape and a visible starting cue. Demonstrate one short stroke. Let the patient follow a wide corridor with short or interrupted strokes. Offer a guide or show-completed option. No requirement for pixel-perfect handwriting.

Configuration | Proposed starting preset

Supported | Short straight or curved path, wide corridor, direction cue.

Standard | Longer simple shape with the same corridor width.

Extended | Two-part shape; reducing guide support is a separate option.

Events and analytics

stroke_started(stroke_id); stroke_sample(x_norm,y_norm); stroke_ended; guide_used; trace_finished. Store template_version, corridor width, required segments and sampling rule.

Coverage = unique required reference-path bins visited inside tolerance / all required bins. Deviation = mean nearest-reference-path distance of spatially resampled stroke points / canvas diagonal. Record lifts, active duration and cue use separately; extra lifts are not automatically errors.

Hand-calculated fixture

Visiting 8 of 10 equal reference-path bins gives 80% coverage. Retracing a visited bin adds no coverage. Mean distance 5 pixels on a 500-pixel diagonal gives normalized deviation 0.01.

Acceptance and interpretation

Short strokes join progress; strokes outside bounds are safe; normalized coordinates work across device sizes; unique coverage and pause fixtures pass; direction feedback is enabled only on templates with a defined direction.

Motor ability, input device and template affect performance. Completion tolerance is an engineering setting requiring testing. Do not grade penmanship, infer neurological decline or compare different scripts as equivalent tasks.


# G5 / Swipe-to-reveal Coloring


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

G5 / Swipe-to-reveal Coloring

Proposed owner: Aryan | Shared frontend reviewer: Shanks

Purpose and patient flow

Reveal the original colors of a caregiver-approved familiar image using broad swipes. The purpose is comfortable engagement and optional conversation.

Preview the familiar picture. Present a faded/outline-like version of the same image. Broad finger strokes reveal the underlying original colors automatically. Accept short strokes. Offer Show picture, Skip, Break and Finish whenever desired.

Configuration | Proposed starting preset

Supported | Wide reveal brush, simple image; Show picture always available.

Standard | Another approved image or optional smaller brush chosen for comfort.

Extended | No automatic harder level. Content and support preferences replace performance-based escalation.

Events and analytics

reveal_stroke(stroke_id, newly_revealed_cells); picture_shown_by_help; caption_played; picture_skipped; activity_finished. Keep image/content version and mask resolution; never log photo bytes or names in events.

Reveal coverage = uniquely revealed eligible mask cells / eligible cells, using a fixed-resolution mask. Record active interaction time, help use and voluntary finish/skip. Repeated strokes do not add coverage. Coverage is participation data, not memory accuracy.

Hand-calculated fixture

Reveal 30 of 100 eligible cells, then swipe over the same area: coverage stays 30%. Show picture may make display coverage 100%, but manual coverage stays 30% and help use is recorded.

Acceptance and interpretation

Imprecise swipes reveal color; no palette, tap-to-fill, scoring, timer pressure or tiny regions; help reveals remainder; mask state survives pause; skipped/private content is respected.

The patient can finish with any coverage. Never require all pixels or use completion speed for difficulty promotion. Familiar imagery may evoke mixed emotions; caregivers can remove it and patients can skip. Do not quiz identity after revealing a family photo.


# G6 / Spot Difference


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

G6 / Spot Difference

Proposed owner: Aryan | Shared frontend reviewer: Shanks

Purpose and patient flow

Find obvious changes between two uncluttered pictures. Candidate observations relate to visual search and attention within the task.

Show images with large differences and generous target areas. Patient selects a changed region. Mark a found region calmly; a false tap gives optional gentle guidance. Offer a hint that highlights one region. Use a layout that preserves readable image size.

Configuration | Proposed starting preset

Supported | 1 obvious difference in a simple scene.

Standard | 2 obvious differences with similar visual density.

Extended | 3 differences; scene complexity changes separately.

Events and analytics

difference_selected(region_id, correct, already_found); hint_used(region_id); puzzle_finished. Store region geometry version and accepted target margins.

Discovery = unique differences found / total differences. Selection precision = new correct selections / (new correct selections + false selections). Exclude taps on already-found regions and debounce repeats. Record active time to first correct, hints and completion.

Hand-calculated fixture

Two unique correct selections and one false selection gives precision 66.7%. If there are three differences, discovery is 66.7%. A later tap on an already-found region changes neither denominator.

Acceptance and interpretation

Target regions match content; enlarged hit areas do not overlap ambiguously; hint/false/repeat behavior is deterministic; both portrait and larger-text layouts remain usable.

High precision after finding one difference is not full completion. Visual impairment, image size and similarity affect observations. Do not create subtle color-only differences or interpret false taps as a clinical attention deficit.


# G7 / Personalized Word Search


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

G7 / Personalized Word Search

Proposed owner: Ruthika | Shared frontend reviewer: Shanks

Purpose and patient flow

Find a few caregiver-approved meaningful words in a readable grid. This activity is offered only when the selected language and reading interaction suit the patient.

Choose supported personal words from Know Me. Display a small grid and a short word list with optional approved picture/audio cues. Select a word with drag or a simpler start/end interaction. Allow a different non-reading activity.

Configuration | Proposed starting preset

Supported | 4 x 4 grid, 1-2 short words, horizontal forward only.

Standard | 5 x 5 grid, 2-3 words, horizontal forward only.

Extended | 6 x 6 grid, up to 4 words; vertical words are a separate reviewed change.

Events and analytics

word_selection(selection_id, target_id_or_null, matched, already_found); hint_used(target_id); puzzle_finished. Store puzzle seed, grid/content version and allowed directions, using opaque word IDs.

Word discovery = unique words found / placed target words. Selection accuracy = newly matched selections / valid submitted selections, excluding already-found repeats. Record hints, active time and per-word selection latency. A cancelled gesture is not a wrong answer.

Hand-calculated fixture

Two target words found in three valid submissions gives 66.7% selection accuracy and 100% discovery when only two words were placed. Empty/cancelled gestures add no attempt.

Acceptance and interpretation

Puzzle generator verifies every target placement and solution; handles duplicate, absent, long and too-few words without loops; font/script shaping is tested; fixtures reproduce a puzzle from its seed.

15-20 profile words does not mean 20 words per puzzle. Tokenization must respect grapheme clusters and the target script; do not split combining characters. First release uses a reviewed supported pack; unsupported content shows an alternative rather than silently corrupting words.


# G8 / Daily Routine Recall


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

G8 / Daily Routine Recall

Proposed owner: Ruthika | Shared frontend reviewer: Shanks

Purpose and patient flow

Practise a caregiver-defined familiar sequence using pictures and optional approved spoken cues. Keep routine knowledge distinct from actual task completion.

Show the individual routine briefly, then ask a simple next-step choice. Start with two illustrated options. Use tap choices before introducing dragging. Explain gently and allow replay or help. Routine order is editable, never universal.

Configuration | Proposed starting preset

Supported | 2 routine steps, visible sequence and 2 choices.

Standard | 3 routine steps, same support and choice count.

Extended | 4 routine steps; hiding preview or adding a choice is a separate change.

Events and analytics

routine_previewed; step_answered(question_id, option_id, first_attempt, correct); sequence_replayed; hint_used; routine_finished. Store routine_version and question-set version.

First-attempt accuracy = questions answered correctly on first valid attempt / questions attempted. Eventual completion and retry count are separate. Record hints, sequence replays and active response latency per question.

Hand-calculated fixture

Three questions with two first-attempt correct answers gives 66.7% accuracy. Correcting the third question later makes completion 100% without changing first-attempt accuracy.

Acceptance and interpretation

Changing the caregiver sequence updates the answer key and version; old sessions keep their original version; ambiguous routines can be removed; reminders continue working when this game is skipped.

Caregivers define routines with appropriate guidance where needed. Do not supply universal medicine-before-food rules or prescription advice. A correct game answer is not evidence that the patient performed a routine independently.


# G9 / Picture Recall


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

G9 / Picture Recall

Proposed owner: Aryan | Shared frontend reviewer: Shanks

Purpose and patient flow

View a simple image, then answer a few prepared questions about its visible contents. Use familiar objects/places when approved, without forcing emotionally sensitive identity questions.

Show the picture with patient-controlled readiness. Hide it when ready. Ask a short question with two large picture choices. Offer Show again and Skip. Questions and correct answers are approved content, not live AI guesses about family photos.

Configuration | Proposed starting preset

Supported | Simple image, 1 question, 2 choices, unlimited preview.

Standard | Same image complexity, 2 questions, 2 choices.

Extended | 3 questions; add an option or retention interval only as a separate tested setting.

Events and analytics

picture_presented; ready_pressed; picture_hidden; recall_answered(question_id, option_id, first_attempt, correct); picture_shown_again; hint_used. Store image/question version and actual exposure duration.

First-attempt accuracy = first-attempt correct / questions attempted. Record number of answered questions, show-again count, hints, exposure time and active answer latency. If the image was shown again, label subsequent responses supported.

Hand-calculated fixture

One correct first answer out of two attempted questions gives 50%. Re-showing the image before question two marks that answer supported; it must not enter an unassisted comparison series.

Acceptance and interpretation

Every question has a visible unambiguous answer; image and question versions stay linked; show-again support is logged; pause does not lose the current question; private images never enter external prompts.

Recognition choices and free recall are different tasks. Use the correct task label and do not compare them in one series. More exposure, familiar content, help and repetition can change results without any change in clinical condition.


# Shared session and event contract


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

Shared session and event contract

One schema connects all nine games to the same backend

Game host responsibilities

Shanks supplies a common game host with start(config, content), pause, resume, requestHint and finish(status) behavior. Owners return structured events through one adapter. Games do not write directly to the database, authenticate users independently or navigate into caregiver screens.

Session configuration snapshot

Persist session_id, patient_id, game_id, game_version, schema_version, config_version, content_version, metric_version, input_mode, language, tutorial flag, support settings, difficulty parameters and status. Store actual settings, not just an Easy/Medium/Hard label. Freeze the snapshot for that session.

Event envelope

Each event has event_id (device-generated UUID), session_id, seq, event_type, occurred_at (UTC), elapsed_ms (monotonic session clock), schema_version and a bounded payload. The backend resolves patient access through the authenticated session. Content uses opaque IDs. Names, personal words, image URLs and raw photo/audio content do not belong in telemetry.

Common lifecycle

session_started; tutorial_started/completed; hint_requested; support_changed; paused(reason); resumed; session_finished(status, final_seq). Status values distinguish completed, stopped_by_user, interrupted and error. Only one finalization is accepted. A replay does not finish the same session twice.

Time and assistance

Active duration is the sum of foreground, unpaused play intervals. Exclude explicit breaks, background time and tutorial time. Do not silently remove hesitation. Response latency begins when an actionable prompt is ready and ends at its valid response, subtracting overlaps with pauses. Distinguish caregiver assistance, in-game hints and unknown assistance.

Durability and completion

Write locally before upload. Create the session idempotently, upload event batches, then complete with final_seq. Server uniqueness covers event_id and session_id + seq. Gaps block final metrics until recovered or explicitly marked incomplete. Retain queued events until acknowledged and retry without changing their IDs.

Sampling and validation

Use bounded, versioned path sampling for movement games; do not stream every rendered frame. Validate sequence, enum, range and payload size. Record monotonic time for duration and UTC for calendar views. Device clock anomalies affect date placement, not fabricated speed. Conflicting payloads under the same ID raise an integrity error.


# Analytics and performance trends


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

Analytics and performance trends

Measure what happened in the game before interpreting it

Measure | Definition and display rule

Accuracy | Use the per-game denominator in G1-G9. Zero eligible attempts = null. Never assign coloring an accuracy score.

Completion | Game-specific objective reached, distinct from accuracy. Stopped/interrupted sessions remain visible but separate.

Time | Active duration in seconds; response latency in milliseconds or seconds with units. Report medians across eligible sessions.

Errors / support | Defined mismatches, false selections or contact episodes; hints, caregiver help and unknown assistance separately.

Efficiency | Task-specific route ratio for completed valid paths only. No cross-game efficiency average.

Engagement | Describe sessions started, voluntary participation, active interaction and optional patient feedback. Time alone does not establish enjoyment.

Provisional individual reference

Proposed reference: tutorial followed by the first three valid, completed comparable sessions for that game. Store metric medians and sample count. Three is an engineering starting point, not a validated clinical assessment protocol. Show Insufficient comparable sessions until eligible data exists.

Comparability requires the same game/version, difficulty parameters, input mode, support status, language and relevant content/task complexity. Exact repeated content can produce practice effects; identify content reuse. A changed level starts a separate series or an explicitly annotated segment. Never pool assisted and unassisted results invisibly.

Trend example using synthetic data

Reference accuracies 60%, 70%, 80% have median 70%. A later comparable median of 80% is +10 percentage points, not +10% relative improvement. Show dates, session count, attempts and support. Say "Higher matching accuracy in these sessions" rather than "Memory improved by 10%".

7-day and 30-day views

Filter by session occurrence date in the chosen display time zone; label late-arriving uploads. Show each point and sample count, gaps rather than zeroes, and reference/configuration changes. Keep noncomparable series separate. A longer window is a viewing option, not evidence of disease progression.

D5 domain sections

Memory: matching, picture, routine and route observations. Attention: visual search. Recognition: picture choices and matching. Language: supported-script word search. These are proposed groupings, not validated domain scores. Trace/maze can sit under motor/visuospatial observations. No combined cognitive score.


# Difficulty and the AI engine


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

Difficulty and the AI engine

Explainable recommendations, applied after human review

Separate the five jobs

<b>Analyse game data:</b> deterministic event-to-metric functions. <b>Identify trends:</b> comparable within-person summaries. <b>Personalize activities:</b> filter approved content by interests, language, accessibility and availability. <b>Adjust difficulty:</b> propose one bounded change. <b>Generate doctor insights:</b> summarize verified observations and uncertainty.

Proposed Reveal Match rule, version 0.1

Hold when data is missing, incomplete, assisted/unknown, or fewer than three comparable eligible sessions exist. For progression, require three completed unassisted sessions, each with at least as many resolved pair attempts as configured pairs, accuracy at least 85% in every session and no hints. Then propose one increase in pair count, within the approved range. This proposed per-level minimum replaces the earlier handbook's fixed four-attempt minimum, which would block successful two- and three-pair starter boards. Record the change in the rule version.

For support, accuracy below 50% in two comparable sessions or repeated requests for help can propose fewer pairs or more guidance. Otherwise hold. Any patient or caregiver request for an easier activity can be honored without waiting for a score threshold. Speed alone never raises difficulty. These thresholds are unvalidated prototype rules requiring usability review.

Other games need their own rules

Do not apply matching accuracy thresholds to routes, coloring or tracing. Use each game's objective and data-quality conditions, compare consistent configurations, and initially keep clinician/caregiver-reviewed presets. Coloring uses comfort/content preferences without automatic difficulty promotion. Maze and Trace require interaction-mode and motor-accessibility context.

Recommendation record

Save recommendation_id, patient_id, rule_version, source_session_ids, measured values, current/proposed configuration, reason, data-quality flags, created_at, expiry/status and reviewer decision. Check current configuration version on approval so an old proposal cannot overwrite a newer decision.

Application and conflict policy

States: pending, accepted, modified, rejected, expired, superseded. The caregiver reviews the proposal in C4. Doctor suggestions appear with attribution. Proposed default: caregiver confirmation activates the next patient activity, including doctor-originated suggestions; alternative doctor authority requires an explicit policy. No mid-session change or silent last-write-wins conflict.

AI scope

Rules can deliver the first explainable loop without training data or an LLM. Optional later language generation receives only authorized, minimized aggregate data through an approved service and cannot change metrics. Future learned ranking requires a defined outcome, consent/data plan, held-out evaluation and monitoring; accumulated sessions alone do not justify ML.


# Doctor report and worked example


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

Doctor report and worked example

A grounded draft with an auditable path back to sessions

D7 report structure

Include patient reference, date range/time zone, generated_at, report_version, source session IDs, last sync, games/configurations covered and sample counts. Separate observations, comparison limits, suggested support and human notes. Include draft/reviewed status, reviewer identity and review time.

Synthetic example - for demonstration only

Section | Example content

Data coverage | Three completed Reveal Match sessions; same 4-pair configuration and touch mode. No tutorial sessions included. All events received.

Observed play | Four pairs per single-board session. Results: 4/5 = 80%, 4/4 = 100%, 4/6 = 66.7%. Median accuracy 80%; zero hints; assistance recorded as absent.

Suggested next step | Hold the current setting. The progression rule requires at least 85% accuracy in every eligible session; only one of these sessions meets that condition.

Range protection | Even if all three sessions met the threshold, four pairs is the current proposed ceiling. Hold at that ceiling or offer a different approved activity; do not invent an unavailable higher level.

Interpretation | These observations describe matching performance during app use. They do not establish memory recovery, diagnosis or disease progression.

Report quality checks

Every number must be calculated from cited sessions and valid denominators. Round only for display. Exclude invalid/missing sessions from eligible comparisons, while showing their count. Avoid recommendations unsupported by an implemented, versioned rule. If there is no comparable data, explicitly say so.

Generation and fallback

A template can generate this report first. If an optional language model is later added, validate its structured output against source facts and allowed statements. Reject invented numbers, clinical diagnoses or prescriptions. When generation fails, show the deterministic summary and a retry option.

Notes and exports

D8 notes are authored by the doctor and stored separately from generated text. Editing a generated report preserves provenance and review history. Export access uses the same patient assignment checks; include freshness and draft status in the export. Never let the patient screen display raw professional analytics.


# Architecture and integration


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

Architecture and integration

The requested screens share one source of session truth

Proposed components

Android-first Flutter patient/caregiver app; Flutter game components, Flame only when useful; FastAPI modular backend; PostgreSQL server storage; SQLite device cache/outbox; caregiver identity verification with server-side patient membership. Authentication service selection and dependency versions require confirmation. Doctor web portal uses the same API and permissions.

Data path

Caregiver Know Me profile and approved config -&gt; cached activity/content -&gt; game host -&gt; local session/event queue -&gt; authenticated sync -&gt; validated session -&gt; versioned metrics -&gt; pending recommendation -&gt; caregiver/doctor review -&gt; approved next activity. The doctor portal reads the stored metrics and decisions, not new calculations in the browser.

Proposed API surface

POST /v1/patients; PUT /v1/patients/{id}/personalization; GET /v1/patients/{id}/activity. PUT /v1/sessions/{client_uuid}; POST /v1/sessions/{id}/events:batch; POST /v1/sessions/{id}/complete. GET /v1/patients/{id}/summary and /recommendations; POST /v1/recommendations/{id}/decision. These extend the existing proposed contracts.

Doctor additions proposed: GET /v1/doctor/patients; assigned-patient session/history views; POST /v1/patients/{id}/reports; GET report status/content; POST /v1/patients/{id}/notes. Reminder CRUD must include schedule version, device delivery state and cancelled occurrences. Freeze exact request/response fixtures before implementation.

Storage and offline behavior

Keep users, patients, memberships, content references, sessions, events, metrics and recommendations separate. Add doctor assignments, notes, reports, reminders and reminder occurrences. Profile/content changes are versioned. Offline play uses cached approved content; enrollment and first login may require internet. Server reports stay stale until sync and say so.

Boundaries to settle before real deployment

Private media requires protected access and caregiver control. Use secure token storage and TLS; select and verify local encryption separately. Plain SQLite plus encrypted transport does not prove encrypted local storage. Define cache removal, account sign-out, revocation, retention and deletion propagation. Use synthetic demo profiles until the real-data process is established.

Shared implementation folders

Proposed: apps/mobile/lib/core and features under Shanks; games/&lt;game_id&gt; per assigned contributor; services/api/app/{auth,patients,sessions,analytics,recommendations} under Pranav; docs/contracts and docs/qa for fixtures and evidence. These are proposed boundaries, not a claim that all folders or modules exist.


# Delivery order and acceptance


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

Delivery order and acceptance

Nine-game ownership is compatible with staged delivery

Stage | Deliverable and gate

A / Contracts & shell | Shanks supplies shared game host and screen navigation. Pranav freezes event/config fixtures. Maharshitha supplies UI/assets. All contributors can run the same sample activity.

B / First complete loop | Aryan builds Reveal Match; Ruthika supplies metric fixtures; Pranav connects persistence/recommendation; Shanks integrates C4/C5 and P1-P6. A real session reaches storage and an approved next activity appears.

C / Required support | Know Me, reminders, pause/rest, offline outbox and caregiver controls become reliable. Test on the chosen phone; do not mark reminders complete from a static screen.

D / Catalogue batches | Aryan: Coloring, Spot Difference, Picture Recall, then Trace. Ruthika: Routine Recall, then Word Search. Pranav: small Route Quest, then Maze. Order is proposed and adjusts to capacity.

E / Doctor & hardening | D1-D8, assigned-patient access, trends, grounded report and notes. Full offline replay, interruption recovery, regression, claim audit and demonstration.

Existing roadmap relationship

The earlier Sep 5-8 core and Sep 9-10 upgrade dates are historical planning targets, not verified progress or a new nine-game deadline. This guide changes catalogue ownership and elaborates the requested UI. S11/S19/S26/S28 game owners need the proposed mapping reviewed; no S01-S30 task becomes complete because this PDF exists.

Every game acceptance pack

Record build/commit, device and OS, configuration/content version, session ID, expected/actual result, screenshot or recording, metric fixture and reviewer. Exercise tutorial, normal completion, zero attempts, early finish, hint/help, pause/background, restart and offline retry. Include game-specific edge cases from G1-G9.

System release blockers

Crashes in the core path, lost/duplicated sessions, inconsistent metrics, unauthorized patient access, misleading medical claims and unusable patient controls block a demo release. Test incomplete sequences, duplicate uploads, approval conflicts, changed levels, unsupported content and reminder delivery failures.

Demo acceptance

Using synthetic data, create a profile, hand over, play, pause/resume, finish, sync, inspect metrics, review a suggestion and open the next approved activity. Doctor sees only assigned patients. Explain which screens are live and which are planned; use a labelled recording or fallback only when needed.


# PPT explained / slides 1-2


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

PPT explained / slides 1-2

Source: supplied six-slide Tesseract deck; no edits made

Slide 1 / Title page

The deck identifies Smart India Hackathon 2026, PS ID SIH26003, the full AI-based cognitive gaming and memory assistance problem title, MedTech / BioTech / HealthTech theme and Software category. Team name is Tesseract and Team ID is blank. These are user-supplied submission details; the official problem listing/template and team ID remain to be verified before submission.

Slide 2 / Idea and product loop

The proposed solution joins a patient game space, caregiver dashboard and healthcare-worker review layer. Know Me collects people, places, interests and meaningful words. A short familiarisation/reference activity precedes logged play. The deck describes nine offline games and medicine, hydration and routine reminders, followed by one clear recommendation and human review.

The loop runs through knowing the person, reference play, personalisation, play, observation, analysis, adaptation, assistance and monitoring. The new P/C/D screen model makes these roles explicit: C2/C3 gather context, P3/P4 deliver play, C4 reviews the recommendation, C6 supports routines and D3-D8 support professional review.

How the nine games fulfil that idea

Reveal Match supplies the first simple evidence loop. Route Quest demonstrates route/return behavior. Word Search and Picture Recall use approved familiar content. Routine Recall connects to personal sequences. Coloring offers engagement without graded recall. Trace, Maze and Spot Difference provide optional alternative interactions.

What to explain accurately in the pitch

The 7.4% figure is an estimate for Indians aged 60+ from the cited LASI-DAD research, not a current app adoption estimate or a claim about all ages. The study supports the burden of the problem, not efficacy of Tesseract. [1]

Describe gameplay as producing app observations. The deck phrase about a "measurement instrument" does not establish clinical validation. Clarify that tutorial/reference play uses ordinary activities; it is not a diagnostic baseline examination.

The catalogue, offline operation, low-cost device compatibility and personalised content are target capabilities until demonstrated. "Difficulty is earned" should be explained gently as performance- and comfort-informed support, with human review, not a reward the patient must earn.

Suggested presenter explanation

"A caregiver helps us understand the person. The patient chooses a familiar activity, with help and breaks always available. We record what happened during play and suggest a manageable next activity. Caregivers and assigned doctors can inspect those observations and guide the plan."


# PPT explained / slides 3-4


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

PPT explained / slides 3-4

Technical approach, feasibility and AI phasing

Slide 3 / Technology and implementation path

The deck proposes Flutter for Android, Flutter/Flame for simple games, Phaser or Godot for the flagship, FastAPI/Python for backend and analytics, PostgreSQL, SQLite/Hive and Firebase. It shows the app, interaction layer, logger, analytics, recommendation, caregiver dashboard and healthcare-worker review as connected stages.

The event list covers time, accuracy, errors, retries, hints, route efficiency, completion and engagement. This guide turns those labels into per-game definitions: coloring has no accuracy; contact episodes differ from card mismatches; incomplete routes do not receive full-route efficiency; time is active play time.

The slide shows content download, offline local play and reconnect/sync. Implementation needs stable IDs, persisted outbox, complete-event validation, deduplication and visible freshness. "Encrypted sync" describes a transport/security requirement, not proof that the device queue is encrypted.

Proposed simplification

Keep the first Route Quest inside the shared Flutter/Flame environment if feasible. Adding another engine introduces embedding and lifecycle work. Choose one local database and one session contract. Retain alternative engines as options; do not present all alternatives as simultaneously implemented.

Slide 4 / Feasibility, risks and mitigation

The deck names connectivity, regional scripts, elderly usability, caregiver setup effort and over-reading scores as risks. Its proposed mitigations are offline queues, language packs, large controls/voice, guided setup and human-reviewed app indicators. It also proposes a transparent feature/rule engine first and learned recommendations later.

A mature technology stack supports feasibility but cannot establish completion in one hackathon. Entry-level Android performance needs measurements on a named device. Assamese, Bengali, Meitei, Khasi and Mizo packs need native content review, script/font checks and audio review. Some language changes can require code changes; a data pack alone is not sufficient proof.

The ten-minute setup and ASHA-assisted enrolment are proposed workflow assumptions until usability and operational partners confirm them. Photo/voice capture is additional implementation scope. Do not assume voice prompts, encryption or every language already exists.

AI phasing clarification

Phase 1 can use deterministic game metrics and explainable rules. Weighted features may be internal experiments, but weights do not validate a Memory or Attention score. Phase 2 needs an evaluation plan and evidence before claiming improved recommendations. Human approval remains visible in C4 and the professional review flow.


# PPT explained / slides 5-6


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

PPT explained / slides 5-6

Benefits, references and the limits of evidence

Slide 5 / Intended benefits

For patients, the deck proposes their own language, familiar people/places, routine reminders, suitable challenge and encouragement. For caregivers, it proposes one clear daily recommendation, completion/engagement history, 7- and 30-day trends, observations and control of personalisation. For healthcare workers, it proposes longitudinal records, activities that appeared easier/harder, caregiver observations, review decisions and a multi-patient view.

The new model supplies patient P1-P9, caregiver C1-C7 and doctor D1-D8 for these benefits. P9 stays simple; detailed comparisons belong in C4 and D5/D6. D2 supports a caseload with explicit assignments, and D7/D8 separate a generated report from professional notes.

System-level claims in the slide include NER deployment, offline operation, multilingual extensibility, regional content, additional games, low-cost hardware and support for NPHCE community care. Treat these as intended alignment and future deployment goals. No government partnership, adoption or programme integration is established by the supplied deck.

Slide 6 / Research and references

The deck cites Lee et al. on LASI-DAD prevalence, WHO dementia material, ARDSI, Cochrane cognitive stimulation evidence, the WHO action plan and MoHFW NPHCE context. Technical references cover Flutter, Flame, Phaser, Godot, FastAPI, PostgreSQL, SQLite, Hive and Firebase. Accessibility references point to WCAG 2.2. It labels its reference imagery as conceptual and disclaims diagnostic use.

Lee et al. support the national prevalence estimate. The deck also states a 7.35% North Eastern grouping excluding Assam; retain that grouping only with the original table and exclusions verified, rather than applying it to the entire NER. [1]

Cochrane reports small cognitive benefits from cognitive stimulation for people with mild-to-moderate dementia. This evidence does not validate this particular app, its nine games or a disease-progression metric. Programme findings should not become a claim of guaranteed memory recovery. [2]

Evidence still needed for Tesseract

A claim-to-source register maintained by Kovid/Ruthika; current programme documents if cited substantively; a competitor comparison for any uniqueness claim; actual setup duration and device performance; local language review; accessibility checks; and appropriate supervised usability feedback. Clinical efficacy requires a separate research process beyond an engineering demo.

PPT status discipline

In the eventual pitch, identify implemented, demonstrated, simulated and planned capabilities. A screenshot is not an offline test; a synthetic trend is not patient evidence; a generated paragraph is not a clinical insight validated by a doctor. The supplied PPT remains untouched by this documentation task.


# Sources and decisions


TESSERACT / PRODUCT & GAME DELIVERY GUIDE

Sources and decisions

Source-of-truth notes for the team

Local source materials

The supplied Cognitive_Gaming_for_Elderly_Dementia_-_Tesseract-5.pptx, slides 1-6, was read for this guide. Project sources: PS003_MASTER_CONTEXT.md; docs/PS003_ORIGINAL_TEAM_BRIEF.md; docs/PS003_BUILD_HANDBOOK.md; docs/PS003_ROADMAP.md; docs/PS003_PATIENT_EXPERIENCE.md. The original brief remains preserved.

External references checked for this guide

[1] Lee J. et al. (2023), <i>Prevalence of dementia in India: National and state estimates from a nationwide study</i>. DOI: 10.1002/alz.12928. Supports the national prevalence context, not Tesseract effectiveness.<br/><link href="https://pmc.ncbi.nlm.nih.gov/articles/PMC10338640/" color="#137F7A">Read the original study</link>

[2] Cochrane, <i>Can cognitive stimulation benefit people with dementia?</i> Review CD005562. Evidence about cognitive stimulation programmes, not a validation of this game catalogue.<br/><link href="https://www.cochrane.org/evidence/CD005562_can-cognitive-stimulation-benefit-people-dementia" color="#137F7A">Read the Cochrane evidence summary</link>

[3] W3C, <i>Web Content Accessibility Guidelines (WCAG) 2.2</i>. Reference for contrast, target sizing, timing and accessible interactions. Native-device usability still requires testing.<br/><link href="https://www.w3.org/TR/WCAG22/" color="#137F7A">Read WCAG 2.2</link>

Confirmed requirements carried forward

Aryan five games; Ruthika two; Pranav two. Patient/caregiver/doctor screen structure as provided. Caregiver-controlled familiar content, supportive patient language, broad-swipe coloring, routine reminders independent of games and assigned-patient access. Pranav retains backend/AI architecture; Shanks retains Flutter architecture/integration.

Proposed decisions for team review

Exact G1-G9 owner mapping; difficulty presets and rule thresholds; first release deadline/catalogue depth; doctor portal technology and enrollment/assignment process; authority for applying doctor suggestions; supported language/content pack; target phone; offline security/deletion policy; any external report-generation service.

Completion record

This milestone produces a PDF and a matching editable requirements record. It documents all six PPT slides, all requested screen IDs and nine game briefs. No application implementation milestone, clinical validation, game completion or official submission approval is claimed. Future progress updates should attach build and test evidence.