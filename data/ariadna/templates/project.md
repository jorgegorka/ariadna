# PROJECT.md Template

Template for `.ariadna_planning/PROJECT.md` — the living project context document.

<template>

```markdown
# [Project Name]

## What This Is

[Current accurate description — 2-3 sentences. What does this product do and who is it for?
Use the user's language and framing. Update whenever reality drifts from this description.]

## Core Value

[The ONE thing that matters most. If everything else fails, this must work.
One sentence that drives prioritization when tradeoffs arise.]

## Who This Serves

[Who uses this and what they care about. Not formal personas — just enough
that downstream planning knows whose problem each feature solves.

Examples:
- **Solo creator** — Wants to publish without fighting tools. Cares about speed, not features.
- **Small team lead** — Needs visibility into what everyone's doing. Frustrated by status meetings.

If it's just you, say so: "Me — I want X because Y."]

## Product Vision

- **Success means:** [The outcome that justifies the effort — "teams stop using spreadsheets", "I can charge $X/month", "my workflow drops from 2 hours to 10 minutes"]
- **Bigger picture:** [Is this standalone? Part of a platform? An experiment? A business?]
- **Not optimizing for:** [What you're deliberately NOT chasing — growth, scale, polish, monetization, etc.]

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — ship to validate)

### Active

<!-- Current scope. Building toward these. -->

- [ ] [Requirement 1]
- [ ] [Requirement 2]
- [ ] [Requirement 3]

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- [Exclusion 1] — [why]
- [Exclusion 2] — [why]

## Context

[Background information that informs implementation:
- Technical environment or ecosystem
- Relevant prior work or experience
- User research or feedback themes
- Known issues to address]

## Constraints

- **[Type]**: [What] — [Why]
- **[Type]**: [What] — [Why]

Common types: Tech stack, Timeline, Budget, Dependencies, Compatibility, Performance, Security

## Key Decisions

<!-- Decisions that constrain future work. Add throughout project lifecycle. -->

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| [Choice] | [Why] | [✓ Good / ⚠️ Revisit / — Pending] |

---
*Last updated: [date] after [trigger]*
```

</template>

<guidelines>

**What This Is:**
- Current accurate description of the product
- 2-3 sentences capturing what it does and who it's for
- Use the user's words and framing
- Update when the product evolves beyond this description

**Core Value:**
- The single most important thing
- Everything else can fail; this cannot
- Drives prioritization when tradeoffs arise
- Rarely changes; if it does, it's a significant pivot

**Who This Serves:**
- Informal user descriptions, not enterprise personas
- Focus on what they care about and what frustrates them
- "Me" is a valid answer if building for yourself
- Drives feature prioritization: which user does this feature serve?
- Updated when you learn more about actual users

**Product Vision:**
- The "why build this" beyond individual features
- Success means: measurable or observable outcome that justifies the work
- Bigger picture: product direction, not a detailed roadmap
- Not optimizing for: explicit de-priorities that prevent scope creep
- Rarely changes; if it does, revisit roadmap structure

**Requirements — Validated:**
- Requirements that shipped and proved valuable
- Format: `- ✓ [Requirement] — [version/phase]`
- These are locked — changing them requires explicit discussion

**Requirements — Active:**
- Current scope being built toward
- These are hypotheses until shipped and validated
- Move to Validated when shipped, Out of Scope if invalidated

**Requirements — Out of Scope:**
- Explicit boundaries on what we're not building
- Always include reasoning (prevents re-adding later)
- Includes: considered and rejected, deferred to future, explicitly excluded

**Context:**
- Background that informs implementation decisions
- Technical environment, prior work, user feedback
- Known issues or technical debt to address
- Update as new context emerges

**Constraints:**
- Hard limits on implementation choices
- Tech stack, timeline, budget, compatibility, dependencies
- Include the "why" — constraints without rationale get questioned

**Key Decisions:**
- Significant choices that affect future work
- Add decisions as they're made throughout the project
- Track outcome when known:
  - ✓ Good — decision proved correct
  - ⚠️ Revisit — decision may need reconsideration
  - — Pending — too early to evaluate

**Last Updated:**
- Always note when and why the document was updated
- Format: `after Phase 2` or `after v1.0 milestone`
- Triggers review of whether content is still accurate

</guidelines>

<evolution>

PROJECT.md evolves throughout the project lifecycle.

**After each phase transition:**
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone:**
1. Full review of all sections
2. Core Value check — still the right priority?
3. Who This Serves still accurate? → Update with real user feedback
4. Product Vision success criteria met? → Celebrate or revisit
5. Audit Out of Scope — reasons still valid?
6. Update Context with current state (users, feedback, metrics)

</evolution>

<brownfield>

For existing codebases:

1. **Map codebase first** via `/ariadna:map-codebase`

2. **Infer Validated requirements** from existing code:
   - What does the codebase actually do?
   - What patterns are established?
   - What's clearly working and relied upon?

3. **Gather Active requirements** from user:
   - Present inferred current state
   - Ask what they want to build next

4. **Initialize:**
   - Validated = inferred from existing code
   - Active = user's goals for this work
   - Out of Scope = boundaries user specifies
   - Context = includes current codebase state

</brownfield>

<state_reference>

STATE.md references PROJECT.md:

```markdown
## Project Reference

See: .ariadna_planning/PROJECT.md (updated [date])

**Core value:** [One-liner from Core Value section]
**Current focus:** [Current phase name]
```

This ensures Claude reads current PROJECT.md context.

</state_reference>
