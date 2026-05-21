# QA Report - Local Frida/LDPlayer

Date: 2026-05-21
Target: local LDPlayer `127.0.0.1:5555`, package `com.nexon.mod`
Mode: repository-adapted QA; no local web app was running on ports 3000, 4000, 8080, 5173, or 8000.

## Summary

- Baseline health: 92/100
- Final health: 100/100
- Issues found: 2
- Issues fixed: 2
- Deferred: 0

## Evidence

- Full test suite: `tests\run-all.ps1` passed.
- Live Frida smoke log: `downloads\frida\qa-nexon-hardware-spoof-headless-20260521-224521.log`
- Live log verifier passed with required `SM-S921N`, `10` cores, `Xclipse 940`, `m-api.nexon.com`, and no popup/old-profile forbidden markers.

## Issues

### ISSUE-001 - Main bypass display log still used old profile

Severity: Medium
Category: Content / Functional verification
Status: verified

The live `com.nexon.mod` smoke initially logged `Display spoof enabled: SM-N935F 1440x2560, densityDpi=560` before the overlay applied the new profile. This made the profile look inconsistent even though the later overlay markers were correct.

Fix: updated the local ignored main bypass file `downloads\frida\fdciabdul-frida-multiple-bypass-ldplayer.js` to use `SM-S921N`, `1080x2340`, and `densityDpi=420` for its Build/display spoof section.

### ISSUE-002 - Missing Android Build SOC fields produced noisy failure logs

Severity: Low
Category: Log quality
Status: verified

The overlay tried to set `Build.SOC_MANUFACTURER` and `Build.SOC_MODEL` on an Android API where those fields are absent, producing repeated `Build.SOC_* spoof failed` lines during delayed refreshes.

Fix: `tools\frida-spoof-process-hardware.js` now skips absent `android.os.Build` fields before assigning `.value`. The SOC values still remain covered through `ro.soc.*` SystemProperties.

## Final Checks

- No `SM-N935F`, `1440x2560`, or `densityDpi=560` markers in the final live log.
- No `Build.SOC_* spoof failed` markers in the final live log.
- No `spoof-values`, `Frida spoof values`, or `Hooked emulator values` markers in the final live log.
- Known main bypass warning `TypeError: not a function` remains allowed by the verifier.

PR summary: QA found 2 issues, fixed 2, health score 92 -> 100.
