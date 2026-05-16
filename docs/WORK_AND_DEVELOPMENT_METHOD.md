# Work And Development Method

이 문서는 작업 방법과 개발 방법을 기록합니다.

## Project Layout

```text
WORKFLOW.md
docs/
logs/
scripts/
screenshots/
downloads/
```

Directory roles:

- `WORKFLOW.md`: project entrypoint and documentation map
- `docs/`: stable operating documents
- `logs/`: append-only learning and decision notes
- `scripts/`: source AutoJs6 scripts edited on Windows
- `screenshots/`: screenshots used for coordinate, image, or OCR analysis
- `downloads/`: downloaded installers and external artifacts

## Development Loop

1. Define the target screen and action.
2. Record whether the automation is offline/personal/testing/accessibility or online/multiplayer.
3. Capture or inspect the screen if coordinates or images are needed.
4. Write the script in `scripts/`.
5. Copy the script to the LDPlayer shared folder.
6. Import or update it in AutoJs6.
7. Run a small test first.
8. Record results, issues, and useful findings in `logs/LEARNINGS.md`.
9. Update stable docs if the finding changes the workflow.

## TDD Loop For Tools

Use this loop for PowerShell helpers, ADB setup scripts, and reusable automation tooling:

1. Add or update a focused test under `tests/`.
2. Run the test and confirm the current failure or missing behavior.
3. Implement the smallest change under `tools/` or `scripts/`.
4. Re-run the focused test.
5. Run one live validation against LDPlayer when the change affects ADB, screenshots, shared folders, or app control.
6. Record stable commands and learned failure modes in `docs/` and `logs/LEARNINGS.md`.

Current ADB test command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\user\Desktop\ms\tests\test-ldplayer-adb-setup.ps1
```

Current live ADB validation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\user\Desktop\ms\tools\setup-ldplayer-adb.ps1 -AdbPath C:\LDPlayer\LDPlayer9\adb.exe -Endpoint 127.0.0.1:5555
```

## Multi-Agent Work Method

Use multi-agent work when the user explicitly asks for it or when work can be split without write conflicts.

Default split:

- Explorer agent: read-only inspection of LDPlayer, logs, ports, docs, and current system state.
- Worker agent: bounded implementation in a disjoint file set, usually `tools/` and `tests/`.
- Main agent: integrate results, perform live setup, run verification, and update project docs/logs.

Workers must not edit docs/logs unless that is their assigned ownership. Main agent owns final integration and documentation.

## Screen Check Cadence

When inspecting LDPlayer visually, Codex should capture the LDPlayer window only, not the whole desktop.

Preferred method:

- Use `tools/capture-ldplayer.ps1`.
- This uses Windows `PrintWindow`, so it does not need to bring LDPlayer to the foreground.
- This avoids covering the user's active work window.

Command:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\user\Desktop\ms\tools\capture-ldplayer.ps1
```

Fallback method:

- Use the screenshot skill's `-WindowHandle` capture.
- This can include overlapping windows, so only use it if `PrintWindow` is insufficient.

Fallback command pattern:

```powershell
$p = Get-Process dnplayer | Select-Object -First 1
powershell -ExecutionPolicy Bypass -File C:\Users\user\.codex\skills\screenshot\scripts\take_screenshot.ps1 -Mode temp -WindowHandle $p.MainWindowHandle
```

The wait should match the action:

- Simple click or navigation: wait `0.5-1.5` seconds.
- Normal UI transitions: wait `1-3` seconds.
- App launch or first screen load: wait `3-7` seconds, then re-check instead of waiting too long at once.
- Store install, update, or network-heavy loading: check every `5-10` seconds unless a longer wait is clearly needed.
- Unknown stuck state: take one screenshot, then decide whether to wait longer or change approach.

Default going forward:

- Prefer frequent short checks over one long wait.
- Use `0.5-1.5` second checks for normal UI work.
- Use repeated `5-10` second checks for installs, downloads, updates, or network loading.
- Only use a long wait when there is a clear reason, and mention that reason.

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

- Keep scripts small until the behavior is proven.
- Put reusable helpers at the top of the script.
- Prefer named functions over long unstructured loops.
- Add a stop condition before any long loop.
- Use `toast()` or logs for visible status during early tests.
- Keep fixed coordinates documented with the screen resolution.

## Safety Boundary

Allowed scope:

- Personal automation
- Offline automation
- Testing
- Accessibility support
- Non-competitive app automation

Avoid:

- Multiplayer farming
- Ranking, economy, trading, or reward automation
- Anti-cheat bypass
- Automation that gives unfair advantage over other users

## Bounded Input Helpers

Repeated key or tap helpers must be bounded by count or short duration.

Rules:

- Default to dry-run before live input.
- Keep intervals at or above `50ms`.
- Reject long unbounded loops.
- Do not run repeated inputs for multiplayer farming, rewards, ranking, economy, trading, or anti-cheat bypass.
- Prefer one short test such as `Count 1-5` before increasing duration.
