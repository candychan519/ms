# Learnings

This is the append-only learning log for this project.

## 2026-05-16 - LDPlayer And AutoJs6 Setup

Context:
Set up Android AutoJs6 automation inside LDPlayer from `C:\Users\user\Desktop\ms`.

Finding:
AutoJs6 runs inside the LDPlayer Android environment, not directly on Windows.

Evidence:
LDPlayer was visible on the Windows desktop, and `ldconsole.exe list2` returned instance `0` with resolution `1600x900` and DPI `240`.

Decision:
Use Windows for editing scripts and LDPlayer/AutoJs6 for executing them.

Next action:
Build future automation scripts under `scripts/`, copy them to the shared folder, import them into AutoJs6, and document results.

## 2026-05-16 - Shared Folder Confirmed

Context:
Needed a reliable way to move `.js` scripts from Windows into LDPlayer.

Finding:
LDPlayer maps `C:\Users\user\Documents\XuanZhi9\Pictures` to `/sdcard/Pictures`.

Evidence:
`autojs6-test.js` was copied to the Windows shared folder and appeared in AutoJs6 import under `Pictures`.

Decision:
Use the shared folder as the default transfer method for scripts.

Next action:
Keep source scripts in `scripts/` and copy them to the shared folder when testing.

## 2026-05-16 - AutoJs6 Test Script Verified

Context:
Needed to verify AutoJs6 installation, import, and execution.

Finding:
`autojs6-test` imported and ran successfully after enabling overlay and accessibility permissions.

Evidence:
The script displayed the toast `AutoJs6 shared folder test OK`.

Decision:
The base automation environment is ready for simple AutoJs6 scripts using `auto.waitFor()`, `toast()`, and `click()`.

Next action:
For each new macro, record target, purpose, resolution, script path, actions, and test result.

## 2026-05-16 - MapleStory Worlds Install Attempt

Context:
Installed MapleStory Worlds into LDPlayer.

Finding:
The official Google Play package name is `com.nexon.mod`. LDPlayer `installapp --packagename com.nexon.mod` opened the LD Store page and installed the LD Store version. The installed app launched, but the app required a newer update on startup.

Evidence:
LD Store showed MapleStory Worlds with version `1.24.0`. On launch, the app showed a download dialog saying a new update was released and asked to download the latest version from the store. The update button opened Google Play, but Google Play required login.

Decision:
Do not install a third-party APK/XAPK without explicit user confirmation. The preferred update path is Google Play login inside LDPlayer, then update from the official Google Play page.

Next action:
Ask the user to either log into Google Play in LDPlayer and continue the update, or explicitly approve a non-Google-Play APK/XAPK source after accepting the trust tradeoff.

## 2026-05-16 - Google Play Installation Preference

Context:
The user clarified the preferred installation policy for LDPlayer apps.

Finding:
The user wants apps to be installed and updated through Google Play by default. If Google Play requires login, the user will log in manually.

Evidence:
User said: "항상 구글 플레이를 통해서 설치하는데, 앞으로 제가 로그인해줄게요."

Decision:
Use Google Play as the default install/update path for Android apps in LDPlayer. Pause for user login when required. Do not use third-party APK/XAPK sources without explicit approval.

Next action:
For MapleStory Worlds, continue from the Google Play login screen after the user logs in.

## 2026-05-16 - Screenshot Wait Cadence

Context:
The user noticed that screenshot checks felt slow.

Finding:
Long waits were used during install, launch, and update flows because those states can take longer. For normal UI work, shorter checks are enough.

Evidence:
Recent waits included about `10-25` seconds during store parsing, app launch, and update redirection.

Decision:
Use frequent short screenshot checks by default: `0.5-1.5` seconds for normal clicks/navigation, `1-3` seconds for normal UI transitions, `3-7` seconds for app launch before re-checking, and repeated `5-10` second checks for installs, updates, downloads, or network-heavy loading.

Next action:
Use shorter and more frequent checks during interactive LDPlayer navigation unless the action is expected to load slowly.

