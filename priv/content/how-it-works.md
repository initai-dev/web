# How It Works

Complete guide to understanding our three-tier LLM initialization system and automated setup process.

## Overview

Our initialization scripts provide a fully automated approach to LLM setup that eliminates manual configuration, ensures consistency across environments, and gets you productive in seconds rather than hours.

The system uses an intelligent **three-tier architecture** that allows precise selection of your development stack:

**Framework → Scope → LLM Specialization**

## Three-Tier Architecture

### The Structure

```
Framework (e.g., blissframework)
├── Backend Scope
│   ├── Universal (works with any LLM)
│   ├── Claude (optimized for Claude)
│   └── Gemini (optimized for Gemini)
├── Frontend Scope
│   ├── Universal
│   ├── Claude
│   └── Gemini
└── Fullstack Scope
    ├── Universal
    ├── Claude
    └── Gemini
```

### Tier 1: Framework Selection
Choose your development framework that defines the overall architecture and tooling approach:
- **Bliss Framework** - Enhanced productivity framework with LLM-optimized patterns
- Additional frameworks can be added as the ecosystem grows

### Tier 2: Scope Selection
Define what part of the application stack you're working on:
- **Backend** - Server-side development, APIs, databases, microservices
- **Frontend** - Client-side development, UI/UX, user interfaces
- **Fullstack** - Complete application development combining both

### Tier 3: LLM Specialization
Choose your AI model optimization level:
- **Universal** - Works with any LLM (Claude, Gemini, GPT, etc.) with generic optimizations
- **Claude** - Specifically optimized for Anthropic's Claude with specialized prompts and workflows
- **Gemini** - Specifically optimized for Google's Gemini with tailored configurations

## The 3-Step Process

### Step 1: Three-Tier Selection
```bash
# Interactive three-tier selection process
curl -sSL https://initai.dev/install.sh | bash

# Step 1: Framework Selection
# Which framework would you like to use?
#   1) blissframework
#      Framework for enhanced development productivity

# Step 2: Scope Selection
# Which development scope for blissframework?
#   1) Backend - Server-side development, APIs, databases
#   2) Frontend - Client-side development, UI/UX

# Step 3: LLM Specialization
# Which LLM will you use with blissframework (backend)?
#   1) Universal - Works with any LLM
#   2) Claude (Anthropic) - Optimized for Claude AI
#   3) Gemini (Google) - Optimized for Gemini AI
```

### Why Three Tiers?

**Framework Level** - Defines your development approach and tooling philosophy
**Scope Level** - Tailors the setup for your specific development focus
**LLM Level** - Optimizes configurations for your chosen AI model

This granular selection ensures you get exactly the right setup for your project without unnecessary bloat.

### Step 2: Package Download & Setup
```bash
# Selected: blissframework (backend) for Claude
# Package downloaded and extracted to: initai/blissframework-backend-claude
# Configuration saved to .initai.json
# Created CLAUDE.md with project instructions

# The script handles everything automatically:
# ✓ Download framework-specific package (ZIP format)
# ✓ Extract to organized directory structure
# ✓ Generate CLAUDE.md with tailored instructions
# ✓ Protect existing CLAUDE.md files from overwriting
# ✓ Save user preferences for future use
# ✓ Optional Claude Code launch integration
```

**What happens during installation:**
1. **Package Selection** - Retrieves the exact package for your framework/scope/LLM combination
2. **Directory Creation** - Sets up organized project structure
3. **File Protection** - Warns before overwriting existing CLAUDE.md customizations
4. **Context Setup** - Creates instructions for static (CLAUDE.md) vs dynamic (PROJECT.md) context
5. **Preference Storage** - Remembers your choices in `.initai.json`
6. **IDE Integration** - Optional Claude Code launch for seamless workflow

### Step 3: Intelligent Development Workflow
```bash
# For Claude selections - automatic prompt:
# Spustit Claude? (y/n): y
# Spouštím Claude Code...

# Your project is now ready with:
# ├── initai/blissframework-backend-claude/  # Framework files
# ├── CLAUDE.md                             # Static instructions
# ├── PROJECT.md                            # Dynamic context (created by Claude)
# └── .initai.json                          # User preferences
```

**Smart Context Management:**
- **CLAUDE.md** - Contains initialization instructions (don't modify)
- **PROJECT.md** - Your working context, decisions, and project evolution
- **Framework files** - Organized in `initai/` directory with scope-specific templates

## Platform-Specific Installation

### Linux / macOS (Bash)
```bash
# Interactive three-tier selection
curl -sSL https://initai.dev/install.sh | bash

# The script will guide you through:
# 1. Framework selection (blissframework)
# 2. Scope selection (backend/frontend/fullstack)
# 3. LLM specialization (universal/claude/gemini)
```

### Windows (PowerShell)
```powershell
# Interactive three-tier selection
iwr -useb https://initai.dev/install.ps1 | iex

# Same three-tier selection process with Windows-optimized experience:
# - Native Windows path handling
# - PowerShell-style progress indicators
# - Windows Terminal color support
```

### API Integration
```bash
# The system uses a RESTful API for package management:
GET /init/shared/list                                    # Available frameworks
GET /init/shared/{framework}/{scope}                     # Universal packages
GET /init/shared/{framework}/{scope}/{llm}               # LLM-specific packages

# Example API response structure:
{
  "frameworks": [
    {
      "name": "blissframework",
      "description": "Enhanced development productivity framework",
      "scopes": [
        {
          "name": "backend",
          "variants": [
            {"name": "universal", "download_url": "/init/shared/blissframework/backend"},
            {"name": "claude", "download_url": "/init/shared/blissframework/backend/claude"}
          ]
        }
      ]
    }
  ]
}
```

> **📋 Advanced:** For detailed information about the multi-tenant architecture and future organization support, see [Tenant System](/content/tenant-system)

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