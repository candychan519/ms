# QA Report: Nexon Frida Headless Overlay

Date: 2026-05-21
Mode: Standard, adapted for LDPlayer/Frida workflow
Scope: `com.nexon.mod` running with Frida hardware overlay and no on-screen Frida value dialog
Health score: 97/100

## Summary

QA found 0 critical, 0 high, and 0 medium issues for the current headless Frida run.

The app stayed foreground on `com.nexon.mod/.MainActivity`, the Frida hardware overlay stayed active, and the screen no longer displayed the `Frida spoof values` dialog.

## Evidence

- Frida session: `frida.exe` PID `27452`, `python.exe` PID `5276`
- Log: `downloads\frida\nexon-hardware-spoof-headless.log`
- Screenshot: `downloads\frida\nexon-headless-qa.png`
- UI dump: `downloads\frida\nexon-headless-ui.xml`
- Test suite: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1`
- Result: all tests passed.

## Checks

- Required hook markers present: hardware profile, 8 cores, memory info, Mali-T880, OkHTTP bypass for `m-api.nexon.com`.
- Forbidden Frida UI markers absent: `spoof-values`, `Frida spoof values`.
- Crash markers absent from Frida log: `FATAL EXCEPTION`, `ANR`, `Application Not Responding`.
- UI XML had no visible `Frida`, `spoof`, `SM-N935F`, `Mali-T880`, or `arm64-v8a` text.

## Notes

Logcat included non-fatal Chromium WebView `ClassNotFoundException` information logs, but no fatal exception or ANR marker was found and the app remained usable in the foreground.

The existing `fdciabdul-frida-multiple-bypass-ldplayer.js` line 724 `TypeError: not a function` warning remains non-fatal and was allowed by the log verifier.

## Issues

No fixable issues found.

## Ship Readiness

Ready to keep running in headless Frida mode. Continue omitting `downloads\frida\show-spoof-values.js` from Nexon launches unless visual value inspection is explicitly needed.