## 2026-05-16 - LDPlayer Window-Only Screenshots

Context:
The user asked whether screenshots can capture only LDPlayer instead of the full desktop.

Finding:
Window-handle capture works for the LDPlayer process `dnplayer`. If another window overlaps LDPlayer, the captured region can include the overlapping content unless LDPlayer is brought to the foreground first.

Evidence:
`take_screenshot.ps1 -Mode temp -WindowHandle 657938` captured the LDPlayer window region. Bringing LDPlayer to the foreground first produced a clean LDPlayer-only screenshot.

Decision:
Use LDPlayer window-only screenshots by default. Before capture, bring the `dnplayer` window to the foreground.

Next action:
Use full-desktop screenshots only when the user asks for desktop context or when window capture is insufficient.

## 2026-05-16 - Non-Obstructing LDPlayer Capture

Context:
The user wanted LDPlayer-only screenshots without bringing LDPlayer forward, because foregrounding LDPlayer hides the user's active work window.

Finding:
Windows `PrintWindow` can capture the LDPlayer window without foregrounding it. This avoids covering the user's working window.

Evidence:
A PowerShell `PrintWindow` test returned `ok=True` and produced a clean LDPlayer screenshot while using the `dnplayer` window handle.

Decision:
Use `tools/capture-ldplayer.ps1` as the preferred LDPlayer screenshot method. Keep ADB `screencap` as a possible future option if LDPlayer ADB is fixed, but current ADB was `offline`.

Next action:
Use `tools/capture-ldplayer.ps1` for routine visual checks.

## 2026-05-16 - LDPlayer ADB Enabled And Verified

Context:
The user asked to set up ADB with multi-agent work and TDD.

Finding:
LDPlayer ADB was disabled. The player log showed `adb debug mode 0`, `127.0.0.1:5555` was not listening, and `adb devices` only showed `127.0.0.1:2222 offline`.

Evidence:
After changing LDPlayer Settings > Other > ADB debugging to Local debugging, `127.0.0.1:5555` started listening and `adb devices -l` showed both `127.0.0.1:5555 device` and `emulator-5554 device`.

Decision:
Use LDPlayer's bundled ADB at `C:\LDPlayer\LDPlayer9\adb.exe` as the project default. Use `127.0.0.1:5555` as the primary serial for explicit `adb -s` commands.

Verification:
`tools/setup-ldplayer-adb.ps1` passed against the live endpoint. `adb shell wm size` returned `1600x900`, `adb shell wm density` returned `240`, and `adb shell screencap` plus `adb pull` produced `downloads/adb-test.png`.

Next action:
Use ADB for fast LDPlayer-only screenshots and command checks when possible, while keeping `tools/capture-ldplayer.ps1` as the non-obstructing Windows fallback.

## 2026-05-16 - ADB Setup TDD

Context:
Needed a repeatable way to validate LDPlayer ADB setup.

Finding:
A simple `adb connect` command can return exit code `0` even when the endpoint is refused or the visible device remains `offline`.

Evidence:
Before enabling ADB, the setup script initially did not fail because `adb connect` and `adb devices` returned exit code `0` while the transport was unusable.

Decision:
`tools/setup-ldplayer-adb.ps1` must parse `adb devices` and require the target endpoint to appear with state `device`. Offline or missing endpoints fail the setup.

Verification:
`tests/test-ldplayer-adb-setup.ps1` covers dry-run behavior, command order, invalid endpoints, and offline transport failure.

Next action:
Extend the same test-first pattern for future reusable ADB helpers such as tap, swipe, screenshot, and file sync commands.

## 2026-05-16 - LDPlayer FPS Lowered To 30

Context:
The user asked to lower the LDPlayer frame rate to 30 FPS.

Finding:
LDPlayer exposes a command-line global FPS setting through `ldconsole.exe globalsetting --fps`.

Evidence:
Running `C:\LDPlayer\LDPlayer9\ldconsole.exe globalsetting --fps 30` completed successfully. `C:\LDPlayer\LDPlayer9\vms\config\leidians.config` now contains `"framesPerSecond": 30`.

