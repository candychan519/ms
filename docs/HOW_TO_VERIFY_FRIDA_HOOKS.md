# How to Verify Frida Hooks in LDPlayer

Use this guide when you want to prove that Frida hooks loaded, the target app stayed healthy, and the app process sees the intended spoofed hardware profile.

## Prerequisites

- LDPlayer ADB is reachable at `127.0.0.1:5555`.
- Frida server exists at `/data/local/tmp/frida-server` inside LDPlayer.
- The main bypass script exists at `downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js`.
- The hardware overlay exists at `tools\frida-spoof-process-hardware.js`.
- `tools\verify-frida-log.ps1` exists.
- Benchmark APKs are available when running repeatable smoke tests:
  - `downloads\benchmarks\pinning-demo-v1.6.1.apk`
  - `downloads\benchmarks\UnCrackable-Level1.apk`

## Install Benchmark Apps

Install the SSL pinning demo:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 install -r .\downloads\benchmarks\pinning-demo-v1.6.1.apk
```

Install OWASP UnCrackable L1:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 install -r .\downloads\benchmarks\UnCrackable-Level1.apk
```

Expected result: each command ends with `Success`.

## Restart Frida Server After LDPlayer Reboot

After every LDPlayer reboot, start Frida server through `su -c` before spawning protected apps:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell su -c '/data/local/tmp/frida-server >/dev/null 2>&1 &'
```

Run this when Frida reports:

```text
need Gadget to attach on jailed Android
```

## Verify SSL Hook Markers With HTTP Toolkit Demo

Start the benchmark app with the main bypass script:

```powershell
& "$env:USERPROFILE\AppData\Roaming\Python\Python313\Scripts\frida.exe" -U -f tech.httptoolkit.pinning_demo `
  -l .\downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js `
  -o .\downloads\frida\httptoolkit-pinning-fdciabdul.log
```

Trigger the demo app buttons that exercise HTTPS clients. Then verify the log:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& '.\tools\verify-frida-log.ps1' -LogPath '.\downloads\frida\httptoolkit-pinning-fdciabdul.log' -RequirePattern @('BypassNativeNow','Unpinning setup completed','Bypassing OkHTTPv3') -ForbidPattern @('FATAL EXCEPTION','Application Not Responding','ANR')"
```

Expected result:

```text
PASS Frida log verification: <resolved-log-path>
```

## Verify Root Detection Hooks With OWASP UnCrackable L1

Start OWASP UnCrackable L1 with the main bypass script:

```powershell
& "$env:USERPROFILE\AppData\Roaming\Python\Python313\Scripts\frida.exe" -U -f owasp.mstg.uncrackable1 `
  -l .\downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js `
  -o .\downloads\frida\uncrackable-l1-fdciabdul.log
```

Verify that root-detection hook markers appeared and crash markers did not:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& '.\tools\verify-frida-log.ps1' -LogPath '.\downloads\frida\uncrackable-l1-fdciabdul.log' -RequirePattern @('Anti Root Detect') -ForbidPattern @('FATAL EXCEPTION','Application Not Responding','ANR')"
```

Expected result:

```text
PASS Frida log verification: <resolved-log-path>
```

## Verify Hardware Spoof Values Visually

Use the HTTP Toolkit Demo when you want a quick visible check of the spoofed values:

```powershell
& "$env:USERPROFILE\AppData\Roaming\Python\Python313\Scripts\frida.exe" -U -f tech.httptoolkit.pinning_demo `
  -l .\downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js `
  -l .\tools\frida-spoof-process-hardware.js `
  -l .\downloads\frida\show-spoof-values.js `
  -o .\downloads\frida\httptoolkit-hardware-spoof.log
```

The visual helper is only for temporary inspection. It can show values such as:

- `SM-N935F`
- `arm64-v8a`
- `8` CPU cores
- `Mali-T880`
- `4294967296` total memory

Verify the same values in the log:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& '.\tools\verify-frida-log.ps1' -LogPath '.\downloads\frida\httptoolkit-hardware-spoof.log' -RequirePattern @('Process hardware profile spoof enabled','Runtime.availableProcessors spoof enabled: 8','ActivityManager.MemoryInfo spoof enabled','Mali-T880') -ForbidPattern @('FATAL EXCEPTION','Application Not Responding','ANR') -Json"
```

## Run `com.nexon.mod` Headless

For a normal target-app run, omit `downloads\frida\show-spoof-values.js` so no Frida values appear on screen:

```powershell
& "$env:USERPROFILE\AppData\Roaming\Python\Python313\Scripts\frida.exe" -U -f com.nexon.mod `
  -l .\downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js `
  -l .\tools\frida-spoof-process-hardware.js `
  -o .\downloads\frida\nexon-hardware-spoof-headless.log
```

Verify the headless target log:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& '.\tools\verify-frida-log.ps1' -LogPath '.\downloads\frida\nexon-hardware-spoof-headless.log' -RequirePattern @('Process hardware profile spoof enabled','Runtime.availableProcessors spoof enabled: 8','ActivityManager.MemoryInfo spoof enabled','Mali-T880','Bypassing OkHTTPv3.*m-api.nexon.com') -ForbidPattern @('FATAL EXCEPTION','ANR','Application Not Responding','spoof-values','Frida spoof values') -AllowWarningPattern @('TypeError: not a function') -Json"
```

Expected result:

- `Passed` is `true`.
- The app remains foreground as `com.nexon.mod/.MainActivity`.
- The screen does not show `Frida spoof values`.
- The known `TypeError: not a function` warning can appear as an allowed warning.

## Troubleshooting

If Frida reports `need Gadget to attach on jailed Android`, restart Frida server through `su -c`.

If values appear on screen during a normal app run, remove `downloads\frida\show-spoof-values.js` from the Frida command.

If ADB reports values that do not match `SM-N935F`, check from inside the app process instead. The overlay is app-process-scoped and does not change host-level LDPlayer identity.

If `verify-frida-log.ps1` fails a required pattern, inspect the log path first. A missing pattern usually means the hook did not load, the app did not exercise that API, or the command wrote to a different log file.

If `Application Not Responding`, `ANR`, or `FATAL EXCEPTION` appears, treat the run as failed even when some hook markers are present.

## Related

- [Frida Hook Verification Reference](FRIDA_HOOK_VERIFICATION_REFERENCE.md)
- [Run a Frida Hook Smoke Test in LDPlayer](TUTORIAL_FRIDA_HOOK_SMOKE_TEST.md)
- [Why Frida Verification Is App-Process Scoped](WHY_FRIDA_VERIFICATION_IS_APP_PROCESS_SCOPED.md)
