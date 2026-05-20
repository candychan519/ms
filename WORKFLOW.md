# Workflow

This project stores notes and scripts for Android AutoJs6 automation running in LDPlayer.

## Documentation Map

Use this file as the project entrypoint. Stable details are split by topic:

- Environment info: `docs/ENVIRONMENT.md`
- Tools and installation: `docs/TOOLS_AND_INSTALLATION.md`
- Frida smoke-test tutorial: `docs/TUTORIAL_FRIDA_HOOK_SMOKE_TEST.md`
- Frida verification how-to: `docs/HOW_TO_VERIFY_FRIDA_HOOKS.md`
- Frida verification reference: `docs/FRIDA_HOOK_VERIFICATION_REFERENCE.md`
- Frida verification rationale: `docs/WHY_FRIDA_VERIFICATION_IS_APP_PROCESS_SCOPED.md`
- Usage and sharing: `docs/USAGE_AND_SHARING.md`
- Work and development method: `docs/WORK_AND_DEVELOPMENT_METHOD.md`
- Recording rules: `docs/RECORDING_RULES.md`
- Learning log: `logs/LEARNINGS.md`
- Script source notes: `scripts/README.md`
- Migration guide: `MIGRATION.md`
- Session summary: `docs/SESSION_SUMMARY_2026-05-16.md`
- ADB setup helper: `tools/setup-ldplayer-adb.ps1`
- Bounded key input helper: `tools/send-ldplayer-key.ps1`
- Minimap player marker helper: `tools/find-minimap-player-marker.ps1`
- Minimap position UI: `tools/show-minimap-position-ui.ps1`
- Codex skill install helper: `tools/install-codex-skill.ps1`
- Full test runner: `tests/run-all.ps1`
- ADB setup tests: `tests/test-ldplayer-adb-setup.ps1`
- LDPlayer capture tests: `tests/test-capture-ldplayer.ps1`
- Minimap marker tests: `tests/test-find-minimap-player-marker.ps1`
- Minimap position UI tests: `tests/test-show-minimap-position-ui.ps1`
- Codex skill install tests: `tests/test-install-codex-skill.ps1`
- Bounded key input tests: `tests/test-send-ldplayer-key.ps1`
- Skill validation tests: `tests/test-ldplayer-autojs6-skill.ps1`
- Reusable Codex skill: `%USERPROFILE%\.codex\skills\ldplayer-autojs6`
- Versioned Codex skill source: `codex-skills/ldplayer-autojs6`

Documentation rule:

- If the environment, tools, install process, usage flow, sharing path, work method, or development method changes, update the matching document.
- If a new finding, mistake, workaround, or verification result appears during work, append it to `logs/LEARNINGS.md`.
- Do not record secrets, passwords, tokens, or account recovery data.

## Environment

- Host OS: Windows
- Emulator: LDPlayer
- Automation runtime: AutoJs6 for Android, installed inside LDPlayer
- Installed AutoJs6 version: 6.7.0
- LDPlayer resolution: 1280x720
- LDPlayer DPI: 240
- LDPlayer ADB endpoint: `127.0.0.1:5555`
- LDPlayer ADB serial: `emulator-5554`
- AutoJs6 overlay permission: enabled
- AutoJs6 accessibility service: enabled

AutoJs6 scripts are not executed directly by Windows. They run inside the Android environment provided by LDPlayer.

```text
Windows
+-- LDPlayer
    +-- Android
        +-- target app or game
        +-- AutoJs6
            +-- .js script
```

## Shared Folder

LDPlayer maps the Windows shared folder to an Android folder:

```text
Windows: %USERPROFILE%\Documents\XuanZhi9\Pictures
Android: /sdcard/Pictures
```

Example:

```text
%USERPROFILE%\Documents\XuanZhi9\Pictures\macro.js
```

is visible inside LDPlayer as:

```text
/sdcard/Pictures/macro.js
```

## Basic Script Workflow

1. Write or edit a script on Windows, for example:

   ```text
   <repo>\scripts\macro.js
   ```

2. Copy the script to the LDPlayer shared folder:

   ```text
   %USERPROFILE%\Documents\XuanZhi9\Pictures\macro.js
   ```

3. Open LDPlayer.

4. Open AutoJs6 inside LDPlayer.

5. Open the script from:

   ```text
   /sdcard/Pictures/macro.js
   ```

6. Run the script from AutoJs6.

## Test Script

Use this small script to confirm that AutoJs6 can run a file from the shared folder:

```text
Project: <repo>\scripts\autojs6-test.js
Windows shared folder: %USERPROFILE%\Documents\XuanZhi9\Pictures\autojs6-test.js
Android path: /sdcard/Pictures/autojs6-test.js
```

```js
auto.waitFor();

toast("AutoJs6 shared folder test OK");
sleep(1000);

click(500, 500);
```

Expected result:

- A toast message appears inside LDPlayer.
- The emulator receives one tap at screen coordinate `500, 500`.

Current status:

- `autojs6-test` was imported into AutoJs6.
- The test script ran successfully and displayed `AutoJs6 shared folder test OK`.

## ADB Workflow

Use LDPlayer's bundled ADB:

```powershell
C:\LDPlayer\LDPlayer9\adb.exe
```

Validate setup:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\setup-ldplayer-adb.ps1 -AdbPath C:\LDPlayer\LDPlayer9\adb.exe -Endpoint 127.0.0.1:5555
```

Run tests for the setup helper:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\test-ldplayer-adb-setup.ps1
```

Use explicit serials when running ADB commands:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell wm size
```

## Screen Coordinates

AutoJs6 coordinate actions depend on the emulator resolution.

Examples:

```js
click(500, 1200);
press(500, 1200, 800);
swipe(500, 1600, 500, 800, 500);
```

If the LDPlayer resolution changes, coordinate-based scripts may need to be updated.

Record the emulator resolution for each script when possible:

```text
Resolution: 1280x720
```

## Minimap Player Coordinates

Use `tools/find-minimap-player-marker.ps1` to detect the yellow player marker in the MapleStory Worlds minimap.

Analyze an existing screenshot:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\find-minimap-player-marker.ps1 -ImagePath .\screenshots\ldplayer-current-pull.png
```

Monitor the current LDPlayer screen:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\find-minimap-player-marker.ps1 -Watch -IntervalMs 500
```

Open the small live coordinate UI:

```powershell
pwsh -STA -NoProfile -ExecutionPolicy Bypass -File .\tools\show-minimap-position-ui.ps1
```

The helper reports minimap-local coordinates, normalized minimap percentages, and full-screen coordinates. Use the minimap-local coordinate for conversation, for example `minimap=(65,49)`.

## Screenshots

Screenshots are useful for:

- Finding button coordinates.
- Choosing image-recognition targets.
- Documenting what screen a script expects.

Store screenshots in the project or the shared folder when they are needed for a script.

Suggested project layout:

```text
scripts/
screenshots/
notes/
WORKFLOW.md
```

## Future Notes Template

When adding a new automation, record:

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
