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

#### Installation Scripts
- **Install controller**: `lib/web_phoenix_web/controllers/install_controller.ex` - Serves installation scripts
- **Routes**: `/install.sh`, `/install.ps1`, `/install.py` - Platform-specific installation scripts

### Router Configuration
The application serves:
- `/` - Home page
- `/content` - Content listing
- `/content/*path` - Dynamic markdown content serving
- `/install.{sh,ps1,py}` - Installation scripts for different platforms

### Content Management
- Markdown files are stored in `priv/content/` directory
- Content is rendered using the Earmark library
- Files are accessed via URL paths that map to markdown filenames
- Content listing is available at `/content`

## Development Workflow

### Adding New Content
1. Create markdown files in `priv/content/`
2. Files are automatically available at `/content/{filename}` (without .md extension)
3. Content listing updates automatically

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

## Recent Updates
- Created Makefile for simplified development workflow
- Redesigned homepage with floating hero layout
- Removed top navigation for cleaner design
- Updated background to dark blue gradient
- Fixed flash message rendering (conditional display)
- Improved responsive design with Bootstrap 5