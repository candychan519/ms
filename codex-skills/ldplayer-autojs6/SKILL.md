---
name: ldplayer-autojs6
description: Manage Android automation projects that use LDPlayer, AutoJs6, and ADB on Windows. Use when setting up or operating LDPlayer emulator automation, installing or running AutoJs6 scripts, validating LDPlayer ADB, changing emulator resolution/FPS, capturing LDPlayer screenshots, syncing scripts through the shared folder, or documenting this workflow.
---

# LDPlayer AutoJs6

## Baseline

Use this skill for the user's Windows + LDPlayer + AutoJs6 automation workflow.

Current known defaults for `C:\Users\user\Desktop\ms`:

- LDPlayer: `C:\LDPlayer\LDPlayer9`
- Console: `C:\LDPlayer\LDPlayer9\ldconsole.exe`
- ADB: `C:\LDPlayer\LDPlayer9\adb.exe`
- Instance: index `0`, name `LDPlayer`
- ADB endpoint: `127.0.0.1:5555`
- Alternate ADB serial: `emulator-5554`
- Resolution: `1280x720`
- DPI: `240`
- Global FPS cap: `60`
- Windows shared folder: `C:\Users\user\Documents\XuanZhi9\Pictures`
- Android shared folder: `/sdcard/Pictures`
- AutoJs6 package: `org.autojs.autojs6`
- MapleStory Worlds package: `com.nexon.mod`

## Safety Boundary

Keep automation scoped to personal, offline, testing, accessibility, and non-competitive workflows.

Do not build or assist with multiplayer farming, ranking, economy, trading, anti-cheat bypass, or automation that gives unfair advantage over other users.

## Standard Workflow

1. Read the project docs before changing behavior:
   - `C:\Users\user\Desktop\ms\WORKFLOW.md`
   - `C:\Users\user\Desktop\ms\docs\ENVIRONMENT.md`
   - `C:\Users\user\Desktop\ms\docs\TOOLS_AND_INSTALLATION.md`
   - `C:\Users\user\Desktop\ms\docs\USAGE_AND_SHARING.md`
   - `C:\Users\user\Desktop\ms\docs\WORK_AND_DEVELOPMENT_METHOD.md`
   - `C:\Users\user\Desktop\ms\logs\LEARNINGS.md`
2. Prefer LDPlayer's bundled ADB over other `adb.exe` installations.
3. Validate ADB before relying on screenshots, input, file sync, or app launch.
4. Use short visual checks:
   - simple tap/navigation: `0.5-1.5` seconds
   - normal UI transition: `1-3` seconds
   - app launch: `3-7` seconds, then re-check
   - downloads/updates/network work: repeat `5-10` second checks
5. Update the stable docs when environment, tools, install flow, usage flow, sharing path, work method, or development method changes.
6. Append new findings, mistakes, workarounds, and verification results to `logs/LEARNINGS.md`.

## ADB

Validate the current LDPlayer ADB endpoint:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\user\Desktop\ms\tools\setup-ldplayer-adb.ps1 -AdbPath C:\LDPlayer\LDPlayer9\adb.exe -Endpoint 127.0.0.1:5555
```

Or use the bundled skill copy:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\user\.codex\skills\ldplayer-autojs6\scripts\setup-ldplayer-adb.ps1 -AdbPath C:\LDPlayer\LDPlayer9\adb.exe -Endpoint 127.0.0.1:5555
```

Manual checks:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' connect 127.0.0.1:5555
& 'C:\LDPlayer\LDPlayer9\adb.exe' devices -l
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell wm size
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell wm density
```

Treat `offline` as failure even when `adb.exe` exits with code `0`.

If ADB is off in LDPlayer, set:

```text
LDPlayer Settings > Other > ADB debugging > Local debugging
```

## Resolution And FPS

Change resolution:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' modify --index 0 --resolution 1280,720,240
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' reboot --index 0
```

Verify after reboot:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' list3 --index 0
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell wm size
```

Change FPS cap:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' globalsetting --fps 60
```

Verify saved FPS:

```powershell
Select-String -Path C:\LDPlayer\LDPlayer9\vms\config\leidians.config -Pattern 'framesPerSecond'
```

The current baseline keeps both the global cap and per-instance preset at `60`.

## Screenshots

Prefer ADB screenshots when ADB is healthy:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell screencap -p /sdcard/Pictures/shot.png
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 pull /sdcard/Pictures/shot.png C:\Users\user\Desktop\ms\downloads\shot.png
```

Use non-obstructing Windows capture when the user is working in another window:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\user\Desktop\ms\tools\capture-ldplayer.ps1
```

If `PrintWindow` returns black/blank for graphics surfaces, use ADB `screencap` or briefly foreground LDPlayer and capture the screen region.

## Bounded Key Input

Use `send-ldplayer-key.ps1` only for short testing/accessibility/private workflows. Do not use it for multiplayer farming, reward loops, ranking, economy, or anti-cheat bypass.

Dry-run a repeated `A` key sequence:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\user\Desktop\ms\tools\send-ldplayer-key.ps1 -Key A -Count 5 -IntervalMs 250 -DryRun
```

Send a short bounded sequence:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\user\Desktop\ms\tools\send-ldplayer-key.ps1 -Key A -Count 5 -IntervalMs 250
```

The tool rejects unbounded runs. `DurationSeconds` is capped by `MaxDurationSeconds` and defaults to a maximum of `30` seconds.

## AutoJs6 Script Flow

1. Edit scripts under `C:\Users\user\Desktop\ms\scripts`.
2. Copy them to `C:\Users\user\Documents\XuanZhi9\Pictures`.
3. Import from `/sdcard/Pictures` in AutoJs6.
4. Run small tests before long loops.
5. Always include a stop condition for repeated actions.

## App Install Policy

Use Google Play as the default source for Android apps and updates in LDPlayer.

If Google Play requires login, pause and let the user log in manually. Do not use third-party APK/XAPK sources unless the user explicitly approves the source and accepts the trust tradeoff.

## TDD And Multi-Agent

For reusable PowerShell helpers:

1. Add or update a focused test under `C:\Users\user\Desktop\ms\tests`.
2. Run the test and observe the failure or missing behavior.
3. Implement the smallest practical change under `tools` or `scripts`.
4. Re-run the test.
5. Run one live LDPlayer validation when the helper touches ADB, screenshots, shared folders, app launch, resolution, or FPS.

When the user asks for multi-agent work, split roles:

- Explorer: read-only inspection of LDPlayer, logs, ports, docs, and current system state.
- Worker: bounded implementation in disjoint files, usually `tools` and `tests`.
- Main agent: live setup, integration, verification, docs, and final report.

## Reference

For a concise baseline and command reference, read `references/project-baseline.md` when needed.
