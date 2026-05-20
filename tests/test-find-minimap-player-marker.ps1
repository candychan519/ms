param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "tools\find-minimap-player-marker.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("minimap-marker-tests-" + [guid]::NewGuid().ToString("N"))
$powerShellExe = (Get-Process -Id $PID).Path
if (-not $powerShellExe) {
  $powerShellExe = (Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
}
if (-not $powerShellExe) {
  $powerShellExe = (Get-Command powershell -ErrorAction Stop | Select-Object -First 1 -ExpandProperty Source)
}
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

function Assert-Equal {
  param(
    $Expected,
    $Actual,
    [string]$Message
  )

  if ($Expected -ne $Actual) {
    Add-Failure "$Message Expected '$Expected', got '$Actual'."
  }
}

try {
  Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "find-minimap-player-marker.ps1 should exist."

  if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
    $scriptText = Get-Content -LiteralPath $scriptPath -Raw
    Assert-True ($scriptText -match "screencap") "Live mode should use ADB screencap."
    Assert-True ($scriptText -match "exec-out screencap -p") "Live mode should stream ADB screenshots directly before falling back to pull."
    Assert-True ($scriptText -match "Direct capture error") "Live mode should keep the slower screencap/pull fallback when direct capture fails."
    Assert-True ($scriptText -match "Watch") "Tool should support a Watch mode."
    Assert-True ($scriptText -match "MinimapPercentX") "Tool should report normalized minimap coordinates."
    Assert-True ($scriptText -match "MinMarkerLocalY") "Tool should support map-specific local Y filtering."
    Assert-True ($scriptText -match "MaxMarkerLocalY") "Tool should support map-specific local Y filtering."
    Assert-True ($scriptText -match "AnnotationPath") "Tool should support annotated detection screenshots."
    Assert-True ($scriptText -match "CandidateCount") "Tool should report accepted candidate counts for diagnostics."
    Assert-True ($scriptText -match "ComponentCount") "Tool should report yellow component counts for diagnostics."
    Assert-True ($scriptText -match "Reason") "Tool should report a plain reason for found/not-found diagnostics."
    Assert-True ($scriptText -match "PreferredMinimapX") "Tool should prefer candidates near the last accepted minimap X."
    Assert-True ($scriptText -match "PreferredMinimapMaxDistance") "Tool should bound preferred-candidate distance."
    Assert-True ($scriptText -match "Get-YellowMarkerPixelWeight") "Tool should use color-weighted marker pixels for a more precise center."
    Assert-True ($scriptText -match "MarkerScore") "Tool should prefer bright marker-like yellow candidates over dull larger components."
    Assert-True ($scriptText -match "PreciseMinimapX") "Tool should report sub-pixel precise minimap coordinates."
    Assert-True ($scriptText -match "PreciseScreenX") "Tool should report sub-pixel precise screen coordinates."
  }

  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
  Add-Type -AssemblyName System.Drawing

  $fixturePath = Join-Path $tempRoot "synthetic-minimap.png"
  $bitmap = New-Object System.Drawing.Bitmap(240, 180)
  try {
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
      $graphics.Clear([System.Drawing.Color]::FromArgb(18, 24, 26))
      $graphics.FillRectangle(
        (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(35, 55, 45))),
        10,
        20,
        120,
        80
      )
      $graphics.FillRectangle(
        (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(240, 200, 20))),
        170,
        8,
        45,
        12
      )
    } finally {
      $graphics.Dispose()
    }

    $markerLocalX = 42
    $markerLocalY = 35
    for ($dy = -4; $dy -le 4; $dy++) {
      for ($dx = -4; $dx -le 4; $dx++) {
        if (([Math]::Abs($dx) + [Math]::Abs($dy)) -le 4) {
          $bitmap.SetPixel(10 + $markerLocalX + $dx, 20 + $markerLocalY + $dy, [System.Drawing.Color]::FromArgb(255, 226, 35))
        }
      }
    }

    $bitmap.SetPixel(10 + 95, 20 + 62, [System.Drawing.Color]::FromArgb(255, 225, 30))
    for ($dy = -4; $dy -le 4; $dy++) {
      for ($dx = -4; $dx -le 4; $dx++) {
        if (([Math]::Abs($dx) + [Math]::Abs($dy)) -le 4) {
          $bitmap.SetPixel(10 + 88 + $dx, 20 + 35 + $dy, [System.Drawing.Color]::FromArgb(206, 160, 80))
        }
      }
    }
    $bitmap.Save($fixturePath, [System.Drawing.Imaging.ImageFormat]::Png)
  } finally {
    $bitmap.Dispose()
  }

  if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
    $jsonOutput = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
      -ImagePath $fixturePath `
      -MinimapX 10 `
      -MinimapY 20 `
      -MinimapWidth 120 `
      -MinimapHeight 80 `
      -Json 2>&1

    Assert-True ($LASTEXITCODE -eq 0) "Static image analysis should pass. Output: $($jsonOutput -join ' ')"
    $result = ($jsonOutput | ConvertFrom-Json)

    Assert-True ([bool]$result.Found) "Synthetic marker should be found."
    Assert-Equal 42 ([int]$result.MinimapX) "Minimap X should match the synthetic marker center."
    Assert-Equal 35 ([int]$result.MinimapY) "Minimap Y should match the synthetic marker center."
    Assert-Equal 42 ([int][Math]::Round([double]$result.PreciseMinimapX)) "Precise minimap X should round to the synthetic marker center."
    Assert-Equal 35 ([int][Math]::Round([double]$result.PreciseMinimapY)) "Precise minimap Y should round to the synthetic marker center."
    Assert-Equal 52 ([int]$result.ScreenX) "Screen X should include the minimap origin."
    Assert-Equal 55 ([int]$result.ScreenY) "Screen Y should include the minimap origin."
    Assert-True ([double]$result.MinimapPercentX -gt 34 -and [double]$result.MinimapPercentX -lt 36) "Minimap X percent should be normalized."
    Assert-True ([double]$result.Confidence -gt 0) "Confidence should be positive for a detected marker."
    Assert-True ([double]$result.MarkerScore -gt 0) "Detected marker output should include a positive marker score."
    Assert-True ([double]$result.MarkerAverageR -gt 220) "Detected marker should prefer the brighter yellow component over dull distractors."
    Assert-True ([int]$result.CandidateCount -gt 0) "Detected marker output should include candidate count."
    Assert-Equal "matched" ([string]$result.Reason) "Detected marker output should report a matched reason."

    $annotationPath = Join-Path $tempRoot "annotated-marker.png"
    $annotatedOutput = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
      -ImagePath $fixturePath `
      -MinimapX 10 `
      -MinimapY 20 `
      -MinimapWidth 120 `
      -MinimapHeight 80 `
      -AnnotationPath $annotationPath `
      -Json 2>&1

    Assert-True ($LASTEXITCODE -eq 0) "Static image annotation should pass. Output: $($annotatedOutput -join ' ')"
    Assert-True (Test-Path -LiteralPath $annotationPath -PathType Leaf) "Annotation image should be written."

    $filteredOutput = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
      -ImagePath $fixturePath `
      -MinimapX 10 `
      -MinimapY 20 `
      -MinimapWidth 120 `
      -MinimapHeight 80 `
      -MinMarkerLocalY 30 `
      -MaxMarkerLocalY 40 `
      -Json 2>&1

    Assert-True ($LASTEXITCODE -eq 0) "Static image analysis with local Y filtering should pass. Output: $($filteredOutput -join ' ')"
    $filtered = ($filteredOutput | ConvertFrom-Json)
    Assert-True ([bool]$filtered.Found) "Synthetic marker should be found when inside the local Y filter."

    $preferredOutput = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
      -ImagePath $fixturePath `
      -MinimapX 10 `
      -MinimapY 20 `
      -MinimapWidth 120 `
      -MinimapHeight 80 `
      -PreferredMinimapX 42 `
      -PreferredMinimapMaxDistance 10 `
      -Json 2>&1

    Assert-True ($LASTEXITCODE -eq 0) "Static image analysis with a preferred X should pass. Output: $($preferredOutput -join ' ')"
    $preferred = ($preferredOutput | ConvertFrom-Json)
    Assert-True ([bool]$preferred.Found) "Synthetic marker should be found with preferred X."
    Assert-True ($null -ne $preferred.PreferredDistance) "Preferred detection output should include preferred distance."

    $excludedOutput = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
      -ImagePath $fixturePath `
      -MinimapX 10 `
      -MinimapY 20 `
      -MinimapWidth 120 `
      -MinimapHeight 80 `
      -MinMarkerLocalY 50 `
      -MaxMarkerLocalY 70 `
      -Json 2>&1

    Assert-True ($LASTEXITCODE -eq 0) "Static image analysis with excluding local Y filtering should pass. Output: $($excludedOutput -join ' ')"
    $excluded = ($excludedOutput | ConvertFrom-Json)
    Assert-True (-not [bool]$excluded.Found) "Synthetic marker should be excluded outside the local Y filter."
    Assert-Equal "no-candidate" ([string]$excluded.Reason) "Excluded marker output should report no candidate."
  }
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

if ($failures.Count -gt 0) {
  Write-Host "Minimap player marker tests failed:" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "Minimap player marker tests passed." -ForegroundColor Green
