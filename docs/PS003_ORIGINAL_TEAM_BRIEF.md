# MASTER TEAM + DEVELOPMENT CONTEXT FOR SIH PS-003

I am working with a 6-member team on Smart India Hackathon 2026 Problem Statement:

**SIH26003 — AI-Based Cognitive Gaming and Memory Assistance Platform for Elderly Dementia Patients in the North Eastern Region (NER).**

I want you to act as our **technical project manager + software architect + development mentor + AI engineering lead**.

Do NOT immediately start generating code.

First understand our team structure, skill levels, responsibilities, development workflow, and the product we are building.

After understanding this context, I will ask you to generate detailed sprint plans, tasks, coding prompts, architecture documents, integration instructions, etc.

---

# 1. OUR TEAM

We have 6 members.

## PRANAV — TEAM LEAD

Pranav is the Team Lead.

Main responsibilities:

* Backend
* AI/Analytics
* Overall technical architecture
* Backend integration
* Connecting all parts of the application
* GitHub/repository management
* API contracts
* Database architecture
* AI/recommendation architecture
* Final system integration
* Technical consistency of the PPT
* Assigning work to other team members
* Making sure all individual modules eventually become ONE working application

Pranav has **Claude Pro**.

Pranav should NOT personally code every module.

His role is to define architecture, contracts and interfaces, delegate work, review it, and perform final integration.

---

# 2. SHANKS — MAIN FRONTEND ENGINEER

Shanks is our strongest frontend developer.

Main responsibilities:

* Main patient-facing frontend
* Flutter application
* Frontend architecture
* Navigation
* Patient screens
* Game integration
* Game implementation
* API integration on frontend
* Frontend debugging
* Final frontend integration

Shanks has **Gemini Pro**.

Shanks should be the primary owner of the Flutter codebase.

He should establish the frontend architecture so that Maharshitha can contribute smaller frontend modules without creating a second conflicting architecture.

---

# 3. MAHARSHITHA — UI/UX + FRONTEND SUPPORT + RESEARCH + PPT

Maharshitha works on:

* UI/UX
* Figma
* Visual design
* Patient-friendly elderly UI
* Frontend support
* Small frontend modules
* Research
* PPT/design support

She is less experienced in frontend coding than Shanks.

Therefore, do NOT give her ownership of the entire frontend architecture.

Instead:

* Shanks establishes the Flutter architecture.
* Maharshitha implements bounded frontend components/screens under that architecture.
* She owns the design system.
* She works closely with Shanks.
* She also contributes to research and PPT.

She has **Gemini Pro**.

Examples of suitable frontend tasks for Maharshitha:

* Patient Profile screen
* Reminder cards
* Routine cards
* Game result cards
* Settings
* UI states
* Accessibility improvements
* Caregiver dashboard UI
* Small reusable components

---

# 4. RUTHIKA — BACKEND SUPPORT + AI/ANALYTICS + RESEARCH

Ruthika has less backend knowledge but can contribute meaningfully.

Main responsibilities:

* Backend support
* AI/analytics support
* Game performance metrics
* Recommendation logic support
* Clinical/product research
* Research validation
* Data-related work

She should NOT be given ownership of the entire backend architecture.

Pranav owns the architecture.

Ruthika works on clearly defined backend modules and analytics tasks under Pranav's architecture.

Potential responsibilities:

* Game session APIs
* Game event APIs
* Performance calculations
* Analytics logic
* Cognitive performance indicators
* Recommendation rules
* Research on dementia types
* Research on cognitive domains
* Research supporting game/activity choices

Ruthika may have Gemini Pro, but this is not confirmed yet.

---

# 5. ARYAN — PITCH + STORYTELLING + PRODUCT + SOME BACKEND

Aryan's main strength is:

* Pitch
* Storytelling
* Product explanation
* SIH presentation
* Problem/solution narrative
* Judge Q&A
* Product documentation
* Research support

Aryan also knows some backend.

Give him small, isolated backend tasks when useful, such as:

* Demo/seed data
* API testing
* Simple CRUD
* Backend documentation
* Integration testing
* Small backend fixes

Do NOT make him responsible for core backend architecture.

