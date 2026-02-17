<purpose>
Create executable phase prompts (PLAN.md files) for a roadmap phase. Default flow: Context (inline if needed) -> Plan -> Verify -> Done. Orchestrates ariadna-planner and ariadna-plan-checker agents. Research skipped by default (Rails conventions pre-loaded); use --research to force research for non-standard integrations.
</purpose>

<required_reading>
Read all files referenced by the invoking prompt's execution_context before starting.

@~/.claude/ariadna/references/ui-brand.md
@~/.claude/ariadna/references/rails-conventions.md
</required_reading>

<process>

## 1. Initialize

Load all context in one call (include file contents to avoid redundant reads):

```bash
INIT=$(ariadna-tools init plan-phase "$PHASE" --include state,roadmap,requirements,context,research,verification,uat)
```

Parse JSON for: `researcher_model`, `planner_model`, `checker_model`, `research_enabled`, `plan_checker_enabled`, `commit_docs`, `phase_found`, `phase_dir`, `phase_number`, `phase_name`, `phase_slug`, `padded_phase`, `has_research`, `has_context`, `has_plans`, `plan_count`, `planning_exists`, `roadmap_exists`.

**File contents (from --include):** `state_content`, `roadmap_content`, `requirements_content`, `context_content`, `research_content`, `verification_content`, `uat_content`. These are null if files don't exist.

**If `planning_exists` is false:** Error — run `/ariadna:new-project` first.

## 2. Parse and Normalize Arguments

Extract from $ARGUMENTS: phase number (integer or decimal like `2.1`), flags (`--research`, `--skip-research`, `--gaps`, `--skip-verify`, `--skip-context`).

**If no phase number:** Detect next unplanned phase from roadmap.

**If `phase_found` is false:** Validate phase exists in ROADMAP.md. If valid, create the directory using `phase_slug` and `padded_phase` from init:
```bash
mkdir -p ".planning/phases/${padded_phase}-${phase_slug}"
```

**Existing artifacts from init:** `has_research`, `has_plans`, `plan_count`.

## 3. Validate Phase

```bash
PHASE_INFO=$(ariadna-tools roadmap get-phase "${PHASE}")
```

**If `found` is false:** Error with available phases. **If `found` is true:** Extract `phase_number`, `phase_name`, `goal` from JSON.

## 4. Inline Context Gathering (Replaces discuss-phase)

Use `context_content` from init JSON (already loaded via `--include context`).

**If `context_content` is not null:** Display: `Using phase context from: ${PHASE_DIR}/*-CONTEXT.md` and skip to step 5.

**If `context_content` is null AND no `--skip-context` flag:**

Analyze the phase goal from `roadmap_content` and determine if there are implementation decisions the user should weigh in on.

**Quick assessment — does this phase need context?**

- Pure infrastructure / setup / configuration → No context needed, skip
- Standard CRUD (models, controllers, views) → No context needed, skip
- User-facing features with UI/UX decisions → Context helpful
- Features with multiple valid approaches → Context helpful

**If context would be helpful:** Offer inline clarification with a single AskUserQuestion:

```
questions: [
  {
    header: "Context",
    question: "Phase {X}: {Name} has some implementation choices. Want to discuss them before planning?",
    multiSelect: false,
    options: [
      { label: "Plan directly (Recommended)", description: "Planner will make reasonable choices, you review the plan" },
      { label: "Quick discussion", description: "Clarify 2-3 key decisions inline" },
      { label: "Full discussion", description: "Run /ariadna:discuss-phase for detailed context gathering" }
    ]
  }
]
```

- **"Plan directly":** Continue to step 5. Planner will use its judgment for ambiguous areas.
- **"Quick discussion":** Identify 2-3 key gray areas and ask focused AskUserQuestion for each. Write a lightweight CONTEXT.md to the phase directory. Then continue to step 5.
- **"Full discussion":** Exit and tell user to run `/ariadna:discuss-phase {X}` first, then return.

**CRITICAL:** Use `context_content` from INIT — pass to planner and checker agents.

## 5. Handle Research

**Default: Skip research.** Rails conventions are pre-loaded via `rails-conventions.md`.

**Skip if:** `--gaps` flag, or `research_enabled` is false (default) without `--research` override.

**If `has_research` is true (from init) AND no `--research` flag:** Use existing, skip to step 6.

**If `--research` flag explicitly passed:**

Display banner:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Ariadna ► RESEARCHING PHASE {X}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Spawning researcher...
```

### Spawn ariadna-phase-researcher

```bash
PHASE_DESC=$(ariadna-tools roadmap get-phase "${PHASE}" | jq -r '.section')
# Use requirements_content from INIT (already loaded via --include requirements)
REQUIREMENTS=$(echo "$INIT" | jq -r '.requirements_content // empty' | grep -A100 "## Requirements" | head -50)
STATE_SNAP=$(ariadna-tools state-snapshot)
# Extract decisions from state-snapshot JSON: jq '.decisions[] | "\(.phase): \(.summary) - \(.rationale)"'
```

Research prompt:

```markdown
<objective>
Research how to implement Phase {phase_number}: {phase_name}
Answer: "What do I need to know to PLAN this phase well?"
</objective>

