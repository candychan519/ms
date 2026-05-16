param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "tools\send-ldplayer-key.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ldplayer-key-tests-" + [guid]::NewGuid().ToString("N"))
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
  param([string]$Message)
  $failures.Add($Message)
}

function Assert-True {
  param(
    [bool]$Condition,
    [string]$Message
  )

  if (-not $Condition) {
    Add-Failure $Message
  }
}

function Assert-Equal {
  param(
    $Expected,
    $Actual,
    [string]$Message
  )

  if ($Expected -ne $Actual) {
    Add-Failure "$Message Expected '$Expected', got '$Actual'."
  }
}

function New-FakeAdb {
  param([string]$Directory)

  New-Item -ItemType Directory -Path $Directory -Force | Out-Null
  $fakeAdbPath = Join-Path $Directory "adb.cmd"
  $logPath = Join-Path $Directory "adb.log"

  @"
@echo off
echo %*>>"$logPath"
if "%1"=="-s" (
  if "%3"=="shell" (
    if "%4"=="input" (
      if "%5"=="keyevent" (
        echo ok
        exit /b 0
      )
    )
  )
)
echo unexpected command %*
exit /b 9
"@ | Set-Content -Path $fakeAdbPath -Encoding ASCII

  return [pscustomobject]@{
    Path = $fakeAdbPath
    LogPath = $logPath
  }
}

try {
  Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "send-ldplayer-key.ps1 should exist."

  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
  $fake = New-FakeAdb -Directory $tempRoot

  $dryRun = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
    -AdbPath $fake.Path `
    -Serial "127.0.0.1:5555" `
    -Key "A" `
    -Count 3 `
    -IntervalMs 50 `
    -DryRun

  Assert-True (($dryRun -join "`n") -match "KEYCODE_A.*29") "Dry-run should show A mapped to keycode 29."
  Assert-True (-not (Test-Path -LiteralPath $fake.LogPath)) "Dry-run should not invoke ADB."

  $run = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
    -AdbPath $fake.Path `
    -Serial "127.0.0.1:5555" `
    -Key "A" `
    -Count 3 `
    -IntervalMs 50

  $loggedCommands = Get-Content -Path $fake.LogPath
  Assert-Equal 3 @($loggedCommands).Count "Count 3 should send exactly three key events."
  Assert-True (($loggedCommands -join "|") -eq "-s 127.0.0.1:5555 shell input keyevent 29|-s 127.0.0.1:5555 shell input keyevent 29|-s 127.0.0.1:5555 shell input keyevent 29") "Each sent event should be KEYCODE_A."
  Assert-True (($run -join "`n") -match "Sent 3") "Run output should report the number of sent key events."

  $invalidOut = Join-Path $tempRoot "invalid.out"
  $invalidErr = Join-Path $tempRoot "invalid.err"
  $invalidProcess = Start-Process `
    -FilePath "powershell" `
    -ArgumentList @(
      "-NoProfile",
      "-ExecutionPolicy", "Bypass",
      "-File", $scriptPath,
      "-AdbPath", $fake.Path,
      "-Key", "F13",
      "-Count", "1"
    ) `
    -RedirectStandardOutput $invalidOut `
    -RedirectStandardError $invalidErr `
    -NoNewWindow `
    -Wait `
    -PassThru
  Assert-True ($invalidProcess.ExitCode -ne 0) "Unsupported key names should fail."

  $longOut = Join-Path $tempRoot "long.out"
  $longErr = Join-Path $tempRoot "long.err"
  $longProcess = Start-Process `
    -FilePath "powershell" `
    -ArgumentList @(
      "-NoProfile",
      "-ExecutionPolicy", "Bypass",
      "-File", $scriptPath,
      "-AdbPath", $fake.Path,
      "-Key", "A",
      "-DurationSeconds", "120"
    ) `
    -RedirectStandardOutput $longOut `
    -RedirectStandardError $longErr `
    -NoNewWindow `
    -Wait `
    -PassThru
  Assert-True ($longProcess.ExitCode -ne 0) "Long key repeat runs should be rejected by default."
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

if ($failures.Count -gt 0) {
  Write-Host "LDPlayer key sender tests failed:" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "LDPlayer key sender tests passed." -ForegroundColor Green
