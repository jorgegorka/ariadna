# Verification Report Template

Template for `.ariadna_planning/phases/XX-name/{phase}-VERIFICATION.md` — phase goal verification results.

---

## File Template

```markdown
---
phase: XX-name
verified: YYYY-MM-DDTHH:MM:SSZ
status: passed | gaps_found | human_needed
score: N/M must-haves verified | security: N critical, N high | performance: N high
---

# Phase {X}: {Name} Verification Report

**Phase Goal:** {goal from ROADMAP.md}
**Verified:** {timestamp}
**Status:** {passed | gaps_found | human_needed}

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | {truth from must_haves} | ✓ VERIFIED | {what confirmed it} |
| 2 | {truth from must_haves} | ✗ FAILED | {what's wrong} |
| 3 | {truth from must_haves} | ? UNCERTAIN | {why can't verify} |

**Score:** {N}/{M} truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `app/controllers/chats_controller.rb` | Chat CRUD actions | ✓ EXISTS + SUBSTANTIVE | Defines index, show, create actions with model queries |
| `app/models/message.rb` | Message model | ✗ STUB | File exists but empty class body, no validations |
| `db/migrate/20250115_create_messages.rb` | Messages table | ✓ EXISTS + SUBSTANTIVE | Creates table with content, user_id, chat_id columns |

**Artifacts:** {N}/{M} verified

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| chats_controller.rb | message.rb | Message.where in index | ✓ WIRED | Line 8: `@messages = Message.where(chat_id: @chat.id)` |
| chats/index.html.erb | chats_controller.rb | @messages + chat_path | ✗ NOT WIRED | View uses @messages but controller doesn't set it in show |
| routes.rb | chats_controller.rb | resources :chats | ✗ NOT WIRED | Route defined but controller missing `create` action |

**Wiring:** {N}/{M} connections verified

## Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| {REQ-01}: {description} | ✓ SATISFIED | - |
| {REQ-02}: {description} | ✗ BLOCKED | API route is stub |
| {REQ-03}: {description} | ? NEEDS HUMAN | Can't verify WebSocket programmatically |

**Coverage:** {N}/{M} requirements satisfied

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| app/models/message.rb | 12 | `# TODO: add validations` | ⚠️ Warning | Indicates incomplete |
| app/controllers/chats_controller.rb | 8 | `def show; end` | 🛑 Blocker | Empty action |
| app/jobs/message_broadcast_job.rb | - | File missing | 🛑 Blocker | Expected job doesn't exist |

**Anti-patterns:** {N} found ({blockers} blockers, {warnings} warnings)

## Security Findings

| Check | Name | Severity | File | Line | Detail |
|-------|------|----------|------|------|--------|
| 3.2a | Unscoped find | Critical | app/controllers/chats_controller.rb | 15 | `Message.find(params[:id])` without user scoping |
| 2.2a | Strong parameters | High | app/controllers/chats_controller.rb | 28 | Missing strong parameter filtering |

**Security:** {N} findings ({critical} critical, {high} high, {medium} medium)

## Performance Findings

| Check | Name | Severity | File | Line | Detail |
|-------|------|----------|------|------|--------|
| 1.1a | N+1 query | High | app/controllers/chats_controller.rb | 10 | `@messages = Message.all` without `.includes(:user)` |
| 5.2a | Missing pagination | High | app/controllers/chats_controller.rb | 10 | Unbounded `.all` without `.page` or `.limit` |

**Performance:** {N} findings ({high} high, {medium} medium, {low} low)

## Human Verification Required

{If no human verification needed:}
None — all verifiable items checked programmatically.

{If human verification needed:}

