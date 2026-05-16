# Scripts

This folder stores AutoJs6 script source files edited on Windows.

## Current Script

- `autojs6-test.js`: verifies AutoJs6 execution and shared-folder import.

## Copy To LDPlayer Shared Folder

```powershell
Copy-Item -Path 'C:\Users\user\Desktop\ms\scripts\<name>.js' -Destination 'C:\Users\user\Documents\XuanZhi9\Pictures\<name>.js' -Force
```

Inside LDPlayer, the file appears at:

```text
/sdcard/Pictures/<name>.js
```

