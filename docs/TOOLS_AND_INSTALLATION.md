# Tools And Installation

이 문서는 작업 도구와 설치 방법을 기록합니다.

## Tools

- `ldconsole.exe`: LDPlayer 인스턴스 제어, 앱 설치, 앱 실행, ADB 명령 호출
- AutoJs6: Android 안에서 `.js` 자동화 스크립트 실행
- PowerShell: Windows 쪽 파일 복사, 상태 확인, 명령 실행
- GitHub Releases: AutoJs6 APK 다운로드 출처
- Windows Explorer shared folder: LDPlayer와 스크립트 파일 공유

## Installed PowerShell

- Version: `7.6.1`
- Command: `pwsh`
- Install source: `winget` package `Microsoft.PowerShell`
- Use `pwsh` for project helper scripts, tests, and UI launch. Windows PowerShell 5.1 remains available as `powershell`.

## Installed AutoJs6

- Version: `v6.7.0`
- APK file: `<repo>\downloads\autojs6-v6.7.0-x86_64-3d410022.apk`
- Source: `https://github.com/SuperMonster003/AutoJs6/releases/tag/v6.7.0`
- APK asset: `autojs6-v6.7.0-x86_64-3d410022.apk`

## Download Method Used

The first `Invoke-WebRequest` download timed out after 5 minutes, leaving a partial file. The download was resumed with `curl.exe`.

```powershell
$url = 'https://github.com/SuperMonster003/AutoJs6/releases/download/v6.7.0/autojs6-v6.7.0-x86_64-3d410022.apk'
$out = '.\downloads\autojs6-v6.7.0-x86_64-3d410022.apk'
curl.exe -L -C - -o $out $url
```

## Install Method Used

AutoJs6 was installed into LDPlayer instance `0`.

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' installapp --index 0 --filename (Resolve-Path .\downloads\autojs6-v6.7.0-x86_64-3d410022.apk)
```

## Android App Installation Policy

For regular Android apps and games in LDPlayer, use Google Play as the default installation and update source.

Policy:

- Prefer Google Play installs and updates.
- If Google Play login is required, pause and let the user log in.
- Do not use third-party APK/XAPK sources unless the user explicitly approves that source and accepts the trust tradeoff.
- LD Store can be used for discovery or temporary install checks, but Google Play is the preferred final install/update path.

Current MapleStory Worlds note:

- Package: `com.nexon.mod`
- LD Store installed version: `1.24.0`
- App startup required a newer update.
- The update path opened Google Play, which required user login.

## Verification

AutoJs6 was verified by:

- Seeing the `AutoJs6` icon on the LDPlayer home screen.
- Running the app from `ldconsole.exe`.
- Enabling required permissions.
- Importing and running `autojs6-test`.

Frida hook verification uses `tools/verify-frida-log.ps1` against logs produced by benchmark apps. The helper checks required hook markers, forbidden crash/ANR markers, and allowed warnings.

Benchmark APKs used:

- HTTP Toolkit Android SSL Pinning Demo `v1.6.1`: `downloads\benchmarks\pinning-demo-v1.6.1.apk`
- OWASP UnCrackable L1: `downloads\benchmarks\UnCrackable-Level1.apk`

Example log verification:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& '.\tools\verify-frida-log.ps1' -LogPath '.\downloads\frida\httptoolkit-pinning-fdciabdul.log' -RequirePattern @('BypassNativeNow','Unpinning setup completed','Bypassing OkHTTPv3') -ForbidPattern @('FATAL EXCEPTION','Application Not Responding','ANR')"
```

### Frida Hardware Profile Overlay

Use `tools\frida-spoof-process-hardware.js` after the main bypass script when the app process should see a coherent SM-N935F-like hardware profile:

- CPU ABI: `arm64-v8a`
- CPU cores: `8`
- GPU: `ARM / Mali-T880 / OpenGL ES 3.2`
- Memory: `4294967296` bytes total, `2147483648` bytes available

Example launch:

```powershell
& "$env:USERPROFILE\AppData\Roaming\Python\Python313\Scripts\frida.exe" -U -f tech.httptoolkit.pinning_demo `
  -l .\downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js `
  -l .\tools\frida-spoof-process-hardware.js `
  -l .\downloads\frida\show-spoof-values.js `
  -o .\downloads\frida\httptoolkit-hardware-spoof.log
```

For MapleStory Worlds, replace `tech.httptoolkit.pinning_demo` with `com.nexon.mod`.

For normal headless target-app runs, omit `downloads\frida\show-spoof-values.js`; that script is only for temporarily displaying the spoofed values on screen.

After an LDPlayer reboot, restart Frida server as root before spawning protected apps. If Frida reports `need Gadget to attach on jailed Android`, run:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell su -c '/data/local/tmp/frida-server >/dev/null 2>&1 &'
```

## Required Permissions

- Overlay permission: needed for AutoJs6 floating controls and UI behavior.
- Accessibility service: needed for `auto.waitFor()`, `click`, `press`, `swipe`, and UI automation.
- Screen capture permission: needed later for image/color/OCR automation with APIs such as `requestScreenCapture()`.

## ADB Setup

LDPlayer's bundled ADB is the default ADB for this project. Do not mix it with Android Studio platform-tools unless there is a specific reason.

Current setup:

- ADB path: `C:\LDPlayer\LDPlayer9\adb.exe`
- LDPlayer UI setting: Settings > Other > ADB debugging > Local debugging
- Primary endpoint: `127.0.0.1:5555`
- Alternate serial shown by LDPlayer: `emulator-5554`

Setup and validation command:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\setup-ldplayer-adb.ps1 -AdbPath C:\LDPlayer\LDPlayer9\adb.exe -Endpoint 127.0.0.1:5555
```

Manual checks:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' connect 127.0.0.1:5555
& 'C:\LDPlayer\LDPlayer9\adb.exe' devices -l
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell wm size
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' adb --index 0 --command "shell wm size"
```

Screen capture through ADB:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell screencap -p /sdcard/Pictures/adb-test.png
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 pull /sdcard/Pictures/adb-test.png .\downloads\adb-test.png
```

## LDPlayer FPS

Use LDPlayer's global setting command to cap emulator FPS:

```powershell
& 'C:\LDPlayer\LDPlayer9\ldconsole.exe' globalsetting --fps 60
```

Verify the saved global setting:

```powershell
Select-String -Path C:\LDPlayer\LDPlayer9\vms\config\leidians.config -Pattern 'framesPerSecond'
```

Current saved value:

```text
"framesPerSecond": 60
```

If the running instance does not visibly apply the saved FPS immediately, restart LDPlayer after saving the setting. The per-instance display preset and global cap should both be `60` for the current baseline.

## Skill Validation Dependencies

Codex skill validation uses the system `skill-creator` validator:

```powershell
python "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" "$env:USERPROFILE\.codex\skills\ldplayer-autojs6"
```

This validator requires `PyYAML`.

Installed dependency:

```text
PyYAML 6.0.3
```

Install command used:

```powershell
python -m pip install PyYAML
```

Project test for the skill:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\test-ldplayer-autojs6-skill.ps1
```