### 1. {Test Name}
**Test:** {What to do}
**Expected:** {What should happen}
**Why human:** {Why can't verify programmatically}

### 2. {Test Name}
**Test:** {What to do}
**Expected:** {What should happen}
**Why human:** {Why can't verify programmatically}

## Gaps Summary

{If no gaps:}
**No gaps found.** Phase goal achieved. Ready to proceed.

{If gaps found:}

### Critical Gaps (Block Progress)

1. **{Gap name}**
   - Missing: {what's missing}
   - Impact: {why this blocks the goal}
   - Fix: {what needs to happen}

2. **{Gap name}**
   - Missing: {what's missing}
   - Impact: {why this blocks the goal}
   - Fix: {what needs to happen}

### Non-Critical Gaps (Can Defer)

1. **{Gap name}**
   - Issue: {what's wrong}
   - Impact: {limited impact because...}
   - Recommendation: {fix now or defer}

## Recommended Fix Plans

{If gaps found, generate fix plan recommendations:}

### {phase}-{next}-PLAN.md: {Fix Name}

**Objective:** {What this fixes}

**Tasks:**
1. {Task to fix gap 1}
2. {Task to fix gap 2}
3. {Verification task}

**Estimated scope:** {Small / Medium}

---

### {phase}-{next+1}-PLAN.md: {Fix Name}

**Objective:** {What this fixes}

**Tasks:**
1. {Task}
2. {Task}

**Estimated scope:** {Small / Medium}

---

## Verification Metadata

**Verification approach:** Goal-backward (derived from phase goal)
**Must-haves source:** {PLAN.md frontmatter | derived from ROADMAP.md goal}
**Automated checks:** {N} passed, {M} failed
**Human checks required:** {N}
**Total verification time:** {duration}

---
*Verified: {timestamp}*
*Verifier: Claude (subagent)*
```

---

## Guidelines

**Status values:**
- `passed` — All must-haves verified, no blockers, no Critical/High security findings, no excessive performance findings
- `gaps_found` — One or more critical gaps found, or any Critical/High security findings, or 3+ High performance findings
- `human_needed` — Automated checks pass but human verification required

**Security/Performance impact on status:**
- Any Critical or High security finding forces `gaps_found` regardless of other checks
- 3+ High performance findings forces `gaps_found`; individual High findings are warnings
- Medium and Low findings are informational and do not affect status

**Evidence types:**
- For EXISTS: "File at path, exports X"
- For SUBSTANTIVE: "N lines, has patterns X, Y, Z"
- For WIRED: "Line N: code that connects A to B"
- For FAILED: "Missing because X" or "Stub because Y"

**Severity levels:**
- 🛑 Blocker: Prevents goal achievement, must fix
- ⚠️ Warning: Indicates incomplete but doesn't block
- ℹ️ Info: Notable but not problematic

**Fix plan generation:**
- Only generate if gaps_found
- Group related fixes into single plans
- Keep to 2-3 tasks per plan
- Include verification task in each plan

---

## Example

```markdown
---
phase: 03-chat
verified: 2025-01-15T14:30:00Z
status: gaps_found
score: 2/5 must-haves verified | security: 1 critical, 1 high | performance: 2 high
---

# Phase 3: Chat Interface Verification Report

**Phase Goal:** Working chat interface where users can send and receive messages
**Verified:** 2025-01-15T14:30:00Z
**Status:** gaps_found

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can see existing messages | ✗ FAILED | Controller index action returns empty, view renders static text |
| 2 | User can type a message | ✓ VERIFIED | form_with in view with text_area for content |
| 3 | User can send a message | ✗ FAILED | create action only calls `head :ok`, no model interaction |
| 4 | Sent message appears in list | ✗ FAILED | No Turbo Stream or redirect after create |
| 5 | Messages persist across refresh | ? UNCERTAIN | Can't verify — create doesn't save to database |

**Score:** 1/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `app/controllers/chats_controller.rb` | Chat CRUD actions | ✗ STUB | index assigns @messages but show/create are `head :ok` |
| `app/views/chats/index.html.erb` | Message list view | ✓ EXISTS + SUBSTANTIVE | Iterates @messages, renders form_with for new message |
| `app/models/message.rb` | Message model | ✗ STUB | Empty class body — no validations, no associations |
| `db/migrate/20250115_create_messages.rb` | Messages table | ✓ EXISTS + SUBSTANTIVE | Creates table with content, user_id, chat_id, timestamps |

**Artifacts:** 2/4 verified

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| chats_controller.rb | message.rb | Message.where in index | ✗ NOT WIRED | Index assigns `@messages = []` (hardcoded empty) |
| chats/index.html.erb | chats_controller.rb | @messages + form_with | ✗ PARTIAL | View uses @messages but controller doesn't query |
| routes.rb | chats_controller.rb | resources :chats | ✗ PARTIAL | Routes defined but create action is stub |
| message.rb | database | belongs_to + migration | ✗ NOT WIRED | Model has no associations, migration exists |

**Wiring:** 0/4 connections verified

## Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| CHAT-01: User can send message | ✗ BLOCKED | create action is stub |
| CHAT-02: User can view messages | ✗ BLOCKED | Controller returns hardcoded empty |
| CHAT-03: Messages persist | ✗ BLOCKED | No database integration in controller |

**Coverage:** 0/3 requirements satisfied

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| app/controllers/chats_controller.rb | 12 | `def create; head :ok; end` | 🛑 Blocker | No-op action |
| app/models/message.rb | 1 | Empty class body | 🛑 Blocker | No validations or associations |
| app/controllers/chats_controller.rb | 5 | `# TODO: query messages` | ⚠️ Warning | Incomplete |

**Anti-patterns:** 3 found (2 blockers, 1 warning)

## Security Findings

| Check | Name | Severity | File | Line | Detail |
|-------|------|----------|------|------|--------|
| 3.2a | Unscoped find | Critical | app/controllers/chats_controller.rb | 8 | `Chat.find(params[:id])` without user scoping |
| 2.2a | Missing strong params | High | app/controllers/chats_controller.rb | 12 | create action has no strong parameter filtering |

**Security:** 2 findings (1 critical, 1 high, 0 medium)

## Performance Findings

| Check | Name | Severity | File | Line | Detail |
|-------|------|----------|------|------|--------|
| 1.1a | Missing eager load | High | app/controllers/chats_controller.rb | 5 | @messages query (once wired) will N+1 on user association |
| 5.2a | Missing pagination | High | app/controllers/chats_controller.rb | 5 | Unbounded query without .page or .limit |

**Performance:** 2 findings (2 high, 0 medium, 0 low)

## Human Verification Required

None needed until automated gaps are fixed.

## Gaps Summary

### Critical Gaps (Block Progress)

1. **Controller actions are stubs**
   - Missing: Model queries in index, create logic in create
   - Impact: Users see empty page, message submission does nothing
   - Fix: Wire controller actions to Message model

2. **Message model is empty**
   - Missing: Validations, associations (belongs_to :chat, belongs_to :user)
   - Impact: No data integrity, no association traversal
   - Fix: Add validations and associations to Message model

3. **No wiring between controller and model**
   - Missing: Message.where/create calls in controller
   - Impact: Even with model fixed, controller wouldn't use it
   - Fix: Wire controller index to Message.where, create to Message.create

### Non-Critical Gaps (Can Defer)

1. **Security: Unscoped find**
   - Issue: Chat.find(params[:id]) allows IDOR
   - Impact: Users could access other users' chats
   - Recommendation: Fix now — scope through Current.user

## Recommended Fix Plans

### 03-04-PLAN.md: Wire Chat Model

**Objective:** Make Message model functional with validations and associations

**Tasks:**
1. Add belongs_to :chat, belongs_to :user associations to Message
2. Add content presence validation and length constraint
3. Verify: Message.create with valid/invalid data behaves correctly

**Estimated scope:** Small

---

### 03-05-PLAN.md: Wire Chat Controller

**Objective:** Connect controller actions to Message model

**Tasks:**
1. Wire index action: `@messages = @chat.messages.includes(:user).order(created_at: :asc)`
2. Wire create action: `Message.create(message_params)` with strong params and Turbo Stream response
3. Scope Chat.find through Current.user to fix IDOR
4. Verify: Messages display, new messages appear after send

**Estimated scope:** Small

---

## Verification Metadata

**Verification approach:** Goal-backward (derived from phase goal)
**Must-haves source:** 03-01-PLAN.md frontmatter
**Automated checks:** 2 passed, 8 failed
**Security checks:** 2 findings (1 critical, 1 high)
**Performance checks:** 2 findings (2 high)
**Human checks required:** 0 (blocked by automated failures)
**Total verification time:** 2 min

---
*Verified: 2025-01-15T14:30:00Z*
*Verifier: Claude (subagent)*
```
