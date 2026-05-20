# Usage And Sharing

이 문서는 AutoJs6 사용 방법과 Windows-LDPlayer 공유 방법을 기록합니다.

## Shared Folder Mapping

LDPlayer maps the Windows folder to Android storage:

```text
Windows: %USERPROFILE%\Documents\XuanZhi9\Pictures
Android: /sdcard/Pictures
```

Example:

```text
%USERPROFILE%\Documents\XuanZhi9\Pictures\autojs6-test.js
```

is visible inside LDPlayer as:

```text
/sdcard/Pictures/autojs6-test.js
```

## Standard Script Flow

1. Edit the script in the project:

   ```text
   <repo>\scripts\<name>.js
   ```

2. Copy it to the LDPlayer shared folder:

   ```powershell
   Copy-Item -Path '.\scripts\<name>.js' -Destination (Join-Path $env:USERPROFILE 'Documents\XuanZhi9\Pictures\<name>.js') -Force
   ```

3. Open AutoJs6 in LDPlayer.

4. Press `+`.

5. Choose `수입` to import.

6. Open `Pictures`.

7. Select the script file.

8. Confirm the import name.

9. Run the script with the play button.

## Current Test Script

- Project path: `<repo>\scripts\autojs6-test.js`
- Windows shared path: `%USERPROFILE%\Documents\XuanZhi9\Pictures\autojs6-test.js`
- Android path: `/sdcard/Pictures/autojs6-test.js`
- Imported AutoJs6 item name: `autojs6-test`

Script:

```js
auto.waitFor();

toast("AutoJs6 shared folder test OK");
sleep(1000);

click(500, 500);
```

Verified result:

- Toast displayed: `AutoJs6 shared folder test OK`
- Accessibility permission was required and enabled.

## Screen Coordinates

Coordinate actions depend on LDPlayer resolution.

Current resolution:

```text
1280x720
```

Common actions:

```js
click(500, 500);
press(500, 500, 800);
swipe(500, 700, 500, 300, 500);
```

If the emulator resolution changes, scripts that use fixed coordinates may need updates.

## Bounded Key Input Testing

Use `tools/send-ldplayer-key.ps1` for short input tests.

Dry-run an `A` key repeat:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\send-ldplayer-key.ps1 -Key A -Count 5 -IntervalMs 250 -DryRun
```

Send a short bounded `A` key repeat:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\send-ldplayer-key.ps1 -Key A -Count 5 -IntervalMs 250
```

The helper uses Android `input keyevent` through ADB. `A` maps to Android keycode `29` (`KEYCODE_A`).
