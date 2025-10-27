@echo off
echo ========================================
echo WhiteBeard Pawn Plugin Installer Build
echo ========================================
echo.

REM Set paths
set PROJECTDIR=%~dp0
set OUTDIR=%PROJECTDIR%bin\Release

echo Step 1: Building Custom Actions...
cd "%PROJECTDIR%CustomActions"
dotnet restore
if errorlevel 1 (
    echo ERROR: Failed to restore CustomActions project
    pause
    exit /b 1
)

dotnet build -c Release
if errorlevel 1 (
    echo ERROR: Failed to build CustomActions project
    pause
    exit /b 1
)
cd "%PROJECTDIR%"

echo.
echo Step 2: Building MSI with WiX v4...

REM Check if wix command is available
where wix >nul 2>&1
if errorlevel 1 (
    echo ERROR: WiX v4 not found!
    echo.
    echo Please install WiX v4 using:
    echo   dotnet tool install --global wix
    echo.
    echo Or update if already installed:
    echo   dotnet tool update --global wix
    echo.
    pause
    exit /b 1
)

REM Build the MSI using dotnet build (recommended for WiX v4 SDK projects)
dotnet build WhiteBeardPawnPlugin.wixproj -c Release
if errorlevel 1 (
    echo ERROR: WiX build failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build completed successfully!
echo MSI created at: %OUTDIR%\WhiteBeardPawnPlugin.msi
echo ========================================
pause
