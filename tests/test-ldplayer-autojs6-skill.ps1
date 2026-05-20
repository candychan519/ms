param(
  [string]$SkillRoot,
  [string]$QuickValidate = (Join-Path $env:USERPROFILE ".codex\skills\.system\skill-creator\scripts\quick_validate.py"),
  [string]$AdbPath = "C:\LDPlayer\LDPlayer9\adb.exe"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $SkillRoot) {
  $SkillRoot = Join-Path $repoRoot "codex-skills\ldplayer-autojs6"
}
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

function Assert-File {
  param([string]$Path)
  Assert-True (Test-Path -LiteralPath $Path -PathType Leaf) "Expected file to exist: $Path"
}

Assert-File (Join-Path $SkillRoot "SKILL.md")
Assert-File (Join-Path $SkillRoot "agents\openai.yaml")
Assert-File (Join-Path $SkillRoot "references\project-baseline.md")
Assert-File (Join-Path $SkillRoot "scripts\setup-ldplayer-adb.ps1")
Assert-File (Join-Path $SkillRoot "scripts\capture-ldplayer.ps1")
Assert-File (Join-Path $SkillRoot "scripts\find-minimap-player-marker.ps1")
Assert-File (Join-Path $SkillRoot "scripts\show-minimap-position-ui.ps1")
Assert-File (Join-Path $SkillRoot "scripts\send-ldplayer-key.ps1")
Assert-File (Join-Path $SkillRoot "scripts\install-codex-skill.ps1")

$skillText = Get-Content -LiteralPath (Join-Path $SkillRoot "SKILL.md") -Raw
Assert-True ($skillText -match "name:\s*ldplayer-autojs6") "SKILL.md should declare the ldplayer-autojs6 name."
Assert-True ($skillText -match "127\.0\.0\.1:5555") "SKILL.md should document the LDPlayer ADB endpoint."
Assert-True ($skillText -match "1280x720") "SKILL.md should document the current resolution baseline."
Assert-True ($skillText -match "framesPerSecond") "SKILL.md should document FPS verification."
Assert-True ($skillText -match 'Global FPS cap:\s*`60`') "SKILL.md should document the current 60 FPS baseline."
Assert-True ($skillText -match "send-ldplayer-key\.ps1") "SKILL.md should document the bounded key input helper."
Assert-True ($skillText -match "find-minimap-player-marker\.ps1") "SKILL.md should document the minimap marker helper."
Assert-True ($skillText -match "show-minimap-position-ui\.ps1") "SKILL.md should document the minimap position UI."
Assert-True ($skillText -match "## Safety Boundary") "SKILL.md should keep an explicit safety boundary."
Assert-True ($skillText -match "anti-cheat bypass") "SKILL.md should document anti-cheat bypass as out of scope."
Assert-True ($skillText -match "MaxDurationSeconds") "SKILL.md should document the bounded duration cap for repeated key input."
Assert-True ($skillText -match "RECORDING_RULES\.md") "SKILL.md should include the recording rules in its standard document list."
Assert-True ($skillText -notmatch "\[TODO\]|TODO:") "SKILL.md should not contain template TODO markers."

$baselineText = Get-Content -LiteralPath (Join-Path $SkillRoot "references\project-baseline.md") -Raw
Assert-True ($baselineText -match "C:\\LDPlayer\\LDPlayer9") "Baseline reference should document the LDPlayer install path."
Assert-True ($baselineText -match "com\.nexon\.mod") "Baseline reference should document MapleStory Worlds package."
Assert-True ($baselineText -match '"framesPerSecond": 60') "Baseline reference should document the current 60 FPS setting."

$yamlProbe = & python -c "import yaml; print(yaml.__version__)" 2>&1
Assert-True ($LASTEXITCODE -eq 0) "PyYAML should be installed for skill validation. Output: $($yamlProbe -join ' ')"

Assert-File $QuickValidate

$validateOutput = & python $QuickValidate $SkillRoot 2>&1
Assert-True ($LASTEXITCODE -eq 0) "quick_validate.py should pass. Output: $($validateOutput -join ' ')"
Assert-True (($validateOutput -join "`n") -match "Skill is valid") "quick_validate.py should report a valid skill."

$dryRunOutput = & $powerShellExe -NoProfile -ExecutionPolicy Bypass `
  -File (Join-Path $SkillRoot "scripts\setup-ldplayer-adb.ps1") `
  -AdbPath $AdbPath `
  -Endpoint "127.0.0.1:5555" `
  -DryRun 2>&1
Assert-True ($LASTEXITCODE -eq 0) "Bundled setup-ldplayer-adb.ps1 dry-run should pass. Output: $($dryRunOutput -join ' ')"
Assert-True (($dryRunOutput -join "`n") -match "DRY-RUN connect") "Bundled setup script should include the connect step in dry-run output."

$keyDryRunOutput = & $powerShellExe -NoProfile -ExecutionPolicy Bypass `
  -File (Join-Path $SkillRoot "scripts\send-ldplayer-key.ps1") `
  -AdbPath $AdbPath `
  -Serial "127.0.0.1:5555" `
  -Key "A" `
  -Count 2 `
  -IntervalMs 50 `
  -DryRun 2>&1
Assert-True ($LASTEXITCODE -eq 0) "Bundled send-ldplayer-key.ps1 dry-run should pass. Output: $($keyDryRunOutput -join ' ')"
Assert-True (($keyDryRunOutput -join "`n") -match "KEYCODE_A.*29") "Bundled key sender should map A to KEYCODE_A."

if ($failures.Count -gt 0) {
  Write-Host "LDPlayer AutoJs6 skill tests failed:" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "LDPlayer AutoJs6 skill tests passed." -ForegroundColor Green
