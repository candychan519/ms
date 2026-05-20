param(
  [int]$IntervalMs = 250,
  [string]$MarkerToolPath,
  [string]$AdbPath = "C:\LDPlayer\LDPlayer9\adb.exe",
  [string]$Serial = "127.0.0.1:5555",
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
if ($IntervalMs -lt 250) {
  $IntervalMs = 250
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
    SkillDescription = "좌표 감시"
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
    SkillDescription = "좌표 감시"
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
    SkillDescription = "좌표 감시"
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
  Set-StatusColor $statusLabel "상태: 감시 중" ([System.Drawing.Color]::FromArgb(30, 120, 70))
}

[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "메이플 콘솔"
$form.Size = New-Object System.Drawing.Size(760, 260)
$form.StartPosition = "CenterScreen"
$form.TopMost = [bool]$TopMost
$form.BackColor = [System.Drawing.Color]::FromArgb(246, 248, 250)

$coordFont = New-Object System.Drawing.Font("Consolas", 22, [System.Drawing.FontStyle]::Bold)
$labelFont = New-Object System.Drawing.Font("Malgun Gothic", 10, [System.Drawing.FontStyle]::Regular)
$smallFont = New-Object System.Drawing.Font("Malgun Gothic", 9, [System.Drawing.FontStyle]::Regular)

$mapGroup = New-Object System.Windows.Forms.GroupBox
$mapGroup.Text = "맵 선택"
$mapGroup.Location = New-Object System.Drawing.Point(12, 12)
$mapGroup.Size = New-Object System.Drawing.Size(240, 198)
$mapGroup.Font = $labelFont

$mapListBox = New-Object System.Windows.Forms.ListBox
$mapListBox.Location = New-Object System.Drawing.Point(12, 24)
$mapListBox.Size = New-Object System.Drawing.Size(214, 86)
$mapListBox.Font = $smallFont
$mapListBox.HorizontalScrollbar = $true
[void]$mapListBox.Items.AddRange([string[]]($mapProfiles | ForEach-Object { $_.Name }))
$defaultIndex = $mapListBox.Items.IndexOf($defaultMapName)
if ($defaultIndex -lt 0) { $defaultIndex = 0 }
$mapListBox.SelectedIndex = $defaultIndex

$mapInfoLabel = New-Label "" 12 116 214 70 $smallFont ([System.Drawing.Color]::FromArgb(85, 95, 105))
$mapGroup.Controls.AddRange(@($mapListBox, $mapInfoLabel))

$coordLabel = New-Label "캐릭터 좌표=(--, --)" 278 24 450 58 $coordFont ([System.Drawing.Color]::FromArgb(20, 93, 160))
$statusLabel = New-Label "상태: 시작 중..." 282 96 440 24 $labelFont ([System.Drawing.Color]::FromArgb(120, 88, 0))
$updatedLabel = New-Label "마지막 확인: --" 282 124 440 22 $smallFont ([System.Drawing.Color]::FromArgb(85, 95, 105))

$toggleButton = New-Object System.Windows.Forms.Button
$toggleButton.Text = "일시정지"
$toggleButton.Location = New-Object System.Drawing.Point(580, 168)
$toggleButton.Size = New-Object System.Drawing.Size(70, 28)

$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Text = "복사"
$copyButton.Location = New-Object System.Drawing.Point(656, 168)
$copyButton.Size = New-Object System.Drawing.Size(70, 28)

$form.Controls.AddRange(@(
    $mapGroup,
    $coordLabel,
    $statusLabel,
    $updatedLabel,
    $toggleButton,
    $copyButton
  ))

Update-MapInfo

$mapListBox.Add_SelectedIndexChanged({
  if ($mapListBox.SelectedItem) {
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

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $IntervalMs
$timer.Add_Tick({
  if ($script:monitoring) {
    Read-MarkerProbe
  }
})

$form.Add_Shown({
  Start-MarkerProbe
  $timer.Start()
})

$form.Add_FormClosing({
  $timer.Stop()
  Stop-MarkerProbe
})

[void][System.Windows.Forms.Application]::Run($form)
