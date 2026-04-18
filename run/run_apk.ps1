# Flutter APK release build. Requires Supabase env vars (no secrets in repo).
# Set SUPABASE_URL and SUPABASE_ANON_KEY or pass -SupabaseUrl / -SupabaseAnonKey.
param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabaseAnonKey = $env:SUPABASE_ANON_KEY
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location -LiteralPath $projectRoot

if (-not $SupabaseUrl -or -not $SupabaseAnonKey) {
  Write-Error 'SUPABASE_URL and SUPABASE_ANON_KEY must be set (environment) or pass -SupabaseUrl and -SupabaseAnonKey. See .env.example and README.md.'
  exit 1
}

Write-Output "Cleaning project..."
flutter clean

Write-Output "Getting dependencies..."
flutter pub get

Write-Output "Stopping existing Gradle daemons..."
Push-Location "android"
.\gradlew --stop
Pop-Location

Write-Output "Building APK..."
flutter build apk `
  --dart-define=SUPABASE_URL=$SupabaseUrl `
  --dart-define=SUPABASE_ANON_KEY=$SupabaseAnonKey

Write-Output "Done!"