Aryan has **ChatGPT Plus**.

Aryan should understand the actual technical product so that the pitch accurately represents what we have built.

He must NOT pitch unsupported claims such as:

* AI diagnoses dementia
* AI cures dementia
* game scores directly measure disease progression

---

# 6. KOVID — RESEARCH + QA + DOCUMENTATION

Kovid has very little/no coding ability.

He mainly works through his mobile and is strongest at research and information gathering.

He should NOT be forced into coding.

His main responsibilities:

### Research

* Dementia types
* Alzheimer's
* Frontotemporal dementia
* Lewy body dementia
* Vascular dementia
* Cognitive domains
* Existing dementia/cognitive apps
* Existing cognitive games
* Research papers
* NER-specific requirements
* Regional language requirements
* Accessibility
* Ethical considerations
* Existing gaps

### QA

Kovid should become our manual testing coordinator.

He can test:

* patient flow
* games
* caregiver dashboard
* API behavior where possible
* offline behavior
* UI accessibility
* edge cases
* demo flow

He should maintain a test-case checklist.

He can use his available AI subscription/tools for research, competitor analysis, paper summaries and test-case generation.

---

# 7. FINAL TEAM OWNERSHIP

Use this as our fixed team structure:

```text
                         PRANAV
          TECH LEAD + BACKEND + AI/ANALYTICS
                    + INTEGRATION
                           |
          +----------------+----------------+
          |                |                |
       FRONTEND         BACKEND          AI / DATA
          |                |                |
        SHANKS          PRANAV             PRANAV
          |             RUTHIKA           RUTHIKA
          |             ARYAN             |
          |
     MAHARSHITHA
          |
   UI/UX + FRONTEND
     SUPPORT


                  PRODUCT / RESEARCH
                         |
              +----------+----------+
              |          |          |
            ARYAN      KOVID    MAHARSHITHA
              |
            PITCH /
          STORYTELLING
```

Pranav must be included in **AI + Analytics**, not only backend/integration.

---

# 8. HOW WE WANT TO BUILD THE PRODUCT

We are building an AI-assisted cognitive gaming and memory assistance platform.

The central loop is:

```text
Know the Patient
        ↓
Create Personalized Profile
        ↓
Establish Baseline
        ↓
Patient Plays
        ↓
Gameplay Events Captured
        ↓
Performance Analysis
        ↓
AI Recommendation
        ↓
Adaptive Difficulty
        ↓
Caregiver Monitoring
        ↓
Healthcare Worker / Doctor Review
        ↓
Next Personalized Activity
```

The product is NOT intended to independently diagnose dementia.

It should provide:

* cognitive engagement
* memory assistance
* personalized activities
* adaptive difficulty
* performance indicators
* caregiver support
* healthcare-worker review
* daily routine assistance
* reminders
* culturally familiar content
* multilingual support
* offline-first operation

---

# 9. PATIENT PROFILE

The caregiver is the main continuous-management user.

The caregiver can create:

### Basic Profile

* Name
* Age
* Photo
* Preferred language

### Clinical Profile

* Dementia type
* Stage/severity as clinically known
* Healthcare worker/doctor notes where appropriate

Supported dementia profiles:

* Alzheimer's disease
* Frontotemporal dementia
* Lewy body dementia
* Vascular dementia
* potentially mixed/other profiles

### Cognitive/Functional Profile

We want app-level indicators around:

* Memory
* Attention
* Executive Function
* Visuospatial
* Language
* Processing Speed
* Motor Interaction
* Engagement

### Accessibility

* Vision limitations
* Hearing limitations
* Motor limitations
* Preferred interaction mode

---

# 10. "KNOW ME" PERSONALIZATION

The caregiver should enter meaningful personal information.

Examples:

### People

* family members
* friends
* familiar people

### Places

* home
* village
* market
* school
* meaningful locations

### Interests

* gardening
* music
* cricket
* cooking
* sewing

### Personal Memory Words

The caregiver should enter approximately:

**15–20 personally meaningful words**

For example:

* GARDEN
* TEA
* RAVI
* HOME
* MUSIC
* SHILLONG
* FLOWER
* MARKET
* FAMILY

