# initai.dev PowerShell installer
# Downloads and installs initai.ps1 to AppData

param(
    [string]$BaseUrl = "https://initai.dev"
)

# Configuration
$AppDataPath = "$env:LOCALAPPDATA\initai"
$InitaiScriptPath = "$AppDataPath\initai.ps1"

# Colors for output
$Green = @{ ForegroundColor = "Green" }
$Yellow = @{ ForegroundColor = "Yellow" }
$Blue = @{ ForegroundColor = "Blue" }
$Red = @{ ForegroundColor = "Red" }
$Cyan = @{ ForegroundColor = "Cyan" }

function Write-Header {
    Write-Host "initai.dev - Installer" @Blue
    Write-Host "Installing initai.ps1 to AppData..."
}

function Initialize-AppData {
    if (-not (Test-Path $AppDataPath)) {
        New-Item -ItemType Directory -Path $AppDataPath -Force | Out-Null
        Write-Host "Created directory: $AppDataPath" @Green
    }
}

function Download-InitaiScript {
    Write-Header
    Initialize-AppData

    try {
        $downloadUrl = "$BaseUrl/initai.ps1"

        Write-Host "Downloading from $downloadUrl..." @Yellow
        Invoke-WebRequest -Uri $downloadUrl -OutFile $InitaiScriptPath -UseBasicParsing

        Write-Host "Installed initai.ps1 successfully!" @Green
        Write-Host ""
        Write-Host "=== Installation Complete ===" @Blue
        Write-Host "Script location: $InitaiScriptPath" @Cyan
        Write-Host ""
        Write-Host "To run from anywhere, add this path to your PATH environment variable:" @Yellow
        Write-Host "$AppDataPath" @Cyan
        Write-Host ""
        Write-Host "Usage:" @Blue
        Write-Host "  Run directly: $InitaiScriptPath" @White
        Write-Host "  Or after adding to PATH: initai.ps1" @White
        Write-Host ""

        return $true
    }
    catch {
        Write-Host "ERROR: Failed to download initai.ps1: $($_.Exception.Message)" @Red
        Write-Host "Please check your internet connection and try again." @Yellow
        return $false
    }
}

# Main execution
$null = Download-InitaiScript