Decision:
Use `globalsetting --fps 30` as the project default FPS cap command.

Known caveat:
The running instance config still contains `basicSettings.fps: 60`, so if the active emulator does not visibly cap to 30 FPS immediately, restart LDPlayer after saving the global setting.

Next action:
For future performance-sensitive automation, prefer the 30 FPS cap to reduce resource usage and stabilize visual timing.

Update:
The FPS setting was briefly restored to `60` while checking whether 30 FPS caused issues, then set back to `30` after the user confirmed to keep it. Current global value remains `"framesPerSecond": 30`.

## 2026-05-16 - LDPlayer Resolution Changed To 1280x720

Context:
The user asked to change LDPlayer resolution to `1280 x 720`.

Finding:
`ldconsole.exe modify --resolution` writes the new resolution to the instance config, but the running Android display keeps the old size until LDPlayer is restarted.

Evidence:
After running `C:\LDPlayer\LDPlayer9\ldconsole.exe modify --index 0 --resolution 1280,720,240`, `leidian0.config` showed `advancedSettings.resolution` as `1280x720`, while ADB still reported `Physical size: 1600x900`. After `ldconsole.exe reboot --index 0`, `ldconsole.exe list3 --index 0` returned `0,LDPlayer,0,1280,720,240` and ADB reported `Physical size: 1280x720`.

Decision:
Use `1280x720` with DPI `240` as the current LDPlayer baseline. Coordinate-based scripts must be written or recalibrated for this resolution.

Next action:
When building MapleStory Worlds automation, collect fresh screenshots and coordinates at `1280x720`, not the older `1600x900` baseline.

## 2026-05-16 - LDPlayer AutoJs6 Workflow Skill Created

Context:
The user asked to summarize the work so far and turn reusable parts into a skill where possible.

Finding:
The repeated workflow now has stable enough pieces to skillize: LDPlayer ADB validation, local debugging setup, resolution/FPS management, screenshots, shared folder usage, AutoJs6 script flow, Google Play install policy, TDD, and documentation rules.

Evidence:
Created `C:\Users\user\.codex\skills\ldplayer-autojs6` with `SKILL.md`, `references/project-baseline.md`, and bundled copies of `setup-ldplayer-adb.ps1` and `capture-ldplayer.ps1`.

Decision:
Use `$ldplayer-autojs6` for future LDPlayer + AutoJs6 + ADB automation maintenance work.

Next action:
Restart Codex if the new skill does not appear automatically in the active skill list.

Validation:
`quick_validate.py` could not run because the current Python environment does not have `yaml` installed. A fallback PowerShell validation confirmed the skill has `SKILL.md`, `agents/openai.yaml`, `references/project-baseline.md`, and the bundled scripts. The skill's ADB setup script also passed dry-run and live endpoint validation.

Correction:
The fallback validation was not sufficient. Installed `PyYAML 6.0.3` with `python -m pip install PyYAML`, reran `quick_validate.py`, and got `Skill is valid!`. Added `tests/test-ldplayer-autojs6-skill.ps1` so skill structure, `PyYAML`, official validation, and bundled setup-script dry-run are now covered by a project test.

## 2026-05-16 - LDPlayer FPS Restored To 60

Context:
The user found the 30 FPS setting was not working well and asked to restore 60 FPS.

Finding:
`globalsetting --fps 60` updates the global setting, and the instance preset already uses `basicSettings.fps: 60`.

Evidence:
`C:\LDPlayer\LDPlayer9\vms\config\leidians.config` shows `"framesPerSecond": 60`, and `C:\LDPlayer\LDPlayer9\vms\config\leidian0.config` shows `"basicSettings.fps": 60`.

Decision:
Use 60 FPS as the current LDPlayer baseline. Keep resolution at `1280x720` and DPI `240`.

Next action:
Keep the reusable skill and session docs aligned to `framesPerSecond: 60` so future setup does not revert to 30 FPS.