These words can be reused in games.

The important concept is:

> The system learns who the patient is, not only what diagnosis they have.

---

# 11. INITIAL BASELINE

When a patient is newly enrolled, we want a short:

## Cognitive Baseline Session

This is NOT a diagnostic test.

It establishes an individual app-performance baseline.

Potential baseline activities:

* Reveal Match Cards
* Spot Difference
* Marble Maze
* Trace
* Picture Recall
* Memory Quest

We capture:

* time
* accuracy
* errors
* completion
* retries
* hints
* route/path
* hesitation
* interaction patterns

Then create an app-level:

## Cognitive Performance Profile

Example:

```text
Memory          78
Attention       71
Visuospatial    82
Executive       61
Processing      74
Engagement      91
```

Do NOT call this a "Dementia Score."

Do NOT imply that these numbers medically diagnose or measure disease severity.

---

# 12. GAMES

We want a modular game ecosystem.

Priority games:

## 1. Reveal Match Cards

Hidden cards.

Tap one → reveal.

Tap another → reveal.

Match → stay open.

Mismatch → flip back.

Difficulty can change through:

* number of pairs
* grid size
* exposure time
* similarity
* distractors

Metrics:

* accuracy
* mismatch count
* response time
* completion time
* retries
* hints

---

## 2. Memory Quest / Route Quest

This is our flagship game.

Patient enters a simple friendly animated environment.

Goal:

* reach a destination
* collect a flag
* return to the starting point

Potential environment:

* house
* garden
* market
* tree
* school
* familiar cultural/local environment

Track:

* total time
* target acquisition time
* route chosen
* route efficiency
* wrong turns
* repeated locations
* pauses
* wrong interactions
* retries
* help usage
* successful return

This demonstrates:

Gameplay → Behavioral Signals → AI Analysis → Personalization

---

## 3. Marble Maze

Use phone gyro/tilt.

Also provide:

### Touch Mode

for users who have motor difficulties.

Track:

* completion time
* collisions
* path efficiency
* corrections
* hesitation

---

## 4. Trace

Trace:

* numbers
* letters
* shapes
* objects

Track:

* completion
* path deviation
* pauses
* corrections
* direction errors
* time

---

## 5. Coloring

Show a complete image first.

Then convert it into an outline.

Patient colors it.

Use familiar scenes and culturally relevant visuals.

Do not aggressively mark colors as "wrong."

The goal is engagement.

---

## 6. Spot Difference

Use easy visual differences.

Start with:

* 1–3 differences

Then gradually increase difficulty.

Track:

* time to first correct selection
* correct differences
* false taps
* hints
* completion

---

## 7. Personalized Word Search

Caregiver provides 15–20 personal words.

The game dynamically creates a word-search using those words.

Example:

GARDEN, TEA, RAVI, HOME, MUSIC, SHILLONG.

This should communicate:

**Personalized reminiscence + cognitive engagement.**

---

## 8. Daily Routine Recall

Example:

Wake Up → Brush → Medicine → Breakfast → Walk

Ask:

* What comes next?
* What comes first?
* What should you remember before going outside?

---

## 9. Picture Recall

Show an image.

Hide it.

Ask simple questions about what was seen.

Where appropriate, use caregiver-provided familiar/personal images.

---

# 13. POSITIVE PATIENT EXPERIENCE

The patient UI must feel:

* happy
* warm
* safe
* encouraging
* calm
* familiar
* playful

Avoid:

* Game Over
* You Failed
* Wrong!
* harsh red error states
* intimidating scoreboards
* complicated dashboards
* tiny text

Use:

* Great job!
* Nice try!
* Let's try again.
* Wonderful!
* Almost there!
* Let's do it together.

Use a positive visual language, especially soft green success states, but do not make the entire interface aggressively green.

The patient should feel:

> Supported, not tested.

---

# 14. CAREGIVER DASHBOARD

The caregiver is the primary monitoring user.

Dashboard should include:

* Patient profile
* Clinical profile
* Personalization
* Today's activities
* Game history
* Performance indicators
* Trends
* AI recommendations
* Reminders
* Caregiver observations

Example:

