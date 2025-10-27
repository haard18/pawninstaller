using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Security.Principal;
using System.Text;
using System.Threading.Tasks;
using WixToolset.Dtf.WindowsInstaller;
using Newtonsoft.Json;

namespace WhiteBeard.PawnPlugin.Installer
{
    public class CustomActions
    {
        private const string LICENSE_FOLDER = @"C:\ProgramData\WhiteBeard";
        private const string LICENSE_FILE_PATTERN = "*_pawn_plugin.lic";
        private const string DEFAULT_MT5_PATH = @"C:\MetaTrader 5 Platform\TradeMain";
        private const string API_VALIDATION_ENDPOINT = "https://api.whitebeard.ai/license/validate";

        /// <summary>
        /// Check if the current user has admin privileges to write to C drive
        /// </summary>
        [CustomAction]
        public static ActionResult CheckAdminPrivileges(Session session)
        {
            session.Log("Begin CheckAdminPrivileges");

            try
            {
                bool isAdmin = false;
                using (WindowsIdentity identity = WindowsIdentity.GetCurrent())
                {
                    WindowsPrincipal principal = new WindowsPrincipal(identity);
                    isAdmin = principal.IsInRole(WindowsBuiltInRole.Administrator);
                }

                session["HASADMINPRIVILEGES"] = isAdmin ? "1" : "0";
                session.Log($"Admin privileges check: {isAdmin}");

                if (!isAdmin)
                {
                    session.Log("ERROR: User does not have admin privileges");
                    MessageBox(session, "This installer requires administrator privileges to install the WhiteBeard Pawn Plugin.\n\nPlease run the installer as Administrator.", "Admin Privileges Required");
                    return ActionResult.Failure;
                }

                return ActionResult.Success;
            }
            catch (Exception ex)
            {
                session.Log($"ERROR in CheckAdminPrivileges: {ex.Message}");
                return ActionResult.Failure;
            }
        }

        /// <summary>
        /// Search for license file in C:\ProgramData\WhiteBeard folder
        /// </summary>
        [CustomAction]
        public static ActionResult SearchLicenseFile(Session session)
        {
            session.Log("Begin SearchLicenseFile");

            try
            {
                // First check if user already provided a path
                string existingPath = session["LICENSEFILE"];
                if (!string.IsNullOrEmpty(existingPath) && File.Exists(existingPath))
                {
                    session.Log($"License file already set: {existingPath}");
                    return ParseLicenseFile(session, existingPath);
                }

                // Create directory if it doesn't exist
                if (!Directory.Exists(LICENSE_FOLDER))
                {
                    session.Log($"License folder does not exist: {LICENSE_FOLDER}");
                    session["VALIDATIONMESSAGE"] = "No license file found. Please browse to your license file.";
                    return ActionResult.Success;
                }

                // Search for license files
                string[] licenseFiles = Directory.GetFiles(LICENSE_FOLDER, LICENSE_FILE_PATTERN);
                
                if (licenseFiles.Length == 0)
                {
                    session.Log("No license files found in default location");
                    session["VALIDATIONMESSAGE"] = "No license file found. Please browse to your license file.";
                    return ActionResult.Success;
                }

                // Use the first found license file
                string licenseFile = licenseFiles[0];
                session.Log($"Found license file: {licenseFile}");
                session["LICENSEFILE"] = licenseFile;

                return ParseLicenseFile(session, licenseFile);
            }
            catch (Exception ex)
            {
                session.Log($"ERROR in SearchLicenseFile: {ex.Message}");
                session["VALIDATIONMESSAGE"] = $"Error searching for license file: {ex.Message}";
                return ActionResult.Success; // Don't fail, let user browse
            }
        }

        /// <summary>
        /// Parse license file to extract company name and email
        /// </summary>
        private static ActionResult ParseLicenseFile(Session session, string filePath)
        {
            try
            {
                if (!File.Exists(filePath))
                {
                    session["VALIDATIONMESSAGE"] = "License file not found.";
                    return ActionResult.Success;
                }

                // Read the license file
                string licenseContent = File.ReadAllText(filePath);
                
                // Try to parse as JSON (assuming license file is JSON encrypted/encoded)
                try
                {
                    // This is a placeholder - actual decryption logic would go here
                    // For now, we'll assume the file contains base64 encoded JSON
                    var licenseData = DecryptLicenseData(licenseContent);
                    
                    if (licenseData != null)
                    {
                        session["COMPANYNAME"] = licenseData.CompanyName ?? "";
                        session["COMPANYEMAIL"] = licenseData.CompanyEmail ?? "";
                        session["VALIDATIONMESSAGE"] = "License file loaded. Click Next to validate.";
                        session.Log($"Parsed license - Company: {licenseData.CompanyName}, Email: {licenseData.CompanyEmail}");
                    }
                }
                catch (Exception parseEx)
                {
                    session.Log($"Could not parse license file: {parseEx.Message}");
                    session["VALIDATIONMESSAGE"] = "License file format invalid.";
                }

                return ActionResult.Success;
            }
            catch (Exception ex)
            {
                session.Log($"ERROR in ParseLicenseFile: {ex.Message}");
                session["VALIDATIONMESSAGE"] = $"Error reading license file: {ex.Message}";
                return ActionResult.Success;
            }
        }

