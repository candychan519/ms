# Contributing

This repository is public and stores reusable LDPlayer, AutoJs6, ADB, Frida, and Maple console workflow code. Contributions should keep local runtime data out of Git and should be verified with the narrowest relevant PowerShell tests.

## Public Repository Boundary

Commit:

- reusable scripts under `tools/`, `scripts/`, and `codex-skills/`
- focused tests under `tests/`
- stable workflow documentation under `README.md`, `WORKFLOW.md`, `MIGRATION.md`, and `docs/`

Do not commit:

- secrets, tokens, passwords, account data, or `.env` files
- APK, XAPK, APKS, Frida logs, screenshots, recordings, or LDPlayer captures
- generated files from `downloads/`, `screenshots/`, or `graphify-out/`
- private runtime state from MapleStory Worlds, AutoJs6, LDPlayer, or Frida sessions

The `.gitignore` is intentionally broad for public sharing. If a generated artifact is useful, document how to reproduce it instead of committing the artifact.

## Development Workflow

1. Start from an up-to-date `main` branch.

   ```powershell
   git checkout main
   git pull --ff-only origin main
   git checkout -b codex/<short-change-name>
   ```

2. Define the target behavior before editing.

   Use `docs/WORK_AND_DEVELOPMENT_METHOD.md` for the project development loop. For reusable helpers, add or update a focused test before the implementation when practical.

3. Keep changes surgical.

   Match the existing PowerShell and JavaScript style. Do not reformat adjacent code or replace the canonical Maple console with a smaller debugging UI.

4. Run focused verification.

   For example:

   ```powershell
   pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\test-start-maple-console.ps1
   pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\test-verify-frida-log.ps1
   pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\test-frida-spoof-process-hardware.ps1
   ```

5. Run the full test suite before shipping when practical.

   ```powershell
   pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\run-all.ps1
   ```

6. Update documentation when behavior changes.

   Update the closest stable document under `docs/`, plus `README.md` or `WORKFLOW.md` if the entrypoint changes.

## Maple Console Changes

`tools/start-maple-console.ps1` is the canonical Maple console. It must keep:

- the `메이플 콘솔` window title
- the minimap coordinate watcher
- three map profiles
- `A 누르기`
- `A→왼쪽+F v2`
- periodic `D 사용` and `D 간격` controls

Before reporting Maple console UI work as fixed, run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\test-start-maple-console.ps1
```

Then visually inspect the live console window or a screenshot. Text-fit tests are useful, but previous regressions still needed a direct visual check for clipped Korean labels.

## Frida Changes

Frida verification is app-process scoped. Attach broad bypass scripts to the target app process, such as `com.nexon.mod`, not to AutoJs6.

For normal Maple runs, omit:

```text
downloads\frida\show-spoof-values.js
```

That helper is only for temporary visible benchmark checks. Normal headless target-app runs should keep Frida spoof values off screen and verify with `tools\verify-frida-log.ps1`.

Use these tests for Frida helper changes:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\test-verify-frida-log.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\test-frida-spoof-process-hardware.ps1
```

## Pull Request Checklist

- [ ] The change is limited to the requested behavior.
- [ ] No private runtime artifacts, logs, screenshots, APKs, or credentials are staged.
- [ ] Focused tests were run and their results are included in the PR.
- [ ] User-facing workflow changes are reflected in README or `docs/`.
- [ ] Maple console changes preserve the canonical UI controls.
- [ ] Frida changes are verified against the target app process, not AutoJs6.

## Related Documentation

- [Workflow](WORKFLOW.md)
- [Work And Development Method](docs/WORK_AND_DEVELOPMENT_METHOD.md)
- [Usage And Sharing](docs/USAGE_AND_SHARING.md)
- [How To Use Maple Console](docs/HOW_TO_USE_MAPLE_CONSOLE.md)
- [How To Verify Frida Hooks](docs/HOW_TO_VERIFY_FRIDA_HOOKS.md)
- [Frida Hook Verification Reference](docs/FRIDA_HOOK_VERIFICATION_REFERENCE.md)
