# initai.dev PowerShell installer
# Initialize LLM frameworks quickly and consistently

param(
    [string]$BaseUrl = "https://initai.dev",
    [switch]$Force,
    [switch]$Help,
    [switch]$Update,
    [switch]$Clear,
    [switch]$ClearAll,
    [switch]$Verbose,
    [switch]$IgnoreSSLIssues
)

# Configuration
$ConfigFile = ".initai.json"
$InitaiDir = "initai"
$AppDataPath = "$env:LOCALAPPDATA\initai"
$InstalledScriptPath = "$AppDataPath\install.ps1"
$VersionFile = "$AppDataPath\.initai-version"
$GlobalConfigFile = "$env:USERPROFILE\.initai"
$CurrentVersion = "2.1.0"

# Colors for output
$Red = @{ ForegroundColor = "Red" }
$Green = @{ ForegroundColor = "Green" }
$Yellow = @{ ForegroundColor = "Yellow" }
$Blue = @{ ForegroundColor = "Blue" }
$Cyan = @{ ForegroundColor = "Cyan" }
$LightCyan = @{ ForegroundColor = "Cyan"; Bold = $true }
$Gray = @{ ForegroundColor = "DarkGray" }
$White = @{ ForegroundColor = "White" }

function Write-Header {
    Write-Host "initai.dev - LLM Framework Manager " @LightCyan -NoNewline
    Write-Host "v$CurrentVersion" @Gray
    Write-Host "Initializing your development environment..." @Gray
}

function Write-VerboseMessage {
    param([string]$Message, [hashtable]$Color = @{})
    if ($Verbose) {
        if ($Color.Count -gt 0) {
            Write-Host $Message @Color
        } else {
            Write-Host $Message
        }
    }
}

function Invoke-HttpRequest {
    param(
        [string]$Uri,
        [string]$OutFile = $null,
        [switch]$UseRestMethod
    )

    $params = @{
        Uri = $Uri
        UseBasicParsing = $true
    }

    if ($OutFile) {
        $params.OutFile = $OutFile
    }

    if ($IgnoreSSLIssues) {
        # Temporarily disable SSL certificate validation
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        $params.SkipCertificateCheck = $true
    }

    try {
        if ($UseRestMethod) {
            return Invoke-RestMethod @params
        } else {
            return Invoke-WebRequest @params
        }
    }
    finally {
        if ($IgnoreSSLIssues) {
            # Re-enable SSL certificate validation
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
        }
    }
}