```text
Patient: Meena

Today's Activities
4 / 5 completed

Memory       78
Attention    71
Visuospatial 83
Engagement   92

AI Recommendation:
"Prioritize memory recall and routine sequencing today.
Reduce navigation difficulty by one level."
```

---

# 15. DOCTOR / HEALTHCARE WORKER VIEW

Higher-level review.

Include:

* patient clinical profile
* stage
* performance trends
* game analytics
* caregiver observations
* AI recommendations

Human-in-the-loop:

```text
AI observes
    ↓
AI analyzes
    ↓
AI recommends
    ↓
Caregiver / Healthcare Worker reviews
    ↓
Recommendation accepted/modified
```

AI does NOT replace the healthcare worker.

---

# 16. AI / ANALYTICS

The AI system should initially be explainable.

Do not over-engineer the MVP with unnecessary deep learning.

Start with:

### Game metrics

```text
accuracy
speed
errors
completion
hints
efficiency
engagement
```

Then derive:

```text
Memory
Attention
Executive
Visuospatial
Language
Processing Speed
Engagement
```

Then:

```text
Performance Profile
        ↓
Recommendation
        ↓
Difficulty
```

Example:

High accuracy + low errors + fast completion:

→ increase difficulty slightly.

Low accuracy + high errors + excessive retries:

→ reduce difficulty / increase support.

The AI should optimize:

> Challenge + Comfort + Engagement

not simply maximize difficulty.

---

# 17. OFFLINE-FIRST

The PS targets NER, including low-connectivity environments.

Therefore:

```text
Internet Available
      ↓
Download Profile / Content
      ↓
OFFLINE
      ↓
Patient Plays
      ↓
Events Stored Locally
      ↓
Internet Returns
      ↓
Secure Synchronization
      ↓
Caregiver Dashboard Updated
```

This should eventually be part of the architecture.

---

# 18. TECH STACK

Current proposed stack:

### Patient App

Flutter

### Simple games

Flame / Flutter

### Advanced game if needed

Phaser or Godot

### Backend

Python + FastAPI

### Database

PostgreSQL

### Local/offline

SQLite / Hive

### Authentication / notifications

Firebase

### AI / Analytics

Python

### Dashboards

Web frontend using the technology most appropriate to the existing project architecture

Do not introduce unnecessary technologies without a reason.

---

# 19. DEVELOPMENT PHILOSOPHY

We do NOT want:

> Six people building six disconnected projects.

We want:

> One product, six owners, one architecture.

There will be:

## ONE MASTER ROADMAP

Approximately 30 development/product sprints.

The sprints are shared across the entire team.

A sprint can have:

* one primary owner
* multiple collaborators
* dependencies
* deliverables
* integration requirements
* testing requirements

Example:

### Reveal Match Sprint

Shanks:
→ game implementation

Ruthika:
→ metrics

Pranav:
→ API + analytics integration

Maharshitha:
→ UI/assets

Kovid:
→ testing

Aryan:
→ product/demo story

One sprint, multiple contributors.

---

# 20. DEVELOPMENT TOOLING

We plan to use:

### Discord

Communication and daily coordination.

### GitHub

Actual source code, branches, pull requests and integration.

### Figma

UI/UX.

### Shared documentation

Product requirements, architecture, API, research, analytics.

### AI tools

Used by each person for their own work.

Do NOT make Discord the source of truth for code.

Do NOT rely on one ChatGPT/Claude conversation for the entire team.

---

# 21. MASTER PROJECT CONTEXT

We want a shared document such as:

`PS003_MASTER_CONTEXT.md`

This should contain:

* Problem Statement
* Product requirements
* Architecture
* Tech stack
* Folder structure
* Database schema
* API contracts
* Game event schema
* AI/analytics model
* UI rules
* Current sprint
* Completed work
* Known bugs
* Integration rules

Every team member can provide the relevant portions of this context to their AI assistant.

This prevents different AI tools from inventing incompatible architectures.

---

# 22. AI USAGE

Different members have different AI tools.

### Pranav

Claude Pro

Use for:

* architecture
* backend
* AI
* integration
* code review
* debugging

### Shanks

Gemini Pro

