# LDPlayer AutoJs6 Automation Workspace

This repository stores the local workflow, scripts, tests, and Codex skill source for Android automation work using LDPlayer, AutoJs6, and ADB on Windows.

## Current Baseline

- LDPlayer: `C:\LDPlayer\LDPlayer9`
- Instance: index `0`, name `LDPlayer`
- Resolution: `1280x720`
- DPI: `240`
- FPS: `60`
- ADB endpoint: `127.0.0.1:5555`
- AutoJs6 package: `org.autojs.autojs6`
- MapleStory Worlds package: `com.nexon.mod`
- Shared folder: `%USERPROFILE%\Documents\XuanZhi9\Pictures` -> `/sdcard/Pictures`

## Main Documents

- `WORKFLOW.md`: entrypoint and documentation map
- `MIGRATION.md`: restore this workspace on another Windows PC
- `docs/SESSION_SUMMARY_2026-05-16.md`: completed setup summary
- `docs/ENVIRONMENT.md`: current environment
- `docs/TOOLS_AND_INSTALLATION.md`: tools and install notes
- `docs/USAGE_AND_SHARING.md`: usage and shared folder workflow
- `docs/WORK_AND_DEVELOPMENT_METHOD.md`: TDD, multi-agent, and safety rules
- `logs/LEARNINGS.md`: append-only findings and decisions

## Tools And Tests

- `tools/setup-ldplayer-adb.ps1`
- `tools/capture-ldplayer.ps1`
- `tools/send-ldplayer-key.ps1`
- `tools/install-codex-skill.ps1`
- `tests/run-all.ps1`
- `tests/test-ldplayer-adb-setup.ps1`
- `tests/test-capture-ldplayer.ps1`
- `tests/test-install-codex-skill.ps1`
- `tests/test-ldplayer-autojs6-skill.ps1`
- `tests/test-send-ldplayer-key.ps1`

## Skill Source

The reusable Codex skill is mirrored under:

```text
codex-skills/ldplayer-autojs6
```

The active local copy is installed at:

```text
%USERPROFILE%\.codex\skills\ldplayer-autojs6
```

## Safety Boundary

Use this workspace for personal, offline, testing, accessibility, and non-competitive automation. Do not build multiplayer farming, reward loops, ranking, economy, trading, anti-cheat bypass, or unfair advantage automation.
