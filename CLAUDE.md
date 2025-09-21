# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Phoenix web application (Elixir) that serves as a documentation and installation script hosting platform for LLM initialization frameworks. The application primarily serves markdown content and provides installation scripts for different platforms.

## Development Commands

### Using Mix (traditional)
- **Start development server**: `mix phx.server`
- **Start with interactive shell**: `iex -S mix phx.server`
- **Install dependencies**: `mix deps.get`
- **Compile project**: `mix compile`
- **Run tests**: `mix test`
- **Format code**: `mix format`
- **Setup project**: `mix setup` (alias for deps.get)
- **Build assets for production**: `mix assets.deploy`

### Using Makefile (recommended)
- **View all commands**: `make help`
- **Start development server**: `make start`
- **Start with interactive shell**: `make iex`
- **Setup project**: `make setup`
- **Run tests**: `make test`
- **Format code**: `make format`
- **Build for production**: `make build`
- **Run all checks**: `make check`
- **Quick development workflow**: `make dev`

## Application Architecture

### Core Structure
- **Application entry point**: `lib/web_phoenix/application.ex` - OTP application with Phoenix endpoint, PubSub, and Telemetry
- **Web layer**: `lib/web_phoenix_web/` - Phoenix web components (controllers, views, router)
- **Business logic**: `lib/web_phoenix/` - Core application modules

### Key Components

#### Markdown Content System
- **Content module**: `lib/web_phoenix/markdown.ex` - Handles markdown rendering and file management
- **Content directory**: `priv/content/` - Stores markdown files served by the application
- **Content controller**: `lib/web_phoenix_web/controllers/content_controller.ex` - Serves markdown content as HTML

#### Installation Scripts & Package System
- **Install controller**: `lib/web_phoenix_web/controllers/install_controller.ex` - Serves installation scripts
- **Init controller**: `lib/web_phoenix_web/controllers/init_controller.ex` - Handles ZIP package downloads and package listing
- **API controller**: `lib/web_phoenix_web/controllers/api_controller.ex` - Version checking and health endpoints
- **Routes**:
  - `/install.sh`, `/install.ps1`, `/install.py` - Platform-specific installation scripts
  - `/init/{tenant}/list` - Lists available packages (e.g., `/init/shared/list`)
  - `/init/{tenant}/{framework}[/{llm}]` - Downloads ZIP packages
  - `/api/check-updates?client_version=X&script=Y` - Script-specific update checking
  - `/api/version`, `/api/health` - System information endpoints

### Router Configuration
The application serves:
- `/` - Home page
- `/content` - Content listing
- `/content/*path` - Dynamic markdown content serving
- `/install.{sh,ps1,py}` - Installation scripts for different platforms
- `/init/{tenant}/list` - Package listing API (JSON)
- `/init/{tenant}/{framework}[/{llm}]` - ZIP package downloads
- `/api/*` - API endpoints (version, health, update checking)

### Content Management
- Markdown files are stored in `priv/static/content/` directory
- Content is rendered using the Earmark library with path traversal protection
- All content URLs are prefixed with `/content/` for security and organization
- Files are accessed via URL paths: `/content/{path}` maps to `priv/static/content/{path}.md`
- Content listing is available at `/content`
- **IMPORTANT**: All pages except the homepage (index.html.heex) should be stored as markdown files in `priv/static/content/` and served through the documentation system using the docs layout

### Security Features
- **Path sanitization**: Prevents directory traversal attacks (`../`, absolute paths blocked)
- **Content directory restriction**: All file access is strictly limited to `priv/static/content/`
- **Input validation**: Only alphanumeric characters, hyphens, underscores, and forward slashes allowed in paths
- **Safe file resolution**: Double-checks resolved file paths remain within content directory

### Menu Configuration System
- **Fixed menu items**: Configured in `config/config.exs` under `:menu_config`
- **Dynamic content discovery**: Automatically scans `priv/static/content/` for available pages
- **Hierarchical structure**: Supports sections, subsections, and items with icons
- **LLM provider configuration**: Define providers (Claude, Gemini) with their frameworks
- **Framework priority**: Control display order with priority settings
- **Icon integration**: FontAwesome icons for all menu items
- **Active state detection**: Automatic highlighting of current page and section
- **Smart folder navigation**:
  - If folder contains `index.md`: Clicking folder opens `index.md`, submenu shows other files (excluding index.md)
  - If folder has no `index.md`: Clicking folder opens first available MD file, submenu shows all files
  - This allows flexible organization where folders can have landing pages or direct content access

### Fallback & Error Handling System
- **Intelligent 404 pages**: Custom not found template with contextual suggestions
- **Smart suggestions**: Context-aware recommendations based on requested path
- **Framework-specific fallbacks**: Shows available pages within same framework when file missing
- **LLM-specific fallbacks**: Lists available LLM documentation when framework page not found
- **General suggestions**: Popular pages (How It Works, Getting Started, Installation guides)
- **Breadcrumb preservation**: Maintains navigation context even on error pages
- **Graceful degradation**: Always provides actionable alternatives to users

