---
name: team-dogfood
description: "Full /team pipeline with parallel /dogfood browser QA in the verify stage. Use when asked to 'team dogfood', 'team-dogfood', or when building a web app that needs browser testing after implementation."
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*), Bash(npm:*), Bash(which:*)
---

# Team Dogfood

This skill is **identical to `/team`** in every way, with one enhancement: the **team-verify stage includes parallel `/dogfood` browser QA workers** alongside standard verification.

## Pipeline

```
team-plan → team-prd → team-exec → team-verify(+ parallel /dogfood QA) → team-fix (loop)
```

All stages except `team-verify` follow the standard `/team` skill exactly. Refer to the `/team` skill for the full pipeline specification.

## Usage

```
/team-dogfood N "task description" --url TARGET_URL
/team-dogfood 3 "build a dashboard app" --url http://localhost:3000
/team-dogfood "refactor auth module" --url https://staging.myapp.com
```

### Parameters

All standard `/team` parameters, plus:

- **--url TARGET_URL** — The URL to dogfood after implementation (required). Can be a localhost dev server or staging URL.
- **--dogfood-workers N** — Number of parallel dogfood workers in verify stage (default: 3).
- **--auth "instructions"** — Optional authentication instructions for dogfood workers.

## Prerequisites Check (Before team-verify dogfood)

The lead checks prerequisites **once**, before the first `team-verify` stage that includes dogfood. This does NOT block `team-plan`, `team-prd`, or `team-exec`.

### Check 1: agent-browser

```bash
which agent-browser && agent-browser --version
```

If NOT found:

```bash
npm install -g agent-browser
```

### Check 2: dogfood skill

```bash
ls ~/.claude/skills/dogfood/SKILL.md 2>/dev/null || ls ~/.agents/skills/dogfood/SKILL.md 2>/dev/null
```

If NOT found, attempt install:

```bash
claude /install-skill dogfood
```

If either prerequisite fails, fall back to standard `/team` verify (no browser QA) and warn the user.

## How team-verify Changes

In standard `/team`, the verify stage runs:
- `verifier` (sonnet) — evidence-based completion check
- Optional: `security-reviewer`, `code-reviewer`, `quality-reviewer`

In `/team-dogfood`, the verify stage runs **all of the above PLUS**:

### Parallel Dogfood QA Workers

1. **Auto-decompose the app** into non-overlapping test scopes:

```bash
agent-browser open {TARGET_URL}
agent-browser wait --load networkidle
agent-browser snapshot -i
agent-browser close
```

From the snapshot, divide the app into N areas (one per dogfood worker).

2. **Spawn dogfood workers in parallel** alongside the standard verifier:

```
team-verify stage workers:
├── verifier (sonnet)           — standard completion/code verification
├── security-reviewer (sonnet)  — if applicable
├── dogfood-worker-1            — /dogfood on scope area 1
├── dogfood-worker-2            — /dogfood on scope area 2
└── dogfood-worker-3            — /dogfood on scope area 3
```

3. **Each dogfood worker's task description MUST include:**

```
## Assignment

You are QA testing: {TARGET_URL}
Your scope: {WORKER_SCOPE_AREA}
Output directory: ./dogfood-output/{WORKER_NAME}/

## MANDATORY: Use /dogfood Skill

You MUST use the /dogfood skill to execute this testing task.
Invoke it as: /dogfood {TARGET_URL}

The /dogfood skill provides:
- Structured exploration workflow (initialize → authenticate → orient → explore → document → wrap up)
- Issue taxonomy reference for severity classification
- Report template for consistent documentation
- Full reproduction evidence (screenshots + videos) for every finding

## Scope Constraints

ONLY test the following area: {WORKER_SCOPE_AREA}
Do NOT test outside your assigned scope.

## Output Requirements

- Output directory: ./dogfood-output/{WORKER_NAME}/
- Session name: {WORKER_NAME}
- Produce: report.md with 5-10 well-documented issues
- Every issue MUST have reproduction evidence

## Authentication

{AUTH_INSTRUCTIONS or "No authentication required"}
```

4. **Each dogfood worker's preamble WORK step:**

