# Flutter build script
param(
  [string]$SupabaseUrl = "https://louwovfikbuyqopfmurn.supabase.co",
  [string]$SupabaseAnonKey = "sb_publishable_d7f6uF4p6jxLBnnObAl9bw_HSRlmFTA"
)

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