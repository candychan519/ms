# How to Use the Maple Console

Use this guide when you want to open the Maple console, watch the current minimap coordinate, and run the built-in repeat controls for MapleStory Worlds in LDPlayer.

The canonical console script is:

```powershell
pwsh -STA -NoProfile -ExecutionPolicy Bypass -File .\tools\start-maple-console.ps1
```

`tools\show-minimap-position-ui.ps1` is only a compatibility wrapper for older notes. New work should use `tools\start-maple-console.ps1`.

## Prerequisites

- LDPlayer is running.
- MapleStory Worlds is open in LDPlayer.
- LDPlayer ADB is reachable at `127.0.0.1:5555`.
- The emulator uses the project baseline resolution `1280x720` and DPI `240`.
- The bundled ADB exists at `C:\LDPlayer\LDPlayer9\adb.exe`.

Validate ADB first:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\setup-ldplayer-adb.ps1 -AdbPath C:\LDPlayer\LDPlayer9\adb.exe -Endpoint 127.0.0.1:5555
```

## Open the console

Start the console from the repository root:

```powershell
pwsh -STA -NoProfile -ExecutionPolicy Bypass -File .\tools\start-maple-console.ps1
```

Use `-TopMost` if you want the utility window to stay above LDPlayer:

```powershell
pwsh -STA -NoProfile -ExecutionPolicy Bypass -File .\tools\start-maple-console.ps1 -TopMost
```

The window title should be `메이플 콘솔`. It should open as a compact utility window, not a large dashboard and not a coordinate-only window.

## Choose the map profile

Pick the active map from the left-side map list.

Current profiles:

- `빅토리아로드 헤네시스동쪽풀숲`
- `선셋로드 사헬지대2`
- `선셋로드 꿈꾸는 사막`

Changing the map restarts the minimap watcher with that map's bounds and marker filters. It also stops any active repeat input so movement does not continue with stale map settings.

## Read and copy the coordinate

The main coordinate label shows the current character coordinate as:

```text
캐릭터 좌표=(x, y)
```

Use the minimap-local coordinate in conversation and tuning notes. For example:

```text
minimap=(65,49)
```

Click `복사` to copy the latest coordinate text to the Windows clipboard.

If the console reports `좌표 급변 무시`, the marker detector saw a jump larger than the selected map allows. This protects the repeat loop from reacting to a likely false marker.

## Use `A 누르기`

Click `A 누르기` to hold the Android `A` scan code through ADB `sendevent`.

While active:

- The button changes to `A 반복 중지`.
- The console keeps `A` down with the configured `AHoldIntervalMs`.
- If `D 사용` is checked, the console briefly releases and restores `A` when it taps `D`.

Click `A 반복 중지` to stop. Closing the window also stops repeat input.

## Use `A→왼쪽+F v2`

Click `A→왼쪽+F v2` to start the coordinate-aware repeat loop.

The v2 loop:

- Watches the latest minimap `x` coordinate.
- Uses the selected map's left and right turn boundaries.
- Sends a direction key and `F` through Android input events.
- Double-taps direction when it changes direction.

Default turn boundaries:

| Map | Left boundary | Right boundary |
|---|---:|---:|
| `빅토리아로드 헤네시스동쪽풀숲` | `20` | `150` |
| `선셋로드 사헬지대2` | `20` | `150` |
| `선셋로드 꿈꾸는 사막` | `20` | `157` |

Click `v2 반복 중지` to stop the loop.

## Use periodic `D`

Check `D 사용` to let the console tap `D` while `A 누르기` is active.

Set `D 간격` to the interval in seconds. The default is `30`. Values below `1` are treated as invalid and the console reports a `D 간격 오류` status instead of sending repeated input.

The `D` tap is interval-gated. It is not sent on every UI refresh tick.

## Pause coordinate watching

Click `일시정지` to stop the minimap watcher without closing the console. Click `시작` to restart it.

Pausing the watcher does not replace the repeat stop buttons. Stop active repeat controls directly before changing emulator state, changing maps, or leaving the target app.

## Verify the console before reporting it fixed

Run the focused test:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\test-start-maple-console.ps1
```

The test checks:

- `start-maple-console.ps1` exists as the canonical entrypoint.
- The bundled skill copy is synchronized.
- `show-minimap-position-ui.ps1` remains a wrapper.
- All three map profiles exist.
- The repeat controls and periodic `D` controls exist.
- Key Korean labels fit their configured control widths.
- ADB input paths and scan codes are validated before shell commands are built.

Also inspect a real screenshot of the `메이플 콘솔` window before saying the UI is fixed. UI Automation can prove that controls exist, but it does not prove Korean text is visually unclipped.

## Troubleshooting

If the console does not open, make sure you used `pwsh -STA`. Windows Forms clipboard and UI behavior need an STA PowerShell session.

If ADB input fails, validate the ADB endpoint and confirm LDPlayer's ADB debugging is set to `Local debugging`.

If the marker does not move, run the marker watcher directly:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\find-minimap-player-marker.ps1 -Watch -IntervalMs 500
```

If the wrong UI opens, check that you launched `tools\start-maple-console.ps1`. The old `show-minimap-position-ui.ps1` name should forward to the same console.

If text is clipped, update the console layout and then re-run `tests\test-start-maple-console.ps1` plus a live screenshot check.

## Related

- [Workflow](../WORKFLOW.md)
- [Work And Development Method](WORK_AND_DEVELOPMENT_METHOD.md)
- [Tools And Installation](TOOLS_AND_INSTALLATION.md)
- [LDPlayer AutoJs6 Skill](../codex-skills/ldplayer-autojs6/SKILL.md)
