# Session Summary - 2026-05-16

This document summarizes the LDPlayer + AutoJs6 automation setup work completed so far.

## Current Baseline

- Project path: `C:\Users\user\Desktop\ms`
- LDPlayer path: `C:\LDPlayer\LDPlayer9`
- LDPlayer command tool: `C:\LDPlayer\LDPlayer9\ldconsole.exe`
- LDPlayer ADB: `C:\LDPlayer\LDPlayer9\adb.exe`
- LDPlayer instance: index `0`, name `LDPlayer`
- ADB endpoint: `127.0.0.1:5555`
- ADB alternate serial: `emulator-5554`
- Resolution: `1280x720`
- DPI: `240`
- Global FPS cap: `60`
- AutoJs6 package: `org.autojs.autojs6`
- MapleStory Worlds package: `com.nexon.mod`
- Windows shared folder: `C:\Users\user\Documents\XuanZhi9\Pictures`
- Android shared folder: `/sdcard/Pictures`

## Completed Work

1. Created the project documentation structure:
   - `WORKFLOW.md`
   - `docs/ENVIRONMENT.md`
   - `docs/TOOLS_AND_INSTALLATION.md`
   - `docs/USAGE_AND_SHARING.md`
   - `docs/WORK_AND_DEVELOPMENT_METHOD.md`
   - `docs/RECORDING_RULES.md`
   - `logs/LEARNINGS.md`

2. Installed and verified AutoJs6:
   - Downloaded AutoJs6 APK.
   - Installed it into LDPlayer.
   - Enabled overlay and accessibility permissions.
   - Imported and ran `scripts/autojs6-test.js`.

3. Confirmed shared folder workflow:
   - Windows path: `C:\Users\user\Documents\XuanZhi9\Pictures`
   - Android path: `/sdcard/Pictures`

4. Installed and launched MapleStory Worlds:
   - Package: `com.nexon.mod`
   - Continued through Google Play/update flow.
   - Reached login and initial resource-download screens.

5. Set up LDPlayer ADB:
   - Enabled LDPlayer `ADB debugging > Local debugging`.
   - Validated `127.0.0.1:5555 device`.
   - Verified `wm size`, `wm density`, and `screencap/pull`.

6. Added TDD validation for ADB setup:
   - `tools/setup-ldplayer-adb.ps1`
   - `tests/test-ldplayer-adb-setup.ps1`

7. Added LDPlayer-only capture:
   - `tools/capture-ldplayer.ps1`
   - Uses Windows `PrintWindow` for non-obstructing LDPlayer capture.
   - ADB `screencap` remains preferred when ADB is healthy.

8. Tuned emulator settings:
   - Resolution changed from `1600x900` to `1280x720`.
   - DPI kept at `240`.
   - Global FPS cap set to `30`.

9. Created a reusable Codex skill:
   - Skill path: `C:\Users\user\.codex\skills\ldplayer-autojs6`
   - Skill name: `ldplayer-autojs6`
   - Includes core workflow, baseline reference, and reusable scripts.

10. Installed validation dependency and added skill tests:
   - Installed `PyYAML 6.0.3` for `quick_validate.py`.
   - Added `tests/test-ldplayer-autojs6-skill.ps1`.
   - Confirmed `quick_validate.py` reports `Skill is valid!`.

## Core Commands

Validate ADB:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\user\Desktop\ms\tools\setup-ldplayer-adb.ps1 -AdbPath C:\LDPlayer\LDPlayer9\adb.exe -Endpoint 127.0.0.1:5555
```

Run ADB tests:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\user\Desktop\ms\tests\test-ldplayer-adb-setup.ps1
```

Run skill tests:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\user\Desktop\ms\tests\test-ldplayer-autojs6-skill.ps1
```

Run official skill validation:

```powershell
python C:\Users\user\.codex\skills\.system\skill-creator\scripts\quick_validate.py C:\Users\user\.codex\skills\ldplayer-autojs6
```

Check resolution:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' list3 --index 0
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell wm size
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell wm density
```

Set resolution:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' modify --index 0 --resolution 1280,720,240
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' reboot --index 0
```

Set FPS:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' globalsetting --fps 60
```

Launch MapleStory Worlds:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' runapp --index 0 --packagename com.nexon.mod
```

Launch AutoJs6:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' runapp --index 0 --packagename org.autojs.autojs6
```

## Safety And Policy

- Use this project for personal, offline, testing, accessibility, and non-competitive automation.
- Do not build multiplayer farming, ranking, economy, trading, anti-cheat bypass, or unfair advantage automation.
- Use Google Play as the default app install/update source in LDPlayer.
- Pause for user login when Google Play or game login requires credentials.
- Do not use third-party APK/XAPK sources unless the user explicitly approves the source and trust tradeoff.

## Next Good Step

Before writing MapleStory Worlds automation, collect fresh screenshots and coordinates at the current `1280x720` baseline. Any coordinate script built before the resolution change should be recalibrated.
