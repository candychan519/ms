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
For each new macro, record target, purpose, resolution, script path, actions, stop condition, and test result.

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
Created `tools/send-ldplayer-key.ps1` as a bounded input helper. It supports dry-run, count-based runs, short duration-based runs, interval control, and rejects long unbounded runs. It must not be used for multiplayer farming, reward loops, ranking, economy, trading, or anti-cheat bypass.

Verification:
Added `tests/test-send-ldplayer-key.ps1`. The test verifies dry-run does not call ADB, `A` maps to keycode `29`, `Count 3` sends exactly three key events, unsupported keys fail, and long duration runs fail by default.

Next action:
If a legitimate private/offline/accessibility test needs live input, start with `-DryRun`, then use a small live count such as `-Count 1` or `-Count 5`.
