param(
  [int]$IntervalMs = 250,
  [string]$MarkerToolPath,
  [string]$AdbPath = "C:\LDPlayer\LDPlayer9\adb.exe",
  [string]$Serial = "127.0.0.1:5555",
  [string]$InputEventPath = "/dev/input/event2",
  [int]$AKeyScanCode = 30,
  [int]$DKeyScanCode = 32,
  [int]$FKeyScanCode = 33,
  [int]$LeftKeyScanCode = 105,
  [int]$RightKeyScanCode = 106,
  [int]$AHoldIntervalMs = 120,
  [int]$AFRepeatKeyHoldMs = 120,
  [int]$AFRepeatBetweenKeyMs = 70,
  [int]$AFRepeatIntervalMs = 500,
  [int]$AFRepeatLeftBoundaryX = 20,
  [int]$AFRepeatRightBoundaryX = 150,
  [double]$DRepeatIntervalSeconds = 30,
  [switch]$TopMost
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Collections.Concurrent;
using System.Diagnostics;

public sealed class DataReceivedLineQueue
{
    public readonly ConcurrentQueue<string> Lines = new ConcurrentQueue<string>();

    public void Enqueue(object sender, DataReceivedEventArgs e)
    {
        if (!String.IsNullOrWhiteSpace(e.Data))
        {
            Lines.Enqueue(e.Data);
        }
    }
}
"@

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $MarkerToolPath) {
  $MarkerToolPath = Join-Path $repoRoot "tools\find-minimap-player-marker.ps1"
  if (-not (Test-Path -LiteralPath $MarkerToolPath -PathType Leaf)) {
    $MarkerToolPath = Join-Path $PSScriptRoot "find-minimap-player-marker.ps1"
  }
}

$MarkerToolPath = [System.IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($MarkerToolPath))
if (-not (Test-Path -LiteralPath $MarkerToolPath -PathType Leaf)) {
  throw "Minimap marker tool was not found: $MarkerToolPath"
}
if (-not (Test-Path -LiteralPath $AdbPath -PathType Leaf)) {
  throw "ADB executable was not found: $AdbPath"
}
if ($Serial -notmatch '^[^:\s]+:\d+$|^emulator-\d+$') {
  throw "Serial must be an ADB serial such as 127.0.0.1:5555 or emulator-5554."
}
if ($InputEventPath -notmatch '^/dev/input/event\d+$') {
  throw "InputEventPath must be an Android input event path such as /dev/input/event2."
}
foreach ($scanCode in @($AKeyScanCode, $DKeyScanCode, $FKeyScanCode, $LeftKeyScanCode, $RightKeyScanCode)) {
  if ($scanCode -lt 0) {
    throw "Input scan codes must be 0 or greater."
  }
}
if ($IntervalMs -lt 250) {
  $IntervalMs = 250
}
if ($AHoldIntervalMs -lt 50) {
  $AHoldIntervalMs = 50
}
if ($AFRepeatKeyHoldMs -lt 20) {
  $AFRepeatKeyHoldMs = 20
}
if ($AFRepeatBetweenKeyMs -lt 0) {
  $AFRepeatBetweenKeyMs = 0
}
if ($AFRepeatIntervalMs -lt 100) {
  $AFRepeatIntervalMs = 100
}
if ($AFRepeatLeftBoundaryX -lt 0) {
  $AFRepeatLeftBoundaryX = 0
}
if ($AFRepeatRightBoundaryX -le $AFRepeatLeftBoundaryX) {
  $AFRepeatRightBoundaryX = $AFRepeatLeftBoundaryX + 1
}
if ($DRepeatIntervalSeconds -lt 1) {
  $DRepeatIntervalSeconds = 1
}

$mapProfiles = @(
  [pscustomobject]@{
    Name = "빅토리아로드 헤네시스동쪽풀숲"
    MinimapX = 8
    MinimapY = 96
    MinimapWidth = 207
    MinimapHeight = 101
    MaxMarkerWidth = 24
    MaxMarkerHeight = 24
    MinMarkerLocalY = -1
    MaxMarkerLocalY = -1
    CoordinateJumpMaxPx = 45
    AFRepeatLeftBoundaryX = $AFRepeatLeftBoundaryX
    AFRepeatRightBoundaryX = $AFRepeatRightBoundaryX
    SkillDescription = "A 반복 / v2 방향+F"
  },
  [pscustomobject]@{
    Name = "선셋로드 사헬지대2"
    MinimapX = 8
    MinimapY = 96
    MinimapWidth = 170
    MinimapHeight = 101
    MaxMarkerWidth = 16
    MaxMarkerHeight = 16
    MinMarkerLocalY = 70
    MaxMarkerLocalY = 88
    CoordinateJumpMaxPx = 45
    AFRepeatLeftBoundaryX = $AFRepeatLeftBoundaryX
    AFRepeatRightBoundaryX = $AFRepeatRightBoundaryX
    SkillDescription = "A 반복 / v2 방향+F"
  },
  [pscustomobject]@{
    Name = "선셋로드 꿈꾸는 사막"
    MinimapX = 8
    MinimapY = 96
    MinimapWidth = 177
    MinimapHeight = 82
    MaxMarkerWidth = 16
    MaxMarkerHeight = 16
    MinMarkerLocalY = 35
    MaxMarkerLocalY = 62
    CoordinateJumpMaxPx = 170
    AFRepeatLeftBoundaryX = 20
    AFRepeatRightBoundaryX = 157
    SkillDescription = "A 반복 / v2 방향+F"
  }
)

