# initai.dev PowerShell installer
# Initialize LLM frameworks quickly and consistently

param(
    [string]$BaseUrl = "https://initai.dev",
    [switch]$Force,
    [switch]$Help,
    [switch]$Update
)

# Configuration
$ConfigFile = ".initai.json"
$InitaiDir = "initai"
$AppDataPath = "$env:LOCALAPPDATA\initai"
$InstalledScriptPath = "$AppDataPath\install.ps1"
$VersionFile = "$AppDataPath\.initai-version"
$GlobalConfigFile = "$env:USERPROFILE\.initai"
$CurrentVersion = "2.0.0"

# Colors for output
$Red = @{ ForegroundColor = "Red" }
$Green = @{ ForegroundColor = "Green" }
$Yellow = @{ ForegroundColor = "Yellow" }
$Blue = @{ ForegroundColor = "Blue" }
$Cyan = @{ ForegroundColor = "Cyan" }

function Write-Header {
    Write-Host "initai.dev - LLM Framework Installer" @Blue
    Write-Host "Initializing your development environment..."
}

function Show-Help {
    Write-Host "Usage: .\install.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -BaseUrl URL     Custom base URL (default: https://initai.dev)"
    Write-Host "  -Force           Force reconfiguration"
    Write-Host "  -Update          Force check for script updates"
    Write-Host "  -Help            Show this help"
    Write-Host ""
    Write-Host "Configuration file: $ConfigFile"
    Write-Host "App data location: $AppDataPath"
}

function Test-Dependencies {
    if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: curl is required but not found" @Red
        Write-Host "Please install curl or use PowerShell 7+ with built-in curl"
        exit 1
    }
}

function Initialize-AppData {
    if (-not (Test-Path $AppDataPath)) {
        New-Item -ItemType Directory -Path $AppDataPath -Force | Out-Null
        Write-Host "Created app data directory: $AppDataPath" @Green
    }
}

function Test-ScriptUpdate {
    Write-Host "Checking for script updates..." @Cyan

    try {
        $updateUrl = "$BaseUrl/api/check-updates?client_version=$CurrentVersion&script=powershell"
        $response = Invoke-RestMethod -Uri $updateUrl -UseBasicParsing

        if ($response.update_available) {
            Write-Host "Update available: v$($response.current_version)" @Yellow
            Write-Host "Current version: v$CurrentVersion" @Cyan

            if ($Update -or (Confirm-Update $response)) {
                Update-Script $response
                return $true
            }
        } else {
            Write-Host "Script is up to date (v$CurrentVersion)" @Green
        }

        return $false
    }
    catch {
        Write-Host "WARNING: Could not check for updates: $($_.Exception.Message)" @Yellow
        return $false
    }
}

function Confirm-Update {
    param($updateInfo)

    Write-Host ""
    Write-Host "Changelog:" @Blue
    foreach ($change in $updateInfo.changelog) {
        Write-Host "  v$($change.version) ($($change.date)):" @Cyan
        foreach ($item in $change.changes) {
            Write-Host "    - $item" @White
        }
    }

    Write-Host ""
    $response = Read-Host "Update to v$($updateInfo.current_version)? (y/N)"
    return $response -eq "y" -or $response -eq "Y"
}

function Update-Script {
    param($updateInfo)

    Write-Host "Downloading script update..." @Yellow

    try {
        # Download new script
        $downloadUrl = "$BaseUrl$($updateInfo.download_url)"
        $tempScript = "$AppDataPath\install.ps1.new"

        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempScript -UseBasicParsing

        # Backup current script if it exists
        if (Test-Path $InstalledScriptPath) {
            Copy-Item $InstalledScriptPath "$InstalledScriptPath.backup" -Force
        }

        # Replace script
        Move-Item $tempScript $InstalledScriptPath -Force

        # Update version file
        $updateInfo.current_version | Set-Content $VersionFile

        Write-Host "Script updated to v$($updateInfo.current_version)" @Green
        Write-Host "Please run the updated script from: $InstalledScriptPath" @Blue

        exit 0
    }
    catch {
        Write-Host "ERROR: Failed to update script: $($_.Exception.Message)" @Red
        if (Test-Path "$InstalledScriptPath.backup") {
            Move-Item "$InstalledScriptPath.backup" $InstalledScriptPath -Force
            Write-Host "Restored backup script" @Yellow
        }
    }
}

function Install-ScriptToAppData {
    if (-not (Test-Path $InstalledScriptPath) -or $script:Force) {
        Write-Host "Installing script to app data..." @Yellow

        try {
            # Copy current script to app data
            Copy-Item $MyInvocation.ScriptName $InstalledScriptPath -Force
            $CurrentVersion | Set-Content $VersionFile

            Write-Host "Script installed to: $InstalledScriptPath" @Green
            Write-Host "You can now run 'initai' from anywhere (if added to PATH)" @Blue

            return $true
        }
        catch {
            Write-Host "WARNING: Could not install to app data: $($_.Exception.Message)" @Yellow
            return $false
        }
    }
    return $false
}

