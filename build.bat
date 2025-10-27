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
set WIXVERSION=

REM Check dotnet tools path first (most common for WiX v4+)
if exist "%USERPROFILE%\.dotnet\tools\wix.exe" (
    set WIXPATH=%USERPROFILE%\.dotnet\tools
    set WIXVERSION=4
)

REM Check traditional WiX v3 installation paths
if "%WIXPATH%"=="" (
    if exist "C:\Program Files (x86)\WiX Toolset v3.11\bin\candle.exe" (
        set "WIXPATH=C:\Program Files (x86)\WiX Toolset v3.11\bin"
        set WIXVERSION=3
    )
)
if "%WIXPATH%"=="" (
    if exist "C:\Program Files (x86)\WiX Toolset v3.14\bin\candle.exe" (
        set "WIXPATH=C:\Program Files (x86)\WiX Toolset v3.14\bin"
        set WIXVERSION=3
    )
)
if "%WIXPATH%"=="" (
    if exist "C:\Program Files\WiX Toolset v3.11\bin\candle.exe" (
        set "WIXPATH=C:\Program Files\WiX Toolset v3.11\bin"
        set WIXVERSION=3
    )
)
if "%WIXPATH%"=="" (
    if exist "C:\Program Files\WiX Toolset v3.14\bin\candle.exe" (
        set "WIXPATH=C:\Program Files\WiX Toolset v3.14\bin"
        set WIXVERSION=3
    )
)

REM Check if wix.exe (v4) is in PATH
where wix.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo WiX Toolset v4 found in PATH
    set WIXPATH=
    set WIXVERSION=4
    goto :wix_found
)

REM Check if candle.exe (v3) is in PATH
where candle.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo WiX Toolset v3 found in PATH
    set WIXPATH=
    set WIXVERSION=3
    goto :wix_found
)

REM Check if WiX was found
if "%WIXVERSION%"=="" (
    echo ERROR: WiX Toolset not found!
    echo.
    echo This project requires WiX Toolset v3.11 or newer.
    echo.
    echo Install options:
    echo   - WiX v3: Download from https://github.com/wixtoolset/wix3/releases
    echo   - WiX v4: dotnet tool install --global wix (Note: Requires project updates for v4^)
    echo.
    pause
    exit /b 1
)

if "%WIXVERSION%"=="4" (
    echo ERROR: This project is designed for WiX v3, but WiX v4 was found.
    echo.
    echo Please install WiX Toolset v3.11 from:
    echo https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/wix311.exe
    echo.
    echo Or uninstall WiX v4 with: dotnet tool uninstall --global wix
    echo.
    pause
    exit /b 1
)

echo Found WiX Toolset v3 at: %WIXPATH%
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