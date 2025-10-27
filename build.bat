@echo off
echo ========================================
echo WhiteBeard Pawn Plugin Installer Build
echo ========================================
echo.

REM Set paths
set PROJECTDIR=%~dp0
set OUTDIR=%PROJECTDIR%bin\Release

REM Try to find WiX in common installation locations
set WIXPATH=
if exist "C:\Program Files (x86)\WiX Toolset v3.11\bin\candle.exe" set WIXPATH=C:\Program Files (x86)\WiX Toolset v3.11\bin
if exist "C:\Program Files (x86)\WiX Toolset v3.14\bin\candle.exe" set WIXPATH=C:\Program Files (x86)\WiX Toolset v3.14\bin
if exist "C:\Program Files\WiX Toolset v3.11\bin\candle.exe" set WIXPATH=C:\Program Files\WiX Toolset v3.11\bin
if exist "C:\Program Files\WiX Toolset v3.14\bin\candle.exe" set WIXPATH=C:\Program Files\WiX Toolset v3.14\bin

REM Check if candle.exe is in PATH
where candle.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo WiX Toolset found in PATH
    set WIXPATH=
    goto :wix_found
)

REM Check if WiX was found
if "%WIXPATH%"=="" (
    echo ERROR: WiX Toolset not found!
    echo.
    echo Please install WiX Toolset v3.11 or newer from https://wixtoolset.org/
    echo.
    echo Alternatively, install via:
    echo   - Download from: https://github.com/wixtoolset/wix3/releases
    echo   - Or use dotnet tool: dotnet tool install --global wix
    echo.
    pause
    exit /b 1
)

echo Found WiX Toolset at: %WIXPATH%
:wix_found

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
if "%WIXPATH%"=="" (
    candle.exe -ext WixUIExtension -ext WixUtilExtension -o "obj\Release\\" Product.wxs LicenseVerificationDialog.wxs MT5DetectionDialog.wxs UI\InstallDialogs.wxs
) else (
    "%WIXPATH%\candle.exe" -ext WixUIExtension -ext WixUtilExtension -o "obj\Release\\" Product.wxs LicenseVerificationDialog.wxs MT5DetectionDialog.wxs UI\InstallDialogs.wxs
)
if errorlevel 1 (
    echo ERROR: WiX compilation failed
    pause
    exit /b 1
)

echo.
echo Step 3: Linking MSI package...
if "%WIXPATH%"=="" (
    light.exe -ext WixUIExtension -ext WixUtilExtension -o "%OUTDIR%\WhiteBeardPawnPlugin.msi" -cultures:en-us obj\Release\*.wixobj
) else (
    "%WIXPATH%\light.exe" -ext WixUIExtension -ext WixUtilExtension -o "%OUTDIR%\WhiteBeardPawnPlugin.msi" -cultures:en-us obj\Release\*.wixobj
)
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