function Test-Configuration {
    if ((Test-Path $ConfigFile) -and -not $Force) {
        Write-Host "Found existing configuration" @Green
        return $true
    } else {
        Write-Host "Setting up new configuration..." @Yellow
        return $false
    }
}

function Get-AvailablePackages {
    $packagesUrl = "$BaseUrl/init/shared/list"
    Write-Host "Getting available packages from $packagesUrl..." @Cyan

    try {
        $response = Invoke-RestMethod -Uri $packagesUrl -UseBasicParsing
        Write-Host "Found $($response.total) available packages" @Green
        return $response.packages
    }
    catch {
        Write-Host "ERROR: Failed to get packages from $packagesUrl" @Red
        Write-Host $_.Exception.Message @Red
        exit 1
    }
}

function Select-Package {
    param($packages)

    # Add usage statistics to packages
    $packagesWithStats = Get-PackageUsageStats $packages

    Write-Host ""
    Write-Host "Available packages:" @Blue

    $i = 1
    foreach ($package in $packagesWithStats) {
        $displayName = if ($package.llm -eq "universal") {
            "$($package.framework) (Universal)"
        } else {
            "$($package.framework) ($($package.llm))"
        }

        $usageText = ""
        if ($package.usage_count -gt 0) {
            $usageText = " - Used $($package.usage_count) times"
            if ($i -eq 1) {
                $usageText += " [MOST USED]"
            }
        }

        Write-Host "  $i) $displayName$usageText" @Cyan
        if ($package.usage_count -eq 0) {
            Write-Host "     $($package.description)" @White
        }
        $i++
    }

    do {
        $selection = Read-Host "`nSelect package (1-$($packagesWithStats.Count))"
        $selectionNum = [int]$selection
    } while ($selectionNum -lt 1 -or $selectionNum -gt $packagesWithStats.Count)

    return $packagesWithStats[$selectionNum - 1]
}

function Download-Package {
    param($package)

    $targetDir = Join-Path $InitaiDir "$($package.framework)-$($package.llm)"
    Write-Host ""
    Write-Host "Downloading $($package.framework) ($($package.llm)) package..." @Yellow

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    try {
        $downloadUrl = "$BaseUrl$($package.download_url)"
        $zipFile = "$targetDir\package.zip"

        Write-Host "  Downloading from $downloadUrl..." @Cyan
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing

        Write-Host "  Extracting package..." @Cyan
        Expand-Archive -Path $zipFile -DestinationPath $targetDir -Force

        # Remove the zip file
        Remove-Item $zipFile -Force

        Write-Host "Package downloaded and extracted to: $targetDir" @Green
        return $targetDir
    }
    catch {
        Write-Host "ERROR: Failed to download package: $($_.Exception.Message)" @Red
        throw
    }
}

function Save-Configuration {
    param($package, $targetDir)

    $config = @{
        base_url = $BaseUrl
        framework = $package.framework
        llm = $package.llm
        description = $package.description
        download_url = $package.download_url
        target_dir = $targetDir
        last_updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        script_version = $CurrentVersion
    }

    $config | ConvertTo-Json | Set-Content $ConfigFile
    Write-Host "Configuration saved to $ConfigFile" @Green
}

function Get-CurrentConfiguration {
    if (Test-Path $ConfigFile) {
        $config = Get-Content $ConfigFile | ConvertFrom-Json
        return $config
    }
    return $null
}

function Get-GlobalConfiguration {
    if (Test-Path $GlobalConfigFile) {
        try {
            $config = Get-Content $GlobalConfigFile | ConvertFrom-Json
            return $config
        }
        catch {
            Write-Host "WARNING: Could not read global config: $($_.Exception.Message)" @Yellow
            return $null
        }
    }
    return $null
}

function Initialize-GlobalConfiguration {
    $defaultConfig = @{
        version = "1.0"
        last_updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        default_tenant = "shared"
        last_selection = $null
        usage_stats = @{}
        preferences = @{
            auto_use_last = $false
            show_usage_stats = $true
        }
    }

    try {
        $defaultConfig | ConvertTo-Json -Depth 3 | Set-Content $GlobalConfigFile
        Write-Host "Created global configuration file: $GlobalConfigFile" @Green
        return $defaultConfig
    }
    catch {
        Write-Host "WARNING: Could not create global config: $($_.Exception.Message)" @Yellow
        return $defaultConfig
    }
}

