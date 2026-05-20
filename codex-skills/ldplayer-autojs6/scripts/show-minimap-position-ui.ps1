Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$mainScript = Join-Path $PSScriptRoot "start-maple-console.ps1"
if (-not (Test-Path -LiteralPath $mainScript -PathType Leaf)) {
  throw "Maple console entrypoint was not found: $mainScript"
}

& $mainScript @args