<phase_context>
IMPORTANT: If CONTEXT.md exists below, it contains user decisions from /ariadna:discuss-phase.
- **Decisions** = Locked — research THESE deeply, no alternatives
- **Claude's Discretion** = Freedom areas — research options, recommend
- **Deferred Ideas** = Out of scope — ignore

{context_content}
</phase_context>

<additional_context>
**Phase description:** {phase_description}
**Requirements:** {requirements}
**Prior decisions:** {decisions}
</additional_context>

<output>
Write to: {phase_dir}/{phase}-RESEARCH.md
</output>
```

```
Task(
  prompt="First, read ~/.claude/agents/ariadna-phase-researcher.md for your role and instructions.\n\n" + research_prompt,
  subagent_type="general-purpose",
  model="{researcher_model}",
  description="Research Phase {phase}"
)
```

### Handle Researcher Return

- **`## RESEARCH COMPLETE`:** Display confirmation, continue to step 6
- **`## RESEARCH BLOCKED`:** Display blocker, offer: 1) Provide context, 2) Skip research, 3) Abort

## 6. Check Existing Plans

```bash
ls "${PHASE_DIR}"/*-PLAN.md 2>/dev/null
```

**If exists:** Offer: 1) Add more plans, 2) View existing, 3) Replan from scratch.

## 7. Use Context Files from INIT