$defaultMapName = "선셋로드 꿈꾸는 사막"
$selectedMapProfile = $mapProfiles | Where-Object { $_.Name -eq $defaultMapName } | Select-Object -First 1
if (-not $selectedMapProfile) {
  $selectedMapProfile = $mapProfiles[0]
}

$monitoring = $true
$currentProcess = $null
$currentOutputHandler = $null
$currentErrorHandler = $null
$currentOutputLines = New-Object DataReceivedLineQueue
$currentErrorLines = New-Object DataReceivedLineQueue
$lastCoordinateText = ""
$lastMinimapX = $null
$aHoldActive = $false
$aHoldTimer = $null
$aHoldIsDown = $false
$dRepeatNextActionAt = [DateTime]::MinValue
$afRepeatActive = $false
$afRepeatTimer = $null
$afRepeatDirectionScanCode = $LeftKeyScanCode
$afRepeatPendingDirectionDoubleTap = $false
$inputProcess = $null

function New-Label {
  param(
    [string]$Text,
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height,
    [System.Drawing.Font]$Font,
    [System.Drawing.Color]$Color
  )

  $label = New-Object System.Windows.Forms.Label
  $label.Text = $Text
  $label.Location = New-Object System.Drawing.Point($X, $Y)
  $label.Size = New-Object System.Drawing.Size($Width, $Height)
  $label.Font = $Font
  $label.ForeColor = $Color
  $label.BackColor = [System.Drawing.Color]::Transparent
  $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
  return $label
}

function Get-CurrentPowerShellPath {
  $powerShellExe = (Get-Process -Id $PID).Path
  if (-not $powerShellExe) {
    $powerShellExe = (Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
  }
  if (-not $powerShellExe) {
    $powerShellExe = (Get-Command powershell -ErrorAction Stop | Select-Object -First 1 -ExpandProperty Source)
  }
  return $powerShellExe
}

function Set-StatusColor {
  param(
    [System.Windows.Forms.Label]$Label,
    [string]$Text,
    [System.Drawing.Color]$Color
  )

  $Label.Text = $Text
  $Label.ForeColor = $Color
}

function Get-InputEventCommand {
  param(
    [int]$ScanCode,
    [int]$Value
  )

  return @(
    "sendevent $InputEventPath 1 $ScanCode $Value",
    "sendevent $InputEventPath 0 0 0"
  )
}

function Get-InputSleepCommand {
  param([int]$HoldMs)

  $seconds = [Math]::Max(0, $HoldMs) / 1000.0
  return ("sleep {0}" -f $seconds.ToString("0.###", [System.Globalization.CultureInfo]::InvariantCulture))
}

function Start-AdbShellInputProcess {
  param([string]$CommandText)

  $escapedCommandText = $CommandText.Replace('"', '\"')
  $argumentText = ('-s "{0}" shell "{1}"' -f $Serial, $escapedCommandText)
  $process = Start-Process -FilePath $AdbPath -ArgumentList $argumentText -WindowStyle Hidden -PassThru
  $script:inputProcess = $process
  return $process
}

function Stop-ActiveInputProcess {
  if ($script:inputProcess -and -not $script:inputProcess.HasExited) {
    try {
      $script:inputProcess.Kill()
      $script:inputProcess.WaitForExit(500) | Out-Null
    } catch {
    }
  }
}

function Invoke-InputEventCommand {
  param(
    [string[]]$Commands,
    [switch]$Async,
    [switch]$Force
  )

  if (-not $Commands -or $Commands.Count -eq 0) {
    return $false
  }

  $commandText = ($Commands -join "; ")
  if ($Async) {
    if (-not $Force -and $script:inputProcess -and -not $script:inputProcess.HasExited) {
      return $false
    }

    Start-AdbShellInputProcess -CommandText $commandText | Out-Null
    return $true
  }

  $output = & $AdbPath -s $Serial shell $commandText 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "ADB input failed: $($output -join ' ')"
  }
  return $true
}

