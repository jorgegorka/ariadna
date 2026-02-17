<purpose>
Execute all plans in a phase using wave-based parallel execution. Orchestrator stays lean — delegates plan execution to subagents.
</purpose>

<core_principle>
Orchestrator coordinates, not executes. Each subagent loads the full execute-plan context. Orchestrator: discover plans → analyze deps → group waves → spawn agents → handle checkpoints → collect results.
</core_principle>

<required_reading>
Read STATE.md before any operation to load project context.
</required_reading>

<process>

<step name="initialize" priority="first">
Load all context in one call:

```bash
INIT=$(ariadna-tools init execute-phase "${PHASE_ARG}")
```

Parse JSON for: `executor_model`, `verifier_model`, `commit_docs`, `parallelization`, `branching_strategy`, `branch_name`, `phase_found`, `phase_dir`, `phase_number`, `phase_name`, `phase_slug`, `plans`, `incomplete_plans`, `plan_count`, `incomplete_count`, `state_exists`, `roadmap_exists`.

**If `phase_found` is false:** Error — phase directory not found.
**If `plan_count` is 0:** Error — no plans found in phase.
**If `state_exists` is false but `.planning/` exists:** Offer reconstruct or continue.

When `parallelization` is false, plans within a wave execute sequentially.
</step>

<step name="handle_branching">
Check `branching_strategy` from init:

**"none":** Skip, continue on current branch.

**"phase" or "milestone":** Use pre-computed `branch_name` from init:
```bash
git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME"
```

All subsequent commits go to this branch. User handles merging.
</step>

<step name="validate_phase">
From init JSON: `phase_dir`, `plan_count`, `incomplete_count`.

Report: "Found {plan_count} plans in {phase_dir} ({incomplete_count} incomplete)"
</step>

<step name="discover_and_group_plans">
Load plan inventory with wave grouping in one call:

```bash
PLAN_INDEX=$(ariadna-tools phase-plan-index "${PHASE_NUMBER}")
```

Parse JSON for: `phase`, `plans[]` (each with `id`, `wave`, `autonomous`, `objective`, `files_modified`, `task_count`, `has_summary`), `waves` (map of wave number → plan IDs), `incomplete`, `has_checkpoints`.

**Filtering:** Skip plans where `has_summary: true`. If `--gaps-only`: also skip non-gap_closure plans. If all filtered: "No matching incomplete plans" → exit.

Report:
```
## Execution Plan

**Phase {X}: {Name}** — {total_plans} plans across {wave_count} waves

| Wave | Plans | What it builds |
|------|-------|----------------|
| 1 | 01-01, 01-02 | {from plan objectives, 3-8 words} |
| 2 | 01-03 | ... |
```
</step>

<step name="execute_waves">
Execute each wave in sequence. Within a wave: parallel if `PARALLELIZATION=true`, sequential if `false`.

**For each wave:**

1. **Describe what's being built (BEFORE spawning):**

   Read each plan's `<objective>`. Extract what's being built and why.

   ```
   ---
   ## Wave {N}

   **{Plan ID}: {Plan Name}**
   {2-3 sentences: what this builds, technical approach, why it matters}

   Spawning {count} agent(s)...
   ---
   ```

   - Bad: "Executing terrain generation plan"
   - Good: "Procedural terrain generator using Perlin noise — creates height maps, biome zones, and collision meshes. Required before vehicle physics can interact with ground."

2. **Spawn executor agents:**

   Pass paths only — executors read files themselves with their fresh 200k context.
   This keeps orchestrator context lean (~10-15%).

   **Domain routing:** Read `domain` from each plan's frontmatter to determine which executor to spawn:

   ```bash
   DOMAIN=$(ariadna-tools frontmatter get "{phase_dir}/{plan_file}" --field domain)
   DOMAIN_GUIDE=$(ariadna-tools frontmatter get "{phase_dir}/{plan_file}" --field domain_guide)
   ```

   | Domain | Executor Agent | Guide |
   |--------|---------------|-------|
   | `backend` | `ariadna-backend-executor` | `@~/.claude/guides/backend.md` |
   | `frontend` | `ariadna-frontend-executor` | `@~/.claude/guides/frontend.md` |
   | `testing` | `ariadna-test-executor` | `@~/.claude/guides/testing.md` |
   | `general` or unset | `ariadna-executor` | (none) |

   ```
   Task(
     subagent_type="{executor_agent}",
     model="{executor_model}",
     prompt="
       <objective>
       Execute plan {plan_number} of phase {phase_number}-{phase_name}.
       Commit each task atomically. Create SUMMARY.md. Update STATE.md.
       </objective>

       <execution_context>
       @~/.claude/ariadna/workflows/execute-plan.md
       @~/.claude/ariadna/templates/summary.md
       @~/.claude/ariadna/references/checkpoints.md
       @~/.claude/ariadna/references/tdd.md
       {If domain_guide is set:}
       @~/.claude/guides/{domain_guide}
       </execution_context>

       <files_to_read>
       Read these files at execution start using the Read tool:
       - Plan: {phase_dir}/{plan_file}
       - State: .planning/STATE.md
       - Config: .planning/config.json (if exists)
       </files_to_read>

       <success_criteria>
       - [ ] All tasks executed
       - [ ] Each task committed individually
       - [ ] SUMMARY.md created in plan directory
       - [ ] STATE.md updated with position and decisions
       </success_criteria>
     "
   )
   ```

