param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "tools\start-maple-console.ps1"
$skillScriptPath = Join-Path $repoRoot "codex-skills\ldplayer-autojs6\scripts\start-maple-console.ps1"
$legacyScriptPath = Join-Path $repoRoot "tools\show-minimap-position-ui.ps1"
$legacySkillScriptPath = Join-Path $repoRoot "codex-skills\ldplayer-autojs6\scripts\show-minimap-position-ui.ps1"
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

function Assert-TextFits {
  param(
    [string]$Text,
    [int]$Width,
    [System.Drawing.Font]$Font,
    [int]$HorizontalPadding,
    [string]$Message
  )

  $measuredWidth = [System.Windows.Forms.TextRenderer]::MeasureText($Text, $Font).Width + $HorizontalPadding
  Assert-True ($measuredWidth -le $Width) ("{0} Measured={1}px, available={2}px." -f $Message, $measuredWidth, $Width)
}

$labelFont = New-Object System.Drawing.Font("Malgun Gothic", 10, [System.Drawing.FontStyle]::Regular)
$smallFont = New-Object System.Drawing.Font("Malgun Gothic", 9, [System.Drawing.FontStyle]::Regular)
$coordFont = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)

Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "start-maple-console.ps1 should exist as the canonical Maple console entrypoint."
Assert-True (Test-Path -LiteralPath $skillScriptPath -PathType Leaf) "Bundled skill copy of start-maple-console.ps1 should exist."
Assert-True (Test-Path -LiteralPath $legacyScriptPath -PathType Leaf) "Legacy show-minimap-position-ui.ps1 wrapper should remain for compatibility."
Assert-True (Test-Path -LiteralPath $legacySkillScriptPath -PathType Leaf) "Bundled legacy show-minimap-position-ui.ps1 wrapper should remain for compatibility."

