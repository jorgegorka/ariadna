# Features Research Template

Template for `.planning/research/FEATURES.md` — feature landscape for the project domain.

<template>

```markdown
# Feature Research

**Domain:** [domain type]
**Researched:** [date]
**Confidence:** [HIGH/MEDIUM/LOW]

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Rails Approach | Notes |
|---------|--------------|------------|----------------|-------|
| [feature] | [user expectation] | LOW/MEDIUM/HIGH | [e.g., Rails authentication generator, Action Cable, Active Storage, Turbo Streams, background job, standard CRUD] | [implementation notes] |
| [feature] | [user expectation] | LOW/MEDIUM/HIGH | [Rails approach] | [implementation notes] |
| [feature] | [user expectation] | LOW/MEDIUM/HIGH | [Rails approach] | [implementation notes] |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Rails Approach | Notes |
|---------|-------------------|------------|----------------|-------|
| [feature] | [why it matters] | LOW/MEDIUM/HIGH | [Rails approach] | [implementation notes] |
| [feature] | [why it matters] | LOW/MEDIUM/HIGH | [Rails approach] | [implementation notes] |
| [feature] | [why it matters] | LOW/MEDIUM/HIGH | [Rails approach] | [implementation notes] |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| [feature] | [surface appeal] | [actual problems] | [better approach] |
| [feature] | [surface appeal] | [actual problems] | [better approach] |

## Feature Dependencies

```
[Feature A]
    └──requires──> [Model/Concern B]
                       └──requires──> [Migration C]

[Feature D] ──enhances──> [Feature A via Turbo interaction]

[Feature E] ──conflicts──> [Feature F]
```

### Dependency Notes

- **[Feature A] requires [Model/Concern B]:** [why — e.g., needs polymorphic association, shared validation concern, new database table]
- **[Feature D] enhances [Feature A]:** [how they work together — e.g., Turbo Frame wrapping, Stimulus controller coordination]
- **[Feature E] conflicts with [Feature F]:** [why they're incompatible — e.g., competing authorization strategies, conflicting callback chains]

### Rails Infrastructure Needs

For each major feature, note which Rails subsystems are involved:

| Feature | Real-Time (Action Cable / Turbo Streams) | Background Jobs | File Handling (Active Storage) | Search | Auth Changes |
|---------|------------------------------------------|-----------------|-------------------------------|--------|--------------|
| [feature] | YES/NO | YES/NO | YES/NO | YES/NO | YES/NO |
| [feature] | YES/NO | YES/NO | YES/NO | YES/NO | YES/NO |
| [feature] | YES/NO | YES/NO | YES/NO | YES/NO | YES/NO |

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed to validate the concept.

- [ ] [Feature] — [why essential]
- [ ] [Feature] — [why essential]
- [ ] [Feature] — [why essential]

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] [Feature] — [trigger for adding]
- [ ] [Feature] — [trigger for adding]

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] [Feature] — [why defer]
- [ ] [Feature] — [why defer]

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| [feature] | HIGH/MEDIUM/LOW | HIGH/MEDIUM/LOW | P1/P2/P3 |
| [feature] | HIGH/MEDIUM/LOW | HIGH/MEDIUM/LOW | P1/P2/P3 |
| [feature] | HIGH/MEDIUM/LOW | HIGH/MEDIUM/LOW | P1/P2/P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Competitor A | Competitor B | Our Approach |
|---------|--------------|--------------|--------------|
| [feature] | [how they do it] | [how they do it] | [our plan] |
| [feature] | [how they do it] | [how they do it] | [our plan] |

## Sources

- [Competitor products analyzed]
- [User research or feedback sources]
- [Industry standards referenced]

---
*Feature research for: [domain]*
*Researched: [date]*
```

</template>

<guidelines>

**Table Stakes:**
- These are non-negotiable for launch
- Users don't give credit for having them, but penalize for missing them
- Example: A Rails SaaS app without password reset or session management is broken

**Differentiators:**
- These are where you compete
- Should align with the Core Value from PROJECT.md
- Don't try to differentiate on everything

**Anti-Features:**
- Prevent scope creep by documenting what seems good but isn't
- Include the alternative approach
- Example: "Real-time updates via Action Cable for everything" when Turbo Frame lazy loading or simple polling suffices
- Example: "Extract into microservices" when the Rails monolith handles the load fine
- Example: "Build a custom admin panel" when a gem like Administrate or Avo covers the need

**Feature Dependencies:**
- Critical for roadmap phase ordering
- If A requires B, B must be in an earlier phase
- Conflicts inform what NOT to combine in same phase
- Note migrations and concerns that multiple features share — build those first
- Turbo Frame and Stimulus controller dependencies affect frontend delivery order

**Rails Infrastructure Needs:**
- Identifying subsystem needs early avoids mid-phase yak shaving
- Features needing Action Cable or Turbo Streams use Solid Cable (database-backed, no Redis needed in Rails 8)
- Features needing Active Storage require storage service setup (local, S3, etc.)
- Features needing background jobs require queue adapter setup (Solid Queue is Rails 8 default, Sidekiq for high-throughput needs)
- Features needing search may require an external service (Elasticsearch, Meilisearch) or pg_search

**MVP Definition:**
- Be ruthless about what's truly minimum
- "Nice to have" is not MVP
- Launch with less, validate, then expand

</guidelines>
