@echo off
echo ========================================
echo WhiteBeard Pawn Plugin Installer Build
echo ========================================
echo.

REM Set paths
set WIXPATH="C:\Program Files (x86)\WiX Toolset v3.11\bin"
set PROJECTDIR=%~dp0
set OUTDIR=%PROJECTDIR%bin\Release

REM Check if WiX is installed
if not exist %WIXPATH%\candle.exe (
    echo ERROR: WiX Toolset not found at %WIXPATH%
    echo Please install WiX Toolset v3.11 or newer from https://wixtoolset.org/
    pause
    exit /b 1
)

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
echo Step 2: Compiling WiX source files...
%WIXPATH%\candle.exe -ext WixUIExtension -ext WixUtilExtension -o "obj\Release\\" Product.wxs LicenseVerificationDialog.wxs MT5DetectionDialog.wxs UI\InstallDialogs.wxs
if errorlevel 1 (
    echo ERROR: WiX compilation failed
    pause
    exit /b 1
)

echo.
echo Step 3: Linking MSI package...
%WIXPATH%\light.exe -ext WixUIExtension -ext WixUtilExtension -o "%OUTDIR%\WhiteBeardPawnPlugin.msi" -cultures:en-us obj\Release\*.wixobj
if errorlevel 1 (
    echo ERROR: WiX linking failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build completed successfully!
echo MSI created at: %OUTDIR%\WhiteBeardPawnPlugin.msi
echo ========================================
pause
