# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0.3] - 2026-05-21

### Fixed

- Keep Frida hardware spoof logs clean when Android lacks newer `Build.SOC_*` fields, while preserving the `SM-S921N` profile through app-process system properties.
- Keep Maple console repeat-stop buttons responsive by sending ADB input from background processes and force-releasing repeat keys on stop.
- Add a local QA report for the `com.nexon.mod` Frida smoke run that verifies the `SM-S921N` profile, headless execution, and absence of old-profile or popup markers.

## [0.1.0.2] - 2026-05-21

### Added

- Monitor MapleStory Worlds minimap coordinates from LDPlayer screenshots, including JSON output, annotated images, and a live Maple console.
- Use the Maple console to switch between three map profiles, watch the current character coordinate, hold `A`, run the `A→왼쪽+F v2` repeat loop, and optionally tap `D` on an interval.
- Add a Frida log verifier for required hook markers, forbidden crash markers, and allowed non-fatal warnings.
- Add a Frida hardware profile overlay for app-process-visible CPU ABI, core count, GPU strings, memory info, and system properties.
- Add QA reports for HTTP Toolkit hardware spoof validation, headless `com.nexon.mod` Frida validation, and Maple console layout checks.

### Changed

- Make `start-maple-console.ps1` the canonical Maple console entrypoint and keep `show-minimap-position-ui.ps1` as a legacy wrapper.
- Keep the repo, bundled skill, and installed skill Maple console copies synchronized.
- Document benchmark APKs, Frida hook verification, hardware overlay usage, and root Frida server restart after LDPlayer reboot.
- Generate dedicated Frida verification tutorial, how-to, reference, and explanation docs.
- Add a task-oriented Maple console how-to for opening the console, choosing map profiles, using repeat controls, and verifying layout.
- Align the Frida hardware overlay to the attached `SM-S921N` profile, including Exynos 2400, Xclipse 940, 10 CPU cores, 8 GiB memory, 1080x2340 display metrics, KT/KR locale and telephony, Wi-Fi/IP/MAC, and Vulkan GPU surfaces.
- Simplify the LDPlayer AutoJs6 workflow docs and reusable skill guidance.
- Cover minimap detection, Maple console controls, skill packaging, Frida verification, and layout sizing with focused PowerShell tests.

### For contributors

- Document that this repository is public and keep credentials, APKs, screenshots, Frida logs, and private runtime artifacts out of Git.
- Add `CONTRIBUTING.md` with the public repository boundary, focused verification workflow, Maple console preservation checklist, and Frida target-process verification rules.

### Fixed

- Validate ADB serial values before live minimap capture commands run.
- Validate Maple console Android input event paths and scan codes before building ADB shell commands.
- Preserve the full Maple console UI after regression, including unclipped Korean labels, two repeat buttons, periodic `D` controls, and all three map profiles.
