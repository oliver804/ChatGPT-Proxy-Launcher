$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$version = (Get-Content VERSION -Raw).Trim()
$build = Join-Path $root 'build/windows'
$fixture = Join-Path $build 'fixture with spaces'
$results = Join-Path $build 'test-results'
New-Item -ItemType Directory -Force $results | Out-Null
dotnet publish Windows/Fixture -c Release -r win-x64 --self-contained true -o $fixture
if ($LASTEXITCODE -ne 0) { throw 'Fixture build failed' }
New-Item -ItemType Directory -Force (Join-Path $fixture 'resources') | Out-Null
foreach ($marker in @('resources/app.asar', 'icudtl.dat', 'chrome_100_percent.pak')) { Set-Content (Join-Path $fixture $marker) 'Integration fixture only' }
function Run-App([string]$exe, [string]$arguments, [int]$seconds = 90) {
    $process = Start-Process -FilePath $exe -ArgumentList $arguments -PassThru
    if (!$process.WaitForExit($seconds * 1000)) { $process.Kill(); throw "Test-owned process timed out: $exe" }
    if ($process.ExitCode -ne 0) { Get-ChildItem $results -Filter '*.txt' | Get-Content; throw "Process failed: $($process.ExitCode)" }
}
$installer = Join-Path $root "dist/$version/Local-Route-Launcher-$version-windows-x64-setup.exe"
$install = Join-Path $build 'installed app with spaces'
Run-App $installer "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /DIR=`"$install`"" 180
$exe = Join-Path $install 'LocalRouteLauncher.exe'
if (!(Test-Path $exe)) { throw 'Installer did not create the app' }
# Test the installed self-contained executable, not dotnet run.
Run-App $exe "--integration-test `"$(Join-Path $fixture 'ChatGPT.exe')`" `"$(Join-Path $results 'integration.txt')`""
Run-App $exe "--smoke-test `"$results`""
if (!(Test-Path (Join-Path $results 'ui-result.txt'))) { throw 'UI smoke test did not complete' }
Get-Content (Join-Path $results 'integration.txt'), (Join-Path $results 'ui-result.txt')
Run-App (Join-Path $install 'unins000.exe') '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' 180
if (Test-Path $exe) { throw 'Uninstaller left the app executable behind' }
Write-Output 'PASS: per-user installation and uninstall; no administrator elevation requested by installer.'
