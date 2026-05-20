# Frida Hook Verification Reference

This reference describes the project Frida verification helpers and the hardware spoof overlay. Use it when you need exact parameters, expected profile values, or the hook surface that is covered by tests.

## Public Surface

### `tools\verify-frida-log.ps1`

Verifies a captured Frida log with required regex patterns, forbidden regex patterns, and allowed warning patterns.

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\verify-frida-log.ps1 `
  -LogPath .\downloads\frida\<log>.log `
  -RequirePattern @('<required-regex>') `
  -ForbidPattern @('<forbidden-regex>') `
  -AllowWarningPattern @('<allowed-warning-regex>') `
  -Json
```

Parameters:

| Parameter | Type | Required | Default | Effect |
|---|---|---:|---|---|
| `LogPath` | `string` | Yes | none | Path to the Frida log file. The command fails if the file does not exist. |
| `RequirePattern` | `string[]` | No | empty array | Each regex must match at least once. Missing required patterns fail the check. |
| `ForbidPattern` | `string[]` | No | empty array | Each regex must match zero times. Present forbidden patterns fail the check. |
| `AllowWarningPattern` | `string[]` | No | empty array | Matching warnings are reported but do not fail the check. |
| `Json` | `switch` | No | off | Emits JSON instead of text. |

Text output starts with `PASS Frida log verification:` or `FAIL Frida log verification:`. Failure exits with code `1`.

JSON output contains:

| Field | Meaning |
|---|---|
| `Passed` | Boolean pass/fail result. |
| `LogPath` | Resolved absolute log path. |
| `Required` | Pattern summaries with counts and up to 3 sample lines. |
| `Forbidden` | Pattern summaries with counts and up to 3 sample lines. |
| `Warnings` | Allowed warning pattern summaries that matched. |
| `Failures` | Human-readable failure reasons. |

### `tools\frida-spoof-process-hardware.js`

Loads after the main LDPlayer bypass script when the target app process should see a coherent SM-N935F-like hardware profile.

```powershell
& "$env:USERPROFILE\AppData\Roaming\Python\Python313\Scripts\frida.exe" -U -f com.nexon.mod `
  -l .\downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js `
  -l .\tools\frida-spoof-process-hardware.js `
  -o .\downloads\frida\nexon-hardware-spoof-headless.log
```

Load order matters. Put `tools\frida-spoof-process-hardware.js` after the main bypass script so the overlay can refresh hardware values that the main script may also touch.

## Hardware Profile

| Area | Value |
|---|---|
| Model | `SM-N935F` |
| Manufacturer / brand | `samsung` |
| Device | `gracerlte` |
| Product | `gracerltexx` |
| Hardware | `samsungexynos8890` |
| CPU ABI | `arm64-v8a` |
| Supported ABIs | `arm64-v8a`, `armeabi-v7a`, `armeabi` |
| CPU cores | `8` |
| CPU family | ARM64 through `android_getCpuFamily` |
| GPU vendor | `ARM` |
| GPU renderer | `Mali-T880` |
| GPU version | `OpenGL ES 3.2` |
| Total memory | `4294967296` bytes |
| Available memory | `2147483648` bytes |
| Memory threshold | `268435456` bytes |
| Low memory | `false` |

## Hook Surface

The overlay covers Java and native reads that apps commonly use for device and hardware checks.

Java hooks:

| Surface | Hooked values |
|---|---|
| `android.os.Build` | Build identity fields, CPU ABI fields, supported ABI arrays |
| `java.lang.Runtime.availableProcessors()` | Returns `8` |
| `android.app.ActivityManager.getMemoryInfo()` | Patches total, available, threshold, and low-memory values |
| `android.os.SystemProperties` | `get`, `getInt`, `getLong`, and native getter overloads for CPU/GPU/build properties |
| `android.opengl.GLES10/20/30/31/32.glGetString()` | GPU vendor, renderer, and version strings |
| `javax.microedition.khronos.opengles.GL10.glGetString()` | GPU vendor, renderer, and version strings |

Native hooks:

| Surface | Hooked values |
|---|---|
| `__system_property_get` | CPU ABI, CPU ABI lists, hardware, EGL, OpenGL ES, fingerprint |
| `glGetString` | GPU vendor, renderer, and version strings |
| `android_getCpuFamily` | ARM64 family value |
| `android_getCpuCount` | `8` |

The overlay also refreshes `android.os.Build` values after `500ms`, `1500ms`, and `3000ms`. This keeps the overlay in control when delayed hooks from the main bypass script write Build fields later in app startup.

## Tested Assertions

`tests\test-verify-frida-log.ps1` checks that:

- A good log passes when required patterns are present.
- A bad log fails when required patterns are missing or forbidden patterns are present.
- Allowed warnings are reported without failing the check.
- JSON output reports `Passed=true` for the good log.

`tests\test-frida-spoof-process-hardware.ps1` checks that the overlay contains hooks for:

- `Runtime.availableProcessors`
- `ActivityManager.getMemoryInfo`
- GLES `glGetString`
- Native `__system_property_get`
- `Build.CPU_ABI` and `Build.SUPPORTED_ABIS`
- `SystemProperties` native getters
- `arm64-v8a`, `Mali-T880`, and `4294967296`

## Limitations

This overlay changes what the instrumented app process sees through hooked Java and native APIs. It does not globally change LDPlayer. ADB shell commands, host tools, and other processes can still report the original emulator values.

## Related

- [How to Verify Frida Hooks in LDPlayer](HOW_TO_VERIFY_FRIDA_HOOKS.md)
- [Run a Frida Hook Smoke Test in LDPlayer](TUTORIAL_FRIDA_HOOK_SMOKE_TEST.md)
- [Why Frida Verification Is App-Process Scoped](WHY_FRIDA_VERIFICATION_IS_APP_PROCESS_SCOPED.md)
- [Tools And Installation](TOOLS_AND_INSTALLATION.md)
