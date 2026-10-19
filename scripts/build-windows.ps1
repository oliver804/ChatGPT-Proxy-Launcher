param([switch]$Test)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$version = (Get-Content VERSION -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid version' }
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$build = Join-Path $root 'build/windows'
$publish = Join-Path $build 'publish'
$release = Join-Path $root "dist/$version"
New-Item -ItemType Directory -Force $build, $release | Out-Null
# Generate a multi-resolution ICO from the same reviewed artwork used by the app and website.
Add-Type -AssemblyName System.Drawing
$source = [System.Drawing.Image]::FromFile((Join-Path $root 'site/assets/icon.png'))
$images = [System.Collections.Generic.List[byte[]]]::new()
$sizes = @(16, 24, 32, 48, 64, 128, 256)
try {
    foreach ($size in $sizes) {
        $bitmap = [System.Drawing.Bitmap]::new($size, $size)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $memory = [System.IO.MemoryStream]::new()
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.DrawImage($source, 0, 0, $size, $size)
            $bitmap.Save($memory, [System.Drawing.Imaging.ImageFormat]::Png)
            $images.Add($memory.ToArray())
        } finally { $memory.Dispose(); $graphics.Dispose(); $bitmap.Dispose() }
    }
} finally { $source.Dispose() }
$stream = [System.IO.File]::Create((Join-Path $build 'Launcher.ico'))
$writer = [System.IO.BinaryWriter]::new($stream)
try {
    $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$sizes.Count)
    $offset = 6 + 16 * $sizes.Count
    for ($i = 0; $i -lt $sizes.Count; $i++) {
        $side = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
        $writer.Write([byte]$side); $writer.Write([byte]$side); $writer.Write([byte]0); $writer.Write([byte]0)
        $writer.Write([uint16]1); $writer.Write([uint16]32); $writer.Write([uint32]$images[$i].Length); $writer.Write([uint32]$offset)
        $offset += $images[$i].Length
    }
    foreach ($bytes in $images) { $writer.Write($bytes) }
} finally { $writer.Dispose(); $stream.Dispose() }
if (Test-Path $publish) { Remove-Item $publish -Recurse -Force }
dotnet run --project Windows/Tests -c Release
if ($LASTEXITCODE -ne 0) { throw 'Core tests failed' }
dotnet publish Windows/App -c Release -r win-x64 --self-contained true -o $publish -p:PublishSingleFile=false -p:DebugType=None
if ($LASTEXITCODE -ne 0) { throw 'Windows publish failed' }
Copy-Item LICENSE, THIRD_PARTY_NOTICES.md $publish
# Include the license and notices distributed with the exact SDK used for this build.
$sdkRoot = Split-Path (Get-Command dotnet).Source -Parent
foreach ($notice in @('LICENSE.txt', 'ThirdPartyNotices.txt')) {
    $noticePath = Join-Path $sdkRoot $notice
    if (!(Test-Path $noticePath)) { throw "Missing .NET notice: $notice" }
    Copy-Item $noticePath (Join-Path $publish "DotNet-$notice")
}
$iscc = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe'
if (!(Test-Path $iscc)) { throw 'Install Inno Setup 6 before building the installer.' }
& $iscc "/DAppVersion=$version" Windows/Installer/launcher.iss
if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed' }
if ($Test) { & "$PSScriptRoot/test-windows.ps1" }
