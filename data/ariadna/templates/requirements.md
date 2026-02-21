# Requirements Template

Template for `.ariadna_planning/REQUIREMENTS.md` — checkable requirements that define "done."

<template>

```markdown
# Requirements: [Project Name]

**Defined:** [date]
**Core Value:** [from PROJECT.md]

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Authentication

- [ ] **AUTH-01**: User can sign up with email and password — *enables personalized experience*
- [ ] **AUTH-02**: User receives email verification after signup — *prevents spam accounts*
- [ ] **AUTH-03**: User can reset password via email link — *reduces support burden*
- [ ] **AUTH-04**: User session persists across browser refresh — *removes friction from daily use*

### [Category 2]

- [ ] **[CAT]-01**: [Requirement description] — *[why this matters]*
- [ ] **[CAT]-02**: [Requirement description] — *[why this matters]*
- [ ] **[CAT]-03**: [Requirement description] — *[why this matters]*

### [Category 3]

- [ ] **[CAT]-01**: [Requirement description] — *[why this matters]*
- [ ] **[CAT]-02**: [Requirement description] — *[why this matters]*

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### [Category]

- **[CAT]-01**: [Requirement description]
- **[CAT]-02**: [Requirement description]

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| [Feature] | [Why excluded] |
| [Feature] | [Why excluded] |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 1 | Pending |
| AUTH-02 | Phase 1 | Pending |
| AUTH-03 | Phase 1 | Pending |
| AUTH-04 | Phase 1 | Pending |
| [REQ-ID] | Phase [N] | Pending |

**Coverage:**
- v1 requirements: [X] total
- Mapped to phases: [Y]
- Unmapped: [Z] ⚠️

---
*Requirements defined: [date]*
*Last updated: [date] after [trigger]*
```

</template>

<guidelines>

**Requirement Format:**
- ID: `[CATEGORY]-[NUMBER]` (AUTH-01, CONTENT-02, SOCIAL-03)
- Description: User-centric, testable, atomic
- Motivation: brief "why" clause after em-dash — `— *reason this matters*`
- Checkbox: Only for v1 requirements (v2 are not yet actionable)

**Requirement Motivation:**
- Each requirement gets a brief "why" clause: `— *reason this matters*`
- Connects features to user needs or business goals from Product Vision
- Helps the roadmapper understand WHY requirements cluster, not just WHAT they are
- Helps the verifier check "did we solve the problem?" not just "did we ship the feature?"
- Keep it short: one clause, italicized, after an em-dash
- Draw from Who This Serves and Product Vision in PROJECT.md

**Categories:**
- Derive from research FEATURES.md categories
- Keep consistent with domain conventions
- Typical: Authentication, Content, Social, Notifications, Moderation, Payments, Admin

**v1 vs v2:**
- v1: Committed scope, will be in roadmap phases
- v2: Acknowledged but deferred, not in current roadmap
- Moving v2 → v1 requires roadmap update

**Out of Scope:**
- Explicit exclusions with reasoning
- Prevents "why didn't you include X?" later
- Anti-features from research belong here with warnings

**Traceability:**
- Empty initially, populated during roadmap creation
- Each requirement maps to exactly one phase
- Unmapped requirements = roadmap gap

**Status Values:**
- Pending: Not started
- In Progress: Phase is active
- Complete: Requirement verified
- Blocked: Waiting on external factor

</guidelines>

<evolution>

**After each phase completes:**
1. Mark covered requirements as Complete
2. Update traceability status
3. Note any requirements that changed scope

**After roadmap updates:**
1. Verify all v1 requirements still mapped
2. Add new requirements if scope expanded
3. Move requirements to v2/out of scope if descoped

**Requirement completion criteria:**
- Requirement is "Complete" when:
  - Feature is implemented
  - Feature is verified (tests pass, manual check done)
  - Feature is committed

</evolution>

<example>

```markdown
# Requirements: CommunityApp

**Defined:** 2025-01-14
**Core Value:** Users can share and discuss content with people who share their interests

## v1 Requirements

### Authentication

- [ ] **AUTH-01**: User can sign up with email and password — *enables personalized experience*
- [ ] **AUTH-02**: User receives email verification after signup — *prevents spam accounts*
- [ ] **AUTH-03**: User can reset password via email link — *reduces support burden*
- [ ] **AUTH-04**: User session persists across browser refresh — *removes friction from daily use*

### Profiles

- [ ] **PROF-01**: User can create profile with display name — *gives users identity in the community*
- [ ] **PROF-02**: User can upload avatar image — *makes profiles recognizable*
- [ ] **PROF-03**: User can write bio (max 500 chars) — *enables self-expression and discovery*
- [ ] **PROF-04**: User can view other users' profiles — *supports finding people with shared interests*

### Content

- [ ] **CONT-01**: User can create text post — *core content creation loop*
- [ ] **CONT-02**: User can upload image with post — *richer content drives engagement*
- [ ] **CONT-03**: User can edit own posts — *reduces friction of sharing (can fix mistakes)*
- [ ] **CONT-04**: User can delete own posts — *user controls their own content*
- [ ] **CONT-05**: User can view feed of posts — *content consumption is the primary activity*

### Social

- [ ] **SOCL-01**: User can follow other users — *builds the social graph that makes the feed work*
- [ ] **SOCL-02**: User can unfollow users — *user controls their experience*
- [ ] **SOCL-03**: User can like posts — *lightweight engagement signal*
- [ ] **SOCL-04**: User can comment on posts — *discussion is core to community value*
- [ ] **SOCL-05**: User can view activity feed (followed users' posts) — *personalized content keeps users returning*

## v2 Requirements

### Notifications

- **NOTF-01**: User receives in-app notifications
- **NOTF-02**: User receives email for new followers
- **NOTF-03**: User receives email for comments on own posts
- **NOTF-04**: User can configure notification preferences

### Moderation

- **MODR-01**: User can report content
- **MODR-02**: User can block other users
- **MODR-03**: Admin can view reported content
- **MODR-04**: Admin can remove content
- **MODR-05**: Admin can ban users

## Out of Scope

| Feature | Reason |
|---------|--------|
| Real-time chat | High complexity, not core to community value |
| Video posts | Storage/bandwidth costs, defer to v2+ |
| OAuth login | Email/password sufficient for v1 |
| Mobile app | Web-first, mobile later |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 1 | Pending |
| AUTH-02 | Phase 1 | Pending |
| AUTH-03 | Phase 1 | Pending |
| AUTH-04 | Phase 1 | Pending |
| PROF-01 | Phase 2 | Pending |
| PROF-02 | Phase 2 | Pending |
| PROF-03 | Phase 2 | Pending |
| PROF-04 | Phase 2 | Pending |
| CONT-01 | Phase 3 | Pending |
| CONT-02 | Phase 3 | Pending |
| CONT-03 | Phase 3 | Pending |
| CONT-04 | Phase 3 | Pending |
| CONT-05 | Phase 3 | Pending |
| SOCL-01 | Phase 4 | Pending |
| SOCL-02 | Phase 4 | Pending |
| SOCL-03 | Phase 4 | Pending |
| SOCL-04 | Phase 4 | Pending |
| SOCL-05 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0 ✓

---
*Requirements defined: 2025-01-14*
*Last updated: 2025-01-14 after initial definition*
```

</example>
