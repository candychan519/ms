# Recording Rules

This document defines what must be recorded while working on this LDPlayer + AutoJs6 automation project.

## Rule 1: Documentation Is Part Of Done

If a task changes any of the following, update the matching document before finishing:

- environment information
- tools, installation, or update process
- shared folder paths
- AutoJs6 permissions or run process
- scripts, tests, or helper tools
- repeated problems and fixes
- user operating preferences

## Rule 2: Stable Knowledge Goes To `docs/`

Record durable reference material in `docs/`:

- Environment: `docs/ENVIRONMENT.md`
- Tools and installation: `docs/TOOLS_AND_INSTALLATION.md`
- Usage and sharing: `docs/USAGE_AND_SHARING.md`
- Work and development method: `docs/WORK_AND_DEVELOPMENT_METHOD.md`
- Recording rules: `docs/RECORDING_RULES.md`
- Migration: `MIGRATION.md`

## Rule 3: New Findings Go To `logs/LEARNINGS.md`

Append new findings, mistakes, workarounds, decisions, and verification results to `logs/LEARNINGS.md`.

Use this format:

```text
## YYYY-MM-DD - Short Title

Context:
Finding:
Evidence:
Decision:
Next action:
```

## Rule 4: Record Evidence, Not Just Conclusions

Prefer concrete evidence:

- command used
- file path
- version number
- screenshot path
- observed output
- confirmed UI state
- test result

## Rule 5: Keep Secrets Out

Do not record:

- passwords
- tokens
- API keys
- account recovery codes
- private personal data

## Rule 6: Separate Current State From History

- Current state: `docs/`
- Historical findings and changes: `logs/LEARNINGS.md`
- Source scripts: `scripts/`
- Helper tools: `tools/`
- Tests: `tests/`
- Temporary installers or large external files: `downloads/`

## Rule 7: Use The Learning Loop

Every meaningful task should follow this loop:

```text
Observe -> Test -> Record -> Reuse -> Refine
```

- Observe: inspect the actual environment or screen.
- Test: run the smallest useful test.
- Record: write the result in the right document.
- Reuse: use recorded knowledge in the next task.
- Refine: update docs when old knowledge becomes stale.

## Rule 8: User Preferences

Current preferences:

- Android apps in LDPlayer should be installed and updated through Google Play by default.
- If Google Play asks for login, pause and let the user log in.
- Do not switch to third-party APK/XAPK sources unless the user explicitly approves it.
- Prefer TDD for helper tools and reusable workflows.
- Use multi-agent review when explicitly requested for completeness checks.
