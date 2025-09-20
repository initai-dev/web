# Phoenix Web Application Makefile

.PHONY: help setup deps compile start test format clean build deploy

# Default target
help:
	@echo "Available commands:"
	@echo "  setup      - Install dependencies and setup project"
	@echo "  deps       - Install/update dependencies"
	@echo "  compile    - Compile the project"
	@echo "  start      - Start development server"
	@echo "  iex        - Start server with interactive shell"
	@echo "  test       - Run tests"
	@echo "  format     - Format code"
	@echo "  clean      - Clean build artifacts"
	@echo "  build      - Build for production"
	@echo "  assets     - Build assets for production"
	@echo "  check      - Run all checks (compile, format, test)"

# Project setup
setup: deps
	@echo "✓ Project setup complete"

# Dependencies
deps:
	@echo "📦 Installing dependencies..."
	mix deps.get

# Compilation
compile:
	@echo "🔨 Compiling project..."
	mix compile

# Development server
start:
	@echo "🚀 Starting development server..."
	mix phx.server

# Interactive shell with server
iex:
	@echo "🚀 Starting server with interactive shell..."
	iex -S mix phx.server

# Testing
test:
	@echo "🧪 Running tests..."
	mix test

# Code formatting
format:
	@echo "✨ Formatting code..."
	mix format

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	mix clean
	rm -rf _build
	rm -rf deps

# Production build
build: deps compile assets
	@echo "📦 Building for production..."
	MIX_ENV=prod mix compile

# Build assets for production
assets:
	@echo "🎨 Building production assets..."
	mix assets.deploy

# Run all checks
check: compile format test
	@echo "✅ All checks passed"

# Development workflow
dev: deps compile start

# Quick restart (for development)
restart:
	@echo "🔄 Quick restart..."
	mix compile && mix phx.server