All file contents are already loaded via `--include` in step 1 (`@` syntax doesn't work across Task() boundaries):

```bash
# Extract from INIT JSON (no need to re-read files)
STATE_CONTENT=$(echo "$INIT" | jq -r '.state_content // empty')
ROADMAP_CONTENT=$(echo "$INIT" | jq -r '.roadmap_content // empty')
REQUIREMENTS_CONTENT=$(echo "$INIT" | jq -r '.requirements_content // empty')
RESEARCH_CONTENT=$(echo "$INIT" | jq -r '.research_content // empty')
VERIFICATION_CONTENT=$(echo "$INIT" | jq -r '.verification_content // empty')
UAT_CONTENT=$(echo "$INIT" | jq -r '.uat_content // empty')
CONTEXT_CONTENT=$(echo "$INIT" | jq -r '.context_content // empty')
```

## 8. Spawn ariadna-planner Agent

Display banner:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Ariadna ► PLANNING PHASE {X}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Spawning planner...
```

Planner prompt:

```markdown
<planning_context>
**Phase:** {phase_number}
**Mode:** {standard | gap_closure}

**Project State:** {state_content}
**Roadmap:** {roadmap_content}
**Requirements:** {requirements_content}

**Phase Context:**
IMPORTANT: If context exists below, it contains USER DECISIONS from /ariadna:discuss-phase.
- **Decisions** = LOCKED — honor exactly, do not revisit
- **Claude's Discretion** = Freedom — make implementation choices
- **Deferred Ideas** = Out of scope — do NOT include

{context_content}

**Research:** {research_content}
**Gap Closure (if --gaps):** {verification_content} {uat_content}
</planning_context>

<rails_context>
Use Rails conventions from your required reading (rails-conventions.md) for:
- Standard task decomposition patterns (model → migration+model+tests, controller → routes+controller+views+tests)
- Known domain detection (skip discovery for standard Rails work)
- Architecture patterns (MVC, concerns, service objects)
- Common pitfall prevention (N+1, mass assignment, fat controllers)
</rails_context>

<downstream_consumer>
Output consumed by /ariadna:execute-phase. Plans need:
- Frontmatter (wave, depends_on, files_modified, autonomous)
- Tasks in XML format
- Verification criteria
- must_haves for goal-backward verification
</downstream_consumer>

<quality_gate>
- [ ] PLAN.md files created in phase directory
- [ ] Each plan has valid frontmatter
- [ ] Tasks are specific and actionable
- [ ] Dependencies correctly identified
- [ ] Waves assigned for parallel execution
- [ ] must_haves derived from phase goal
</quality_gate>
```

```
Task(
  prompt="First, read ~/.claude/agents/ariadna-planner.md for your role and instructions.\n\n" + filled_prompt,
  subagent_type="general-purpose",
  model="{planner_model}",
  description="Plan Phase {phase}"
)
```

## 9. Handle Planner Return

- **`## PLANNING COMPLETE`:** Display plan count. If `--skip-verify` or `plan_checker_enabled` is false (from init): skip to step 13. Otherwise: step 10.
- **`## CHECKPOINT REACHED`:** Present to user, get response, spawn continuation (step 12)
- **`## PLANNING INCONCLUSIVE`:** Show attempts, offer: Add context / Retry / Manual

## 10. Spawn ariadna-plan-checker Agent

Display banner:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Ariadna ► VERIFYING PLANS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Spawning plan checker...
```

```bash
PLANS_CONTENT=$(cat "${PHASE_DIR}"/*-PLAN.md 2>/dev/null)
```

Checker prompt:

```markdown
<verification_context>
**Phase:** {phase_number}
**Phase Goal:** {goal from ROADMAP}

**Plans to verify:** {plans_content}
**Requirements:** {requirements_content}

**Phase Context:**
IMPORTANT: Plans MUST honor user decisions. Flag as issue if plans contradict.
- **Decisions** = LOCKED — plans must implement exactly
- **Claude's Discretion** = Freedom areas — plans can choose approach
- **Deferred Ideas** = Out of scope — plans must NOT include

{context_content}
</verification_context>

<expected_output>
- ## VERIFICATION PASSED — all checks pass
- ## ISSUES FOUND — structured issue list with severity (minor/major/blocker)
</expected_output>
```

```
Task(
  prompt=checker_prompt,
  subagent_type="ariadna-plan-checker",
  model="{checker_model}",
  description="Verify Phase {phase} plans"
)
```

## 11. Handle Checker Return

- **`## VERIFICATION PASSED`:** Display confirmation, proceed to step 13.
- **`## ISSUES FOUND`:** Classify issues and proceed to step 12.

## 12. Handle Checker Issues (Inline Fix, No Revision Loop)

**Classify each issue by severity:**

### Minor Issues (orchestrator fixes inline)
Issues the orchestrator can fix directly with the Edit tool — no agent re-spawn needed:
- Missing requirement mapping in frontmatter
- Dependency ordering errors (wrong wave number)
- Missing `<verify>` or `<done>` elements in tasks
- Frontmatter field corrections
- must_haves adjustments

**For minor issues:** Fix the PLAN.md files directly using the Edit tool:
```
Read the PLAN.md file, apply the fix, write it back.
```

Display: `Fixed {N} minor issue(s) inline.`

### Major Issues (present to user)
Issues that require architectural decisions or significant plan restructuring:
- Missing requirements with no clear task mapping
- Incorrect decomposition (tasks too large or wrong scope)
- Contradictions with user decisions from CONTEXT.md
- Scope creep (tasks implementing deferred ideas)

**For major issues:** Present to user with AskUserQuestion:
```
questions: [
  {
    header: "Plan Issues",
    question: "The plan checker found {N} issue(s) that need your input. How to proceed?",
    multiSelect: false,
    options: [
      { label: "Accept as-is", description: "Proceed despite issues" },
      { label: "Re-plan", description: "Spawn planner again with issue context" },
      { label: "Fix manually", description: "I'll edit the PLAN.md files myself" }
    ]
  }
]
```

- **"Accept as-is":** Proceed to step 13.
- **"Re-plan":** Spawn planner in revision mode (single attempt, not a loop):

```
Task(
  prompt="First, read ~/.claude/agents/ariadna-planner.md for your role and instructions.\n\n" + revision_prompt_with_issues,
  subagent_type="general-purpose",
  model="{planner_model}",
  description="Revise Phase {phase} plans"
)
```

After planner returns, proceed to step 13 (no re-check loop).

- **"Fix manually":** Display file paths and exit.

## 13. Present Final Status

Route to `<offer_next>`.

</process>

<offer_next>
Output this markdown directly (not as a code block):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Ariadna ► PHASE {X} PLANNED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Phase {X}: {Name}** — {N} plan(s) in {M} wave(s)

| Wave | Plans | What it builds |
|------|-------|----------------|
| 1    | 01, 02 | [objectives] |
| 2    | 03     | [objective]  |

Context: {Gathered inline | Used existing | Skipped}
Research: {Completed | Used existing | Skipped (Rails conventions loaded)}
Verification: {Passed | Passed with fixes | Skipped}

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Execute Phase {X}** — run all {N} plans

/ariadna:execute-phase {X}

<sub>/clear first → fresh context window</sub>

───────────────────────────────────────────────────────────────

**Also available:**
- cat .planning/phases/{phase-dir}/*-PLAN.md — review plans
- /ariadna:plan-phase {X} --research — re-research first

───────────────────────────────────────────────────────────────
</offer_next>

<success_criteria>
- [ ] .planning/ directory validated
- [ ] Phase validated against roadmap
- [ ] Phase directory created if needed
- [ ] Context handled: existing CONTEXT.md used, inline gathering offered, or skipped
- [ ] Research skipped by default (Rails conventions in context), or completed if --research flag
- [ ] Existing plans checked
- [ ] ariadna-planner spawned with rails-conventions + any CONTEXT.md + RESEARCH.md
- [ ] Plans created (PLANNING COMPLETE or CHECKPOINT handled)
- [ ] ariadna-plan-checker spawned (unless --skip-verify)
- [ ] Minor checker issues fixed inline by orchestrator (no revision loop)
- [ ] Major checker issues presented to user for decision
- [ ] User sees status between agent spawns
- [ ] User knows next steps
</success_criteria>
