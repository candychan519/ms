---
name: ldplayer-autojs6
description: Manage Android automation projects that use LDPlayer, AutoJs6, and ADB on Windows. Use when setting up or operating LDPlayer emulator automation, installing or running AutoJs6 scripts, validating LDPlayer ADB, changing emulator resolution/FPS, capturing LDPlayer screenshots, syncing scripts through the shared folder, or documenting this workflow.
---

# LDPlayer AutoJs6

## Baseline

Use this skill for the user's Windows + LDPlayer + AutoJs6 automation workflow.

Current known defaults for this project. Treat `<repo>` as the cloned repository root on the current PC.

- LDPlayer: `C:\LDPlayer\LDPlayer9`
- Console: `C:\LDPlayer\LDPlayer9\ldconsole.exe`
- ADB: `C:\LDPlayer\LDPlayer9\adb.exe`
- Instance: index `0`, name `LDPlayer`
- ADB endpoint: `127.0.0.1:5555`
- Alternate ADB serial: `emulator-5554`
- Resolution: `1280x720`
- DPI: `240`
- Global FPS cap: `60`
- Windows shared folder: `%USERPROFILE%\Documents\XuanZhi9\Pictures`
- Android shared folder: `/sdcard/Pictures`
- AutoJs6 package: `org.autojs.autojs6`
- MapleStory Worlds package: `com.nexon.mod`

## Standard Workflow

1. Read the project docs before changing behavior:
   - `<repo>\WORKFLOW.md`
   - `<repo>\MIGRATION.md`
   - `<repo>\docs\ENVIRONMENT.md`
   - `<repo>\docs\TOOLS_AND_INSTALLATION.md`
   - `<repo>\docs\USAGE_AND_SHARING.md`
   - `<repo>\docs\WORK_AND_DEVELOPMENT_METHOD.md`
   - `<repo>\docs\RECORDING_RULES.md`
   - `<repo>\logs\LEARNINGS.md`
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
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\setup-ldplayer-adb.ps1 -AdbPath C:\LDPlayer\LDPlayer9\adb.exe -Endpoint 127.0.0.1:5555
```

Or use the bundled skill copy:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\ldplayer-autojs6\scripts\setup-ldplayer-adb.ps1" -AdbPath C:\LDPlayer\LDPlayer9\adb.exe -Endpoint 127.0.0.1:5555
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
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 pull /sdcard/Pictures/shot.png .\downloads\shot.png
```

Use non-obstructing Windows capture when the user is working in another window:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\capture-ldplayer.ps1
```

If `PrintWindow` returns black/blank for graphics surfaces, use ADB `screencap` or briefly foreground LDPlayer and capture the screen region.

## Minimap Player Marker

Use `find-minimap-player-marker.ps1` to detect the yellow MapleStory Worlds player marker in the top-left minimap. It reports minimap-local coordinates, normalized minimap percentages, and full-screen coordinates.

Analyze a saved screenshot:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\find-minimap-player-marker.ps1 -ImagePath .\screenshots\ldplayer-current-pull.png
```

Watch live LDPlayer coordinates with ADB `screencap`:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\find-minimap-player-marker.ps1 -Watch -IntervalMs 500
```

Open the Maple console:

```powershell
pwsh -STA -NoProfile -ExecutionPolicy Bypass -File .\tools\start-maple-console.ps1
```

`start-maple-console.ps1` is the canonical Maple console. It should keep the current coordinate display plus the repeat controls: `A 누르기`, `A→왼쪽+F v2`, `D 사용`, `D 간격`, and the three map profiles `빅토리아로드 헤네시스동쪽풀숲`, `선셋로드 사헬지대2`, and `선셋로드 꿈꾸는 사막`. Do not replace it with a coordinate-only UI; create a separate helper if a temporary coordinate view is needed. `show-minimap-position-ui.ps1` is only a legacy wrapper for older commands.

Use minimap-local coordinates for conversation, for example `minimap=(65,49)`.

When changing this console, keep these copies synchronized:

- `<repo>\tools\start-maple-console.ps1`
- `<repo>\codex-skills\ldplayer-autojs6\scripts\start-maple-console.ps1`
- `%USERPROFILE%\.codex\skills\ldplayer-autojs6\scripts\start-maple-console.ps1` when operating the installed skill locally
- Keep `show-minimap-position-ui.ps1` as a wrapper that forwards to `start-maple-console.ps1`.

Run `tests\test-start-maple-console.ps1` and inspect a real `메이플 콘솔` screenshot before reporting that the UI is fixed. UI Automation name checks do not prove Korean text is unclipped.

## Bounded Key Input

Use `send-ldplayer-key.ps1` for short input checks.

Dry-run a repeated `A` key sequence:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\send-ldplayer-key.ps1 -Key A -Count 5 -IntervalMs 250 -DryRun
```

Send a short bounded key sequence:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\send-ldplayer-key.ps1 -Key A -Count 5 -IntervalMs 250
```

The tool rejects unbounded runs. `DurationSeconds` is capped by `MaxDurationSeconds` and defaults to a maximum of `30` seconds.

## AutoJs6 Script Flow

1. Edit scripts under `<repo>\scripts`.
2. Copy them to `%USERPROFILE%\Documents\XuanZhi9\Pictures`.
3. Import from `/sdcard/Pictures` in AutoJs6.
4. Run small tests before long loops.
5. Always include a stop condition for repeated actions.

## Frida Verification

Attach broad Frida bypass scripts to the protected target app process, not to AutoJs6. Keep AutoJs6 for UI automation and use Frida against the app under test, such as `com.nexon.mod`.

Use benchmark apps for repeatable smoke tests when validating hook behavior:

- HTTP Toolkit Android SSL Pinning Demo for SSL/pinning hook checks.
- OWASP UnCrackable L1 for root-detection hook checks.

Verify captured Frida logs with:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-frida-log.ps1 -LogPath .\downloads\frida\<log>.log
```

When the app process should see a coherent SM-N935F-like profile, load the hardware overlay after the main bypass script:

```powershell
& "$env:USERPROFILE\AppData\Roaming\Python\Python313\Scripts\frida.exe" -U -f com.nexon.mod `
  -l .\downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js `
  -l .\tools\frida-spoof-process-hardware.js `
  -o .\downloads\frida\nexon-hardware-spoof-headless.log
```

For temporary on-screen spoof-value inspection, add `downloads\frida\show-spoof-values.js`. Omit it for normal headless target-app runs.

After an LDPlayer reboot, restart Frida server as root before spawning protected apps:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell su -c '/data/local/tmp/frida-server >/dev/null 2>&1 &'
```

## App Install Policy

Use Google Play as the default source for Android apps and updates in LDPlayer.

If Google Play requires login, pause and let the user log in manually. Do not use third-party APK/XAPK sources unless the user explicitly approves the source and accepts the trust tradeoff.

## TDD And Multi-Agent

For reusable PowerShell helpers:

1. Add or update a focused test under `<repo>\tests`.
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
