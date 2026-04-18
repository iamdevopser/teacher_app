# Flutter Windows runner — project root is the parent of this script folder (run/)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location -LiteralPath $projectRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error 'flutter not found in PATH. Add the Flutter SDK bin folder to Path.'
    exit 1
}

Write-Output 'Cleaning project...'
flutter clean
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Output 'Getting dependencies...'
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Output 'Running on Windows...'
flutter run -d windows
exit $LASTEXITCODE
