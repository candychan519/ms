param(
  [string]$ImagePath,
  [switch]$Watch,
  [int]$Samples = 1,
  [int]$IntervalMs = 500,
  [string]$AdbPath = "C:\LDPlayer\LDPlayer9\adb.exe",
  [string]$Serial = "127.0.0.1:5555",
  [string]$RemotePath = "/sdcard/Pictures/minimap-marker-watch.png",
  [string]$CapturePath,
  [int]$MinimapX = 8,
  [int]$MinimapY = 96,
  [int]$MinimapWidth = 207,
  [int]$MinimapHeight = 101,
  [int]$YellowMinR = 180,
  [int]$YellowMinG = 140,
  [int]$YellowMaxB = 95,
  [int]$MinMarkerPixels = 8,
  [int]$MaxMarkerWidth = 24,
  [int]$MaxMarkerHeight = 24,
  [int]$MinMarkerLocalX = -1,
  [int]$MaxMarkerLocalX = -1,
  [int]$MinMarkerLocalY = -1,
  [int]$MaxMarkerLocalY = -1,
  [double]$PreferredMinimapX = -1,
  [int]$PreferredMinimapMaxDistance = 45,
  [string]$AnnotationPath,
  [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
$script:lastCandidateCount = 0
$script:lastComponentCount = 0

function Resolve-FullPath {
  param([string]$Path)

  return [System.IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($Path))
}

function New-CapturePath {
  if ($CapturePath) {
    $full = Resolve-FullPath $CapturePath
  } else {
    $full = Join-Path ([System.IO.Path]::GetTempPath()) "ldplayer-minimap-marker.png"
  }

  $parent = Split-Path -Parent $full
  if ($parent) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
  return $full
}

function Capture-LdPlayerScreenshot {
  param([string]$OutputPath)

  if (-not (Test-Path -LiteralPath $AdbPath -PathType Leaf)) {
    throw "ADB was not found: $AdbPath"
  }

  $directCaptureError = $null
  try {
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $AdbPath
    $startInfo.Arguments = ('-s "{0}" exec-out screencap -p' -f ($Serial -replace '"', '\"'))
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    [void]$process.Start()
    try {
      $fileStream = [System.IO.File]::Open($OutputPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
      try {
        $process.StandardOutput.BaseStream.CopyTo($fileStream)
      } finally {
        $fileStream.Dispose()
      }
      $stderr = $process.StandardError.ReadToEnd()
      $process.WaitForExit()
      if ($process.ExitCode -ne 0) {
        throw "ADB exec-out screencap failed for serial $Serial. $stderr"
      }
      if (-not (Test-Path -LiteralPath $OutputPath -PathType Leaf) -or (Get-Item -LiteralPath $OutputPath).Length -le 8) {
        throw "ADB exec-out screencap returned an empty image."
      }
      return $OutputPath
    } finally {
      $process.Dispose()
    }
  } catch {
    $directCaptureError = $_.Exception.Message
    if (Test-Path -LiteralPath $OutputPath -PathType Leaf) {
      Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue
    }
  }

  & $AdbPath -s $Serial shell screencap -p $RemotePath | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "ADB screencap failed for serial $Serial. Direct capture error: $directCaptureError"
  }

  & $AdbPath -s $Serial pull $RemotePath $OutputPath | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "ADB pull failed from $RemotePath to $OutputPath. Direct capture error: $directCaptureError"
  }

  return $OutputPath
}

function Test-YellowMarkerPixel {
  param([System.Drawing.Color]$Color)

  if ($Color.R -lt $YellowMinR) { return $false }
  if ($Color.G -lt $YellowMinG) { return $false }
  if ($Color.B -gt $YellowMaxB) { return $false }
  if (($Color.R - $Color.G) -gt 110) { return $false }
  if (($Color.G - $Color.B) -lt 45) { return $false }
  return $true
}

function Get-YellowMarkerPixelWeight {
  param([System.Drawing.Color]$Color)

  $redScore = [Math]::Max(0, [int]$Color.R - $YellowMinR)
  $greenScore = [Math]::Max(0, [int]$Color.G - $YellowMinG)
  $blueScore = [Math]::Max(0, $YellowMaxB - [int]$Color.B)
  return [Math]::Max(1.0, 1.0 + (($redScore + $greenScore + $blueScore) / 255.0))
}

function Find-LargestMarkerComponent {
  param([System.Drawing.Bitmap]$Bitmap)

  $script:lastCandidateCount = 0
  $script:lastComponentCount = 0
  if ($MinimapX -lt 0 -or $MinimapY -lt 0 -or $MinimapWidth -le 0 -or $MinimapHeight -le 0) {
    throw "Minimap bounds are invalid."
  }
  if (($MinimapX + $MinimapWidth) -gt $Bitmap.Width -or ($MinimapY + $MinimapHeight) -gt $Bitmap.Height) {
    throw "Minimap bounds exceed image size $($Bitmap.Width)x$($Bitmap.Height)."
  }

  $mask = New-Object 'bool[,]' $MinimapWidth, $MinimapHeight
  $weights = New-Object 'double[,]' $MinimapWidth, $MinimapHeight
  $visited = New-Object 'bool[,]' $MinimapWidth, $MinimapHeight

  for ($y = 0; $y -lt $MinimapHeight; $y++) {
    for ($x = 0; $x -lt $MinimapWidth; $x++) {
      $color = $Bitmap.GetPixel($MinimapX + $x, $MinimapY + $y)
      $matched = Test-YellowMarkerPixel $color
      $mask[$x, $y] = $matched
      if ($matched) {
        $weights[$x, $y] = Get-YellowMarkerPixelWeight $color
      }
    }
  }

  $best = $null
  $preferredBest = $null
  for ($startY = 0; $startY -lt $MinimapHeight; $startY++) {
    for ($startX = 0; $startX -lt $MinimapWidth; $startX++) {
      if (-not $mask[$startX, $startY] -or $visited[$startX, $startY]) {
        continue
      }

      $queue = New-Object 'System.Collections.Generic.Queue[object]'
      $queue.Enqueue(@($startX, $startY))
      $visited[$startX, $startY] = $true

      $count = 0
      $sumX = 0
      $sumY = 0
      $weightedSumX = 0.0
      $weightedSumY = 0.0
      $weightTotal = 0.0
      $sumR = 0
      $sumG = 0
      $sumB = 0
      $minX = $startX
      $maxX = $startX
      $minY = $startY
      $maxY = $startY

      while ($queue.Count -gt 0) {
        $point = $queue.Dequeue()
        $x = [int]$point[0]
        $y = [int]$point[1]

        $count++
        $sumX += $x
        $sumY += $y
        $weight = [double]$weights[$x, $y]
        $weightedSumX += ([double]$x * $weight)
        $weightedSumY += ([double]$y * $weight)
        $weightTotal += $weight
        $color = $Bitmap.GetPixel($MinimapX + $x, $MinimapY + $y)
        $sumR += $color.R
        $sumG += $color.G
        $sumB += $color.B
        if ($x -lt $minX) { $minX = $x }
        if ($x -gt $maxX) { $maxX = $x }
        if ($y -lt $minY) { $minY = $y }
        if ($y -gt $maxY) { $maxY = $y }

        for ($ny = $y - 1; $ny -le $y + 1; $ny++) {
          for ($nx = $x - 1; $nx -le $x + 1; $nx++) {
            if ($nx -lt 0 -or $ny -lt 0 -or $nx -ge $MinimapWidth -or $ny -ge $MinimapHeight) {
              continue
            }
            if ($visited[$nx, $ny] -or -not $mask[$nx, $ny]) {
              continue
            }
            $visited[$nx, $ny] = $true
            $queue.Enqueue(@($nx, $ny))
          }
        }
      }

      $width = $maxX - $minX + 1
      $height = $maxY - $minY + 1
      $script:lastComponentCount++
      if ($count -lt $MinMarkerPixels -or $width -gt $MaxMarkerWidth -or $height -gt $MaxMarkerHeight) {
        continue
      }

      $pixelCenterX = $sumX / $count
      $pixelCenterY = $sumY / $count
      $weightedCenterX = if ($weightTotal -gt 0) { $weightedSumX / $weightTotal } else { $pixelCenterX }
      $weightedCenterY = if ($weightTotal -gt 0) { $weightedSumY / $weightTotal } else { $pixelCenterY }
      $boxCenterX = ($minX + $maxX) / 2.0
      $boxCenterY = ($minY + $maxY) / 2.0
      $centerX = (($weightedCenterX * 2.0) + $boxCenterX) / 3.0
      $centerY = (($weightedCenterY * 2.0) + $boxCenterY) / 3.0
      if ($MinMarkerLocalX -ge 0 -and $centerX -lt $MinMarkerLocalX) { continue }
      if ($MaxMarkerLocalX -ge 0 -and $centerX -gt $MaxMarkerLocalX) { continue }
      if ($MinMarkerLocalY -ge 0 -and $centerY -lt $MinMarkerLocalY) { continue }
      if ($MaxMarkerLocalY -ge 0 -and $centerY -gt $MaxMarkerLocalY) { continue }
      $script:lastCandidateCount++
      $averageR = $sumR / [double]$count
      $averageG = $sumG / [double]$count
      $averageB = $sumB / [double]$count
      $markerScore = $count * (($averageR + $averageG - $averageB) / 300.0)

      $candidate = [pscustomobject]@{
        Pixels = $count
        CenterX = $centerX
        CenterY = $centerY
        PixelCenterX = $pixelCenterX
        PixelCenterY = $pixelCenterY
        WeightedCenterX = $weightedCenterX
        WeightedCenterY = $weightedCenterY
        BoxCenterX = $boxCenterX
        BoxCenterY = $boxCenterY
        MarkerScore = $markerScore
        AverageR = $averageR
        AverageG = $averageG
        AverageB = $averageB
        Width = $width
        Height = $height
        PreferredDistance = if ($PreferredMinimapX -ge 0) { [Math]::Abs($centerX - $PreferredMinimapX) } else { $null }
      }

      if ($PreferredMinimapX -ge 0 -and $candidate.PreferredDistance -le $PreferredMinimapMaxDistance) {
        if ($null -eq $preferredBest -or $candidate.MarkerScore -gt $preferredBest.MarkerScore -or ($candidate.MarkerScore -eq $preferredBest.MarkerScore -and $candidate.PreferredDistance -lt $preferredBest.PreferredDistance)) {
          $preferredBest = $candidate
        }
      }
      if ($null -eq $best -or $candidate.MarkerScore -gt $best.MarkerScore) {
        $best = $candidate
      }
    }
  }

  if ($null -ne $preferredBest) {
    return $preferredBest
  }
  return $best
}

function Save-MarkerAnnotation {
  param(
    [string]$ImagePath,
    $Result
  )

  if (-not $AnnotationPath) {
    return
  }

  $fullAnnotationPath = Resolve-FullPath $AnnotationPath
  $parent = Split-Path -Parent $fullAnnotationPath
  if ($parent) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  $bitmap = New-Object System.Drawing.Bitmap((Resolve-FullPath $ImagePath))
  try {
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
      $boundsPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Lime, 3)
      $pointBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
      $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
      $font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
      try {
        $graphics.DrawRectangle($boundsPen, $MinimapX, $MinimapY, $MinimapWidth, $MinimapHeight)
        if ([bool]$Result.Found) {
          $graphics.FillEllipse($pointBrush, ([int]$Result.ScreenX) - 5, ([int]$Result.ScreenY) - 5, 10, 10)
          $graphics.DrawString("detected ($($Result.MinimapX),$($Result.MinimapY))", $font, $textBrush, $MinimapX, $MinimapY + $MinimapHeight + 4)
        } else {
          $graphics.DrawString("not found: $($Result.Reason)", $font, $textBrush, $MinimapX, $MinimapY + $MinimapHeight + 4)
        }
      } finally {
        $boundsPen.Dispose()
        $pointBrush.Dispose()
        $textBrush.Dispose()
        $font.Dispose()
      }
    } finally {
      $graphics.Dispose()
    }
    $bitmap.Save($fullAnnotationPath, [System.Drawing.Imaging.ImageFormat]::Png)
  } finally {
    $bitmap.Dispose()
  }
}

