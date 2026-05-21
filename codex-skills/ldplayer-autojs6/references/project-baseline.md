# Project Baseline

This reference summarizes the reusable LDPlayer + AutoJs6 automation state. Treat `<repo>` as the cloned repository root.

## Current Environment

- Host: Windows, PowerShell
- Project path: `<repo>`
- LDPlayer path: `C:\LDPlayer\LDPlayer9`
- LDPlayer version observed: `9.5.11.1`
- Instance: index `0`, name `LDPlayer`
- Console: `C:\LDPlayer\LDPlayer9\ldconsole.exe`
- ADB: `C:\LDPlayer\LDPlayer9\adb.exe`
- ADB endpoint: `127.0.0.1:5555`
- ADB alternate serial: `emulator-5554`
- Resolution: `1280x720`
- DPI: `240`
- Global FPS cap: `60`
- AutoJs6: `6.7.0`, package `org.autojs.autojs6`
- MapleStory Worlds package: `com.nexon.mod`

## Shared Folder

```text
Windows: %USERPROFILE%\Documents\XuanZhi9\Pictures
Android: /sdcard/Pictures
```

## Verification Commands

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' list3 --index 0
& 'C:\LDPlayer\LDPlayer9\adb.exe' connect 127.0.0.1:5555
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

## Common Commands

Launch MapleStory Worlds:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' runapp --index 0 --packagename com.nexon.mod
```

Launch AutoJs6:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' runapp --index 0 --packagename org.autojs.autojs6
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

Capture through ADB:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell screencap -p /sdcard/Pictures/shot.png
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 pull /sdcard/Pictures/shot.png .\downloads\shot.png
```

Dry-run an `A` key test:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\send-ldplayer-key.ps1 -Key A -Count 5 -IntervalMs 250 -DryRun
```

## Known Caveats

- LDPlayer ADB can be disabled by UI setting. Enable `Settings > Other > ADB debugging > Local debugging`.
- `adb connect` can return success-like output while the device remains `offline`; parse `adb devices`.
- Resolution changes require LDPlayer reboot before Android `wm size` changes.
- Some graphics surfaces may appear black/blank with Windows `PrintWindow`; use ADB screenshots or foreground capture.
- Google Play is the default install/update source for Android apps. Pause for user login when required.
- After an LDPlayer reboot, restart `/data/local/tmp/frida-server` through `su -c` before spawning protected apps with Frida.
- Use `tools\verify-frida-log.ps1` for Frida log smoke checks, and load `tools\frida-spoof-process-hardware.js` after the main bypass script when the target app process needs the SM-S921N-like hardware profile.
