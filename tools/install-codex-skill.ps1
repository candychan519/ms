param(
  [string]$SourceSkillPath = (Join-Path (Split-Path -Parent $PSScriptRoot) "codex-skills\ldplayer-autojs6"),
  [string]$DestinationRoot = (Join-Path $env:USERPROFILE ".codex\skills"),
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourceSkillPath -PathType Container)) {
  throw "Source skill path does not exist: $SourceSkillPath"
}

$skillFile = Join-Path $SourceSkillPath "SKILL.md"
if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
  throw "Source skill is missing SKILL.md: $skillFile"
}

$destinationPath = Join-Path $DestinationRoot (Split-Path -Leaf $SourceSkillPath)

if ($DryRun) {
  Write-Output "DRY-RUN source=$SourceSkillPath"
  Write-Output "DRY-RUN destination=$destinationPath"
  Write-Output "DRY-RUN create destination root if missing"
  Write-Output "DRY-RUN copy skill recursively"
  return
}

New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null

$fullDestinationRoot = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $DestinationRoot).Path)
$fullDestinationPath = [System.IO.Path]::GetFullPath($destinationPath)
$rootWithSeparator = $fullDestinationRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
if (-not $fullDestinationPath.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Destination path is outside DestinationRoot: $destinationPath"
}

if (Test-Path -LiteralPath $destinationPath) {
  Remove-Item -LiteralPath $destinationPath -Recurse -Force
}

Copy-Item -LiteralPath $SourceSkillPath -Destination $destinationPath -Recurse -Force

Write-Output "Installed skill to $destinationPath"
