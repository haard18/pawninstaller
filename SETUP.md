# WhiteBeard Pawn Plugin - Windows Installer

A WiX-based Windows installer (MSI) for the WhiteBeard Pawn Plugin for MetaTrader 5.

## Features

### License Verification
- **Automatic License Detection**: Searches `C:\ProgramData\WhiteBeard` for license files ending with `_pawn_plugin.lic`
- **Manual License Selection**: Users can browse to select their license file if not found automatically
- **License Validation**: Validates license authenticity via WhiteBeard API endpoint
- **Company Information Display**: Extracts and displays company name and email from license file

### Administrator Privileges
- **Automatic Detection**: Checks if user has administrator privileges required for installation
- **Warning Prompt**: Alerts user if admin rights are not available

### MT5 Detection
- **Default Path Detection**: Automatically searches for MT5 at `C:\MetaTrader 5 Platform\TradeMain`
- **Common Paths Search**: Checks additional common MT5 installation locations
- **Manual Selection**: Allows user to browse to custom MT5 installation directory
- **Validation**: Verifies selected directory is a valid MT5 installation

### File Installation
- **Plugin Deployment**: Copies `PawnPlugin64.dll` to MT5's `/Plugins` folder
- **License Storage**: Copies license file to `C:\ProgramData\WhiteBeard` for plugin access
- **Directory Creation**: Automatically creates necessary directories if they don't exist

### User Interface
- Custom WiX dialogs for intuitive installation flow
- License agreement acceptance
- Progress indication during installation
- Error handling with informative messages

## Prerequisites

