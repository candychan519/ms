param(
  [string]$Path,
  [ValidateSet("png", "jpg", "jpeg", "bmp")]
  [string]$Format = "png"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class LdPlayerCaptureNative {
  [StructLayout(LayoutKind.Sequential)]
  public struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
  }

  [DllImport("user32.dll")]
  public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

  [DllImport("user32.dll")]
  public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdcBlt, uint nFlags);
}
"@

function New-OutputPath {
  if ($Path) {
    $full = [System.IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($Path))
    $parent = Split-Path -Parent $full
    if ($parent) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    return $full
  }

  $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
  return Join-Path ([System.IO.Path]::GetTempPath()) "ldplayer-shot-$timestamp.$Format"
}

$process = Get-Process dnplayer -ErrorAction Stop | Select-Object -First 1
if (-not $process.MainWindowHandle -or $process.MainWindowHandle -eq [IntPtr]::Zero) {
  throw "LDPlayer window handle was not found."
}

$rect = New-Object LdPlayerCaptureNative+RECT
if (-not [LdPlayerCaptureNative]::GetWindowRect($process.MainWindowHandle, [ref]$rect)) {
  throw "Failed to get LDPlayer window bounds."
}

$width = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top
if ($width -le 0 -or $height -le 0) {
  throw "LDPlayer window bounds are invalid: ${width}x${height}."
}

$outputPath = New-OutputPath
$bitmap = New-Object System.Drawing.Bitmap($width, $height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

try {
  $hdc = $graphics.GetHdc()
  try {
    $ok = [LdPlayerCaptureNative]::PrintWindow($process.MainWindowHandle, $hdc, 2)
  } finally {
    $graphics.ReleaseHdc($hdc)
  }

  if (-not $ok) {
    throw "PrintWindow failed for LDPlayer."
  }

  $imageFormat = switch ($Format.ToLowerInvariant()) {
    "png" { [System.Drawing.Imaging.ImageFormat]::Png }
    "jpg" { [System.Drawing.Imaging.ImageFormat]::Jpeg }
    "jpeg" { [System.Drawing.Imaging.ImageFormat]::Jpeg }
    "bmp" { [System.Drawing.Imaging.ImageFormat]::Bmp }
  }

  $bitmap.Save($outputPath, $imageFormat)
} finally {
  $graphics.Dispose()
  $bitmap.Dispose()
}

Write-Output $outputPath