function Update-GlobalConfiguration {
    param($selectedPackage)

    $globalConfig = Get-GlobalConfiguration
    if (-not $globalConfig) {
        $globalConfig = Initialize-GlobalConfiguration
    }

    $packageKey = "$($globalConfig.default_tenant)/$($selectedPackage.framework)/$($selectedPackage.llm)"
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

    # Update last selection
    $globalConfig.last_selection = @{
        tenant = $globalConfig.default_tenant
        framework = $selectedPackage.framework
        llm = $selectedPackage.llm
        description = $selectedPackage.description
        last_used = $timestamp
    }

    # Update usage stats
    if (-not $globalConfig.usage_stats) {
        $globalConfig.usage_stats = @{}
    }

    if ($globalConfig.usage_stats.$packageKey) {
        $globalConfig.usage_stats.$packageKey.count++
        $globalConfig.usage_stats.$packageKey.last_used = $timestamp
    } else {
        $globalConfig.usage_stats.$packageKey = @{
            count = 1
            last_used = $timestamp
        }
    }

    $globalConfig.last_updated = $timestamp

    try {
        $globalConfig | ConvertTo-Json -Depth 3 | Set-Content $GlobalConfigFile
        Write-Host "Updated global configuration" @Green
    }
    catch {
        Write-Host "WARNING: Could not update global config: $($_.Exception.Message)" @Yellow
    }
}

function Get-PackageUsageStats {
    param($packages)

    $globalConfig = Get-GlobalConfiguration
    if (-not $globalConfig -or -not $globalConfig.usage_stats) {
        return $packages
    }

    foreach ($package in $packages) {
        $packageKey = "$($globalConfig.default_tenant)/$($package.framework)/$($package.llm)"
        $stats = $globalConfig.usage_stats.$packageKey

        if ($stats) {
            $package | Add-Member -NotePropertyName "usage_count" -NotePropertyValue $stats.count -Force
            $package | Add-Member -NotePropertyName "last_used" -NotePropertyValue $stats.last_used -Force
        } else {
            $package | Add-Member -NotePropertyName "usage_count" -NotePropertyValue 0 -Force
            $package | Add-Member -NotePropertyName "last_used" -NotePropertyValue $null -Force
        }
    }

    # Sort by usage count (descending), then by framework name
    return $packages | Sort-Object @{Expression="usage_count"; Descending=$true}, framework
}

function Show-LastSelectionPrompt {
    $globalConfig = Get-GlobalConfiguration

    if (-not $globalConfig -or -not $globalConfig.last_selection) {
        return $false
    }

    $lastSelection = $globalConfig.last_selection
    $usageKey = "$($lastSelection.tenant)/$($lastSelection.framework)/$($lastSelection.llm)"
    $usageStats = $globalConfig.usage_stats.$usageKey

    Write-Host ""
    Write-Host "Use the same selection as last time?" @Blue

    if ($usageStats) {
        $usageText = "Used $($usageStats.count) times"
    } else {
        $usageText = "Used 1 time"
    }

    Write-Host "[$($lastSelection.tenant)] $($lastSelection.framework) ($($lastSelection.llm)) - $usageText" @Cyan

    $response = Read-Host "Use this selection? (Y/n)"
    return $response -eq "" -or $response -eq "y" -or $response -eq "Y"
}

# Main execution
function Main {
    Write-Header

    if ($Help) {
        Show-Help
        exit 0
    }

    Test-Dependencies
    Initialize-AppData

    # Check for script updates (unless running from installed location)
    if ($MyInvocation.ScriptName -ne $InstalledScriptPath) {
        if (Test-ScriptUpdate) {
            return  # Script was updated, exit current execution
        }
        Install-ScriptToAppData
    }

    if (-not (Test-Configuration)) {
        # New setup - check for last selection first
        $selectedPackage = $null

        # Try to use last selection
        if (Show-LastSelectionPrompt) {
            $globalConfig = Get-GlobalConfiguration
            $lastSelection = $globalConfig.last_selection

            # Find the package that matches last selection
            $packages = Get-AvailablePackages
            $selectedPackage = $packages | Where-Object {
                $_.framework -eq $lastSelection.framework -and $_.llm -eq $lastSelection.llm
            } | Select-Object -First 1

            if (-not $selectedPackage) {
                Write-Host "WARNING: Last selection no longer available, showing all packages..." @Yellow
            } else {
                Write-Host "Using last selection..." @Green
            }
        }

        # If no last selection or not found, show package selection
        if (-not $selectedPackage) {
            $packages = Get-AvailablePackages
            $selectedPackage = Select-Package $packages
        }

        Write-Host ""
        Write-Host "Selected: $($selectedPackage.framework) ($($selectedPackage.llm))" @Blue

        try {
            $targetDir = Download-Package $selectedPackage
            Save-Configuration $selectedPackage $targetDir
            Update-GlobalConfiguration $selectedPackage

            Write-Host ""
            Write-Host "Setup complete!" @Green
            Write-Host "Framework files: .\$targetDir\" @Yellow
            Write-Host "Tell your LLM: 'Load initialization files from .\$targetDir\'" @Blue
        }
        catch {
            Write-Host "ERROR: Setup failed: $($_.Exception.Message)" @Red
            exit 1
        }
    } else {
        # Existing configuration
        $config = Get-CurrentConfiguration
        if ($config) {
            Write-Host "Current configuration: $($config.framework) ($($config.llm))" @Cyan
            Write-Host "Target directory: $($config.target_dir)" @Yellow
            Write-Host "Use -Force to reconfigure" @Blue
        }
    }

    Write-Host ""
    Write-Host "Ready to code with initai.dev!" @Green
}

# Run main function
Main