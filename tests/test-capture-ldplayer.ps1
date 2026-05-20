param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "tools\capture-ldplayer.ps1"
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

Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "capture-ldplayer.ps1 should exist."

$scriptText = Get-Content -LiteralPath $scriptPath -Raw
Assert-True ($scriptText -match "PrintWindow") "Capture helper should use PrintWindow for non-obstructing capture."
Assert-True ($scriptText -match "Get-Process dnplayer") "Capture helper should target the LDPlayer dnplayer process."
Assert-True ($scriptText -match "Write-Output") "Capture helper should output the screenshot path."

$ldplayer = Get-Process dnplayer -ErrorAction SilentlyContinue | Select-Object -First 1
if ($ldplayer) {
  $output = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath 2>&1
  Assert-True ($LASTEXITCODE -eq 0) "Capture helper should run when LDPlayer is running. Output: $($output -join ' ')"
  $shotPath = @($output)[-1].ToString()
  Assert-True (Test-Path -LiteralPath $shotPath -PathType Leaf) "Capture helper should create an image file: $shotPath"
  $shot = Get-Item -LiteralPath $shotPath
  Assert-True ($shot.Length -gt 0) "Capture image should not be empty."
} else {
  Write-Host "LDPlayer is not running; live capture assertion skipped." -ForegroundColor Yellow
}

if ($failures.Count -gt 0) {
  Write-Host "LDPlayer capture tests failed:" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "LDPlayer capture tests passed." -ForegroundColor Green