3. **Wait for all agents in wave to complete.**

4. **Report completion — spot-check claims first:**

   For each SUMMARY.md:
   - Verify first 2 files from `key-files.created` exist on disk
   - Check `git log --oneline --all --grep="{phase}-{plan}"` returns ≥1 commit
   - Check for `## Self-Check: FAILED` marker

   If ANY spot-check fails: report which plan failed, route to failure handler — ask "Retry plan?" or "Continue with remaining waves?"

   If pass:
   ```
   ---
   ## Wave {N} Complete

   **{Plan ID}: {Plan Name}**
   {What was built — from SUMMARY.md}
   {Notable deviations, if any}

   {If more waves: what this enables for next wave}
   ---
   ```

   - Bad: "Wave 2 complete. Proceeding to Wave 3."
   - Good: "Terrain system complete — 3 biome types, height-based texturing, physics collision meshes. Vehicle physics (Wave 3) can now reference ground surfaces."

5. **Handle failures:**

   **Known Claude Code bug (classifyHandoffIfNeeded):** If an agent reports "failed" with error containing `classifyHandoffIfNeeded is not defined`, this is a Claude Code runtime bug — not an Ariadna or agent issue. The error fires in the completion handler AFTER all tool calls finish. In this case: run the same spot-checks as step 4 (SUMMARY.md exists, git commits present, no Self-Check: FAILED). If spot-checks PASS → treat as **successful**. If spot-checks FAIL → treat as real failure below.

   For real failures: report which plan failed → ask "Continue?" or "Stop?" → if continue, dependent plans may also fail. If stop, partial completion report.

6. **Execute checkpoint plans between waves** — see `<checkpoint_handling>`.

7. **Proceed to next wave.**
</step>

<step name="team_execution">
**Alternative to `execute_waves`.** Used when `team_execution` config is `true` OR `--team` flag is passed.

**Decision gate:** Check config and flags:
```bash
TEAM_MODE=$(ariadna-tools config get execution.team 2>/dev/null || echo "false")
```
If `TEAM_MODE` is `true` OR `--team` flag present → use team execution. Otherwise → use wave-based `execute_waves` (default).

**Team execution flow:**

1. **Create team:**
   ```
   TeamCreate(team_name="phase-{N}-execution", description="Executing phase {N}")
   ```

2. **Create tasks from plans:** One `TaskCreate` per incomplete plan:
   ```
   TaskCreate(
     subject="Execute plan {plan_id}: {objective}",
     description="Execute {phase_dir}/{plan_file}. Domain: {domain}. Files: {files_modified}.",
     activeForm="Executing plan {plan_id}"
   )
   ```
   Set up dependencies using `addBlockedBy` matching plan `depends_on` fields.

3. **Spawn domain executor agents:** One agent per unique domain in the plans:
   ```
   Task(
     team_name="phase-{N}-execution",
     name="{domain}-executor",
     subagent_type="ariadna-{domain}-executor",
     model="{executor_model}",
     prompt="
       You are a {domain} executor on team phase-{N}-execution.

       <protocol>
       1. Check TaskList for tasks assigned to you
       2. Claim unblocked tasks via TaskUpdate(status='in_progress')
       3. Read the plan file, execute all tasks, create SUMMARY.md
       4. Mark task completed via TaskUpdate(status='completed')
       5. Check TaskList for next available task
       6. When no tasks remain, send message to team lead
       </protocol>

       <execution_context>
       @~/.claude/ariadna/workflows/execute-plan.md
       @~/.claude/ariadna/templates/summary.md
       @~/.claude/guides/{domain_guide}
       </execution_context>
     "
   )
   ```
   For `general` domain, use `ariadna-executor` as the subagent_type.

