<#
  Generates real Firebase config for this project:
    - lib/firebase_options.dart
    - android/app/google-services.json (Android app in your Firebase project)

  Prereqs (one-time on your machine):
    - Flutter SDK on PATH (`flutter doctor`)
    - Firebase CLI login used by FlutterFire:
        npm i -g firebase-tools
        firebase login

  Usage (from project root):
    .\scripts\configure_firebase.ps1 YOUR_FIREBASE_PROJECT_ID

  Or:
    $env:FIREBASE_PROJECT = "YOUR_FIREBASE_PROJECT_ID"
    .\scripts\configure_firebase.ps1
#>

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

$projectId = $args[0]
if ([string]::IsNullOrWhiteSpace($projectId)) {
  $projectId = $env:FIREBASE_PROJECT
}
if ([string]::IsNullOrWhiteSpace($projectId)) {
  Write-Host ""
  Write-Host "Missing Firebase project id." -ForegroundColor Yellow
  Write-Host "  .\scripts\configure_firebase.ps1 <your-project-id>" -ForegroundColor Cyan
  Write-Host "or set env var FIREBASE_PROJECT then run the script again." -ForegroundColor Cyan
  Write-Host ""
  exit 1
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "Flutter was not found on PATH. Install Flutter and reopen this terminal."
}

if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
  Write-Error "Dart was not found on PATH. Install Flutter (it includes Dart) and reopen this terminal."
}

Write-Host "Project: $projectId" -ForegroundColor Green
Write-Host "Running flutter pub get..." -ForegroundColor Green
flutter pub get

Write-Host "Installing FlutterFire CLI..." -ForegroundColor Green
dart pub global activate flutterfire_cli

Write-Host "Running flutterfire configure (updates lib/firebase_options.dart + Android files)..." -ForegroundColor Green

# Android package must match android/app/build.gradle applicationId.
dart pub global run flutterfire_cli:flutterfire configure `
  --project="$projectId" `
  --yes `
  --platforms="android,web" `
  --android-package-name="com.tuition.attendance_manager"

Write-Host ""
Write-Host "Done. Next steps:" -ForegroundColor Green
Write-Host "  - Enable Phone sign-in in Firebase Console > Authentication > Sign-in method." -ForegroundColor Cyan
Write-Host "  - Add your Android SHA-256 (debug/release) for Phone Auth." -ForegroundColor Cyan
Write-Host "  - Deploy Firestore rules/indexes from this repo if you use Firebase CLI." -ForegroundColor Cyan
Write-Host ""
