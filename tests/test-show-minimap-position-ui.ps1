param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "tools\show-minimap-position-ui.ps1"
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

Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "show-minimap-position-ui.ps1 should exist."

if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
  $scriptText = Get-Content -LiteralPath $scriptPath -Raw
  Assert-True ($scriptText -match "System\.Windows\.Forms") "UI should use Windows Forms."
  Assert-True ($scriptText -match '메이플 콘솔') "UI should use the Korean console name."
  Assert-True ($scriptText -match '맵 선택') "UI should include a left-side map selection area."
  Assert-True ($scriptText -match "mapProfiles") "UI should define map-specific profiles."
  Assert-True ($scriptText -match "SkillDescription") "Map profiles should own their displayed descriptions."
  Assert-True ($scriptText -match "빅토리아로드 헤네시스동쪽풀숲") "UI should include the previous Henesys east grassland map profile."
  Assert-True ($scriptText -match "선셋로드 사헬지대2") "UI should include the Sahel Zone 2 map profile."
  Assert-True ($scriptText -match "선셋로드 꿈꾸는 사막") "UI should include the Dreaming Desert map profile."
  Assert-True ($scriptText -match 'defaultMapName = "선셋로드 꿈꾸는 사막"') "UI should default to the current Dreaming Desert map by name."
  Assert-True ($scriptText -match 'IndexOf\(\$defaultMapName\)') "UI should select the default map by name instead of a fragile index."
  Assert-True ($scriptText -match "mapListBox") "UI should expose map profiles through a list box."
  Assert-True ($scriptText -match "HorizontalScrollbar") "UI should allow long map names to be read in the map list."
  Assert-True ($scriptText -match "SelectedIndexChanged") "UI should update settings when a map is selected."
  Assert-True ($scriptText -match "find-minimap-player-marker\.ps1") "UI should reuse the minimap marker detector."
  Assert-True ($scriptText -match '"-Watch"') "UI should keep one marker watcher process running."
  Assert-True ($scriptText -match '"-Samples", "0"') "UI should run the marker watcher continuously."
  Assert-True ($scriptText -match '"-Json"') "UI should consume machine-readable detector output."
  Assert-True ($scriptText -match '"-MinimapX"') "UI should pass the selected map's minimap X bound to the marker detector."
  Assert-True ($scriptText -match '"-MinimapY"') "UI should pass the selected map's minimap Y bound to the marker detector."
  Assert-True ($scriptText -match '"-MinimapWidth"') "UI should pass the selected map's minimap width to the marker detector."
  Assert-True ($scriptText -match '"-MinimapHeight"') "UI should pass the selected map's minimap height to the marker detector."
  Assert-True ($scriptText -match '"-MaxMarkerWidth"') "UI should pass map-specific marker width filtering to the marker detector."
  Assert-True ($scriptText -match '"-MaxMarkerHeight"') "UI should pass map-specific marker height filtering to the marker detector."
  Assert-True ($scriptText -match '"-MinMarkerLocalY"') "UI should pass map-specific local Y filtering to the marker detector."
  Assert-True ($scriptText -match '"-MaxMarkerLocalY"') "UI should pass map-specific local Y filtering to the marker detector."
  Assert-True ($scriptText -match "MinimapWidth = 170") "Sahel Zone 2 should use a tighter minimap search width."
  Assert-True ($scriptText -match "MinMarkerLocalY = 70") "Sahel Zone 2 should filter out upper static yellow minimap components."
  Assert-True ($scriptText -match "MaxMarkerLocalY = 88") "Sahel Zone 2 should filter out lower static yellow terrain."
  Assert-True ($scriptText -match "MinimapWidth = 177") "Dreaming Desert should use its ADB minimap width."
  Assert-True ($scriptText -match "MinimapHeight = 82") "Dreaming Desert should use its ADB minimap height."
  Assert-True ($scriptText -match "MinMarkerLocalY = 35") "Dreaming Desert should filter upper yellow minimap decorations."
  Assert-True ($scriptText -match "MaxMarkerLocalY = 62") "Dreaming Desert should filter lower yellow minimap decorations."
  Assert-True ($scriptText -match "CoordinateJumpMaxPx = 170") "Dreaming Desert should accept large left-right minimap jumps."
  Assert-True ($scriptText -match "PreciseMinimapX") "UI should prefer precise marker X coordinates when the detector reports them."
  Assert-True ($scriptText -match "PreciseMinimapY") "UI should prefer precise marker Y coordinates when the detector reports them."
  Assert-True ($scriptText -match "좌표 급변 무시") "UI should report ignored marker coordinate jumps."
  Assert-True ($scriptText -match "System\.Diagnostics\.Process") "UI should poll the detector without blocking the form."
  Assert-True ($scriptText -match "BeginOutputReadLine") "UI should read marker watcher output asynchronously."
  Assert-True ($scriptText -match "DataReceivedLineQueue") "UI should queue marker watcher JSON lines."
  Assert-True ($scriptText -match "CreateDelegate") "UI should bind the output handler as a real .NET delegate."
  Assert-True ($scriptText -match "Stop-MarkerProbe") "UI should stop the marker watcher on pause, map change, and close."
  Assert-True ($scriptText -match "Get-Process -Id [`$]PID") "UI should reuse the current PowerShell executable for marker probes."
  Assert-True ($scriptText -notmatch 'Join-Path [`$]PSHOME "powershell\.exe"') "UI should not assume Windows PowerShell inside PSHOME."
  Assert-True ($scriptText -match "Clipboard") "UI should provide a coordinate copy action."
  Assert-True ($scriptText -match "Timer") "UI should refresh on a timer."
  Assert-True ($scriptText -match "캐릭터 좌표=") "UI should label the marker position as the character coordinate."
  Assert-True ($scriptText -match "상태:") "UI should show a plain status label."
  Assert-True ($scriptText -match "마지막 확인:") "UI should show when the coordinate was last checked."
  Assert-True ($scriptText -match "복사") "UI should use Korean copy text."
  Assert-True ($scriptText -notmatch "sendevent") "Coordinate UI should not send low-level input events."
  Assert-True ($scriptText -notmatch "SendInput") "Coordinate UI should not use Windows keyboard injection."
  Assert-True ($scriptText -notmatch "keybd_event") "Coordinate UI should avoid legacy keyboard injection APIs."
  Assert-True ($scriptText -notmatch "AKeyScanCode") "Coordinate UI should not define game-input scan codes."
  Assert-True ($scriptText -notmatch "Start-AHold") "Coordinate UI should not include A-repeat controls."
  Assert-True ($scriptText -notmatch "Start-AFRepeat") "Coordinate UI should not include A/F repeat controls."
  Assert-True ($scriptText -notmatch "DRepeat") "Coordinate UI should not include periodic D-repeat controls."
  Assert-True ($scriptText -notmatch "Alt\+방향키") "Coordinate UI should not include movement automation states."
  Assert-True ($scriptText -notmatch "A 누르기") "Coordinate UI should not expose an A-hold button."
}

if ($failures.Count -gt 0) {
  Write-Host "Minimap position UI tests failed:" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "Minimap position UI tests passed." -ForegroundColor Green
