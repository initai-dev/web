# How It Works

Complete guide to understanding our LLM initialization system and automated setup process.

## Overview

Our initialization scripts provide a fully automated approach to LLM setup that eliminates manual configuration, ensures consistency across environments, and gets you productive in seconds rather than hours.

## The 3-Step Process

### Step 1: Choose Your Stack
```bash
# Example: Initialize with interactive selection
./install.sh --interactive

# Select your provider:
# [1] Claude (Anthropic)
# [2] Gemini (Google)
#
# Select your framework:
# [1] Bliss Framework (recommended)
# [2] Custom setup
```

Our detection system automatically identifies:
- **Operating System**: Linux, macOS, Windows
- **Package Manager**: npm, pip, conda, apt, brew, etc.
- **Development Environment**: VS Code, PyCharm, Vim, etc.
- **Existing Dependencies**: Python version, Node.js, etc.

### Step 2: Automated Installation
```bash
# The script handles everything automatically:
# ✓ Install required dependencies
# ✓ Set up environment variables
# ✓ Configure API endpoints
# ✓ Install framework-specific packages
# ✓ Setup development tools integration
# ✓ Create sample configurations
```

**What happens during installation:**
1. **Dependency Resolution** - Checks and installs required packages
2. **Environment Setup** - Creates `.env` files with secure defaults
3. **Framework Integration** - Downloads and configures your chosen framework
4. **IDE Configuration** - Sets up syntax highlighting, autocomplete
5. **Validation** - Tests connection and functionality

### Step 3: Start Building
```bash
# Immediately ready to use:
claude "Generate a hello world API"
gemini "Create a data analysis script"

# Or using framework directly:
python -m bliss.generate --type api --name hello-world
```

## Platform-Specific Installation

### Linux / macOS
```bash
# One-line installation
curl -sSL https://initai.dev/install.sh | bash

# Or with options
curl -sSL https://initai.dev/install.sh | bash -s -- --provider claude --framework bliss
```

### Windows PowerShell
```powershell
# One-line installation
iwr -useb https://initai.dev/install.ps1 | iex

# Or with options
iwr -useb https://initai.dev/install.ps1 | iex; Install-LLM -Provider Gemini -Framework BlissFramework
```

### Python (Cross-platform)
```bash
# Universal installer
curl -sSL https://initai.dev/install.py | python3

# With virtual environment
python3 -m venv llm-env && source llm-env/bin/activate
curl -sSL https://initai.dev/install.py | python3 --venv
```

## Advanced Configuration

### Custom Environment Setup
```bash
# Enterprise configuration
./install.sh --config enterprise \
            --proxy http://proxy.company.com:8080 \
            --cert /path/to/company.crt \
            --no-telemetry

# Development team setup
./install.sh --team-config \
            --shared-templates /shared/templates \
            --git-hooks \
            --pre-commit-checks
```

### Framework-Specific Options
```bash
# Bliss Framework with extensions
./install.sh --provider claude \
            --framework bliss \
            --enable-extensions \
            --install-models local

# Bliss Framework with enhanced features
./install.sh --provider gemini \
            --framework bliss \
            --enable-multimodal \
            --optimize-performance
```

## Supported Platforms & Requirements

### System Requirements
- **Operating System**: Linux (Ubuntu 18+), macOS (10.15+), Windows (10+)
- **Memory**: Minimum 4GB RAM (8GB+ recommended)
- **Storage**: 2GB free space for full installation
- **Network**: Internet connection for initial setup

### Supported Languages & Frameworks
- **Python**: 3.8+ (with pip, conda)
- **Node.js**: 16+ (with npm, yarn)
- **Go**: 1.19+ (experimental)
- **Rust**: 1.65+ (experimental)

## Security & Enterprise Features

### Built-in Security
```bash
# Secure by default configuration
✓ API keys stored in encrypted keyring
✓ Environment variables properly scoped
✓ Network requests use TLS 1.3
✓ No telemetry without explicit consent
✓ Local model caching encrypted
```

### Enterprise Integration
- **SSO Support**: SAML, OAuth2, LDAP
- **Proxy Configuration**: Corporate firewall compatibility
- **Audit Logging**: Full installation and usage tracking
- **Compliance**: SOC2, GDPR, HIPAA ready configurations

## Troubleshooting

### Common Issues

**Installation fails with permission error**
```bash
# Fix permissions
sudo chown -R $USER:$USER ~/.local/share/initai
chmod +x ~/.local/bin/claude

# Or install to user directory
./install.sh --user-install
```

**API connection timeouts**
```bash
# Test connectivity
curl -I https://api.anthropic.com/health
curl -I https://generativelanguage.googleapis.com/health

# Configure proxy if needed
export HTTPS_PROXY=http://proxy.company.com:8080
./install.sh --use-proxy
```

**Framework conflicts with existing installation**
```bash
# Clean installation
./install.sh --clean --force

# Install in isolated environment
./install.sh --isolated --prefix /opt/llm-tools
```

### Advanced Debugging
```bash
# Enable verbose logging
export INITAI_DEBUG=1
./install.sh --verbose

# Check installation logs
tail -f ~/.local/share/initai/logs/install.log

# Validate configuration
initai doctor --full-check
```

## Next Steps

After successful installation:

1. **[Configure Claude](/claude/installation)** - Set up Anthropic Claude
2. **[Configure Gemini](/gemini/installation)** - Set up Google Gemini
3. **[Explore Examples](/content/getting-started)** - Practical usage examples
4. **[Framework Guides](/content/model-configuration)** - Deep dive into configurations

## Performance Benchmarks

Our installation process is optimized for speed:
- **Average installation time**: 15-30 seconds
- **Network usage**: 50-150MB depending on selection
- **First API call**: <2 seconds after installation
- **Framework loading**: <500ms for most operations