function Measure-MinimapPlayerMarker {
  param([string]$Path)

  $fullPath = Resolve-FullPath $Path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Image was not found: $fullPath"
  }

  $bitmap = New-Object System.Drawing.Bitmap($fullPath)
  try {
    $component = Find-LargestMarkerComponent $bitmap
    if ($null -eq $component) {
      return [pscustomobject]@{
        Timestamp = (Get-Date).ToString("o")
        Found = $false
        Reason = "no-candidate"
        ImagePath = $fullPath
        CandidateCount = $script:lastCandidateCount
        ComponentCount = $script:lastComponentCount
        MinimapBounds = [pscustomobject]@{
          X = $MinimapX
          Y = $MinimapY
          Width = $MinimapWidth
          Height = $MinimapHeight
        }
      }
    }

    $preciseLocalX = [Math]::Round([double]$component.CenterX, 2)
    $preciseLocalY = [Math]::Round([double]$component.CenterY, 2)
    $localX = [int][Math]::Round($preciseLocalX)
    $localY = [int][Math]::Round($preciseLocalY)
    $screenX = $MinimapX + $localX
    $screenY = $MinimapY + $localY
    $preciseScreenX = [Math]::Round($MinimapX + $preciseLocalX, 2)
    $preciseScreenY = [Math]::Round($MinimapY + $preciseLocalY, 2)
    $confidence = [Math]::Min(1.0, [Math]::Round(($component.Pixels / [double]($MinMarkerPixels * 4)), 3))

    return [pscustomobject]@{
      Timestamp = (Get-Date).ToString("o")
      Found = $true
      ImagePath = $fullPath
      Reason = "matched"
      CandidateCount = $script:lastCandidateCount
      ComponentCount = $script:lastComponentCount
      ScreenX = $screenX
      ScreenY = $screenY
      PreciseScreenX = $preciseScreenX
      PreciseScreenY = $preciseScreenY
      MinimapX = $localX
      MinimapY = $localY
      PreciseMinimapX = $preciseLocalX
      PreciseMinimapY = $preciseLocalY
      MinimapPercentX = [Math]::Round(($localX / [double]$MinimapWidth) * 100, 2)
      MinimapPercentY = [Math]::Round(($localY / [double]$MinimapHeight) * 100, 2)
      PreciseMinimapPercentX = [Math]::Round(($preciseLocalX / [double]$MinimapWidth) * 100, 2)
      PreciseMinimapPercentY = [Math]::Round(($preciseLocalY / [double]$MinimapHeight) * 100, 2)
      MarkerPixels = $component.Pixels
      ComponentWidth = $component.Width
      ComponentHeight = $component.Height
      MarkerScore = [Math]::Round([double]$component.MarkerScore, 2)
      MarkerAverageR = [Math]::Round([double]$component.AverageR, 1)
      MarkerAverageG = [Math]::Round([double]$component.AverageG, 1)
      MarkerAverageB = [Math]::Round([double]$component.AverageB, 1)
      PixelCenterX = [Math]::Round([double]$component.PixelCenterX, 2)
      PixelCenterY = [Math]::Round([double]$component.PixelCenterY, 2)
      WeightedCenterX = [Math]::Round([double]$component.WeightedCenterX, 2)
      WeightedCenterY = [Math]::Round([double]$component.WeightedCenterY, 2)
      BoxCenterX = [Math]::Round([double]$component.BoxCenterX, 2)
      BoxCenterY = [Math]::Round([double]$component.BoxCenterY, 2)
      PreferredDistance = $component.PreferredDistance
      Confidence = $confidence
      MinimapBounds = [pscustomobject]@{
        X = $MinimapX
        Y = $MinimapY
        Width = $MinimapWidth
        Height = $MinimapHeight
      }
    }
  } finally {
    $bitmap.Dispose()
  }
}

