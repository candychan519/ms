param(
  [string]$AdbPath = "C:\LDPlayer\LDPlayer9\adb.exe",
  [string]$Serial = "127.0.0.1:5555",
  [string]$Key = "A",
  [int]$Count = 10,
  [int]$IntervalMs = 250,
  [int]$DurationSeconds = 0,
  [int]$MaxDurationSeconds = 30,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-KeyCode {
  param([string]$KeyName)

  $normalized = $KeyName.Trim().ToUpperInvariant()

  if ($normalized -match '^KEYCODE_') {
    $normalized = $normalized.Substring(8)
  }

  if ($normalized.Length -eq 1 -and $normalized[0] -ge [char]'A' -and $normalized[0] -le [char]'Z') {
    return [pscustomobject]@{
      Name = "KEYCODE_$normalized"
      Code = 29 + ([int][char]$normalized[0] - [int][char]'A')
    }
  }

  if ($normalized.Length -eq 1 -and $normalized[0] -ge [char]'0' -and $normalized[0] -le [char]'9') {
    return [pscustomobject]@{
      Name = "KEYCODE_$normalized"
      Code = 7 + ([int][char]$normalized[0] - [int][char]'0')
    }
  }

  $known = @{
    "ENTER" = 66
    "SPACE" = 62
    "BACK" = 4
    "ESCAPE" = 111
    "TAB" = 61
  }

  if ($known.ContainsKey($normalized)) {
    return [pscustomobject]@{
      Name = "KEYCODE_$normalized"
      Code = $known[$normalized]
    }
  }

  throw "Unsupported key '$KeyName'. Supported keys: A-Z, 0-9, ENTER, SPACE, BACK, ESCAPE, TAB."
}

if (-not (Test-Path -LiteralPath $AdbPath -PathType Leaf)) {
  throw "ADB executable was not found: $AdbPath"
}

if ($Serial -notmatch '^[^:\s]+:\d+$|^emulator-\d+$') {
  throw "Serial must be an ADB serial such as 127.0.0.1:5555 or emulator-5554."
}

if ($IntervalMs -lt 50) {
  throw "IntervalMs must be at least 50 to avoid an unsafe input flood."
}

if ($Count -lt 0) {
  throw "Count must be 0 or greater."
}

if ($DurationSeconds -lt 0) {
  throw "DurationSeconds must be 0 or greater."
}

if ($DurationSeconds -gt $MaxDurationSeconds) {
  throw "DurationSeconds '$DurationSeconds' exceeds the safety limit '$MaxDurationSeconds'. Use short bounded runs only."
}

$keyCode = Resolve-KeyCode -KeyName $Key

if ($DurationSeconds -gt 0) {
  $Count = [Math]::Max(1, [Math]::Floor(($DurationSeconds * 1000) / $IntervalMs))
}

if ($Count -eq 0) {
  throw "Count resolved to 0. Use Count >= 1 or DurationSeconds > 0."
}

if ($DryRun) {
  Write-Output "DRY-RUN key=$($keyCode.Name) code=$($keyCode.Code) serial=$Serial count=$Count intervalMs=$IntervalMs"
  for ($i = 1; $i -le $Count; $i++) {
    Write-Output "DRY-RUN ${i}/${Count}: $AdbPath -s $Serial shell input keyevent $($keyCode.Code)"
  }
  return
}

for ($i = 1; $i -le $Count; $i++) {
  $output = & $AdbPath -s $Serial shell input keyevent $keyCode.Code 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "ADB keyevent failed at ${i}/${Count} with exit code ${LASTEXITCODE}: $($output -join [Environment]::NewLine)"
  }

  if ($i -lt $Count) {
    Start-Sleep -Milliseconds $IntervalMs
  }
}

Write-Output "Sent $Count $($keyCode.Name) event(s) to $Serial at ${IntervalMs}ms intervals."
