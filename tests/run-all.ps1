param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$testRoot = $PSScriptRoot
$powerShellExe = (Get-Process -Id $PID).Path
if (-not $powerShellExe) {
  $powerShellExe = (Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
}
if (-not $powerShellExe) {
  $powerShellExe = (Get-Command powershell -ErrorAction Stop | Select-Object -First 1 -ExpandProperty Source)
}
$tests = @(
  "test-ldplayer-adb-setup.ps1",
  "test-send-ldplayer-key.ps1",
  "test-capture-ldplayer.ps1",
  "test-verify-frida-log.ps1",
  "test-frida-spoof-process-hardware.ps1",
  "test-find-minimap-player-marker.ps1",
  "test-show-minimap-position-ui.ps1",
  "test-install-codex-skill.ps1",
  "test-ldplayer-autojs6-skill.ps1"
)

foreach ($test in $tests) {
  $path = Join-Path $testRoot $test
  Write-Host "Running $test" -ForegroundColor Cyan
  & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $path
  if ($LASTEXITCODE -ne 0) {
    throw "$test failed with exit code $LASTEXITCODE"
  }
}

Write-Host "All tests passed." -ForegroundColor Green