function Send-InputEvent {
  param(
    [int]$ScanCode,
    [int]$Value,
    [switch]$Async,
    [switch]$Force
  )

  Invoke-InputEventCommand -Commands (Get-InputEventCommand -ScanCode $ScanCode -Value $Value) -Async:$Async -Force:$Force | Out-Null
}

function Send-AKeyDown {
  Send-InputEvent -ScanCode $AKeyScanCode -Value 1 -Async -Force
  $script:aHoldIsDown = $true
}

function Send-AKeyUp {
  Send-InputEvent -ScanCode $AKeyScanCode -Value 0 -Async -Force
  $script:aHoldIsDown = $false
}

function Release-RepeatKeys {
  Stop-ActiveInputProcess
  Invoke-InputEventCommand -Async -Force -Commands @(
    (Get-InputEventCommand -ScanCode $AKeyScanCode -Value 0)
    (Get-InputEventCommand -ScanCode $DKeyScanCode -Value 0)
    (Get-InputEventCommand -ScanCode $FKeyScanCode -Value 0)
    (Get-InputEventCommand -ScanCode $LeftKeyScanCode -Value 0)
    (Get-InputEventCommand -ScanCode $RightKeyScanCode -Value 0)
  ) | Out-Null
}

function Send-DKeyTapThenAKeyDown {
  Invoke-InputEventCommand -Async -Commands @(
    (Get-InputEventCommand -ScanCode $DKeyScanCode -Value 1)
    (Get-InputSleepCommand -HoldMs $AFRepeatKeyHoldMs)
    (Get-InputEventCommand -ScanCode $DKeyScanCode -Value 0)
    (Get-InputSleepCommand -HoldMs $AFRepeatBetweenKeyMs)
    (Get-InputEventCommand -ScanCode $AKeyScanCode -Value 1)
  )
  $script:aHoldIsDown = $true
}

function Send-DKeyTapDuringARepeat {
  Invoke-InputEventCommand -Async -Commands @(
    (Get-InputEventCommand -ScanCode $AKeyScanCode -Value 0)
    (Get-InputSleepCommand -HoldMs $AFRepeatBetweenKeyMs)
    (Get-InputEventCommand -ScanCode $DKeyScanCode -Value 1)
    (Get-InputSleepCommand -HoldMs $AFRepeatKeyHoldMs)
    (Get-InputEventCommand -ScanCode $DKeyScanCode -Value 0)
    (Get-InputSleepCommand -HoldMs $AFRepeatBetweenKeyMs)
    (Get-InputEventCommand -ScanCode $AKeyScanCode -Value 1)
  )
  $script:aHoldIsDown = $true
}

function Get-DRepeatIntervalMs {
  if (-not $dRepeatIntervalTextBox) {
    return $null
  }

  try {
    $seconds = [double]$dRepeatIntervalTextBox.Text
  } catch {
    return $null
  }

  if ($seconds -lt 1) {
    return $null
  }

  return [int][Math]::Round($seconds * 1000)
}

function Get-NextDRepeatActionAt {
  if (-not $dRepeatCheckBox -or -not $dRepeatCheckBox.Checked) {
    return [DateTime]::MinValue
  }

  $intervalMs = Get-DRepeatIntervalMs
  if ($null -eq $intervalMs) {
    return [DateTime]::MinValue
  }

  return (Get-Date).AddMilliseconds($intervalMs)
}

function Start-AHold {
  if ($script:aHoldActive) {
    return $true
  }

  Send-AKeyDown
  $script:aHoldActive = $true
  $script:dRepeatNextActionAt = Get-NextDRepeatActionAt
  return $true
}

function Stop-AHold {
  if ($script:aHoldTimer) {
    $script:aHoldTimer.Stop()
  }
  if ($script:aHoldIsDown) {
    try {
      Release-RepeatKeys
    } catch {
    }
  }

  $script:aHoldActive = $false
  $script:aHoldIsDown = $false
  $script:dRepeatNextActionAt = [DateTime]::MinValue
}