Update:
After restoring 60 FPS, rebooted LDPlayer instance `0` with `ldconsole.exe reboot --index 0`. Post-reboot checks confirmed `framesPerSecond: 60`, `basicSettings.fps: 60`, `list3` as `1280,720,240`, ADB `127.0.0.1:5555 device`, `wm size` as `1280x720`, and density `240`.

## 2026-05-16 - Bounded A Key Input Helper

Context:
The user asked to develop a macro where pressing keyboard `A` repeatedly triggers a skill.

Finding:
For safe testing/accessibility/private workflows, ADB can send Android keyboard events without adding more AutoJs6 permissions. `A` maps to Android `KEYCODE_A` keycode `29`.

Decision:
Created `tools/send-ldplayer-key.ps1` as a bounded input helper. It supports dry-run, count-based runs, short duration-based runs, interval control, and rejects long unbounded runs.

Verification:
Added `tests/test-send-ldplayer-key.ps1`. The test verifies dry-run does not call ADB, `A` maps to keycode `29`, `Count 3` sends exactly three key events, unsupported keys fail, and long duration runs fail by default.

Next action:
If a legitimate private/offline/accessibility test needs live input, start with `-DryRun`, then use a small live count such as `-Count 1` or `-Count 5`.

## 2026-05-17 - Migration Guide Added

Context:
The user asked whether the current repository is enough for migrating to another PC, then asked to organize and finish the work.

Finding:
The repository already contains the source, scripts, tests, documentation, and versioned Codex skill source, but a target PC still needs LDPlayer, AutoJs6, Google Play login, MapleStory Worlds, Python/PyYAML, and local Codex skill installation.

Decision:
Added `MIGRATION.md` as the single entrypoint for restoring the workspace on another Windows PC. The guide documents cloned contents, intentionally ignored artifacts, install steps, LDPlayer settings, Codex skill restore, and verification commands.

Next action:
Use `MIGRATION.md` first when setting up a new PC, then run the validation commands before continuing automation work.

## 2026-05-17 - Migration Audit Hardening

Context:
The user asked to use multi-agent review to find anything missed before treating the migration as ready.

Finding:
The audit found migration weaknesses: hardcoded `C:\Users\user` paths in skill tests and skill docs, missing Codex/skill validator preconditions, no skill install helper, no full test runner, no focused capture helper test, incomplete secret ignore patterns, missing `RECORDING_RULES.md` from the skill's standard doc list, and some broken encoded text in rules docs.

Decision:
Hardened migration by adding `tools/install-codex-skill.ps1`, `tests/test-install-codex-skill.ps1`, `tests/test-capture-ldplayer.ps1`, and `tests/run-all.ps1`. Generalized skill/test paths to `<repo>` and `$env:USERPROFILE` where possible, expanded `.gitignore` secret patterns, rewrote `docs/RECORDING_RULES.md`, cleaned `docs/WORK_AND_DEVELOPMENT_METHOD.md`, and updated `MIGRATION.md` with Codex, PyYAML, AutoJs6 download, shared-folder, per-instance FPS, and active-skill validation steps.

Next action:
Use `tests/run-all.ps1` as the default pre-push verification command.

Verification:
`tests/run-all.ps1` passed after the hardening changes. The LDPlayer-only live capture assertion was skipped because LDPlayer was not running, but the static capture checks passed. The repo skill passed `quick_validate.py`, and the active Codex skill was reinstalled from `codex-skills/ldplayer-autojs6`.

## 2026-05-17 - Live Minimap Player Coordinate Tool

Context:
The user wants a shared coordinate reference from the LDPlayer minimap while discussing navigation and visual debugging.

Finding:
The yellow player marker can be detected from the top-left minimap using a constrained yellow connected-component search inside the default minimap bounds `x=8 y=96 width=207 height=101` on the current `1280x720` LDPlayer baseline.

