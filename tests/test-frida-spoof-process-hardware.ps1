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
  Assert-True ($content -match "SM-S921N") "Model should match the attached SM-S921N profile."
  Assert-True ($content -match "Exynos 2400") "SOC should match the attached SM-S921N profile."
  Assert-True ($content -match "Xclipse 940") "GPU renderer should match the attached SM-S921N profile."
  Assert-True ($content -match "totalMem" -and $content -match "8589934592") "Total memory should be spoofed as 8 GiB."
  Assert-True ($content -match "cores: 10") "CPU cores should be spoofed as 10 for the SM-S921N profile."
  Assert-True ($content -match "DisplayMetrics" -and $content -match "densityDpi" -and $content -match "2340") "Display metrics should be spoofed without relying on the main bypass file."
  Assert-True ($content -match "WifiInfo" -and $content -match "getMacAddress" -and $content -match "getIpAddress") "Wi-Fi IP and MAC surfaces should be spoofed."
  Assert-True ($content -match "TelephonyManager" -and $content -match "getNetworkOperatorName" -and $content -match "KT") "Korean carrier telephony surfaces should be spoofed."
  Assert-True ($content -match "TimeZone" -and $content -match "Asia/Seoul") "Korean timezone should be spoofed."
  Assert-True ($content -match "vkGetPhysicalDeviceProperties" -and $content -match "vulkanDeviceName") "Vulkan GPU properties should be spoofed."
  Assert-True ($content -notmatch "AlertDialog" -and $content -notmatch "Toast" -and $content -notmatch "Hooked emulator values") "Hardware overlay should not show on-screen Frida messages."
}

if ($failures.Count -gt 0) {
  Write-Host "Frida hardware spoof tests failed:" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "Frida hardware spoof tests passed." -ForegroundColor Green
