# Work And Development Method

This document records the working method and development method for the LDPlayer + AutoJs6 automation project.

## Project Layout

```text
WORKFLOW.md
MIGRATION.md
docs/
logs/
scripts/
screenshots/
downloads/
tools/
tests/
codex-skills/
```

Directory roles:

- `WORKFLOW.md`: project entrypoint and documentation map
- `MIGRATION.md`: restore the workspace on another Windows PC
- `docs/`: stable operating documents
- `logs/`: append-only learning and decision notes
- `scripts/`: source AutoJs6 scripts edited on Windows
- `screenshots/`: ignored screenshot workspace
- `downloads/`: ignored installers and external artifacts
- `tools/`: reusable PowerShell helpers
- `tests/`: TDD and migration validation
- `codex-skills/`: versioned Codex skill source

## Development Loop

1. Define the target screen and action.
2. Record whether the automation is offline, personal, testing, accessibility, or online/multiplayer.
3. Capture or inspect the screen if coordinates or images are needed.
4. Write or update the smallest useful script or helper.
5. Add or update a focused test first when the change is reusable.
6. Run the focused test.
7. Run one live LDPlayer validation when the change touches ADB, screenshots, shared folders, app launch, resolution, FPS, or input.
8. Record results, issues, and useful findings in `logs/LEARNINGS.md`.
9. Update stable docs if the finding changes the workflow.

## TDD Loop For Tools

Use this loop for PowerShell helpers, ADB setup scripts, capture helpers, input helpers, and reusable automation tooling:

1. Add or update a focused test under `tests/`.
2. Run the test and confirm the current failure or missing behavior.
3. Implement the smallest change under `tools/`, `scripts/`, or `codex-skills/`.
4. Re-run the focused test.
5. Run `tests/run-all.ps1` before committing when practical.
6. Record stable commands and learned failure modes in `docs/` and `logs/LEARNINGS.md`.

Run all tests:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1
```

## Multi-Agent Work Method

Use multi-agent work when the user explicitly asks for it or when work can be split without write conflicts.

Default split:

- Explorer agent: read-only inspection of LDPlayer, logs, ports, docs, and current system state.
- Worker agent: bounded implementation in disjoint files, usually `tools/` and `tests/`.
- Main agent: integrate results, perform live setup, run verification, update docs/logs, and push changes when requested.

Workers must not edit docs/logs unless that is their assigned ownership. Main agent owns final integration and documentation.

## Screen Check Cadence

When inspecting LDPlayer visually, prefer LDPlayer-only captures over full desktop screenshots.

Preferred methods:

- Use ADB `screencap` when ADB is healthy.
- Use `tools/capture-ldplayer.ps1` when the user is working in another window and non-obstructing capture is needed.
- Use `tools/find-minimap-player-marker.ps1 -Watch` when the user wants live minimap player coordinates for communication or visual debugging.
- Use `tools/start-maple-console.ps1` for the Maple console. This is the canonical minimap repeat UI, not just a coordinate viewer.

Command:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\capture-ldplayer.ps1
```

The wait should match the action:

- Simple click or navigation: wait `0.5-1.5` seconds.
- Normal UI transitions: wait `1-3` seconds.
- App launch or first screen load: wait `3-7` seconds, then re-check.
- Store install, update, or network-heavy loading: check every `5-10` seconds.
- Unknown stuck state: take one screenshot, then decide whether to wait longer or change approach.

## Maple Console Preservation

`tools/start-maple-console.ps1` is the main Maple console. `tools/show-minimap-position-ui.ps1` is only a legacy wrapper for older commands. Do not replace the main console with a coordinate-only UI while debugging minimap detection. If a temporary coordinate-only view is needed, create a separate helper instead.

The console is expected to keep:

- Three map profiles: `빅토리아로드 헤네시스동쪽풀숲`, `선셋로드 사헬지대2`, and `선셋로드 꿈꾸는 사막`.
- The minimap coordinate display and watcher.
- `A 누르기`, `A→왼쪽+F v2`, and the periodic `D 사용` / `D 간격` controls.

Before reporting that the console is fixed or open, verify both behavior and layout:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\test-start-maple-console.ps1
```

Also capture a live screenshot of the `메이플 콘솔` window and inspect it visually. Control names and bounding boxes are not enough; they missed clipped Korean text before.

## New Script Template

Record this before or while building each new automation:

```text
Name:
Target app/game:
Purpose:
Offline or online:
LDPlayer resolution:
Script path:
Shared folder path:
Required screenshots:
Main actions:
Stop condition:
Known issues:
```

## Code Style

- Keep scripts small until behavior is proven.
- Put reusable helpers at the top of scripts.
- Prefer named functions over long unstructured loops.
- Add a stop condition before any long loop.
- Use `toast()` or logs for visible status during early AutoJs6 tests.
- Keep fixed coordinates documented with the screen resolution.

## Bounded Input Helpers

Repeated key or tap helpers must be bounded by count or short duration.

Rules:

- Default to dry-run before live input.
- Keep intervals at or above `50ms`.
- Reject long unbounded loops.
- Prefer one short test such as `Count 1-5` before increasing duration.