```
2. WORK: You MUST invoke the /dogfood skill to execute your assigned testing task.
   Run: /dogfood {TARGET_URL}
   Configure the dogfood session with:
   - Session name: {WORKER_NAME}
   - Output directory: ./dogfood-output/{WORKER_NAME}/
   - Scope: {YOUR_ASSIGNED_SCOPE}

   Do NOT test manually without /dogfood. Do NOT skip the skill.
   Do NOT test outside your assigned scope.
   Use `agent-browser` directly (not `npx agent-browser`) for the fast Rust client.
```

Worker agent type: `oh-my-claudecode:executor` with allowed tools `Bash(agent-browser:*)`, `Bash(npx agent-browser:*)`.

## Verify Stage Outcome

The verify stage now produces TWO types of results:

### From standard verifier/reviewers:
- Code quality assessment
- Security review (if applicable)
- Completion evidence

### From dogfood workers:
- Individual reports at `./dogfood-output/worker-*/report.md`
- Combined report at `./dogfood-output/combined-report.md`

**Aggregation:** The lead merges individual dogfood reports:
- Deduplicate issues found by multiple workers
- Re-number issues sequentially (ISSUE-001 through ISSUE-NNN)
- Update summary severity counts
- Add coverage section showing which areas each worker tested

### Pass/Fail Decision

The verify stage **fails** (→ team-fix) if:
- Standard verifier finds issues (same as `/team`), OR
- Dogfood workers find **Critical** or **High** severity issues

The verify stage **passes** if:
- Standard verifier passes, AND
- Dogfood workers find only **Medium/Low** issues or no issues

Medium/Low dogfood issues are reported to the user but do NOT block completion.

## team-fix Behavior

When verify fails due to dogfood findings:
- Fix tasks are created from the dogfood report (Critical/High issues only)
- Each fix task references the specific ISSUE-NNN with reproduction evidence
- After fixes, the pipeline loops back: `team-exec → team-verify(+dogfood)`
- On re-verify, dogfood workers re-test the specific areas where issues were found

## Everything Else

All other aspects follow the standard `/team` skill exactly:
- **team-plan**: `explore` + `planner`, optionally `analyst`/`architect`
- **team-prd**: `analyst`, optionally `critic`
- **team-exec**: `executor` + task-appropriate specialists
- **team-fix**: `executor`/`build-fixer`/`debugger` depending on defect type
- **State persistence**: `state_write(mode="team")` with all standard fields
- **Handoff documents**: `.omc/handoffs/<stage-name>.md`
- **Shutdown protocol**: Standard team shutdown
- **Team + Ralph composition**: Supported (`/team-dogfood ralph "task" --url URL`)
- **CLI workers**: Supported for exec stage (codex/gemini)
- **Error handling**: Standard team error handling
- **Cancellation**: Standard `/oh-my-claudecode:cancel`

## Example

```
User: /team-dogfood 4 "build a todo app with auth" --url http://localhost:3000

team-plan:
  explore scans codebase, planner creates task graph

team-prd:
  analyst defines acceptance criteria

team-exec:
  worker-1: Implement auth (login, signup, session)
  worker-2: Implement todo CRUD
  worker-3: Implement UI components
  worker-4: Write tests

team-verify:
  ├── verifier: checks code quality, test results, completion
  ├── dogfood-worker-1: /dogfood localhost:3000 — auth flows
  ├── dogfood-worker-2: /dogfood localhost:3000 — todo CRUD
  └── dogfood-worker-3: /dogfood localhost:3000 — UI/UX

  Results:
    verifier: PASS
    dogfood: 12 issues (1 critical, 3 high, 5 medium, 3 low)
    → FAIL (critical + high issues found)

team-fix:
  worker-1: Fix ISSUE-001 (critical: login form submits empty)
  worker-2: Fix ISSUE-002 (high: todo delete has no confirmation)
  worker-3: Fix ISSUE-003 (high: session expires without warning)
  worker-4: Fix ISSUE-004 (high: mobile layout broken)

team-verify (round 2):
  ├── verifier: PASS
  ├── dogfood-worker-1: re-test auth flows → 0 new issues
  ├── dogfood-worker-2: re-test todo CRUD → 0 new issues
  └── dogfood-worker-3: re-test UI/UX → 1 medium issue

  Results:
    verifier: PASS
    dogfood: 1 medium issue (non-blocking)
    → PASS

complete:
  Combined dogfood report: ./dogfood-output/combined-report.md
  Total: 1 remaining medium issue (reported, non-blocking)
```