Use for:

* Flutter
* frontend
* game coding
* debugging

### Maharshitha

Gemini Pro

Use for:

* UI/UX
* frontend components
* visual design
* Figma assistance

### Ruthika

Gemini Pro if confirmed

Use for:

* analytics
* backend support
* research
* recommendation logic

### Aryan

ChatGPT Plus

Use for:

* pitch
* storytelling
* judge questions
* research synthesis
* product explanation

### Kovid

Available AI subscription tools

Use for:

* research
* papers
* competitor analysis
* QA
* documentation

IMPORTANT:

Everyone's AI should work from the SAME architecture/context.

Do NOT allow six AI assistants to independently invent six different architectures.

---

# 23. GITHUB WORKFLOW

Nobody directly pushes to `main`.

Suggested:

```text
main
│
└── develop
      │
      ├── feature/patient-home
      ├── feature/reveal-match
      ├── feature/game-events
      ├── feature/performance
      ├── feature/recommendation
      ├── feature/caregiver-dashboard
      └── feature/offline-sync
```

Workflow:

```text
Task
 ↓
Feature branch
 ↓
Code
 ↓
Test
 ↓
Pull Request
 ↓
Review
 ↓
Merge
 ↓
Integration
 ↓
QA
```

Pranav controls final integration.

Shanks reviews frontend contributions.

Pranav reviews backend/AI contributions.

Kovid coordinates manual QA.

---

# 24. DEFINITION OF DONE

A feature is NOT complete merely because the code works locally.

A feature is complete when:

```text
Code
 ↓
Tested
 ↓
Documented
 ↓
Committed
 ↓
Pull Request
 ↓
Reviewed
 ↓
Merged
 ↓
Integrated
 ↓
End-to-end tested
```

For example, Reveal Match is not "done" until:

* game works
* events are emitted
* metrics are calculated
* backend receives them
* database stores them
* analytics processes them
* recommendation is generated
* patient receives the next recommendation
* caregiver can see the result
* QA has tested it

---

# 25. OUR SEPTEMBER 5–8 DEVELOPMENT PLAN

We have September 5–8 for the main development push.

September 9–10 will be our internal hackathon and will be used primarily for upgrades, additional features and polishing.

Therefore:

# SEP 5

## FOUNDATION

Goals:

* product requirements
* clinical research
* architecture
* database
* API contracts
* GitHub setup
* Flutter setup
* UI/UX system
* game analytics specification

---

# SEP 6

## CORE IMPLEMENTATION

Goals:

* backend skeleton
* patient APIs
* Flutter foundation
* patient home
* Reveal Match v1
* game event schema
* performance calculator
* caregiver dashboard foundation

---

# SEP 7

## AI + FIRST FULL INTEGRATION

Goals:

```text
Patient
 ↓
Game
 ↓
Game Data
 ↓
Backend
 ↓
Analytics
 ↓
AI Recommendation
 ↓
Caregiver Dashboard
```

Also build the first version of:

**Personalized Word Search**

---

# SEP 8

## STABILIZATION + DEMO FREEZE

No major new features.

Focus on:

* integration
* bugs
* testing
* UI polish
* API fixes
* AI validation
* demo flow
* PPT alignment
* deployment

At the end of September 8:

# FEATURE FREEZE

Anything additional becomes the September 9–10 upgrade backlog.

---

# 26. SEPTEMBER 9–10

These are NOT part of the core September 5–8 plan.

They are upgrade days.

Possible priorities:

### P0

* Offline sync
* Memory Quest
* Marble Maze
* better caregiver dashboard

### P1

* Spot Difference
* Trace
* Daily Routine Recall
* Voice assistance

### P2

* Coloring
* Picture Recall
* more languages
* advanced recommendation model

The exact priorities will be decided after the Sep 8 working MVP is evaluated.

---

# 27. HOW I WANT YOU TO HELP US

When I give you a sprint:

