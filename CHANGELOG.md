# Changelog

All notable changes to InitAI.dev will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Three-tier architecture system** - Complete overhaul from two-tier to Framework → Scope → LLM structure
- **Smart Claude Code integration** - Automatic Claude launch prompts for Claude-specific packages
- **Project context management** - Separation of static instructions (CLAUDE.md) and dynamic context (PROJECT.md)
- **File protection system** - Warns before overwriting existing CLAUDE.md files
- **Cross-platform installation scripts** - Enhanced Bash, PowerShell, and Python scripts with three-tier selection
- **Python installation support** - Full-featured install.py and initai.py with cross-platform compatibility
- **Comprehensive documentation** - Updated README.md with complete architecture overview
- **Changelog button** - Fixed position changelog access button in top-right corner
- **Bootstrap installer** - Separate install.ps1/install.py for initial setup with PATH management
- **PATH integration** - Automatic user PATH setup for global initai command access
- **.NET package support** - Added dotnet scope with Claude-optimized guidance files
- **Tenant system documentation** - Dedicated tenant-system.md for multi-tenant architecture

### Changed
- **Package structure** - Migrated from `/init/{tenant}/{framework}` to `/init/{tenant}/{framework}/{scope}[/{llm}]`
- **API response format** - Hierarchical structure with frameworks containing scopes containing variants
- **Installation workflow** - Enhanced user experience with framework → scope → LLM selection flow
- **CLAUDE.md template** - Added PROJECT.md workflow and READ-ONLY initai/ folder instructions
- **Configuration management** - Unified .initai.json with launch_claude preference integration
- **Execution order** - Generate CLAUDE.md before launching Claude for proper context loading
- **Branding consistency** - Standardized to lowercase "initai.dev" across all components

### Fixed
- **Color output issues** - Removed problematic Bold parameter from PowerShell color hashtables
- **URL parsing errors** - Fixed BaseUrl parameter passing between install.ps1 and initai.ps1
- **Configuration conflicts** - Eliminated duplicate .initai and .initai.json files
- **Claude launch timing** - Fixed CLAUDE.md generation order to ensure instructions are available at startup
- **PATH restart messaging** - Hide "Restart console" message when PATH already contains initai.dev
- **Emoticon compatibility** - Replaced Unicode symbols with ASCII equivalents for broader terminal support

### Removed
- **Backward compatibility code** - Removed all legacy two-tier support since no active users exist
- **Quick start section** - Removed from installation scripts to reduce user confusion
- **Duplicate configuration files** - Consolidated .initai text file into .initai.json structure

### Technical Details

#### New Three-Tier Structure
```
Framework (blissframework)
├── Backend Scope
│   ├── Universal (works with any LLM)
│   ├── Claude (optimized for Claude)
│   └── Gemini (optimized for Gemini)
└── Frontend Scope
    ├── Universal
    ├── Claude
    └── Gemini
```

#### Enhanced Installation Scripts
- **Bootstrap installer (install.ps1/install.py)**: Separate installers with PATH management and smart restart messaging
- **Bash (initai.sh)**: Added `select_scope()` function, unified config, and READ-ONLY folder instructions
- **PowerShell (initai.ps1)**: Parallel implementation with `Select-Scope`, Claude detection, and color fixes
- **Python (initai.py)**: Full cross-platform implementation with identical three-tier functionality
- **Error handling**: Improved JSON parsing with fallback mechanisms and proper BaseUrl parameter passing
- **Cross-platform sync**: All three scripts maintain identical functionality and user experience

#### API Endpoints
```
GET /init/shared/list                                    # Framework hierarchy
GET /init/shared/{framework}/{scope}                     # Universal packages
GET /init/shared/{framework}/{scope}/{llm}               # LLM-specialized packages
```

#### File Protection Logic
- Detects existing CLAUDE.md files
- Prompts user for overwrite confirmation
- Provides guidance for manual integration
- Preserves user customizations

#### .NET Package Support
- **Universal dotnet package**: Basic .NET framework for all LLMs
- **Claude-optimized package**: Specialized with architecture-patterns.txt, general-principles.txt, naming-conventions.txt
- **Framework manifest**: Comprehensive compatibility metadata with features and language support
- **Scope integration**: Seamless three-tier selection with backend/frontend/dotnet options

#### PATH Integration & Bootstrap Installer
- **Smart PATH detection**: Checks existing PATH before adding initai.dev directory
- **User PATH modification**: Safe user-level PATH updates without requiring admin privileges
- **Conditional restart messaging**: Only shows "Restart console" when PATH was actually modified
- **Bootstrap workflow**: install.ps1/install.py → download initai.ps1/initai.py → setup PATH → launch main script
- **Global command access**: 'initai' command available from any directory after PATH setup
- **Python registry support**: Windows registry manipulation and Unix shell RC file updates

#### Claude Code Integration
- Automatic launch prompt for Claude selections
- User preference persistence in unified `.initai.json` file
- Context separation strategy with CLAUDE.md (static) + PROJECT.md (dynamic)
- Framework-specific instructions with READ-ONLY folder guidance
- Proper execution order: Generate CLAUDE.md → Ask Claude launch → Launch with context available

### Development
- Updated all controllers for three-tier routing
- Enhanced error handling and validation
- Comprehensive test coverage for new architecture
- Documentation generation and maintenance

## [Previous Versions]

*Note: This changelog begins with the major three-tier architecture refactor. Previous versions used a two-tier system that has been completely replaced.*

---

🎯 **Built for developers, by developers. Making LLM framework initialization effortless and intelligent.**

*Visit [initai.dev](https://initai.dev) to get started*