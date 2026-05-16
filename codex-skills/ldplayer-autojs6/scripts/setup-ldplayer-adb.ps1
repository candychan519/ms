param(
  [string]$AdbPath,
  [string]$Endpoint = "127.0.0.1:5555",
  [switch]$DryRun,
  [switch]$Json,
  [switch]$PassThru,
  [switch]$SkipDeviceCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-AdbExecutable {
  param([string]$RequestedPath)

  if ($RequestedPath) {
    $expanded = [Environment]::ExpandEnvironmentVariables($RequestedPath)
    if (-not (Test-Path -LiteralPath $expanded -PathType Leaf)) {
      throw "ADB executable was not found at '$RequestedPath'."
    }

    return (Resolve-Path -LiteralPath $expanded).Path
  }

  $candidates = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:ProgramFiles\LDPlayer\LDPlayer9\adb.exe",
    "${env:ProgramFiles(x86)}\LDPlayer\LDPlayer9\adb.exe",
    "C:\LDPlayer\LDPlayer9\adb.exe",
    "C:\LDPlayer\LDPlayer4\adb.exe"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }

  $fromPath = Get-Command adb.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($fromPath) {
    return $fromPath.Source
  }

  throw "ADB executable was not found. Pass -AdbPath or install Android platform-tools/LDPlayer."
}

function Invoke-AdbStep {
  param(
    [string]$ResolvedAdbPath,
    [string]$Name,
    [string[]]$Arguments,
    [switch]$DryRun
  )

  if ($DryRun) {
    return [pscustomobject]@{
      Name = $Name
      Command = $ResolvedAdbPath
      Arguments = $Arguments
      ExitCode = 0
      Output = @("<dry-run>")
      DryRun = $true
    }
  }

  $output = & $ResolvedAdbPath @Arguments 2>&1
  $exitCode = $LASTEXITCODE

  return [pscustomobject]@{
    Name = $Name
    Command = $ResolvedAdbPath
    Arguments = $Arguments
    ExitCode = $exitCode
    Output = @($output | ForEach-Object { $_.ToString() })
    DryRun = $false
  }
}

function Test-AdbDeviceReady {
  param(
    [object[]]$DeviceOutput,
    [string]$Endpoint
  )

  foreach ($line in $DeviceOutput) {
    $text = $line.ToString().Trim()
    if ($text -match ("^" + [regex]::Escape($Endpoint) + "\s+device(\s|$)")) {
      return $true
    }
  }

  return $false
}

if ($Endpoint -notmatch '^[^:\s]+:\d+$') {
  throw "Endpoint must be in host:port form, for example 127.0.0.1:5555."
}

$resolvedAdbPath = Resolve-AdbExecutable -RequestedPath $AdbPath
$steps = @(
  @{ Name = "version"; Arguments = @("version") },
  @{ Name = "start-server"; Arguments = @("start-server") },
  @{ Name = "connect"; Arguments = @("connect", $Endpoint) },
  @{ Name = "devices"; Arguments = @("devices") }
)

$results = foreach ($step in $steps) {
  $result = Invoke-AdbStep `
    -ResolvedAdbPath $resolvedAdbPath `
    -Name $step.Name `
    -Arguments $step.Arguments `
    -DryRun:$DryRun

  if (-not $DryRun -and $result.ExitCode -ne 0) {
    throw "ADB step '$($step.Name)' failed with exit code $($result.ExitCode): $($result.Output -join [Environment]::NewLine)"
  }

  $result
}

if (-not $DryRun -and -not $SkipDeviceCheck) {
  $devicesResult = @($results | Where-Object { $_.Name -eq "devices" })[0]
  if (-not (Test-AdbDeviceReady -DeviceOutput $devicesResult.Output -Endpoint $Endpoint)) {
    throw "ADB endpoint '$Endpoint' is not ready. Expected '$Endpoint device' in 'adb devices', got: $($devicesResult.Output -join [Environment]::NewLine)"
  }
}

if ($Json) {
  $results | ConvertTo-Json -Depth 5
} elseif ($PassThru) {
  $results
} else {
  foreach ($result in $results) {
    $joinedArgs = $result.Arguments -join " "
    $prefix = if ($result.DryRun) { "DRY-RUN" } else { "OK" }
    Write-Output "$prefix $($result.Name): $($result.Command) $joinedArgs"
  }
}