function Invoke-DRepeatIfDue {
  if (-not $script:aHoldActive) {
    return $null
  }
  if (-not $dRepeatCheckBox.Checked) {
    $script:dRepeatNextActionAt = [DateTime]::MinValue
    return $null
  }

  $intervalMs = Get-DRepeatIntervalMs
  if ($null -eq $intervalMs) {
    $script:dRepeatNextActionAt = [DateTime]::MinValue
    return "D 간격 오류"
  }

  if ($script:dRepeatNextActionAt -eq [DateTime]::MinValue) {
    $script:dRepeatNextActionAt = (Get-Date).AddMilliseconds($intervalMs)
    return $null
  }
  if ((Get-Date) -lt $script:dRepeatNextActionAt) {
    return $null
  }

  if ($script:aHoldIsDown) {
    Send-DKeyTapDuringARepeat
  } else {
    Send-DKeyTapThenAKeyDown
  }

  $script:dRepeatNextActionAt = (Get-Date).AddMilliseconds($intervalMs)
  $seconds = [Math]::Round(([double]$intervalMs / 1000), 1)
  return "D 입력 완료, 다음 ${seconds}초 후"
}

function Get-SelectedAFRepeatLeftBoundaryX {
  $profile = $script:selectedMapProfile
  if ($profile -and $null -ne $profile.AFRepeatLeftBoundaryX) {
    return [double]$profile.AFRepeatLeftBoundaryX
  }
  return [double]$AFRepeatLeftBoundaryX
}

function Get-SelectedAFRepeatRightBoundaryX {
  $profile = $script:selectedMapProfile
  if ($profile -and $null -ne $profile.AFRepeatRightBoundaryX) {
    return [double]$profile.AFRepeatRightBoundaryX
  }
  return [double]$AFRepeatRightBoundaryX
}

function Get-AFRepeatDirectionText {
  if ($script:afRepeatDirectionScanCode -eq $RightKeyScanCode) {
    return "오른쪽"
  }
  return "왼쪽"
}

function Get-AFRepeatStatusText {
  return ("A→{0}+F" -f (Get-AFRepeatDirectionText))
}

function Update-AFRepeatDirectionFromCoordinate {
  if ($null -eq $script:lastMinimapX) {
    return
  }

  $x = [double]$script:lastMinimapX
  if ($x -le (Get-SelectedAFRepeatLeftBoundaryX) -and $script:afRepeatDirectionScanCode -ne $RightKeyScanCode) {
    $script:afRepeatDirectionScanCode = $RightKeyScanCode
    $script:afRepeatPendingDirectionDoubleTap = $true
  } elseif ($x -ge (Get-SelectedAFRepeatRightBoundaryX) -and $script:afRepeatDirectionScanCode -ne $LeftKeyScanCode) {
    $script:afRepeatDirectionScanCode = $LeftKeyScanCode
    $script:afRepeatPendingDirectionDoubleTap = $true
  }
}

function Start-AFRepeat {
  if ($script:afRepeatActive) {
    return $true
  }

  $script:afRepeatActive = $true
  $script:afRepeatDirectionScanCode = $LeftKeyScanCode
  $script:afRepeatPendingDirectionDoubleTap = $false
  Update-AFRepeatDirectionFromCoordinate
  return $true
}

function Stop-AFRepeat {
  if ($script:afRepeatTimer) {
    $script:afRepeatTimer.Stop()
  }
  Release-RepeatKeys
  $script:afRepeatActive = $false
  $script:afRepeatPendingDirectionDoubleTap = $false
}

function Send-AFKeyTapCycle {
  Update-AFRepeatDirectionFromCoordinate
  $directionScanCode = $script:afRepeatDirectionScanCode
  $turnCommands = @()
  if ($script:afRepeatPendingDirectionDoubleTap) {
    $turnCommands = @(
      (Get-InputEventCommand -ScanCode $directionScanCode -Value 1)
      (Get-InputSleepCommand -HoldMs $AFRepeatBetweenKeyMs)
      (Get-InputEventCommand -ScanCode $directionScanCode -Value 0)
      (Get-InputSleepCommand -HoldMs $AFRepeatBetweenKeyMs)
      (Get-InputEventCommand -ScanCode $directionScanCode -Value 1)
      (Get-InputSleepCommand -HoldMs $AFRepeatBetweenKeyMs)
      (Get-InputEventCommand -ScanCode $directionScanCode -Value 0)
      (Get-InputSleepCommand -HoldMs $AFRepeatBetweenKeyMs)
    )
    $script:afRepeatPendingDirectionDoubleTap = $false
  }

  Invoke-InputEventCommand -Async -Commands @(
    (Get-InputEventCommand -ScanCode $AKeyScanCode -Value 1)
    (Get-InputSleepCommand -HoldMs $AFRepeatKeyHoldMs)
    (Get-InputEventCommand -ScanCode $AKeyScanCode -Value 0)
    (Get-InputSleepCommand -HoldMs $AFRepeatBetweenKeyMs)
    $turnCommands
    (Get-InputEventCommand -ScanCode $directionScanCode -Value 1)
    (Get-InputSleepCommand -HoldMs $AFRepeatBetweenKeyMs)
    (Get-InputEventCommand -ScanCode $FKeyScanCode -Value 1)
    (Get-InputSleepCommand -HoldMs $AFRepeatKeyHoldMs)
    (Get-InputEventCommand -ScanCode $FKeyScanCode -Value 0)
    (Get-InputEventCommand -ScanCode $directionScanCode -Value 0)
  )
}

