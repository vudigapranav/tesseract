# Tesseract project continuity

Read `Brain.md` first for the current working state, then update it after every meaningful project change with decisions, changed files, checks actually run, limitations and the next action.

Before changing this project, read `PS003_MASTER_CONTEXT.md` and the relevant sections of `docs/PS003_BUILD_HANDBOOK.md` and `docs/PS003_ROADMAP.md`. The complete original brief is `docs/PS003_ORIGINAL_TEAM_BRIEF.md`.

Respect fixed team ownership and distinguish proposed decisions from confirmed requirements. Do not mark planned features as implemented. Update current status and verified evidence after milestones. The initial request was review/planning only; start implementation when the user asks. Do not modify the supplied SIH PPT unless requested.

## Standing product-quality requirement

Confirmed by the user on 2026-09-07: the final target is a polished, fully
functional, production-quality app that stands out to judges among eight other
teams. Every future Tesseract prompt, plan and handoff must carry this target,
with task-appropriate functional, design, reliability and verification criteria.
Skeletons and demo-only behavior are interim work, not completion. Use the user's
healthcare UI reference as visual inspiration while preserving patient
accessibility, team ownership and truthful evidence. See Brain.md for details;
this requirement alone does not authorize new implementation or external actions.

## Repository layout

`Apnapan/` holds the Flutter mobile side of the app; `services/` holds the backend. Within `Apnapan/`, every game (`Apnapan/games/*`) depends only on `Apnapan/packages/tesseract_game_contract` — no game may add a network, database or auth dependency of its own.