4. **Assign tasks:** `TaskUpdate(owner="{domain}-executor")` for each task based on plan domain.

5. **Monitor progress:** Orchestrator monitors via `TaskList`. When agents complete tasks:
   - Newly unblocked tasks become available for assignment
   - Assign unblocked tasks to idle agents of the matching domain
   - Cross-domain handoffs: if a frontend task depends on a backend task, the frontend executor can read the backend SUMMARY.md for context

6. **Handle checkpoints:** Same as wave-based — agent sends message to orchestrator, orchestrator presents checkpoint to user, spawns continuation agent.

7. **Shutdown team:** When all tasks are complete:
   ```
   SendMessage(type="shutdown_request", recipient="{domain}-executor")
   ```
   for each spawned agent. After all agents shut down:
   ```
   TeamDelete()
   ```

**Conflict prevention:** File ownership is enforced by `files_modified` frontmatter — the planner ensures no overlap between concurrent plans assigned to different agents.
</step>

<step name="checkpoint_handling">
Plans with `autonomous: false` require user interaction.

**Flow:**

1. Spawn agent for checkpoint plan
2. Agent runs until checkpoint task or auth gate → returns structured state
3. Agent return includes: completed tasks table, current task + blocker, checkpoint type/details, what's awaited
4. **Present to user:**
   ```
   ## Checkpoint: [Type]

   **Plan:** 03-03 Dashboard Layout
   **Progress:** 2/3 tasks complete

   [Checkpoint Details from agent return]
   [Awaiting section from agent return]
   ```
5. User responds: "approved"/"done" | issue description | decision selection
6. **Spawn continuation agent (NOT resume)** using continuation-prompt.md template:
   - `{completed_tasks_table}`: From checkpoint return
   - `{resume_task_number}` + `{resume_task_name}`: Current task
   - `{user_response}`: What user provided
   - `{resume_instructions}`: Based on checkpoint type
7. Continuation agent verifies previous commits, continues from resume point
8. Repeat until plan completes or user stops

**Why fresh agent, not resume:** Resume relies on internal serialization that breaks with parallel tool calls. Fresh agents with explicit state are more reliable.

**Checkpoints in parallel waves:** Agent pauses and returns while other parallel agents may complete. Present checkpoint, spawn continuation, wait for all before next wave.
</step>

<step name="aggregate_results">
After all waves:

**Aggregate requirements coverage:** Parse `requirements_covered` from all SUMMARY.md frontmatter in this phase. Cross-check against `requirements_content` (from INIT or re-read REQUIREMENTS.md) for requirements mapped to this phase. Flag uncovered requirements. Show coverage count.

If covered requirements exist, update REQUIREMENTS.md traceability table: set status to "Complete" for each covered REQ-ID, with evidence from the SUMMARY frontmatter.

```markdown
## Phase {X}: {Name} Execution Complete

**Waves:** {N} | **Plans:** {M}/{total} complete
**Requirements:** {covered}/{total_for_phase} covered

| Wave | Plans | Status |
|------|-------|--------|
| 1 | plan-01, plan-02 | ✓ Complete |
| CP | plan-03 | ✓ Verified |
| 2 | plan-04 | ✓ Complete |

### Plan Details
1. **03-01**: [one-liner from SUMMARY.md]
2. **03-02**: [one-liner from SUMMARY.md]

### Requirements Coverage
| REQ-ID | Requirement | Evidence |
|--------|-------------|----------|
| {id} | {description} | {evidence from SUMMARY} |
| {id} | {description} | ⚠ Not covered |

[Omit section if no REQUIREMENTS.md or no requirements for this phase]

### Issues Encountered
[Aggregate from SUMMARYs, or "None"]
```
</step>

<step name="verify_phase_goal">
Verify phase achieved its GOAL, not just completed tasks.

```
Task(
  prompt="Verify phase {phase_number} goal achievement.
Phase directory: {phase_dir}
Phase goal: {goal from ROADMAP.md}
Check must_haves against actual codebase. Create VERIFICATION.md.",
  subagent_type="ariadna-verifier",
  model="{verifier_model}"
)
```

Read status:
```bash
grep "^status:" "$PHASE_DIR"/*-VERIFICATION.md | cut -d: -f2 | tr -d ' '
```

| Status | Action |
|--------|--------|
| `passed` | → user_acceptance |
| `human_needed` | Present items for human testing, get approval or feedback → user_acceptance |
| `gaps_found` | Present gap summary, offer `/ariadna:plan-phase {phase} --gaps` |

