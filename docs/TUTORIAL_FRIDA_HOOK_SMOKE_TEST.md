# Run a Frida Hook Smoke Test in LDPlayer

In this tutorial, you will run a benchmark app through Frida, display the spoofed hardware values once, and then verify the captured log. By the end, you will know the difference between a visual value check and a headless target-app run.

## What you'll need

- LDPlayer running with ADB debugging set to local debugging.
- PowerShell 7 as `pwsh`.
- Frida CLI at `$env:USERPROFILE\AppData\Roaming\Python\Python313\Scripts\frida.exe`.
- Frida server at `/data/local/tmp/frida-server` inside LDPlayer.
- `downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js`.
- `tools\frida-spoof-process-hardware.js`.
- `downloads\frida\show-spoof-values.js`.
- HTTP Toolkit Android SSL Pinning Demo APK at `downloads\benchmarks\pinning-demo-v1.6.1.apk`.

## Step 1: Confirm ADB Sees LDPlayer

Run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\setup-ldplayer-adb.ps1 -AdbPath C:\LDPlayer\LDPlayer9\adb.exe -Endpoint 127.0.0.1:5555
```

You should see a connected device for `127.0.0.1:5555`. If the device is `offline`, reopen LDPlayer settings and enable:

```text
Settings > Other > ADB debugging > Local debugging
```

## Step 2: Install the Benchmark App

Run:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 install -r .\downloads\benchmarks\pinning-demo-v1.6.1.apk
```

You should see:

```text
Success
```

## Step 3: Restart Frida Server as Root

Run:

```powershell
& 'C:\LDPlayer\LDPlayer9\adb.exe' -s 127.0.0.1:5555 shell su -c '/data/local/tmp/frida-server >/dev/null 2>&1 &'
```

This makes Frida spawn and attach work again after an LDPlayer reboot.

## Step 4: Launch the Benchmark With the Visual Value Helper

Run:

```powershell
& "$env:USERPROFILE\AppData\Roaming\Python\Python313\Scripts\frida.exe" -U -f tech.httptoolkit.pinning_demo `
  -l .\downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js `
  -l .\tools\frida-spoof-process-hardware.js `
  -l .\downloads\frida\show-spoof-values.js `
  -o .\downloads\frida\httptoolkit-hardware-spoof.log
```

The app opens inside LDPlayer. The temporary value display should show the app-process-visible profile, including `SM-N935F`, `arm64-v8a`, `8` cores, `Mali-T880`, and `4294967296` total memory.

## Step 5: Verify the Captured Log

Leave the Frida process running long enough for the hooks to initialize. Then run this in another PowerShell window:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& '.\tools\verify-frida-log.ps1' -LogPath '.\downloads\frida\httptoolkit-hardware-spoof.log' -RequirePattern @('Process hardware profile spoof enabled','Runtime.availableProcessors spoof enabled: 8','ActivityManager.MemoryInfo spoof enabled','Mali-T880') -ForbidPattern @('FATAL EXCEPTION','Application Not Responding','ANR')"
```

You should see:

```text
PASS Frida log verification: <resolved-log-path>
```

## Step 6: Run the Target App Without the Visual Helper

For a normal `com.nexon.mod` run, omit `show-spoof-values.js`:

```powershell
& "$env:USERPROFILE\AppData\Roaming\Python\Python313\Scripts\frida.exe" -U -f com.nexon.mod `
  -l .\downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js `
  -l .\tools\frida-spoof-process-hardware.js `
  -o .\downloads\frida\nexon-hardware-spoof-headless.log
```

The app should open without a Frida value dialog on screen.

## Step 7: Verify the Headless Target Run

Run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& '.\tools\verify-frida-log.ps1' -LogPath '.\downloads\frida\nexon-hardware-spoof-headless.log' -RequirePattern @('Process hardware profile spoof enabled','Runtime.availableProcessors spoof enabled: 8','ActivityManager.MemoryInfo spoof enabled','Mali-T880','Bypassing OkHTTPv3.*m-api.nexon.com') -ForbidPattern @('FATAL EXCEPTION','ANR','Application Not Responding','spoof-values','Frida spoof values') -AllowWarningPattern @('TypeError: not a function')"
```

You should see a pass. If the known line 724 `TypeError: not a function` appears, the verifier reports it as an allowed warning.

## What you built

You now have a repeatable smoke test:

- A benchmark app run that can visibly show spoofed values.
- A log verification command that checks hook markers and crash markers.
- A headless `com.nexon.mod` command that keeps Frida values off the screen.

For exact parameter behavior, read [Frida Hook Verification Reference](FRIDA_HOOK_VERIFICATION_REFERENCE.md). For the design reasoning, read [Why Frida Verification Is App-Process Scoped](WHY_FRIDA_VERIFICATION_IS_APP_PROCESS_SCOPED.md).
