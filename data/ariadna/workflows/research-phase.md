<purpose>
Research how to implement a phase. Spawns ariadna-phase-researcher with phase context.

Standalone research command. For most workflows, use `/ariadna:plan-phase` which integrates research automatically.
</purpose>

<process>

## Step 0: Resolve Model Profile

@~/.claude/ariadna/references/model-profile-resolution.md

Resolve model for:
- `ariadna-phase-researcher`

## Step 1: Normalize and Validate Phase

@~/.claude/ariadna/references/phase-argument-parsing.md

```bash
PHASE_INFO=$(ariadna-tools roadmap get-phase "${PHASE}")
```

If `found` is false: Error and exit.

## Step 2: Check Existing Research

```bash
ls .ariadna_planning/phases/${PHASE}-*/RESEARCH.md 2>/dev/null
```

If exists: Offer update/view/skip options.

## Step 3: Gather Phase Context

```bash
# Phase section from roadmap (already loaded in PHASE_INFO)
echo "$PHASE_INFO" | jq -r '.section'
cat .ariadna_planning/REQUIREMENTS.md 2>/dev/null
cat .ariadna_planning/phases/${PHASE}-*/*-CONTEXT.md 2>/dev/null
# Decisions from state-snapshot (structured JSON)
ariadna-tools state-snapshot | jq '.decisions'
```

## Step 4: Spawn Researcher

```
Task(
  prompt="<objective>
Research implementation approach for Phase {phase}: {name}
</objective>

<context>
Phase description: {description}
Requirements: {requirements}
Prior decisions: {decisions}
Phase context: {context_md}
</context>

<output>
Write to: .ariadna_planning/phases/${PHASE}-{slug}/${PHASE}-RESEARCH.md
</output>",
  subagent_type="ariadna-phase-researcher",
  model="{researcher_model}"
)
```

## Step 5: Handle Return

- `## RESEARCH COMPLETE` — Display summary, offer: Plan/Dig deeper/Review/Done
- `## CHECKPOINT REACHED` — Present to user, spawn continuation
- `## RESEARCH INCONCLUSIVE` — Show attempts, offer: Add context/Try different mode/Manual

</process>
