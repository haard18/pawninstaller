#!/usr/bin/env pwsh
# PowerShell build script for WhiteBeard Pawn Plugin Installer (WiX v4)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WhiteBeard Pawn Plugin Installer Build" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ProjectDir = $PSScriptRoot
$OutDir = Join-Path $ProjectDir "bin\Release"

# Step 1: Build Custom Actions
Write-Host "Step 1: Building Custom Actions..." -ForegroundColor Yellow
Push-Location (Join-Path $ProjectDir "CustomActions")

dotnet restore
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to restore CustomActions project" -ForegroundColor Red
    Pop-Location
    exit 1
}

dotnet build -c Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build CustomActions project" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

# Step 2: Build MSI with WiX v4
Write-Host ""
Write-Host "Step 2: Building MSI with WiX v4..." -ForegroundColor Yellow

# Check if wix command is available
$wixCmd = Get-Command wix -ErrorAction SilentlyContinue
if (-not $wixCmd) {
    Write-Host "ERROR: WiX v4 not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install WiX v4 using:" -ForegroundColor Yellow
    Write-Host "  dotnet tool install --global wix" -ForegroundColor White
    Write-Host ""
    Write-Host "Or update if already installed:" -ForegroundColor Yellow
    Write-Host "  dotnet tool update --global wix" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Build the MSI
$msiPath = Join-Path $OutDir "WhiteBeardPawnPlugin.msi"
wix build -o $msiPath WhiteBeardPawnPlugin.wixproj -pdbtype none -arch x64

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: WiX build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "MSI created at: $msiPath" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