## Development Workflow

### Adding New Content
1. Create markdown files in `priv/static/content/`
2. Files are automatically available at `/content/{path}` (without .md extension)
3. Subdirectories are supported: `/content/{llm}/{framework}/{page}`
4. Content listing and navigation updates automatically

### Adding New Packages
1. **Create package directory**: `priv/packages/shared/{framework}/`
2. **Add universal files**: `init.md`, `manifest.json` in framework root
3. **Add LLM-specific files**: Create `{llm}/` subdirectories with specialized files
4. **Package discovery**: New packages automatically appear in `/init/shared/list` API
5. **Testing**: Use `/init/shared/{framework}[/{llm}]` to download ZIP packages

### Configuring Menu
1. **Fixed sections**: Edit `:fixed_items` in `config/config.exs` for always-shown menu sections
2. **LLM providers**: Add new providers to `:llm_providers` with name, title, icon, and supported frameworks
3. **Framework settings**: Configure framework metadata in `:frameworks` (title, icon, priority)
4. **Dynamic discovery**: New files in `priv/static/content/` appear automatically in appropriate sections
5. **Icon customization**: Use FontAwesome classes for consistent iconography

### Asset Management
- Frontend assets are in `assets/` directory
- ESBuild is used for JavaScript/CSS bundling
- Live reload is configured for development
- Static files are served from `priv/static/`
- Background images stored in `priv/static/images/`

### UI/UX Design
- **Layout**: Floating hero section with centered content over gradient background
- **Styling**: Bootstrap 5 + custom CSS with dark blue gradient theme
- **Hero Section**: Full-height centered floating text with call-to-action
- **Get Started Section**: Two-column layout with install commands and features
- **No Navigation**: Clean design without top navigation bar
- **Flash Messages**: Conditionally rendered alerts (only show when messages exist)

### Configuration
- **Development**: `config/dev.exs` - Local development settings
- **Production**: `config/prod.exs` - Production configuration
- **Runtime**: `config/runtime.exs` - Runtime configuration
- **Test**: `config/test.exs` - Test environment settings

## Dependencies
Key dependencies include:
- Phoenix framework (~> 1.6.6)
- Phoenix LiveView for interactive components
- Earmark for markdown processing
- ESBuild for asset compilation
- Telemetry for monitoring

## Testing
- Tests are located in `test/` directory
- Run tests with `mix test` or `make test`
- Test configuration in `config/test.exs`

### Package Management System
- **Package storage**: `priv/packages/shared/` - Framework files organized by LLM
- **ZIP-based delivery**: Packages are dynamically created as ZIP files on request
- **Universal vs LLM-specific**: Support for both universal frameworks and LLM-optimized versions
- **Package structure**:
  ```
  priv/packages/shared/
  ├── blissframework/
  │   ├── init.md              # Universal framework files
  │   ├── manifest.json
  │   └── claude/              # LLM-specific files
  │       ├── init.md
  │       └── manifest.json
  ```
- **Automatic discovery**: New packages are automatically detected and listed via API

### Installation Script Features
- **Self-updating mechanism**: Scripts check for updates and can update themselves
- **Global user configuration**: `~/.initai` stores user preferences and usage statistics
- **Smart defaults**: Remembers last selection and suggests most-used packages
- **App data installation**: Scripts install to user's app data folder for global access
- **Cross-platform support**: PowerShell (Windows), Bash (Unix), Python (cross-platform)
- **Version tracking**: Each script type has independent versioning via `installer-manifest.json`

### API System
- **Script-specific updates**: `/api/check-updates?client_version=X&script=Y`
- **Package listing**: `/init/{tenant}/list` returns available packages with metadata
- **ZIP downloads**: `/init/{tenant}/{framework}[/{llm}]` serves dynamic ZIP packages
- **Health monitoring**: `/api/health` and `/api/version` for system status
- **Installer manifest**: `priv/static/installer-manifest.json` defines script versions and features

## Recent Updates
- **Major**: Implemented ZIP-based package delivery system
- **Major**: Added self-updating installation scripts with global user preferences
- **Major**: Created script-specific version checking API
- **Feature**: Global user configuration with usage statistics and smart defaults
- **Feature**: App data installation for cross-project accessibility
- **Fix**: ZIP creation in Elixir (charlist filenames, binary content)
- **Enhancement**: Removed legacy route conflicts and cleaned up router
- Created Makefile for simplified development workflow
- Redesigned homepage with floating hero layout
- Removed top navigation for cleaner design
- Updated background to dark blue gradient
- Fixed flash message rendering (conditional display)
- Improved responsive design with Bootstrap 5