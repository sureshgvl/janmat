# JanMat Web Deployment Script
# Created November 29, 2025

Write-Host "Starting JanMat Web Deployment..." -ForegroundColor Green

# Check prerequisites
Write-Host "Checking Flutter..." -ForegroundColor Yellow
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Flutter not found" -ForegroundColor Red
    Read-Host "Press Enter"
    exit 1
}
Write-Host "Flutter OK" -ForegroundColor Green

Write-Host "Checking Firebase..." -ForegroundColor Yellow
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Firebase not found" -ForegroundColor Red
    Read-Host "Press Enter"
    exit 1
}
Write-Host "Firebase OK" -ForegroundColor Green

# Version management
Write-Host "Reading version..." -ForegroundColor Yellow
$content = Get-Content "pubspec.yaml" -Raw
$versionMatch = [regex]::Match($content, 'version:\s*([0-9]+\.[0-9]+\.[0-9]+\+[0-9]+)')
$currentVersion = if ($versionMatch.Success) { $versionMatch.Groups[1].Value } else { "1.0.3+6" }
Write-Host "Current version: $currentVersion" -ForegroundColor Yellow

Write-Host "Version options:" -ForegroundColor Yellow
Write-Host "  1: Increment build number (+1)" -ForegroundColor Yellow
Write-Host "  Enter new version manually" -ForegroundColor Yellow
Write-Host "  Press Enter: Keep current version" -ForegroundColor Yellow

$choice = Read-Host "Choose option or enter new version"

if ([string]::IsNullOrWhiteSpace($choice)) {
    $newVersion = $currentVersion
    Write-Host "Keeping current version: $newVersion" -ForegroundColor Green
} elseif ($choice -eq "1") {
    # Increment build number (after the +)
    $parts = $currentVersion -split '\+'
    $baseVersion = $parts[0]
    $buildNumber = [int]$parts[1] + 1
    $newVersion = "$baseVersion+$buildNumber"
    Write-Host "Incremented version: $newVersion" -ForegroundColor Green
} else {
    $newVersion = $choice
}

Write-Host "Using version: $newVersion" -ForegroundColor Green

# Create backup
Copy-Item "pubspec.yaml" "pubspec.yaml.backup" -Force
Set-Content "pubspec.yaml" ($content -replace "version:\s*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+", "version: $newVersion") -Encoding UTF8
Write-Host "Version updated" -ForegroundColor Green

# Clear VS Code settings
$env:DART_FLUTTER_ADDITIONAL_ARGS = ""
$env:DART_FLUTTER_RUN_ADDITIONAL_ARGS = ""

# Flutter commands
Write-Host "Cleaning..." -ForegroundColor Yellow
& flutter --no-version-check clean

Write-Host "Getting dependencies..." -ForegroundColor Yellow
& flutter --no-version-check pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Dependencies failed" -ForegroundColor Red
    Read-Host "Press Enter"
    exit 1
}

Write-Host "Building..." -ForegroundColor Yellow
& flutter build web --release --no-wasm-dry-run
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Build failed" -ForegroundColor Red
    Read-Host "Press Enter"
    exit 1
}

Write-Host "Deploying..." -ForegroundColor Yellow
& firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Deployment failed" -ForegroundColor Red
    Read-Host "Press Enter"
    exit 1
}

Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "URL: https://janmat-official.web.app" -ForegroundColor Cyan
Read-Host "Press Enter to finish"
