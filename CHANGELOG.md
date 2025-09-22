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
- **Cross-platform installation scripts** - Enhanced Bash and PowerShell scripts with three-tier selection
- **Comprehensive documentation** - Updated README.md with complete architecture overview
- **Changelog button** - Fixed position changelog access button in top-right corner

### Changed
- **Package structure** - Migrated from `/init/{tenant}/{framework}` to `/init/{tenant}/{framework}/{scope}[/{llm}]`
- **API response format** - Hierarchical structure with frameworks containing scopes containing variants
- **Installation workflow** - Enhanced user experience with framework → scope → LLM selection flow
- **CLAUDE.md template** - Added PROJECT.md workflow instructions and context management

### Removed
- **Backward compatibility code** - Removed all legacy two-tier support since no active users exist
- **Quick start section** - Removed from installation scripts to reduce user confusion

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
- **Bash (initai.sh)**: Added `select_scope()` function and Claude launch integration
- **PowerShell (initai.ps1)**: Parallel implementation with `Select-Scope` and Claude detection
- **Error handling**: Improved JSON parsing with fallback mechanisms

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

#### Claude Code Integration
- Automatic launch prompt for Claude selections
- User preference persistence in `.initai` file
- Context separation strategy with CLAUDE.md + PROJECT.md
- Framework-specific instructions and workflows

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