**If human_needed:**
```
## ✓ Phase {X}: {Name} — Human Verification Required

All automated checks passed. {N} items need human testing:

{From VERIFICATION.md human_verification section}

"approved" → continue | Report issues → gap closure
```

**If gaps_found:**
```
## ⚠ Phase {X}: {Name} — Gaps Found

**Score:** {N}/{M} must-haves verified
**Report:** {phase_dir}/{phase}-VERIFICATION.md

### What's Missing
{Gap summaries from VERIFICATION.md}

---
## ▶ Next Up

`/ariadna:plan-phase {X} --gaps`

<sub>`/clear` first → fresh context window</sub>

Also: `cat {phase_dir}/{phase}-VERIFICATION.md` — full report
Also: `/ariadna:verify-work {X}` — manual testing first
```

Gap closure cycle: `/ariadna:plan-phase {X} --gaps` reads VERIFICATION.md → creates gap plans with `gap_closure: true` → user runs `/ariadna:execute-phase {X} --gaps-only` → verifier re-runs.
</step>

<step name="user_acceptance">
**Trigger:** After verifier returns `passed` (or `human_needed` items are approved by user).

**Skip if:** `--no-review` flag, or ALL plans in this phase have `domain: backend` or `domain: testing` only (no user-facing deliverables).

**Otherwise:** Show a lightweight acceptance gate. Gather one-liners from each SUMMARY.md + key decisions Claude made during execution:

```
questions: [
  {
    header: "Acceptance",
    question: "Phase {X}: {Name} — verified and passing.\n\nWhat was built:\n- {one-liner from SUMMARY 1}\n- {one-liner from SUMMARY 2}\n\nKey decisions made:\n- {decision 1 from SUMMARY}\n- {decision 2 from SUMMARY}\n\nDoes the direction look right?",
    multiSelect: false,
    options: [
      { label: "Looks good", description: "Mark phase complete and continue" },
      { label: "Test first", description: "Run /ariadna:verify-work before marking complete" },
      { label: "Issues", description: "Record blocker and suggest gap closure" }
    ]
  }
]
```

- **"Looks good":** Proceed to `update_roadmap`.
- **"Test first":** Display: `Run /ariadna:verify-work {X} to test, then re-run /ariadna:execute-phase {X} to continue.` Exit without marking phase complete.
- **"Issues":** Ask user to describe the issue. Record as blocker in STATE.md via `ariadna-tools state add-blocker "{issue}"`. Display: `Blocker recorded. Run /ariadna:plan-phase {X} --gaps to create fix plans.` Exit without marking phase complete.
</step>

<step name="update_roadmap">
Mark phase complete in ROADMAP.md (date, status).

```bash
ariadna-tools commit "docs(phase-{X}): complete phase execution" --files .planning/ROADMAP.md .planning/STATE.md .planning/phases/{phase_dir}/*-VERIFICATION.md .planning/REQUIREMENTS.md
```
</step>

<step name="offer_next">

**If more phases:**
```
## Next Up

**Phase {X+1}: {Name}** — {Goal}

`/ariadna:plan-phase {X+1}`

<sub>`/clear` first for fresh context</sub>
```

**If milestone complete:**
```
MILESTONE COMPLETE!

All {N} phases executed.

`/ariadna:complete-milestone`
```
</step>

</process>

<context_efficiency>
Orchestrator: ~10-15% context. Subagents: fresh 200k each. No polling (Task blocks). No context bleed.
</context_efficiency>

<failure_handling>
- **classifyHandoffIfNeeded false failure:** Agent reports "failed" but error is `classifyHandoffIfNeeded is not defined` → Claude Code bug, not Ariadna. Spot-check (SUMMARY exists, commits present) → if pass, treat as success
- **Agent fails mid-plan:** Missing SUMMARY.md → report, ask user how to proceed
- **Dependency chain breaks:** Wave 1 fails → Wave 2 dependents likely fail → user chooses attempt or skip
- **All agents in wave fail:** Systemic issue → stop, report for investigation
- **Checkpoint unresolvable:** "Skip this plan?" or "Abort phase execution?" → record partial progress in STATE.md
</failure_handling>

<resumption>
Re-run `/ariadna:execute-phase {phase}` → discover_plans finds completed SUMMARYs → skips them → resumes from first incomplete plan → continues wave execution.

STATE.md tracks: last completed plan, current wave, pending checkpoints.
</resumption>
