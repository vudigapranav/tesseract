# Patient experience decisions

Updated 2026-09-05 from the user's voice clarification. This is a requirements note, not an implementation record. It supersedes the earlier proposed tap-to-fill coloring and optional reminder scope.

## Confirmed direction

- Coloring uses broad swipes to reveal the original colors of a familiar picture. No palette selection, tiny regions, or requirement to stay inside outlines.
- Patient comfort and meaningful personal content take priority over game count or competitive scoring.
- Daily routine support is central. Reminders are required in the main app, independent of games.
- The user wants to support memory and daily life. The product must not promise memory recovery or infer clinical improvement from game scores.

## Proposed swipe-to-reveal behavior

1. Show a caregiver-selected familiar photo or scene, optionally with its caption.
2. Offer a simple invitation to reveal its colors; show a faded or outline-like version of the same image.
3. A broad finger stroke uncovers the underlying image. No precise tracing or fixed route is required. The original colors appear automatically.
4. Let the patient stop, continue later, request help, or reveal the remaining image. Do not require every pixel to be uncovered.
5. Once revealed, offer a gentle caption or conversation invitation, not an identity quiz. Captions and optional audio come from caregiver-approved content.

Implementation difficulty: medium for a prepared image with a reveal mask; high-quality rendering, saving reveal progress, and touch/device testing still require work. This is different from unrestricted freehand painting or automatic segmentation into fill regions.

A swiping interaction is the user's preferred design, not a proven accessibility benefit for every patient. Use a wide brush, accept short strokes, and provide caregiver help / show-picture controls. Familiar content may evoke mixed emotions: a caregiver can preview and remove it; patients can skip it. Never guarantee happiness or force reminiscence.

## How games relate to routines

- Daily Routine Recall: the direct routine game. Use the patient's caregiver-defined sequence, initially two or three illustrated steps with optional spoken guidance. Avoid a universal "correct" routine.
- Picture Recall: can use familiar objects and places associated with a routine, using prepared caregiver-approved questions. It does not verify that the real activity occurred.
- Reveal Match: can use matching pictures of familiar routine objects. This is familiarity practice, not proof of independence or routine adherence.
- Word Search: can use meaningful routine words for a patient comfortable reading the supported script. Always offer non-reading alternatives.
- Swipe-to-reveal Coloring: familiar scenes may invite conversation about daily life. It is not a recall test.
- Route Quest: can depict a small fictionalized familiar setting. It does not establish real-world navigation safety.
- Trace, Marble Maze and Spot Difference: optional interaction/engagement activities; do not claim they directly restore daily routine skills.

## Required main-app reminders

The caregiver creates and edits reminders for routine activities such as meals, hydration, walks, appointments and caregiver-entered medicine schedules. The app never generates or changes prescriptions or doses.

Proposed patient presentation: one calm card with familiar icon/photo, optional voice cue, and simple acknowledgement or later/help actions. Avoid harsh alarms, accumulating penalties and repeated prompts that cause frustration.

Game completion is never required to receive a reminder. Store routine schedules locally for offline delivery after setup. Request notification permissions and verify actual delivery on the target Android phone, including restart/background behavior. Do not claim guaranteed delivery without testing.

Record prompted / acknowledged / postponed / caregiver-confirmed separately. An acknowledgement is not proof of medicine intake or task completion. No automatic advice to repeat medication after a missed prompt. Caregiver views must show uncertainty rather than inferred adherence. Remote caregiver updates require connectivity; local patient reminders should not.

## Acceptance focus

- Short, imprecise swipes reveal color; the patient does not need to select a color.
- No timer, fail state, negative grading or pixel-perfect completion requirement in coloring.
- Familiar picture and caption are approved by the caregiver and skippable by the patient.
- Routine activity order is editable for the individual patient.
- Reminders function independently of game progress and their actual device delivery is tested.
- No clinical recovery, universal emotional response or medication-adherence claim is produced.

## Work allocation status

Updated 2026-09-06: the user confirmed Aryan five games, Ruthika two and Pranav two, superseding the earlier four/five discussion. Exact game-to-person mapping is proposed in `PS003_GAME_ASSIGNMENTS_AND_UI.md`. Shared architecture ownership remains unchanged. Any Aryan brief must use swipe-to-reveal coloring, not tap-to-fill.
