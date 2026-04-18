# Flutter Windows runner — always uses the folder where this script lives as project root
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

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
