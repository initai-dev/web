# Phoenix Web Application Makefile

# === Configuration ===
# Docker image settings
DOCKER_IMAGE_NAME = registry.km8.es/initai-web:production
DOCKER_CONTAINER_NAME = initai-web
DOCKER_PORT = 4000

.PHONY: help setup deps compile start test format clean build deploy docker-build docker-run docker-stop docker-logs docker-shell docker-compose-up docker-compose-down

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
	@echo ""
	@echo "Docker commands:"
	@echo "  docker-build    - Build Docker image"
	@echo "  docker-run      - Run application in Docker container"
	@echo "  docker-stop     - Stop Docker container"
	@echo "  docker-logs     - View Docker container logs"
	@echo "  docker-shell    - Open shell in running container"
	@echo "  docker-dev      - Full Docker workflow (stop, build, run)"
	@echo "  docker-clean    - Clean all Docker artifacts"
	@echo ""
	@echo "Docker Compose commands:"
	@echo "  docker-compose-up   - Start services with docker-compose"
	@echo "  docker-compose-down - Stop services with docker-compose"

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

# === Docker Commands ===

# Build Docker image
docker-build:
	@echo "🐳 Building Docker image..."
	docker build -t $(DOCKER_IMAGE_NAME) .

# Run Docker container
docker-run:
	@echo "🐳 Running Docker container..."
	docker run -d \
		--name $(DOCKER_CONTAINER_NAME) \
		-p $(DOCKER_PORT):4000 \
		-e SECRET_KEY_BASE=$$(mix phx.gen.secret) \
		$(DOCKER_IMAGE_NAME)
	@echo "🚀 Application running at http://localhost:$(DOCKER_PORT)"

# Stop Docker container
docker-stop:
	@echo "🐳 Stopping Docker container..."
	-docker stop $(DOCKER_CONTAINER_NAME)
	-docker rm $(DOCKER_CONTAINER_NAME)

# View Docker container logs
docker-logs:
	@echo "📄 Viewing Docker container logs..."
	docker logs -f $(DOCKER_CONTAINER_NAME)

# Open shell in running container
docker-shell:
	@echo "🐚 Opening shell in Docker container..."
	docker exec -it $(DOCKER_CONTAINER_NAME) /bin/sh

# Docker development workflow
docker-dev: docker-stop docker-build docker-run
	@echo "🐳 Docker development setup complete!"

# Clean Docker artifacts
docker-clean:
	@echo "🧹 Cleaning Docker artifacts..."
	-docker stop $(DOCKER_CONTAINER_NAME)
	-docker rm $(DOCKER_CONTAINER_NAME)
	-docker rmi $(DOCKER_IMAGE_NAME)
	docker system prune -f

# === Docker Compose Commands ===

# Start services with docker-compose
docker-compose-up:
	@echo "🐳 Starting services with docker-compose..."
	docker-compose up -d --build
	@echo "🚀 Application running at http://localhost:4000"

# Stop services with docker-compose
docker-compose-down:
	@echo "🐳 Stopping services with docker-compose..."
	docker-compose down