        /// <summary>
        /// Validate license file by calling WhiteBeard API
        /// </summary>
        [CustomAction]
        public static ActionResult ValidateLicense(Session session)
        {
            session.Log("Begin ValidateLicense");

            try
            {
                string licenseFile = session["LICENSEFILE"];
                
                if (string.IsNullOrEmpty(licenseFile) || !File.Exists(licenseFile))
                {
                    session["VALIDATIONMESSAGE"] = "Please select a valid license file.";
                    session["LICENSEVALID"] = "0";
                    return ActionResult.Success;
                }

                // Read license file content
                string licenseContent = File.ReadAllText(licenseFile);
                
                // Call API to validate
                bool isValid = ValidateLicenseWithAPI(session, licenseContent).Result;
                
                session["LICENSEVALID"] = isValid ? "1" : "0";
                
                if (isValid)
                {
                    session["VALIDATIONMESSAGE"] = "License validated successfully!";
                    session.Log("License validation successful");
                }
                else
                {
                    session["VALIDATIONMESSAGE"] = "License validation failed. Please contact WhiteBeard for assistance.";
                    session.Log("License validation failed");
                }

                return ActionResult.Success;
            }
            catch (Exception ex)
            {
                session.Log($"ERROR in ValidateLicense: {ex.Message}");
                session["VALIDATIONMESSAGE"] = $"Error validating license: {ex.Message}";
                session["LICENSEVALID"] = "0";
                return ActionResult.Success;
            }
        }