Decision:
Added `tools/find-minimap-player-marker.ps1`. It can analyze a saved screenshot with `-ImagePath` or monitor live LDPlayer output with `-Watch` using ADB `screencap`. It reports minimap-local coordinates, normalized minimap percentages, full-screen coordinates, marker pixel count, and confidence.

Verification:
`tests/test-find-minimap-player-marker.ps1`, `tests/test-ldplayer-autojs6-skill.ps1`, and `tests/run-all.ps1` passed. The versioned Codex skill was updated and reinstalled to `%USERPROFILE%\.codex\skills\ldplayer-autojs6`.

Next action:
Use minimap-local coordinates like `minimap=(x,y)` when discussing the character's position. Recheck minimap bounds if LDPlayer resolution or the app UI layout changes.

## 2026-05-17 - Minimap Position UI

Context:
The user asked for a simple program with a UI that displays the current character coordinate.

Decision:
Added `tools/show-minimap-position-ui.ps1`, a small Windows Forms monitor that reuses `tools/find-minimap-player-marker.ps1`. The UI shows the current `minimap=(x,y)` coordinate, normalized minimap percentage, full-screen coordinate, confidence, pixel count, update time, pause/start control, and a copy button.

Verification:
`tests/test-show-minimap-position-ui.ps1`, `tests/test-ldplayer-autojs6-skill.ps1`, and `tests/run-all.ps1` passed.

Launch note:
Because this repository path contains a space in `바탕 화면`, external `Start-Process` launches must quote the `-File` script path. Running from the repo can use `powershell -STA -NoProfile -ExecutionPolicy Bypass -File .\tools\show-minimap-position-ui.ps1`.

Next action:
Keep this UI open when discussing navigation. Use its large `minimap=(x,y)` value as the shared reference coordinate.

## 2026-05-17 - PowerShell 7.6.1 Migration For Helpers

Context:
The user asked to install the latest PowerShell, update the project for that version, restart the coordinate UI, and verify it still works.

Decision:
Installed PowerShell `7.6.1` with `winget` package `Microsoft.PowerShell`. Project helper examples now prefer `pwsh`. Tests that spawn child PowerShell processes now reuse the current executable, so running the suite under `pwsh` keeps child checks on PowerShell 7 instead of falling back to Windows PowerShell 5.1. The minimap UI also reuses the current executable for its marker probe process.

Verification:
`pwsh -NoProfile -Command '$PSVersionTable'` reported `PSVersion 7.6.1` and `PSEdition Core`. `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1` passed. The old Windows PowerShell UI process was stopped, and the UI was restarted with `pwsh -STA`; the running UI process is `pwsh` with window title `Minimap Position`.

Next action:
Use `pwsh` for new helper runs and UI launches. Keep `powershell` only as a Windows PowerShell 5.1 fallback when a legacy-only behavior is required.

## 2026-05-20 - MapleStory Worlds LDPlayer Launch Check

Context:
The user asked to verify MapleStory Worlds in LDPlayer and mentioned Frida bypass.

Decision:
Did not use Frida or bypass app protections. Verified normal launch through LDPlayer's bundled ADB against `com.nexon.mod`.

Verification:
ADB endpoint `127.0.0.1:5555` connected; instance `0`/`LDPlayer` reported `1280x720` at `240` DPI; package `com.nexon.mod` was installed. `monkey -p com.nexon.mod -c android.intent.category.LAUNCHER 1` launched `.MainActivity`, `pidof` returned `7770`, and both window focus and resumed activity stayed on `com.nexon.mod/.MainActivity`. ADB screenshot `downloads/mapleworld-launch-check.png` showed the Nexon OTP verification screen. App logs did not show a fatal app exception or ANR, though they did include WebView/Google Play service warnings and a Chromium renderer crash line while the main activity remained focused.

Next action:
Complete OTP manually in Nexon Play if deeper post-login verification is needed. Keep checks to normal launch and log capture; do not use Frida bypass or app protection evasion.

## 2026-05-21 - AutoJs6 Test Run Against MapleStory Worlds

Context:
The user asked to run `scripts/autojs6-test.js` against the LDPlayer `com.nexon.mod` target.

