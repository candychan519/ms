# Environment

이 문서는 LDPlayer + AutoJs6 자동화 환경 정보를 기록합니다.

## Host

- OS: Windows
- Project path: `C:\Users\user\Desktop\ms`
- Shell used by Codex: PowerShell
- Current working directory: `C:\Users\user\Desktop\ms`

## Emulator

- Emulator: LDPlayer 9
- Detected LDPlayer version: `LDPlayer 9.5.11.1`
- LDPlayer command tool: `C:\LDPlayer\LDPlayer9\ldconsole.exe`
- LDPlayer bundled ADB: `C:\LDPlayer\LDPlayer9\adb.exe`
- LDPlayer instance index: `0`
- LDPlayer instance name: `LDPlayer`
- Resolution: `1280x720`
- DPI: `240`
- Global FPS cap: `60`
- ADB endpoint: `127.0.0.1:5555`
- ADB emulator serial: `emulator-5554`
- ADB setting: LDPlayer Settings > Other > ADB debugging > Local debugging

Useful check command:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' list2
```

Observed output:

```text
0,LDPlayer,0,1280,720,240
```

ADB check commands:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' connect 127.0.0.1:5555
& 'C:\LDPlayer\LDPlayer9\adb.exe' devices -l
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell wm size
```

Observed working state:

```text
127.0.0.1:5555 device
emulator-5554  device
Physical size: 1280x720
Physical density: 240
```

FPS check:

```powershell
Select-String -Path C:\LDPlayer\LDPlayer9\vms\config\leidians.config -Pattern 'framesPerSecond'
```

Observed global setting:

```text
"framesPerSecond": 60
```

## Android Automation Runtime

- Runtime app: AutoJs6
- Installed version: `6.7.0`
- Package name used to run app: `org.autojs.autojs6`
- Overlay permission: enabled
- Accessibility service: enabled

Useful run command:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' runapp --index 0 --packagename org.autojs.autojs6
```

## Important Model

AutoJs6 does not run on Windows directly. It runs inside Android, inside LDPlayer.

```text
Windows
+-- LDPlayer
    +-- Android
        +-- target app or game
        +-- AutoJs6
            +-- .js script
```
