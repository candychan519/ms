param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "tools\setup-ldplayer-adb.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ldplayer-adb-tests-" + [guid]::NewGuid().ToString("N"))
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
  param(
    [string]$Directory,
    [string]$DeviceState = "device"
  )

  New-Item -ItemType Directory -Path $Directory -Force | Out-Null
  $fakeAdbPath = Join-Path $Directory "adb.cmd"
  $logPath = Join-Path $Directory "adb.log"

  @"
@echo off
echo %*>>"$logPath"
if "%1"=="version" (
  echo Android Debug Bridge version 1.0.41
  exit /b 0
)
if "%1"=="start-server" (
  echo * daemon started successfully
  exit /b 0
)
if "%1"=="connect" (
  echo connected to %2
  exit /b 0
)
if "%1"=="devices" (
  echo List of devices attached
  echo 127.0.0.1:5555 $DeviceState
  exit /b 0
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
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
  $fake = New-FakeAdb -Directory $tempRoot

  $dryRun = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
    -AdbPath $fake.Path `
    -Endpoint "127.0.0.1:5555" `
    -DryRun `
    -Json |
    ConvertFrom-Json

  Assert-Equal 4 @($dryRun).Count "Dry-run should plan four ADB steps."
  Assert-True (((@($dryRun) | Select-Object -ExpandProperty Name) -join ",") -eq "version,start-server,connect,devices") "Dry-run should keep the expected step order."
  Assert-True (@($dryRun)[2].Arguments[0] -eq "connect") "Dry-run should include an adb connect step."
  Assert-True (@($dryRun)[2].Arguments[1] -eq "127.0.0.1:5555") "Dry-run should target the requested LDPlayer endpoint."
  Assert-True (-not (Test-Path -LiteralPath $fake.LogPath)) "Dry-run should not invoke the ADB executable."

  $mocked = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
    -AdbPath $fake.Path `
    -Endpoint "127.0.0.1:5555" `
    -Json |
    ConvertFrom-Json

  Assert-Equal 4 @($mocked).Count "Mocked run should execute four ADB steps."
  Assert-True (@($mocked | Where-Object { $_.ExitCode -ne 0 }).Count -eq 0) "Mocked ADB steps should all succeed."

  $loggedCommands = Get-Content -Path $fake.LogPath
  Assert-True (($loggedCommands -join "|") -eq "version|start-server|connect 127.0.0.1:5555|devices") "Mocked run should call the expected ADB commands in order."

  $offlineFake = New-FakeAdb -Directory (Join-Path $tempRoot "offline") -DeviceState "offline"
  $offlineOut = Join-Path $tempRoot "offline.out"
  $offlineErr = Join-Path $tempRoot "offline.err"
  $offlineProcess = Start-Process `
    -FilePath "powershell" `
    -ArgumentList @(
      "-NoProfile",
      "-ExecutionPolicy", "Bypass",
      "-File", $scriptPath,
      "-AdbPath", $offlineFake.Path,
      "-Endpoint", "127.0.0.1:5555"
    ) `
    -RedirectStandardOutput $offlineOut `
    -RedirectStandardError $offlineErr `
    -NoNewWindow `
    -Wait `
    -PassThru
  Assert-True ($offlineProcess.ExitCode -ne 0) "Offline ADB transport should fail the readiness check."

  $invalidEndpointOut = Join-Path $tempRoot "invalid-endpoint.out"
  $invalidEndpointErr = Join-Path $tempRoot "invalid-endpoint.err"
  $invalidEndpointProcess = Start-Process `
    -FilePath "powershell" `
    -ArgumentList @(
      "-NoProfile",
      "-ExecutionPolicy", "Bypass",
      "-File", $scriptPath,
      "-AdbPath", $fake.Path,
      "-Endpoint", "not-a-host-port",
      "-DryRun"
    ) `
    -RedirectStandardOutput $invalidEndpointOut `
    -RedirectStandardError $invalidEndpointErr `
    -NoNewWindow `
    -Wait `
    -PassThru
  $invalidEndpointExitCode = $invalidEndpointProcess.ExitCode

  Assert-True ($invalidEndpointExitCode -ne 0) "Invalid endpoint input should fail before running ADB."
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

if ($failures.Count -gt 0) {
  Write-Host "LDPlayer ADB setup tests failed:" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "LDPlayer ADB setup tests passed." -ForegroundColor Green