Finding:
ADB was connected at `127.0.0.1:5555` and `com.nexon.mod/.MainActivity` was already foreground. AutoJs6 accessibility was disabled, which blocks scripts that call `auto.waitFor()`. Re-enabled the AutoJs6 accessibility service. The Windows shared-folder copy did not appear immediately at `/sdcard/Pictures/autojs6-test.js`, so ADB `push` was used for the live run.

Verification:
Started AutoJs6 `RunIntentActivity` with `file:///sdcard/Pictures/autojs6-test.js`, returned focus to `com.nexon.mod`, and verified AutoJs6 logs: `ScriptEngineService` started, the toast text `AutoJs6 shared folder test OK` was emitted, and the script completed. Screenshot `downloads/autojs6-test-after-dismiss.png` showed `com.nexon.mod` foreground after the run. AutoJs6 briefly requested superuser during startup; no persistent root grant was intentionally selected, and AutoJs6 was force-stopped after the script completed.

Next action:
For future AutoJs6 smoke runs, verify accessibility first, push the script to `/sdcard/Pictures` if shared-folder sync is stale, and avoid granting superuser for scripts that do not require root.

## 2026-05-21 - Frida fdciabdul Script Against AutoJs6

Context:
The user asked to run AutoJs6 using `downloads/frida/fdciabdul-frida-multiple-bypass-ldplayer.js`.

Finding:
The file is a Frida hook script, not an AutoJs6 script. Running it with `frida -U -f org.autojs.autojs6 -l ...` loaded the hooks but AutoJs6 crashed during `MainActivity` startup. Starting AutoJs6 first and then attaching with `frida -U -p <pid> -l ...` also loaded the hooks but left AutoJs6 in an ANR state. The script hooks `getprop`, `su`, `Runtime.exec`, `ProcessBuilder`, display metrics, and SSL pinning APIs, which is too broad for AutoJs6 itself.

Verification:
Frida logs showed `Display spoof enabled`, `BypassNativeNow`, and `Unpinning setup completed`. Android logs showed AutoJs6 `MainActivity` startup failure on the spawn attempt and `Application Not Responding: org.autojs.autojs6` on the attach attempt. The failed Frida processes were stopped, and no persistent root grant was selected.

Next action:
Do not attach this bypass script to AutoJs6. If a Frida bypass is needed, attach it to the protected target app process, then run AutoJs6 separately for UI automation.

## 2026-05-21 - Frida fdciabdul Script Against com.nexon.mod

Context:
The user asked to run `downloads/frida/fdciabdul-frida-multiple-bypass-ldplayer.js` against `com.nexon.mod` instead of AutoJs6.

Finding:
Started `com.nexon.mod` through Frida with `frida -U -f com.nexon.mod -l ...`. The target app stayed foreground as `com.nexon.mod/.MainActivity`, and the Frida process remained attached. The script logged display spoof setup, native bypass setup, SSL unpinning setup, and live bypass activity for Nexon endpoints including `m-api.nexon.com`, `sdk-push.mp.nexon.com`, `gtable.inface.nexon.com`, and `public.api.nexon.com`. One script-side `TypeError: not a function` occurred at line 724, but the Frida session and target app continued running.

Verification:
ADB reported `com.nexon.mod` PID `12908`, with window focus on `com.nexon.mod/.MainActivity`. Screenshot `downloads/frida/nexon-frida-current.png` showed the MapleStory Worlds home screen loaded. Frida log path: `downloads/frida/nexon-fdciabdul-frida.log`.

Next action:
Keep the Windows `frida.exe`/`python.exe` process alive while the hooks are needed. Stop that process or force-stop `com.nexon.mod` when done.

## 2026-05-21 - Frida Benchmark Verification With TDD And Multi-Agent

Context:
The user asked to verify the Frida hook with benchmark apps, explicitly using multi-agent work and reflecting TDD.

