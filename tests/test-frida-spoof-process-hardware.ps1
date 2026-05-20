param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "tools\frida-spoof-process-hardware.js"
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

Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "frida-spoof-process-hardware.js should exist."

if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
  $content = Get-Content -LiteralPath $scriptPath -Raw

  Assert-True ($content -match "availableProcessors") "Runtime.availableProcessors should be hooked."
  Assert-True ($content -match "ActivityManager" -and $content -match "getMemoryInfo") "ActivityManager.MemoryInfo should be spoofed."
  Assert-True ($content -match "GLES20" -and $content -match "glGetString") "GLES glGetString should be hooked."
  Assert-True ($content -match "__system_property_get") "Native system properties should be hooked."
  Assert-True ($content -match "SUPPORTED_ABIS" -and $content -match "CPU_ABI") "Build CPU ABI fields should be spoofed."
  Assert-True ($content -match "native_get" -and $content -match "native_get_int") "SystemProperties native getters should be spoofed."
  Assert-True ($content -match "ro[.]product[.]cpu[.]abi" -and $content -match "arm64-v8a") "CPU ABI should be spoofed as arm64-v8a."
  Assert-True ($content -match "Mali-T880") "GPU renderer should match the SM-N935F/Exynos profile."
  Assert-True ($content -match "totalMem" -and $content -match "4294967296") "Total memory should be spoofed as 4 GiB."
}

if ($failures.Count -gt 0) {
  Write-Host "Frida hardware spoof tests failed:" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "Frida hardware spoof tests passed." -ForegroundColor Green
