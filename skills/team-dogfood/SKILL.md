---
name: team-dogfood
description: "Full /team pipeline with parallel /dogfood browser QA in the verify stage. Use when asked to 'team dogfood', 'team-dogfood', or when building a web app that needs browser testing after implementation."
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*), Bash(npm:*), Bash(which:*), Bash(curl:*), Bash(mkdir:*), Bash(cat:*), Bash(ls:*), Bash(lsof:*), Bash(kill:*), Bash(pkill:*), Bash(npx next:*), Bash(npx prisma:*), Bash(sleep:*)
---

# Team Dogfood

This skill extends `/team` with **parallel `/dogfood` browser QA** in the verify stage.

## CRITICAL: Team Orchestration Requirement

**You MUST use the `/oh-my-claudecode:team` skill as the base orchestration mechanism.**

This means:
1. **FIRST**, invoke the `/team` skill via `Skill("oh-my-claudecode:team", args)` to set up proper Claude Code native team coordination
2. The `/team` skill handles: team creation, task decomposition, teammate spawning, stage transitions, and coordination
3. `/team-dogfood` ONLY adds the dogfood QA layer on top of `/team`'s verify stage
4. **Do NOT substitute Task agents for team coordination** — you must use `/team`'s native team mechanism

### How to Invoke

When `/team-dogfood` is triggered with arguments like `N "task description" --url URL`:

1. Parse the arguments to extract:
   - `N` — number of workers (optional, default from /team)
   - `task description` — the work to be done
   - `--url TARGET_URL` — the URL to dogfood (required for dogfood QA, default: http://localhost:3000)
   - `--dogfood-workers N` — number of dogfood workers in verify stage (default: 3)
   - `--auth "instructions"` — optional auth instructions for dogfood workers

2. Invoke the `/team` skill:
   ```
   Skill("oh-my-claudecode:team", "N \"task description\"")
   ```

3. The `/team` skill will run its standard pipeline:
   ```
   team-plan → team-prd → team-exec → team-verify → team-fix (loop)
   ```

4. **INTERCEPT at team-verify stage**: Before `/team` runs its standard verify, inject the dogfood QA workers alongside the standard verifiers.

### Interception Strategy

Since you cannot literally intercept `/team`'s internal stages, the practical approach is:

**Option A (Preferred): Invoke /team with modified instructions**

Pass the full context to `/team` so it knows to include dogfood in its verify stage:

```
Skill("oh-my-claudecode:team", "N \"task description. IMPORTANT: During team-verify stage, in addition to standard verifier/reviewer agents, also spawn parallel dogfood QA workers using agent-browser to test TARGET_URL. Decompose the app into N non-overlapping test scopes and assign one dogfood worker per scope. Each dogfood worker should use the /dogfood skill. Dogfood results go to ./dogfood-output/. Critical/High dogfood issues trigger team-fix loop.\"")
```

**Option B (If /team doesn't support inline verify customization):**

1. Run `/team` for `team-plan → team-prd → team-exec` stages
2. After team-exec completes, run your own verify stage that combines:
   - Standard verifier/reviewer agents (via Task tool)
   - Parallel dogfood QA workers (via Task tool with agent-browser)
3. If issues found, create fix tasks and loop back

## Pipeline

```
team-plan → team-prd → team-exec → team-verify(+ parallel /dogfood QA) → team-fix (loop)
```

All stages are managed by the `/team` skill. The only addition is dogfood QA workers in the verify stage.

## Prerequisites Check (Before team-verify dogfood)

Check prerequisites **once**, before the first verify stage that includes dogfood. This does NOT block team-plan, team-prd, or team-exec.

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
team-verify stage workers (managed by /team):
|- verifier (sonnet)           -- standard completion/code verification
|- security-reviewer (sonnet)  -- if applicable
|- dogfood-worker-1            -- /dogfood on scope area 1
|- dogfood-worker-2            -- /dogfood on scope area 2
|- dogfood-worker-3            -- /dogfood on scope area 3
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
- Structured exploration workflow (initialize -> authenticate -> orient -> explore -> document -> wrap up)
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

The verify stage **fails** (-> team-fix) if:
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
- After fixes, the pipeline loops back: `team-exec -> team-verify(+dogfood)`
- On re-verify, dogfood workers re-test the specific areas where issues were found

## Everything Else

All other aspects are handled by the `/team` skill:
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

Step 1: Invoke /team skill
  Skill("oh-my-claudecode:team", "4 \"build a todo app with auth\"")

Step 2: /team runs its pipeline
  team-plan:
    explore scans codebase, planner creates task graph

  team-prd:
    analyst defines acceptance criteria

  team-exec:
    worker-1: Implement auth (login, signup, session)
    worker-2: Implement todo CRUD
    worker-3: Implement UI components
    worker-4: Write tests

Step 3: At team-verify, /team-dogfood adds dogfood workers
  team-verify:
    |- verifier: checks code quality, test results, completion
    |- dogfood-worker-1: /dogfood localhost:3000 -- auth flows
    |- dogfood-worker-2: /dogfood localhost:3000 -- todo CRUD
    |- dogfood-worker-3: /dogfood localhost:3000 -- UI/UX

  Results:
    verifier: PASS
    dogfood: 12 issues (1 critical, 3 high, 5 medium, 3 low)
    -> FAIL (critical + high issues found)

Step 4: /team runs team-fix with dogfood issues
  team-fix:
    worker-1: Fix ISSUE-001 (critical: login form submits empty)
    worker-2: Fix ISSUE-002 (high: todo delete has no confirmation)
    worker-3: Fix ISSUE-003 (high: session expires without warning)
    worker-4: Fix ISSUE-004 (high: mobile layout broken)

Step 5: Re-verify with dogfood
  team-verify (round 2):
    |- verifier: PASS
    |- dogfood-worker-1: re-test auth flows -> 0 new issues
    |- dogfood-worker-2: re-test todo CRUD -> 0 new issues
    |- dogfood-worker-3: re-test UI/UX -> 1 medium issue

  Results:
    verifier: PASS
    dogfood: 1 medium issue (non-blocking)
    -> PASS

complete:
  Combined dogfood report: ./dogfood-output/combined-report.md
  Total: 1 remaining medium issue (reported, non-blocking)
```
