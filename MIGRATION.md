# Migration Guide

Use this guide to restore this LDPlayer + AutoJs6 automation workspace on another Windows PC.

## What Is In Git

The private GitHub repository contains:

- Project documentation and workflow notes
- PowerShell tools under `tools/`
- PowerShell tests under `tests/`
- AutoJs6 test script under `scripts/`
- Reusable Codex skill source under `codex-skills/ldplayer-autojs6`
- Learning log under `logs/LEARNINGS.md`

The repository intentionally excludes:

- `downloads/`
- APK/XAPK/APKS files
- screenshots and image captures
- `.env`, token, and key files
- editor and OS noise

## Baseline To Recreate

```text
OS: Windows
LDPlayer: LDPlayer 9
LDPlayer install path: C:\LDPlayer\LDPlayer9
LDPlayer instance: index 0, name LDPlayer
Resolution: 1280x720
DPI: 240
FPS: 60
ADB endpoint: 127.0.0.1:5555
AutoJs6 package: org.autojs.autojs6
MapleStory Worlds package: com.nexon.mod
Windows shared folder: C:\Users\user\Documents\XuanZhi9\Pictures
Android shared folder: /sdcard/Pictures
```

## 1. Clone The Repository

```powershell
git clone https://github.com/candychan519/ms.git
cd ms
```

If GitHub CLI is preferred:

```powershell
gh repo clone candychan519/ms
cd ms
```

## 2. Install Required Windows Tools

Install Git if missing:

```powershell
winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements
```

Install GitHub CLI if missing:

```powershell
winget install --id GitHub.cli -e --accept-package-agreements --accept-source-agreements
```

Install Python if missing:

```powershell
winget install --id Python.Python.3.13 -e --accept-package-agreements --accept-source-agreements
```

Install the skill validation dependency:

```powershell
python -m pip install PyYAML
```

## 3. Install And Configure LDPlayer

Install LDPlayer 9, then confirm this path exists:

```powershell
Test-Path C:\LDPlayer\LDPlayer9\ldconsole.exe
Test-Path C:\LDPlayer\LDPlayer9\adb.exe
```

Set the emulator baseline:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' modify --index 0 --resolution 1280,720,240
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' globalsetting --fps 60
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' reboot --index 0
```

Enable ADB inside LDPlayer:

```text
LDPlayer Settings > Other > ADB debugging > Local debugging
```

## 4. Install Android Apps

Install AutoJs6 inside LDPlayer.

Preferred flow:

- Use the documented AutoJs6 release in `docs/TOOLS_AND_INSTALLATION.md`.
- Install into LDPlayer.
- Enable overlay permission.
- Enable accessibility service.
- Import `scripts/autojs6-test.js` from `/sdcard/Pictures` after copying it to the shared folder.

Install MapleStory Worlds through Google Play:

- Use Google Play as the default install/update source.
- Log in manually when Google Play or the game requires credentials.
- Do not use third-party APK/XAPK sources unless explicitly approved.

## 5. Restore The Codex Skill

Copy the versioned skill into the active Codex skills folder:

```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\.codex\skills" -Force | Out-Null
Copy-Item -Recurse -Force .\codex-skills\ldplayer-autojs6 "$env:USERPROFILE\.codex\skills\ldplayer-autojs6"
```

Restart Codex if `$ldplayer-autojs6` does not appear in the active skill list.

## 6. Verify The Migration

Validate ADB:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\setup-ldplayer-adb.ps1 -AdbPath C:\LDPlayer\LDPlayer9\adb.exe -Endpoint 127.0.0.1:5555
```

Run project tests:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-ldplayer-adb-setup.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-send-ldplayer-key.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-ldplayer-autojs6-skill.ps1
```

Run official skill validation:

```powershell
python C:\Users\user\.codex\skills\.system\skill-creator\scripts\quick_validate.py "$env:USERPROFILE\.codex\skills\ldplayer-autojs6"
```

Check emulator state:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' list3 --index 0
& 'C:\LDPlayer\LDPlayer9\adb.exe' devices -l
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell wm size
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell wm density
Select-String -Path C:\LDPlayer\LDPlayer9\vms\config\leidians.config -Pattern 'framesPerSecond'
```

Expected baseline:

```text
0,LDPlayer,0,1280,720,240
127.0.0.1:5555 device
Physical size: 1280x720
Physical density: 240
"framesPerSecond": 60
```

## 7. Known Non-Migrated State

These are intentionally not restored by Git:

- Google Play login
- Game login
- LDPlayer Android app data
- downloaded APK files
- screenshots and captured images
- local Codex runtime state

Recreate these manually on the target PC.

## Safety Boundary

Use this workspace for personal, offline, testing, accessibility, and non-competitive automation. Do not build or run multiplayer farming, reward loops, ranking, economy, trading, anti-cheat bypass, or unfair advantage automation.