function Show-Help {
    Write-Host "Usage: .\initai.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -BaseUrl URL     Custom base URL (default: https://initai.dev)"
    Write-Host "  -Force           Force reconfiguration"
    Write-Host "  -Update          Force check for script updates"
    Write-Host "  -Clear           Remove initai folder and downloaded packages"
    Write-Host "  -ClearAll        Remove initai folder AND local .initai.json config"
    Write-Host "  -Verbose         Show detailed progress messages"
    Write-Host "  -IgnoreSSLIssues Skip SSL certificate verification"
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
    Write-VerboseMessage "Checking for script updates..." @Cyan

    try {
        $updateUrl = "$BaseUrl/api/check-updates?client_version=$CurrentVersion&script=powershell"
        $response = Invoke-HttpRequest -Uri $updateUrl -UseRestMethod

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
        Write-VerboseMessage "WARNING: Could not check for updates: $($_.Exception.Message)" @Yellow
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

    Write-VerboseMessage "Downloading script update..." @Yellow

    try {
        # Download new initai.ps1 script
        $downloadUrl = "$BaseUrl/initai.ps1"
        $currentScript = $MyInvocation.ScriptName
        $tempScript = "$currentScript.new"

        Invoke-HttpRequest -Uri $downloadUrl -OutFile $tempScript

        # Backup current script
        if (Test-Path $currentScript) {
            Copy-Item $currentScript "$currentScript.backup" -Force
        }

        # Replace current script
        Move-Item $tempScript $currentScript -Force

        Write-Host "Script updated to v$($updateInfo.current_version)" @Green
        Write-Host ""
        Write-Host "Please restart initai.ps1 to use the new version:" @Blue
        Write-Host "  .\initai.ps1" @Yellow
        Write-Host ""

        exit 0
    }
    catch {
        Write-Host "ERROR: Failed to update script: $($_.Exception.Message)" @Red
        if (Test-Path "$currentScript.backup") {
            Move-Item "$currentScript.backup" $currentScript -Force
            Write-Host "Restored backup script" @Yellow
        }
        throw
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
        Write-VerboseMessage "Found existing configuration" @Green
        return $true
    } else {
        Write-Host "Setting up new configuration..." @Yellow
        return $false
    }
}

function Get-AvailablePackages {
    $packagesUrl = "$BaseUrl/init/shared/list"
    Write-VerboseMessage "Getting available frameworks from $packagesUrl..." @Cyan

    try {
        $response = Invoke-HttpRequest -Uri $packagesUrl -UseRestMethod
        Write-VerboseMessage "Found $($response.frameworks.Count) available frameworks" @Green
        return $response.frameworks
    }
    catch {
        Write-Host "ERROR: Failed to get frameworks from $packagesUrl" @Red
        Write-Host $_.Exception.Message @Red
        exit 1
    }
}

function Select-Framework {
    param($frameworks)

    if ($frameworks.Count -eq 0) {
        Write-Host "ERROR: No frameworks available" @Red
        exit 1
    }

    Write-Host ""
    Write-Host "Which framework would you like to use?" @Blue

    for ($i = 0; $i -lt $frameworks.Count; $i++) {
        $framework = $frameworks[$i]
        Write-Host "  $($i + 1)) $($framework.name)" @Cyan
        Write-Host "     $($framework.description)"
    }

    do {
        $selection = Read-Host "`nSelect framework (1-$($frameworks.Count))"
        $selectionNum = [int]$selection
    } while ($selectionNum -lt 1 -or $selectionNum -gt $frameworks.Count)

    return $frameworks[$selectionNum - 1].name
}

function Select-Scope {
    param($frameworks, $selectedFramework)

    # Find the selected framework
    $framework = $frameworks | Where-Object { $_.name -eq $selectedFramework }
    if (-not $framework) {
        Write-Host "ERROR: Framework '$selectedFramework' not found" @Red
        exit 1
    }

    $scopes = $framework.scopes
    if ($scopes.Count -eq 0) {
        Write-Host "ERROR: No scopes available for $selectedFramework" @Red
        exit 1
    }

    Write-Host ""
    Write-Host "Which development scope for $selectedFramework?" @Blue

    for ($i = 0; $i -lt $scopes.Count; $i++) {
        $scope = $scopes[$i]
        switch ($scope.name) {
            "backend" { Write-Host "  $($i + 1)) Backend - Server-side development, APIs, databases" @Cyan }
            "frontend" { Write-Host "  $($i + 1)) Frontend - Client-side development, UI/UX" @Cyan }
            "fullstack" { Write-Host "  $($i + 1)) Fullstack - Complete application development" @Cyan }
            default { Write-Host "  $($i + 1)) $($scope.name) - $($scope.description)" @Cyan }
        }
    }

    do {
        $selection = Read-Host "`nSelect scope (1-$($scopes.Count))"
        $selectionNum = [int]$selection
    } while ($selectionNum -lt 1 -or $selectionNum -gt $scopes.Count)

    return $scopes[$selectionNum - 1].name
}

function Select-LLM {
    param($frameworks, $selectedFramework, $selectedScope)

    # Find the selected framework and scope
    $framework = $frameworks | Where-Object { $_.name -eq $selectedFramework }
    if (-not $framework) {
        Write-Host "ERROR: Framework '$selectedFramework' not found" @Red
        exit 1
    }

    $scope = $framework.scopes | Where-Object { $_.name -eq $selectedScope }
    if (-not $scope) {
        Write-Host "ERROR: Scope '$selectedScope' not found for $selectedFramework" @Red
        exit 1
    }

    $variants = $scope.variants
    if ($variants.Count -eq 0) {
        Write-Host "ERROR: No LLM variants available for $selectedFramework/$selectedScope" @Red
        exit 1
    }

    Write-Host ""
    Write-Host "Which LLM will you use with $selectedFramework ($selectedScope)?" @Blue

    for ($i = 0; $i -lt $variants.Count; $i++) {
        $variant = $variants[$i]
        switch ($variant.name) {
            "claude" { Write-Host "  $($i + 1)) Claude (Anthropic) - $($variant.description)" @Cyan }
            "gemini" { Write-Host "  $($i + 1)) Gemini (Google) - $($variant.description)" @Cyan }
            "universal" { Write-Host "  $($i + 1)) Universal - $($variant.description)" @Cyan }
            default { Write-Host "  $($i + 1)) $($variant.name) - $($variant.description)" @Cyan }
        }
    }

    do {
        $selection = Read-Host "`nSelect LLM (1-$($variants.Count))"
        $selectionNum = [int]$selection
    } while ($selectionNum -lt 1 -or $selectionNum -gt $variants.Count)

    return $variants[$selectionNum - 1].name
}

function Find-DownloadUrl {
    param($frameworks, $selectedFramework, $selectedScope, $selectedLLM)

    # Find the selected framework and scope
    $framework = $frameworks | Where-Object { $_.name -eq $selectedFramework }
    if (-not $framework) {
        Write-Host "ERROR: Framework '$selectedFramework' not found" @Red
        exit 1
    }

    $scope = $framework.scopes | Where-Object { $_.name -eq $selectedScope }
    if (-not $scope) {
        Write-Host "ERROR: Scope '$selectedScope' not found for $selectedFramework" @Red
        exit 1
    }

    $variant = $scope.variants | Where-Object { $_.name -eq $selectedLLM }
    if (-not $variant) {
        Write-Host "ERROR: LLM variant '$selectedLLM' not found for $selectedFramework/$selectedScope" @Red
        exit 1
    }

    return $variant.download_url
}

function Download-Package {
    param($framework, $scope, $llm, $downloadUrl)

    $targetDir = Join-Path $InitaiDir "$framework-$scope-$llm"
    Write-Host ""
    Write-VerboseMessage "Downloading $framework ($scope) package for $llm..." @Yellow

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    try {
        $fullDownloadUrl = "$BaseUrl$downloadUrl"
        $zipFile = "$targetDir\package.zip"

        Write-VerboseMessage "  Downloading from $fullDownloadUrl..." @Cyan
        Invoke-HttpRequest -Uri $fullDownloadUrl -OutFile $zipFile

        Write-VerboseMessage "  Extracting package..." @Cyan
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
    param($framework, $scope, $llm, $targetDir)

    $downloadUrl = "/init/shared/$framework/$scope"
    if ($llm -ne "universal") {
        $downloadUrl += "/$llm"
    }

    $config = @{
        base_url = $BaseUrl
        framework = $framework
        scope = $scope
        llm = $llm
        description = "$framework $scope development for $llm"
        download_url = $downloadUrl
        target_dir = $targetDir
        last_updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        script_version = $CurrentVersion
    }

    $config | ConvertTo-Json | Set-Content $ConfigFile
    Write-Host "Configuration saved to $ConfigFile" @Green
}

function Generate-LLMInstructions {
    param($preferredLLM, $framework, $scope, $targetDir)

    $llmFile = ""
    $content = ""

    switch ($preferredLLM) {
        "claude" {
            $llmFile = "CLAUDE.md"
            $content = @"
# Claude Instructions for $framework ($scope)

## Project Context Management
- **Always save project context and notes to PROJECT.md**
- CLAUDE.md contains only initialization instructions (don't modify)
- Use PROJECT.md for ongoing project documentation, decisions, and context
- Load PROJECT.md content at start of each session to continue where you left off

## Communication Style
- Use bullet points for all responses
- Be concise and direct
- Focus on actionable information

## Project Setup
- Framework: $framework
- Scope: $scope
- LLM specialization: $preferredLLM
- Initialization files: $targetDir

## Instructions
Please read and follow the initialization files in $targetDir on every session start:

- Load the framework configuration
- Apply the coding standards and patterns
- Use the provided templates and conventions
- **Load PROJECT.md to understand current project state**

## File Structure
- CLAUDE.md - Initialization instructions (static - don't modify)
- PROJECT.md - Your working context (dynamic - update regularly)
- $targetDir/ - Framework files and templates

## Key Guidelines
- Always use bullet format for responses
- Prioritize developer productivity
- Follow the framework's best practices
- Maintain consistency across the project
- **Save all project decisions and context to PROJECT.md**

---
Generated by initai.dev on $(Get-Date -Format "yyyy-MM-dd")
"@
        }
        "gemini" {
            $llmFile = "GEMINI.md"
            $content = @"
# Gemini Instructions for $framework ($scope)

## Communication Style
- Use bullet points for all responses
- Provide detailed explanations when needed
- Focus on research and analysis

## Project Setup
- Framework: $framework
- Scope: $scope
- LLM specialization: $preferredLLM
- Initialization files: $targetDir

## Instructions
Please read and follow the initialization files in $targetDir on every session start:

- Load the framework configuration
- Apply the coding standards and patterns
- Use the provided templates and conventions

## Key Guidelines
- Always use bullet format for responses
- Leverage analytical capabilities for complex problems
- Follow the framework's best practices
- Provide comprehensive documentation

---
Generated by initai.dev on $(Get-Date -Format "yyyy-MM-dd")
"@
        }
        "universal" {
            $llmFile = "LLM_INSTRUCTIONS.md"
            $content = @"
# LLM Instructions for $framework ($scope)

## Communication Style
- Use bullet points for all responses
- Adapt to the specific LLM being used
- Focus on clear, actionable guidance

## Project Setup
- Framework: $framework
- Scope: $scope
- LLM specialization: $preferredLLM
- Initialization files: $targetDir

## Instructions
Please read and follow the initialization files in $targetDir on every session start:

- Load the framework configuration
- Apply the coding standards and patterns
- Use the provided templates and conventions

## Key Guidelines
- Always use bullet format for responses
- Work with any LLM provider
- Follow the framework's best practices
- Maintain consistency across the project

---
Generated by initai.dev on $(Get-Date -Format "yyyy-MM-dd")
"@
        }
    }

    if ($content) {
        # Check if LLM instruction file already exists
        if (Test-Path $llmFile) {
            Write-Host ""
            $overwrite = Read-Host "$llmFile už existuje. Přepsat? (y/n)"
            if ($overwrite -notmatch "^[yY]$") {
                Write-Host "Ponecháván stávající $llmFile" @Cyan
                Write-Host ""
                Write-Host "UPOZORNĚNÍ: Ujistěte se, že váš $llmFile obsahuje instrukci:" @Yellow
                Write-Host "`"Please read and follow the initialization files in $targetDir on every session start`"" @Blue
                Write-Host ""
                return
            }
        }

        try {
            $content | Set-Content $llmFile -Encoding UTF8
            Write-Host "Created $llmFile with project instructions" @Green
        }
        catch {
            Write-Host "WARNING: Could not create ${llmFile}: $($_.Exception.Message)" @Yellow
        }
    }
}

function Show-PackageInstructions {
    param($targetDir)

    $initFile = Join-Path $targetDir "init.md"
    if (Test-Path $initFile) {
        Write-Host ""
        Write-Host "=== Package Instructions ===" @Blue
        $content = Get-Content $initFile | Select-Object -First 10
        foreach ($line in $content) {
            Write-Host $line @White
        }
        if ((Get-Content $initFile).Count -gt 10) {
            Write-Host "... (see $initFile for full instructions)" @Yellow
        }
        Write-Host "===========================" @Blue
    }
}

function Clear-InitaiFolder {
    Write-Host "Cleaning up initai folder..." @Yellow

    if (Test-Path $InitaiDir) {
        try {
            Remove-Item $InitaiDir -Recurse -Force
            Write-Host "Removed initai folder: $InitaiDir" @Green
        }
        catch {
            Write-Host "WARNING: Could not remove initai folder: $($_.Exception.Message)" @Yellow
        }
    } else {
        Write-Host "No initai folder found to remove" @Cyan
    }

    # Also remove LLM instruction files
    $llmFiles = @("CLAUDE.md", "GEMINI.md", "LLM_INSTRUCTIONS.md")
    foreach ($file in $llmFiles) {
        if (Test-Path $file) {
            try {
                Remove-Item $file -Force
                Write-Host "Removed LLM instruction file: $file" @Green
            }
            catch {
                Write-Host "WARNING: Could not remove ${file}: $($_.Exception.Message)" @Yellow
            }
        }
    }
}

function Clear-AllLocalFiles {
    Write-Host "Cleaning up all local initai files..." @Yellow

    # Remove initai folder and LLM files
    Clear-InitaiFolder

    # Remove local configuration
    if (Test-Path $ConfigFile) {
        try {
            Remove-Item $ConfigFile -Force
            Write-Host "Removed local configuration: $ConfigFile" @Green
        }
        catch {
            Write-Host "WARNING: Could not remove ${ConfigFile}: $($_.Exception.Message)" @Yellow
        }
    } else {
        Write-Host "No local configuration found to remove" @Cyan
    }

    Write-Host ""
    Write-Host "Local cleanup complete!" @Green
    Write-Host "Note: Global user preferences in $GlobalConfigFile are preserved" @Blue
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

    # Update usage stats - ensure it's a hashtable, not PSObject
    if (-not $globalConfig.usage_stats) {
        $globalConfig.usage_stats = @{}
    } elseif ($globalConfig.usage_stats.GetType().Name -eq "PSCustomObject") {
        # Convert PSCustomObject to hashtable
        $newUsageStats = @{}
        $globalConfig.usage_stats.PSObject.Properties | ForEach-Object {
            $newUsageStats[$_.Name] = $_.Value
        }
        $globalConfig.usage_stats = $newUsageStats
    }

    if ($globalConfig.usage_stats.ContainsKey($packageKey)) {
        $globalConfig.usage_stats[$packageKey].count++
        $globalConfig.usage_stats[$packageKey].last_used = $timestamp
    } else {
        $globalConfig.usage_stats[$packageKey] = @{
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

        # Handle both hashtable and PSObject cases
        if ($globalConfig.usage_stats.GetType().Name -eq "PSCustomObject") {
            $stats = $globalConfig.usage_stats.PSObject.Properties | Where-Object { $_.Name -eq $packageKey } | Select-Object -ExpandProperty Value
        } else {
            $stats = $globalConfig.usage_stats[$packageKey]
        }

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

    # Handle both hashtable and PSObject cases
    if ($globalConfig.usage_stats.GetType().Name -eq "PSCustomObject") {
        $usageStats = $globalConfig.usage_stats.PSObject.Properties | Where-Object { $_.Name -eq $usageKey } | Select-Object -ExpandProperty Value
    } else {
        $usageStats = $globalConfig.usage_stats[$usageKey]
    }

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

function Test-PackageUpdate {
    param($config)

    if (-not $config) {
        return $false
    }

    Write-VerboseMessage "Checking for package updates..." @Cyan

    try {
        # Build package URL
        $packageUrl = "$BaseUrl/init/shared/$($config.framework)/$($config.scope)"
        if ($config.llm -ne "universal") {
            $packageUrl += "/$($config.llm)"
        }

        $response = Invoke-RestMethod -Uri $packageUrl -UseBasicParsing -Method HEAD

        # Check if package has been updated (simple approach for now)
        # TODO: Add proper version checking when packages have version metadata
        Write-VerboseMessage "Package check completed" @Green
        return $false  # For now, don't auto-update packages
    }
    catch {
        Write-VerboseMessage "Could not check for package updates: $($_.Exception.Message)" @Yellow
        return $false
    }
}

# Main execution
function Main {
    Write-Header

    if ($Help) {
        Show-Help
        exit 0
    }

    # Handle clear operations
    if ($Clear) {
        Clear-InitaiFolder
        exit 0
    }

    if ($ClearAll) {
        Clear-AllLocalFiles
        exit 0
    }

    Test-Dependencies

    # Always check for script updates
    if (Test-ScriptUpdate) {
        return  # Script was updated, exit current execution
    }

    if (-not (Test-Configuration)) {
        # New setup - ask for framework, scope, then LLM
        $frameworks = Get-AvailablePackages

        $selectedFramework = Select-Framework $frameworks
        $selectedScope = Select-Scope $frameworks $selectedFramework
        $selectedLLM = Select-LLM $frameworks $selectedFramework $selectedScope
        $downloadUrl = Find-DownloadUrl $frameworks $selectedFramework $selectedScope $selectedLLM

        Write-Host ""
        Write-Host "Selected: $selectedFramework ($selectedScope) for $selectedLLM" @Blue

        try {
            $targetDir = Download-Package $selectedFramework $selectedScope $selectedLLM $downloadUrl
            Save-Configuration $selectedFramework $selectedScope $selectedLLM $targetDir
            Generate-LLMInstructions $selectedLLM $selectedFramework $selectedScope $targetDir
            Show-PackageInstructions $targetDir

            Write-Host ""
            Write-Host "Setup complete!" @Green
            Write-Host "Framework files: .\$targetDir\" @Yellow
            Write-Host "LLM instructions: .\CLAUDE.md (or .\GEMINI.md)" @Yellow
            Write-Host "Tell your LLM: 'Load the initialization files and follow the project instructions'" @Blue

            # Ask if user wants to launch Claude (only if Claude was selected)
            if ($selectedLLM -eq "claude") {
                Write-Host ""
                $launchClaude = Read-Host "Spustit Claude? (y/n)"
                if ($launchClaude -match "^[yY]$") {
                    # Save preference and launch Claude
                    "launch_claude=true" | Add-Content ".initai"
                    try {
                        if (Get-Command claude-code -ErrorAction SilentlyContinue) {
                            Write-Host "Spouštím Claude Code..." @Cyan
                            & claude-code
                        }
                        elseif (Get-Command claude -ErrorAction SilentlyContinue) {
                            Write-Host "Spouštím Claude CLI..." @Cyan
                            & claude
                        }
                        else {
                            Write-Host "Claude CLI nebyl nalezen. Prosím nainstalujte Claude Code CLI:" @Yellow
                            Write-Host "https://claude.ai/code" @White
                        }
                    }
                    catch {
                        Write-Host "Nepodařilo se spustit Claude CLI: $($_.Exception.Message)" @Yellow
                        Write-Host "Prosím navštivte: https://claude.ai/code" @White
                    }
                }
                else {
                    "launch_claude=false" | Add-Content ".initai"
                }
            }
        }
        catch {
            Write-Host "ERROR: Setup failed: $($_.Exception.Message)" @Red
            exit 1
        }
    } else {
        # Existing configuration - check for updates and show package instructions
        $config = Get-CurrentConfiguration
        if ($config) {
            Write-Host "Current configuration: $($config.framework) ($($config.scope)) for $($config.llm)" @Cyan
            Write-Host "Target directory: $($config.target_dir)" @Yellow

            # Check for package updates
            $null = Test-PackageUpdate $config

            # Show package instructions on every run
            Show-PackageInstructions $config.target_dir

            Write-Host "Use -Force to reconfigure" @Blue
        }
    }
}

# Run main function
Main