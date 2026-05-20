# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0.1] - 2026-05-21

### Added

- Add a Frida log verifier for required hook markers, forbidden crash markers, and allowed non-fatal warnings.
- Add a Frida hardware profile overlay for app-process-visible CPU ABI, core count, GPU strings, memory info, and system properties.
- Add QA reports for HTTP Toolkit hardware spoof validation and headless `com.nexon.mod` Frida validation.

### Changed

- Document benchmark APKs, Frida hook verification, hardware overlay usage, and root Frida server restart after LDPlayer reboot.
- Record Frida/LDPlayer/Nexon validation findings in the learning log.

## [0.1.0.0] - 2026-05-21

### Added

- Monitor MapleStory Worlds minimap coordinates from LDPlayer screenshots with a live Windows UI.
- Detect the player marker in minimap screenshots, including JSON output and annotated image support.
- Cover the minimap marker and coordinate UI helpers with focused PowerShell tests.

### Changed

- Simplified the LDPlayer AutoJs6 workflow docs and reusable skill guidance.
- Updated learning notes with recent LDPlayer, MapleStory Worlds, and AutoJs6 verification results.

### Fixed

- Validate ADB serial values before live minimap capture commands run.
