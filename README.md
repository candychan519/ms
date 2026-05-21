# LDPlayer AutoJs6 Automation Workspace

This repository stores the local workflow, scripts, tests, and Codex skill source for Android automation work using LDPlayer, AutoJs6, and ADB on Windows.

## Public Repository Notice

This is a public GitHub repository. Keep secrets, account credentials, private device data, screenshots with personal information, APK downloads, and Frida run logs out of Git.

## Current Baseline

- LDPlayer: `C:\LDPlayer\LDPlayer9`
- Instance: index `0`, name `LDPlayer`
- Resolution: `1280x720`
- DPI: `240`
- FPS: `60`
- ADB endpoint: `127.0.0.1:5555`
- AutoJs6 package: `org.autojs.autojs6`
- MapleStory Worlds package: `com.nexon.mod`
- Shared folder: `%USERPROFILE%\Documents\XuanZhi9\Pictures` -> `/sdcard/Pictures`

## Start Maple Console

Open the Maple console from the repository root:

```powershell
pwsh -STA -NoProfile -ExecutionPolicy Bypass -File .\tools\start-maple-console.ps1
```

Use `-TopMost` to keep the console above LDPlayer:

```powershell
pwsh -STA -NoProfile -ExecutionPolicy Bypass -File .\tools\start-maple-console.ps1 -TopMost
```

The console window title is `메이플 콘솔`. It includes the minimap coordinate watcher, three map profiles, `A 누르기`, `A→왼쪽+F v2`, and periodic `D` controls. For the full operating guide, read `docs/HOW_TO_USE_MAPLE_CONSOLE.md`.

## Frida Bypass Quick Start

Restart Frida server as root after every LDPlayer reboot:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell su -c '/data/local/tmp/frida-server >/dev/null 2>&1 &'
```

Run the MapleStory Worlds package (`com.nexon.mod`) with the main bypass script and the process hardware overlay:

```powershell
& "$env:USERPROFILE\AppData\Roaming\Python\Python313\Scripts\frida.exe" -U -f com.nexon.mod `
  -l .\downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js `
  -l .\tools\frida-spoof-process-hardware.js `
  -o .\downloads\frida\nexon-hardware-spoof-headless.log
```

Normal Maple runs should omit `downloads\frida\show-spoof-values.js` so Frida values do not appear on screen. Use that visual helper only for temporary benchmark checks.

Verify the Maple run log:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& '.\tools\verify-frida-log.ps1' -LogPath '.\downloads\frida\nexon-hardware-spoof-headless.log' -RequirePattern @('Process hardware profile spoof enabled','Runtime.availableProcessors spoof enabled: 8','ActivityManager.MemoryInfo spoof enabled','Mali-T880','Bypassing OkHTTPv3.*m-api.nexon.com') -ForbidPattern @('FATAL EXCEPTION','ANR','Application Not Responding','spoof-values','Frida spoof values') -AllowWarningPattern @('TypeError: not a function') -Json"
```

For benchmark setup, visible spoof-value checks, and the explanation of app-process-scoped verification, read `docs/HOW_TO_VERIFY_FRIDA_HOOKS.md`.

## Main Documents

- `WORKFLOW.md`: entrypoint and documentation map
- `MIGRATION.md`: restore this workspace on another Windows PC
- `docs/SESSION_SUMMARY_2026-05-16.md`: completed setup summary
- `docs/ENVIRONMENT.md`: current environment
- `docs/TOOLS_AND_INSTALLATION.md`: tools and install notes
- `docs/TUTORIAL_FRIDA_HOOK_SMOKE_TEST.md`: tutorial for the Frida benchmark smoke test
- `docs/HOW_TO_VERIFY_FRIDA_HOOKS.md`: how-to guide for benchmark and target-app Frida verification
- `docs/HOW_TO_USE_MAPLE_CONSOLE.md`: how-to guide for the Maple console and repeat controls
- `docs/FRIDA_HOOK_VERIFICATION_REFERENCE.md`: reference for the Frida log verifier and hardware overlay
- `docs/WHY_FRIDA_VERIFICATION_IS_APP_PROCESS_SCOPED.md`: explanation of the app-process-scoped verification model
- `docs/USAGE_AND_SHARING.md`: usage and shared folder workflow
- `docs/WORK_AND_DEVELOPMENT_METHOD.md`: TDD, multi-agent, and safety rules
- `logs/LEARNINGS.md`: append-only findings and decisions

## Tools And Tests

- `tools/setup-ldplayer-adb.ps1`
- `tools/capture-ldplayer.ps1`
- `tools/send-ldplayer-key.ps1`
- `tools/find-minimap-player-marker.ps1`
- `tools/start-maple-console.ps1`
- `tools/show-minimap-position-ui.ps1`
- `tools/install-codex-skill.ps1`
- `tools/verify-frida-log.ps1`
- `tools/frida-spoof-process-hardware.js`
- `tests/run-all.ps1`
- `tests/test-ldplayer-adb-setup.ps1`
- `tests/test-capture-ldplayer.ps1`
- `tests/test-find-minimap-player-marker.ps1`
- `tests/test-start-maple-console.ps1`
- `tests/test-install-codex-skill.ps1`
- `tests/test-ldplayer-autojs6-skill.ps1`
- `tests/test-send-ldplayer-key.ps1`
- `tests/test-verify-frida-log.ps1`
- `tests/test-frida-spoof-process-hardware.ps1`

## Skill Source

The reusable Codex skill is mirrored under:

```text
codex-skills/ldplayer-autojs6
```

The active local copy is installed at:

```text
%USERPROFILE%\.codex\skills\ldplayer-autojs6
```