function Write-MarkerResult {
  param($Result)

  if ($Json) {
    $Result | ConvertTo-Json -Depth 4 -Compress
    return
  }

  if (-not $Result.Found) {
    Write-Output "$($Result.Timestamp) marker=not-found"
    return
  }

  Write-Output ("{0} minimap=({1},{2}) percent=({3}%,{4}%) screen=({5},{6}) confidence={7} pixels={8}" -f `
    $Result.Timestamp,
    $Result.MinimapX,
    $Result.MinimapY,
    $Result.MinimapPercentX,
    $Result.MinimapPercentY,
    $Result.ScreenX,
    $Result.ScreenY,
    $Result.Confidence,
    $Result.MarkerPixels)
}

if ($IntervalMs -lt 100) {
  throw "IntervalMs must be at least 100."
}
if ($Samples -lt 0) {
  throw "Samples must be 0 or greater. Use 0 with -Watch to run until Ctrl+C."
}
if (-not $Watch -and $Samples -eq 0) {
  throw "Samples 0 is only valid with -Watch."
}

if ($ImagePath -and $Watch) {
  throw "Use either -ImagePath for a static image or -Watch for live capture, not both."
}

if ($ImagePath) {
  $result = Measure-MinimapPlayerMarker $ImagePath
  Save-MarkerAnnotation -ImagePath $ImagePath -Result $result
  Write-MarkerResult $result
  exit 0
}

$captureFile = New-CapturePath
$remaining = if ($Watch) { $Samples } else { 1 }

while ($true) {
  $shotPath = Capture-LdPlayerScreenshot $captureFile
  $result = Measure-MinimapPlayerMarker $shotPath
  Save-MarkerAnnotation -ImagePath $shotPath -Result $result
  Write-MarkerResult $result

  if (-not $Watch) {
    break
  }

  if ($remaining -gt 0) {
    $remaining--
    if ($remaining -le 0) {
      break
    }
  }

  Start-Sleep -Milliseconds $IntervalMs
}
