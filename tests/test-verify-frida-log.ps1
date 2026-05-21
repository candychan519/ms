param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "tools\verify-frida-log.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("frida-log-tests-" + [guid]::NewGuid().ToString("N"))
$powerShellExe = (Get-Process -Id $PID).Path
if (-not $powerShellExe) {
  $powerShellExe = (Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
}
if (-not $powerShellExe) {
  $powerShellExe = (Get-Command powershell -ErrorAction Stop | Select-Object -First 1 -ExpandProperty Source)
}
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

try {
  Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "verify-frida-log.ps1 should exist."

  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
  $goodLog = Join-Path $tempRoot "good.log"
  $badLog = Join-Path $tempRoot "bad.log"

  @"
Attach
BypassNativeNow
[+] Display profile spoof enabled: 1080x2340, densityDpi=420
Unpinning setup completed
  --> Bypassing OkHTTPv3 (`$okhttp): m-api.nexon.com
TypeError: not a function
"@ | Set-Content -LiteralPath $goodLog -Encoding ASCII

  @"
Attach
FATAL EXCEPTION: main
"@ | Set-Content -LiteralPath $badLog -Encoding ASCII

  $escapedScriptPath = $scriptPath.Replace("'", "''")
  $escapedGoodLog = $goodLog.Replace("'", "''")
  $goodCommand = "& '$escapedScriptPath' -LogPath '$escapedGoodLog' -RequirePattern @('Attach', 'BypassNativeNow', 'Bypassing OkHTTPv3') -ForbidPattern @('FATAL EXCEPTION') -AllowWarningPattern @('TypeError: not a function') -Json"
  $goodResult = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -Command $goodCommand |
    ConvertFrom-Json

  Assert-True ($LASTEXITCODE -eq 0) "Good log should pass."
  Assert-True ($goodResult.Passed -eq $true) "Good log JSON should report Passed=true."
  Assert-True (@($goodResult.Warnings).Count -eq 1) "Allowed warning should be reported but not fail the log."

  $badOut = Join-Path $tempRoot "bad.out"
  $badErr = Join-Path $tempRoot "bad.err"
  $badProcess = Start-Process `
    -FilePath $powerShellExe `
    -ArgumentList @(
      "-NoProfile",
      "-ExecutionPolicy", "Bypass",
      "-File", $scriptPath,
      "-LogPath", $badLog,
      "-RequirePattern", "BypassNativeNow",
      "-ForbidPattern", "FATAL EXCEPTION",
      "-Json"
    ) `
    -RedirectStandardOutput $badOut `
    -RedirectStandardError $badErr `
    -NoNewWindow `
    -Wait `
    -PassThru

  Assert-True ($badProcess.ExitCode -ne 0) "Bad log should fail when required patterns are missing or forbidden patterns are present."
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

if ($failures.Count -gt 0) {
  Write-Host "Frida log verifier tests failed:" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "Frida log verifier tests passed." -ForegroundColor Green
