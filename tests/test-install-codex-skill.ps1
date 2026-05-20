param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot "tools\install-codex-skill.ps1"
$sourceSkill = Join-Path $repoRoot "codex-skills\ldplayer-autojs6"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-skill-install-test-" + [guid]::NewGuid().ToString("N"))
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

try {
  Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "install-codex-skill.ps1 should exist."
  Assert-True (Test-Path -LiteralPath (Join-Path $sourceSkill "SKILL.md") -PathType Leaf) "Repo skill source should contain SKILL.md."

  $dryRun = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
    -SourceSkillPath $sourceSkill `
    -DestinationRoot $tempRoot `
    -DryRun
  Assert-True (($dryRun -join "`n") -match "DRY-RUN") "Dry-run should report planned actions."
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $tempRoot "ldplayer-autojs6"))) "Dry-run should not copy the skill."

  $run = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
    -SourceSkillPath $sourceSkill `
    -DestinationRoot $tempRoot
  $installedSkill = Join-Path $tempRoot "ldplayer-autojs6"
  Assert-True (($run -join "`n") -match "Installed skill") "Install run should report the installed path."
  Assert-True (Test-Path -LiteralPath (Join-Path $installedSkill "SKILL.md") -PathType Leaf) "Installed skill should contain SKILL.md."
  Assert-True (Test-Path -LiteralPath (Join-Path $installedSkill "scripts\setup-ldplayer-adb.ps1") -PathType Leaf) "Installed skill should contain setup script."
  Assert-True (Test-Path -LiteralPath (Join-Path $installedSkill "references\project-baseline.md") -PathType Leaf) "Installed skill should contain baseline reference."

  $runAgain = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath `
    -SourceSkillPath $sourceSkill `
    -DestinationRoot $tempRoot
  Assert-True (($runAgain -join "`n") -match "Installed skill") "Second install should also report the installed path."
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $installedSkill "ldplayer-autojs6"))) "Reinstall should not create a nested ldplayer-autojs6 directory."
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}

if ($failures.Count -gt 0) {
  Write-Host "Codex skill install tests failed:" -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host " - $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "Codex skill install tests passed." -ForegroundColor Green
