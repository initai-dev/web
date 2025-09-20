# initai.dev PowerShell installer
# Initialize LLM frameworks quickly and consistently

param(
    [string]$BaseUrl = "https://initai.dev",
    [switch]$Force,
    [switch]$Help
)

# Configuration
$ConfigFile = ".initai.json"
$InitaiDir = "initai"

# Colors for output
$Red = @{ ForegroundColor = "Red" }
$Green = @{ ForegroundColor = "Green" }
$Yellow = @{ ForegroundColor = "Yellow" }
$Blue = @{ ForegroundColor = "Blue" }
$Cyan = @{ ForegroundColor = "Cyan" }

function Write-Header {
    Write-Host "🚀 initai.dev - LLM Framework Installer" @Blue
    Write-Host "Initializing your development environment..."
}

function Show-Help {
    Write-Host "Usage: .\install.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -BaseUrl URL     Custom base URL (default: https://initai.dev)"
    Write-Host "  -Force           Force reconfiguration"
    Write-Host "  -Help            Show this help"
    Write-Host ""
    Write-Host "Configuration file: $ConfigFile"
}

function Test-Dependencies {
    if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
        Write-Host "❌ curl is required but not found" @Red
        Write-Host "Please install curl or use PowerShell 7+ with built-in curl"
        exit 1
    }
}

function Test-Configuration {
    if ((Test-Path $ConfigFile) -and -not $Force) {
        Write-Host "✅ Found existing configuration" @Green
        return $true
    } else {
        Write-Host "📋 Setting up new configuration..." @Yellow
        return $false
    }
}

function Get-Manifest {
    $manifestUrl = "$BaseUrl/manifest.json"
    Write-Host "📡 Downloading manifest from $manifestUrl..." @Cyan

    try {
        Invoke-WebRequest -Uri $manifestUrl -OutFile ".manifest.json" -UseBasicParsing

        # Verify JSON is valid
        $null = Get-Content ".manifest.json" | ConvertFrom-Json

        Write-Host "✅ Manifest downloaded successfully" @Green
    }
    catch {
        Write-Host "❌ Failed to download manifest from $manifestUrl" @Red
        Write-Host $_.Exception.Message @Red
        exit 1
    }
}

function Select-LLM {
    Write-Host ""
    Write-Host "🤖 Available LLMs:" @Blue

    $manifest = Get-Content ".manifest.json" | ConvertFrom-Json
    $llms = $manifest.llms.PSObject.Properties.Name

    $i = 1
    foreach ($llm in $llms) {
        $llmInfo = $manifest.llms.$llm
        Write-Host "  $i) $($llmInfo.name) - $($llmInfo.description)" @Cyan
        $i++
    }

    do {
        $selection = Read-Host "`nSelect LLM (1-$($llms.Count))"
        $selectionNum = [int]$selection
    } while ($selectionNum -lt 1 -or $selectionNum -gt $llms.Count)

    return $llms[$selectionNum - 1]
}

function Select-Framework {
    param($llm)

    Write-Host ""
    Write-Host "⚡ Available frameworks for $llm:" @Blue

    $manifest = Get-Content ".manifest.json" | ConvertFrom-Json
    $frameworks = $manifest.llms.$llm.frameworks.PSObject.Properties.Name

    $i = 1
    foreach ($fw in $frameworks) {
        $fwInfo = $manifest.llms.$llm.frameworks.$fw
        Write-Host "  $i) $($fwInfo.name) - $($fwInfo.description)" @Cyan
        $i++
    }

    do {
        $selection = Read-Host "`nSelect framework (1-$($frameworks.Count))"
        $selectionNum = [int]$selection
    } while ($selectionNum -lt 1 -or $selectionNum -gt $frameworks.Count)

    return $frameworks[$selectionNum - 1]
}

function Get-FrameworkFiles {
    param($llm, $framework)

    $targetDir = Join-Path $InitaiDir "$llm\$framework"
    Write-Host ""
    Write-Host "📦 Downloading $llm $framework framework files..." @Yellow

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $manifest = Get-Content ".manifest.json" | ConvertFrom-Json
    $files = $manifest.llms.$llm.frameworks.$framework.files

    foreach ($file in $files) {
        $fileUrl = "$BaseUrl/$llm/$framework/$file"
        $targetFile = Join-Path $targetDir $file

        Write-Host "  ↓ Downloading $file..." @Cyan
        try {
            Invoke-WebRequest -Uri $fileUrl -OutFile $targetFile -UseBasicParsing
            Write-Host "    ✅ $file" @Green
        }
        catch {
            Write-Host "    ❌ Failed to download $file" @Red
        }
    }
}

function Save-Configuration {
    param($llm, $framework)

    $manifest = Get-Content ".manifest.json" | ConvertFrom-Json
    $version = $manifest.llms.$llm.frameworks.$framework.version

    $config = @{
        base_url = $BaseUrl
        llm = $llm
        framework = $framework
        version = $version
        last_updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }

    $config | ConvertTo-Json | Set-Content $ConfigFile
    Write-Host "✅ Configuration saved to $ConfigFile" @Green
}

function Get-CurrentConfiguration {
    if (Test-Path $ConfigFile) {
        $config = Get-Content $ConfigFile | ConvertFrom-Json
        return @{
            llm = $config.llm
            framework = $config.framework
        }
    }
    return $null
}

# Main execution
function Main {
    Write-Header

    if ($Help) {
        Show-Help
        exit 0
    }

    Test-Dependencies

    if (-not (Test-Configuration)) {
        # New setup
        Get-Manifest

        $llm = Select-LLM
        $framework = Select-Framework $llm

        Write-Host ""
        Write-Host "🎯 Selected: $llm $framework framework" @Blue

        Get-FrameworkFiles $llm $framework
        Save-Configuration $llm $framework

        Remove-Item ".manifest.json" -ErrorAction SilentlyContinue

        Write-Host ""
        Write-Host "✅ Setup complete!" @Green
        Write-Host "📖 Framework files: .\$InitaiDir\$llm\$framework\" @Yellow
        Write-Host "💡 Tell your LLM: 'Load initialization files from .\$InitaiDir\$llm\$framework\'" @Blue
    } else {
        # Existing configuration
        $config = Get-CurrentConfiguration
        if ($config) {
            Write-Host "Current configuration: $($config.llm) $($config.framework)" @Cyan
            Write-Host "💡 Use -Force to reconfigure" @Blue
        }
    }

    Write-Host ""
    Write-Host "🎉 Ready to code with initai.dev!" @Green
}

# Run main function
Main