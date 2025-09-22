# InitAI.dev - LLM Framework Package Manager

🚀 **Modern package management system for LLM development frameworks with intelligent three-tier architecture**

[![Phoenix](https://img.shields.io/badge/Phoenix-1.6.6-orange)](https://phoenixframework.org/)
[![Elixir](https://img.shields.io/badge/Elixir-1.14+-purple)](https://elixir-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 🎯 **Project Overview**

InitAI.dev is a Phoenix web application that revolutionizes how developers initialize and manage LLM-optimized development frameworks. The system provides:

- **Three-tier architecture**: Framework → Scope → LLM specialization
- **Cross-platform installation scripts**: Bash, PowerShell, Python
- **Intelligent Claude Code integration** for seamless development workflow
- **Project context management** with persistent state across sessions
- **Self-updating mechanisms** with global user preferences

## ⚡ **Quick Start**

### Installation Scripts

**Bash (Linux/macOS):**
```bash
curl -fsSL https://initai.dev/install.sh | bash
```

**PowerShell (Windows):**
```powershell
iwr -useb https://initai.dev/install.ps1 | iex
```

### Development Setup

```bash
# Clone repository
git clone https://github.com/your-org/initai-web-phoenix
cd initai-web-phoenix

# Setup dependencies
mix setup

# Start development server
make start
# or: mix phx.server
```

## 🏗️ **Three-Tier Architecture**

### Hierarchy Structure
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

### User Experience Flow
1. **Framework Selection** - Choose your development framework
2. **Scope Selection** - Pick backend, frontend, or fullstack
3. **LLM Selection** - Select universal or LLM-specialized version

## 🛠️ **Core Features**

### Smart Package Management
- **Dynamic ZIP generation** - Packages created on-demand
- **Hierarchical organization** - Clear separation by scope and LLM
- **Automatic discovery** - New packages auto-detected and listed
- **Version control** - Independent versioning for each script type

### Intelligent Claude Integration
- **Auto-launch prompts** - Asks to launch Claude Code for Claude selections
- **Project context separation** - CLAUDE.md (instructions) vs PROJECT.md (context)
- **Persistent context** - Maintains project state across sessions
- **File protection** - Smart warnings before overwriting customized files

### Cross-Platform Support
- **Bash scripts** - Linux/macOS with fallback JSON parsing
- **PowerShell scripts** - Windows with full .NET integration
- **Self-updating** - Automatic version checking and updates
- **Global preferences** - User configuration across all projects

## 📁 **Project Structure**

```
├── lib/web_phoenix_web/
│   ├── controllers/
│   │   ├── init_controller.ex      # Three-tier package management
│   │   ├── api_controller.ex       # Version checking & health
│   │   └── install_controller.ex   # Installation script serving
│   └── router.ex                   # Clean route structure
├── priv/packages/shared/
│   └── blissframework/
│       ├── backend/
│       │   ├── init.md             # Universal backend files
│       │   ├── manifest.json
│       │   └── claude/             # Claude-specific files
│       └── frontend/
│           ├── init.md
│           ├── manifest.json
│           └── claude/
├── priv/static/
│   ├── initai.sh                   # Bash installation script
│   ├── initai.ps1                  # PowerShell installation script
│   └── installer-manifest.json     # Version tracking
└── assets/                         # Frontend assets
```

## 🔌 **API Endpoints**

### Package Management
```
GET /init/shared/list
# Returns hierarchical framework structure
{
  "frameworks": [
    {
      "name": "blissframework",
      "description": "...",
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

GET /init/shared/{framework}/{scope}           # Universal packages
GET /init/shared/{framework}/{scope}/{llm}     # LLM-specialized packages
```

### System APIs
```
GET /api/check-updates?client_version=2.1.0&script=powershell
GET /api/version
GET /api/health
```

## 🎨 **User Experience Highlights**

### Smart File Management
- **CLAUDE.md protection** - Prevents accidental overwriting of customized instructions
- **PROJECT.md workflow** - Persistent context management for ongoing projects
- **Local preferences** - `.initai` file stores Claude launch preferences

### Installation Experience
```bash
$ initai.sh

initai.dev - LLM Framework Manager v2.1.0
Initializing your development environment...

Which framework would you like to use?
  1) blissframework
     Framework for enhanced development productivity

Which development scope for blissframework?
  1) Backend - Server-side development, APIs, databases
  2) Frontend - Client-side development, UI/UX

Which LLM will you use with blissframework (backend)?
  1) Universal - Works with any LLM
  2) Claude (Anthropic) - Optimized for Claude AI

Selected: blissframework (backend) for claude
Package downloaded and extracted to: initai/blissframework-backend-claude
Configuration saved to .initai.json
Created CLAUDE.md with project instructions

Spustit Claude? (y/n): y
Spouštím Claude Code...
```

## 🧠 **Claude Code Integration**

### Automatic Context Loading
When Claude Code starts in a project with InitAI setup, it automatically:

1. **Detects CLAUDE.md** - Loads framework-specific instructions
2. **Reads PROJECT.md** - Continues from previous session context
3. **Applies framework config** - Follows coding standards and patterns
4. **Maintains consistency** - Uses established project conventions

### Generated Instructions Template
```markdown
# Claude Instructions for blissframework (backend)

## Project Context Management
- **Always save project context and notes to PROJECT.md**
- CLAUDE.md contains only initialization instructions (don't modify)
- Use PROJECT.md for ongoing project documentation, decisions, and context

## File Structure
- CLAUDE.md - Initialization instructions (static)
- PROJECT.md - Your working context (dynamic)
- initai/blissframework-backend-claude/ - Framework files

## Key Guidelines
- Always use bullet format for responses
- Save all project decisions and context to PROJECT.md
- Follow the framework's best practices
```

## 🔧 **Development**

### Available Commands
```bash
make help          # Show all available commands
make start         # Start development server
make setup         # Install dependencies
make test          # Run tests
make format        # Format code
make build         # Build for production
```

### Adding New Packages
```bash
# 1. Create package structure
mkdir -p priv/packages/shared/{framework}/{scope}
mkdir -p priv/packages/shared/{framework}/{scope}/{llm}

# 2. Add package files
echo "# Framework init" > priv/packages/shared/{framework}/{scope}/init.md
echo '{"name": "..."}' > priv/packages/shared/{framework}/{scope}/manifest.json

# 3. Packages are automatically discovered
curl https://initai.dev/init/shared/list
```

## 🚀 **Deployment**

The application is designed for production deployment with:

- **Automatic ZIP generation** - No pre-built packages needed
- **CDN compatibility** - Static assets served efficiently
- **Health monitoring** - Built-in health and version endpoints
- **Scalable architecture** - Phoenix OTP for high concurrent requests

## 📋 **Architecture Decisions**

### Why Three-Tier?
1. **Clear separation** - Backend vs Frontend vs Fullstack
2. **LLM specialization** - Optimized files per AI model
3. **Universal fallback** - Works without LLM-specific optimizations
4. **Future expansion** - Easy to add mobile, desktop, cloud scopes

### Why Phoenix/Elixir?
1. **Concurrent request handling** - Excellent for package downloads
2. **Dynamic ZIP creation** - No storage overhead
3. **Live reload** - Great developer experience
4. **OTP supervision** - Rock-solid reliability

### Why Smart Claude Integration?
1. **Seamless workflow** - From package install to coding
2. **Context persistence** - Never lose project state
3. **Framework adherence** - Automatic best practices
4. **Developer productivity** - Zero-friction setup

## 🔮 **Roadmap**

- [ ] **More frameworks** - Support for additional development frameworks
- [ ] **Database backend** - Move from file-based to database package storage
- [ ] **User authentication** - Personal package collections and preferences
- [ ] **Metrics dashboard** - Usage analytics and popular packages
- [ ] **Mobile/Desktop scopes** - Expand beyond web development
- [ ] **Package versioning** - Semantic versioning for framework packages
- [ ] **Community packages** - Allow user-contributed frameworks

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes following the existing patterns
4. Test your changes: `make test`
5. Submit a pull request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

🎯 **Built for developers, by developers. Making LLM framework initialization effortless and intelligent.**

*Visit [initai.dev](https://initai.dev) to get started*