Finding:
Used one explorer agent to evaluate public benchmark apps and one worker agent to design the TDD log-verification harness. Added `tools/verify-frida-log.ps1`, `tests/test-verify-frida-log.ps1`, and included the test in `tests/run-all.ps1`. The test was added first, failed because the helper did not exist, then passed after the helper was implemented and stabilized for PowerShell 7.6 result serialization.

Verification:
Installed official benchmark APKs into LDPlayer: HTTP Toolkit Android SSL Pinning Demo `v1.6.1` as `tech.httptoolkit.pinning_demo`, and OWASP UnCrackable L1 as `owasp.mstg.uncrackable1`. HTTP Toolkit produced live Frida bypass logs for OkHTTP and Appmattus hooks; visible button results included successful Context, OkHTTP, Volley, TrustKit, and Appmattus+OkHttp CT requests, while Appmattus CT alone still failed on hostname verification. OWASP UnCrackable L1 showed `Root detected!` without Frida, then reached the normal `Enter the Secret String` screen with Frida and logged `Anti Root Detect` file checks. `tests/run-all.ps1` passed.

Next action:
Use HTTP Toolkit Demo for SSL hook smoke tests and OWASP UnCrackable L1 for root-detection smoke tests. For stronger SSL pass/fail proof, repeat HTTP Toolkit with an explicit HTTPS interception proxy/CA setup so pinned requests fail without Frida and pass with Frida.

## 2026-05-21 - Frida Process Hardware Profile Overlay

Context:
The user asked how to make CPU, GPU, core count, and memory match the values seen inside the hooked app process.

Finding:
The main `fdciabdul-frida-multiple-bypass-ldplayer.js` script already spoofs Build/device/display values and forces `android_getCpuFamily()` toward ARM64, but it did not spoof Java-visible processor count, GPU strings, memory info, or CPU ABI fields consistently. Added `tools/frida-spoof-process-hardware.js` as a separate overlay so the original bypass script can remain unchanged.

Verification:
Added `tests/test-frida-spoof-process-hardware.ps1` and included it in `tests/run-all.ps1`. The test first failed while the overlay was missing, then passed after the overlay was added. Live validation against HTTP Toolkit Demo produced `downloads/frida/httptoolkit-hardware-spoof.log` with `cpuAbi=arm64-v8a`, `cpuCores=8`, `gpu.renderer=Mali-T880`, `gpu.version=OpenGL ES 3.2`, and `memory.totalMem=4294967296`. `tests/run-all.ps1` passed.

Next action:
Load the overlay after the main bypass script for targets that need the coherent SM-N935F/Exynos-style hardware profile.

## 2026-05-21 - LDPlayer Reboot And com.nexon.mod Hardware Overlay Run

Context:
The user asked to restart LDPlayer and test `com.nexon.mod` with the Frida hardware overlay.

Finding:
After LDPlayer reboot, the first Frida spawn attempt failed with `need Gadget to attach on jailed Android` because Frida server was not running as root. Starting `/data/local/tmp/frida-server` through `su -c` restored spawn/attach support.

Verification:
Started `com.nexon.mod` with `fdciabdul-frida-multiple-bypass-ldplayer.js`, `tools/frida-spoof-process-hardware.js`, and `downloads/frida/show-spoof-values.js`. ADB reported app PID `3989` and focus on `com.nexon.mod/.MainActivity`. `downloads/frida/nexon-hardware-spoof.log` verified `cpuAbi=arm64-v8a`, `cpuCores=8`, `gpu.renderer=Mali-T880`, `memory.totalMem=4294967296`, and a live OkHTTP bypass for `m-api.nexon.com`. No fatal exception, ANR, or application-not-responding marker was present; the known line 724 `TypeError: not a function` warning remained non-fatal.

Next action:
After every LDPlayer reboot, confirm `frida-server` is running as root before launching `com.nexon.mod` through Frida.

## 2026-05-21 - Maple Console Repeat UI Regression

Context:
The user reported that the opened Maple console was not the latest UI: the previous console had two repeat buttons, a periodic D checkbox, and three map profiles.

