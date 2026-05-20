# Why Frida Verification Is App-Process Scoped

Frida hooks in this project are verified from the target app process because that is where the app reads device, graphics, memory, root, and networking signals. Host-level LDPlayer values can remain unchanged while the instrumented app process sees the spoofed values.

## The problem

There are three different places that can report device state:

```text
Windows host
  -> LDPlayer emulator
      -> Android shell and system services
          -> target app process hooked by Frida
```

ADB shell commands and host tools usually report LDPlayer's real emulator identity. That is useful for managing the environment, but it does not prove what a hooked app process sees.

AutoJs6 is also not the right verification target for broad Frida bypass scripts. Earlier runs showed that attaching the broad bypass script to AutoJs6 could crash or hang AutoJs6. AutoJs6 should stay responsible for UI automation. Frida should attach to the protected app process that needs the hooks.

## The approach

The current flow separates three jobs:

| Job | Tool | Why |
|---|---|---|
| UI automation | AutoJs6 | Runs Android UI scripts inside LDPlayer. |
| Hook application | Frida attached to the target package | Changes what the protected app process sees. |
| Verification | Benchmark apps, logs, and `verify-frida-log.ps1` | Proves hooks loaded and the app stayed healthy. |

The hardware profile overlay is a separate Frida script loaded after the main bypass script. This keeps the original bypass script unchanged while adding a coherent app-process-visible profile:

```text
fdciabdul-frida-multiple-bypass-ldplayer.js
  -> broad bypass, SSL, root, display, command hooks

tools/frida-spoof-process-hardware.js
  -> CPU ABI, core count, GPU strings, memory, system properties
```

Loading the overlay second matters because the main script can also touch Build values. The overlay refreshes Build fields after short delays so the final app-visible profile is stable.

## Why benchmark apps are used

Benchmark apps make hook verification repeatable:

| App | What it proves |
|---|---|
| HTTP Toolkit Android SSL Pinning Demo | SSL and pinning hooks can be exercised through known client buttons. |
| OWASP UnCrackable L1 | Root-detection hooks can be tested against a known root warning path. |
| HTTP Toolkit Demo with `show-spoof-values.js` | Hardware profile values can be displayed from inside the app process. |

After the benchmark passes, the same script stack can be run against `com.nexon.mod` without the visual helper.

## Why the normal target run is headless

`downloads\frida\show-spoof-values.js` is intentionally temporary. It is useful when you want to see `SM-N935F`, `Mali-T880`, CPU cores, and memory on screen. It should be omitted from normal target-app runs because it creates visible Frida UI.

Headless verification uses logs instead:

```text
Required markers:
  Process hardware profile spoof enabled
  Runtime.availableProcessors spoof enabled: 8
  ActivityManager.MemoryInfo spoof enabled
  Mali-T880
  Bypassing OkHTTPv3.*m-api.nexon.com

Forbidden markers:
  FATAL EXCEPTION
  ANR
  Application Not Responding
  spoof-values
  Frida spoof values
```

This gives the same proof without showing Frida values inside the app.

## Trade-offs

App-process-scoped hooks are precise, but they do not change the whole emulator. That is good for targeted testing, but it means ADB can still show original LDPlayer values.

Log verification is repeatable and easy to automate, but it only proves that expected markers appeared. A hook that never gets exercised by the target app may not produce its marker.

The visual helper is fast for inspection, but it changes the screen. Keep it for benchmark checks and omit it for normal runs.

Keeping the hardware overlay separate avoids editing the broad bypass script, but it makes load order important. Always load the overlay after the main bypass script.

## Alternatives considered

Changing LDPlayer's global device identity would make ADB and every process report the same values, but it is broader, harder to undo, and not needed for app-process hook verification.

Attaching the broad bypass script to AutoJs6 looked convenient, but it destabilized AutoJs6. Keeping AutoJs6 and Frida attached to separate processes is cleaner.

Editing the original bypass script directly would reduce one `-l` argument, but it would make future updates harder to compare. The overlay keeps project-specific hardware behavior isolated.

## Related

- [Frida Hook Verification Reference](FRIDA_HOOK_VERIFICATION_REFERENCE.md)
- [How to Verify Frida Hooks in LDPlayer](HOW_TO_VERIFY_FRIDA_HOOKS.md)
- [Run a Frida Hook Smoke Test in LDPlayer](TUTORIAL_FRIDA_HOOK_SMOKE_TEST.md)
