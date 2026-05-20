param(
  [Parameter(Mandatory = $true)]
  [string]$LogPath,
  [string[]]$RequirePattern = @(),
  [string[]]$ForbidPattern = @(),
  [string[]]$AllowWarningPattern = @(),
  [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-InputFile {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Frida log file was not found: $Path"
  }

  return (Resolve-Path -LiteralPath $Path).Path
}

function Get-PatternSummary {
  param(
    [string]$Content,
    [string[]]$Lines,
    [string]$Pattern
  )

  try {
    $matches = [regex]::Matches($Content, $Pattern)
    $sampleLines = @(
      $Lines |
        Where-Object { $_ -match $Pattern } |
        Select-Object -First 3
    )
  } catch {
    throw "Invalid regex pattern '$Pattern': $($_.Exception.Message)"
  }

  return [pscustomobject]@{
    Pattern = $Pattern
    Count = $matches.Count
    Samples = $sampleLines
  }
}

$resolvedLogPath = Resolve-InputFile -Path $LogPath
$content = Get-Content -LiteralPath $resolvedLogPath -Raw
if ($null -eq $content) {
  $content = ""
}
$lines = @($content -split "`r?`n")

$required = New-Object System.Collections.Generic.List[object]
$forbidden = New-Object System.Collections.Generic.List[object]
$warnings = New-Object System.Collections.Generic.List[object]
$failures = New-Object System.Collections.Generic.List[string]

foreach ($pattern in $RequirePattern) {
  $summary = Get-PatternSummary -Content $content -Lines $lines -Pattern $pattern
  $required.Add($summary)
  if ($summary.Count -eq 0) {
    $failures.Add("Missing required pattern: $pattern")
  }
}

foreach ($pattern in $ForbidPattern) {
  $summary = Get-PatternSummary -Content $content -Lines $lines -Pattern $pattern
  $forbidden.Add($summary)
  if ($summary.Count -gt 0) {
    $failures.Add("Forbidden pattern was present: $pattern")
  }
}

foreach ($pattern in $AllowWarningPattern) {
  $summary = Get-PatternSummary -Content $content -Lines $lines -Pattern $pattern
  if ($summary.Count -gt 0) {
    $warnings.Add($summary)
  }
}

$result = [pscustomobject]@{
  Passed = ($failures.Count -eq 0)
  LogPath = $resolvedLogPath
  Required = $required.ToArray()
  Forbidden = $forbidden.ToArray()
  Warnings = $warnings.ToArray()
  Failures = $failures.ToArray()
}

if ($Json) {
  $result | ConvertTo-Json -Depth 6
} else {
  if ($result.Passed) {
    Write-Output "PASS Frida log verification: $resolvedLogPath"
  } else {
    Write-Output "FAIL Frida log verification: $resolvedLogPath"
    foreach ($failure in $failures) {
      Write-Output " - $failure"
    }
  }

  foreach ($warning in $warnings) {
    Write-Output "WARN allowed pattern matched $($warning.Count) time(s): $($warning.Pattern)"
  }
}

if (-not $result.Passed) {
  exit 1
}