if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
  $scriptText = Get-Content -LiteralPath $scriptPath -Raw
  try {
    [scriptblock]::Create($scriptText) | Out-Null
  } catch {
    Add-Failure ("start-maple-console.ps1 should parse as PowerShell: {0}" -f $_.Exception.Message)
  }

  if (Test-Path -LiteralPath $skillScriptPath -PathType Leaf) {
    $skillScriptText = Get-Content -LiteralPath $skillScriptPath -Raw
    try {
      [scriptblock]::Create($skillScriptText) | Out-Null
    } catch {
      Add-Failure ("Bundled skill copy should parse as PowerShell: {0}" -f $_.Exception.Message)
    }

    $normalizedScriptText = $scriptText -replace "`r`n", "`n"
    $normalizedSkillScriptText = $skillScriptText -replace "`r`n", "`n"
    Assert-True ($normalizedScriptText -eq $normalizedSkillScriptText) "Bundled skill copy should stay in sync with the tools copy."
  }

  foreach ($legacyPath in @($legacyScriptPath, $legacySkillScriptPath)) {
    if (-not (Test-Path -LiteralPath $legacyPath -PathType Leaf)) { continue }
    $legacyText = Get-Content -LiteralPath $legacyPath -Raw
    try {
      [scriptblock]::Create($legacyText) | Out-Null
    } catch {
      Add-Failure ("Legacy wrapper should parse as PowerShell: {0}" -f $_.Exception.Message)
    }
    Assert-True ($legacyText -match "start-maple-console\.ps1") "Legacy wrapper should forward to start-maple-console.ps1."
    Assert-True ($legacyText -notmatch "System\.Windows\.Forms") "Legacy wrapper should not contain the main Windows Forms implementation."
  }

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
  Assert-True ($scriptText -match 'AutoScaleMode = \[System\.Windows\.Forms\.AutoScaleMode\]::None') "Maple console should disable automatic DPI scaling so the utility window does not become huge."
  Assert-True ($scriptText -match 'ClientSize = New-Object System\.Drawing\.Size\(730, 300\)') "UI should use a compact client area that still fits Korean labels."
  Assert-True ($scriptText -match 'MinimumSize = New-Object System\.Drawing\.Size\(710, 340\)') "UI should keep a large enough minimum window size without becoming huge."
  Assert-True ($scriptText -match '\$mapGroup\.Size = New-Object System\.Drawing\.Size\(330, 250\)') "Map selection area should be wide enough for Korean map names."
  Assert-True ($scriptText -match '\$mapListBox\.Size = New-Object System\.Drawing\.Size\(304, 96\)') "Map list should show all three maps without tight clipping."
  Assert-True ($scriptText -match '\$coordLabel = New-Label "캐릭터 좌표=\(--, --\)" 360 24 350 50') "Coordinate label should have enough width for the full placeholder text."
  Assert-True ($scriptText -match '\$aHoldButton\.Size = New-Object System\.Drawing\.Size\(120, 32\)') "A-hold button should have enough width for Korean text."
  Assert-True ($scriptText -match '\$afRepeatButton\.Size = New-Object System\.Drawing\.Size\(160, 32\)') "v2 repeat button should have enough width for its full label."
  Assert-True ($scriptText -match '\$dRepeatCheckBox\.Size = New-Object System\.Drawing\.Size\(100, 28\)') "D checkbox should have enough width for its full label."
  Assert-True ($scriptText -match '\$dRepeatIntervalLabel = New-Label "D 간격" 480 262 90 30') "D interval label should have enough width for its full text."
  Assert-TextFits "빅토리아로드 헤네시스동쪽풀숲" 304 $smallFont 28 "Longest map name should fit in the map list."
  Assert-TextFits "캐릭터 좌표=(--, --)" 350 $coordFont 24 "Coordinate placeholder should fit in its label."
  Assert-TextFits "A 누르기" 120 $smallFont 36 "A button text should fit."
  Assert-TextFits "A→왼쪽+F v2" 160 $smallFont 36 "v2 button text should fit."
  Assert-TextFits "D 사용" 100 $smallFont 32 "D checkbox text should fit."
  Assert-TextFits "D 간격" 90 $smallFont 16 "D interval label text should fit."
  Assert-TextFits "일시정지" 116 $smallFont 30 "Pause button text should fit."
  Assert-TextFits "복사" 86 $smallFont 30 "Copy button text should fit."
  Assert-True ($scriptText -notmatch "SendInput") "Coordinate UI should not use Windows keyboard injection."
  Assert-True ($scriptText -notmatch "keybd_event") "Coordinate UI should avoid legacy keyboard injection APIs."
  Assert-True ($scriptText -notmatch "Alt\+방향키") "Coordinate UI should not include movement automation states."
  Assert-True ($scriptText -match "sendevent") "Repeat UI should send bounded low-level Android input events through ADB."
  Assert-True ($scriptText -match "InputEventPath must be an Android input event path") "Repeat UI should validate the Android input event path before building ADB shell commands."
  Assert-True ($scriptText -match "Input scan codes must be 0 or greater") "Repeat UI should reject invalid scan codes before building ADB shell commands."
  Assert-True ($scriptText -match '/dev/input/event2') "Repeat UI should default to LDPlayer's known input event path."
  Assert-True ($scriptText -match 'AKeyScanCode = 30') "Repeat UI should define the A key scan code."
  Assert-True ($scriptText -match 'DKeyScanCode = 32') "Repeat UI should define the D key scan code."
  Assert-True ($scriptText -match 'FKeyScanCode = 33') "Repeat UI should define the F key scan code."
  Assert-True ($scriptText -match 'LeftKeyScanCode = 105') "Repeat UI should define the left arrow scan code."
  Assert-True ($scriptText -match 'RightKeyScanCode = 106') "Repeat UI should define the right arrow scan code."
  Assert-True ($scriptText -match 'AHoldIntervalMs = 120') "A-hold timer should use the previous repeat interval."
  Assert-True ($scriptText -match 'AFRepeatKeyHoldMs = 120') "v2 repeat should keep the previous key hold duration."
  Assert-True ($scriptText -match 'AFRepeatBetweenKeyMs = 70') "v2 repeat should keep the previous inter-key delay."
  Assert-True ($scriptText -match 'AFRepeatIntervalMs = 500') "v2 repeat should keep the previous repeat interval."
  Assert-True ($scriptText -match 'AFRepeatLeftBoundaryX = 20') "v2 repeat should keep the left minimap turn boundary."
  Assert-True ($scriptText -match 'AFRepeatRightBoundaryX = 150') "v2 repeat should keep the default right minimap turn boundary."
  Assert-True ($scriptText -match 'AFRepeatRightBoundaryX = 157') "Dreaming Desert should keep its wider right turn boundary."
  Assert-True ($scriptText -match 'DRepeatIntervalSeconds = 30') "D-repeat should default to the previous 30 second interval."
  Assert-True ($scriptText -match "Start-AHold") "Repeat UI should include an A-hold start function."
  Assert-True ($scriptText -match "Stop-AHold") "Repeat UI should include an A-hold stop function."
  Assert-True ($scriptText -match "Start-AFRepeat") "Repeat UI should include the v2 A/direction/F repeat start function."
  Assert-True ($scriptText -match "Stop-AFRepeat") "Repeat UI should include the v2 A/direction/F repeat stop function."
  Assert-True ($scriptText -match "Start-AdbShellInputProcess") "Repeat UI should send ADB input from a background process so the stop button remains clickable."
  Assert-True ($scriptText -match "Invoke-InputEventCommand -Async") "Repeat timers should not block the Windows Forms UI thread while sending ADB input."
  Assert-True ($scriptText -match "Release-RepeatKeys") "Repeat stop actions should release A, D, F, and direction keys."
  Assert-True ($scriptText -match "Stop-ActiveInputProcess") "Repeat stop actions should interrupt any in-flight input process before releasing keys."
  Assert-True ($scriptText -match "Send-AFKeyTapCycle") "Repeat UI should send the v2 A/direction/F input cycle."
  Assert-True ($scriptText -match "Update-AFRepeatDirectionFromCoordinate") "v2 repeat should turn based on minimap coordinates."
  Assert-True ($scriptText -match "Send-DKeyTapDuringARepeat") "D-repeat should briefly release and restore A while tapping D."
  Assert-True ($scriptText -match "Invoke-DRepeatIfDue") "D-repeat should be interval-gated instead of firing every tick."
  Assert-True ($scriptText -match "A 누르기") "Repeat UI should expose the A-hold button."
  Assert-True ($scriptText -match "A 반복 중지") "Repeat UI should expose a stop state for A-hold."
  Assert-True ($scriptText -match "A→왼쪽\+F v2") "Repeat UI should expose the v2 repeat button."
  Assert-True ($scriptText -match "v2 반복 중지") "Repeat UI should expose a stop state for v2 repeat."
  Assert-True ($scriptText -match "D 사용") "Repeat UI should expose the periodic D checkbox."
  Assert-True ($scriptText -match "D 간격") "Repeat UI should expose the D interval field label."
  Assert-True ($scriptText -match "dRepeatCheckBox") "Repeat UI should wire the D checkbox."
  Assert-True ($scriptText -match "dRepeatIntervalTextBox") "Repeat UI should wire the D interval text box."
  Assert-True ($scriptText -match "Get-DRepeatIntervalMs") "Repeat UI should parse and validate the D interval."
}

if ($failures.Count -gt 0) {
  Write-Host "Maple console tests failed:" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "Maple console tests passed." -ForegroundColor Green