        /// <summary>
        /// Call API endpoint to validate license
        /// </summary>
        private static async Task<bool> ValidateLicenseWithAPI(Session session, string licenseContent)
        {
            try
            {
                using (var client = new HttpClient())
                {
                    client.Timeout = TimeSpan.FromSeconds(30);
                    
                    var payload = new
                    {
                        licenseData = licenseContent,
                        product = "pawn_plugin"
                    };

                    var json = JsonConvert.SerializeObject(payload);
                    var content = new StringContent(json, Encoding.UTF8, "application/json");
                    
                    session.Log($"Calling API: {API_VALIDATION_ENDPOINT}");
                    var response = await client.PostAsync(API_VALIDATION_ENDPOINT, content);
                    
                    session.Log($"API Response Status: {response.StatusCode}");
                    
                    if (response.IsSuccessStatusCode)
                    {
                        var responseContent = await response.Content.ReadAsStringAsync();
                        var result = JsonConvert.DeserializeObject<LicenseValidationResponse>(responseContent);
                        return result?.IsValid ?? false;
                    }
                    
                    return false;
                }
            }
            catch (Exception ex)
            {
                session.Log($"API validation error: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Detect MT5 installation directory
        /// </summary>
        [CustomAction]
        public static ActionResult DetectMT5Installation(Session session)
        {
            session.Log("Begin DetectMT5Installation");

            try
            {
                // Check if user already provided a path
                string existingPath = session["MT5DIRECTORY"];
                
                if (!string.IsNullOrEmpty(existingPath))
                {
                    if (ValidateMT5Directory(existingPath))
                    {
                        session.Log($"MT5 directory validated: {existingPath}");
                        session["MT5STATUSMESSAGE"] = "MT5 installation found and validated.";
                        return ActionResult.Success;
                    }
                    else
                    {
                        session["MT5STATUSMESSAGE"] = "Selected directory is not a valid MT5 installation.";
                        return ActionResult.Success;
                    }
                }

                // Try default location
                if (Directory.Exists(DEFAULT_MT5_PATH) && ValidateMT5Directory(DEFAULT_MT5_PATH))
                {
                    session["MT5DIRECTORY"] = DEFAULT_MT5_PATH;
                    session["MT5STATUSMESSAGE"] = "MT5 installation detected at default location.";
                    session.Log($"MT5 found at default location: {DEFAULT_MT5_PATH}");
                    return ActionResult.Success;
                }

                // Look in common installation locations
                string[] commonPaths = new[]
                {
                    @"C:\Program Files\MetaTrader 5",
                    @"C:\Program Files (x86)\MetaTrader 5",
                    @"C:\MetaTrader 5",
                    @"C:\MT5"
                };

                foreach (string path in commonPaths)
                {
                    if (Directory.Exists(path) && ValidateMT5Directory(path))
                    {
                        session["MT5DIRECTORY"] = path;
                        session["MT5STATUSMESSAGE"] = $"MT5 installation detected at {path}";
                        session.Log($"MT5 found at: {path}");
                        return ActionResult.Success;
                    }
                }

                session["MT5STATUSMESSAGE"] = "MT5 not found. Please browse to your MT5 installation directory.";
                session.Log("MT5 not found in default locations");
                
                return ActionResult.Success;
            }
            catch (Exception ex)
            {
                session.Log($"ERROR in DetectMT5Installation: {ex.Message}");
                session["MT5STATUSMESSAGE"] = $"Error detecting MT5: {ex.Message}";
                return ActionResult.Success;
            }
        }

        /// <summary>
        /// Validate that a directory is a valid MT5 installation
        /// </summary>
        private static bool ValidateMT5Directory(string path)
        {
            if (!Directory.Exists(path))
                return false;

            // Check for MT5 executable or Plugins folder
            string terminal64 = Path.Combine(path, "terminal64.exe");
            string terminal = Path.Combine(path, "terminal.exe");
            
            return File.Exists(terminal64) || File.Exists(terminal);
        }

        /// <summary>
        /// Copy plugin files to MT5 and license file to ProgramData
        /// </summary>
        [CustomAction]
        public static ActionResult CopyPluginFiles(Session session)
        {
            session.Log("Begin CopyPluginFiles");

            try
            {
                string mt5Directory = session["MT5DIRECTORY"];
                string licenseFile = session["LICENSEFILE"];
                
                if (string.IsNullOrEmpty(mt5Directory))
                {
                    session.Log("ERROR: MT5 directory not set");
                    return ActionResult.Failure;
                }

                if (string.IsNullOrEmpty(licenseFile))
                {
                    session.Log("ERROR: License file not set");
                    return ActionResult.Failure;
                }

                // Create Plugins folder if it doesn't exist
                string pluginsFolder = Path.Combine(mt5Directory, "Plugins");
                if (!Directory.Exists(pluginsFolder))
                {
                    Directory.CreateDirectory(pluginsFolder);
                    session.Log($"Created Plugins folder: {pluginsFolder}");
                }

                // Copy PawnPlugin64.dll to Plugins folder
                string sourcePlugin = Path.Combine(session["INSTALLFOLDER"], "PawnPlugin64.dll");
                string destPlugin = Path.Combine(pluginsFolder, "PawnPlugin64.dll");
                
                if (File.Exists(sourcePlugin))
                {
                    File.Copy(sourcePlugin, destPlugin, true);
                    session.Log($"Copied plugin: {sourcePlugin} -> {destPlugin}");
                }
                else
                {
                    session.Log($"WARNING: Plugin source file not found: {sourcePlugin}");
                }

                // Create WhiteBeard folder in ProgramData if needed
                if (!Directory.Exists(LICENSE_FOLDER))
                {
                    Directory.CreateDirectory(LICENSE_FOLDER);
                    session.Log($"Created license folder: {LICENSE_FOLDER}");
                }

                // Copy license file to ProgramData\WhiteBeard
                string licenseFileName = Path.GetFileName(licenseFile);
                string destLicense = Path.Combine(LICENSE_FOLDER, licenseFileName);
                
                File.Copy(licenseFile, destLicense, true);
                session.Log($"Copied license: {licenseFile} -> {destLicense}");

                return ActionResult.Success;
            }
            catch (Exception ex)
            {
                session.Log($"ERROR in CopyPluginFiles: {ex.Message}");
                MessageBox(session, $"Error copying files: {ex.Message}", "Installation Error");
                return ActionResult.Failure;
            }
        }

        /// <summary>
        /// Decrypt/decode license data from file content
        /// </summary>
        private static LicenseData DecryptLicenseData(string licenseContent)
        {
            try
            {
                // This is a placeholder implementation
                // In production, you would decrypt/decode the license file properly
                
                // Attempt to decode from Base64
                byte[] data = Convert.FromBase64String(licenseContent);
                string json = Encoding.UTF8.GetString(data);
                
                return JsonConvert.DeserializeObject<LicenseData>(json);
            }
            catch
            {
                // If Base64 decode fails, try parsing as plain JSON
                try
                {
                    return JsonConvert.DeserializeObject<LicenseData>(licenseContent);
                }
                catch
                {
                    return null;
                }
            }
        }

        /// <summary>
        /// Show a message box to the user
        /// </summary>
        private static void MessageBox(Session session, string message, string caption)
        {
            using (Record record = new Record(0))
            {
                record.FormatString = message;
                session.Message(InstallMessage.Error | (InstallMessage)MessageButtons.OK, record);
            }
        }

        // Helper classes for JSON serialization
        private class LicenseData
        {
            [JsonProperty("company_name")]
            public string CompanyName { get; set; }
            
            [JsonProperty("company_email")]
            public string CompanyEmail { get; set; }
            
            [JsonProperty("license_key")]
            public string LicenseKey { get; set; }
            
            [JsonProperty("expiry_date")]
            public string ExpiryDate { get; set; }
        }

        private class LicenseValidationResponse
        {
            [JsonProperty("is_valid")]
            public bool IsValid { get; set; }
            
            [JsonProperty("message")]
            public string Message { get; set; }
        }
    }
}