### Development Environment
- **Windows OS**: Windows 10/11 or Windows Server 2016+
- **WiX Toolset**: v3.11 or newer ([Download](https://wixtoolset.org/releases/))
- **.NET Framework**: 4.7.2 or newer (for custom actions)
- **.NET SDK**: 6.0+ for building custom actions
- **Visual Studio**: 2019/2022 (optional, but recommended for development)

## Project Structure

```
pawninstaller/
├── CustomActions/              # C# custom action library
│   ├── CustomActions.cs        # Main custom action implementations
│   └── CustomActions.csproj    # Project file
├── UI/                         # UI dialog definitions
│   └── InstallDialogs.wxs      # Custom UI flow definitions
├── Payload/                    # Files to be installed
│   ├── PawnPlugin64.dll        # MT5 plugin DLL (to be provided)
│   └── example_pawn_plugin.lic # Sample license file
├── Product.wxs                 # Main WiX product definition
├── LicenseVerificationDialog.wxs  # License verification UI
├── MT5DetectionDialog.wxs      # MT5 detection UI
├── License.rtf                 # EULA text
├── WhiteBeardPawnPlugin.wixproj   # WiX project file
├── WhiteBeardPawnPlugin.sln    # Visual Studio solution
├── build.bat                   # Windows build script
└── build.sh                    # Cross-platform build script
```

## Building the Installer

### Method 1: Using Visual Studio
1. Open `WhiteBeardPawnPlugin.sln` in Visual Studio
2. Build the solution (F6 or Build > Build Solution)
3. Find the MSI in `bin\Release\WhiteBeardPawnPlugin.msi`

### Method 2: Using Command Line (Windows)
```batch
build.bat
```

### Method 3: Using Command Line (Cross-platform)
```bash
chmod +x build.sh
./build.sh
```

## Installation Flow

1. **Welcome Screen**: Initial installer welcome
2. **License Verification**:
   - Automatic search for license file in `C:\ProgramData\WhiteBeard`
   - Display company name and email from license
   - Manual browse option if not found
   - API validation of license authenticity
3. **MT5 Detection**:
   - Automatic detection of MT5 installation
   - Manual browse option for custom installations
4. **License Agreement**: User must accept EULA
5. **Ready to Install**: Final confirmation
6. **Installation Progress**: Copy files and configure system
7. **Completion**: Installation finished

## Custom Actions

The installer includes several custom actions implemented in C#:

### CheckAdminPrivileges
Verifies the user has administrator rights required for installation.

### SearchLicenseFile
Searches `C:\ProgramData\WhiteBeard` for license files matching `*_pawn_plugin.lic` pattern.

### ValidateLicense
- Parses license file to extract company information
- Calls WhiteBeard API endpoint to validate license authenticity
- Endpoint: `https://api.whitebeard.ai/license/validate`

### DetectMT5Installation
- Checks default MT5 installation path
- Searches common installation directories
- Validates directory contains MT5 executable

### CopyPluginFiles
- Copies `PawnPlugin64.dll` to MT5 Plugins folder
- Copies license file to `C:\ProgramData\WhiteBeard`
- Creates directories as needed

## License File Format

License files should be JSON format (optionally Base64 encoded):

```json
{
  "company_name": "Example Company",
  "company_email": "company@example.com",
  "license_key": "XXXX-XXXX-XXXX-XXXX",
  "product": "pawn_plugin",
  "issued_date": "2025-01-01",
  "expiry_date": "2026-01-01",
  "features": ["mt5_plugin", "api_access"]
}
```

## API Integration

The installer validates licenses by calling:

**Endpoint**: `POST https://api.whitebeard.ai/license/validate`

**Request Body**:
```json
{
  "licenseData": "<license_file_content>",
  "product": "pawn_plugin"
}
```

**Response**:
```json
{
  "is_valid": true,
  "message": "License validated successfully"
}
```

## Deployment

### Prerequisites for End Users
- Windows 10/11 or Windows Server 2016+
- Administrator privileges
- MetaTrader 5 installed
- Valid WhiteBeard Pawn Plugin license file

### Distribution
1. Build the MSI using one of the methods above
2. Distribute `WhiteBeardPawnPlugin.msi` to customers
3. Provide license file (`*_pawn_plugin.lic`) separately via:
   - Email (from info@whitebeard.ai)
   - Download from app.whitebeard.ai

### Customer Installation Steps
1. Download `WhiteBeardPawnPlugin.msi`
2. Obtain license file from WhiteBeard
3. Right-click MSI and select "Run as Administrator"
4. Follow installation wizard
5. Select or verify license file location
6. Confirm MT5 installation directory
7. Accept license agreement
8. Complete installation

## Contact Information

For licensing, support, or inquiries:

- **Website**: [www.whitebeard.ai](https://www.whitebeard.ai)
- **Email**: info@whitebeard.ai
- **Phone**: +1 646 422 8482

## License

Copyright © 2025 WhiteBeard. All rights reserved.

This installer and the WhiteBeard Pawn Plugin are proprietary software. See `License.rtf` for full license agreement.

## Troubleshooting

### Build Issues

**WiX Toolset Not Found**
- Ensure WiX Toolset v3.11+ is installed
- Verify WiX bin folder is in PATH or update `build.bat` with correct path

**Custom Actions Build Fails**
- Ensure .NET SDK 6.0+ is installed
- Run `dotnet restore` in CustomActions folder
- Check for missing NuGet packages

**Missing References**
- Restore NuGet packages: `dotnet restore CustomActions/CustomActions.csproj`

### Installation Issues

**"Admin Privileges Required"**
- Right-click MSI and select "Run as Administrator"

**"License File Not Found"**
- Ensure license file ends with `_pawn_plugin.lic`
- Place in `C:\ProgramData\WhiteBeard` or browse manually

**"License Validation Failed"**
- Check internet connection
- Verify license file is valid and not expired
- Contact WhiteBeard support

**"MT5 Not Detected"**
- Ensure MetaTrader 5 is installed
- Use Browse button to manually select MT5 directory
- Verify selected folder contains `terminal64.exe` or `terminal.exe`

## Development Notes

### Adding New Features
1. Update WiX source files (`.wxs`) for UI changes
2. Implement custom actions in `CustomActions.cs` for logic
3. Reference custom actions in `Product.wxs`
4. Update build scripts if adding new files
5. Test installation on clean Windows VM

### Debugging
- Enable WiX verbose logging:
  ```
  msiexec /i WhiteBeardPawnPlugin.msi /l*v install.log
  ```
- Check custom action logs in installer session log
- Use Visual Studio debugger for custom actions (attach to msiexec.exe)

## Version History

**1.0.0** - Initial Release
- License verification with API validation
- Automatic MT5 detection
- Admin privilege checking
- File installation to MT5 Plugins folder
- License storage in ProgramData
