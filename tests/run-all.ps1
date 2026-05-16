param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$testRoot = $PSScriptRoot
$tests = @(
  "test-ldplayer-adb-setup.ps1",
  "test-send-ldplayer-key.ps1",
  "test-capture-ldplayer.ps1",
  "test-install-codex-skill.ps1",
  "test-ldplayer-autojs6-skill.ps1"
)

foreach ($test in $tests) {
  $path = Join-Path $testRoot $test
  Write-Host "Running $test" -ForegroundColor Cyan
  & powershell -NoProfile -ExecutionPolicy Bypass -File $path
  if ($LASTEXITCODE -ne 0) {
    throw "$test failed with exit code $LASTEXITCODE"
  }
}

Write-Host "All tests passed." -ForegroundColor Green