function Stop-MarkerProbe {
  if ($script:currentProcess) {
    try {
      if (-not $script:currentProcess.HasExited) {
        $script:currentProcess.Kill()
        $script:currentProcess.WaitForExit(1000) | Out-Null
      }
    } catch {
      # Best effort cleanup while the form is closing or changing map.
    } finally {
      $script:currentProcess.Dispose()
      $script:currentProcess = $null
      $script:currentOutputHandler = $null
      $script:currentErrorHandler = $null
    }
  }
}

function Start-MarkerProbe {
  Stop-MarkerProbe

  $script:currentOutputLines = New-Object DataReceivedLineQueue
  $script:currentErrorLines = New-Object DataReceivedLineQueue
  $profile = $script:selectedMapProfile

  $startInfo = New-Object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName = Get-CurrentPowerShellPath
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $arguments = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $MarkerToolPath,
    "-Watch",
    "-Samples", "0",
    "-IntervalMs", ([string]$IntervalMs),
    "-AdbPath", $AdbPath,
    "-Serial", $Serial,
    "-MinimapX", ([string]$profile.MinimapX),
    "-MinimapY", ([string]$profile.MinimapY),
    "-MinimapWidth", ([string]$profile.MinimapWidth),
    "-MinimapHeight", ([string]$profile.MinimapHeight),
    "-MaxMarkerWidth", ([string]$profile.MaxMarkerWidth),
    "-MaxMarkerHeight", ([string]$profile.MaxMarkerHeight),
    "-MinMarkerLocalY", ([string]$profile.MinMarkerLocalY),
    "-MaxMarkerLocalY", ([string]$profile.MaxMarkerLocalY),
    "-Json"
  )
  foreach ($argument in $arguments) {
    [void]$startInfo.ArgumentList.Add($argument)
  }

  $process = New-Object System.Diagnostics.Process
  $process.StartInfo = $startInfo
  $script:currentOutputHandler = [System.Diagnostics.DataReceivedEventHandler]::CreateDelegate(
    [System.Diagnostics.DataReceivedEventHandler],
    $script:currentOutputLines,
    "Enqueue"
  )
  $script:currentErrorHandler = [System.Diagnostics.DataReceivedEventHandler]::CreateDelegate(
    [System.Diagnostics.DataReceivedEventHandler],
    $script:currentErrorLines,
    "Enqueue"
  )
  $process.add_OutputDataReceived($script:currentOutputHandler)
  $process.add_ErrorDataReceived($script:currentErrorHandler)
  [void]$process.Start()
  $process.BeginOutputReadLine()
  $process.BeginErrorReadLine()
  $script:currentProcess = $process
}

