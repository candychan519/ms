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
Observed LDPlayer version: 9.5.11.1
LDPlayer install path: C:\LDPlayer\LDPlayer9
LDPlayer instance: index 0, name LDPlayer
Resolution: 1280x720
DPI: 240
FPS: 60
ADB endpoint: 127.0.0.1:5555
AutoJs6 package: org.autojs.autojs6
MapleStory Worlds package: com.nexon.mod
Windows shared folder: %USERPROFILE%\Documents\XuanZhi9\Pictures
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

Confirm Codex has been installed and run at least once on the target PC. The following path should exist after Codex initializes local skills:

```powershell
Test-Path "$env:USERPROFILE\.codex\skills"
```

If the official skill validator is unavailable on the target PC, restore the Codex environment first and restart Codex:

```powershell
Test-Path "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py"
```

Create local generated-artifact folders that are intentionally not tracked by Git:

```powershell
New-Item -ItemType Directory -Path .\downloads,.\screenshots -Force | Out-Null
```

## 3. Install And Configure LDPlayer

Install LDPlayer 9, then confirm this path exists:

```powershell
Test-Path C:\LDPlayer\LDPlayer9\ldconsole.exe
Test-Path C:\LDPlayer\LDPlayer9\adb.exe
```

The source PC used LDPlayer `9.5.11.1`. If a newer LDPlayer 9 build is installed, verify ADB, shared folder, and settings paths because LDPlayer can change config details between builds.

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
- Create `downloads/` if it does not exist.
- Download the AutoJs6 APK again on the target PC; APK files are intentionally not stored in Git.
- Install into LDPlayer.
- Enable overlay permission.
- Enable accessibility service.
- Import `scripts/autojs6-test.js` from `/sdcard/Pictures` after copying it to the shared folder.

Example AutoJs6 download command:

```powershell
New-Item -ItemType Directory -Path .\downloads -Force | Out-Null
$url = 'https://github.com/SuperMonster003/AutoJs6/releases/download/v6.7.0/autojs6-v6.7.0-x86_64-3d410022.apk'
$out = '.\downloads\autojs6-v6.7.0-x86_64-3d410022.apk'
curl.exe -L -C - -o $out $url
Get-Item $out | Select-Object FullName,Length
```

Install AutoJs6:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' installapp --index 0 --filename (Resolve-Path .\downloads\autojs6-v6.7.0-x86_64-3d410022.apk)
```

Install MapleStory Worlds through Google Play:

- Use Google Play as the default install/update source.
- Log in manually when Google Play or the game requires credentials.
- Do not use third-party APK/XAPK sources unless explicitly approved.

## 5. Restore The Codex Skill

Install the versioned skill into the active Codex skills folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\install-codex-skill.ps1
```

Restart Codex if `$ldplayer-autojs6` does not appear in the active skill list.

To verify what will be copied without writing:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\install-codex-skill.ps1 -DryRun
```

## 6. Verify The Migration

Validate ADB:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\setup-ldplayer-adb.ps1 -AdbPath C:\LDPlayer\LDPlayer9\adb.exe -Endpoint 127.0.0.1:5555
```

Run project tests:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1
```

Or run the checks individually:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-ldplayer-adb-setup.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-install-codex-skill.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-send-ldplayer-key.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-capture-ldplayer.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-ldplayer-autojs6-skill.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-ldplayer-autojs6-skill.ps1 -SkillRoot "$env:USERPROFILE\.codex\skills\ldplayer-autojs6"
```

Run official skill validation:

```powershell
python "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" "$env:USERPROFILE\.codex\skills\ldplayer-autojs6"
```

Check emulator state:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' list3 --index 0
& 'C:\LDPlayer\LDPlayer9\adb.exe' devices -l
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell wm size
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell wm density
Select-String -Path C:\LDPlayer\LDPlayer9\vms\config\leidians.config -Pattern 'framesPerSecond'
Select-String -Path C:\LDPlayer\LDPlayer9\vms\config\leidian0.config -Pattern 'basicSettings.fps'
```

Expected baseline:

```text
0,LDPlayer,0,1280,720,240
127.0.0.1:5555 device
Physical size: 1280x720
Physical density: 240
"framesPerSecond": 60
"basicSettings.fps": 60
```

Verify the LDPlayer shared folder:

```powershell
$shared = Join-Path $env:USERPROFILE 'Documents\XuanZhi9\Pictures'
New-Item -ItemType Directory -Path $shared -Force | Out-Null
Copy-Item .\scripts\autojs6-test.js (Join-Path $shared 'autojs6-test.js') -Force
Test-Path (Join-Path $shared 'autojs6-test.js')
```

Then import `/sdcard/Pictures/autojs6-test.js` in AutoJs6 and confirm the toast appears.

## 7. Known Non-Migrated State

These are intentionally not restored by Git:

- Google Play login
- Game login
- LDPlayer Android app data
- MapleStory Worlds resource downloads and in-game settings
- MapleStory Worlds update state
- downloaded APK files
- screenshots and captured images
- local Codex runtime state

Recreate these manually on the target PC.

## Safety Boundary

Use this workspace for personal, offline, testing, accessibility, and non-competitive automation. Do not build or run multiplayer farming, reward loops, ranking, economy, trading, anti-cheat bypass, or unfair advantage automation.