1. Explain the sprint.
2. Explain exactly what each team member should do.
3. Divide the sprint into concrete tasks.
4. Give each person an expected deliverable.
5. Identify dependencies.
6. Identify which files/modules they should touch.
7. Explain how their work connects to other members.
8. Provide AI prompts for the relevant team member when useful.
9. Explain Git/GitHub workflow.
10. Explain how the completed work gets integrated.
11. Provide testing criteria.
12. Provide a definition of done.
13. Identify what should NOT be changed.
14. Keep the architecture consistent with the master context.

When giving coding tasks, do not simply say:

> "Build the backend."

Instead give precise tasks such as:

> Create `POST /game/session`, define request/response schemas, persist the session, return `session_id`, write tests, and document the endpoint.

---

# 28. HOW WE WANT TEAM COMMUNICATION TO WORK

Discord channels may include:

```text
#announcements
#daily-sprint
#frontend
#backend
#ai-analytics
#games
#research
#ui-ux
#testing
#ppt-pitch
#integration
```

Do not create dozens of unnecessary channels.

Every daily sprint should have:

```text
SPRINT:
OBJECTIVE:

PRANAV:
-

SHANKS:
-

MAHARSHITHA:
-

RUTHIKA:
-

KOVID:
-

ARYAN:
-

INTEGRATION TARGET:
-

DEFINITION OF DONE:
-
```

Each team member reports:

```text
DONE:
-

IN PROGRESS:
-

BLOCKED:
-

NEED FROM:
-

BRANCH/PR:
-
```

If blocked for more than approximately 30 minutes, they should ask in Discord instead of silently wasting hours.

---

# 29. VERY IMPORTANT MANAGEMENT PRINCIPLE

Pranav should NOT become the bottleneck.

He should:

* define architecture
* define contracts
* assign work
* review important code
* own backend/AI
* perform integration

But other people must independently deliver their modules.

The purpose of the team structure is:

> **Parallel development with controlled integration.**

Not:

> Everyone waits for Pranav.

---

# 30. FIRST VERTICAL SLICE

Our most important milestone is:

```text
Caregiver creates patient
        ↓
Select dementia type/stage
        ↓
Enter 15–20 personal words
        ↓
Patient opens app
        ↓
Baseline / Reveal Match
        ↓
Gameplay data captured
        ↓
Backend stores data
        ↓
Analytics processes data
        ↓
AI generates recommendation
        ↓
Caregiver sees performance
        ↓
Patient receives next recommended activity
```

If this works end-to-end, we consider the core architecture proven.

Only after this works should we aggressively expand the number of games.

---

# 31. WHAT WE SHOULD NOT DO

Do NOT encourage us to waste the initial development window on:

* nine unfinished games
* unnecessarily complicated ML
* AR/VR
* huge 3D environments
* excessive animations
* perfect voice AI for every regional language
* complicated medical diagnosis
* overly complex doctor dashboards
* unnecessary microservices
* excessive authentication complexity
* features that are not necessary for the first working loop

We prefer:

> **One excellent integrated vertical slice over many disconnected features.**

---

# 32. YOUR ROLE WITH OUR TEAM

Treat this project as if you are our technical project manager and senior engineer working alongside us.

When we ask:

> “What should Shanks do today?”

Give Shanks concrete frontend/game tasks.

When we ask:

> “What should Ruthika do?”

Give her bounded backend/analytics/research tasks appropriate to her current skill level.

When we ask:

> “What should Kovid do?”

Give him meaningful research/QA/documentation work rather than coding.

When we ask:

> “How should Pranav integrate this?”

Give exact integration instructions.

When we ask:

> “How do we use Claude/Gemini/ChatGPT for this?”

Create a prompt specifically for that team member and their assigned task, while preserving our master architecture.

When we ask:

> “What do we do next?”

Look at our current sprint status and dependencies and tell us the highest-priority next action.

Do NOT randomly redesign the project every time we ask a question.

Maintain continuity with this architecture.

---

# FINAL PRINCIPLE

Our project should work like this:

**Six people.**

**One architecture.**

**One GitHub repository.**

**One master context.**

**One master sprint roadmap.**

**Parallel work.**

**Controlled integration.**

**AI-assisted development.**

**Human-reviewed recommendations.**

**One working product.**

The ultimate goal is not to have six people say:

> “I finished my part.”

The goal is for the team to say:

> **“Our parts work together.”**
