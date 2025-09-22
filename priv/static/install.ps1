# InitAI.dev - PowerShell Bootstrap Installer
# Downloads and sets up the main InitAI script with PATH management

param(
    [string]$BaseUrl = "https://initai.dev",
    [switch]$Force,
    [switch]$Verbose
)

# Configuration
$AppDataPath = "$env:LOCALAPPDATA\initai"
$MainScriptPath = "$AppDataPath\initai.ps1"
$MainScriptUrl = "$BaseUrl/initai.ps1"

# Colors for output
$Red = @{ ForegroundColor = "Red" }
$Green = @{ ForegroundColor = "Green" }
$Yellow = @{ ForegroundColor = "Yellow" }
$Blue = @{ ForegroundColor = "Blue" }
$Cyan = @{ ForegroundColor = "Cyan" }
$Gray = @{ ForegroundColor = "DarkGray" }

function Write-Header {
    Write-Host "initai.dev Bootstrap Installer" @Cyan
    Write-Host "Setting up LLM Framework Manager..." @Gray
    Write-Host ""
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

function Test-PathContains {
    param([string]$PathToCheck)

    $currentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
    if (-not $currentPath) {
        return $false
    }

    # Split PATH and check each entry
    $pathEntries = $currentPath -split ';'
    foreach ($entry in $pathEntries) {
        if ($entry.Trim() -eq $PathToCheck.Trim()) {
            return $true
        }
    }
    return $false
}

function Add-ToUserPath {
    param([string]$PathToAdd)

    if (Test-PathContains $PathToAdd) {
        Write-VerboseMessage "PATH already contains: $PathToAdd" @Green
        return $true
    }

    try {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
        $newPath = if ($currentPath) { "$currentPath;$PathToAdd" } else { $PathToAdd }

        [Environment]::SetEnvironmentVariable("PATH", $newPath, [EnvironmentVariableTarget]::User)
        Write-Host "[OK] Added to PATH: $PathToAdd" @Green
        Write-Host "  PATH changes will take effect in new console sessions" @Gray
        return $true
    }
    catch {
        Write-Host "ERROR: Failed to add to PATH: $($_.Exception.Message)" @Red
        return $false
    }
}

function Install-InitaiScript {
    try {
        # Create AppData directory if it doesn't exist
        if (-not (Test-Path $AppDataPath)) {
            New-Item -ItemType Directory -Path $AppDataPath -Force | Out-Null
            Write-Host "[OK] Created directory: $AppDataPath" @Green
        }

        # Download main script
        Write-Host "Downloading initai.dev script..." @Blue
        Write-VerboseMessage "From: $MainScriptUrl" @Gray
        Write-VerboseMessage "To: $MainScriptPath" @Gray

        Invoke-WebRequest -Uri $MainScriptUrl -OutFile $MainScriptPath -UseBasicParsing
        Write-Host "[OK] Downloaded initai.dev script" @Green

        return $true
    }
    catch {
        Write-Host "ERROR: Failed to download initai.dev script: $($_.Exception.Message)" @Red
        return $false
    }
}

function Prompt-AddToPath {
    if (Test-PathContains $AppDataPath) {
        Write-Host "[OK] initai.dev is already in your PATH" @Green
        return "already_in_path"
    }

    Write-Host ""
    Write-Host "Add initai.dev to your PATH for global access?" @Blue
    Write-Host "This will add the following directory to your user PATH:" @Gray
    Write-Host "  $AppDataPath" @Yellow
    Write-Host ""
    Write-Host "Benefits:" @Gray
    Write-Host "  * Run 'initai' from any directory" @Gray
    Write-Host "  * Access initai.dev tools globally" @Gray
    Write-Host "  * Consistent development environment" @Gray
    Write-Host ""

    $response = Read-Host "Add to PATH? (Y/n)"
    if ($response -eq "" -or $response -match "^[yY]$") {
        if (Add-ToUserPath $AppDataPath) {
            return "added_to_path"
        } else {
            return "failed_to_add"
        }
    } else {
        Write-Host "Skipped adding to PATH" @Gray
        Write-Host "You can run initai.dev with: $MainScriptPath" @Yellow
        return "skipped"
    }
}

function Test-InitaiInstalled {
    return (Test-Path $MainScriptPath)
}

# Main installation logic
function Main {
    Write-Header

    # Check if already installed and not forced
    if ((Test-InitaiInstalled) -and (-not $Force)) {
        Write-Host "initai.dev is already installed at: $MainScriptPath" @Yellow

        # Still check/offer PATH setup
        if (-not (Test-PathContains $AppDataPath)) {
            $pathResult = Prompt-AddToPath
            if ($pathResult -eq "added_to_path") {
                Write-Host "(Restart your console for PATH changes to take effect)" @Gray
            }
        } else {
            Write-Host "[OK] initai.dev is in your PATH" @Green
        }

        Write-Host ""
        Write-Host "Running initai.dev..." @Blue

        # Execute the main script with any remaining arguments plus BaseUrl
        $remainingArgs = $args | Where-Object { $_ -notmatch "^-(?:BaseUrl|Force|Verbose)$" }
        & $MainScriptPath -BaseUrl $BaseUrl @remainingArgs
        return
    }

    # Install the main script
    if (-not (Install-InitaiScript)) {
        exit 1
    }

    # Prompt for PATH setup
    $pathResult = Prompt-AddToPath

    Write-Host ""
    Write-Host "[OK] initai.dev installation complete!" @Green

    switch ($pathResult) {
        "already_in_path" {
            Write-Host "You can now run 'initai' from any directory" @Cyan
        }
        "added_to_path" {
            Write-Host "You can now run 'initai' from any directory" @Cyan
            Write-Host "(Restart your console for PATH changes to take effect)" @Gray
        }
        "skipped" {
            Write-Host "To run initai.dev, use: $MainScriptPath" @Yellow
        }
        "failed_to_add" {
            Write-Host "To run initai.dev, use: $MainScriptPath" @Yellow
            Write-Host "PATH setup failed - you can add manually: $AppDataPath" @Gray
        }
    }

    Write-Host ""
    Write-Host "Starting initai.dev for initial setup..." @Blue

    # Run the main script for initial configuration
    & $MainScriptPath -BaseUrl $BaseUrl
}

# Execute main function
Main @args