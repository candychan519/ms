# Changelog

All notable changes to this project will be documented in this file.

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
- Simplified the LDPlayer AutoJs6 workflow docs and reusable skill guidance.
- Cover minimap detection, Maple console controls, skill packaging, Frida verification, and layout sizing with focused PowerShell tests.

### Fixed

- Validate ADB serial values before live minimap capture commands run.
- Validate Maple console Android input event paths and scan codes before building ADB shell commands.
- Preserve the full Maple console UI after regression, including unclipped Korean labels, two repeat buttons, periodic `D` controls, and all three map profiles.