function Update-MapInfo {
  $profile = $script:selectedMapProfile
  $mapInfoLabel.Text = ("{0}`r`n미니맵 {1},{2} {3}x{4}`r`n{5}" -f `
      $profile.Name,
      $profile.MinimapX,
      $profile.MinimapY,
      $profile.MinimapWidth,
      $profile.MinimapHeight,
      $profile.SkillDescription)
}

function Read-MarkerProbe {
  $line = $null
  while ($script:currentErrorLines.Lines.TryDequeue([ref]$line)) {
    if ($line) {
      Set-StatusColor $statusLabel "상태: 읽기 오류" ([System.Drawing.Color]::FromArgb(170, 50, 50))
    }
  }

  $latest = $null
  while ($script:currentOutputLines.Lines.TryDequeue([ref]$line)) {
    if (-not $line) { continue }
    try {
      $latest = $line | ConvertFrom-Json
    } catch {
      Set-StatusColor $statusLabel "상태: JSON 파싱 실패" ([System.Drawing.Color]::FromArgb(170, 50, 50))
    }
  }

  if (-not $latest) {
    if ($script:currentProcess -and $script:currentProcess.HasExited) {
      Set-StatusColor $statusLabel "상태: 감시 재시작" ([System.Drawing.Color]::FromArgb(120, 88, 0))
      Start-MarkerProbe
    }
    return
  }

  $updatedLabel.Text = ("마지막 확인: {0}" -f (Get-Date -Format "HH:mm:ss"))
  if (-not [bool]$latest.Found) {
    $coordLabel.Text = "캐릭터 좌표=(--, --)"
    Set-StatusColor $statusLabel "상태: 캐릭터 위치 없음" ([System.Drawing.Color]::FromArgb(170, 50, 50))
    return
  }

  $x = if ($null -ne $latest.PreciseMinimapX) { [double]$latest.PreciseMinimapX } else { [double]$latest.MinimapX }
  $y = if ($null -ne $latest.PreciseMinimapY) { [double]$latest.PreciseMinimapY } else { [double]$latest.MinimapY }
  if ($null -ne $script:lastMinimapX) {
    $jump = [Math]::Abs($x - [double]$script:lastMinimapX)
    if ($jump -gt [double]$script:selectedMapProfile.CoordinateJumpMaxPx) {
      Set-StatusColor $statusLabel ("상태: 좌표 급변 무시 ({0:0.0}->{1:0.0})" -f [double]$script:lastMinimapX, $x) ([System.Drawing.Color]::FromArgb(120, 88, 0))
      return
    }
  }

  $script:lastMinimapX = $x
  $script:lastCoordinateText = ("캐릭터 좌표=({0:0.0}, {1:0.0})" -f $x, $y)
  $coordLabel.Text = $script:lastCoordinateText
  if ($script:afRepeatActive) {
    Update-AFRepeatDirectionFromCoordinate
  }
  Set-StatusColor $statusLabel "상태: 감시 중" ([System.Drawing.Color]::FromArgb(30, 120, 70))
}

[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "메이플 콘솔"
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
$form.ClientSize = New-Object System.Drawing.Size(730, 300)
$form.MinimumSize = New-Object System.Drawing.Size(710, 340)
$form.StartPosition = "CenterScreen"
$form.TopMost = [bool]$TopMost
$form.BackColor = [System.Drawing.Color]::FromArgb(246, 248, 250)

$coordFont = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
$labelFont = New-Object System.Drawing.Font("Malgun Gothic", 10, [System.Drawing.FontStyle]::Regular)
$smallFont = New-Object System.Drawing.Font("Malgun Gothic", 9, [System.Drawing.FontStyle]::Regular)

$mapGroup = New-Object System.Windows.Forms.GroupBox
$mapGroup.Text = "맵 선택"
$mapGroup.Location = New-Object System.Drawing.Point(12, 12)
$mapGroup.Size = New-Object System.Drawing.Size(330, 250)
$mapGroup.Font = $labelFont

$mapListBox = New-Object System.Windows.Forms.ListBox
$mapListBox.Location = New-Object System.Drawing.Point(12, 24)
$mapListBox.Size = New-Object System.Drawing.Size(304, 96)
$mapListBox.Font = $smallFont
$mapListBox.HorizontalScrollbar = $true
[void]$mapListBox.Items.AddRange([string[]]($mapProfiles | ForEach-Object { $_.Name }))
$defaultIndex = $mapListBox.Items.IndexOf($defaultMapName)
if ($defaultIndex -lt 0) { $defaultIndex = 0 }
$mapListBox.SelectedIndex = $defaultIndex

$mapInfoLabel = New-Label "" 12 138 304 90 $smallFont ([System.Drawing.Color]::FromArgb(85, 95, 105))
$mapGroup.Controls.AddRange(@($mapListBox, $mapInfoLabel))

$coordLabel = New-Label "캐릭터 좌표=(--, --)" 360 24 350 50 $coordFont ([System.Drawing.Color]::FromArgb(20, 93, 160))
$statusLabel = New-Label "상태: 시작 중..." 364 88 340 24 $labelFont ([System.Drawing.Color]::FromArgb(120, 88, 0))
$updatedLabel = New-Label "마지막 확인: --" 364 114 340 22 $smallFont ([System.Drawing.Color]::FromArgb(85, 95, 105))

$toggleButton = New-Object System.Windows.Forms.Button
$toggleButton.Text = "일시정지"
$toggleButton.Location = New-Object System.Drawing.Point(500, 146)
$toggleButton.Size = New-Object System.Drawing.Size(116, 32)

$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Text = "복사"
$copyButton.Location = New-Object System.Drawing.Point(626, 146)
$copyButton.Size = New-Object System.Drawing.Size(86, 32)

$aHoldButton = New-Object System.Windows.Forms.Button
$aHoldButton.Text = "A 누르기"
$aHoldButton.Location = New-Object System.Drawing.Point(360, 184)
$aHoldButton.Size = New-Object System.Drawing.Size(120, 32)

$aHoldLabel = New-Label "스킬 반복: 꺼짐" 500 184 210 32 $smallFont ([System.Drawing.Color]::FromArgb(85, 95, 105))

$afRepeatButton = New-Object System.Windows.Forms.Button
$afRepeatButton.Text = "A→왼쪽+F v2"
$afRepeatButton.Location = New-Object System.Drawing.Point(360, 224)
$afRepeatButton.Size = New-Object System.Drawing.Size(160, 32)

$afRepeatLabel = New-Label "v2 반복: 꺼짐" 540 224 170 32 $smallFont ([System.Drawing.Color]::FromArgb(85, 95, 105))

$dRepeatCheckBox = New-Object System.Windows.Forms.CheckBox
$dRepeatCheckBox.Text = "D 사용"
$dRepeatCheckBox.Location = New-Object System.Drawing.Point(360, 264)
$dRepeatCheckBox.Size = New-Object System.Drawing.Size(100, 28)
$dRepeatCheckBox.Font = $smallFont

$dRepeatIntervalLabel = New-Label "D 간격" 480 262 90 30 $smallFont ([System.Drawing.Color]::FromArgb(85, 95, 105))

$dRepeatIntervalTextBox = New-Object System.Windows.Forms.TextBox
$dRepeatIntervalTextBox.Text = ([string]$DRepeatIntervalSeconds)
$dRepeatIntervalTextBox.Location = New-Object System.Drawing.Point(575, 265)
$dRepeatIntervalTextBox.Size = New-Object System.Drawing.Size(58, 24)
$dRepeatIntervalTextBox.Font = $smallFont

$dRepeatSecondsLabel = New-Label "초" 640 262 30 30 $smallFont ([System.Drawing.Color]::FromArgb(85, 95, 105))

$form.Controls.AddRange(@(
    $mapGroup,
    $coordLabel,
    $statusLabel,
    $updatedLabel,
    $toggleButton,
    $copyButton,
    $aHoldButton,
    $aHoldLabel,
    $afRepeatButton,
    $afRepeatLabel,
    $dRepeatCheckBox,
    $dRepeatIntervalLabel,
    $dRepeatIntervalTextBox,
    $dRepeatSecondsLabel
  ))

Update-MapInfo

function Set-AHoldUiStopped {
  $aHoldButton.Text = "A 누르기"
  $aHoldLabel.Text = "스킬 반복: 꺼짐"
  $aHoldLabel.ForeColor = [System.Drawing.Color]::FromArgb(85, 95, 105)
}

function Set-AFRepeatUiStopped {
  $afRepeatButton.Text = "A→왼쪽+F v2"
  $afRepeatLabel.Text = "v2 반복: 꺼짐"
  $afRepeatLabel.ForeColor = [System.Drawing.Color]::FromArgb(85, 95, 105)
}

function Stop-RepeatInputsForUi {
  if ($script:aHoldActive) {
    Stop-AHold
    Set-AHoldUiStopped
  }
  if ($script:afRepeatActive) {
    Stop-AFRepeat
    Set-AFRepeatUiStopped
  }
}

$mapListBox.Add_SelectedIndexChanged({
  if ($mapListBox.SelectedItem) {
    Stop-RepeatInputsForUi
    $script:selectedMapProfile = $script:mapProfiles | Where-Object { $_.Name -eq [string]$mapListBox.SelectedItem } | Select-Object -First 1
    $script:lastMinimapX = $null
    Update-MapInfo
    if ($script:monitoring) {
      Start-MarkerProbe
      Set-StatusColor $statusLabel "상태: 맵 변경됨" ([System.Drawing.Color]::FromArgb(85, 95, 105))
    }
  }
})

$toggleButton.Add_Click({
  $script:monitoring = -not $script:monitoring
  if ($script:monitoring) {
    $toggleButton.Text = "일시정지"
    Start-MarkerProbe
    Set-StatusColor $statusLabel "상태: 감시 중" ([System.Drawing.Color]::FromArgb(30, 120, 70))
  } else {
    $toggleButton.Text = "시작"
    Stop-MarkerProbe
    Set-StatusColor $statusLabel "상태: 일시정지됨" ([System.Drawing.Color]::FromArgb(85, 95, 105))
  }
})

$copyButton.Add_Click({
  if ($script:lastCoordinateText) {
    [System.Windows.Forms.Clipboard]::SetText($script:lastCoordinateText)
    Set-StatusColor $statusLabel "상태: 좌표 복사됨" ([System.Drawing.Color]::FromArgb(30, 120, 70))
  }
})

$dRepeatCheckBox.Add_CheckedChanged({
  $script:dRepeatNextActionAt = Get-NextDRepeatActionAt
})

$dRepeatIntervalTextBox.Add_TextChanged({
  $script:dRepeatNextActionAt = Get-NextDRepeatActionAt
})

$aHoldButton.Add_Click({
  try {
    if ($script:aHoldActive) {
      Stop-AHold
      Set-AHoldUiStopped
      Set-StatusColor $statusLabel "상태: A 반복 중지" ([System.Drawing.Color]::FromArgb(85, 95, 105))
      return
    }

    if ($script:afRepeatActive) {
      Stop-AFRepeat
      Set-AFRepeatUiStopped
    }

    Start-AHold | Out-Null
    $aHoldTimer.Start()
    $aHoldButton.Text = "A 반복 중지"
    $aHoldLabel.Text = "스킬 반복: 켜짐"
    $aHoldLabel.ForeColor = [System.Drawing.Color]::FromArgb(30, 120, 70)
    Set-StatusColor $statusLabel "상태: A 반복 중" ([System.Drawing.Color]::FromArgb(30, 120, 70))
  } catch {
    Stop-AHold
    Set-AHoldUiStopped
    Set-StatusColor $statusLabel ("상태: A 반복 실패 - {0}" -f $_.Exception.Message) ([System.Drawing.Color]::FromArgb(170, 50, 50))
  }
})

$afRepeatButton.Add_Click({
  try {
    if ($script:afRepeatActive) {
      Stop-AFRepeat
      Set-AFRepeatUiStopped
      Set-StatusColor $statusLabel "상태: v2 반복 중지" ([System.Drawing.Color]::FromArgb(85, 95, 105))
      return
    }

    if ($script:aHoldActive) {
      Stop-AHold
      Set-AHoldUiStopped
    }

    Start-AFRepeat | Out-Null
    $afRepeatTimer.Start()
    $afRepeatButton.Text = "v2 반복 중지"
    $afRepeatLabel.Text = ("v2 반복: {0}" -f (Get-AFRepeatStatusText))
    $afRepeatLabel.ForeColor = [System.Drawing.Color]::FromArgb(30, 120, 70)
    Set-StatusColor $statusLabel "상태: v2 반복 중" ([System.Drawing.Color]::FromArgb(30, 120, 70))
  } catch {
    Stop-AFRepeat
    Set-AFRepeatUiStopped
    Set-StatusColor $statusLabel ("상태: v2 반복 실패 - {0}" -f $_.Exception.Message) ([System.Drawing.Color]::FromArgb(170, 50, 50))
  }
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $IntervalMs
$timer.Add_Tick({
  if ($script:monitoring) {
    Read-MarkerProbe
  }
})

$aHoldTimer = New-Object System.Windows.Forms.Timer
$aHoldTimer.Interval = $AHoldIntervalMs
$aHoldTimer.Add_Tick({
  if (-not $script:aHoldActive) {
    $aHoldTimer.Stop()
    return
  }

  try {
    if (-not $script:aHoldIsDown) {
      Send-AKeyDown
    }
    $dRepeatStatus = Invoke-DRepeatIfDue
    if ($dRepeatStatus) {
      Set-StatusColor $statusLabel ("상태: {0}" -f $dRepeatStatus) ([System.Drawing.Color]::FromArgb(30, 120, 70))
    }
  } catch {
    Stop-AHold
    Set-AHoldUiStopped
    Set-StatusColor $statusLabel ("상태: 반복 입력 실패 - {0}" -f $_.Exception.Message) ([System.Drawing.Color]::FromArgb(170, 50, 50))
  }
})

$afRepeatTimer = New-Object System.Windows.Forms.Timer
$afRepeatTimer.Interval = $AFRepeatIntervalMs
$afRepeatTimer.Add_Tick({
  if (-not $script:afRepeatActive) {
    $afRepeatTimer.Stop()
    return
  }

  try {
    Send-AFKeyTapCycle
    $afRepeatLabel.Text = ("v2 반복: {0}" -f (Get-AFRepeatStatusText))
    Set-StatusColor $statusLabel "상태: v2 반복 중" ([System.Drawing.Color]::FromArgb(30, 120, 70))
  } catch {
    Stop-AFRepeat
    Set-AFRepeatUiStopped
    Set-StatusColor $statusLabel ("상태: v2 반복 실패 - {0}" -f $_.Exception.Message) ([System.Drawing.Color]::FromArgb(170, 50, 50))
  }
})

$form.Add_Shown({
  Start-MarkerProbe
  $timer.Start()
})

$form.Add_FormClosing({
  $timer.Stop()
  Stop-RepeatInputsForUi
  Stop-MarkerProbe
})

[void][System.Windows.Forms.Application]::Run($form)