Finding:
`tools/show-minimap-position-ui.ps1` had been overwritten with a coordinate-only console, while the installed skill copy still had an older two-map A-repeat version. The expected latest behavior existed in prior session history: `A 누르기`, `A→왼쪽+F v2`, `D 사용`, `D 간격`, and the three profiles `빅토리아로드 헤네시스동쪽풀숲`, `선셋로드 사헬지대2`, and `선셋로드 꿈꾸는 사막`.

Verification:
Restored the repeat controls into `tools/show-minimap-position-ui.ps1`, synced the repo skill copy and installed Codex skill copy, updated `tests/test-show-minimap-position-ui.ps1`, and ran `tests/run-all.ps1`. The UI test now parses both script copies and checks that the bundled skill copy stays in sync with the tools copy. The opened `메이플 콘솔` window was also verified through Windows UI Automation to expose both repeat buttons, the D controls, and all three map names.

Next action:
If the console UI looks stale again, check both `tools/start-maple-console.ps1` and `%USERPROFILE%\.codex\skills\ldplayer-autojs6\scripts\start-maple-console.ps1`; both copies need to stay aligned. `show-minimap-position-ui.ps1` is only a legacy wrapper.

Documentation:
The console's canonical status is now documented in `WORKFLOW.md`, `docs/WORK_AND_DEVELOPMENT_METHOD.md`, and `codex-skills/ldplayer-autojs6/SKILL.md`: `start-maple-console.ps1` is the Maple console, not a coordinate-only scratch UI, and it must retain the repeat controls, three map profiles, copy synchronization, tests, and live screenshot layout check.

Naming follow-up:
The main console file was renamed from `show-minimap-position-ui.ps1` to `start-maple-console.ps1` because the old name made the file look like a minor coordinate helper. The old filename remains as a thin compatibility wrapper only.

## 2026-05-21 - Maple Console Layout Clipping

Context:
After the repeat UI was restored, the user reported that the console window had become too small and Korean labels were clipped.

Finding:
The prior QA checked Windows UI Automation control names and bounds, but did not inspect a pixel screenshot. The actual screenshot showed clipped text on the `A→왼쪽+F v2` button and the `D 사용` / `D 간격` controls.

Verification:
Expanded the text-bearing controls enough to prevent clipping, then compacted the window back down after overcorrecting. The current verification screenshot is `downloads/qa/maple-console-qa-final-printwindow.png`, captured with `PrintWindow` because `CopyFromScreen` can miss the window on this multi-monitor/DPI setup. The captured window rectangle was about `746x340`. `tests/test-start-maple-console.ps1` asserts the compact layout dimensions and uses `System.Windows.Forms.TextRenderer.MeasureText` to verify key Korean labels fit inside their configured widths.

Next action:
For Windows Forms UI QA, always capture and inspect a real screenshot in addition to UI Automation name/bounds checks; name presence does not prove text is visually unclipped.

## 2026-05-23 - LDPlayer hosts Override Via Bind Mount

Context:
The user asked to add Nexon-related blocking entries to LDPlayer's `/system/etc/hosts`.

Finding:
LDPlayer index `0` was initially stopped, so ADB on `127.0.0.1:5555` refused the connection until the instance was launched. After `adb root`, direct writes to `/system/etc/hosts` still failed because `/dev/root` stayed read-only and `adb remount` reported `Permission denied`. A root bind mount from `/data/local/tmp/hosts.codex` to `/system/etc/hosts` succeeded and immediately changed what apps see at that path.

Verification:
`cat /system/etc/hosts` showed the requested IPv4 and IPv6 entries after the bind mount. `ping -c 1 -W 1 x-phaethon.ngs.nexon.com` and `ping -c 1 -W 1 mod-file.dn.nexoncdn.co.kr` both resolved to `127.0.0.1` and replied from localhost.

Next action:
Treat this as a runtime override unless a persistent boot-time remount/bind mechanism is added. After an LDPlayer reboot, reapply the bind mount or create an explicit helper for it.
